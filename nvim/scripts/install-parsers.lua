-- Headless installer: download or update every Tree-sitter parser in modules.tooling.
local parsers = require('modules.tooling').parsers
local ts = require('nvim-treesitter')
assert(ts.install(parsers):wait(300000), 'Some syntax parsers failed to install')
assert(ts.update(parsers):wait(300000), 'Some syntax parsers failed to update')
for _, lang in ipairs(parsers) do
  assert(pcall(vim.treesitter.language.add, lang), 'Parser installation failed: ' .. lang)
end
print('All syntax parsers installed and up to date')
vim.cmd('qa!')
