-- Global keymaps. Leader mappings use Space; Ctrl shortcuts also work in terminal chat panes.

local map = function(mode, key, fn, desc)
  vim.keymap.set(mode, key, fn, { desc = desc })
end

local function fzf_open_tab()
  return require('config.tabs').open_from_fzf
end

local function find_project_files()
  require('fzf-lua').files({ actions = { ['enter'] = fzf_open_tab() } })
end

local function find_project_text()
  require('fzf-lua').live_grep({ actions = { ['enter'] = fzf_open_tab() } })
end

map({ 'n', 'i' }, '<D-p>', find_project_files, 'Find project files')
map('n', '<leader>ff', find_project_files, 'Find files')
map('n', '<leader>fg', find_project_text, 'Search project text')
map('n', '<leader>fb', function()
  require('fzf-lua').buffers()
end, 'Find open buffer')
map('n', '<leader>e', function()
  require('config.sidebar').toggle_files()
end, 'Toggle file tree')
map('n', '<leader>ac', '<cmd>Codex<cr>', 'Codex chat')
map('n', '<leader>au', '<cmd>CursorAgent<cr>', 'Cursor Agent chat')
map('n', '<leader>ag', '<cmd>Gemini<cr>', 'Gemini chat')
map('n', '<leader>al', '<cmd>Claude<cr>', 'Claude chat')
map('n', '<leader>ao', '<cmd>OpenCode<cr>', 'OpenCode chat')
map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', 'Project diagnostics')
map('n', '<leader>xd', vim.diagnostic.open_float, 'Line diagnostics')
local function git_in_editor(cmd)
  return function()
    require('config.tabs').focus()
    vim.cmd(cmd)
  end
end

map('n', '<leader>gs', git_in_editor('Git ++curwin'), 'Git status')
map('n', '<leader>gb', git_in_editor('Git ++curwin blame'), 'Git blame')
map('n', '<leader>gl', git_in_editor('Git ++curwin log --oneline'), 'Git history')
map('n', '<leader>gd', git_in_editor('Gdiffsplit'), 'Git diff')
map('n', '<leader>gp', function()
  require('gitsigns').preview_hunk()
end, 'Preview Git hunk')
map('n', '<leader>hs', function()
  require('gitsigns').stage_hunk()
end, 'Stage hunk')
map('n', '<leader>f', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, 'Format buffer')
map('n', '<leader>w', '<cmd>write<cr>', 'Save')
map('t', '<Esc><Esc>', '<C-\\><C-n>', 'Leave terminal input')

-- Let Neovim handle the click first, then make a clicked live chat writable.
-- Winbar clicks have no buffer line and must keep their own tab actions.
vim.keymap.set({ 'n', 'i' }, '<LeftMouse>', function()
  local pos = vim.fn.getmousepos()
  if pos.line > 0 and pos.winid ~= 0 then
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(pos.winid) or vim.api.nvim_get_current_win() ~= pos.winid then
        return
      end
      local buf = vim.api.nvim_win_get_buf(pos.winid)
      local agents = require('config.agents')
      local id = vim.b[buf].chat_id
      local session = agents.sessions[id]
      if id and (not session or session.exited) then
        agents.close(id)
      elseif session and vim.bo[buf].buftype == 'terminal' then
        vim.cmd.startinsert()
      end
    end)
  end
  return '<LeftMouse>'
end, { expr = true, desc = 'Focus clicked pane' })

for _, key in ipairs({ 'h', 'j', 'k', 'l' }) do
  map('n', '<C-' .. key .. '>', '<C-w>' .. key, 'Focus window')
end

map('n', '<F5>', function()
  require('dap').continue()
end, 'Debug continue/start')
map('n', '<F10>', function()
  require('dap').step_over()
end, 'Debug step over')
map('n', '<F11>', function()
  require('dap').step_into()
end, 'Debug step into')
map('n', '<F12>', function()
  require('dap').step_out()
end, 'Debug step out')
map('n', '<leader>db', function()
  require('dap').toggle_breakpoint()
end, 'Toggle breakpoint')
map('n', '<leader>du', function()
  require('dapui').toggle()
end, 'Toggle debugger UI')
map('n', '<leader>dq', function()
  require('dap').terminate()
end, 'Stop debugging')

-- Commands so the same actions work from normal, insert, and terminal mappings.
vim.api.nvim_create_user_command('ProjectCloseTab', function()
  require('config.tabs').close()
end, {})
vim.api.nvim_create_user_command('PaneNewTab', function()
  require('config.tabs').new_context()
end, {})
vim.api.nvim_create_user_command('PaneSave', function()
  require('config.tabs').save()
end, {})
vim.api.nvim_create_user_command('FindProjectFiles', find_project_files, {})
vim.api.nvim_create_user_command('FindProjectText', find_project_text, {})
vim.api.nvim_create_user_command('GitChanges', function()
  require('config.sidebar').git()
end, {})
vim.api.nvim_create_user_command('SidebarFilesToggle', function()
  require('config.sidebar').toggle_files()
end, {})
vim.api.nvim_create_user_command('SetupSettings', function()
  require('config.sidebar').settings()
end, {})
vim.api.nvim_create_user_command('SetupExtensions', function()
  require('config.sidebar').extensions()
end, {})
vim.api.nvim_create_user_command('CommandPalette', function()
  require('config.palette').open()
end, {})
vim.api.nvim_create_user_command('ContextMenu', function()
  require('config.context_menu').current()
end, {})

local shortcuts = {
  ['<C-s>'] = { 'PaneSave', 'Save editor file' },
  ['<C-b>'] = { 'SidebarFilesToggle', 'Toggle file tree' },
  ['<C-g>'] = { 'GitChanges', 'Show Git changes' },
  ['<C-,>'] = { 'SetupSettings', 'Open Settings' },
  ['<C-S-p>'] = { 'CommandPalette', 'Command palette' },
  ['<C-p>'] = { 'FindProjectFiles', 'Find project files' },
  ['<C-f>'] = { 'FindProjectText', 'Search project text' },
  ['<C-t>'] = { 'PaneNewTab', 'New editor or chat tab' },
  ['<C-w>'] = { 'ProjectCloseTab', 'Close current editor or chat tab' },
  ['<C-q>'] = { 'SessionQuit', 'Quit Neovim' },
  ['<C-]>'] = { 'AgentSelect', 'Choose a chat CLI' },
}
for key, binding in pairs(shortcuts) do
  map({ 'n', 'i' }, key, '<Cmd>' .. binding[1] .. '<CR>', binding[2])
  -- Leave terminal-input mode first so the command runs in the editor.
  map('t', key, '<C-\\><C-n><Cmd>' .. binding[1] .. '<CR>', binding[2])
end
map('n', '<leader>p', '<Cmd>CommandPalette<CR>', 'Command palette')
map('n', '<S-F10>', '<Cmd>ContextMenu<CR>', 'Context menu')

-- Ctrl+W is remapped above, so splits use leader instead of the window-command prefix.
map('n', '<leader>ws', '<Cmd>split<CR>', 'Split window below')
map('n', '<leader>wv', '<Cmd>vsplit<CR>', 'Split window right')

require('config.tabs')
require('config.icons')
