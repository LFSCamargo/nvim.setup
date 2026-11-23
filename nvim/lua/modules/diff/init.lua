-- Git diff preview in the existing editor pane. No new split or shell command.
local M = {}
local api = vim.api
local ns = api.nvim_create_namespace('SetupGitDiff')
local buf, previous, request_id = nil, nil, 0

local function valid_path(root, path)
  if
    type(root) ~= 'string'
    or root == ''
    or type(path) ~= 'string'
    or path == ''
    or path:find('[\r\n]')
    or path:find('\0', 1, true)
  then
    return nil
  end
  local base = vim.fs.normalize(root)
  local full = vim.fs.normalize(base .. '/' .. path)
  if full:sub(1, #base + 1) ~= base .. '/' then
    return nil
  end
  return full
end

local function paint(lines)
  if not (buf and api.nvim_buf_is_valid(buf)) then
    return
  end
  require('modules.shared.buffer').replace(buf, lines)
  local crumb = package.loaded['modules.breadcrumb']
  if crumb and crumb.render then
    crumb.render()
  end
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, line in ipairs(lines) do
    local group
    if i == 1 then
      group = 'GitDiffTitle'
    elseif line:match('^%+[^+]') then
      group = 'GitDiffAdded'
    elseif line:match('^%-[^-]') then
      group = 'GitDiffRemoved'
    elseif line:match('^@@') then
      group = 'GitDiffHunk'
    elseif line:match('^diff ') or line:match('^index ') or line:match('^%+%+%+') or line:match('^%-%-%-') then
      group = 'GitDiffMeta'
    end
    if group then
      api.nvim_buf_add_highlight(buf, ns, group, i - 1, 0, -1)
    end
  end
end

function M.active()
  return buf ~= nil and api.nvim_buf_is_valid(buf)
end

function M.buffer()
  return M.active() and buf or nil
end

function M.source_buf()
  return M.active() and previous and api.nvim_buf_is_valid(previous) and previous or nil
end

local function resolve_git_target(file_buf)
  if not api.nvim_buf_is_valid(file_buf) then
    return nil
  end
  local name = api.nvim_buf_get_name(file_buf)
  if name == '' then
    return nil
  end
  local abs = vim.fs.normalize(vim.fn.fnamemodify(name, ':p'))
  local dir = vim.fn.fnamemodify(abs, ':h')
  local out = vim.fn.systemlist({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == '' then
    return nil
  end
  local root = vim.fs.normalize(out[1])
  local rel = abs
  if abs:sub(1, #root + 1) == root .. '/' then
    rel = abs:sub(#root + 2)
  end
  local st = vim.fn.systemlist({ 'git', '-C', root, 'status', '--porcelain=v1', '--', rel })
  local line = vim.v.shell_error == 0 and st[1] or nil
  local status = 'M'
  local group = 'unstaged'
  if line and #line >= 2 then
    local x, y = line:sub(1, 1), line:sub(2, 2)
    if x == '?' and y == '?' then
      status = '?'
      group = 'unstaged'
    elseif y ~= ' ' and y ~= '' then
      status = y
      group = 'unstaged'
    elseif x ~= ' ' and x ~= '' then
      status = x
      group = 'staged'
    end
  end
  return root, {
    path = rel,
    status = status,
    group = group,
  }
end

function M.toggle_for_buf(target_buf)
  local tabs = require('modules.tabs')
  local win = tabs.editor_win() or api.nvim_get_current_win()
  target_buf = target_buf
    or (win and api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win))
    or api.nvim_get_current_buf()
  if
    M.active() and (target_buf == buf or (win and api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf))
  then
    M.close()
    local sidebar = package.loaded['modules.sidebar']
    if sidebar and sidebar.view == 'git' and sidebar.render then
      sidebar.render(sidebar.current_branch or 'Git', sidebar.generation)
    end
    return true
  end
  local root, entry = resolve_git_target(target_buf)
  if not root or not entry then
    return false
  end
  return M.open(root, entry)
end

function M.open(root, entry)
  if type(entry) ~= 'table' or (entry.group ~= 'staged' and entry.group ~= 'unstaged') then
    return false
  end
  local full = valid_path(root, entry.path)
  if not full then
    return false
  end
  local old = entry.old and valid_path(root, entry.old) or nil
  if entry.old and not old then
    return false
  end
  local tabs = require('modules.tabs')
  local win = tabs.focus()
  if not win then
    return false
  end
  if not M.active() then
    previous = api.nvim_win_get_buf(win)
    buf = api.nvim_create_buf(true, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = 'git-diff'
  end
  request_id = request_id + 1
  local current = request_id
  vim.b[buf].git_diff_path = full
  vim.b[buf].git_diff_rel = entry.path
  vim.b[buf].git_diff_label = 'Diff: ' .. vim.fn.fnamemodify(entry.path, ':t')
  api.nvim_win_set_buf(win, buf)
  local scope = entry.group == 'staged' and 'Staged' or 'Unstaged'
  paint({ scope .. ' diff: ' .. entry.path, 'Loading diff…' })
  local args
  local allow_one = false
  if entry.status == '?' then
    args = { 'git', '-C', root, 'diff', '--no-index', '--no-color', '--', '/dev/null', full }
    allow_one = true
  else
    args = { 'git', '-C', root, 'diff', '--no-ext-diff', '--no-color', '--no-textconv' }
    if entry.group == 'staged' then
      args[#args + 1] = '--cached'
    end
    args[#args + 1] = '--'
    if old then
      args[#args + 1] = entry.old
    end
    args[#args + 1] = entry.path
  end
  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if current ~= request_id or not M.active() then
        return
      end
      if result.code ~= 0 and not (allow_one and result.code == 1) then
        paint({ scope .. ' diff: ' .. entry.path, 'Could not load diff', (result.stderr or ''):gsub('[\r\n]+', ' ') })
        return
      end
      local lines = { scope .. ' diff: ' .. entry.path }
      local file_buf = vim.fn.bufnr(full)
      if file_buf ~= -1 and vim.bo[file_buf].modified then
        lines[#lines + 1] = 'Unsaved editor changes are not shown. Save the file to update this diff.'
      end
      lines[#lines + 1] = ''
      local output = (result.stdout or ''):gsub('\n$', '')
      if output == '' then
        lines[#lines + 1] = 'No diff for this file.'
      else
        vim.list_extend(lines, vim.split(output, '\n', { plain = true }))
      end
      paint(lines)
    end)
  end)
  return true
end

function M.close()
  if not M.active() then
    return
  end
  request_id = request_id + 1
  local old_buf = buf
  local replacement = previous and api.nvim_buf_is_valid(previous) and previous or api.nvim_create_buf(true, false)
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == old_buf then
      require('modules.tabs').set_buf(win, replacement)
    end
  end
  buf, previous = nil, nil
  api.nvim_buf_delete(old_buf, { force = true })
  require('modules.tabs').ensure()
end

local function highlights()
  api.nvim_set_hl(0, 'GitDiffTitle', { fg = '#83a598', bold = true })
  api.nvim_set_hl(0, 'GitDiffAdded', { fg = '#98971a' })
  api.nvim_set_hl(0, 'GitDiffRemoved', { fg = '#cc241d' })
  api.nvim_set_hl(0, 'GitDiffHunk', { fg = '#d79921' })
  api.nvim_set_hl(0, 'GitDiffMeta', { fg = '#a89984' })
end
highlights()
api.nvim_create_autocmd('ColorScheme', { callback = highlights })

return M
