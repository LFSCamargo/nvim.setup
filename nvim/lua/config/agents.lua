-- Chat CLIs in one shared pane (25% width). Switching tabs leaves the process
-- running. When a CLI exits, that chat tab closes. Sessions resume by ID:
-- `codex resume <uuid>`, `agent --resume=<uuid>`, `gemini --resume <uuid>`,
-- `claude --resume <uuid>`, `opencode --session <id>`.

local M = { sessions = {}, active = nil, win = nil }
local next_id = 0

local function width()
  return math.max(1, math.floor(vim.o.columns * 0.25))
end

local function valid_win()
  return M.win and vim.api.nvim_win_is_valid(M.win)
end

local function shutting_down()
  local loaded = package.loaded['config.session']
  return loaded and loaded.exiting
end

-- A failed wipe can drop the session while the terminal buffer remains.
local function buf_for(id)
  local session = M.sessions[id]
  if session and vim.api.nvim_buf_is_valid(session.buf) then return session.buf end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].chat_id == id then return buf end
  end
end

-- Chat session IDs are passed as argv elements, never through a shell.
local function persist_id(value)
  return type(value) == 'string' and #value >= 6 and #value <= 80 and value:match('^[%w%-_]+$') ~= nil
end

local function persist_uuid(value)
  return persist_id(value) and value:match('^[%x%-]+$') ~= nil and #value >= 8 and #value <= 64
end

local function persist()
  local ok, session = pcall(require, 'config.session')
  if ok and not session.busy then session.save() end
end

local function make_uuid()
  local hex = vim.fn.sha256(('%s:%s:%s'):format(vim.uv.hrtime(), math.random(), vim.uv.os_getpid()))
  return table.concat({
    hex:sub(1, 8), hex:sub(9, 12), hex:sub(13, 16), hex:sub(17, 20), hex:sub(21, 32),
  }, '-')
end

local function known_ids(name)
  local seen = {}
  for _, session in pairs(M.sessions) do
    if session.name == name and persist_id(session.uuid) then seen[session.uuid] = true end
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

local function newest_claude_uuid(cwd, known)
  local abs = vim.fn.fnamemodify(cwd, ':p'):gsub('/$', '')
  local dir = vim.fn.expand('~/.claude/projects/' .. abs:gsub('[^%w]', '-'))
  local handle = vim.uv.fs_scandir(dir)
  local best, best_mtime
  while handle do
    local name = vim.uv.fs_scandir_next(handle)
    if not name then break end
    local id = name:match('^([%x%-]+)%.jsonl$')
    if persist_uuid(id) and not known[id] then
      local stat = vim.uv.fs_stat(dir .. '/' .. name)
      local mtime = stat and stat.mtime and stat.mtime.sec or 0
      if not best_mtime or mtime >= best_mtime then
        best, best_mtime = id, mtime
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

local function capture_after_start(id, finder)
  local attempts = 0
  local function tick()
    attempts = attempts + 1
    local session = M.sessions[id]
    if not session or persist_id(session.uuid) then return end
    local uuid = finder(vim.fn.getcwd(), known_ids(session.name))
    if uuid then
      session.uuid = uuid
      persist()
      return
    end
    if attempts < 8 then vim.defer_fn(tick, 250) end
  end
  vim.defer_fn(tick, 250)
end

-- bin is the executable. start() is a new chat; resume() restores a stored ID.
-- IDs are allocated locally or by the CLI, then passed as argv (not a shell string).
local CLIS = {
  codex = {
    bin = 'codex',
    prompt = 'Codex',
    command = 'Codex',
    prefix = 'Codex ',
    start = function() return { 'codex' } end,
    resume = function(id) return { 'codex', 'resume', id } end,
    capture = newest_codex_uuid,
  },
  cursor = {
    bin = 'agent',
    prompt = 'Cursor Agent',
    command = 'CursorAgent',
    prefix = 'Agent ',
    allocate = allocate_agent_uuid,
    start = function(id)
      if persist_id(id) then return { 'agent', '--resume=' .. id } end
      return { 'agent' }
    end,
    resume = function(id) return { 'agent', '--resume=' .. id } end,
  },
  gemini = {
    bin = 'gemini',
    prompt = 'Gemini',
    command = 'Gemini',
    prefix = 'Gemini ',
    allocate = make_uuid,
    start = function(id)
      if persist_id(id) then return { 'gemini', '--session-id', id } end
      return { 'gemini' }
    end,
    resume = function(id) return { 'gemini', '--resume', id } end,
  },
  claude = {
    bin = 'claude',
    prompt = 'Claude',
    command = 'Claude',
    prefix = 'Claude ',
    start = function() return { 'claude' } end,
    resume = function(id) return { 'claude', '--resume', id } end,
    capture = newest_claude_uuid,
  },
  opencode = {
    bin = 'opencode',
    prompt = 'OpenCode',
    command = 'OpenCode',
    prefix = 'OpenCode ',
    allocate = function()
      return 'ses_' .. vim.fn.sha256(('%s:%s'):format(vim.uv.hrtime(), math.random())):sub(1, 16)
    end,
    start = function(id)
      if persist_id(id) then return { 'opencode', '--session', id } end
      return { 'opencode' }
    end,
    resume = function(id) return { 'opencode', '--session', id } end,
  },
}

