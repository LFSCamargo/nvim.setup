-- Codex and Cursor Agent CLI sessions in one shared chat pane (25% width).
-- Each session is a terminal buffer; switching tabs leaves the process running.
-- Chats resume by UUID (`codex resume <uuid>`, `agent --resume=<uuid>`).

local M = { sessions = {}, active = nil, win = nil }
local next_id = 0

local function width()
  return math.max(1, math.floor(vim.o.columns * 0.25))
end

local function valid_win()
  return M.win and vim.api.nvim_win_is_valid(M.win)
end

local function persist_uuid(value)
  return type(value) == 'string' and value:match('^[%x%-]+$') ~= nil and #value >= 8 and #value <= 64
end

local function persist()
  local ok, session = pcall(require, 'config.session')
  if ok and not session.busy then session.save() end
end

local function known_codex_uuids()
  local seen = {}
  for _, session in pairs(M.sessions) do
    if session.name == 'codex' and persist_uuid(session.uuid) then seen[session.uuid] = true end
  end
  return seen
end

local function newest_codex_uuid(cwd, known)
  local path = vim.fn.expand('~/.codex/session_index.jsonl')
  local fd = vim.uv.fs_open(path, 'r', 384)
  if not fd then return nil end
  local stat = vim.uv.fs_fstat(fd)
  local raw = stat and vim.uv.fs_read(fd, stat.size, 0) or ''
  vim.uv.fs_close(fd)
  local best
  local abs = vim.fn.fnamemodify(cwd, ':p')
  for line in vim.gsplit(raw, '\n', { plain = true, trimempty = true }) do
    local ok, row = pcall(vim.json.decode, line)
    if ok and type(row) == 'table' then
      local id = row.id or row.session_id or row.uuid
      local row_cwd = row.cwd or row.cwd_path or row.directory or row.workdir
      if persist_uuid(id) and not known[id] then
        if not row_cwd or vim.fn.fnamemodify(row_cwd, ':p') == abs then best = id end
      end
    end
  end
  return best
end

local function allocate_agent_uuid()
  if vim.fn.executable('agent') == 0 then return nil end
  local ok, result = pcall(function()
    return vim.system({ 'agent', 'create-chat' }, { timeout = 4000, text = true }):wait()
  end)
  if not ok or not result or result.code ~= 0 or type(result.stdout) ~= 'string' then return nil end
  local id = vim.trim(result.stdout)
  if persist_uuid(id) then return id end
  local matched = id:match('([%x%-][%x%-][%x%-][%x%-][%x%-][%x%-][%x%-][%x%-][%x%-]*)')
  return persist_uuid(matched) and matched or nil
end

local function capture_codex_uuid(id, cwd)
  local known = known_codex_uuids()
  local attempts = 0
  local function tick()
    attempts = attempts + 1
    local session = M.sessions[id]
    if not session or persist_uuid(session.uuid) then return end
    local uuid = newest_codex_uuid(cwd, known)
    if uuid then
      session.uuid = uuid
      persist()
      return
    end
    if attempts < 8 then vim.defer_fn(tick, 250) end
  end
  vim.defer_fn(tick, 250)
end

function M.is_chat(buf)
  return vim.b[buf].chat_id ~= nil
end

-- Enter terminal-input mode after the window actually owns the buffer.
local function focus_input(win, buf)
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win)
      or vim.api.nvim_get_current_win() ~= win
      or vim.api.nvim_win_get_buf(win) ~= buf then
      return
    end
    local session = M.sessions[vim.b[buf].chat_id]
    if session and not session.exited and vim.bo[buf].buftype == 'terminal' then
      vim.cmd.startinsert()
    end
  end)
end

-- Show an existing session, creating the sidebar split if needed.
function M.show(id)
  local session = M.sessions[id]
  if not session or not vim.api.nvim_buf_is_valid(session.buf) then return end
  if not valid_win() then
    vim.cmd('botright vsplit')
    M.win = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_set_current_win(M.win)
  vim.api.nvim_win_set_buf(M.win, session.buf)
  vim.api.nvim_win_set_width(M.win, width())
  vim.wo[M.win].winfixwidth = true
  M.active = id
  vim.cmd('redrawstatus')
  if vim.bo[session.buf].buftype == 'terminal' and not session.exited then
    vim.cmd.startinsert()
  end
end

