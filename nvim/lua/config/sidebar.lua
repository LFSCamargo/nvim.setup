-- Files/Git sidebar. Git runs asynchronously so navigation stays responsive.
local M = { view = 'files', generation = 0 }
local api = vim.api
local git_buf, git_win, composer_buf, composer_win, log_buf, log_win, root, rows, log_rows
local groups = { staged = {}, unstaged = {}, history = {} }
local expanded = { staged = true, unstaged = true }
local render_id = 0
local current_branch = 'Git'
local highlights = api.nvim_create_namespace('GitChanges')
local composer_marks = api.nvim_create_namespace('GitComposer')

local function setup_highlights()
  api.nvim_set_hl(0, 'GitChangeDeleted', { fg = '#fb4934' })
  api.nvim_set_hl(0, 'GitChangeModified', { fg = '#fabd2f' })
  api.nvim_set_hl(0, 'GitChangeAdded', { fg = '#b8bb26' })
  api.nvim_set_hl(0, 'GitHelp', { fg = '#928374' })
  api.nvim_set_hl(0, 'GitButton', { fg = '#83a598', bold = true })
end
setup_highlights()
api.nvim_create_autocmd('ColorScheme', { callback = setup_highlights })

function M.width()
  return math.max(1, math.floor(vim.o.columns * 0.20))
end

function M.file_icon(path)
  return require('config.icons').file_icon(path)
end

function M.tree_icons()
  return require('config.icons').tree_icons()
end

function M.log_height()
  return math.max(3, math.floor(vim.o.lines * 0.30))
end

local function valid(win)
  return win and api.nvim_win_is_valid(win)
end

local function close_git()
  if valid(log_win) then api.nvim_win_close(log_win, true) end
  if valid(composer_win) then api.nvim_win_close(composer_win, true) end
  if valid(git_win) then api.nvim_win_close(git_win, true) end
  composer_win, git_win, log_win = nil, nil, nil
end

local function paint(lines)
  if not git_buf or not api.nvim_buf_is_valid(git_buf) then return end
  vim.bo[git_buf].modifiable = true
  api.nvim_buf_set_lines(git_buf, 0, -1, false, lines)
  vim.bo[git_buf].modifiable = false
end

local function paint_log(lines)
  if not log_buf or not api.nvim_buf_is_valid(log_buf) then return end
  vim.bo[log_buf].modifiable = true
  api.nvim_buf_set_lines(log_buf, 0, -1, false, lines)
  vim.bo[log_buf].modifiable = false
end

local function run(args, callback, opts)
  local sysopts = { text = false }
  if opts then for key, value in pairs(opts) do sysopts[key] = value end end
  local ok, err = pcall(vim.system, args, sysopts, function(result)
    vim.schedule(function() callback(result) end)
  end)
  if not ok then vim.schedule(function() callback({ code = 1, stderr = tostring(err) }) end) end
end

local function git_notify(result, fallback)
  vim.notify('Git: ' .. (result.stderr or fallback):gsub('[\r\n]+', ' '), vim.log.levels.ERROR)
end

local function change_highlight(status)
  if status:find('D', 1, true) then return 'GitChangeDeleted' end
  if status:find('A', 1, true) or status == '?' then return 'GitChangeAdded' end
  return 'GitChangeModified'
end

