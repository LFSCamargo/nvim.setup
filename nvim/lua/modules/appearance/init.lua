-- Keep Gruvbox syntax colors and strip highlight backgrounds so the terminal shows through.
-- Selection fills stay: visual mode, search, and the selected completion item.

local M = {}
package.loaded['modules.appearance'] = M

-- Groups that must keep a background or reverse fill so the selection stays visible.
M.selection_highlights = {
  'Visual',
  'VisualNOS',
  'VisualNC',
  'Search',
  'IncSearch',
  'CurSearch',
  'Substitute',
  'MatchParen',
  'PmenuSel',
  'PmenuKindSel',
  'PmenuExtraSel',
  'PmenuMatchSel',
  'WildMenu',
}

local keep = {}
for _, name in ipairs(M.selection_highlights) do
  keep[name] = true
end

-- The bottom statusline and active tabs keep fills; inactive tabs and pane borders are transparent.
-- Tokens follow the active catalog theme (Gruvbox until the user picks another).
M.bar_fill = '#3c3836'
M.powerline_fill = '#504a31'
M.tab_accent = '#fabd2f'
M.tab_ink = '#1d2021'
M.muted = '#a89984'
M.fg = '#ebdbb2'
M.sep = '#665c54'
M.modes = {
  Normal = '#d79921',
  Insert = '#cc241d',
  Visual = '#d65d0e',
  Replace = '#9d0006',
  Command = '#b57614',
  Terminal = '#d79921',
}

function M.set_chrome(chrome)
  if type(chrome) ~= 'table' then
    return
  end
  M.bar_fill = chrome.bar_fill or M.bar_fill
  M.powerline_fill = chrome.powerline_fill or M.powerline_fill
  M.tab_accent = chrome.tab_accent or M.tab_accent
  M.tab_ink = chrome.tab_ink or M.tab_ink
  M.muted = chrome.muted or M.muted
  M.fg = chrome.fg or M.fg
  M.sep = chrome.sep or M.sep
  if type(chrome.modes) == 'table' then
    M.modes = vim.tbl_extend('force', M.modes, chrome.modes)
  end
  vim.api.nvim_set_hl(0, 'PaneTabActive', { fg = M.tab_ink, bg = M.tab_accent, bold = true })
  vim.api.nvim_set_hl(0, 'PaneTabActiveSep', { fg = M.tab_accent })
  vim.api.nvim_set_hl(0, 'SidebarTabActive', { fg = M.tab_ink, bg = M.tab_accent, bold = true })
  vim.api.nvim_set_hl(0, 'SidebarTabActiveSep', { fg = M.tab_accent })
  local statusline = package.loaded['modules.statusline']
  if type(statusline) == 'table' and statusline.refresh_highlights then
    statusline.refresh_highlights()
  end
  M.paint_scrollbars()
  M.paint_terminal()
  local settings = package.loaded['modules.settings']
  if type(settings) == 'table' and settings.highlights then
    settings.highlights()
  end
end

function M.chrome()
  return {
    bar_fill = M.bar_fill,
    powerline_fill = M.powerline_fill,
    tab_accent = M.tab_accent,
    tab_ink = M.tab_ink,
    muted = M.muted,
    fg = M.fg,
    sep = M.sep,
    modes = M.modes,
  }
end

function M.scroll_plugin_opts()
  local opts = { enabled = false }
  for _, spec in ipairs(require('modules.plugins.ui')) do
    if spec[1] == 'mihovilrak/scroll.nvim' and type(spec.opts) == 'table' then
      opts = vim.deepcopy(spec.opts)
      break
    end
  end
  local settings = package.loaded['modules.settings']
  opts.enabled = settings and settings.get and settings.get().scrollbars == true
  return opts
end

-- scroll.nvim is off until Settings → Scrollbars. setup() enables or tears down.
function M.apply_scroll_plugin()
  local opts = M.scroll_plugin_opts()
  pcall(function()
    require('scroll').setup(opts)
  end)
  if opts.enabled then
    M.paint_scrollbars()
  end
end

-- scroll.nvim links to Pmenu by default, which reads as a bright block after
-- we strip popup backgrounds. Paint muted chrome instead.
function M.paint_scrollbars()
  vim.api.nvim_set_hl(0, 'ScrollTrack', { fg = M.sep, bg = M.bar_fill })
  vim.api.nvim_set_hl(0, 'ScrollThumb', { fg = M.muted, bg = M.sep })
  vim.api.nvim_set_hl(0, 'ScrollThumbHover', { fg = M.fg, bg = M.sep })
  pcall(function()
    require('scroll.highlight').setup()
  end)
end

-- Stock xterm / libvterm ANSI (same values Neovim uses when the globals are unset).
function M.default_ansi()
  return {
    [0] = '#000000',
    '#cd0000',
    '#00cd00',
    '#cdcd00',
    '#0000ee',
    '#cd00cd',
    '#00cdcd',
    '#e5e5e5',
    '#7f7f7f',
    '#ff0000',
    '#00ff00',
    '#ffff00',
    '#5c5cff',
    '#ff00ff',
    '#00ffff',
    '#ffffff',
  }
end

function M.reset_terminal_colors()
  for i = 0, 15 do
    vim.g['terminal_color_' .. i] = nil
  end
end

local function hex_color(value, fallback)
  if type(value) == 'string' and value:match('^#%x%x%x%x%x%x$') then
    return value
  end
  return fallback
end

