-- Language servers, completion capabilities, and buffer-local LSP keys.
-- Servers themselves are installed by Mason (see config.tooling).

local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

-- Vue needs the TypeScript plugin that ships inside the Mason vue-language-server package.
local mason = vim.fn.stdpath('data') .. '/mason/packages/'
vim.lsp.config('vtsls', {
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = '@vue/typescript-plugin',
            location = mason .. 'vue-language-server/node_modules/@vue/language-server',
            languages = { 'vue' },
            configNamespace = 'typescript',
            enableForWorkspaceTypeScriptVersions = true,
          },
        },
      },
    },
    typescript = { inlayHints = { parameterNames = { enabled = 'literals' } } },
  },
})
vim.lsp.config('jsonls', { settings = { json = { validate = { enable = true } } } })
vim.lsp.config('yamlls', { settings = { yaml = { keyOrdering = false } } })
vim.lsp.config('rust_analyzer', { settings = { ['rust-analyzer'] = { check = { command = 'clippy' } } } })

-- lua-language-server: `vim` is the Neovim API. Prefer a project .luarc.json when present.
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      telemetry = { enable = false },
    },
  },
  on_init = function(client)
    if client.workspace_folders then
      local root = client.workspace_folders[1].name
      if vim.uv.fs_stat(root .. '/.luarc.json') or vim.uv.fs_stat(root .. '/.luarc.jsonc') then
        return
      end
    end
    -- Projects without .luarc.json still get Neovim runtime types and the `vim` global.
    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua or {}, {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      telemetry = { enable = false },
    })
  end,
})

vim.lsp.enable({
  'vtsls',
  'vue_ls',
  'svelte',
  'html',
  'cssls',
  'tailwindcss',
  'eslint',
  'rust_analyzer',
  'gopls',
  'solidity_ls_nomicfoundation',
  'taplo',
  'jsonls',
  'yamlls',
  'lua_ls',
})

vim.diagnostic.config({
  virtual_text = { spacing = 2 },
  severity_sort = true,
  float = { border = 'rounded' },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local function map(k, f, desc)
      vim.keymap.set('n', k, f, { buffer = ev.buf, desc = desc })
    end
    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('gr', vim.lsp.buf.references, 'References')
    map('K', vim.lsp.buf.hover, 'Documentation')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
    map('<leader>ds', vim.lsp.buf.document_symbol, 'Document symbols')
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = 'Signature help' })
  end,
})
