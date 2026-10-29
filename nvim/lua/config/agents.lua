local M = { sessions = {}, active = nil, win = nil }
local next_id = 0
local function width() return math.max(1, math.floor(vim.o.columns * 0.25)) end
local function valid_win() return M.win and vim.api.nvim_win_is_valid(M.win) end
function M.is_chat(buf) return vim.b[buf].chat_id ~= nil end
local function focus_input(win, buf)
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win
      or vim.api.nvim_win_get_buf(win) ~= buf then return end
    local session = M.sessions[vim.b[buf].chat_id]
    if session and not session.exited and vim.bo[buf].buftype == 'terminal' then vim.cmd.startinsert() end
  end)
end
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
  if vim.bo[session.buf].buftype == 'terminal' and not session.exited then vim.cmd.startinsert() end
end
function M.new(name)
  local command = name == 'codex' and 'codex' or 'agent'
  if vim.fn.executable(command) == 0 then
    vim.notify(command .. ' is not on PATH', vim.log.levels.ERROR)
    return
  end
  next_id = next_id + 1
  local id = next_id
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].chat_id = id
  vim.bo[buf].bufhidden = 'hide'
  local session = { buf = buf, name = name, label = (name == 'codex' and 'Codex ' or 'Agent ') .. id }
  M.sessions[id] = session
  M.show(id)
  session.job = vim.fn.jobstart({ command }, { term = true, cwd = vim.fn.getcwd(), on_exit = function()
    vim.schedule(function()
      session.exited = true
      vim.cmd('redrawstatus')
    end)
  end })
  if session.job <= 0 then
    session.exited = true
    vim.notify('Could not start ' .. command, vim.log.levels.ERROR)
  end
  vim.keymap.set('t', '<Esc>', function()
    if not session.exited then vim.api.nvim_chan_send(session.job, '\27') end
  end, { buffer = buf, nowait = true, desc = 'Send Escape to agent' })
  vim.cmd.startinsert()
end
function M.select()
  vim.ui.select({ 'Codex', 'Cursor Agent' }, { prompt = 'New chat — choose CLI:' }, function(choice)
    if choice then M.new(choice == 'Codex' and 'codex' or 'cursor') end
  end)
end
function M.toggle(name)
  if valid_win() and M.sessions[M.active] and M.sessions[M.active].name == name then
    vim.api.nvim_win_close(M.win, false)
    M.win = nil
    return
  end
  for _, id in ipairs(vim.tbl_keys(M.sessions)) do
    if M.sessions[id].name == name then M.show(id); return end
  end
  M.new(name)
end
function M.close(id)
  local session = M.sessions[id]
  if not session then return end
  M.sessions[id] = nil
  if session.job and not session.exited then vim.fn.jobstop(session.job) end
  if vim.api.nvim_buf_is_valid(session.buf) then vim.api.nvim_buf_delete(session.buf, { force = true }) end
  local ids = vim.tbl_keys(M.sessions)
  table.sort(ids)
  if #ids > 0 then M.show(ids[#ids])
  else
    M.active = nil
    if valid_win() and #vim.api.nvim_list_wins() > 1 then vim.api.nvim_win_close(M.win, false) end
    M.win = nil
  end
end
vim.api.nvim_create_autocmd('VimResized', { callback = function()
  if valid_win() then vim.api.nvim_win_set_width(M.win, width()) end
end })
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, { callback = function(ev)
  if M.is_chat(ev.buf) then focus_input(vim.api.nvim_get_current_win(), ev.buf) end
end })
vim.api.nvim_create_user_command('AgentSelect', M.select, {})
vim.api.nvim_create_user_command('Codex', function() M.toggle('codex') end, {})
vim.api.nvim_create_user_command('CursorAgent', function() M.toggle('cursor') end, {})
return M
