-- User settings: icons and a live reload. Persisted globally, not per project.
local M = {}
local api = vim.api
local defaults = {
  icons = true,
  number = true,
  relativenumber = true,
  clipboard = true,
  indent = 2,
  scrolloff = 5,
  ignorecase = true,
  smartcase = true,
  transparent = true,
  session_restore = true,
}
local current = vim.deepcopy(defaults)
M.defaults = defaults
M.options = {
  { section = 'Appearance', key = 'icons', label = 'File icons', kind = 'boolean' },
  { section = 'Appearance', key = 'transparent', label = 'Transparent background', kind = 'boolean' },
  { section = 'Appearance', key = 'number', label = 'Line numbers', kind = 'boolean' },
  { section = 'Appearance', key = 'relativenumber', label = 'Relative line numbers', kind = 'boolean' },
  { section = 'Editing', key = 'indent', label = 'Indent width', kind = 'choice', values = { 2, 4, 8 } },
  { section = 'Editing', key = 'scrolloff', label = 'Scroll margin', kind = 'choice', values = { 0, 3, 5, 8, 10 } },
  { section = 'Editing', key = 'clipboard', label = 'System clipboard', kind = 'boolean' },
  { section = 'Search', key = 'ignorecase', label = 'Ignore case', kind = 'boolean' },
  { section = 'Search', key = 'smartcase', label = 'Smart case', kind = 'boolean' },
  {
    section = 'Sessions',
    key = 'session_restore',
    label = 'Restore project session',
    kind = 'boolean',
    restart = true,
  },
}
local buf, win, rows
local ns = api.nvim_create_namespace('SetupSettings')
package.loaded['modules.settings'] = M
local booting = false

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
  local result = vim.deepcopy(defaults)
  for _, option in ipairs(M.options) do
    local value = data[option.key]
    if option.kind == 'boolean' and type(value) == 'boolean' then
      result[option.key] = value
    elseif option.values and vim.tbl_contains(option.values, value) then
      result[option.key] = value
    end
  end
  return result
end

function M.get()
  return vim.deepcopy(current)
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
  vim.o.number = current.number
  vim.o.relativenumber = current.relativenumber
  vim.o.clipboard = current.clipboard and 'unnamedplus' or ''
  vim.o.expandtab = true
  vim.o.shiftwidth = current.indent
  vim.o.tabstop = current.indent
  vim.o.scrolloff = current.scrolloff
  vim.o.ignorecase = current.ignorecase
  vim.o.smartcase = current.smartcase
  local appearance = package.loaded['modules.appearance']
  if not booting and appearance and appearance.apply then
    appearance.apply()
  end
  require('modules.icons').apply()
  pcall(vim.cmd.redrawstatus)
  if M.visible() then
    M.render()
  end
end

function M.set(key, value)
  local option
  for _, item in ipairs(M.options) do
    if item.key == key then
      option = item
      break
    end
  end
  if
    not option
    or (option.kind == 'boolean' and type(value) ~= 'boolean')
    or (option.values and not vim.tbl_contains(option.values, value))
  then
    return false
  end
  current[key] = value
  local ok, err = M.save()
  if not ok then
    vim.notify('Could not save settings: ' .. tostring(err), vim.log.levels.ERROR)
  end
  M.apply()
  return ok
end

function M.reset(key)
  return M.set(key, defaults[key])
end

function M.reload()
  M.load()
  M.apply()
  vim.notify('Settings reloaded', vim.log.levels.INFO)
end

function M.boot()
  booting = true
  M.load()
  M.apply()
  booting = false
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
  require('modules.shared.buffer').replace(buf, lines)
end

local function mark(line, hl, from, to)
  api.nvim_buf_add_highlight(buf, ns, hl, line, from or 0, to or -1)
end

function M.render()
  if not M.visible() then
    return
  end
  local s = M.get()
  local lines = { '', '  Enter/click to change. x resets. q: Files.', '' }
  rows = {}
  local section
  for _, option in ipairs(M.options) do
    if section ~= option.section then
      section = option.section
      lines[#lines + 1] = '  ' .. section
    end
    local value = s[option.key]
    local display = type(value) == 'boolean' and (value and 'On' or 'Off') or tostring(value)
    lines[#lines + 1] = '    ' .. option.label .. ': ' .. display .. (option.restart and ' (restart)' or '')
    rows[#lines] = { kind = 'setting', option = option }
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  [Reload config]'
  rows[#lines] = { kind = 'reload' }
  lines[#lines + 1] = '  [Command palette]'
  rows[#lines] = { kind = 'palette' }
  paint(lines)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  mark(1, 'SetupHelp')
  for i, line in ipairs(lines) do
    if line:match('^  %w') and not rows[i] and i > 3 then
      mark(i - 1, 'SetupSection')
    end
    if rows[i] then
      mark(i - 1, rows[i].kind == 'setting' and 'SetupChoiceOn' or 'SetupButton')
    end
  end
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
  if entry.kind == 'palette' then
    require('modules.palette').open()
    return
  end
  local option = entry.option
  local value = current[option.key]
  if option.kind == 'boolean' then
    M.set(option.key, not value)
  else
    local index = 1
    for i, candidate in ipairs(option.values) do
      if candidate == value then
        index = i
        break
      end
    end
    M.set(option.key, option.values[index % #option.values + 1])
  end
end

local function bind()
  vim.keymap.set('n', '<CR>', function()
    activate(selected())
  end, { buffer = buf, silent = true, nowait = true, desc = 'Change setting' })
  vim.keymap.set('n', 'q', function()
    require('modules.sidebar').files()
  end, { buffer = buf, silent = true, nowait = true, desc = 'Files sidebar' })
  vim.keymap.set('n', 'r', M.reload, { buffer = buf, silent = true, nowait = true, desc = 'Reload settings' })
  vim.keymap.set('n', 'x', function()
    local entry = selected()
    if entry and entry.option then
      M.reset(entry.option.key)
    end
  end, { buffer = buf, silent = true, nowait = true, desc = 'Reset setting' })
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
      api.nvim_win_set_width(win, math.max(36, require('modules.sidebar').width()))
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
