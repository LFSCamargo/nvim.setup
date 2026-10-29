-- Child Neovim startup for e2e.lua: load keys/agents and open two fake CLI sessions.
vim.o.mouse = 'a'
require('config.appearance')
require('config.keys')
local editor = vim.api.nvim_get_current_win()
local agents = require('config.agents')
agents.new('codex')
agents.new('cursor')
agents.show(1)
vim.api.nvim_set_current_win(editor)
vim.cmd.stopinsert()
