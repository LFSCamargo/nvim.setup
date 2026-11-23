-- Behavioral assertions run inside the simulated UI child by e2e.lua.
return function()
  local api = vim.api
  local home = require('modules.home')
  local crumb = require('modules.breadcrumb')
  local tabs = require('modules.tabs')
  local diff = require('modules.diff')
  tabs.open(vim.env.E2E_DIR .. '/repo/app.ts')
  local buf = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()
  local original_name = api.nvim_buf_get_name(buf)
  api.nvim_buf_set_name(buf, vim.env.E2E_DIR .. '/repo/nvim/lua/modules/keys/init.lua')
  assert(crumb.segments(buf).file == 'init.lua')
  local _, chunks = crumb.format(buf)
  local text = ''
  local appearance = require('modules.appearance')
  local accent = tonumber(appearance.tab_accent:sub(2), 16)
  local sep = tonumber(appearance.sep:sub(2), 16)
  for _, chunk in ipairs(chunks) do
    text = text .. chunk[1]
    local hl = api.nvim_get_hl(0, { name = chunk[2], link = false })
    if chunk[2] == 'BreadcrumbCap' then
      assert(chunk[1] == '' and hl.fg == accent and hl.bg == nil, 'cap must end the yellow fill')
    elseif chunk[2] == 'BreadcrumbActionCap' then
      assert(chunk[1] == '' and hl.fg == sep and hl.bg == nil, 'right action cap must be grayscaled without bg')
    elseif chunk[2] == 'BreadcrumbAction' then
      assert(hl.bg == sep, 'right action button must have grayscaled fill')
    elseif chunk[2] ~= 'Normal' then
      assert(hl.bg == accent, 'every path chunk, including the icon and padding, needs yellow fill')
    end
  end
  assert(text:find('nvim  lua  modules  keys > ', 1, true), text)
  assert(text:find('init.lua ', 1, true), text)

  local _, wide_chunks = crumb.format(buf, 80)
  local wide_text = ''
  for _, chunk in ipairs(wide_chunks) do
    wide_text = wide_text .. chunk[1]
  end
  assert(wide_text:find(' ± ', 1, true), 'editable file breadcrumb must show grayscaled ± button: ' .. wide_text)
  assert(not wide_text:find('│', 1, true), 'breadcrumb button must not contain a pipe separator: ' .. wide_text)

  -- 80% breadcrumb limit: when exceeded, cut the middle of the path and add ...
  local plain_short, short_chunks = crumb.format(buf, 42)
  local left_text = ''
  for _, chunk in ipairs(short_chunks) do
    left_text = left_text .. chunk[1]
    if chunk[2] == 'BreadcrumbCap' then
      break
    end
  end
  assert(
    vim.fn.strdisplaywidth(left_text) <= math.floor(42 * 0.80),
    'breadcrumb path must fit within 80% of available space: '
      .. vim.fn.strdisplaywidth(left_text)
      .. ' > '
      .. math.floor(42 * 0.80)
  )
  assert(plain_short:find('...', 1, true), 'middle truncation must insert ... in path: ' .. plain_short)
  assert(plain_short:find('  init%.lua$'), 'middle truncation must keep filename at end of path: ' .. plain_short)

  crumb.render()
  vim.cmd('redraw')
  local pos = vim.fn.win_screenpos(win)
  local row = ''
  for col = pos[2], pos[2] + api.nvim_win_get_width(win) - 1 do
    row = row .. vim.fn.screenstring(pos[1] + 1, col)
  end
  assert(row:find('init.lua ', 1, true), 'breadcrumb must be visible below tabs: ' .. row)
  assert(row:find(' ± ', 1, true), 'grayscaled diff toggle button must be rendered on the right: ' .. row)
  local ns = api.nvim_create_namespace('nvim_setup_breadcrumb')
  local marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  assert(#marks == 1 and marks[1][4].virt_lines_leftcol, 'breadcrumb must bypass the number gutter')
  assert(row:find('^ [^ ]'), 'breadcrumb must have only one leading space: ' .. row)
  api.nvim_buf_set_name(buf, original_name)

  -- Click the grayscaled ± button to toggle read-only git diff for the file, then click  to go back.
  crumb.render()
  vim.cmd('redraw')
  local start_col, end_col = crumb.button_bounds(win)
  assert(start_col and end_col and end_col == api.nvim_win_get_width(win), 'button bounds must sit on the right edge')
  local click_pos = {
    winid = win,
    screenrow = pos[1] + 1,
    screencol = pos[2] + start_col,
    line = 1,
    column = 1,
  }
  local hit, target_buf = crumb.is_button_click(click_pos)
  assert(hit and target_buf == buf, 'is_button_click must detect click on ± without E565 inside expr mapping')
  assert(crumb.handle_click(click_pos) == true, 'clicking ± must toggle git diff')
  assert(diff.active() and api.nvim_win_get_buf(win) == diff.buffer(), 'diff buffer must open in the editor window')
  local diff_buf = diff.buffer()
  local file_glyph = require('modules.icons').sidebar.files
  assert(crumb.action_label(diff_buf) == ' ' .. file_glyph .. ' ', 'diff buffer must show file icon back button')
  vim.wait(1000, function()
    local lines = api.nvim_buf_get_lines(diff_buf, 0, -1, false)
    return #lines > 1 and not (lines[2] or ''):find('Loading', 1, true)
  end, 20)
  crumb.render()
  vim.cmd('redraw')
  local diff_row = ''
  for col = pos[2], pos[2] + api.nvim_win_get_width(win) - 1 do
    diff_row = diff_row .. vim.fn.screenstring(pos[1] + 1, col)
  end
  assert(diff_row:find('app.ts ', 1, true), 'diff view must preserve file breadcrumb: ' .. diff_row)
  assert(
    diff_row:find(' ' .. file_glyph .. ' ', 1, true),
    'diff view must render file icon button on the right: ' .. diff_row
  )
  assert(crumb.handle_click(click_pos) == true, 'clicking file icon must return to the regular editable file')
  assert(
    not diff.active() and api.nvim_win_get_buf(win) == buf,
    'closing diff from breadcrumb must restore file buffer'
  )

  assert(crumb.segments(home.buf()) == nil)
  local lines = {}
  for i = 1, 80 do
    lines[i] = 'line ' .. i
  end
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_win_set_cursor(win, { 50, 0 })
  vim.cmd('normal! zt')
  crumb.render()
  assert(vim.fn.winsaveview().topfill == 1, 'scrolling must keep the breadcrumb row visible')
  -- Scrolling to the bottom must keep a scroll-margin of blank padding below EOF.
  api.nvim_win_set_cursor(win, { 80, 0 })
  vim.cmd('normal! zt')
  crumb.render()
  local bottom_view = vim.fn.winsaveview()
  local bottom_margin = tonumber(vim.wo[win].scrolloff) or tonumber(vim.o.scrolloff) or 5
  local usable = math.max(1, api.nvim_win_get_height(win) - 1 - bottom_margin)
  local max_top = math.max(1, 80 - usable + 1)
  assert(
    bottom_view.topline == max_top and bottom_view.topfill == 1,
    'bottom scroll must keep '
      .. bottom_margin
      .. ' blank lines below EOF and keep breadcrumb visible: topline='
      .. tostring(bottom_view.topline)
      .. ' max_top='
      .. tostring(max_top)
  )
  assert(api.nvim_win_call(win, function()
    return vim.opt_local.fillchars:get().eob
  end) == ' ', 'mid editor must hide end-of-buffer ~ markers so blank padding looks like spacing')
  vim.bo[buf].modified = false
  assert(#require('modules.home.art') > 10, 'offline spaceship artwork is required')
  tabs.close_editor(buf)
  return true
end
