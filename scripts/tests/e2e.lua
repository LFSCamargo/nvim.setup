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
  assert(eval([[
    local want = math.max(1, math.floor(vim.o.columns * 0.25))
    return vim.api.nvim_win_get_width(require('config.agents').win) == want
  ]]), 'chat pane should be 25% of the editor width')

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

  eval([[
    vim.cmd.cd(vim.fn.fnameescape(vim.env.E2E_DIR .. '/repo'))
    local tree_win
    package.loaded['nvim-tree.api'] = { tree = {
      close = function() if tree_win and vim.api.nvim_win_is_valid(tree_win) then vim.api.nvim_win_close(tree_win, true) end end,
      open = function()
        vim.cmd('topleft vsplit')
        tree_win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].filetype = 'NvimTree'
        vim.api.nvim_win_set_buf(tree_win, buf)
      end,
    } }
    local system = vim.system
    vim.system = function(_, _, cb) vim.defer_fn(function() cb({ code = 0, stdout = '/late\n' }) end, 300) end
    local sidebar = require('config.sidebar')
    sidebar.git()
    assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'):find('Loading', 1, true), 'loading indicator missing')
    sidebar.files()
    vim.system = system
  ]])
  vim.wait(500)
  assert(eval("return require('config.sidebar').view") == 'files', 'late Git result reopened the sidebar')
  eval("require('config.sidebar').git()")
  wait_for('Git changes', function()
    return eval([[
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'git-changes'
          and table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'):find('changed file.txt', 1, true) then
          return true
        end
      end
      return false
    ]])
  end)
  assert(eval([[
    local want = require('config.sidebar').width()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-changes' then
        return vim.api.nvim_win_get_width(win) == want and want == math.max(1, math.floor(vim.o.columns * 0.20))
      end
    end
    return false
  ]]), 'Git sidebar should be 20% of the editor width')
  assert(eval([[
    local want = require('config.sidebar').log_height()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-log' then
        return vim.api.nvim_win_get_height(win) == want and want == math.max(3, math.floor(vim.o.lines * 0.30))
      end
    end
    return false
  ]]), 'Git log pane should be 30% of the editor height')
  local function focus_git_list()
    eval([[
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-changes' then
          vim.api.nvim_set_current_win(win)
          return
        end
      end
      error('git list window missing')
    ]])
  end
  local function sidebar_text()
    focus_git_list()
    return eval("return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\\n')")
  end
  local function sidebar_line(label)
    focus_git_list()
    return eval(string.format([[
      local label = %s
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for i, line in ipairs(lines) do
        if line:find(label, 1, true) and (not line:find('Staged', 1, true) or label:find('Staged', 1, true)) then
          return i
        end
      end
      return 0
    ]], string.format('%q', label)))
  end
  local function focus_git_line(label)
    local line = sidebar_line(label)
    assert(line > 0, 'git line missing: ' .. label)
    eval('vim.api.nvim_win_set_cursor(0, { ' .. line .. ', 0 })')
    return line
  end
  local function log_text()
    return eval([[
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'git-log' then
          return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
        end
      end
      return ''
    ]])
  end
  local function focus_log()
    eval([[
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-log' then
          vim.api.nvim_set_current_win(win)
          return
        end
      end
      error('git log window missing')
    ]])
  end
  local function log_line(label)
    focus_log()
    return eval(string.format([[
      local label = %s
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for i, line in ipairs(lines) do
        if line:find(label, 1, true) then return i end
      end
      return 0
    ]], string.format('%q', label)))
  end
  local function focus_log_line(label)
    local line = log_line(label)
    assert(line > 0, 'git log line missing: ' .. label)
    eval('vim.api.nvim_win_set_cursor(0, { ' .. line .. ', 0 })')
    return line
  end
  local function click_sidebar(line, col)
    focus_git_list()
    local win = request('nvim_get_current_win')
    local sp = eval(string.format('return vim.fn.screenpos(%d, %d, %d)', win, line, math.max(col, 1)))
    request('nvim_input_mouse', 'left', 'press', '', 0, sp.row - 1, sp.col - 1)
    request('nvim_input_mouse', 'left', 'release', '', 0, sp.row - 1, sp.col - 1)
  end
  assert(sidebar_line('Staged Changes') > 0 and sidebar_line('deleted.txt') > 0 and sidebar_line('new.txt') > 0, 'Git sections or changes missing')
  wait_for('commit graph', function()
    local text = log_text()
    return log_line('COMMITS') > 0 and text:find('initial', 1, true) ~= nil
  end)
  local shown = sidebar_text()
  assert(not shown:find('Click', 1, true), 'mouse hint should not be shown')
  assert(shown:find('[Commit]', 1, true) and shown:find('Ctrl+Enter', 1, true), 'commit button missing')
  assert(shown:find('x revert', 1, true) and shown:find('i message', 1, true), 'keyboard helper text missing')
  assert(shown:find('[Stage All]', 1, true) and shown:find('[Revert All]', 1, true), 'bulk change actions missing')
  assert(eval([[
    local found = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-composer' then found = true end
    end
    return found
  ]]), 'commit message composer missing')
  assert(eval([[
    local marks = vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().GitChanges, 0, -1, { details = true })
    local seen = {}
    for _, mark in ipairs(marks) do seen[mark[4].hl_group] = true end
    return seen.GitChangeDeleted and seen.GitChangeModified and seen.GitChangeAdded
  ]]), 'change colors missing')
  click_sidebar(sidebar_line('Changes  ('), 2)
  wait_for('collapsing changes with mouse', function() return sidebar_line('changed file.txt') == 0 end)
  vim.wait(500)
  click_sidebar(sidebar_line('Changes  ('), 2)
  wait_for('expanding changes with mouse', function() return sidebar_line('changed file.txt') > 0 end)
  click_sidebar(sidebar_line('changed file.txt'), 2)
  wait_for('staging from Git sidebar', function()
    local result = vim.system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true }):wait()
    return result.stdout:find('changed file.txt', 1, true) ~= nil
  end)
  wait_for('Git sidebar refresh', function()
    return sidebar_text():find('M  changed file.txt', 1, true) ~= nil
  end)
  wait_for('Unstage All action', function() return sidebar_line('[Unstage All]') > 0 end)
  vim.wait(500)
  click_sidebar(sidebar_line('changed file.txt'), 2)
  wait_for('unstaging with mouse', function()
    local result = vim.system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true }):wait()
    return not result.stdout:find('changed file.txt', 1, true)
  end)
  wait_for('unstaged section refresh', function()
    return sidebar_text():find('+  M  changed file.txt', 1, true) ~= nil
  end)
  focus_git_line('changed file.txt')
  request('nvim_input', 's')
  wait_for('keyboard staging', function()
    local result = vim.system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true }):wait()
    return result.stdout:find('changed file.txt', 1, true) ~= nil
  end)
  wait_for('staged file after keyboard', function()
    return sidebar_text():find('M  changed file.txt', 1, true) ~= nil and sidebar_line('[Unstage All]') > 0
  end)
  focus_git_list()
  request('nvim_input', 'U')
  wait_for('unstage all', function()
    local result = vim.system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true }):wait()
    return result.stdout:find('changed file.txt', 1, true) == nil
  end)
  wait_for('changes restored after unstage all', function()
    return sidebar_text():find('+  M  changed file.txt', 1, true) ~= nil
  end)
  focus_git_line('new.txt')
  request('nvim_input', 's')
  wait_for('staging new file for commit', function()
    local result = vim.system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true }):wait()
    return result.stdout:find('new.txt', 1, true) ~= nil
  end)
  wait_for('staged new file in sidebar', function()
    return sidebar_line('[Unstage All]') > 0 and sidebar_text():find('new.txt', 1, true) ~= nil
  end)
  eval([[
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'git-composer' then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'e2e commit from sidebar' })
      end
    end
  ]])
  focus_git_list()
  request('nvim_input', 'C')
  wait_for('commit from Git sidebar', function()
    local result = vim.system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'log', '-1', '--pretty=%s' }, { text = true }):wait()
    return (result.stdout or ''):find('e2e commit from sidebar', 1, true) ~= nil
  end)
  wait_for('committed file leaving changes', function()
    local text = sidebar_text()
    return not text:find('Loading', 1, true) and sidebar_line('new.txt') == 0 and sidebar_line('changed file.txt') > 0
  end)
  wait_for('commit graph after sidebar commit', function()
    return log_text():find('e2e commit from sidebar', 1, true) ~= nil
  end)
  local function in_mid_editor()
    return eval([[
      local tabs = require('config.tabs')
      local win = vim.api.nvim_get_current_win()
      local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      return win == tabs.editor_win()
        and win ~= require('config.agents').win
        and ft ~= 'git-changes' and ft ~= 'git-log' and ft ~= 'git-composer' and ft ~= 'NvimTree'
    ]])
  end
  local function has_editor_tab()
    return eval([[
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if require('config.tabs').editor_buf(buf) then return true end
      end
      return false
    ]])
  end
  local wins_before_open = eval('return #vim.api.nvim_tabpage_list_wins(0)')
  focus_git_line('changed file.txt')
  request('nvim_input', '<CR>')
  wait_for('opening changed file', function()
    return eval("return vim.api.nvim_buf_get_name(0):find('changed file.txt', 1, true) ~= nil")
  end)
  assert(in_mid_editor(), 'git file should open in the mid editor')
  assert(eval('return #vim.api.nvim_tabpage_list_wins(0)') == wins_before_open, 'git file should reuse the mid editor, not split')
  eval("require('config.sidebar').git()")
  wait_for('Git sidebar after opening a file', function()
    return sidebar_line('changed file.txt') > 0 and log_text():find('e2e commit from sidebar', 1, true) ~= nil
  end)
  focus_log_line('e2e commit from sidebar')
  request('nvim_input', '<CR>')
  wait_for('opening a commit from the graph', function()
    return eval([[
      return vim.bo.filetype == 'git'
        and table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'):find('e2e commit from sidebar', 1, true) ~= nil
    ]])
  end)
  assert(in_mid_editor(), 'git commit should open in the mid editor')
  eval("require('config.sidebar').git()")
  wait_for('Git sidebar after showing a commit', function()
    return sidebar_line('changed file.txt') > 0
  end)
  focus_git_line('changed file.txt')
  request('nvim_input', '<CR>')
  wait_for('opening a file after a commit view', function()
    return eval("return vim.api.nvim_buf_get_name(0):find('changed file.txt', 1, true) ~= nil")
  end)
  assert(in_mid_editor(), 'git file after a commit view should open in the mid editor')
  eval('vim.cmd("quit")')
  wait_for('keeping the editor pane after :q', function()
    return eval("return require('config.tabs').editor_win() ~= nil") and has_editor_tab()
  end)
  eval([[
    local tabs = require('config.tabs')
    local win = tabs.ensure()
    local scratch = vim.api.nvim_create_buf(false, true)
    if win then vim.api.nvim_win_set_buf(win, scratch) end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if tabs.editor_buf(buf) then
        vim.bo[buf].modified = false
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  ]])
  wait_for('no editor tabs remaining', function()
    return not has_editor_tab()
  end)
  eval("require('config.sidebar').git()")
  wait_for('Git sidebar after closing editor tabs', function()
    return sidebar_line('changed file.txt') > 0
  end)
  focus_git_line('changed file.txt')
  request('nvim_input', '<CR>')
  wait_for('opening a file when no tabs remain', function()
    return eval("return vim.api.nvim_buf_get_name(0):find('changed file.txt', 1, true) ~= nil")
  end)
  assert(in_mid_editor(), 'git file should open in a new mid-editor tab')
  assert(has_editor_tab(), 'opening from git should add a tab when none remain')
  eval("require('config.sidebar').git()")
  wait_for('Git sidebar after opening a file with no tabs', function()
    return sidebar_line('changed file.txt') > 0
  end)
  request('nvim_input', 'i')
  wait_for('keyboard focus on commit message', function()
    return eval("return vim.bo[vim.api.nvim_get_current_buf()].filetype == 'git-composer'")
      and request('nvim_get_mode').mode == 'i'
  end)
  request('nvim_input', '<Esc>')
  wait_for('leaving commit message insert', function()
    local mode = request('nvim_get_mode').mode
    return mode ~= 'i' and mode ~= 't'
  end)
  eval("vim.fn.confirm = function() return 1 end")
  focus_git_line('changed file.txt')
  request('nvim_input', 'x')
  wait_for('reverting a changed file', function()
    local f = io.open(vim.env.E2E_DIR .. '/repo/changed file.txt', 'r')
    if not f then return false end
    local text = f:read('*a')
    f:close()
    return text == 'before\n'
  end)
  wait_for('reverted file leaving changes', function()
    local text = sidebar_text()
    return not text:find('Loading', 1, true) and sidebar_line('changed file.txt') == 0 and sidebar_line('deleted.txt') > 0
  end)
  eval("require('config.sidebar').files()")
  eval("require('config.tabs').focus()")
  print('PASS: asynchronous Git sidebar, switching, staging and opening files')


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
