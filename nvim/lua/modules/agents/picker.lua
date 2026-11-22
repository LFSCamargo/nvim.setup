-- Floating modal picker for starting a new AI agent chat tab.
-- Renders 1-cell brand glyphs in the list and 7-line ASCII brand art in the preview pane.

local M = {}
local api = vim.api
local ns = api.nvim_create_namespace('AgentPicker')

local win, buf, origin_win, on_select
local query = ''
local filtering = false
local closing = false
local selected_idx = 1
local filtered = {}
local row_map = {}
local layout_wide = true
local layout_left_w = 34
local layout_width = 66

local FILTER_PREFIX = '  / '

-- Pure 7-bit ASCII brand emblems (exactly 7 lines each, <= 14 cols) so preview
-- art never jumps height and works in every terminal font.
M.ascii = {
  codex = {
    '    .----.    ',
    "  .' /--\\ '.  ",
    " / .' /\\ '. \\ ",
    ' | | (  ) | | ',
    " \\ '. \\/ .' / ",
    "  '. \\--/ .'  ",
    "    '----'    ",
  },
  cursor = {
    '      /\\      ',
    "    .'  '.    ",
    "  .'  |\\  '.  ",
    ' |    | \\   | ',
    ' |    | /   | ',
    "  '.  |/  .'  ",
    "    '.__.'    ",
  },
  claude = {
    '      ||      ',
    '   \\  ||  /   ',
    '  --\\ || /--  ',
    ' === (**) === ',
    '  --/ || \\--  ',
    '   /  ||  \\   ',
    '      ||      ',
  },
  opencode = {
    ' +----------+ ',
    ' |  .----.  | ',
    ' |  |####|  | ',
    ' |  |####|  | ',
    ' |  |####|  | ',
    " |  '----'  | ",
    ' +----------+ ',
  },
  antigravity = {
    '      /\\      ',
    '     /  \\     ',
    '    / /\\ \\    ',
    '   / /()\\ \\   ',
    '  / /    \\ \\  ',
    ' /_/      \\_\\ ',
    '   ^  ^^  ^   ',
  },
}

local function valid(w)
  return w ~= nil and api.nvim_win_is_valid(w)
end

local function valid_buf(b)
  return b ~= nil and api.nvim_buf_is_valid(b)
end

function M.highlights()
  local appearance = package.loaded['modules.appearance']
  local fg = appearance and appearance.fg or '#ebdbb2'
  local muted = appearance and appearance.muted or '#a89984'
  local sep = appearance and appearance.sep or '#665c54'
  local accent = appearance and appearance.tab_accent or '#fabd2f'
  local ink = appearance and appearance.tab_ink or '#1d2021'
  api.nvim_set_hl(0, 'AgentPickerBorder', { fg = sep })
  api.nvim_set_hl(0, 'AgentPickerTitle', { fg = accent, bold = true })
  api.nvim_set_hl(0, 'AgentPickerFooter', { fg = muted })
  api.nvim_set_hl(0, 'AgentPickerPrompt', { fg = accent, bold = true })
  api.nvim_set_hl(0, 'AgentPickerFilter', { fg = fg })
  api.nvim_set_hl(0, 'AgentPickerHint', { fg = muted })
  api.nvim_set_hl(0, 'AgentPickerSep', { fg = sep })
  api.nvim_set_hl(0, 'AgentPickerSel', { fg = ink, bg = accent, bold = true })
  api.nvim_set_hl(0, 'AgentPickerItem', { fg = fg })
  api.nvim_set_hl(0, 'AgentPickerKey', { fg = muted })
  api.nvim_set_hl(0, 'AgentPickerInstalled', { fg = '#8ec07c', bold = true })
  api.nvim_set_hl(0, 'AgentPickerMissing', { fg = '#fb4934' })
  api.nvim_set_hl(0, 'AgentPickerEmpty', { fg = muted, italic = true })
  local icons = package.loaded['modules.icons']
  if type(icons) == 'table' and icons.agent_highlights then
    icons.agent_highlights()
  end
