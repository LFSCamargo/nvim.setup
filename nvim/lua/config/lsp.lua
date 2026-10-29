local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })
local mason = vim.fn.stdpath('data') .. '/mason/packages/'
vim.lsp.config('vtsls', {
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
  settings = { vtsls = { tsserver = { globalPlugins = { {
    name = '@vue/typescript-plugin', location = mason .. 'vue-language-server/node_modules/@vue/language-server', languages = { 'vue' }, configNamespace = 'typescript', enableForWorkspaceTypeScriptVersions = true,
  } } } }, typescript = { inlayHints = { parameterNames = { enabled = 'literals' } } } },
})
vim.lsp.config('jsonls', { settings = { json = { validate = { enable = true } } } })
vim.lsp.config('yamlls', { settings = { yaml = { keyOrdering = false } } })
vim.lsp.config('rust_analyzer', { settings = { ['rust-analyzer'] = { check = { command = 'clippy' } } } })
vim.lsp.enable({ 'vtsls', 'vue_ls', 'svelte', 'html', 'cssls', 'tailwindcss', 'eslint', 'rust_analyzer', 'gopls', 'solidity_ls_nomicfoundation', 'taplo', 'jsonls', 'yamlls', 'lua_ls' })
vim.diagnostic.config({ virtual_text = { spacing = 2 }, severity_sort = true, float = { border = 'rounded' } })
vim.api.nvim_create_autocmd('LspAttach', { callback = function(ev)
  local function map(k, f, desc) vim.keymap.set('n', k, f, { buffer = ev.buf, desc = desc }) end
  map('gd', vim.lsp.buf.definition, 'Go to definition')
  map('gr', vim.lsp.buf.references, 'References')
  map('K', vim.lsp.buf.hover, 'Documentation')
  map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
  map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
  map('<leader>ds', vim.lsp.buf.document_symbol, 'Document symbols')
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = 'Signature help' })
end })