M.order = { 'codex', 'cursor', 'gemini', 'claude', 'opencode' }

function M.is_cli(name)
  return CLIS[name] ~= nil
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
    local id = vim.b[buf].chat_id
    local session = M.sessions[id]
    if not session or session.exited then
      M.close(id)
      return
    end
    if vim.bo[buf].buftype == 'terminal' then vim.cmd.startinsert() end
  end)
end

-- Show an existing session, creating the sidebar split if needed.
function M.show(id)
  local session = M.sessions[id]
  if not session then return end
  if session.exited or not vim.api.nvim_buf_is_valid(session.buf) then
    M.close(id)
    return
  end
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
  if vim.bo[session.buf].buftype == 'terminal' then vim.cmd.startinsert() end
end

local function argv_for(cli, id, restoring)
  if restoring and persist_id(id) then return cli.resume(id), cli.start(nil) end
  return cli.start(id), cli.start(nil)
end

-- Start a new CLI as an argv list (not a shell string) so the command is not interpolated.
function M.new(name, opts)
  opts = opts or {}
  local cli = CLIS[name]
  if not cli then
    vim.notify('Unknown chat CLI: ' .. tostring(name), vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable(cli.bin) == 0 then
    vim.notify(cli.bin .. ' is not on PATH', vim.log.levels.ERROR)
    return
  end
  local restoring = persist_id(opts.uuid)
  local uuid = restoring and opts.uuid or nil
  if not uuid and cli.allocate then uuid = cli.allocate() end
  next_id = next_id + 1
  local id = next_id
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].chat_id = id
  vim.bo[buf].bufhidden = 'hide'
  local session = {
    buf = buf,
    name = name,
    uuid = uuid,
    label = opts.label or (cli.prefix .. id),
  }
  M.sessions[id] = session
  M.show(id)
  local resume_argv, fresh_argv = argv_for(cli, uuid, restoring)
  -- Defer past TermClose: wiping the current terminal in on_exit fails (E937)
  -- and used to leave a stuck "(exited)" tab that close could not retry.
  local function finish()
    session.exited = true
    if shutting_down() then return end
    M.close(id)
  end
  local function on_exit()
    vim.defer_fn(finish, 20)
  end
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = buf,
    once = true,
    callback = function()
      vim.defer_fn(finish, 20)
    end,
  })
  session.job = vim.fn.jobstart(resume_argv, {
    term = true,
    cwd = vim.fn.getcwd(),
    on_exit = on_exit,
  })
  if session.job <= 0 and persist_id(uuid) then
    session.uuid = nil
    uuid = nil
    vim.notify('Could not resume ' .. cli.bin .. '; starting a new session', vim.log.levels.WARN)
    session.job = vim.fn.jobstart(fresh_argv, {
      term = true,
      cwd = vim.fn.getcwd(),
      on_exit = on_exit,
    })
  end
  if session.job <= 0 then
    session.exited = true
    vim.notify('Could not start ' .. cli.bin, vim.log.levels.ERROR)
  elseif cli.capture and not persist_id(session.uuid) then
    capture_after_start(id, cli.capture)
  end
  -- Esc stays in terminal mode and is forwarded to the CLI (stop generation, and so on).
  vim.keymap.set('t', '<Esc>', function()
    if not session.exited then vim.api.nvim_chan_send(session.job, '\27') end
  end, { buffer = buf, nowait = true, desc = 'Send Escape to agent' })
  vim.cmd.startinsert()
  persist()
end

function M.select()
  local choices = {}
  for _, name in ipairs(M.order) do
    choices[#choices + 1] = CLIS[name].prompt
  end
  vim.ui.select(choices, { prompt = 'New chat — choose CLI:' }, function(choice)
    for name, cli in pairs(CLIS) do
      if cli.prompt == choice then
        M.new(name)
        return
      end
    end
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
    local s = M.sessions[id]
    if s and s.name == name and not s.exited then
      M.show(id)
      return
    end
  end
  M.new(name)
end

-- Stop the job, delete the buffer, and show another session or close the pane.
-- Switch away before wiping: deleting the current terminal often fails and
-- used to drop the session while the "(exited)" tab stayed on screen.
function M.close(id)
  if shutting_down() then return end
  local session = M.sessions[id]
  local buf = buf_for(id)
  if session then
    M.sessions[id] = nil
    if session.job then pcall(vim.fn.jobstop, session.job) end
    session.exited = true
  elseif not buf then
    return
  end
  if M.active == id then M.active = nil end
  pcall(vim.cmd.stopinsert)

  local ids = vim.tbl_keys(M.sessions)
  table.sort(ids)
  if #ids > 0 then
    local showing = valid_win() and buf and vim.api.nvim_win_get_buf(M.win) == buf
    if showing or not M.sessions[M.active] then M.show(ids[#ids]) end
  else
    M.active = nil
    if valid_win() and #vim.api.nvim_list_wins() > 1 then
      pcall(vim.api.nvim_win_close, M.win, false)
    end
    M.win = nil
  end

  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
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
for _, name in ipairs(M.order) do
  vim.api.nvim_create_user_command(CLIS[name].command, function() M.toggle(name) end, {})
end
return M