end

M.highlights()
api.nvim_create_autocmd('ColorScheme', { callback = M.highlights })

local function disp_width(text)
  return vim.fn.strdisplaywidth(text or '')
end

local function truncate(text, max_w)
  text = tostring(text or '')
  if max_w <= 0 then
    return ''
  end
  if disp_width(text) <= max_w then
    return text
  end
  if max_w == 1 then
    return '…'
  end
  local out = text
  local chars = vim.fn.strchars(text)
  while chars > 0 and disp_width(out) > max_w - 1 do
    chars = chars - 1
    out = vim.fn.strcharpart(text, 0, chars)
  end
  return out .. '…'
end

local function segs_width(segs)
  local w = 0
  for _, seg in ipairs(segs) do
    w = w + disp_width(seg[1])
  end
  return w
end

local function fit_left(segs, target_w, fill_hl)
  local out = {}
  local used = 0
  for _, seg in ipairs(segs) do
    local text = seg[1]
    local w = disp_width(text)
    if used + w <= target_w then
      out[#out + 1] = { text, seg[2] }
      used = used + w
    else
      local remain = target_w - used
      if remain > 0 then
        local cut = truncate(text, remain)
        out[#out + 1] = { cut, seg[2] }
        used = used + disp_width(cut)
      end
      break
    end
  end
  if used < target_w then
    out[#out + 1] = { string.rep(' ', target_w - used), fill_hl }
  end
  return out
end

local function center_box(segs, target_w)
  local w = segs_width(segs)
  if w >= target_w then
    return fit_left(segs, target_w)
  end
  local left_pad = math.floor((target_w - w) / 2)
  local right_pad = target_w - w - left_pad
  local out = {}
  if left_pad > 0 then
    out[#out + 1] = { string.rep(' ', left_pad), nil }
  end
  for _, seg in ipairs(segs) do
    out[#out + 1] = seg
  end
  if right_pad > 0 then
    out[#out + 1] = { string.rep(' ', right_pad), nil }
  end
  return out
end

local function flatten_row(segs)
  local parts = {}
  local marks = {}
  local col = 0
  for _, seg in ipairs(segs) do
    local text = seg[1] or ''
    local hl = seg[2]
    local len = #text
    if len > 0 then
      parts[#parts + 1] = text
      if hl then
        marks[#marks + 1] = { col, col + len, hl }
      end
      col = col + len
    end
  end
  return table.concat(parts), marks
end

local function match_rank(item, needle)
  if needle == '' then
    return 0
  end
  local name = (item.name or ''):lower()
  local prompt = (item.prompt or ''):lower()
  if name:sub(1, #needle) == needle or prompt:sub(1, #needle) == needle then
    return 1
  end
  if name:find(needle, 1, true) or prompt:find(needle, 1, true) then
    return 2
  end
  local bin = (item.bin or ''):lower()
  local cmd = (item.command or ''):lower()
  if bin:find(needle, 1, true) or cmd:find(needle, 1, true) then
    return 3
  end
  local extra = ((item.description or '') .. ' ' .. table.concat(item.aliases or {}, ' ')):lower()
  if extra:find(needle, 1, true) then
    return 4
  end
  return nil
end

local function compute_filtered()
  local all = require('modules.agents').list()
  local needle = vim.trim(query):lower()
  local ranked = {}
  for idx, item in ipairs(all) do
    local rank = match_rank(item, needle)
    if rank then
      ranked[#ranked + 1] = { rank = rank, order = idx, item = item }
    end
  end
  table.sort(ranked, function(a, b)
    if a.rank ~= b.rank then
      return a.rank < b.rank
    end
    return a.order < b.order
  end)
  local out = {}
  for _, entry in ipairs(ranked) do
    out[#out + 1] = entry.item
  end
  return out
end

local function build_item_row(idx, item, active, left_w)
  local icons = require('modules.icons')
  local glyph, brand_hl = icons.agent_glyph(item.name)
  local status = item.installed and '●' or '○'
  local status_hl = item.installed and 'AgentPickerInstalled' or 'AgentPickerMissing'
  local badge = ('[%d] '):format(idx)
  local prefix = active and '  ▸ ' or '    '
  local open_tag = item.open_count > 0 and (' (' .. item.open_count .. ')') or ''
  -- Reserve 3 cells on the right for ' ' .. status .. ' '.
  local fixed = disp_width(prefix) + disp_width(badge) + disp_width(glyph) + 1 + 3
  local max_name = math.max(4, left_w - fixed)
  local label = truncate(item.prompt .. open_tag, max_name)
  local pad = math.max(1, left_w - fixed - disp_width(label))
  if active then
    local segs = {
      { prefix .. badge .. glyph .. ' ' .. label .. string.rep(' ', pad + 1) .. status .. ' ', 'AgentPickerSel' },
    }
    return fit_left(segs, left_w, 'AgentPickerSel')
  end
  local segs = {
    { prefix, 'AgentPickerItem' },
    { badge, 'AgentPickerKey' },
    { glyph, brand_hl },
    { ' ' .. label, 'AgentPickerItem' },
    { string.rep(' ', pad + 1), nil },
    { status, status_hl },
    { ' ', nil },
  }
  return fit_left(segs, left_w)
end

local function build_preview(item, right_w)
  local rows = {}
  if not item then
    for _ = 1, 12 do
      rows[#rows + 1] = { { string.rep(' ', right_w), nil } }
    end
    rows[5] = center_box({ { 'No agent selected', 'AgentPickerEmpty' } }, right_w)
    return rows
  end
  local icons = require('modules.icons')
  local glyph, brand_hl = icons.agent_glyph(item.name)
  local art = M.ascii[item.name] or {}
  for i = 1, 7 do
    local line = art[i] or ''
    rows[#rows + 1] = center_box({ { line, brand_hl } }, right_w)
  end
  rows[#rows + 1] = { { string.rep(' ', right_w), nil } }
  rows[#rows + 1] = center_box({
    { glyph .. ' ', brand_hl },
    { item.prompt, brand_hl },
  }, right_w)
  rows[#rows + 1] = center_box({ { truncate(item.description, right_w - 2), 'AgentPickerItem' } }, right_w)
  local state_text = item.installed and 'installed' or 'not on PATH'
  local state_hl = item.installed and 'AgentPickerInstalled' or 'AgentPickerMissing'
  rows[#rows + 1] = center_box({
    { item.bin .. ' · ', 'AgentPickerHint' },
    { state_text, state_hl },
  }, right_w)
  rows[#rows + 1] = { { string.rep(' ', right_w), nil } }
  return rows
end

local function build_left(left_w)
  local rows = {}
  row_map = {}
  rows[1] = { { string.rep(' ', left_w), nil } }
  if #filtered == 0 then
    rows[2] = fit_left({ { '  No matching agents', 'AgentPickerEmpty' } }, left_w)
    for i = 3, 8 do
      rows[i] = { { string.rep(' ', left_w), nil } }
    end
  else
    for i = 1, 5 do
      local item = filtered[i]
      if item then
        rows[i + 1] = build_item_row(i, item, i == selected_idx, left_w)
        -- Body row (i + 1) maps to 1-indexed buffer line (i + 3) after filter + divider.
        row_map[i + 3] = { index = i, name = item.name }
      else
        rows[i + 1] = { { string.rep(' ', left_w), nil } }
      end
    end
    rows[7] = { { string.rep(' ', left_w), nil } }
    rows[8] = { { string.rep(' ', left_w), nil } }
  end
  rows[9] = fit_left({ { '  ' .. string.rep('─', math.max(4, left_w - 4)), 'AgentPickerSep' } }, left_w)
  local cur = filtered[selected_idx]
  if cur then
    local badge = cur.installed and '● Installed' or '○ Not on PATH'
    local badge_hl = cur.installed and 'AgentPickerInstalled' or 'AgentPickerMissing'
    local open_info = cur.open_count > 0 and (' · ' .. cur.open_count .. ' open') or ''
    rows[10] = fit_left({
      { '  ', nil },
      { badge, badge_hl },
      { open_info, 'AgentPickerHint' },
    }, left_w)
    rows[11] = fit_left({
      { '  ' .. cur.shortcut .. '  :' .. cur.command, 'AgentPickerHint' },
    }, left_w)
  else
    rows[10] = fit_left({ { '  Press <BS> to clear filter', 'AgentPickerHint' } }, left_w)
    rows[11] = { { string.rep(' ', left_w), nil } }
  end
  rows[12] = { { string.rep(' ', left_w), nil } }
  return rows
end

local function build_filter_segs()
  if filtering then
    return {
      { FILTER_PREFIX, 'AgentPickerPrompt' },
      { query, 'AgentPickerFilter' },
    }
  end
  if query ~= '' then
    return {
      { FILTER_PREFIX, 'AgentPickerPrompt' },
      { query, 'AgentPickerFilter' },
      { '  (<BS> clear)', 'AgentPickerHint' },
    }
  end
  return {
    { FILTER_PREFIX, 'AgentPickerPrompt' },
    { 'Filter agents... (press /)', 'AgentPickerHint' },
  }
end

local function render(keep_filter_line)
  if not valid(win) or not valid_buf(buf) then
    return
  end
  filtered = compute_filtered()
  if #filtered == 0 then
    selected_idx = 0
  else
    selected_idx = math.max(1, math.min(selected_idx > 0 and selected_idx or 1, #filtered))
  end

  local lines = {}
  local all_marks = {}

  local filter_text, filter_marks = flatten_row(build_filter_segs())
  lines[1] = filter_text
  all_marks[1] = filter_marks

  local div_text, div_marks = flatten_row({
    { '  ' .. string.rep('─', math.max(4, layout_width - 4)), 'AgentPickerSep' },
  })
  lines[2] = div_text
  all_marks[2] = div_marks

  local left_rows = build_left(layout_left_w)
  local right_w = layout_wide and math.max(16, layout_width - layout_left_w - 3) or 0
  local right_rows = layout_wide and build_preview(filtered[selected_idx], right_w) or nil

  for i = 1, 12 do
    local segs = {}
    for _, s in ipairs(left_rows[i]) do
      segs[#segs + 1] = s
    end
    if layout_wide and right_rows then
      segs[#segs + 1] = { ' │ ', 'AgentPickerSep' }
      for _, s in ipairs(right_rows[i]) do
        segs[#segs + 1] = s
      end
    end
    local text, marks = flatten_row(segs)
    lines[i + 2] = text
    all_marks[i + 2] = marks
  end

  local was_mod = vim.bo[buf].modifiable
  vim.bo[buf].modifiable = true
  if keep_filter_line then
    local body = {}
    for i = 2, #lines do
      body[#body + 1] = lines[i]
    end
    api.nvim_buf_set_lines(buf, 1, -1, false, body)
  else
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  vim.bo[buf].modifiable = filtering and true or (keep_filter_line and was_mod or false)

  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if keep_filter_line then
    api.nvim_buf_add_highlight(buf, ns, 'AgentPickerPrompt', 0, 0, #FILTER_PREFIX)
    local line0 = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
    if #line0 > #FILTER_PREFIX then
      api.nvim_buf_add_highlight(buf, ns, 'AgentPickerFilter', 0, #FILTER_PREFIX, #line0)
    end
  else
    for _, m in ipairs(all_marks[1] or {}) do
      api.nvim_buf_add_highlight(buf, ns, m[3], 0, m[1], m[2])
    end
  end
  for lnum = 2, #lines do
    for _, m in ipairs(all_marks[lnum] or {}) do
      api.nvim_buf_add_highlight(buf, ns, m[3], lnum - 1, m[1], m[2])
    end
  end

  if not filtering and selected_idx > 0 then
    pcall(api.nvim_win_set_cursor, win, { selected_idx + 3, 2 })
  end
end

function M.visible()
  return valid(win) and valid_buf(buf)
end

function M.state()
  local names = {}
  for _, item in ipairs(filtered) do
    names[#names + 1] = item.name
  end
  local cur = filtered[selected_idx]
  return {
    visible = M.visible(),
    win = win,
    buf = buf,
    query = query,
    filtering = filtering,
    selected_index = selected_idx,
    selected = cur and cur.name or nil,
    items = names,
    wide = layout_wide,
  }
end

function M.close(restore)
  if closing then
    return
  end
  closing = true
  local old_win = win
  local old_origin = origin_win
  win, buf, origin_win, on_select = nil, nil, nil, nil
  filtering = false
  query = ''
  selected_idx = 1
  filtered = {}
  row_map = {}
  pcall(vim.cmd.stopinsert)
  if valid(old_win) then
    pcall(api.nvim_win_close, old_win, true)
  end
  if restore and valid(old_origin) then
    pcall(api.nvim_set_current_win, old_origin)
  end
  closing = false
end

local function move(delta)
  if #filtered == 0 then
    return
  end
  selected_idx = ((selected_idx - 1 + delta) % #filtered) + 1
  render(filtering)
end

function M.filter(text)
  query = type(text) == 'string' and text or ''
  selected_idx = 1
  if M.visible() then
    render(false)
  end
  return vim.deepcopy(filtered)
end

function M.choose(target)
  local chosen
  if type(target) == 'number' then
    chosen = filtered[target]
  elseif type(target) == 'string' then
    for _, item in ipairs(filtered) do
      if item.name == target then
        chosen = item
        break
      end
    end
    if not chosen and require('modules.agents').is_cli(target) then
      chosen = require('modules.agents').meta(target)
    end
  else
    chosen = filtered[selected_idx]
  end
  if not chosen then
    return false
  end
  local cb = on_select
  local name = chosen.name
  M.close(false)
  vim.schedule(function()
    if cb then
      cb(name)
    else
      require('modules.agents').new(name)
    end
  end)
  return true
end

local function begin_filter()
  if not M.visible() or filtering then
    return
  end
  filtering = true
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, 1, false, { FILTER_PREFIX .. query })
  render(true)
  api.nvim_win_set_cursor(win, { 1, #FILTER_PREFIX + #query })
  vim.cmd('startinsert!')
end

local function sync_filter_line()
  if not filtering or not M.visible() then
    return
  end
  local line = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
  if line:sub(1, #FILTER_PREFIX) ~= FILTER_PREFIX then
    local rest = line:gsub('^%s*/?%s*', '')
    api.nvim_buf_set_lines(buf, 0, 1, false, { FILTER_PREFIX .. rest })
    pcall(api.nvim_win_set_cursor, win, { 1, #FILTER_PREFIX + #rest })
    line = FILTER_PREFIX .. rest
  end
  local next_query = line:sub(#FILTER_PREFIX + 1)
  if next_query ~= query then
    query = next_query
    selected_idx = 1
  end
  render(true)
end

local function bind_keys()
  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set({ 'n', 'x', 's', 'o', 'i' }, '<C-o>', '<Nop>', opts)
  for _, key in ipairs({ 'j', '<Down>', '<Tab>', '<C-n>' }) do
    vim.keymap.set('n', key, function()
      move(1)
    end, opts)
  end
  for _, key in ipairs({ 'k', '<Up>', '<S-Tab>', '<C-p>' }) do
    vim.keymap.set('n', key, function()
      move(-1)
    end, opts)
  end
  for _, key in ipairs({ '<CR>', '<Space>' }) do
    vim.keymap.set('n', key, function()
      M.choose()
    end, opts)
  end
  for i = 1, 5 do
    vim.keymap.set('n', tostring(i), function()
      M.choose(i)
    end, opts)
  end
  for _, key in ipairs({ '/', 'i' }) do
    vim.keymap.set('n', key, begin_filter, opts)
  end
  vim.keymap.set('n', '<BS>', function()
    if query ~= '' then
      query = ''
      selected_idx = 1
      render(false)
    end
  end, opts)
  for _, key in ipairs({ '<Esc>', 'q' }) do
    vim.keymap.set('n', key, function()
      M.close(true)
    end, opts)
  end

  for _, key in ipairs({ '<Down>', '<C-n>', '<Tab>' }) do
    vim.keymap.set('i', key, function()
      move(1)
    end, opts)
  end
  for _, key in ipairs({ '<Up>', '<C-p>', '<S-Tab>' }) do
    vim.keymap.set('i', key, function()
      move(-1)
    end, opts)
  end
  vim.keymap.set('i', '<CR>', function()
    vim.cmd.stopinsert()
    M.choose()
  end, opts)
  vim.keymap.set('i', '<C-u>', function()
    query = ''
    selected_idx = 1
    api.nvim_buf_set_lines(buf, 0, 1, false, { FILTER_PREFIX })
    pcall(api.nvim_win_set_cursor, win, { 1, #FILTER_PREFIX })
    render(true)
  end, opts)
  vim.keymap.set('i', '<Esc>', '<C-\\><C-n>', opts)

  vim.keymap.set('n', '<LeftMouse>', function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == win and mouse.line > 0 then
      vim.schedule(function()
        if not M.visible() then
          return
        end
        if mouse.line == 1 then
          begin_filter()
          return
        end
        local entry = row_map[mouse.line]
        if entry and (not layout_wide or mouse.column <= layout_left_w) then
          M.choose(entry.name)
        end
      end)
      return ''
    end
    return '<LeftMouse>'
  end, { buffer = buf, expr = true, silent = true })

  api.nvim_create_autocmd('TextChangedI', {
    buffer = buf,
    callback = sync_filter_line,
  })
  api.nvim_create_autocmd('InsertLeave', {
    buffer = buf,
    callback = function()
      if not filtering or not M.visible() then
        return
      end
      local line = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
      query = line:gsub('^%s*/?%s*', '')
      filtering = false
      vim.bo[buf].modifiable = false
      render(false)
    end,
  })
  api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if M.visible() then
          M.close(false)
        end
      end)
    end,
  })
end

function M.open(opts)
  opts = type(opts) == 'table' and opts or {}
  if M.visible() then
    M.close(false)
  end
  pcall(vim.cmd.stopinsert)

  local current = api.nvim_get_current_win()
  origin_win = valid(current) and current or nil
  on_select = type(opts.on_select) == 'function' and opts.on_select or nil
  query = ''
  filtering = false
  selected_idx = 1

  local cols = math.max(1, vim.o.columns)
  local rows = math.max(1, vim.o.lines)
  layout_width = math.min(68, math.max(32, cols - 6))
  layout_wide = layout_width >= 58
  layout_left_w = layout_wide and 34 or layout_width
  local height = math.min(14, math.max(6, rows - 6))
  local row = math.max(0, math.floor((rows - height - 2) / 2))
  local col = math.max(0, math.floor((cols - layout_width - 2) / 2))

  buf = api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'setup-agent-picker'

  local footer = layout_wide and ' ↑↓/jk move · 1-5 pick · / filter · Enter open · Esc close '
    or ' jk · 1-5 · / · Enter · Esc '
  local ok, opened = pcall(api.nvim_open_win, buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = layout_width,
    height = height,
    border = 'rounded',
    style = 'minimal',
    zindex = 90,
    title = { { ' New AI Chat ', 'AgentPickerTitle' } },
    title_pos = 'center',
    footer = { { footer, 'AgentPickerFooter' } },
    footer_pos = 'center',
  })
  if not ok or not valid(opened) then
    if valid_buf(buf) then
      pcall(api.nvim_buf_delete, buf, { force = true })
    end
    buf, origin_win, on_select = nil, nil, nil
    return false
  end

  win = opened
  api.nvim_win_call(win, function()
    vim.cmd('clearjumps')
  end)
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].winhighlight = 'FloatBorder:AgentPickerBorder,FloatTitle:AgentPickerTitle,FloatFooter:AgentPickerFooter'

  M.highlights()
  bind_keys()
  render(false)
  return true
end

return M
