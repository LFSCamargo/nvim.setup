-- Headless plugin restore/upgrade used by scripts/plugins.sh.
-- Restore keeps the lockfile revisions; upgrade lets lazy.nvim advance them.

local manager = require('lazy.manage')
local config = require('lazy.core.config')

local function check_tasks()
  local failed = {}
  for name, plugin in pairs(config.plugins) do
    for _, task in ipairs(plugin._.tasks or {}) do
      if task:has_errors() then
        failed[#failed + 1] = name .. ': ' .. task:output()
      end
    end
    assert(vim.uv.fs_stat(plugin.dir), 'Plugin not installed: ' .. name)
  end
  assert(#failed == 0, table.concat(failed, '\n'))
end

local opts = { wait = true, show = false }
if vim.env.SETUP_PLUGIN_MODE == 'upgrade' then
  manager.sync(opts)
  check_tasks()
else
  -- install() rewrites the lockfile; keep the intended revisions for restore().
  local desired = vim.json.decode(table.concat(vim.fn.readfile(config.options.lockfile), '\n'))
  manager.install({ wait = true, show = false, lockfile = true })
  check_tasks()
  local lock = require('lazy.manage.lock')
  lock.lock, lock._loaded = vim.deepcopy(desired), true
  manager.restore(opts)
  check_tasks()
  for name, revision in pairs(desired) do
    local plugin = config.plugins[name]
    if plugin then
      local result = vim.system({ 'git', '-C', plugin.dir, 'rev-parse', 'HEAD' }, { text = true }):wait()
      assert(result.code == 0 and vim.trim(result.stdout) == revision.commit, 'Plugin revision mismatch: ' .. name)
    end
  end
end
print('Plugin installation complete')
vim.cmd('qa!')
