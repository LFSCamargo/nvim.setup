-- Keep Gruvbox syntax colors and strip highlight backgrounds so the terminal shows through.
-- Selection fills stay: visual mode, search, and the selected completion item.

local M = {}

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

-- Statusline pills keep a fill; SL* groups are defined in config.statusline.
function M.keeps_fill(name)
  if keep[name] then
    return true
  end
  if name == 'StatusLine' or name == 'StatusLineNC' then
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
  local settings = package.loaded['config.settings']
  if settings and settings.get and not settings.get().transparent then
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
end

function M.apply()
  local ok, gruvbox = pcall(require, 'gruvbox')
  if ok then
    gruvbox.setup({
      transparent_mode = require('config.settings').get().transparent,
      terminal_colors = false,
      inverse = false,
    })
    vim.cmd.colorscheme('gruvbox')
  end
  if require('config.settings').get().transparent then
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

require('config.settings').boot()

return M
