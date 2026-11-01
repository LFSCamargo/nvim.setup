-- Global statusline: mode, git, file, focused-agent usage, diagnostics, cursor.
-- One bar for the whole UI (tree + editor + chat). The mode pill and the cursor
-- block keep accent fills, and their points face inward like the tab bar
-- ( after the mode,  before the cursor). Highlights keep fills so
-- appearance.lua's transparency pass does not wash the colors out.

local M = {}
local api = vim.api

-- Same points as the tab bar: editor tabs close with , agent tabs open with .
local RAISE = ''
local CAP = ''

local function chrome()
  return require('modules.appearance')
end
local modes = {
  n = { 'NORMAL', 'Normal' },
  no = { 'NORMAL', 'Normal' },
  nov = { 'NORMAL', 'Normal' },
  noV = { 'NORMAL', 'Normal' },
  niI = { 'NORMAL', 'Normal' },
  niR = { 'NORMAL', 'Normal' },
  niV = { 'NORMAL', 'Normal' },
  i = { 'INSERT', 'Insert' },
  ic = { 'INSERT', 'Insert' },
  ix = { 'INSERT', 'Insert' },
  v = { 'VISUAL', 'Visual' },
  vs = { 'VISUAL', 'Visual' },
  V = { 'V-LINE', 'Visual' },
  Vs = { 'V-LINE', 'Visual' },
  ['\22'] = { 'V-BLOCK', 'Visual' },
  ['\22s'] = { 'V-BLOCK', 'Visual' },
  s = { 'SELECT', 'Visual' },
  S = { 'S-LINE', 'Visual' },
  ['\19'] = { 'S-BLOCK', 'Visual' },
  R = { 'REPLACE', 'Replace' },
  Rc = { 'REPLACE', 'Replace' },
  Rx = { 'REPLACE', 'Replace' },
  Rv = { 'REPLACE', 'Replace' },
  c = { 'COMMAND', 'Command' },
  cv = { 'COMMAND', 'Command' },
  ce = { 'COMMAND', 'Command' },
  r = { 'CONFIRM', 'Command' },
  rm = { 'MORE', 'Command' },
  t = { 'TERMINAL', 'Terminal' },
  nt = { 'TERMINAL', 'Terminal' },
  ntT = { 'TERMINAL', 'Terminal' },
}

local side_ft = {
  NvimTree = 'Files',
  ['git-changes'] = 'Git',
  ['git-composer'] = 'Git',
  ['git-log'] = 'Git',
  ['setup-settings'] = 'Settings',
  ['setup-themes'] = 'Themes',
  ['setup-extensions'] = 'Extensions',
  ['git-diff'] = 'Diff',
}

M.fill_highlights = {
  'StatusLine',
  'StatusLineNC',
  'SLRec',
  'SLDebug',
  'SLModeNormal',
  'SLModeInsert',
  'SLModeVisual',
  'SLModeReplace',
  'SLModeCommand',
  'SLModeTerminal',
  'SLModeNormalSep',
  'SLModeInsertSep',
  'SLModeVisualSep',
  'SLModeReplaceSep',
  'SLModeCommandSep',
  'SLModeTerminalSep',
  'SLAgent',
  'SLBucket',
  'SLRightSep',
  'SLRight',
}

local git_cache = { cwd = '', at = 0, head = '' }
local usage_cache = {}

local AGENT_USAGE_TITLES = {
  codex = 'Codex',
  cursor = 'Cursor',
  claude = 'Claude',
  opencode = 'OpenCode',
  antigravity = 'Antigravity',
  gemini = 'Gemini',
}

local function escape(s)
  return (tostring(s):gsub('%%', '%%%%'):gsub('[\r\n]', ' '))
end

local function strip_ansi(line)
  return (line:gsub('\27%[[0-9:;]*[A-Za-z]', ''):gsub('\27%].*?\7', ''))
end

