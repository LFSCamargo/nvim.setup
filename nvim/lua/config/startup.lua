local M = {}
local opened = false
function M.open()
  if opened then return end
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
  agents.new('codex')
  local codex = agents.active
  agents.new('cursor')
  if codex then agents.show(codex) end
  -- Keep the editor ready for typing, with both chat sessions running.
  api.nvim_set_current_win(editor)
  vim.cmd.stopinsert()
  require('nvim-tree.api').tree.resize()
end
vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function()
  -- Headless maintenance and scripts must not start interactive CLIs.
  if #vim.api.nvim_list_uis() > 0 then vim.schedule(M.open) end
end })
return M
