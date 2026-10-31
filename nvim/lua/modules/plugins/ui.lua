return {
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
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup(require('modules.sidebar').tree_setup())
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
}
