local M = {}

function M.specs()
  local specs = vim.list_extend({}, require('modules.plugins.ui'))
  vim.list_extend(specs, require('modules.plugins.tools'))
  return vim.list_extend(specs, require('modules.extensions').specs())
end

return M
