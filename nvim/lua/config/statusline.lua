-- Global Gruvbox statusline: mode, git, file, diagnostics, LSP, and cursor.
-- One bar for the whole UI (tree + editor + chat). Highlights keep fills so
-- appearance.lua's transparency pass does not wash the colors out.

local M = {}
local api = vim.api

local bar_bg = '#3c3836'
local ink = '#1d2021'
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

-- Faded Gruvbox yellow/red/orange so the bar is warm without the neon brights.
local mode_colors = {
  Normal = '#d79921',
  Insert = '#cc241d',
  Visual = '#d65d0e',
  Replace = '#9d0006',
  Command = '#b57614',
  Terminal = '#cc241d',
}

local side_ft = {
  NvimTree = 'Files',
  ['git-changes'] = 'Git',
  ['git-composer'] = 'Git',
  ['git-log'] = 'Git',
  ['setup-settings'] = 'Settings',
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
}

local git_cache = { cwd = '', at = 0, head = '' }

local function escape(s)
  return (tostring(s):gsub('%%', '%%%%'):gsub('[\r\n]', ' '))
end

local function apply_highlights()
  api.nvim_set_hl(0, 'StatusLine', { fg = '#ebdbb2', bg = bar_bg })
  api.nvim_set_hl(0, 'StatusLineNC', { fg = '#a89984', bg = bar_bg })
  for kind, bg in pairs(mode_colors) do
    api.nvim_set_hl(0, 'SLMode' .. kind, { fg = ink, bg = bg, bold = true })
    api.nvim_set_hl(0, 'SLMode' .. kind .. 'Sep', { fg = bg, bg = bar_bg })
  end
  api.nvim_set_hl(0, 'SLGit', { fg = '#d79921', bg = bar_bg })
  api.nvim_set_hl(0, 'SLGitAdd', { fg = '#98971a', bg = bar_bg })
  api.nvim_set_hl(0, 'SLGitChange', { fg = '#d79921', bg = bar_bg })
  api.nvim_set_hl(0, 'SLGitDelete', { fg = '#cc241d', bg = bar_bg })
  api.nvim_set_hl(0, 'SLFile', { fg = '#ebdbb2', bg = bar_bg })
  api.nvim_set_hl(0, 'SLModified', { fg = '#d65d0e', bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagError', { fg = '#cc241d', bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagWarn', { fg = '#d79921', bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagInfo', { fg = '#689d6a', bg = bar_bg })
  api.nvim_set_hl(0, 'SLDiagHint', { fg = '#d65d0e', bg = bar_bg })
  api.nvim_set_hl(0, 'SLLsp', { fg = '#bdae93', bg = bar_bg })
  api.nvim_set_hl(0, 'SLFt', { fg = '#d79921', bg = bar_bg })
  api.nvim_set_hl(0, 'SLMeta', { fg = '#928374', bg = bar_bg })
  api.nvim_set_hl(0, 'SLPos', { fg = '#d79921', bg = bar_bg })
  api.nvim_set_hl(0, 'SLPct', { fg = '#cc241d', bg = bar_bg })
  api.nvim_set_hl(0, 'SLSearch', { fg = '#d65d0e', bg = bar_bg })
  api.nvim_set_hl(0, 'SLRec', { fg = ink, bg = '#cc241d', bold = true })
  api.nvim_set_hl(0, 'SLDebug', { fg = ink, bg = '#d65d0e', bold = true })
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
  local agents = package.loaded['config.agents']
  if agents and agents.is_chat(buf) then
    local id = vim.b[buf].chat_id
    local session = id and agents.sessions[id]
    return session and session.label or 'Chat', nil
  end
  local name = api.nvim_buf_get_name(buf)
  if name == '' then
    return '[New]', nil
  end
  local icon = select(1, require('config.icons').file_icon(name))
  if icon == ' ' then
    icon = nil
  end
  return vim.fn.fnamemodify(name, ':t'), icon
end

local function diagnostic_counts(buf)
  local ok, counts = pcall(vim.diagnostic.count, buf)
  if not ok or type(counts) ~= 'table' then
    return 0, 0, 0, 0
  end
  local sev = vim.diagnostic.severity
  return counts[sev.ERROR] or 0, counts[sev.WARN] or 0, counts[sev.INFO] or 0, counts[sev.HINT] or 0
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

local function special_buf(buf)
  local ft = vim.bo[buf].filetype
  if side_ft[ft] then
    return true
  end
  local agents = package.loaded['config.agents']
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

  local mode = modes[api.nvim_get_mode().mode] or { 'NORMAL', 'Normal' }
  add('SLMode' .. mode[2], ' ' .. mode[1] .. ' ')
  add('SLMode' .. mode[2] .. 'Sep', '')

  local git = git_info(buf)
  if git then
    add('SLGit', '   ' .. escape(git.head))
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
  add('SLFile', '  ' .. (icon and (icon .. ' ') or '') .. escape(label))
  if vim.bo[buf].modified then
    add('SLModified', ' ●')
  end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    add('SLMeta', ' RO')
  end

  if not special_buf(buf) then
    local err, warn, info, hint = diagnostic_counts(buf)
    if err > 0 then
      add('SLDiagError', '  E:' .. err)
    end
    if warn > 0 then
      add('SLDiagWarn', '  W:' .. warn)
    end
    if info > 0 then
      add('SLDiagInfo', '  I:' .. info)
    end
    if hint > 0 then
      add('SLDiagHint', '  H:' .. hint)
    end
  end

  local rec = vim.fn.reg_recording()
  if rec ~= '' then
    add('SLRec', ' REC @' .. escape(rec) .. ' ')
  end
  if debugging() then
    add('SLDebug', ' DEBUG ')
  end

  parts[#parts + 1] = '%#StatusLine# %='

  local search = search_label()
  if search then
    add('SLSearch', ' ' .. escape(search) .. ' ')
  end

  if not special_buf(buf) then
    local lsp = lsp_names(buf)
    if lsp then
      add('SLLsp', '  ' .. escape(lsp))
    end
    local ft = vim.bo[buf].filetype
    if ft ~= '' then
      add('SLFt', '  ' .. escape(ft))
    end
    local enc = encoding_label(buf)
    if enc then
      add('SLMeta', '  ' .. escape(enc))
    end
    local ff = format_label(buf)
    if ff then
      add('SLMeta', '  ' .. ff)
    end
    local indent = indent_label(buf)
    if indent then
      add('SLMeta', '  ' .. indent)
    end
  end

  local pos, pct = location(win, buf)
  add('SLPos', '  ' .. pos)
  add('SLPct', '  ' .. pct .. ' ')
  return table.concat(parts)
end

function M.draw()
  local ok, line = pcall(render)
  if ok then
    return line
  end
  return ' %f %m%r%=%l:%c %p%% '
end

apply_highlights()
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.ruler = false
vim.opt.statusline = "%!v:lua.require'config.statusline'.draw()"

api.nvim_create_autocmd('ColorScheme', { callback = apply_highlights })
api.nvim_create_autocmd('User', {
  pattern = { 'LazyLoad', 'VeryLazy' },
  callback = function()
    vim.schedule(apply_highlights)
  end,
})
-- Re-apply after appearance.lua's delayed transparency pass.
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
}, {
  callback = function()
    vim.cmd.redrawstatus()
  end,
})
api.nvim_create_autocmd('User', {
  pattern = { 'GitSignsUpdate', 'FugitiveChanged' },
  callback = function()
    vim.cmd.redrawstatus()
  end,
})
api.nvim_create_autocmd('DirChanged', {
  callback = function()
    git_cache.at = 0
    git_cache.head = ''
  end,
})

return M