-- Map the 16 ANSI slots to the active catalog chrome so Cursor Agent bars
-- and named SGR follow the selected theme instead of stock xterm white.
function M.theme_ansi(chrome)
  chrome = chrome or M.chrome()
  local stock = M.default_ansi()
  local modes = type(chrome.modes) == 'table' and chrome.modes or {}
  local fg = hex_color(chrome.fg, stock[7])
  local muted = hex_color(chrome.muted, stock[8])
  local sep = hex_color(chrome.sep, stock[8])
  local accent = hex_color(chrome.tab_accent, stock[11])
  local red = hex_color(modes.Replace, stock[1])
  local green = hex_color(modes.Insert, stock[2])
  local yellow = hex_color(modes.Command, stock[3])
  local blue = hex_color(modes.Normal, stock[4])
  local magenta = hex_color(modes.Visual, stock[5])
  return {
    -- Keep ANSI 0 as stock black. Mapping it to theme ink paints the whole
    -- chat pane and fights transparency.
    [0] = stock[0],
    red,
    green,
    yellow,
    blue,
    magenta,
    muted,
    -- Cursor's prompt bar uses 7/15. Theming those to text color makes
    -- spaces vanish ("Adda", "Runeverything").
    stock[7],
    sep,
    red,
    green,
    accent,
    blue,
    magenta,
    muted,
    stock[15],
  }
end

-- Publish themed ANSI as RGB. Named SGR from any agent is remapped to
-- gray by Warp's contrast setting; RGB is left alone.
function M.apply_terminal_colors(_env)
  for i, hex in pairs(M.theme_ansi()) do
    vim.g['terminal_color_' .. i] = hex
  end
  return true
end

-- Default terminal cells stay transparent like Normal so Warp shows through.
-- Cursor Agent paints its own input chrome; a Terminal fill made that a slab.
function M.paint_terminal()
  local fg = hex_color(M.fg, '#e5e5e5')
  vim.api.nvim_set_hl(0, 'Terminal', { fg = fg })
  vim.api.nvim_set_hl(0, 'TerminalNormal', { fg = fg })
  return M.apply_terminal_colors()
end

-- Statusline pills and active tabs keep their fill through transparency passes.
function M.keeps_fill(name)
  if keep[name] then
    return true
  end
  if name == 'StatusLine' or name == 'StatusLineNC' then
    return true
  end
  if name == 'PaneTabActive' or name == 'SidebarTabActive' then
    return true
  end
  if name:sub(1, 6) == 'Scroll' then
    return true
  end
  return name:sub(1, 2) == 'SL'
end

-- Gruvbox dark bg3, used only if Visual was already stripped before this module ran.
local visual_fallback = { bg = '#665c54' }

local saved = {}

local function copy_hl(hl)
  local out = {}
  for _, key in ipairs({
    'fg',
    'bg',
    'sp',
    'bold',
    'italic',
    'underline',
    'undercurl',
    'underdouble',
    'underdotted',
    'underdashed',
    'strikethrough',
    'reverse',
    'standout',
    'nocombine',
    'ctermfg',
    'ctermbg',
    'blend',
  }) do
    out[key] = hl[key]
  end
  return out
end

local function has_fill(hl)
  return hl.bg ~= nil or hl.ctermbg ~= nil or hl.reverse == true
end

-- Remember selection colors while they still have a fill (typically right after ColorScheme).
local function remember_selection()
  for _, name in ipairs(M.selection_highlights) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if has_fill(hl) then
      saved[name] = copy_hl(hl)
    end
  end
end

local function restore_selection()
  for _, name in ipairs(M.selection_highlights) do
    local hl = saved[name]
    if hl then
      vim.api.nvim_set_hl(0, name, copy_hl(hl))
    end
  end
  -- Visual is the reported case: never leave it without a fill.
  if not has_fill(vim.api.nvim_get_hl(0, { name = 'Visual', link = false })) then
    vim.api.nvim_set_hl(0, 'Visual', visual_fallback)
    saved.Visual = copy_hl(visual_fallback)
  end
end

local function clear_backgrounds()
  local settings = package.loaded['modules.settings']
  if settings and settings.get and not settings.get().transparent then
    M.paint_terminal()
    return
  end
  remember_selection()
  for name, hl in pairs(vim.api.nvim_get_hl(0, { link = true })) do
    -- Leave visual/search/completion selection alone so the fill stays visible.
    if not M.keeps_fill(name) then
      if hl.link then
        vim.api.nvim_set_hl(0, name, { link = hl.link })
      elseif has_fill(hl) then
        hl.bg = nil
        hl.ctermbg = nil
        hl.reverse = nil
        hl.default = nil
        vim.api.nvim_set_hl(0, name, hl)
      end
    end
  end
  -- Preserve Gruvbox foreground colors, including the default text color.
  vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })
  vim.api.nvim_set_hl(0, 'NormalNC', { link = 'Normal' })
  restore_selection()
  M.paint_scrollbars()
  M.paint_terminal()
end

function M.apply()
  require('modules.themes').apply_scheme()
  if require('modules.settings').get().transparent then
    clear_backgrounds()
  end
end

clear_backgrounds()
vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter', 'BufWinEnter' }, {
  callback = function()
    vim.schedule(clear_backgrounds)
  end,
})
vim.api.nvim_create_autocmd('User', {
  pattern = { 'LazyLoad', 'VeryLazy' },
  callback = function()
    vim.schedule(clear_backgrounds)
  end,
})

-- Some plugins define highlights in deferred startup callbacks; re-apply after they run.
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.defer_fn(clear_backgrounds, 100)
    vim.defer_fn(clear_backgrounds, 1000)
  end,
})

require('modules.settings').boot()
M.apply()

return M
