-- nvim.setup entry point: options, plugin manager, then UI modules.
-- Leader is Space. Plugins are pinned in lazy-lock.json.

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = 'a'
o.clipboard = 'unnamedplus'
o.termguicolors = true -- Needed for accurate Gruvbox syntax colors.
o.signcolumn = 'yes'
o.updatetime = 250
o.timeoutlen = 400
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.undofile = true
o.swapfile = false -- Session snapshots recover unsaved buffers; leftover .swp must not ATTENTION.
o.scrolloff = 5
o.completeopt = { 'menu', 'menuone', 'noselect' }

-- nvim-tree replaces netrw; disable the built-in file explorer.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazy = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazy) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazy,
  })
  if vim.v.shell_error ~= 0 then
    error(out)
  end
end
vim.opt.rtp:prepend(lazy)

require('lazy').setup(require('modules.plugins').specs(), {
  rocks = { enabled = false },
  checker = { enabled = false },
  change_detection = { notify = false },
})

require('modules.agents')
require('modules.session')
require('modules.keys')
require('modules.images')
require('modules.appearance')
require('modules.statusline')
require('modules.startup')
