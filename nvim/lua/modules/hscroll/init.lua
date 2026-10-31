-- Horizontal scroll for the mid editor and left sidebar.
-- Many terminals do not forward sideways wheel events; a macOS worker
-- watches the trackpad and calls scroll() over a local RPC socket.

local M = {}
local HORIZ_STEP = 6
local sock

vim.opt.mousemoveevent = true
vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 0

local function is_horiz_target(win)
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local agents = require('modules.agents')
  local buf = vim.api.nvim_win_get_buf(win)
  return not (agents.win == win or agents.is_chat(buf) or vim.bo[buf].buftype == 'terminal')
end

local function horiz_win()
  local pos = vim.fn.getmousepos()
  if is_horiz_target(pos.winid) then
    return pos.winid
  end
  local cur = vim.api.nvim_get_current_win()
  if is_horiz_target(cur) then
    return cur
  end
  local editor = require('modules.tabs').editor_win()
  if is_horiz_target(editor) then
    return editor
  end
  return nil
end

function M.socket_dir()
  return vim.fn.stdpath('state') .. '/nvim-setup-hscroll'
end

function M.interactive()
  return vim.env.E2E_DIR == nil and #vim.api.nvim_list_uis() > 0
end

function M.scroll(dir)
  dir = tonumber(dir) or 0
  if dir == 0 then
    return false
  end
  local win = horiz_win()
  if not win then
    return false
  end
  vim.api.nvim_win_call(win, function()
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 0
    local view = vim.fn.winsaveview()
    local info = vim.fn.getwininfo(win)[1]
    local text_width = 1
    if info then
      text_width = math.max(1, info.width - info.textoff)
    end
    local left = math.max(0, view.leftcol + (HORIZ_STEP * dir))
    if view.col < left then
      view.col = left
      view.curswant = left
    elseif view.col > left + text_width - 1 then
      view.col = left + text_width - 1
      view.curswant = view.col
    end
    view.leftcol = left
    vim.fn.winrestview(view)
  end)
  return true
end

function M.listen(opts)
  opts = type(opts) == 'table' and opts or {}
  if not opts.force and not M.interactive() then
    return nil
  end
  if type(sock) == 'string' then
    return sock
  end
  vim.fn.mkdir(M.socket_dir(), 'p', 448)
  local path = M.socket_dir() .. '/' .. tostring(vim.fn.getpid()) .. '.sock'
  if type(path) ~= 'string' or path:find('%.%.', 1, true) then
    return nil
  end
  local ok = pcall(vim.fn.serverstart, path)
  if ok then
    sock = path
  end
  return sock
end

function M.ensure_worker()
  if not M.interactive() or vim.fn.has('mac') == 0 then
    return false
  end
  local bin = vim.fn.expand('~/.local/bin/nvim-setup-hscroll')
  if vim.fn.executable(bin) == 0 then
    return false
  end
  if vim.fn.system({ 'pgrep', '-x', 'nvim-setup-hscroll' }):find('%d') then
    return true
  end
  vim.fn.jobstart({ bin }, { detach = true })
  return true
end

function M.stop()
  if type(sock) == 'string' then
    pcall(vim.fn.serverstop, sock)
    pcall(vim.uv.fs_unlink, sock)
    sock = nil
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    M.listen()
    M.ensure_worker()
  end,
})
vim.api.nvim_create_autocmd('VimLeavePre', { callback = M.stop })

return M
