vim.o.mouse = 'a'
require('config.keys')
local editor = vim.api.nvim_get_current_win()
local agents = require('config.agents')
agents.new('codex')
agents.new('cursor')
agents.show(1)
vim.api.nvim_set_current_win(editor)
vim.cmd.stopinsert()
