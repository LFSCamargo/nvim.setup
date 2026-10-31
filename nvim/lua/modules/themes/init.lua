-- Searchable catalog of supported colorschemes. The Themes sidebar applies one.
local M = {}
local api = vim.api
local catalog = require('modules.themes.catalog')
local buf, win, rows
local query = ''
local editing_search = false
local ns = api.nvim_create_namespace('SetupThemes')
package.loaded['modules.themes'] = M

local function valid(w)
  return w and api.nvim_win_is_valid(w)
end

function M.list()
  return catalog
end

function M.get(id)
  for _, theme in ipairs(catalog) do
    if theme.id == id then
      return theme
    end
  end
end

function M.has(id)
  return M.get(id) ~= nil
end

function M.default_id()
  return 'gruvbox'
end

function M.label(id)
  local theme = M.get(id)
  return theme and theme.label or 'Gruvbox Dark'
end

function M.schemes()
  local names = {}
  for _, theme in ipairs(catalog) do
    names[theme.colorscheme] = true
  end
  return names
end

function M.filter(text)
  query = text or ''
  if M.visible() then
    M.render()
  end
  return M.search(query)
end

function M.search(text)
  text = string.lower(vim.trim(text or ''))
  if text == '' then
    return vim.list_extend({}, catalog)
  end
  local out = {}
  for _, theme in ipairs(catalog) do
    local hay = string.lower(theme.id .. ' ' .. theme.label .. ' ' .. theme.flavor)
    for _, alias in ipairs(theme.aliases or {}) do
      hay = hay .. ' ' .. string.lower(alias)
    end
    if hay:find(text, 1, true) then
      out[#out + 1] = theme
    end
  end
  return out
end

function M.specs()
  local seen, out = {}, {}
  for _, theme in ipairs(catalog) do
    if not theme.shipped and not seen[theme.plugin] then
      seen[theme.plugin] = true
      out[#out + 1] = {
        theme.plugin,
        name = theme.plugin_name,
        lazy = true,
      }
    end
  end
  return out
end

local function plugin_folder(theme)
  return theme.plugin_name or theme.plugin:match('([^/]+)$')
end

function M.apply_scheme()
  local settings = require('modules.settings')
  local id = settings.get().theme
  local theme = M.get(id) or M.get(M.default_id())
  local appearance = package.loaded['modules.appearance']
  if type(appearance) == 'table' and appearance.set_chrome then
    appearance.set_chrome(theme.chrome)
  end
  if package.loaded.lazy and theme.setup then
    theme.setup()
  end
  vim.o.background = 'dark'
  if package.loaded.lazy then
    if
      not pcall(function()
        require('lazy').load({ plugins = { plugin_folder(theme) } })
        pcall(vim.cmd.colorscheme, theme.colorscheme)
      end) or vim.g.colors_name ~= theme.colorscheme
    then
      vim.g.colors_name = theme.colorscheme
    end
  else
    vim.g.colors_name = theme.colorscheme
  end
  if type(appearance) == 'table' and appearance.set_chrome then
    appearance.set_chrome(theme.chrome)
  end
end

function M.select(id)
  if not M.has(id) then
    return false
  end
  return require('modules.settings').set('theme', id)
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
  win, buf, rows, editing_search = nil, nil, nil, false
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
  local active = require('modules.settings').get().theme
  local lines = {
    '',
    '  > ' .. (query == '' and 'Search themes...' or query),
    '',
  }
  rows = { [2] = { kind = 'search' } }
  for _, theme in ipairs(M.search(query)) do
    local mark_dot = theme.id == active and '● ' or '  '
    lines[#lines + 1] = '  ' .. mark_dot .. theme.label
    rows[#lines] = { kind = 'theme', id = theme.id }
    lines[#lines + 1] = '    ' .. theme.flavor
    rows[#lines] = { kind = 'theme', id = theme.id }
  end
  paint(lines)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  mark(1, 'SetupHelp')
  for i, _ in ipairs(lines) do
    local row = rows[i]
    if row and row.kind == 'theme' then
      mark(i - 1, row.id == active and 'SetupChoiceOn' or 'SetupChoiceOff')
    end
  end
end

local function begin_search()
  if not M.visible() then
    return
  end
  editing_search = true
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 1, 2, false, { '  > ' })
  api.nvim_win_set_cursor(win, { 2, 4 })
  vim.cmd('startinsert!')
end

local function activate(line)
  local row = rows and rows[line]
  if not row then
    return
  end
  if row.kind == 'search' then
    begin_search()
    return
  end
  if row.kind == 'theme' then
    M.select(row.id)
    if M.visible() then
      M.render()
    end
  end
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
  vim.bo[buf].filetype = 'setup-themes'
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  api.nvim_win_set_width(win, math.max(1, width or 20))
  vim.keymap.set('n', '<CR>', function()
    activate(api.nvim_win_get_cursor(win)[1])
  end, { buffer = buf, silent = true, desc = 'Apply theme' })
  vim.keymap.set('n', '/', begin_search, { buffer = buf, desc = 'Search themes' })
  vim.keymap.set('i', '<CR>', '<Esc>', { buffer = buf, desc = 'Apply theme search' })
  api.nvim_create_autocmd('InsertLeave', {
    buffer = buf,
    callback = function()
      if not editing_search or not M.visible() then
        return
      end
      editing_search = false
      query = (api.nvim_buf_get_lines(buf, 1, 2, false)[1] or ''):gsub('^%s*>%s*', '')
      if query == 'Search themes...' then
        query = ''
      end
      vim.bo[buf].modifiable = false
      M.render()
    end,
  })
  vim.keymap.set('n', 'q', function()
    require('modules.sidebar').files()
  end, { buffer = buf, silent = true, desc = 'Files sidebar' })
  vim.keymap.set('n', '<LeftMouse>', function()
    local pos = vim.fn.getmousepos()
    if pos.winid == win and pos.line > 0 then
      vim.schedule(function()
        if M.visible() then
          activate(pos.line)
        end
      end)
    end
    return '<LeftMouse>'
  end, { buffer = buf, expr = true, silent = true, desc = 'Apply theme' })
  M.render()
end

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
      win, buf, rows, editing_search = nil, nil, nil, false
    end
  end,
})

return M
