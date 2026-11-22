-- Behavioral assertions run inside the simulated UI child by e2e.lua.
return function()
  local api = vim.api
  local home = require('modules.home')
  local crumb = require('modules.breadcrumb')
  local tabs = require('modules.tabs')
  tabs.open(vim.env.E2E_DIR .. '/repo/app.ts')
  local buf = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()
  local original_name = api.nvim_buf_get_name(buf)
  api.nvim_buf_set_name(buf, vim.env.E2E_DIR .. '/repo/nvim/lua/modules/keys/init.lua')
  assert(crumb.segments(buf).file == 'init.lua')
  local _, chunks = crumb.format(buf)
  local text = ''
  local appearance = require('modules.appearance')
  for i, chunk in ipairs(chunks) do
    text = text .. chunk[1]
    local hl = api.nvim_get_hl(0, { name = chunk[2], link = false })
    local accent = tonumber(appearance.tab_accent:sub(2), 16)
    if i == #chunks then
      assert(chunk[1] == '' and hl.fg == accent and hl.bg == nil, 'cap must end the yellow fill')
    else
      assert(hl.bg == accent, 'every path chunk, including the icon and padding, needs yellow fill')
    end
  end
  assert(text:find('nvim  lua  modules  keys > ', 1, true), text)
  assert(text:find('init.lua ', 1, true), text)
  crumb.render()
  vim.cmd('redraw')
  local pos = vim.fn.win_screenpos(win)
  local row = ''
  for col = pos[2], pos[2] + api.nvim_win_get_width(win) - 1 do
    row = row .. vim.fn.screenstring(pos[1] + 1, col)
  end
  assert(row:find('init.lua ', 1, true), 'breadcrumb must be visible below tabs: ' .. row)
  local ns = api.nvim_create_namespace('nvim_setup_breadcrumb')
  local marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  assert(#marks == 1 and marks[1][4].virt_lines_leftcol, 'breadcrumb must bypass the number gutter')
  assert(row:find('^ [^ ]'), 'breadcrumb must have only one leading space: ' .. row)
  api.nvim_buf_set_name(buf, original_name)
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
  vim.bo[buf].modified = false
  assert(#require('modules.home.art') > 10, 'offline spaceship artwork is required')
  tabs.close_editor(buf)
  return true
end
