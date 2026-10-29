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

  request('nvim_set_current_win', editor)
  eval([[
    local session = require('config.session')
    local dir = session.dir()
    assert(dir:find('nvim-setup-sessions', 1, true), 'session dir should be under nvim-setup-sessions')
    assert(not dir:find(vim.fn.getcwd(), 1, true), 'session dir must hash cwd, not embed the path')
    vim.cmd.enew()
    local unnamed = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(unnamed, 0, -1, true, { 'unsaved hello' })
    local named_path = vim.fn.tempname()
    vim.fn.writefile({ 'original' }, named_path)
    vim.cmd.edit(vim.fn.fnameescape(named_path))
    local named = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(named, 0, -1, true, { 'changed' })
    assert(vim.bo[unnamed].modified, 'unnamed buffer should be modified before save')
    assert(vim.bo[named].modified, 'named buffer should be modified before save')
    assert(vim.api.nvim_buf_get_name(named) ~= '', 'named buffer should have a path')
    assert(session.save(), 'session save should succeed with a UI')
    local data = session.load()
    assert(data and data.editor and data.editor.tabs, 'session.json should list editor tabs')
    local found_unnamed, found_named
    for _, tab in ipairs(data.editor.tabs) do
      if tab.modified and tab.uuid and tab.path == '' then found_unnamed = tab end
      if tab.modified and tab.uuid and tab.path ~= '' then found_named = tab end
    end
    assert(found_unnamed and found_unnamed.uuid, 'modified unnamed buffer needs a snapshot uuid')
    assert(found_named and found_named.uuid, 'modified named buffer needs a snapshot uuid')
    vim.api.nvim_buf_delete(unnamed, { force = true })
    vim.api.nvim_buf_delete(named, { force = true })
    session.restore_editor(data)
    local restored_unnamed, restored_named
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
        if lines[1] == 'unsaved hello' then restored_unnamed = buf end
        if lines[1] == 'changed' then restored_named = buf end
      end
    end
    assert(restored_unnamed and vim.bo[restored_unnamed].modified, 'unnamed unsaved buffer should restore modified')
    assert(restored_named and vim.bo[restored_named].modified, 'named unsaved buffer should restore modified')
    local before = table.concat(vim.fn.readfile(session.file()), '\n')
    vim.env.NVIM_CLEAN = '1'
    assert(session.clean(), 'NVIM_CLEAN=1 should mark a clean launch')
    assert(session.restore() == false, 'clean launch must skip restore')
    local chats = vim.tbl_count(require('config.agents').sessions)
    session.save()
    assert(table.concat(vim.fn.readfile(session.file()), '\n') == before, 'clean launch must not clobber the session')
    assert(vim.tbl_count(require('config.agents').sessions) == chats, 'clean restore must not spawn chats')
    vim.env.NVIM_CLEAN = nil
  ]])

  eval("require('config.agents').new('codex', { uuid = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee' })")
  wait_for('codex resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/codex-args', 'r')
    if not f then return false end
    local args = f:read('*a')
    f:close()
    return args:find('resume aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee', 1, true)
  end)
  eval("require('config.agents').new('cursor', { uuid = '11111111-2222-4333-8444-555555555555' })")
  wait_for('agent resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/agent-args', 'r')
    if not f then return false end
    local args = f:read('*a')
    f:close()
    return args:find('--resume=11111111-2222-4333-8444-555555555555', 1, true)
  end)
  eval([[
    require('config.session').restore_chats({
      chats = {
        active = 1,
        sessions = {
          { name = 'codex', uuid = '99999999-aaaa-4bbb-8ccc-dddddddddddd', label = 'Codex saved' },
        },
      },
    })
  ]])
  wait_for('restored chat uuid', function()
    return eval([[
      local found = false
      for _, s in pairs(require('config.agents').sessions) do
        if s.uuid == '99999999-aaaa-4bbb-8ccc-dddddddddddd' then found = true end
      end
      return found
    ]])
  end)
  wait_for('restored codex resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/codex-args', 'r')
    if not f then return false end
    local args = f:read('*a')
    f:close()
    return args:find('resume 99999999-aaaa-4bbb-8ccc-dddddddddddd', 1, true)
  end)
  print('PASS: session persist, unsaved buffers, UUID resume and NVIM_CLEAN')

  request('nvim_input', '<C-q>')
  wait_for('Ctrl-Q quitting Neovim from terminal input', function()
    return exit_status ~= nil
  end)
  assert(exit_status == 0, 'Ctrl-Q should exit successfully')
end, debug.traceback)

pcall(request, 'nvim_command', 'qa!')
vim.fn.jobstop(child)
if not ok then error(err) end
