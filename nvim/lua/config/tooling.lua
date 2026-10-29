-- Mason packages and Tree-sitter parsers installed by make tools / make parsers.
return {
  packages = {
    'vtsls',
    'vue-language-server',
    'svelte-language-server',
    'html-lsp',
    'css-lsp',
    'tailwindcss-language-server',
    'eslint-lsp',
    'rust-analyzer',
    'gopls',
    'nomicfoundation-solidity-language-server',
    'taplo',
    'json-lsp',
    'yaml-language-server',
    'lua-language-server',
    'prettierd',
    'js-debug-adapter',
    'delve',
    'codelldb',
  },
  parsers = {
    'bash', 'css', 'go', 'gomod', 'html', 'javascript', 'json', 'lua',
    'markdown', 'markdown_inline', 'rust', 'solidity', 'svelte', 'toml',
    'tsx', 'typescript', 'vim', 'vimdoc', 'vue', 'yaml', 'zsh',
  },
}
