-- User settings: icons and a live reload. Persisted globally, not per project.
local M = {}
local api = vim.api
local defaults = { icons = true }
local current = { icons = true }
local buf, win, rows
local ns = api.nvim_create_namespace('SetupSettings')

local function valid(w)
  return w and api.nvim_win_is_valid(w)
end

function M.file()
  if type(vim.env.E2E_DIR) == 'string' and vim.env.E2E_DIR ~= '' then
    return vim.env.E2E_DIR .. '/settings.json'
  end
  return vim.fn.stdpath('state') .. '/nvim-setup/settings.json'
end

local function sanitize(data)
  if type(data) ~= 'table' then
    data = {}
  end
  return { icons = data.icons ~= false }
end

function M.get()
  return { icons = current.icons }
end

function M.load()
  local path = M.file()
  local fd = vim.uv.fs_open(path, 'r', 384)
  if not fd then
    current = sanitize(defaults)
    return current
  end
  local stat = vim.uv.fs_fstat(fd)
  local raw = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
  vim.uv.fs_close(fd)
  local ok, data = pcall(vim.json.decode, raw or '')
  current = sanitize(ok and data or {})
  return current
end

function M.save()
  local path = M.file()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local fd, err = vim.uv.fs_open(path, 'w', 384)
  if not fd then
    return false, err
  end
  vim.uv.fs_write(fd, vim.json.encode(M.get()))
  vim.uv.fs_close(fd)
  vim.uv.fs_chmod(path, 384)
  return true
end

function M.apply()
  require('config.icons').apply()
  pcall(vim.cmd.redrawstatus)
  if M.visible() then
    M.render()
  end
end

function M.set(key, value)
  if key ~= 'icons' then
    return false
  end
  current.icons = value ~= false
  M.save()
  M.apply()
  return true
end

function M.reload()
  M.load()
  M.apply()
  vim.notify('Settings reloaded', vim.log.levels.INFO)
end

function M.boot()
  M.load()
  M.apply()
end

function M.visible()
  return valid(win) and buf and api.nvim_buf_is_valid(buf)
end

function M.focus()
  if M.visible() then
    api.nvim_set_current_win(win)
    M.render()
  end
end

function M.close()
  if valid(win) then
    api.nvim_win_close(win, true)
  end
  win, buf, rows = nil, nil, nil
end

local function paint(lines)
  if not buf or not api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function mark(line, hl, from, to)
  api.nvim_buf_add_highlight(buf, ns, hl, line, from or 0, to or -1)
end

function M.render()
  if not M.visible() then
    return
  end
  local s = M.get()
  local lines = {
    '  SETTINGS',
    '  Saved for this machine. Reload picks them up without quitting.',
    '',
    '  Icons',
    '    [' .. (s.icons and 'x' or ' ') .. '] On',
    '    [' .. (s.icons and ' ' or 'x') .. '] Off',
    '',
    '  [Reload config]',
    '',
    '  Enter or click to change. q returns to Files.',
  }
  rows = {
    [5] = { kind = 'icons', value = true },
    [6] = { kind = 'icons', value = false },
    [8] = { kind = 'reload' },
  }
  paint(lines)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  mark(0, 'SetupTitle')
  mark(1, 'SetupHelp')
  mark(3, 'SetupSection')
  mark(4, s.icons and 'SetupChoiceOn' or 'SetupChoiceOff')
  mark(5, s.icons and 'SetupChoiceOff' or 'SetupChoiceOn')
  mark(7, 'SetupButton')
  mark(9, 'SetupHelp')
end

local function selected(line)
  line = line or api.nvim_win_get_cursor(win)[1]
  return rows and rows[line]
end

local function activate(entry)
  if not entry then
    return
  end
  if entry.kind == 'reload' then
    M.reload()
    return
  end
  M.set(entry.kind, entry.value)
end

local function bind()
  vim.keymap.set('n', '<CR>', function()
    activate(selected())
  end, { buffer = buf, silent = true, nowait = true, desc = 'Change setting' })
  vim.keymap.set('n', 'q', function()
    require('config.sidebar').files()
  end, { buffer = buf, silent = true, nowait = true, desc = 'Files sidebar' })
  vim.keymap.set('n', 'r', M.reload, { buffer = buf, silent = true, nowait = true, desc = 'Reload settings' })
  vim.keymap.set('n', '<LeftMouse>', function()
    local pos = vim.fn.getmousepos()
    if pos.winid == win and pos.line > 0 then
      vim.schedule(function()
        if M.visible() then
          activate(selected(pos.line))
        end
      end)
    end
    return '<LeftMouse>'
  end, { buffer = buf, expr = true, silent = true, desc = 'Change setting' })
end

function M.open(width)
  if M.visible() then
    api.nvim_set_current_win(win)
    M.render()
    return
  end
  vim.cmd('topleft vsplit')
  win = api.nvim_get_current_win()
  buf = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'setup-settings'
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  api.nvim_win_set_width(win, math.max(1, width or 20))
  bind()
  M.render()
end

local function highlights()
  api.nvim_set_hl(0, 'SetupTitle', { fg = '#ebdbb2', bold = true })
  api.nvim_set_hl(0, 'SetupSection', { fg = '#a89984', bold = true })
  api.nvim_set_hl(0, 'SetupChoiceOn', { fg = '#d79921', bold = true })
  api.nvim_set_hl(0, 'SetupChoiceOff', { fg = '#a89984' })
  api.nvim_set_hl(0, 'SetupButton', { fg = '#83a598', bold = true })
  api.nvim_set_hl(0, 'SetupHelp', { fg = '#928374' })
end
highlights()
api.nvim_create_autocmd('ColorScheme', { callback = highlights })

api.nvim_create_autocmd('VimResized', {
  callback = function()
    if M.visible() then
      api.nvim_win_set_width(win, require('config.sidebar').width())
    end
  end,
})

api.nvim_create_autocmd('BufWipeout', {
  callback = function(event)
    if buf and event.buf == buf then
      win, buf, rows = nil, nil, nil
    end
  end,
})

return M
