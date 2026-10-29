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
o.scrolloff = 5
o.completeopt = { 'menu', 'menuone', 'noselect' }

-- nvim-tree replaces netrw; disable the built-in file explorer.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazy = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazy) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazy,
  })
  if vim.v.shell_error ~= 0 then error(out) end
end
vim.opt.rtp:prepend(lazy)

require('lazy').setup({
  {
    'ellisonleao/gruvbox.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      -- Transparent backgrounds so the terminal color shows through.
      require('gruvbox').setup({ transparent_mode = true, terminal_colors = false, inverse = false })
      vim.o.background = 'dark'
      vim.cmd.colorscheme('gruvbox')
    end,
  },
  { 'nvim-tree/nvim-web-devicons', opts = {} },
  {
    'nvim-tree/nvim-tree.lua',
    config = function()
      require('nvim-tree').setup({
        view = { width = function() return math.max(1, math.floor(vim.o.columns * 0.25)) end },
        renderer = { icons = { show = { file = false, folder = false, git = false } } },
        update_focused_file = { enable = true },
      })
    end,
  },
  {
    'ibhagwan/fzf-lua',
    opts = {
      fzf_opts = { ['--layout'] = 'reverse' },
      files = {
        cmd = 'fd --type f --hidden --exclude .git --exclude node_modules --exclude target --exclude .svelte-kit --exclude .nuxt --exclude dist',
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    opts = { current_line_blame = true, current_line_blame_opts = { delay = 700 } },
  },
  { 'tpope/vim-fugitive' },
  { 'folke/trouble.nvim', opts = { icons = false } },
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = { icons = { mappings = false } } },
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      vim.cmd('syntax enable')
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
      })
    end,
  },
  { 'mason-org/mason.nvim', opts = {} },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'mason-org/mason.nvim', 'hrsh7th/cmp-nvim-lsp' },
    config = function() require('config.lsp') end,
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path' },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        snippet = { expand = function(args) vim.snippet.expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
          ['<C-e>'] = cmp.mapping.abort(),
          -- Tab: next item, snippet jump, complete after text, otherwise indent.
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
            elseif vim.snippet.active({ direction = 1 }) then
              vim.snippet.jump(1)
            else
              local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
              if before:match('%S$') then cmp.complete() else fallback() end
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
            elseif vim.snippet.active({ direction = -1 }) then
              vim.snippet.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources(
          { { name = 'nvim_lsp' }, { name = 'path' } },
          { { name = 'buffer', keyword_length = 3 } }
        ),
      })
    end,
  },
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        vue = { 'prettierd' },
        svelte = { 'prettierd' },
        json = { 'prettierd' },
        yaml = { 'prettierd' },
        toml = { 'taplo' },
        rust = { 'rustfmt' },
        go = { 'gofmt' },
      },
    },
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio', 'leoluz/nvim-dap-go' },
    config = function() require('config.dap') end,
  },
}, {
  rocks = { enabled = false },
  checker = { enabled = false },
  change_detection = { notify = false },
})

require('config.agents')
require('config.keys')
require('config.appearance')
require('config.startup')
