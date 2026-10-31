return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      vim.cmd('syntax enable')
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
  { 'mason-org/mason.nvim', opts = {} },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'mason-org/mason.nvim', 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      require('modules.lsp')
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path' },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },
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
              if before:match('%S$') then
                cmp.complete()
              else
                fallback()
              end
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
    opts = function()
      return require('modules.format')
    end,
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio', 'leoluz/nvim-dap-go' },
    config = function()
      require('modules.dap')
    end,
  },
}
