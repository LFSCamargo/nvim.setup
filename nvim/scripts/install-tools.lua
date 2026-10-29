-- Headless installer: install any Mason packages listed in config.tooling that are missing.
local names = require('config.tooling').packages
local registry = require('mason-registry')
registry.refresh(function()
  for _, name in ipairs(names) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      print('UNKNOWN ' .. name)
    elseif not pkg:is_installed() then
      pkg:once('install:success', function() print('INSTALLED ' .. name) end)
      pkg:once('install:failed', function() print('FAILED ' .. name) end)
      pkg:install()
    end
  end
end)
local ok = vim.wait(600000, function()
  for _, name in ipairs(names) do
    local found, pkg = pcall(registry.get_package, name)
    if not found or not pkg:is_installed() or pkg:is_installing() then return false end
  end
  return true
end, 500)
if not ok then
  for _, name in ipairs(names) do
    local found, pkg = pcall(registry.get_package, name)
    if not found or not pkg:is_installed() then print('MISSING ' .. name) end
  end
  vim.cmd('cquit 1')
end
vim.cmd.qa()
