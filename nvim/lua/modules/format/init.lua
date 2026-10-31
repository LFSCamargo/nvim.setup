-- Buffer formatters for Space f (conform.nvim).
-- Lua uses StyLua: Prettier's Lua plugin is unmaintained.
return {
  formatters_by_ft = {
    javascript = { 'prettierd' },
    typescript = { 'prettierd' },
    javascriptreact = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    vue = { 'prettierd' },
    svelte = { 'prettierd' },
    html = { 'prettierd' },
    css = { 'prettierd' },
    scss = { 'prettierd' },
    less = { 'prettierd' },
    json = { 'prettierd' },
    jsonc = { 'prettierd' },
    yaml = { 'prettierd' },
    markdown = { 'prettierd' },
    graphql = { 'prettierd' },
    lua = { 'stylua' },
    toml = { 'taplo' },
    rust = { 'rustfmt' },
    go = { 'gofmt' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    zsh = { 'shfmt' },
  },
  formatters = {
    shfmt = { prepend_args = { '-i', '2', '-ci' } },
  },
}