local function argv_for(name, uuid)
  if name == 'codex' then
    if persist_uuid(uuid) then return { 'codex', 'resume', uuid }, { 'codex' } end
    return { 'codex' }, { 'codex' }
  end
  if persist_uuid(uuid) then return { 'agent', '--resume=' .. uuid }, { 'agent' } end
  return { 'agent' }, { 'agent' }
end

-- Start a new CLI as an argv list (not a shell string) so the command is not interpolated.
function M.new(name, opts)
  opts = opts or {}
  local command = name == 'codex' and 'codex' or 'agent'
  if vim.fn.executable(command) == 0 then
    vim.notify(command .. ' is not on PATH', vim.log.levels.ERROR)
    return
  end
  local uuid = persist_uuid(opts.uuid) and opts.uuid or nil
  if name ~= 'codex' and not uuid then uuid = allocate_agent_uuid() end
  next_id = next_id + 1
  local id = next_id
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].chat_id = id
  vim.bo[buf].bufhidden = 'hide'
  local session = {
    buf = buf,
    name = name,
    uuid = uuid,
    label = opts.label or ((name == 'codex' and 'Codex ' or 'Agent ') .. id),
  }
  M.sessions[id] = session
  M.show(id)
  local resume_argv, fresh_argv = argv_for(name, uuid)
  local function on_exit()
    vim.schedule(function()
      session.exited = true
      vim.cmd('redrawstatus')
    end)
  end
  session.job = vim.fn.jobstart(resume_argv, {
    term = true,
    cwd = vim.fn.getcwd(),
    on_exit = on_exit,
  })
  if session.job <= 0 and persist_uuid(uuid) then
    session.uuid = nil
    uuid = nil
    vim.notify('Could not resume ' .. command .. '; starting a new session', vim.log.levels.WARN)
    session.job = vim.fn.jobstart(fresh_argv, {
      term = true,
      cwd = vim.fn.getcwd(),
      on_exit = on_exit,
    })
  end
  if session.job <= 0 then
    session.exited = true
    vim.notify('Could not start ' .. command, vim.log.levels.ERROR)
  elseif name == 'codex' and not persist_uuid(session.uuid) then
    capture_codex_uuid(id, vim.fn.getcwd())
  end
  -- Esc stays in terminal mode and is forwarded to the CLI (stop generation, and so on).
  vim.keymap.set('t', '<Esc>', function()
    if not session.exited then vim.api.nvim_chan_send(session.job, '\27') end
  end, { buffer = buf, nowait = true, desc = 'Send Escape to agent' })
  vim.cmd.startinsert()
  persist()
end

function M.select()
  vim.ui.select({ 'Codex', 'Cursor Agent' }, { prompt = 'New chat — choose CLI:' }, function(choice)
    if choice then M.new(choice == 'Codex' and 'codex' or 'cursor') end
  end)
end

-- Toggle this CLI's pane: hide if it is already showing, else focus or start it.
function M.toggle(name)
  if valid_win() and M.sessions[M.active] and M.sessions[M.active].name == name then
    vim.api.nvim_win_close(M.win, false)
    M.win = nil
    return
  end
  for _, id in ipairs(vim.tbl_keys(M.sessions)) do
    if M.sessions[id].name == name then
      M.show(id)
      return
    end
  end
  M.new(name)
end

-- Stop the job, delete the buffer, and show another session or close the pane.
function M.close(id)
  local session = M.sessions[id]
  if not session then return end
  M.sessions[id] = nil
  if session.job and not session.exited then vim.fn.jobstop(session.job) end
  if vim.api.nvim_buf_is_valid(session.buf) then
    vim.api.nvim_buf_delete(session.buf, { force = true })
  end
  local ids = vim.tbl_keys(M.sessions)
  table.sort(ids)
  if #ids > 0 then
    M.show(ids[#ids])
  else
    M.active = nil
    if valid_win() and #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(M.win, false)
    end
    M.win = nil
  end
  persist()
end

vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    if valid_win() then vim.api.nvim_win_set_width(M.win, width()) end
  end,
})
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  callback = function(ev)
    if M.is_chat(ev.buf) then focus_input(vim.api.nvim_get_current_win(), ev.buf) end
  end,
})
vim.api.nvim_create_user_command('AgentSelect', M.select, {})
vim.api.nvim_create_user_command('Codex', function() M.toggle('codex') end, {})
vim.api.nvim_create_user_command('CursorAgent', function() M.toggle('cursor') end, {})
return M
