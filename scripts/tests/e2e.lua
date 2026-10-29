-- Simulated UI e2e: spawn a child Neovim over RPC and drive mouse, focus, and Escape.
-- Fake `codex` / `agent` binaries (from scripts/e2e.sh) record input under E2E_DIR.

for _, rel in ipairs({ '/.luarc.json', '/nvim/.luarc.json' }) do
  local luarc = vim.json.decode(table.concat(vim.fn.readfile(vim.env.SETUP_ROOT .. rel), '\n'))
  assert(vim.tbl_contains(luarc.diagnostics.globals, 'vim'), rel .. ' must declare vim as a global')
end

local exit_status
local child = vim.fn.jobstart({
  vim.v.progpath, '--embed', '-n', '--cmd',
  'set runtimepath^=' .. vim.fn.fnameescape(vim.env.SETUP_ROOT .. '/nvim'),
  '-u', 'NONE', '-c', 'luafile ' .. vim.fn.fnameescape(vim.env.SETUP_ROOT .. '/scripts/tests/e2e-init.lua'),
}, { rpc = true, on_exit = function(_, status) exit_status = status end })
assert(child > 0, 'Could not start Neovim')

local function request(method, ...)
  return vim.rpcrequest(child, method, ...)
end

local function eval(code)
  return request('nvim_exec_lua', code, {})
end

local function wait_for(description, predicate)
  assert(vim.wait(5000, predicate, 20), 'Timed out waiting for ' .. description)
end

local ok, err = xpcall(function()
  request('nvim_ui_attach', 120, 40, { rgb = true })
  local visual = eval("return vim.api.nvim_get_hl(0, { name = 'Visual', link = false })")
  local normal = eval("return vim.api.nvim_get_hl(0, { name = 'Normal', link = false })")
  assert(visual.bg or visual.ctermbg or visual.reverse, 'Visual selection needs a background')
  assert(not normal.bg and not normal.ctermbg and not normal.reverse, 'Normal must stay transparent')
  wait_for('startup and chat sessions', function()
    return eval("local a = require('config.agents'); return vim.tbl_count(a.sessions) == 2 and a.win ~= nil")
  end)
  local chat = eval("return require('config.agents').win")
  local editor = request('nvim_get_current_win')
  assert(editor ~= chat, 'Startup should focus the editor')

  local function click(win)
    local pos = request('nvim_win_get_position', win)
    -- The first screen row is the winbar; click the content below it.
    request('nvim_input_mouse', 'left', 'press', '', 0, pos[1] + 2, pos[2] + 2)
    request('nvim_input_mouse', 'left', 'release', '', 0, pos[1] + 2, pos[2] + 2)
  end

  click(chat)
  wait_for('mouse focus and terminal input', function()
    return request('nvim_get_current_win') == chat and request('nvim_get_mode').mode == 't'
  end)

  -- Esc must reach the fake CLI as 0x1b and must not leave terminal-input mode.
  local function escape_reaches(name)
    request('nvim_input', '<Esc>')
    wait_for('Escape reaching ' .. name, function()
      local f = io.open(vim.env.E2E_DIR .. '/' .. name .. '-input', 'rb')
      if not f then return false end
      local input = f:read('*a')
      f:close()
      return input == '\27'
    end)
  end

  escape_reaches('codex')
  assert(request('nvim_get_mode').mode == 't', 'Escape left terminal input')
  click(editor)
  wait_for('mouse focus returning to editor', function()
    return request('nvim_get_current_win') == editor
  end)
  click(chat)
  wait_for('mouse focus returning to chat', function()
    return request('nvim_get_current_win') == chat and request('nvim_get_mode').mode == 't'
  end)
  request('nvim_input', '<C-\\><C-n>')
  wait_for('leaving terminal input', function() return request('nvim_get_mode').mode ~= 't' end)
  vim.wait(600)
  click(chat)
  wait_for('clicking the current chat restores input', function()
    return request('nvim_get_mode').mode == 't'
  end)
  eval("require('config.agents').show(2)")
  wait_for('second chat input', function()
    return eval("return vim.b.chat_id") == 2 and request('nvim_get_mode').mode == 't'
  end)
  escape_reaches('agent')
  print('PASS: local chat config, mouse focus, Escape delivery and terminal mode')

  request('nvim_input', '<C-q>')
  wait_for('Ctrl-Q quitting Neovim from terminal input', function()
    return exit_status ~= nil
  end)
  assert(exit_status == 0, 'Ctrl-Q should exit successfully')
end, debug.traceback)

pcall(request, 'nvim_command', 'qa!')
vim.fn.jobstop(child)
if not ok then error(err) end