local function apply_highlights()
  local appearance = chrome()
  local bar_bg = appearance.bar_fill
  local accent = appearance.tab_accent
  local ink = appearance.tab_ink
  local mode_colors = appearance.modes
  api.nvim_set_hl(0, 'StatusLine', { fg = appearance.fg, bg = bar_bg })
  api.nvim_set_hl(0, 'StatusLineNC', { fg = appearance.muted, bg = bar_bg })
  for kind, bg in pairs(mode_colors) do
    api.nvim_set_hl(0, 'SLMode' .. kind, { fg = ink, bg = bg, bold = true })
    api.nvim_set_hl(0, 'SLMode' .. kind .. 'Sep', { fg = bg, bg = bar_bg })
  end
  api.nvim_set_hl(0, 'SLGit', { fg = mode_colors.Normal, bg = bar_bg })
  api.nvim_set_hl(0, 'SLGitAdd', { fg = mode_colors.Insert, bg = bar_bg })
  api.nvim_set_hl(0, 'SLGitChange', { fg = mode_colors.Normal, bg = bar_bg })
  api.nvim_set_hl(0, 'SLGitDelete', { fg = mode_colors.Replace, bg = bar_bg })
  api.nvim_set_hl(0, 'SLFile', { fg = appearance.fg, bg = bar_bg })
  api.nvim_set_hl(0, 'SLModified', { fg = mode_colors.Visual, bg = bar_bg })
  api.nvim_set_hl(0, 'SLAgent', { fg = mode_colors.Insert, bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagError', { fg = mode_colors.Replace, bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagWarn', { fg = mode_colors.Normal, bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagInfo', { fg = mode_colors.Insert, bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagHint', { fg = mode_colors.Visual, bg = bar_bg })
  api.nvim_set_hl(0, 'SLBucket', { fg = appearance.fg, bg = bar_bg, bold = true })
  api.nvim_set_hl(0, 'SLLsp', { fg = appearance.muted, bg = bar_bg })
  api.nvim_set_hl(0, 'SLFt', { fg = mode_colors.Normal, bg = bar_bg })
  api.nvim_set_hl(0, 'SLMeta', { fg = appearance.muted, bg = bar_bg })
  api.nvim_set_hl(0, 'SLRight', { fg = ink, bg = accent, bold = true })
  api.nvim_set_hl(0, 'SLRightSep', { fg = accent, bg = bar_bg })
  api.nvim_set_hl(0, 'SLSearch', { fg = mode_colors.Visual, bg = bar_bg })
  api.nvim_set_hl(0, 'SLRec', { fg = ink, bg = mode_colors.Replace, bold = true })
  api.nvim_set_hl(0, 'SLDebug', { fg = ink, bg = mode_colors.Visual, bold = true })
end

local function git_head_fallback()
  local cwd = vim.fn.getcwd()
  local now = vim.uv.now()
  if git_cache.cwd == cwd and now - git_cache.at < 3000 then
    return git_cache.head
  end
  git_cache.cwd = cwd
  git_cache.at = now
  local out = vim.fn.systemlist({ 'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD' })
  if vim.v.shell_error ~= 0 then
    git_cache.head = ''
    return ''
  end
  local head = out[1] or ''
  if head == 'HEAD' then
    local short = vim.fn.systemlist({ 'git', '-C', cwd, 'rev-parse', '--short', 'HEAD' })
    if vim.v.shell_error == 0 and short[1] then
      head = short[1]
    end
  end
  git_cache.head = head
  return head
end

local function git_info(buf)
  local dict = vim.b[buf].gitsigns_status_dict
  local head = vim.b[buf].gitsigns_head
  if type(dict) == 'table' and type(dict.head) == 'string' and dict.head ~= '' then
    head = dict.head
  elseif type(head) ~= 'string' or head == '' then
    head = git_head_fallback()
    dict = nil
  end
  if type(head) ~= 'string' or head == '' then
    return nil
  end
  return {
    head = head,
    added = type(dict) == 'table' and tonumber(dict.added) or 0,
    changed = type(dict) == 'table' and tonumber(dict.changed) or 0,
    removed = type(dict) == 'table' and tonumber(dict.removed) or 0,
  }
end

local function file_label(buf)
  local ft = vim.bo[buf].filetype
  local side = side_ft[ft]
  if side then
    return side, nil
  end
  local agents = package.loaded['modules.agents']
  if agents and agents.is_chat(buf) then
    local id = vim.b[buf].chat_id
    local session = id and agents.sessions[id]
    return session and session.label or 'Chat', nil
  end
  local name = api.nvim_buf_get_name(buf)
  if name == '' then
    return '[New]', nil
  end
  local icon = select(1, require('modules.icons').file_icon(name))
  if icon == ' ' then
    icon = nil
  end
  return vim.fn.fnamemodify(name, ':t'), icon
end

local function diagnostic_bucket(source)
  local src = type(source) == 'string' and source:lower() or ''
  if src:find('eslint', 1, true) then
    return 'ESLint', 20
  end
  if src:find('stylelint', 1, true) then
    return 'Stylelint', 21
  end
  if
    src:find('typescript', 1, true)
    or src:find('tsserver', 1, true)
    or src:find('vtsls', 1, true)
    or src == 'ts'
    or src:find('vue%-language', 1, true)
  then
    return 'TS', 10
  end
  if src:find('luacheck', 1, true) or src:find('selene', 1, true) then
    return 'Lint', 30
  end
  if src:find('lua', 1, true) then
    return 'Lua', 40
  end
  if src:find('rust', 1, true) or src:find('clippy', 1, true) then
    return 'Rust', 41
  end
  if src:find('gopls', 1, true) or src:find('go ', 1, true) then
    return 'Go', 42
  end
  if src ~= '' then
    local word = src:match('^[%w%-_]+') or src
    if #word > 12 then
      word = word:sub(1, 12)
    end
    return word:sub(1, 1):upper() .. word:sub(2), 50
  end
  return 'LSP', 60
end

local function diagnostic_groups(buf)
  local ok, diags = pcall(vim.diagnostic.get, buf)
  if not ok or type(diags) ~= 'table' then
    return {}
  end
  local sev = vim.diagnostic.severity
  local groups = {}
  for _, diag in ipairs(diags) do
    local label, order = diagnostic_bucket(diag.source)
    local bucket = groups[label]
    if not bucket then
      bucket = { label = label, order = order, e = 0, w = 0, i = 0, h = 0 }
      groups[label] = bucket
    end
    if diag.severity == sev.ERROR then
      bucket.e = bucket.e + 1
    elseif diag.severity == sev.WARN then
      bucket.w = bucket.w + 1
    elseif diag.severity == sev.INFO then
      bucket.i = bucket.i + 1
    elseif diag.severity == sev.HINT then
      bucket.h = bucket.h + 1
    end
  end
  local list = {}
  for _, bucket in pairs(groups) do
    if bucket.e + bucket.w + bucket.i + bucket.h > 0 then
      list[#list + 1] = bucket
    end
  end
  table.sort(list, function(a, b)
    if a.order == b.order then
      return a.label < b.label
    end
    return a.order < b.order
  end)
  return list
end

local function lsp_names(buf)
  local ok, clients = pcall(vim.lsp.get_clients, { bufnr = buf })
  if not ok or type(clients) ~= 'table' or #clients == 0 then
    return nil
  end
  local names, seen = {}, {}
  for _, client in ipairs(clients) do
    local name = client.name
    if type(name) == 'string' and name ~= '' and not seen[name] then
      seen[name] = true
      names[#names + 1] = name
    end
  end
  if #names == 0 then
    return nil
  end
  return table.concat(names, ',')
end

local function debugging()
  local ok, dap = pcall(require, 'dap')
  return ok and dap.session() ~= nil
end

local function search_label()
  if vim.v.hlsearch ~= 1 then
    return nil
  end
  local ok, sc = pcall(vim.fn.searchcount, { recompute = false, maxcount = 99 })
  if not ok or type(sc) ~= 'table' or not sc.total or sc.total < 1 then
    return nil
  end
  local total = sc.incomplete == 1 and (sc.total .. '+') or tostring(sc.total)
  return string.format('%d/%s', sc.current or 0, total)
end

local function indent_label(buf)
  local shift = vim.bo[buf].shiftwidth
  if shift == 0 then
    shift = vim.bo[buf].tabstop
  end
  if vim.bo[buf].expandtab then
    if shift == 2 then
      return nil
    end
    return 'spaces:' .. shift
  end
  return 'tabs:' .. vim.bo[buf].tabstop
end

local function encoding_label(buf)
  local enc = vim.bo[buf].fileencoding
  if enc == '' then
    enc = vim.o.encoding
  end
  if enc ~= 'utf-8' then
    return enc
  end
end

local function format_label(buf)
  local ff = vim.bo[buf].fileformat
  if ff == 'dos' then
    return 'CRLF'
  end
  if ff == 'mac' then
    return 'CR'
  end
end

local function location(win, buf)
  local pos = api.nvim_win_get_cursor(win)
  local row = pos[1]
  local col = pos[2] + 1
  if win == api.nvim_get_current_win() then
    col = vim.fn.virtcol('.')
  end
  local total = math.max(1, api.nvim_buf_line_count(buf))
  local pct
  if total <= 1 or row <= 1 then
    pct = 'TOP'
  elseif row >= total then
    pct = 'BOT'
  else
    pct = string.format('%d%%%%', math.floor((row - 1) / (total - 1) * 100 + 0.5))
  end
  return string.format('%d:%d', row, col), pct
end

local function chat_session(buf)
  local agents = package.loaded['modules.agents']
  if not agents or not agents.is_chat(buf) then
    return nil
  end
  local id = vim.b[buf].chat_id
  return id and agents.sessions[id] or nil
end

local function trim_usage(text, max_len)
  text = text:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
  if #text > (max_len or 44) then
    text = text:sub(1, max_len or 44):gsub('%s+$', '') .. '…'
  end
  return text
end

local function usage_hint_line(line)
  local lower = line:lower()
  if line:find('%%', 1, true) then
    return true
  end
  return lower:find('usage', 1, true)
    or lower:find('limit', 1, true)
    or lower:find('remaining', 1, true)
    or lower:find('resets', 1, true)
    or lower:find('quota', 1, true)
end

local function usage_detail_from_line(line, agent_name)
  local pct, tail = line:match('(%d+%%).-(%d+%.?%d*[hm].-5%s*[hH])')
  if pct and tail and agent_name == 'codex' then
    return trim_usage(('%s %s'):format(pct, tail))
  end
  pct = line:match('(%d+%%).-5%s*[hH]')
  if pct and agent_name == 'codex' then
    return trim_usage(('%s 5h'):format(pct))
  end
  pct, tail = line:match('(%d+%%).-(resets in %d+%.?%d*[hm])')
  if pct and tail then
    return trim_usage(('%s · %s'):format(pct, tail))
  end
  pct = line:match('(%d+%%)')
  if pct then
    local rest = line:match('%d+%%(.+)$')
    if rest and #rest > 2 then
      return trim_usage(pct .. rest)
    end
    return pct
  end
  local compact = line:match('[%w%:%.%/%%%s%-]+')
  if compact and usage_hint_line(line) then
    return trim_usage(compact)
  end
  return nil
end

local function usage_detail_from_buffer(buf, agent_name)
  if not api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= 'terminal' then
    return nil
  end
  local count = api.nvim_buf_line_count(buf)
  if count < 1 then
    return nil
  end
  local start = math.max(0, count - 160)
  local lines = api.nvim_buf_get_lines(buf, start, count, false)
  for i = #lines, 1, -1 do
    local line = strip_ansi(lines[i])
    if line ~= '' and usage_hint_line(line) then
      local detail = usage_detail_from_line(line, agent_name)
      if detail then
        return detail
      end
    end
  end
  return nil
end

local function agent_usage_label(buf)
  if type(vim.g.statusline_agent_usage) == 'string' and vim.g.statusline_agent_usage ~= '' then
    return vim.g.statusline_agent_usage
  end
  if type(vim.g.statusline_codex_usage) == 'string' and vim.g.statusline_codex_usage ~= '' then
    return vim.g.statusline_codex_usage
  end
  local session = chat_session(buf)
  if not session then
    return nil
  end
  local title = AGENT_USAGE_TITLES[session.name]
  if not title then
    return nil
  end
  if type(vim.g.statusline_agent_usage) == 'table' then
    local forced = vim.g.statusline_agent_usage[session.name]
    if type(forced) == 'string' and forced ~= '' then
      return ('%s Usage %s'):format(title, forced)
    end
  end
  local now = vim.uv.now()
  local cached = usage_cache[buf]
  if cached and cached.name == session.name and now - cached.at < 4000 and cached.text ~= '' then
    return cached.text
  end
  local detail = usage_detail_from_buffer(buf, session.name)
  local text = detail and ('%s Usage %s'):format(title, detail) or nil
  usage_cache[buf] = { name = session.name, text = text or '', at = now }
  return text
end

local function special_buf(buf)
  local ft = vim.bo[buf].filetype
  if side_ft[ft] then
    return true
  end
  local agents = package.loaded['modules.agents']
  return agents and agents.is_chat(buf) or false
end

local function render()
  local win = vim.g.statusline_winid
  if not win or not api.nvim_win_is_valid(win) then
    win = api.nvim_get_current_win()
  end
  local buf = api.nvim_win_get_buf(win)
  local parts = {}
  local function add(group, text)
    if not text or text == '' then
      return
    end
    parts[#parts + 1] = '%#' .. group .. '#' .. text
  end

  -- Mode is the left accent, flush like an editor tab: padding, then one .
  local mode = modes[api.nvim_get_mode().mode] or { 'NORMAL', 'Normal' }
  add('SLMode' .. mode[2], ' ' .. mode[1] .. ' ')
  add('SLMode' .. mode[2] .. 'Sep', CAP)

  local left = false
  local function left_item()
    add('StatusLine', left and '  ' or ' ')
    left = true
  end

  local git = git_info(buf)
  if git then
    left_item()
    add('SLGit', ' ' .. escape(git.head))
    if git.added > 0 then
      add('SLGitAdd', ' +' .. git.added)
    end
    if git.changed > 0 then
      add('SLGitChange', ' ~' .. git.changed)
    end
    if git.removed > 0 then
      add('SLGitDelete', ' -' .. git.removed)
    end
  end

  local label, icon = file_label(buf)
  left_item()
  add('SLFile', (icon and (icon .. ' ') or '') .. escape(label))
  if vim.bo[buf].modified then
    add('SLModified', ' ●')
  end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    add('SLMeta', ' RO')
  end

  local agent_usage = agent_usage_label(buf)
  if agent_usage then
    left_item()
    add('SLAgent', escape(agent_usage))
  end

  local rec = vim.fn.reg_recording()
  if rec ~= '' then
    left_item()
    add('SLRec', ' REC @' .. escape(rec) .. ' ')
  end
  if debugging() then
    left_item()
    add('SLDebug', ' DEBUG ')
  end

  parts[#parts + 1] = '%#StatusLine# %='

  local right = false
  local function right_item()
    if right then
      add('StatusLine', '  ')
    end
    right = true
  end

  local search = search_label()
  if search then
    right_item()
    add('SLSearch', escape(search))
  end

  if not special_buf(buf) then
    local groups = diagnostic_groups(buf)
    for _, bucket in ipairs(groups) do
      right_item()
      add('SLBucket', bucket.label)
      if bucket.e > 0 then
        add('SLDiagError', ' E:' .. bucket.e)
      end
      if bucket.w > 0 then
        add('SLDiagWarn', ' W:' .. bucket.w)
      end
      if bucket.i > 0 then
        add('SLDiagInfo', ' I:' .. bucket.i)
      end
      if bucket.h > 0 then
        add('SLDiagHint', ' H:' .. bucket.h)
      end
    end

    local lsp = lsp_names(buf)
    if lsp then
      right_item()
      add('SLLsp', escape(lsp))
    end
    local ft = vim.bo[buf].filetype
    if ft ~= '' then
      right_item()
      add('SLFt', escape(ft))
    end
    local enc = encoding_label(buf)
    if enc then
      right_item()
      add('SLMeta', escape(enc))
    end
    local ff = format_label(buf)
    if ff then
      right_item()
      add('SLMeta', ff)
    end
    local indent = indent_label(buf)
    if indent then
      right_item()
      add('SLMeta', indent)
    end
  end

  -- Cursor block is the right accent, flush like an agent tab: one , then the fill.
  local pos, pct = location(win, buf)
  if right then
    add('StatusLine', ' ')
  end
  add('SLRightSep', RAISE)
  add('SLRight', ' ' .. pos .. '  ' .. pct .. ' ')
  return table.concat(parts)
end

function M.draw()
  local ok, line = pcall(render)
  if ok then
    return line
  end
  return ' %f %m%r%=%l:%c %p%% '
end

M.refresh_highlights = apply_highlights
apply_highlights()
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.ruler = false
vim.opt.statusline = "%!v:lua.require'modules.statusline'.draw()"

api.nvim_create_autocmd('ColorScheme', { callback = apply_highlights })
api.nvim_create_autocmd('User', {
  pattern = { 'LazyLoad', 'VeryLazy' },
  callback = function()
    vim.schedule(apply_highlights)
  end,
})
vim.defer_fn(function()
  if M._agent_timer then
    return
  end
  local uv = vim.uv or vim.loop
  if not uv or not uv.new_timer then
    return
  end
  -- vim.g only stores msgpack values, so the libuv handle stays on the module.
  M._agent_timer = uv.new_timer()
  M._agent_timer:start(
    5000,
    5000,
    vim.schedule_wrap(function()
      usage_cache = {}
      pcall(vim.cmd.redrawstatus)
    end)
  )
end, 500)
api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.defer_fn(apply_highlights, 120)
    vim.defer_fn(apply_highlights, 1100)
  end,
})
api.nvim_create_autocmd({
  'ModeChanged',
  'DiagnosticChanged',
  'BufEnter',
  'BufWinEnter',
  'BufWritePost',
  'FileType',
  'RecordingEnter',
  'RecordingLeave',
  'LspAttach',
  'LspDetach',
  'DirChanged',
  'TermEnter',
  'TermClose',
}, {
  callback = function(ev)
    if ev.event == 'TermEnter' or ev.event == 'TermClose' then
      usage_cache = {}
    end
    pcall(vim.cmd.redrawstatus)
  end,
})
api.nvim_create_autocmd('User', {
  pattern = { 'GitSignsUpdate', 'FugitiveChanged' },
  callback = function()
    pcall(vim.cmd.redrawstatus)
  end,
})
api.nvim_create_autocmd('DirChanged', {
  callback = function()
    git_cache.at = 0
    git_cache.head = ''
  end,
})

return M
