-- Replace read-only UI buffer contents without repeating modifiable toggles.
local M = {}

function M.replace(buf, lines)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  return true
end

-- Reveal a virtual line above the first buffer line when the view is at the top.
function M.show_top_spacing(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        local view = vim.fn.winsaveview()
        if view.topline == 1 and view.topfill == 0 then
          view.topfill = 1
          vim.fn.winrestview(view)
        end
      end)
    end
  end
end

return M
