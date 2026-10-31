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

return M