local function git_paths(entry)
  local paths = {}
  for _, rel in ipairs({ entry.path, entry.old }) do
    if type(rel) == 'string' and rel ~= '' and not rel:find('[\r\n]') then
      paths[#paths + 1] = rel
    end
  end
  return paths
end

local function with_paths(args, paths)
  if #paths == 0 then return nil end
  for _, path in ipairs(paths) do args[#args + 1] = path end
  return args
end

local function after_git(generation, result, fallback)
  if result and result.code ~= 0 then git_notify(result, fallback) end
  if generation == M.generation and M.view == 'git' then M.refresh() end
end

local function message_text()
  if not composer_buf or not api.nvim_buf_is_valid(composer_buf) then return '' end
  return vim.trim(table.concat(api.nvim_buf_get_lines(composer_buf, 0, -1, false), '\n')):gsub('\0', '')
end

local function paint_composer_placeholder()
  if not composer_buf or not api.nvim_buf_is_valid(composer_buf) then return end
  api.nvim_buf_clear_namespace(composer_buf, composer_marks, 0, -1)
  local lines = api.nvim_buf_get_lines(composer_buf, 0, -1, false)
  if #lines == 1 and lines[1] == '' then
    local short = current_branch:match('^([^%s%.]+)') or 'HEAD'
    api.nvim_buf_set_extmark(composer_buf, composer_marks, 0, 0, {
      virt_text = { { 'Message (Ctrl+Enter to commit on ' .. short:gsub('[%c]', ' ') .. ')', 'Comment' } },
      virt_text_pos = 'overlay',
    })
  end
end

local function focus_composer(insert)
  if not valid(composer_win) then return end
  api.nvim_set_current_win(composer_win)
  if insert then
    vim.schedule(function()
      if valid(composer_win) then
        api.nvim_set_current_win(composer_win)
        vim.cmd.startinsert()
      end
    end)
  end
end

local function focus_list()
  if valid(git_win) then api.nvim_set_current_win(git_win) end
end

local function focus_log()
  if valid(log_win) then api.nvim_set_current_win(log_win) end
end

local function change_index(entry)
  if not entry or not entry.path or not root then return end
  local args = with_paths(
    entry.group == 'staged' and { 'git', '-C', root, 'restore', '--staged', '--' }
      or { 'git', '-C', root, 'add', '--' },
    git_paths(entry)
  )
  if not args then return end
  local generation = M.generation
  run(args, function(result) after_git(generation, result, 'command failed') end)
end

local function stage_all()
  if not root or #groups.unstaged == 0 then return end
  local generation = M.generation
  run({ 'git', '-C', root, 'add', '--all', '--' }, function(result)
    after_git(generation, result, 'stage all failed')
  end)
end

local function unstage_all()
  if not root or #groups.staged == 0 then return end
  local generation = M.generation
  run({ 'git', '-C', root, 'restore', '--staged', '--', '.' }, function(result)
    after_git(generation, result, 'unstage all failed')
  end)
end

local function revert_entry(entry, opts)
  if not entry or not entry.path or not root then return end
  local paths = git_paths(entry)
  if #paths == 0 then return end
  if not (opts and opts.confirmed) then
    local prompt = entry.status == '?' and ('Delete untracked file "' .. entry.path .. '"?')
      or ('Revert "' .. entry.path .. '"?')
    if vim.fn.confirm(prompt, '&Yes\n&No', 2) ~= 1 then return end
  end
  local generation = M.generation
  local args
  if entry.group == 'staged' then
    args = with_paths({ 'git', '-C', root, 'restore', '--source=HEAD', '--staged', '--worktree', '--' }, paths)
  elseif entry.status == '?' then
    args = with_paths({ 'git', '-C', root, 'clean', '-f', '--' }, paths)
  else
    args = with_paths({ 'git', '-C', root, 'restore', '--worktree', '--' }, paths)
  end
  if args then run(args, function(result) after_git(generation, result, 'revert failed') end) end
end

local function revert_all()
  if not root or #groups.unstaged == 0 then return end
  if vim.fn.confirm('Revert all unstaged changes?', '&Yes\n&No', 2) ~= 1 then return end
  local generation = M.generation
  local tracked, untracked = {}, {}
  for _, entry in ipairs(groups.unstaged) do
    for _, path in ipairs(git_paths(entry)) do
      if entry.status == '?' then untracked[#untracked + 1] = path
      else tracked[#tracked + 1] = path end
    end
  end
  local function finish(result)
    after_git(generation, result, 'revert all failed')
  end
  local function clean_untracked(previous)
    if previous and previous.code ~= 0 then finish(previous); return end
    if #untracked == 0 then finish(previous); return end
    run(with_paths({ 'git', '-C', root, 'clean', '-f', '--' }, untracked), finish)
  end
  if #tracked == 0 then clean_untracked(); return end
  run(with_paths({ 'git', '-C', root, 'restore', '--worktree', '--' }, tracked), clean_untracked)
end

local function commit()
  if not root then return end
  local message = message_text()
  if message == '' then
    vim.notify('Type a commit message first', vim.log.levels.WARN)
    focus_composer(true)
    return
  end
  local generation = M.generation
  local function do_commit()
    run({ 'git', '-C', root, 'commit', '-F', '-' }, function(result)
      if result.code ~= 0 then
        git_notify(result, 'commit failed')
      else
        if composer_buf and api.nvim_buf_is_valid(composer_buf) then
          api.nvim_buf_set_lines(composer_buf, 0, -1, false, { '' })
          paint_composer_placeholder()
        end
      end
      if generation == M.generation and M.view == 'git' then M.refresh() end
    end, { text = true, stdin = message })
  end
  run({ 'git', '-C', root, 'diff', '--cached', '--quiet' }, function(result)
    if generation ~= M.generation or M.view ~= 'git' then return end
    if result.code == 1 then
      do_commit()
      return
    end
    if result.code ~= 0 then
      git_notify(result, 'commit failed')
      return
    end
    if #groups.unstaged == 0 then
      vim.notify('No changes to commit', vim.log.levels.WARN)
      return
    end
    if vim.fn.confirm('No staged changes. Stage all and commit?', '&Yes\n&No', 2) ~= 1 then return end
    run({ 'git', '-C', root, 'add', '--all', '--' }, function(add_result)
      if generation ~= M.generation or M.view ~= 'git' then return end
      if add_result.code ~= 0 then
        git_notify(add_result, 'stage all failed')
        return
      end
      do_commit()
    end)
  end)
end

local function open_file(entry)
  if entry.status == 'D' then
    vim.notify('This file was deleted; use Space g s to inspect its diff')
    return
  end
  if not root or type(entry.path) ~= 'string' or entry.path == '' or entry.path:find('[\r\n]') then return end
  local path = vim.fs.normalize(root .. '/' .. entry.path)
  local base = vim.fs.normalize(root)
  if path ~= base and path:sub(1, #base + 1) ~= base .. '/' then return end
  local target = require('config.tabs').focus()
  if not target then return end
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

local function show_commit(hash)
  if not root or type(hash) ~= 'string' or not hash:match('^%x+$') or #hash < 7 or #hash > 40 then return end
  local tabs = require('config.tabs')
  local target = tabs.focus()
  if not target then return end
  run({ 'git', '-C', root, 'show', '--stat', '--format=medium', hash }, function(result)
    if result.code ~= 0 then git_notify(result, 'could not show commit'); return end
    if not api.nvim_win_is_valid(target) then
      target = tabs.focus()
      if not target then return end
    end
    local buf = api.nvim_create_buf(true, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].filetype = 'git'
    pcall(api.nvim_buf_set_name, buf, 'git://show/' .. hash)
    api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout or '', '\n', { plain = true }))
    vim.bo[buf].modifiable = false
    api.nvim_set_current_win(target)
    api.nvim_win_set_buf(target, buf)
  end, { text = true })
end

local function selected(line)
  return rows and rows[line or api.nvim_win_get_cursor(0)[1]]
end

local function selected_log(line)
  return log_rows and log_rows[line or api.nvim_win_get_cursor(0)[1]]
end

local function activate(entry, action)
  if not entry then return end
  if entry.kind == 'commit' or action == 'commit' then commit(); return end
  if entry.kind == 'bulk' then
    if action == 'revert' or (entry.group == 'unstaged' and action == 'revert_all') then revert_all()
    elseif entry.group == 'staged' then unstage_all()
    else stage_all() end
    return
  end
  if entry.kind == 'log' then
    if entry.hash then show_commit(entry.hash) end
    return
  end
  if not entry.path then
    expanded[entry.group] = not expanded[entry.group]
    M.render(current_branch, M.generation)
    return
  end
  if action == 'revert' then revert_entry(entry); return end
  if action == 'index' or action == true then change_index(entry); return end
  open_file(entry)
end

local function click_action(entry, col)
  if not entry then return end
  if entry.kind == 'commit' then activate(entry); return end
  if entry.kind == 'bulk' then
    activate(entry, (entry.revert_col and col >= entry.revert_col) and 'revert' or nil)
    return
  end
  if entry.path then
    if entry.revert_col and col >= entry.revert_col then activate(entry, 'revert')
    elseif col <= 4 then activate(entry, 'index')
    else activate(entry) end
    return
  end
  activate(entry)
end

function M.render_log()
  if M.view ~= 'git' or not log_buf or not api.nvim_buf_is_valid(log_buf) then return end
  log_rows = {}
  local items = groups.history or {}
  local lines = { ('  COMMITS  (%d)'):format(#items), '  Enter show  Tab files' }
  if #items == 0 then
    lines[#lines + 1] = '     No commits'
  else
    for i, entry in ipairs(items) do
      lines[#lines + 1] = ' ' .. entry.text
      log_rows[i + 2] = entry
    end
  end
  paint_log(lines)
  api.nvim_buf_clear_namespace(log_buf, highlights, 0, -1)
  api.nvim_buf_add_highlight(log_buf, highlights, 'GitButton', 0, 0, -1)
  api.nvim_buf_add_highlight(log_buf, highlights, 'GitHelp', 1, 0, -1)
  for i, entry in ipairs(items) do
    api.nvim_buf_add_highlight(log_buf, highlights, entry.hash and 'GitButton' or 'GitHelp', i + 1, 0, -1)
  end
end

function M.render(branch, generation)
  if generation ~= M.generation or M.view ~= 'git' then return end
  render_id = render_id + 1
  local rendering = render_id
  rows = {}
  rows[3] = { kind = 'commit' }
  paint({
    '  SOURCE CONTROL',
    '  ' .. branch:gsub('[%c]', ' '),
    '  [Commit]  Ctrl+Enter',
    '  s/u  x revert  i message',
    '',
  })
  api.nvim_buf_clear_namespace(git_buf, highlights, 0, -1)
  api.nvim_buf_add_highlight(git_buf, highlights, 'GitButton', 2, 0, -1)
  api.nvim_buf_add_highlight(git_buf, highlights, 'GitHelp', 3, 0, -1)
  paint_composer_placeholder()
  M.render_log()
  local section, file_index, emitted_header, emitted_bulk, line_count = 1, 1, false, false, 5
  local names = { 'staged', 'unstaged' }
  local function batch()
    if generation ~= M.generation or rendering ~= render_id or M.view ~= 'git' or not git_buf or not api.nvim_buf_is_valid(git_buf) then return end
    local lines, colors = {}, {}
    while section <= #names and #lines < 200 do
      local name = names[section]
      local items = groups[name] or {}
      if not emitted_header then
        lines[#lines + 1] = (' %s %s  (%d)'):format(expanded[name] and '▾' or '▸', name == 'staged' and 'Staged Changes' or 'Changes', #items)
        rows[line_count + #lines] = { kind = 'section', group = name }
        emitted_header = true
      elseif not expanded[name] then
        lines[#lines + 1] = ''
        section, file_index, emitted_header, emitted_bulk = section + 1, 1, false, false
      elseif not emitted_bulk then
        if #items == 0 then
          lines[#lines + 1] = '     No changes'
          lines[#lines + 1] = ''
          section, file_index, emitted_header, emitted_bulk = section + 1, 1, false, false
        else
          if name == 'staged' then
            lines[#lines + 1] = '   [Unstage All]'
            rows[line_count + #lines] = { kind = 'bulk', group = 'staged' }
          else
            local line = '   [Stage All]  [Revert All]'
            lines[#lines + 1] = line
            rows[line_count + #lines] = { kind = 'bulk', group = 'unstaged', revert_col = line:find('[Revert All]', 1, true) }
          end
          colors[#colors + 1] = { line_count + #lines - 1, 'GitButton' }
          emitted_bulk = true
        end
      elseif file_index <= #items then
        local entry = items[file_index]
        local symbol = name == 'staged' and '−' or '+'
        local icon, icon_hl = M.file_icon(entry.path)
        local safe = entry.path:gsub('[%c]', '?')
        local prefix = ('  %s  %s  '):format(symbol, entry.status)
        local line = prefix .. icon .. ' ' .. safe .. '  x'
        lines[#lines + 1] = line
        rows[line_count + #lines] = {
          path = entry.path, old = entry.old, status = entry.status, group = name,
          kind = 'file', revert_col = line:find('x$'),
        }
        local row = line_count + #lines - 1
        colors[#colors + 1] = { row, change_highlight(entry.status), 0, -1 }
        colors[#colors + 1] = { row, icon_hl, #prefix, #prefix + #icon }
        file_index = file_index + 1
      else
        lines[#lines + 1] = ''
        section, file_index, emitted_header, emitted_bulk = section + 1, 1, false, false
      end
    end
    if #lines > 0 then
      vim.bo[git_buf].modifiable = true
      api.nvim_buf_set_lines(git_buf, -1, -1, false, lines)
      vim.bo[git_buf].modifiable = false
      for _, color in ipairs(colors) do
        api.nvim_buf_add_highlight(git_buf, highlights, color[2], color[1], color[3] or 0, color[4] or -1)
      end
      line_count = line_count + #lines
    end
    if section <= #names then vim.defer_fn(batch, 1) end
  end
  batch()
end

function M.refresh()
  M.generation = M.generation + 1
  local generation = M.generation
  root, rows = nil, {}
  groups = { staged = {}, unstaged = {}, history = {} }
  paint({ '  SOURCE CONTROL', '', '  Loading Git changes…' })
  paint_log({ '  COMMITS', '', '  Loading…' })
  run({ 'git', '-C', vim.fn.getcwd(), 'rev-parse', '--show-toplevel' }, function(result)
    if generation ~= M.generation or M.view ~= 'git' then return end
    if result.code ~= 0 then
      paint({ '  SOURCE CONTROL', '', '  Not a Git repository' })
      paint_log({ '  COMMITS', '', '  Not a Git repository' })
      return
    end
    root = (result.stdout or ''):gsub('[\r\n]+$', '')
    run({ 'git', '-C', root, 'status', '--porcelain=v1', '-z', '--branch', '--untracked-files=all' }, function(status)
      if generation ~= M.generation or M.view ~= 'git' then return end
      if status.code ~= 0 then
        paint({ '  SOURCE CONTROL', '', '  Could not load Git status', (status.stderr or ''):gsub('[\r\n]+', ' ') })
        paint_log({ '  COMMITS', '', '  Could not load Git log' })
        return
      end
      local raw = status.stdout or ''
      local branch_end = raw:find('\0', 1, true)
      current_branch = branch_end and raw:sub(4, branch_end - 1) or 'Git'
      local pos = branch_end and branch_end + 1 or #raw + 1
      local function parse_batch()
        if generation ~= M.generation or M.view ~= 'git' then return end
        local count = 0
        while pos <= #raw and count < 200 do
          local stop = raw:find('\0', pos, true)
          if not stop then pos = #raw + 1; break end
          local record = raw:sub(pos, stop - 1)
          pos = stop + 1
          local xy, path = record:sub(1, 2), record:sub(4)
          if #record >= 4 then
            local old
            if xy:find('R', 1, true) or xy:find('C', 1, true) then
              local old_end = raw:find('\0', pos, true)
              old = old_end and raw:sub(pos, old_end - 1) or nil
              pos = old_end and old_end + 1 or #raw + 1
            end
            if xy:sub(1, 1) ~= ' ' and xy ~= '??' then
              groups.staged[#groups.staged + 1] = { path = path, old = old, status = xy:sub(1, 1), group = 'staged' }
            end
            if xy:sub(2, 2) ~= ' ' then
              groups.unstaged[#groups.unstaged + 1] = { path = path, old = old, status = xy == '??' and '?' or xy:sub(2, 2), group = 'unstaged' }
            end
          end
          count = count + 1
        end
        if pos <= #raw then
          vim.defer_fn(parse_batch, 1)
        else
          run({ 'git', '-C', root, '-c', 'color.ui=never', 'log', '--graph', '--oneline', '--decorate', '--no-color', '--max-count=40' }, function(log)
            if generation ~= M.generation or M.view ~= 'git' then return end
            groups.history = {}
            if log.code == 0 then
              for line in (log.stdout or ''):gmatch('[^\r\n]+') do
                local safe = line:gsub('[%c]', ' ')
                groups.history[#groups.history + 1] = {
                  kind = 'log',
                  hash = safe:match('(%x%x%x%x%x%x%x+)'),
                  text = safe,
                }
              end
            end
            M.render(current_branch, generation)
          end, { text = true })
        end
      end
      parse_batch()
    end)
  end)
end

function M.files()
  M.generation = M.generation + 1
  M.view = 'files'
  close_git()
  require('nvim-tree.api').tree.open({ focus = true })
end

function M.toggle_files()
  if M.view == 'git' and valid(git_win) then M.files()
  else require('nvim-tree.api').tree.toggle() end
end

local function map_buf(buf, mode, key, fn, desc)
  vim.keymap.set(mode, key, fn, { buffer = buf, silent = true, nowait = true, desc = desc })
end

local function bind_list_keys()
  map_buf(git_buf, 'n', '<CR>', function() activate(selected()) end, 'Open file or toggle')
  map_buf(git_buf, 'n', 's', function()
    local entry = selected()
    if entry and entry.path and entry.group == 'unstaged' then change_index(entry)
    elseif entry and not entry.path and entry.group == 'unstaged' then stage_all() end
  end, 'Stage')
  map_buf(git_buf, 'n', 'S', stage_all, 'Stage all')
  map_buf(git_buf, 'n', 'u', function()
    local entry = selected()
    if entry and entry.path and entry.group == 'staged' then change_index(entry)
    elseif entry and not entry.path and entry.group == 'staged' then unstage_all() end
  end, 'Unstage')
  map_buf(git_buf, 'n', 'U', unstage_all, 'Unstage all')
  map_buf(git_buf, 'n', 'x', function()
    local entry = selected()
    if entry and entry.path then revert_entry(entry)
    elseif entry and entry.group == 'unstaged' then revert_all() end
  end, 'Revert')
  map_buf(git_buf, 'n', 'X', revert_all, 'Revert all')
  map_buf(git_buf, 'n', 'C', commit, 'Commit')
  map_buf(git_buf, 'n', '<C-CR>', commit, 'Commit')
  map_buf(git_buf, 'n', 'i', function() focus_composer(true) end, 'Edit commit message')
  map_buf(git_buf, 'n', '<Tab>', focus_log, 'Focus commit log')
  map_buf(git_buf, 'n', 'r', M.refresh, 'Refresh')
  map_buf(git_buf, 'n', 'q', M.files, 'Files sidebar')
  vim.keymap.set('n', '<LeftMouse>', function()
    local pos = vim.fn.getmousepos()
    if pos.winid == git_win and pos.line > 0 then
      vim.schedule(function()
        if valid(git_win) and M.view == 'git' then click_action(selected(pos.line), pos.column) end
      end)
    end
    return '<LeftMouse>'
  end, { buffer = git_buf, expr = true, silent = true, desc = 'Activate Git item' })
end

local function bind_log_keys()
  map_buf(log_buf, 'n', '<CR>', function() activate(selected_log()) end, 'Show commit')
  map_buf(log_buf, 'n', 'i', function() focus_composer(true) end, 'Edit commit message')
  map_buf(log_buf, 'n', '<Tab>', function() focus_composer(false) end, 'Focus commit message')
  map_buf(log_buf, 'n', 'C', commit, 'Commit')
  map_buf(log_buf, 'n', '<C-CR>', commit, 'Commit')
  map_buf(log_buf, 'n', 'r', M.refresh, 'Refresh')
  map_buf(log_buf, 'n', 'q', M.files, 'Files sidebar')
  vim.keymap.set('n', '<LeftMouse>', function()
    local pos = vim.fn.getmousepos()
    if pos.winid == log_win and pos.line > 0 then
      vim.schedule(function()
        if valid(log_win) and M.view == 'git' then activate(selected_log(pos.line)) end
      end)
    end
    return '<LeftMouse>'
  end, { buffer = log_buf, expr = true, silent = true, desc = 'Show commit' })
end

local function bind_composer_keys()
  map_buf(composer_buf, { 'n', 'i' }, '<C-CR>', commit, 'Commit')
  map_buf(composer_buf, 'n', 'C', commit, 'Commit')
  map_buf(composer_buf, 'n', '<Tab>', focus_list, 'Git file list')
  map_buf(composer_buf, 'n', 'q', M.files, 'Files sidebar')
  map_buf(composer_buf, 'n', 'r', M.refresh, 'Refresh')
  api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = composer_buf,
    callback = paint_composer_placeholder,
  })
end

local function configure_side(win, buf, ft)
  api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = ft
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
end

local function apply_log_height()
  if valid(log_win) then api.nvim_win_set_height(log_win, M.log_height()) end
end

local function open_composer()
  if valid(composer_win) then return end
  api.nvim_set_current_win(git_win)
  vim.cmd('aboveleft 5split')
  composer_win = api.nvim_get_current_win()
  composer_buf = api.nvim_create_buf(false, true)
  configure_side(composer_win, composer_buf, 'git-composer')
  vim.wo[composer_win].winfixheight = true
  api.nvim_win_set_height(composer_win, 5)
  vim.bo[composer_buf].modifiable = true
  bind_composer_keys()
  paint_composer_placeholder()
  api.nvim_set_current_win(git_win)
end

local function open_log()
  if valid(log_win) then
    apply_log_height()
    return
  end
  if not valid(git_win) then return end
  api.nvim_set_current_win(git_win)
  vim.cmd('belowright split')
  log_win = api.nvim_get_current_win()
  log_buf = api.nvim_create_buf(false, true)
  configure_side(log_win, log_buf, 'git-log')
  vim.wo[log_win].winfixheight = true
  apply_log_height()
  bind_log_keys()
  paint_log({ '  COMMITS', '', '  Loading…' })
  api.nvim_set_current_win(git_win)
end

local function git_side(win)
  return win == git_win or win == composer_win or win == log_win
end

function M.git()
  if M.view == 'git' and valid(git_win) then
    open_composer()
    open_log()
    api.nvim_set_current_win(git_win)
    M.refresh()
    return
  end
  M.view = 'git'
  require('nvim-tree.api').tree.close()
  vim.cmd('topleft vsplit')
  git_win = api.nvim_get_current_win()
  git_buf = api.nvim_create_buf(false, true)
  configure_side(git_win, git_buf, 'git-changes')
  api.nvim_win_set_width(git_win, M.width())
  bind_list_keys()
  open_composer()
  open_log()
  M.refresh()
end

local left_git
api.nvim_create_autocmd('WinLeave', {
  callback = function()
    left_git = git_side(api.nvim_get_current_win())
  end,
})
api.nvim_create_autocmd('WinEnter', {
  callback = function()
    if M.view ~= 'git' or left_git or not git_side(api.nvim_get_current_win()) then return end
    vim.defer_fn(function()
      if M.view == 'git' then M.refresh() end
    end, 20)
  end,
})

api.nvim_create_autocmd('VimResized', {
  callback = function()
    if M.view ~= 'git' then return end
    if valid(git_win) then api.nvim_win_set_width(git_win, M.width()) end
    if valid(composer_win) then api.nvim_win_set_height(composer_win, 5) end
    apply_log_height()
  end,
})

_G.SidebarFiles = function(_, _, button) if button == 'l' then M.files() end end
_G.SidebarGit = function(_, _, button) if button == 'l' then M.git() end end
function M.winbar()
  return '%#PaneTab' .. (M.view == 'files' and 'Active' or 'Inactive') .. '#%0@v:lua.SidebarFiles@ Files %T'
    .. '%#PaneTab' .. (M.view == 'git' and 'Active' or 'Inactive') .. '#%0@v:lua.SidebarGit@ Git %T%#Normal#'
end

return M
