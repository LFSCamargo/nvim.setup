-- Simulated UI e2e: spawn a child Neovim over RPC and drive mouse, focus, and Escape.
-- Fake chat CLI binaries (from scripts/e2e.sh) record input under E2E_DIR.

for _, rel in ipairs({ '/.luarc.json', '/nvim/.luarc.json' }) do
  local luarc = vim.json.decode(table.concat(vim.fn.readfile(vim.env.SETUP_ROOT .. rel), '\n'))
  assert(vim.tbl_contains(luarc.diagnostics.globals, 'vim'), rel .. ' must declare vim as a global')
end

local exit_status
local child = vim.fn.jobstart({
  vim.v.progpath,
  '--embed',
  '-n',
  '--cmd',
  'set runtimepath^=' .. vim.fn.fnameescape(vim.env.SETUP_ROOT .. '/nvim'),
  '-u',
  'NONE',
  '-c',
  'luafile ' .. vim.fn.fnameescape(vim.env.SETUP_ROOT .. '/scripts/tests/e2e-init.lua'),
}, {
  rpc = true,
  on_exit = function(_, status)
    exit_status = status
  end,
})
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
  assert(
    eval([[
    local want = math.max(1, math.floor(vim.o.columns * 0.25))
    return vim.api.nvim_win_get_width(require('config.agents').win) == want
  ]]),
    'chat pane should be 25% of the editor width'
  )

  local function statusline()
    return eval([[
      vim.cmd('redrawstatus')
      return vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true }).str
    ]])
  end
  assert(eval('return vim.o.laststatus') == 3, 'statusline should be one global bar')
  assert(eval('return vim.o.showmode') == false, 'mode text should live in the statusline')
  local mode_hl = eval("return vim.api.nvim_get_hl(0, { name = 'SLModeNormal', link = false })")
  local insert_hl = eval("return vim.api.nvim_get_hl(0, { name = 'SLModeInsert', link = false })")
  local bar_hl = eval("return vim.api.nvim_get_hl(0, { name = 'StatusLine', link = false })")
  local function hl_hex(hl)
    local bg = hl.bg or hl.ctermbg
    assert(bg, 'mode highlight needs a fill')
    return string.format('#%06x', bg)
  end
  assert(hl_hex(mode_hl) == '#d79921', 'NORMAL should be faded Gruvbox yellow, got ' .. hl_hex(mode_hl))
  assert(hl_hex(insert_hl) == '#cc241d', 'INSERT should be faded Gruvbox red, got ' .. hl_hex(insert_hl))
  local tab_hl = eval("return vim.api.nvim_get_hl(0, { name = 'PaneTabActive', link = false })")
  local tab_fg = tab_hl.fg or tab_hl.ctermfg
  assert(tab_fg, 'active tab needs a foreground')
  assert(
    string.format('#%06x', tab_fg) == '#d79921',
    'active tab should be faded Gruvbox yellow, got ' .. string.format('#%06x', tab_fg)
  )
  assert(bar_hl.bg or bar_hl.ctermbg, 'statusline bar needs a fill')
  local stl = statusline()
  assert(stl:find('NORMAL', 1, true), 'statusline should show NORMAL, got: ' .. stl)
  assert(not stl:find('utf%-8'), 'default utf-8 should stay off the statusline: ' .. stl)
  request('nvim_input', 'i')
  wait_for('insert mode for statusline', function()
    return request('nvim_get_mode').mode == 'i'
  end)
  stl = statusline()
  assert(stl:find('INSERT', 1, true), 'statusline should show INSERT, got: ' .. stl)
  request('nvim_input', '<Esc>')
  wait_for('normal mode after statusline insert', function()
    local mode = request('nvim_get_mode').mode
    return mode ~= 'i' and mode ~= 't'
  end)
  local rich = eval([[
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local saved = {
      modified = vim.bo[buf].modified,
      fenc = vim.bo[buf].fileencoding,
      ff = vim.bo[buf].fileformat,
      et = vim.bo[buf].expandtab,
      ts = vim.bo[buf].tabstop,
      sw = vim.bo[buf].shiftwidth,
      ft = vim.bo[buf].filetype,
      head = vim.b[buf].gitsigns_head,
      dict = vim.b[buf].gitsigns_status_dict,
    }
    vim.bo[buf].filetype = 'lua'
    vim.bo[buf].modified = true
    vim.bo[buf].fileencoding = 'latin1'
    vim.bo[buf].fileformat = 'dos'
    vim.bo[buf].expandtab = false
    vim.bo[buf].tabstop = 4
    vim.bo[buf].shiftwidth = 4
    vim.b[buf].gitsigns_head = 'feature'
    vim.b[buf].gitsigns_status_dict = { head = 'feature', added = 3, changed = 1, removed = 2 }
    local ns = vim.api.nvim_create_namespace('e2e-stl')
    vim.diagnostic.set(ns, buf, {
      { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = 'boom' },
      { lnum = 0, col = 1, severity = vim.diagnostic.severity.WARN, message = 'careful' },
    })
    vim.cmd('redrawstatus')
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true, winid = win }).str
    vim.diagnostic.reset(ns, buf)
    vim.bo[buf].modified = saved.modified
    vim.bo[buf].fileencoding = saved.fenc
    vim.bo[buf].fileformat = saved.ff
    vim.bo[buf].expandtab = saved.et
    vim.bo[buf].tabstop = saved.ts
    vim.bo[buf].shiftwidth = saved.sw
    vim.bo[buf].filetype = saved.ft
    vim.b[buf].gitsigns_head = saved.head
    vim.b[buf].gitsigns_status_dict = saved.dict
    return text
  ]])
  for _, needle in ipairs({
    'feature',
    '+3',
    '~1',
    '-2',
    'E:1',
    'W:1',
    'latin1',
    'CRLF',
    'tabs:4',
    'lua',
    '●',
    '[New]',
  }) do
    assert(rich:find(needle, 1, true), 'statusline missing ' .. needle .. ': ' .. rich)
  end
  local pct = eval([[
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, vim.env.E2E_DIR .. '/100%.lua')
    local prev = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_win_set_buf(win, buf)
    vim.cmd('redrawstatus')
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true, winid = win }).str
    vim.api.nvim_win_set_buf(win, prev)
    vim.api.nvim_buf_delete(buf, { force = true })
    return text
  ]])
  assert(pct:find('100%.lua', 1, true), 'statusline should escape % in filenames: ' .. pct)
  local files = eval([[
    local win = vim.api.nvim_get_current_win()
    local prev = vim.api.nvim_win_get_buf(win)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = 'NvimTree'
    vim.api.nvim_win_set_buf(win, buf)
    vim.cmd('redrawstatus')
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true, winid = win }).str
    vim.api.nvim_win_set_buf(win, prev)
    vim.api.nvim_buf_delete(buf, { force = true })
    return text
  ]])
  assert(files:find('Files', 1, true), 'statusline should name the Files tree: ' .. files)
  local chat_stl = eval([[
    local win = require('config.agents').win
    local prev = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(win)
    vim.cmd.stopinsert()
    vim.cmd('redrawstatus')
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true, winid = win }).str
    vim.api.nvim_set_current_win(prev)
    vim.cmd.stopinsert()
    return text
  ]])
  assert(
    chat_stl:find('Codex', 1, true) or chat_stl:find('Agent', 1, true),
    'statusline should name the chat session: ' .. chat_stl
  )
  local search = eval([[
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local prev_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'foo', 'foo', 'bar' })
    vim.fn.setreg('/', 'foo')
    vim.opt.hlsearch = true
    vim.fn.search('foo', 'c')
    vim.fn.searchcount({ recompute = true })
    vim.cmd('redrawstatus')
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true, winid = win }).str
    vim.opt.hlsearch = false
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, prev_lines)
    vim.bo[buf].modified = false
    return text
  ]])
  assert(search:find('1/2', 1, true), 'statusline should show search matches: ' .. search)
  print('PASS: colorful statusline with mode, git, diagnostics, and file info')

  local formatters = eval('return require("config.format").formatters_by_ft')
  assert(
    formatters.lua[1] == 'stylua',
    'Lua should format with StyLua, got: ' .. tostring(formatters.lua and formatters.lua[1])
  )
  assert(formatters.html[1] == 'prettierd', 'HTML should format with prettierd')
  assert(formatters.markdown[1] == 'prettierd', 'Markdown should format with prettierd')
  assert(formatters.sh[1] == 'shfmt', 'shell should format with shfmt')
  print('PASS: Space f formatters cover Lua, web, markdown, and shell')

  local tabs = eval([[
    local win = vim.api.nvim_get_current_win()
    local prev = vim.api.nvim_win_get_buf(win)
    local a = vim.api.nvim_create_buf(true, false)
    local b = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(a, vim.env.E2E_DIR .. '/one.lua')
    vim.api.nvim_buf_set_name(b, vim.env.E2E_DIR .. '/two.lua')
    vim.bo[a].modified = false
    vim.bo[b].modified = false
    vim.api.nvim_set_hl(0, 'DevIconTest', { fg = 0x83a598 })
    vim.api.nvim_win_set_buf(win, a)
    vim.cmd('redrawstatus')
    local bar = vim.api.nvim_eval_statusline(
      vim.api.nvim_get_option_value('winbar', { win = win }),
      { use_winbar = true, winid = win }
    ).str
    local files = vim.api.nvim_eval_statusline(require('config.sidebar').winbar(), { use_winbar = true }).str
    local chat = require('config.agents').win
    local chat_bar = vim.api.nvim_eval_statusline(
      vim.api.nvim_get_option_value('winbar', { win = chat }),
      { use_winbar = true, winid = chat }
    ).str
    local vert = vim.opt.fillchars:get().vert
    if type(vert) ~= 'string' or vert == '' then vert = '│' end
    local function hex(hl, key)
      local n = hl[key]
      return n and string.format('#%06x', n) or nil
    end
    local wb = vim.api.nvim_get_hl(0, { name = 'WinBar', link = false })
    local sep = vim.api.nvim_get_hl(0, { name = 'PaneTabSep', link = false })
    local active = vim.api.nvim_get_hl(0, { name = 'PaneTabActive', link = false })
    local inactive = vim.api.nvim_get_hl(0, { name = 'PaneTabInactive', link = false })
    local icon_hl = vim.api.nvim_get_hl(0, { name = 'PaneTabIconDevIconTest', link = false })
    local needle = 'two.lua ×'
    local i = bar:find(needle, 1, true)
    local close_col = i and vim.fn.strdisplaywidth(bar:sub(1, i + #'two.lua ' - 1)) or -1
    return {
      bar = bar,
      files = files,
      chat_bar = chat_bar,
      vert = vert,
      winbar_ul = not not wb.underline,
      sep_ul = not not sep.underline,
      fill = hex(wb, 'bg'),
      sep_fill = hex(sep, 'bg'),
      active_fill = hex(active, 'bg'),
      inactive_fill = hex(inactive, 'bg'),
      icon_fill = hex(icon_hl, 'bg'),
      icon_fg = hex(icon_hl, 'fg'),
      close_col = close_col,
      prev = prev,
      one = a,
      two = b,
      win = win,
    }
  ]])
  assert(
    tabs.bar:find('L one.lua ×', 1, true) and tabs.bar:find('L two.lua ×', 1, true),
    'tab bar should look like icon name × │ icon name × │ + │, got: ' .. tabs.bar
  )
  assert(tabs.bar:find(tabs.vert, 1, true), 'tab bar should use pane dividers, got: ' .. tabs.bar)
  local plus = tabs.bar:find('+', 1, true)
  assert(plus, 'tab bar should keep +: ' .. tabs.bar)
  assert(not tabs.bar:sub(plus):find('×', 1, true), '× should sit inside each tab, not after +: ' .. tabs.bar)
  assert(
    tabs.files:find('Files', 1, true) and tabs.files:find('Git', 1, true) and tabs.files:find('Settings', 1, true),
    'Files/Git/Settings winbar missing labels: ' .. tabs.files
  )
  assert(tabs.files:find(tabs.vert, 1, true), 'Files/Git winbar should use pane dividers, got: ' .. tabs.files)
  assert(not tabs.files:find('×', 1, true), 'Files/Git tabs should not have close: ' .. tabs.files)
  assert(
    tabs.chat_bar:find('+', 1, true) and tabs.chat_bar:find('×', 1, true),
    'chat tab bar should keep + and in-tab ×: ' .. tabs.chat_bar
  )
  local chat_plus = tabs.chat_bar:find('+', 1, true)
  assert(
    not tabs.chat_bar:sub(chat_plus):find('×', 1, true),
    'chat × should sit inside each tab, not after +: ' .. tabs.chat_bar
  )
  assert(not tabs.winbar_ul and not tabs.sep_ul, 'tab bar should not use a bright underline')
  assert(
    not tabs.fill and not tabs.sep_fill and not tabs.active_fill and not tabs.inactive_fill,
    'tab bar should stay transparent, got ' .. tostring(tabs.fill)
  )
  assert(
    not tabs.icon_fill and tabs.icon_fg == '#83a598',
    'tab Devicons should keep type color without a fill, got '
      .. tostring(tabs.icon_fg)
      .. ' / '
      .. tostring(tabs.icon_fill)
  )
  assert(tabs.close_col >= 0, 'tab bar should expose × on two.lua: ' .. tabs.bar)

  local tab_pos = request('nvim_win_get_position', tabs.win)
  request('nvim_input_mouse', 'left', 'press', '', 0, tab_pos[1], tab_pos[2] + tabs.close_col)
  request('nvim_input_mouse', 'left', 'release', '', 0, tab_pos[1], tab_pos[2] + tabs.close_col)
  wait_for('clicking × on two.lua to close that tab', function()
    return eval(string.format(
      [[
      local two, one = %d, %d
      return not vim.api.nvim_buf_is_valid(two)
        and vim.api.nvim_buf_is_valid(one)
        and vim.api.nvim_win_get_buf(%d) == one
    ]],
      tabs.two,
      tabs.one,
      tabs.win
    ))
  end)
  eval(string.format(
    [[
    local prev, one, two, win = %d, %d, %d, %d
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(prev) then
      vim.api.nvim_win_set_buf(win, prev)
    end
    for _, buf in ipairs({ one, two }) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].modified = false
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  ]],
    tabs.prev,
    tabs.one,
    tabs.two,
    tabs.win
  ))
  print('PASS: tab bar uses in-tab ×, pane dividers, and a horizontal rule')

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
      if not f then
        return false
      end
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
  wait_for('leaving terminal input', function()
    return request('nvim_get_mode').mode ~= 't'
  end)
  vim.wait(600)
  click(chat)
  wait_for('clicking the current chat restores input', function()
    return request('nvim_get_mode').mode == 't'
  end)
  eval("require('config.agents').show(2)")
  wait_for('second chat input', function()
    return eval('return vim.b.chat_id') == 2 and request('nvim_get_mode').mode == 't'
  end)
  escape_reaches('agent')
  print('PASS: local chat config, mouse focus, Escape delivery and terminal mode')

  -- Process exit (Ctrl+C in the CLI) must close that chat tab, not leave "(exited)".
  local closed_id = eval("return require('config.agents').active")
  local closed_buf = eval(string.format('return require("config.agents").sessions[%d].buf', closed_id))
  eval(string.format('vim.fn.jobstop(require("config.agents").sessions[%d].job)', closed_id))
  wait_for('exited agent chat tab to close', function()
    return eval(string.format(
      [[
      local a = require('config.agents')
      return a.sessions[%d] == nil
        and not vim.api.nvim_buf_is_valid(%d)
        and vim.tbl_count(a.sessions) == 1
        and a.win ~= nil
        and vim.api.nvim_win_is_valid(a.win)
        and a.active ~= %d
        and a.sessions[a.active] ~= nil
        and vim.api.nvim_win_get_buf(a.win) == a.sessions[a.active].buf
    ]],
      closed_id,
      closed_buf,
      closed_id
    ))
  end)
  print('PASS: agent process exit closes the chat tab')

  eval("require('config.agents').new('cursor')")
  wait_for('extra agent tab', function()
    return eval('return vim.tbl_count(require("config.agents").sessions) == 2')
  end)
  local leftover_id = eval("return require('config.agents').active")
  local leftover_buf = eval(string.format('return require("config.agents").sessions[%d].buf', leftover_id))
  eval(string.format('require("config.agents").sessions[%d].exited = true', leftover_id))
  eval(string.format('require("config.agents").show(%d)', leftover_id))
  wait_for('clicking an exited chat tab to close it', function()
    return eval(string.format(
      [[
      local a = require('config.agents')
      return a.sessions[%d] == nil and not vim.api.nvim_buf_is_valid(%d)
    ]],
      leftover_id,
      leftover_buf
    ))
  end)
  print('PASS: clicking an exited chat tab closes it')

  eval("require('config.agents').new('cursor')")
  wait_for('orphan agent tab', function()
    return eval('return vim.tbl_count(require("config.agents").sessions) >= 2')
  end)
  local orphan_id = eval("return require('config.agents').active")
  local orphan_buf = eval(string.format('return require("config.agents").sessions[%d].buf', orphan_id))
  eval(string.format(
    [[
    local a = require('config.agents')
    local id, buf = %d, %d
    a.sessions[id].exited = true
    a.sessions[id] = nil
    vim.api.nvim_set_current_win(a.win)
    vim.api.nvim_win_set_buf(a.win, buf)
    vim.cmd.startinsert()
  ]],
    orphan_id,
    orphan_buf
  ))
  request('nvim_input', '<C-w>')
  wait_for('Ctrl-W to close an orphan exited chat', function()
    return eval(string.format('return not vim.api.nvim_buf_is_valid(%d)', orphan_buf))
  end)
  print('PASS: Ctrl-W closes a leftover exited chat tab')

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
    assert(vim.o.swapfile == false, 'swapfile must stay off so ATTENTION does not interrupt session restore')
    assert(vim.bo[unnamed].swapfile == false, 'unnamed editor buffers must not create swap files')
    assert(vim.bo[named].swapfile == false, 'named editor buffers must not create swap files')
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
    assert(vim.o.swapfile == false, 'session restore must leave swapfile off')
    assert(vim.bo[restored_unnamed].swapfile == false, 'restored unnamed buffers must not create swap files')
    assert(vim.bo[restored_named].swapfile == false, 'restored named buffers must not create swap files')
    local before = table.concat(vim.fn.readfile(session.file()), '\n')
    vim.env.NVIM_CLEAN = '1'
    assert(session.clean(), 'NVIM_CLEAN=1 should mark a clean launch')
    assert(session.restore() == false, 'clean launch must skip restore')
    assert(vim.o.swapfile == false, 'clean launch must still disable swap files')
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
    package.loaded['nvim-web-devicons'] = package.loaded['nvim-web-devicons'] or {
      setup = function() end,
      get_icon = function(_, ext)
        local icons = { txt = 'T', ts = 'S', rs = 'R' }
        return icons[ext or ''] or 'F', 'DevIconTest'
      end,
    }
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
  assert(
    eval([[
    local want = require('config.sidebar').width()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-changes' then
        return vim.api.nvim_win_get_width(win) == want and want == math.max(1, math.floor(vim.o.columns * 0.20))
      end
    end
    return false
  ]]),
    'Git sidebar should be 20% of the editor width'
  )
  assert(
    eval([[
    local want = require('config.sidebar').log_height()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-log' then
        return vim.api.nvim_win_get_height(win) == want and want == math.max(3, math.floor(vim.o.lines * 0.30))
      end
    end
    return false
  ]]),
    'Git log pane should be 30% of the editor height'
  )
  local gen = eval("return require('config.sidebar').generation")
  eval("require('config.sidebar').git()")
  assert(eval("return require('config.sidebar').generation") > gen, 'clicking Git should refresh')
  wait_for('Git sidebar after focusing Git', function()
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
  gen = eval("return require('config.sidebar').generation")
  eval([[
    local win = require('config.tabs').editor_win()
    if win then vim.api.nvim_set_current_win(win) end
  ]])
  eval([[
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-changes' then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    error('git list window missing')
  ]])
  wait_for('Git sidebar refresh after focusing from the editor', function()
    return eval("return require('config.sidebar').generation") > gen
  end)
  wait_for('Git changes after focusing the git list', function()
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
    return eval(string.format(
      [[
      local label = %s
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for i, line in ipairs(lines) do
        if line:find(label, 1, true) and (not line:find('Staged', 1, true) or label:find('Staged', 1, true)) then
          return i
        end
      end
      return 0
    ]],
      string.format('%q', label)
    ))
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
    return eval(string.format(
      [[
      local label = %s
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for i, line in ipairs(lines) do
        if line:find(label, 1, true) then return i end
      end
      return 0
    ]],
      string.format('%q', label)
    ))
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
  assert(
    sidebar_line('Staged Changes') > 0 and sidebar_line('deleted.txt') > 0 and sidebar_line('new.txt') > 0,
    'Git sections or changes missing'
  )
  wait_for('commit graph', function()
    local text = log_text()
    return log_line('COMMITS') > 0 and text:find('initial', 1, true) ~= nil
  end)
  local shown = sidebar_text()
  local function tree_icons_safe()
    return eval([[
      local function folder_ok(icons)
        -- nvim-tree/node/directory.lua:210 indexes web_devicons.folder.enable
        return icons.show.file == true and icons.show.folder == true
          and icons.show.folder_arrow == true
          and type(icons.padding) == 'table'
          and icons.padding.icon == ' '
          and icons.web_devicons.file.enable == true
          and icons.web_devicons.file.color == true
          and icons.web_devicons.folder.enable == false
          and icons.web_devicons.folder.color == false
          and icons.glyphs.folder.arrow_closed == '>'
          and icons.glyphs.folder.arrow_open == 'v'
          and type(icons.glyphs.folder.default) == 'string'
          and type(icons.glyphs.folder.open) == 'string'
      end
      local icons = require('config.icons')
      if not folder_ok(icons.tree_icons()) then return false end
      local live = package.loaded['nvim-tree.config']
      local drawn = live and live.g and live.g.renderer and live.g.renderer.icons
      return drawn and type(drawn.web_devicons.folder.enable) == 'boolean'
    ]])
  end
  assert(tree_icons_safe(), 'Files sidebar should show colored file type icons')
  assert(
    eval("return require('config.sidebar').tree_setup().renderer.highlight_git") == 'name',
    'Files tree should color names from git status, not icons'
  )
  assert(
    eval("return require('config.sidebar').tree_setup().renderer.root_folder_label") == false,
    'Files tree should not show the project path/.. root label'
  )
  assert(
    eval("return require('config.sidebar').tree_setup().renderer.highlight_opened_files") == 'none',
    'opened files should not get a non-git color'
  )
  assert(
    eval([[
    local function hex(hl)
      local fg = hl.fg or hl.ctermfg
      return fg and string.format('#%06x', fg) or nil
    end
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
    local special = vim.api.nvim_get_hl(0, { name = 'NvimTreeSpecialFile', link = false })
    local ignored = vim.api.nvim_get_hl(0, { name = 'NvimTreeGitFileIgnoredHL', link = false })
    local dirty = vim.api.nvim_get_hl(0, { name = 'NvimTreeGitFileDirtyHL', link = false })
    return hex(special) == hex(normal)
      and hex(ignored) == hex(normal)
      and not special.underline
      and hex(dirty) == '#d79921'
  ]]),
    'unmodified Files entries should be Normal; git dirty should be faded yellow'
  )
  assert(
    eval([[
    local found_icon, found_git = false, false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'git-changes' then
        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
          local hl = mark[4] and mark[4].hl_group
          if type(hl) == 'string' and hl:find('DevIcon', 1, true) then found_icon = true end
          if type(hl) == 'string' and hl:find('GitChange', 1, true) then found_git = true end
        end
      end
    end
    return found_icon and found_git
  ]]),
    'Git sidebar should color icons by file type and names by git status'
  )
  assert(
    eval([[
    for _, range in ipairs(vim.fn.getcellwidths()) do
      if range[1] <= 0xF07B and range[2] >= 0xF07B and range[3] == 2 then return false end
    end
    return true
  ]]),
    'Devicons should occupy one cell so they do not overlap filenames'
  )
  assert(
    shown:find('T changed file.txt', 1, true)
      and shown:find('T deleted.txt', 1, true)
      and shown:find('T new.txt', 1, true),
    'txt icon missing in Git'
  )
  assert(shown:find('S app.ts', 1, true) and shown:find('R lib.rs', 1, true), 'extension icons missing in Git')
  assert(
    not shown:find('S lib.rs', 1, true) and not shown:find('R app.ts', 1, true),
    'Git file icons should follow the extension'
  )
  assert(not shown:find('Click', 1, true), 'mouse hint should not be shown')
  assert(shown:find('[Commit]', 1, true) and shown:find('Ctrl+Enter', 1, true), 'commit button missing')
  assert(shown:find('x revert', 1, true) and shown:find('i message', 1, true), 'keyboard helper text missing')
  assert(shown:find('[Stage All]', 1, true) and shown:find('[Revert All]', 1, true), 'bulk change actions missing')
  assert(
    eval([[
    local found = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'git-composer' then found = true end
    end
    return found
  ]]),
    'commit message composer missing'
  )
  assert(
    eval([[
    local marks = vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().GitChanges, 0, -1, { details = true })
    local seen = {}
    for _, mark in ipairs(marks) do seen[mark[4].hl_group] = true end
    return seen.GitChangeDeleted and seen.GitChangeModified and seen.GitChangeAdded
  ]]),
    'change colors missing'
  )
  click_sidebar(sidebar_line('Changes  ('), 2)
  wait_for('collapsing changes with mouse', function()
    return sidebar_line('changed file.txt') == 0
  end)
  vim.wait(500)
  click_sidebar(sidebar_line('Changes  ('), 2)
  wait_for('expanding changes with mouse', function()
    return sidebar_line('changed file.txt') > 0
  end)
  click_sidebar(sidebar_line('changed file.txt'), 2)
  wait_for('staging from Git sidebar', function()
    local result = vim
      .system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true })
      :wait()
    return result.stdout:find('changed file.txt', 1, true) ~= nil
  end)
  wait_for('Git sidebar refresh', function()
    return sidebar_text():find('M  T changed file.txt', 1, true) ~= nil
  end)
  wait_for('Unstage All action', function()
    return sidebar_line('[Unstage All]') > 0
  end)
  vim.wait(500)
  click_sidebar(sidebar_line('changed file.txt'), 2)
  wait_for('unstaging with mouse', function()
    local result = vim
      .system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true })
      :wait()
    return not result.stdout:find('changed file.txt', 1, true)
  end)
  wait_for('unstaged section refresh', function()
    return sidebar_text():find('+  M  T changed file.txt', 1, true) ~= nil
  end)
  focus_git_line('changed file.txt')
  request('nvim_input', 's')
  wait_for('keyboard staging', function()
    local result = vim
      .system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true })
      :wait()
    return result.stdout:find('changed file.txt', 1, true) ~= nil
  end)
  wait_for('staged file after keyboard', function()
    return sidebar_text():find('M  T changed file.txt', 1, true) ~= nil and sidebar_line('[Unstage All]') > 0
  end)
  focus_git_list()
  request('nvim_input', 'U')
  wait_for('unstage all', function()
    local result = vim
      .system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true })
      :wait()
    return result.stdout:find('changed file.txt', 1, true) == nil
  end)
  wait_for('changes restored after unstage all', function()
    return sidebar_text():find('+  M  T changed file.txt', 1, true) ~= nil
  end)
  focus_git_line('new.txt')
  request('nvim_input', 's')
  wait_for('staging new file for commit', function()
    local result = vim
      .system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'diff', '--cached', '--name-only' }, { text = true })
      :wait()
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
    local result = vim
      .system({ 'git', '-C', vim.env.E2E_DIR .. '/repo', 'log', '-1', '--pretty=%s' }, { text = true })
      :wait()
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
        and ft ~= 'git-changes' and ft ~= 'git-log' and ft ~= 'git-composer' and ft ~= 'NvimTree' and ft ~= 'setup-settings'
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
  assert(
    eval('return #vim.api.nvim_tabpage_list_wins(0)') == wins_before_open,
    'git file should reuse the mid editor, not split'
  )
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
  eval('vim.fn.confirm = function() return 1 end')
  focus_git_line('changed file.txt')
  request('nvim_input', 'x')
  wait_for('reverting a changed file', function()
    local f = io.open(vim.env.E2E_DIR .. '/repo/changed file.txt', 'r')
    if not f then
      return false
    end
    local text = f:read('*a')
    f:close()
    return text == 'before\n'
  end)
  wait_for('reverted file leaving changes', function()
    local text = sidebar_text()
    return not text:find('Loading', 1, true)
      and sidebar_line('changed file.txt') == 0
      and sidebar_line('deleted.txt') > 0
  end)
  eval("require('config.sidebar').files()")
  eval("require('config.tabs').focus()")
  print('PASS: asynchronous Git sidebar, switching, staging and opening files')

  assert(eval("return vim.fn.exists(':IconTheme')") == 0, 'icon pack picker should be removed')
  assert(eval("return vim.fn.maparg('<C-S-i>', 'n')") == '', 'Ctrl+Shift+I should not switch icon packs')
  assert(eval("return require('config.icons').file_icon('app.ts')") == 'S', 'Devicons should mark .ts files')
  assert(eval("return require('config.icons').file_icon('lib.rs')") == 'R', 'Devicons should mark .rs files')
  assert(
    eval("local _, hl = require('config.icons').file_icon('app.ts'); return hl") == 'DevIconTest',
    'Devicons should return a type color group'
  )
  assert(eval("return require('config.icons').tree_icons().web_devicons.file.enable") == true)
  assert(
    eval("return require('config.icons').tree_icons().web_devicons.file.color") == true,
    'Files icons should keep file-type colors'
  )
  assert(
    eval("return require('config.icons').tree_icons().web_devicons.folder.enable") == false,
    'folders must not use file Devicons'
  )
  assert(tree_icons_safe(), 'Files sidebar should keep nvim-tree folder icons')
  assert(eval("return require('config.icons').tree_icons().show.folder_arrow") == true)
  assert(eval("return require('config.icons').tree_icons().glyphs.folder.arrow_closed") == '>')
  print('PASS: Devicons only, one-cell Nerd Font glyphs')

  eval("require('config.sidebar').settings()")
  wait_for('Settings sidebar', function()
    return eval('return vim.bo.filetype') == 'setup-settings'
  end)
  local settings_text = eval("return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\\n')")
  assert(
    settings_text:find('Icons', 1, true) and settings_text:find('[Reload config]', 1, true),
    'Settings panel missing controls: ' .. settings_text
  )
  assert(
    not settings_text:find('Theme', 1, true)
      and not settings_text:find('Dark', 1, true)
      and not settings_text:find('Light', 1, true),
    'Settings should not switch theme: ' .. settings_text
  )
  eval('vim.api.nvim_win_set_cursor(0, {6, 0})')
  request('nvim_input', '<CR>')
  wait_for('icons off from Settings', function()
    return eval("return require('config.settings').get().icons") == false
      and eval("return require('config.icons').file_icon('app.ts')") == ' '
  end)
  assert(
    eval("return require('config.icons').tree_icons().web_devicons.file.enable") == false,
    'Files tree should hide Devicons when icons are off'
  )
  assert(eval('return vim.o.background') == 'dark', 'Settings must not change the colorscheme')
  local saved = eval([[
    local path = require('config.settings').file()
    return table.concat(vim.fn.readfile(path), '\n')
  ]])
  assert(not saved:find('theme', 1, true), 'settings.json should not persist theme')
  assert(
    saved:find('"icons":false', 1, true) or saved:find('"icons": false', 1, true),
    'settings.json should persist icons'
  )
  eval([[
    local path = require('config.settings').file()
    vim.fn.writefile({ '{"theme":"light","icons":true}' }, path)
  ]])
  eval('vim.api.nvim_win_set_cursor(0, {8, 0})')
  request('nvim_input', '<CR>')
  wait_for('reload settings from disk', function()
    return eval("return require('config.settings').get().icons") == true
      and eval("return require('config.icons').file_icon('app.ts')") == 'S'
  end)
  assert(eval('return vim.o.background') == 'dark', 'Reload must ignore a leftover theme in settings.json')
  request('nvim_input', 'q')
  wait_for('return to Files from Settings', function()
    return eval("return require('config.sidebar').view") == 'files'
  end)
  assert(eval("return vim.fn.exists(':SetupSettings')") == 2, ':SetupSettings should open the Settings tab')
  assert(eval("return vim.fn.maparg('<C-,>', 'n')") ~= '', 'Ctrl+, should open Settings')
  print('PASS: Settings sidebar icons, persist, and reload')

  -- Ctrl+P must add a mid-editor tab. Vim :edit on a blank [New] buffer replaces it.
  eval("require('config.tabs').new()")
  wait_for('blank editor tab before Ctrl-P', function()
    return eval("return vim.api.nvim_buf_get_name(0) == ''")
  end)
  local blank_tab = eval('return vim.api.nvim_get_current_buf()')
  local wins_before_find = eval('return #vim.api.nvim_tabpage_list_wins(0)')
  eval([[
    vim.api.nvim_create_user_command('FindProjectFiles', function()
      require('config.tabs').open_from_fzf({ vim.env.E2E_DIR .. '/repo/new.txt' })
    end, { force = true })
  ]])
  request('nvim_input', '<C-p>')
  wait_for('Ctrl-P opening a file tab', function()
    return eval("return vim.api.nvim_buf_get_name(0):find('new.txt', 1, true) ~= nil")
  end)
  assert(in_mid_editor(), 'Ctrl-P should open the file in the mid editor')
  assert(
    eval('return #vim.api.nvim_tabpage_list_wins(0)') == wins_before_find,
    'Ctrl-P should reuse the mid editor, not split like a new Vim window'
  )
  assert(
    eval(
      string.format(
        'return vim.api.nvim_buf_is_valid(%d) and vim.bo[%d].buflisted and vim.api.nvim_get_current_buf() ~= %d',
        blank_tab,
        blank_tab,
        blank_tab
      )
    ),
    'Ctrl-P should keep the previous tab instead of replacing it like :edit'
  )
  local file_tabs = eval([[
    local n = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf):find('new.txt', 1, true) and require('config.tabs').editor_buf(buf) then
        n = n + 1
      end
    end
    return n
  ]])
  request('nvim_input', '<C-p>')
  wait_for('Ctrl-P focusing an already open file', function()
    return eval("return vim.api.nvim_buf_get_name(0):find('new.txt', 1, true) ~= nil")
  end)
  assert(eval([[
      local n = 0
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):find('new.txt', 1, true) and require('config.tabs').editor_buf(buf) then
          n = n + 1
        end
      end
      return n
    ]]) == file_tabs, 'Ctrl-P should switch to an existing tab instead of duplicating it')
  print('PASS: Ctrl-P opens a new mid-editor tab')

  assert(
    eval([[
    local a = require('config.agents')
    return a.is_cli('gemini') and a.is_cli('claude') and a.is_cli('opencode')
      and a.order[3] == 'gemini' and a.order[4] == 'claude' and a.order[5] == 'opencode'
  ]]),
    'Gemini, Claude, and OpenCode must be registered chat CLIs'
  )
  eval("require('config.agents').new('codex', { uuid = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee' })")
  wait_for('codex resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/codex-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('resume aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee', 1, true)
  end)
  eval("require('config.agents').new('cursor', { uuid = '11111111-2222-4333-8444-555555555555' })")
  wait_for('agent resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/agent-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--resume=11111111-2222-4333-8444-555555555555', 1, true)
  end)
  eval("require('config.agents').new('gemini', { uuid = '22222222-3333-4444-8555-666666666666' })")
  wait_for('gemini resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/gemini-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--resume 22222222-3333-4444-8555-666666666666', 1, true)
  end)
  eval("require('config.agents').new('claude', { uuid = '33333333-4444-4555-8666-777777777777' })")
  wait_for('claude resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/claude-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--resume 33333333-4444-4555-8666-777777777777', 1, true)
  end)
  eval("require('config.agents').new('opencode', { uuid = 'ses_deadbeefcafebabe' })")
  wait_for('opencode resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/opencode-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--session ses_deadbeefcafebabe', 1, true)
  end)
  eval("require('config.agents').new('gemini')")
  wait_for('gemini new session-id argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/gemini-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--session-id ', 1, true)
  end)
  eval("require('config.agents').new('opencode')")
  wait_for('opencode new session argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/opencode-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--session ses_', 1, true)
  end)
  eval([[
    require('config.session').restore_chats({
      chats = {
        active = 1,
        sessions = {
          { name = 'codex', uuid = '99999999-aaaa-4bbb-8ccc-dddddddddddd', label = 'Codex saved' },
          { name = 'gemini', uuid = 'aaaa1111-bbbb-4ccc-8ddd-eeeeeeeeeeee', label = 'Gemini saved' },
          { name = 'claude', uuid = 'bbbb2222-cccc-4ddd-8eee-ffffffffffff', label = 'Claude saved' },
          { name = 'opencode', uuid = 'ses_cafef00d12345678', label = 'OpenCode saved' },
        },
      },
    })
  ]])
  wait_for('restored chat uuid', function()
    return eval([[
      local found = { codex = false, gemini = false, claude = false, opencode = false }
      for _, s in pairs(require('config.agents').sessions) do
        if s.uuid == '99999999-aaaa-4bbb-8ccc-dddddddddddd' then found.codex = true end
        if s.uuid == 'aaaa1111-bbbb-4ccc-8ddd-eeeeeeeeeeee' then found.gemini = true end
        if s.uuid == 'bbbb2222-cccc-4ddd-8eee-ffffffffffff' then found.claude = true end
        if s.uuid == 'ses_cafef00d12345678' then found.opencode = true end
      end
      return found.codex and found.gemini and found.claude and found.opencode
    ]])
  end)
  wait_for('restored codex resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/codex-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('resume 99999999-aaaa-4bbb-8ccc-dddddddddddd', 1, true)
  end)
  wait_for('restored gemini resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/gemini-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--resume aaaa1111-bbbb-4ccc-8ddd-eeeeeeeeeeee', 1, true)
  end)
  wait_for('restored claude resume argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/claude-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--resume bbbb2222-cccc-4ddd-8eee-ffffffffffff', 1, true)
  end)
  wait_for('restored opencode session argv', function()
    local f = io.open(vim.env.E2E_DIR .. '/opencode-args', 'r')
    if not f then
      return false
    end
    local args = f:read('*a')
    f:close()
    return args:find('--session ses_cafef00d12345678', 1, true)
  end)
  print('PASS: session persist, unsaved buffers, UUID resume and NVIM_CLEAN')

  eval([[
    local a = require('config.agents')
    local keep = a.active
    local extra = {}
    for id, _ in pairs(a.sessions) do
      if id ~= keep then extra[#extra + 1] = id end
    end
    for _, id in ipairs(extra) do a.close(id) end
    vim.fn.jobstop(a.sessions[keep].job)
  ]])
  wait_for('last exited agent chat to close the pane', function()
    return eval([[
      local a = require('config.agents')
      return vim.tbl_count(a.sessions) == 0
        and (a.win == nil or not vim.api.nvim_win_is_valid(a.win))
    ]])
  end)
  print('PASS: last agent process exit closes the chat pane')

  eval("require('config.agents').new('cursor')")
  wait_for('replacement chat for Ctrl-Q', function()
    return eval([[
      local a = require('config.agents')
      return vim.tbl_count(a.sessions) == 1
        and a.win ~= nil
        and vim.api.nvim_win_is_valid(a.win)
    ]])
  end)
  eval("vim.api.nvim_set_current_win(require('config.agents').win)")
  wait_for('terminal input before Ctrl-Q', function()
    return request('nvim_get_mode').mode == 't'
  end)

  request('nvim_input', '<C-q>')
  wait_for('Ctrl-Q quitting Neovim from terminal input', function()
    return exit_status ~= nil
  end)
  assert(exit_status == 0, 'Ctrl-Q should exit successfully')
end, debug.traceback)

pcall(request, 'nvim_command', 'qa!')
vim.fn.jobstop(child)
if not ok then
  error(err)
end
