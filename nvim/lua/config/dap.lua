local dap, ui = require('dap'), require('dapui')
ui.setup()
dap.listeners.after.event_initialized['ui'] = function() ui.open() end
dap.listeners.before.event_terminated['ui'] = function() ui.close() end
dap.listeners.before.event_exited['ui'] = function() ui.close() end
local packages = vim.fn.stdpath('data') .. '/mason/packages/'
dap.adapters['pwa-node'] = { type = 'server', host = '127.0.0.1', port = '${port}', executable = { command = 'node', args = { packages .. 'js-debug-adapter/js-debug/src/dapDebugServer.js', '${port}', '127.0.0.1' } } }
dap.adapters['pwa-chrome'] = dap.adapters['pwa-node']
for _, ft in ipairs({ 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue' }) do
  dap.configurations[ft] = {
    { name = 'Launch current file (Node)', type = 'pwa-node', request = 'launch', program = '${file}', cwd = '${workspaceFolder}', sourceMaps = true, console = 'integratedTerminal' },
    { name = 'Attach to Node (--inspect)', type = 'pwa-node', request = 'attach', processId = require('dap.utils').pick_process, cwd = '${workspaceFolder}', sourceMaps = true },
    { name = 'Browser (Chrome --remote-debugging-port=9222)', type = 'pwa-chrome', request = 'attach', port = 9222, webRoot = '${workspaceFolder}', sourceMaps = true },
  }
end
require('dap-go').setup({ delve = { path = vim.fn.stdpath('data') .. '/mason/bin/dlv' } })
dap.adapters.codelldb = { type = 'server', port = '${port}', executable = { command = packages .. 'codelldb/extension/adapter/codelldb', args = { '--port', '${port}' } } }
dap.configurations.rust = { { name = 'Debug compiled Rust binary', type = 'codelldb', request = 'launch', program = function() return vim.fn.input('Binary: ', vim.fn.getcwd() .. '/target/debug/', 'file') end, cwd = '${workspaceFolder}', stopOnEntry = false } }
-- Per-project .vscode/launch.json configurations are read explicitly, avoiding startup execution.
vim.api.nvim_create_user_command('DebugLoadLaunch', function() require('dap.ext.vscode').load_launchjs(nil, { ['pwa-node'] = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' }, node = { 'javascript', 'typescript' } }) end, {})
