local api = vim.api
assert(vim.fn.has('nvim-0.12') == 1, 'Neovim 0.12+ required')
assert(vim.g.colors_name == 'gruvbox', 'Gruvbox did not load')
assert(vim.o.mouse:find('a'), 'Mouse support missing')
assert(vim.o.showtabline == 0, 'Global tab bar must be hidden')
for _, key in ipairs({ '<C-s>', '<C-t>', '<C-w>', '<C-]>' }) do
  assert(vim.fn.maparg(key, 'n') ~= '', 'Missing keybinding: ' .. key)
end
for _, name in ipairs({ 'config.agents', 'config.tabs', 'cmp', 'nvim-tree.api', 'dap', 'conform', 'fzf-lua' }) do
  assert(pcall(require, name), 'Could not load module: ' .. name)
end
local registry = require('mason-registry')
for _, name in ipairs(require('config.tooling').packages) do
  assert(registry.get_package(name):is_installed(), 'Missing Mason package: ' .. name)
end
for _, lang in ipairs(require('config.tooling').parsers) do
  assert(pcall(vim.treesitter.language.add, lang), 'Missing syntax parser: ' .. lang)
end
for _, pair in ipairs({ { 'vim', 'let g:example = 1' }, { 'zsh', 'export EXAMPLE=ok' } }) do
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, { pair[2] })
  vim.bo[buf].filetype = pair[1]
  vim.treesitter.start(buf)
  assert(vim.treesitter.highlighter.active[buf], 'Highlighting failed: ' .. pair[1])
  api.nvim_buf_delete(buf, { force = true })
end
-- Let deferred plugin highlights and transparency cleanup finish before checking.
vim.defer_fn(function()
  local ok, err = pcall(function()
    for name, hl in pairs(api.nvim_get_hl(0, { link = false })) do
      assert(not hl.bg and not hl.ctermbg and not hl.reverse, 'Unexpected background: ' .. name)
    end
    assert(vim.tbl_isempty(require('config.agents').sessions), 'Headless startup launched chats')
    print('PASS: configuration, plugins, Mason tools, parsers, highlighting, transparency and shortcuts')
  end)
  if not ok then print(err); vim.cmd('cquit 1') else vim.cmd('qa!') end
end, 1300)
