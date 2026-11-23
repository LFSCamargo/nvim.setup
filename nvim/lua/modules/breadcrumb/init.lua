-- VS Code-style file path breadcrumb rendered directly underneath the editor winbar.

local M = {}
local api = vim.api
local ns = api.nvim_create_namespace('nvim_setup_breadcrumb')
local rendering = false
local float_wins = {}
local float_bufs = {}

function M.highlights()
  local appearance = require('modules.appearance')
  api.nvim_set_hl(0, 'BreadcrumbDir', { fg = appearance.tab_ink, bg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbSep', { fg = appearance.tab_ink, bg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbIcon', { fg = appearance.tab_ink, bg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbCap', { fg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbFile', { fg = appearance.tab_ink, bg = appearance.tab_accent, bold = true })
  api.nvim_set_hl(0, 'BreadcrumbAction', { fg = appearance.fg, bg = appearance.sep, bold = true })
  api.nvim_set_hl(0, 'BreadcrumbActionCap', { fg = appearance.sep })
end

local function buf_path(buf)
  if not api.nvim_buf_is_valid(buf) then
    return ''
  end
  if vim.bo[buf].filetype == 'git-diff' then
    if type(vim.b[buf].git_diff_path) == 'string' and vim.b[buf].git_diff_path ~= '' then
      return vim.b[buf].git_diff_path
    end
    local diff = package.loaded['modules.diff']
    local src = diff and diff.source_buf and diff.source_buf()
    if src and api.nvim_buf_is_valid(src) then
      return api.nvim_buf_get_name(src)
    end
  end
  return api.nvim_buf_get_name(buf)
end

function M.segments(buf)
  if not api.nvim_buf_is_valid(buf) then
    return nil
  end
  local tabs = package.loaded['modules.tabs']
  if tabs and not tabs.editor_buf(buf) then
    return nil
  end
  local name = buf_path(buf)
  if name == '' then
    return nil
  end
  local norm = vim.fs.normalize(name)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local rel
  if norm:sub(1, #cwd + 1) == cwd .. '/' then
    rel = norm:sub(#cwd + 2)
  else
    rel = vim.fn.fnamemodify(name, ':~')
  end
  local parts = vim.split(rel, '/', { plain = true, trimempty = true })
  if #parts == 0 then
    return nil
  end
  local file = table.remove(parts)
  local icon, icon_hl = require('modules.icons').file_icon(name)
  if icon == ' ' then
    icon, icon_hl = nil, nil
  end
  return {
    dirs = parts,
    file = file,
    icon = icon,
    icon_hl = icon_hl,
    is_diff = vim.bo[buf].filetype == 'git-diff',
  }
end

local function crumb_display_width(dirs, icon, file)
  local w = 1 -- leading space
  for i, dir in ipairs(dirs) do
    w = w + vim.fn.strdisplaywidth(dir)
    w = w + vim.fn.strdisplaywidth(i == #dirs and ' > ' or '  ')
  end
  if icon and icon ~= '' then
    w = w + vim.fn.strdisplaywidth(icon .. ' ')
  end
  w = w + vim.fn.strdisplaywidth(file) + 2 -- trailing space + ''
  return w
end

local function truncate_middle_text(text, max_cells)
  if vim.fn.strdisplaywidth(text) <= max_cells then
    return text
  end
  if max_cells <= 3 then
    return string.rep('.', math.max(0, max_cells))
  end
  local chars = vim.fn.strchars(text)
  local budget = max_cells - 3
  local head_target = math.max(1, math.ceil(budget / 2))
  local tail_target = math.max(0, budget - head_target)
  local head, head_w = '', 0
  for i = 0, chars - 1 do
    local ch = vim.fn.strcharpart(text, i, 1)
    local cw = vim.fn.strdisplaywidth(ch)
    if head_w + cw > head_target then
      break
    end
    head = head .. ch
    head_w = head_w + cw
  end
  local tail, tail_w = '', 0
  for i = chars - 1, 0, -1 do
    local ch = vim.fn.strcharpart(text, i, 1)
    local cw = vim.fn.strdisplaywidth(ch)
    if tail_w + cw > tail_target then
      break
    end
    tail = ch .. tail
    tail_w = tail_w + cw
  end
  return head .. '...' .. tail
end

local function limit_segments(seg, max_width)
  if crumb_display_width(seg.dirs, seg.icon, seg.file) <= max_width then
    return
  end
  local orig = vim.deepcopy(seg.dirs)
  if #orig > 0 then
    local left_count = math.ceil((#orig - 1) / 2)
    local right_count = math.max(0, #orig - 1 - left_count)
    while left_count + right_count >= 0 do
      local candidate = {}
      for i = 1, left_count do
        candidate[#candidate + 1] = orig[i]
      end
      candidate[#candidate + 1] = '...'
      for i = #orig - right_count + 1, #orig do
        candidate[#candidate + 1] = orig[i]
      end
      if crumb_display_width(candidate, seg.icon, seg.file) <= max_width then
        seg.dirs = candidate
        return
      end
      if left_count == 0 and right_count == 0 then
        break
      end
      if left_count > right_count then
        left_count = left_count - 1
      else
        right_count = right_count - 1
      end
    end
    if crumb_display_width({ '...' }, seg.icon, seg.file) <= max_width then
      seg.dirs = { '...' }
      return
    end
    seg.dirs = {}
  end
  local fixed = crumb_display_width(seg.dirs, seg.icon, '')
  local file_budget = math.max(4, max_width - fixed)
  seg.file = truncate_middle_text(seg.file, file_budget)
end

function M.action_label(buf)
  if not api.nvim_buf_is_valid(buf) then
    return nil
  end
  if vim.bo[buf].filetype == 'git-diff' then
    return ' ' .. require('modules.icons').sidebar.files .. ' '
  end
  return ' ± '
end

function M.format(buf, width)
  local seg = M.segments(buf)
  if not seg then
    return nil, nil
  end
  local max_width = width and math.max(12, math.floor(width * 0.80)) or nil
  if max_width then
    limit_segments(seg, max_width)
  end
  local chunks = { { ' ', 'BreadcrumbDir' } }
  local plain = {}
  for i, dir in ipairs(seg.dirs) do
    chunks[#chunks + 1] = { dir, 'BreadcrumbDir' }
    chunks[#chunks + 1] = { i == #seg.dirs and ' > ' or '  ', 'BreadcrumbSep' }
    plain[#plain + 1] = dir
  end
  if seg.icon and seg.icon ~= '' then
    chunks[#chunks + 1] = { seg.icon .. ' ', 'BreadcrumbIcon' }
  end
  chunks[#chunks + 1] = { seg.file, 'BreadcrumbFile' }
  chunks[#chunks + 1] = { ' ', 'BreadcrumbFile' }
  chunks[#chunks + 1] = { '', 'BreadcrumbCap' }
  plain[#plain + 1] = seg.file

  if width then
    local left_w = crumb_display_width(seg.dirs, seg.icon, seg.file)
    local btn = M.action_label(buf)
    local btn_w = 1 + vim.fn.strdisplaywidth(btn) -- '' + button text
    local gap = width - left_w - btn_w
    if gap >= 0 then
      if gap > 0 then
        chunks[#chunks + 1] = { string.rep(' ', gap), 'Normal' }
      end
      chunks[#chunks + 1] = { '', 'BreadcrumbActionCap' }
      chunks[#chunks + 1] = { btn, 'BreadcrumbAction' }
    end
  end

  return table.concat(plain, '  '), chunks
end

function M.button_bounds(win)
  win = win or api.nvim_get_current_win()
  if not (win and api.nvim_win_is_valid(win)) then
    return nil
  end
  local buf = api.nvim_win_get_buf(win)
  if not M.segments(buf) then
    return nil
  end
  local width = api.nvim_win_get_width(win)
  local btn = M.action_label(buf)
  if not btn then
    return nil
  end
  local btn_w = 1 + vim.fn.strdisplaywidth(btn)
  return width - btn_w + 1, width
end

local function resolve_editor_win(win)
  if not (win and win ~= 0 and api.nvim_win_is_valid(win)) then
    return nil
  end
  for parent, fw in pairs(float_wins) do
    if fw == win and api.nvim_win_is_valid(parent) then
      return parent
    end
  end
  return win
end

function M.is_button_click(pos)
  pos = pos or vim.fn.getmousepos()
  local win = resolve_editor_win(pos.winid)
  if not (win and win ~= 0 and api.nvim_win_is_valid(win)) then
    return false
  end
  local buf = api.nvim_win_get_buf(win)
  if not M.segments(buf) then
    return false
  end
  local win_pos = vim.fn.win_screenpos(win)
  local has_winbar = vim.wo[win].winbar ~= ''
  local crumb_screen_row = win_pos[1] + (has_winbar and 1 or 0)
  if pos.screenrow ~= crumb_screen_row then
    return false
  end
  local rel_col = pos.screencol - win_pos[2] + 1
  local start_col, end_col = M.button_bounds(win)
  if not start_col or rel_col < start_col or rel_col > end_col then
    return false
  end
  return true, buf
end

function M.handle_click(pos)
  local hit, buf = M.is_button_click(pos)
  if not hit then
    return false
  end
  return M.toggle_diff(buf)
end

function M.toggle_diff(buf)
  buf = buf or api.nvim_get_current_buf()
  local ok = require('modules.diff').toggle_for_buf(buf)
  M.render()
  return ok
end

function M.clear(buf)
  if api.nvim_buf_is_valid(buf) then
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

local function close_float(w)
  local fw = float_wins[w]
  float_wins[w] = nil
  if fw and api.nvim_win_is_valid(fw) then
    pcall(api.nvim_win_close, fw, true)
  end
  local fb = float_bufs[w]
  float_bufs[w] = nil
  if fb and api.nvim_buf_is_valid(fb) then
    pcall(api.nvim_buf_delete, fb, { force = true })
  end
end

local function sync_float(w, chunks, width)
  if M.use_float == false or #api.nvim_list_uis() == 0 then
    close_float(w)
    return
  end
  local fb = float_bufs[w]
  if not (fb and api.nvim_buf_is_valid(fb)) then
    fb = api.nvim_create_buf(false, true)
    vim.bo[fb].buftype = 'nofile'
    vim.bo[fb].bufhidden = 'wipe'
    vim.bo[fb].swapfile = false
    vim.bo[fb].modifiable = false
    float_bufs[w] = fb
  end
  api.nvim_buf_clear_namespace(fb, ns, 0, -1)
  pcall(api.nvim_buf_set_extmark, fb, ns, 0, 0, {
    virt_text = chunks,
    virt_text_pos = 'overlay',
    hl_mode = 'combine',
  })
  local fw = float_wins[w]
  local cfg = {
    relative = 'win',
    win = w,
    row = 0,
    col = 0,
    width = math.max(1, width),
    height = 1,
    style = 'minimal',
    focusable = false,
    zindex = 45,
  }
  if fw and api.nvim_win_is_valid(fw) then
    pcall(api.nvim_win_set_config, fw, cfg)
  else
    local ok, new_fw = pcall(api.nvim_open_win, fb, false, vim.tbl_extend('force', cfg, { noautocmd = true }))
    if ok and new_fw then
      float_wins[w] = new_fw
      vim.wo[new_fw].winblend = 0
      vim.wo[new_fw].wrap = false
      vim.wo[new_fw].winhighlight = 'Normal:Normal,NormalFloat:Normal'
    end
  end
end

local function clamp_view(w, buf, has_crumb)
  if not api.nvim_win_is_valid(w) or not api.nvim_buf_is_valid(buf) then
    return
  end
  api.nvim_win_call(w, function()
    local view = vim.fn.winsaveview()
    local changed = false
    if has_crumb and view.topfill ~= 1 then
      view.topfill = 1
      changed = true
    elseif not has_crumb and view.topfill ~= 0 then
      view.topfill = 0
      changed = true
    end
    local count = api.nvim_buf_line_count(buf)
    local height = api.nvim_win_get_height(w)
    -- Keep the configured scroll margin as blank padding below EOF in editor windows.
    local bottom_margin = 0
    if has_crumb then
      bottom_margin = tonumber(vim.wo.scrolloff) or tonumber(vim.o.scrolloff) or 5
    end
    local usable = math.max(1, height - (has_crumb and 1 or 0) - bottom_margin)
    local max_top = math.max(1, count - usable + 1)
    if view.topline > max_top then
      view.topline = max_top
      if has_crumb then
        view.topfill = 1
      end
      changed = true
    end
    if changed then
      vim.fn.winrestview(view)
    end
  end)
end

function M.render(win)
  if rendering then
    return
  end
  rendering = true
  local function one(w)
    if not api.nvim_win_is_valid(w) then
      close_float(w)
      return
    end
    local ok, cfg = pcall(api.nvim_win_get_config, w)
    if ok and type(cfg) == 'table' and cfg.relative ~= '' then
      return
    end
    local buf = api.nvim_win_get_buf(w)
    M.clear(buf)
    local width = api.nvim_win_get_width(w)
    local _, chunks = M.format(buf, width)
    if not chunks then
      close_float(w)
      clamp_view(w, buf, false)
      return
    end
    local count = api.nvim_buf_line_count(buf)
    if count < 1 then
      close_float(w)
      return
    end
    clamp_view(w, buf, true)
    local info = vim.fn.getwininfo(w)[1]
    local top = info and info.topline or 1
    local row = math.max(0, math.min(count - 1, top - 1))
    pcall(api.nvim_buf_set_extmark, buf, ns, row, 0, {
      virt_lines = { chunks },
      virt_lines_above = true,
      virt_lines_leftcol = true,
      priority = 100,
    })
    sync_float(w, chunks, width)
  end
  local ok, err = pcall(function()
    if win then
      one(win)
      return
    end
    local seen = {}
    for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
      seen[w] = true
      one(w)
    end
    for w in pairs(float_wins) do
      if not seen[w] or not api.nvim_win_is_valid(w) then
        close_float(w)
      end
    end
  end)
  rendering = false
  if not ok then
    error(err)
  end
end

M.highlights()
local group = api.nvim_create_augroup('NvimSetupBreadcrumb', { clear = true })
api.nvim_create_autocmd('ColorScheme', { group = group, callback = M.highlights })
api.nvim_create_autocmd({
  'BufEnter',
  'BufWinEnter',
  'WinEnter',
  'WinScrolled',
  'VimResized',
  'DirChanged',
  'BufFilePost',
  'FileType',
}, {
  group = group,
  callback = function()
    M.render()
  end,
})

api.nvim_create_autocmd('WinClosed', {
  group = group,
  callback = function(ev)
    local closed = tonumber(ev.match)
    if closed then
      close_float(closed)
    end
  end,
})

return M
