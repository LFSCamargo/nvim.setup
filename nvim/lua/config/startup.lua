-- Interactive startup layout: file tree, editor focus, then restored or default chats.
-- Headless runs (install, validate, tests) skip this so CLIs are not launched.
-- NVIM_CLEAN=1 skips session restore and starts a blank editor plus two fresh chats.

local M = {}
local opened = false

function M.open()
  if opened then
    return
  end
  opened = true
  local api = vim.api
  local dir = vim.fn.argv(0)
  if vim.fn.isdirectory(dir) == 1 then
    vim.cmd.cd(vim.fn.fnameescape(vim.fn.fnamemodify(dir, ':p')))
  end
  require('nvim-tree.api').tree.open({ focus = false })
  local editor
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local buf = api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == '' and vim.bo[buf].filetype ~= 'NvimTree' then
      editor = win
      break
    end
  end
  if not editor then
    vim.cmd('botright vnew')
    editor = api.nvim_get_current_win()
  end
  api.nvim_set_current_win(editor)
  local agents = require('config.agents')
  if not require('config.session').restore() then
    agents.new('codex')
    local codex = agents.active
    agents.new('cursor')
    -- Show Codex as the visible chat tab while both jobs keep running.
    if codex then
      agents.show(codex)
    end
  end
  api.nvim_set_current_win(editor)
  vim.cmd.stopinsert()
  require('nvim-tree.api').tree.resize()
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    if #vim.api.nvim_list_uis() > 0 then
      vim.schedule(M.open)
    end
  end,
})

return M
