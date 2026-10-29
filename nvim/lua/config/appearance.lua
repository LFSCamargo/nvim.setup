-- Keep Gruvbox foreground colors and let the terminal paint every background.
vim.opt.statusline = '%f %m%r%=%y  %l:%c  %p%%'
local function clear_backgrounds()
  for name, hl in pairs(vim.api.nvim_get_hl(0, { link = true })) do
    if hl.link then
      vim.api.nvim_set_hl(0, name, { link = hl.link })
    elseif hl.bg or hl.ctermbg or hl.reverse then
      hl.bg = nil
      hl.ctermbg = nil
      hl.reverse = nil
      hl.default = nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
  -- Preserve Gruvbox foreground colors, including the default text color.
  vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })
  vim.api.nvim_set_hl(0, 'NormalNC', { link = 'Normal' })
end
clear_backgrounds()
vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter', 'BufWinEnter' }, { callback = function() vim.schedule(clear_backgrounds) end })
vim.api.nvim_create_autocmd('User', { pattern = { 'LazyLoad', 'VeryLazy' }, callback = function() vim.schedule(clear_backgrounds) end })

-- Some plugins define their highlights in deferred startup callbacks.
vim.api.nvim_create_autocmd('VimEnter', { callback = function()
  vim.defer_fn(clear_backgrounds, 100)
  vim.defer_fn(clear_backgrounds, 1000)
end })
