-- Project homescreen shown when no editor tabs are open.
-- Uses MaximilianLloyd/ascii.nvim's Futurama spaceship with colors behind a NeoVim banner.

local M = {}
local api = vim.api
local ns = api.nvim_create_namespace('nvim_setup_home')

local NEOVIM_BANNER = {
  '  █▄░█ █▀▀ █▀█ █░█ █ █▀▄▀█  ',
  '  █░▀█ ██▄ █▄█ ▀▄▀ █ █░▀░█  ',
}

local MENU_ITEMS = {
  {
    key = 'f',
    icon = '󰈞',
    label = 'Find File',
    hint = 'SPC f f',
    run = function()
      vim.cmd('FindProjectFiles')
    end,
  },
  {
    key = 'r',
    icon = '󰋚',
    label = 'Recent File',
    hint = 'SPC f r',
    run = function()
      require('fzf-lua').oldfiles({
        actions = { ['enter'] = require('modules.tabs').open_from_fzf },
      })
    end,
  },
  {
    key = 'w',
    icon = '󰊄',
    label = 'Find Word',
    hint = 'SPC f g',
    run = function()
      vim.cmd('FindProjectText')
    end,
  },
  {
    key = 'n',
    icon = '󰈔',
    label = 'New File',
    hint = 'C-t',
    run = function()
      require('modules.tabs').new()
    end,
  },
  {
    key = 't',
    icon = '󰏘',
    label = 'Themes',
    hint = 'SPC t h',
    run = function()
      vim.cmd('SetupThemes')
    end,
  },
  {
    key = 's',
    icon = '󰒓',
    label = 'Settings',
    hint = 'C-,',
    run = function()
      vim.cmd('SetupSettings')
    end,
  },
}

local home_buf = nil
local menu_rows = {}
local active_index = 1

local function spaceship_art()
  local ok, futurama = pcall(require, 'ascii.cartoons.futurama')
  if ok and type(futurama) == 'table' and type(futurama.spaceship) == 'table' and #futurama.spaceship > 0 then
    return futurama.spaceship
  end
  return require('modules.home.art')
end

function M.highlights()
  local appearance = require('modules.appearance')
  -- Planet Express spaceship palette + bright NeoVim banner.
  api.nvim_set_hl(0, 'HomeShipHull', { fg = '#7ec8a0' })
  api.nvim_set_hl(0, 'HomeShipStripe', { fg = '#fb4934' })
  api.nvim_set_hl(0, 'HomeShipWindow', { fg = '#83a598', bold = true })
  api.nvim_set_hl(0, 'HomeShipEngine', { fg = '#fabd2f' })
  api.nvim_set_hl(0, 'HomeShipDim', { fg = appearance.sep })
  api.nvim_set_hl(0, 'HomeTitle', { fg = '#7aa2f7', bold = true })
  api.nvim_set_hl(0, 'HomeMenuIcon', { fg = '#b4befe' })
  api.nvim_set_hl(0, 'HomeMenuLabel', { fg = appearance.fg })
  api.nvim_set_hl(0, 'HomeMenuActive', { fg = appearance.tab_accent, bold = true })
  api.nvim_set_hl(0, 'HomeMenuHint', { fg = appearance.muted })
end

function M.is_home(buf)
  return buf ~= nil and api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == 'setup-home'
end

local function ship_line_hl(row_idx)
  if row_idx == 4 or row_idx == 5 then
    return 'HomeShipStripe'
  end
  if row_idx >= 11 then
    return 'HomeShipEngine'
  end
  return 'HomeShipHull'
end

local function pad_center(text, width)
  local w = vim.fn.strdisplaywidth(text)
  local pad = math.max(0, math.floor((width - w) / 2))
  return string.rep(' ', pad) .. text, pad
end

-- Overlay a UTF-8 banner centered on top of an ASCII spaceship line, returning
-- the merged line and byte-range highlight spans.
local function overlay_line(bg_line, fg_line, base_hl, pad)
  local bg_w = vim.fn.strdisplaywidth(bg_line)
  local fg_w = vim.fn.strdisplaywidth(fg_line)
  local start_col = math.max(0, math.floor((bg_w - fg_w) / 2))
  local prefix = string.rep(' ', pad)
  local left = vim.fn.strcharpart(bg_line, 0, start_col)
  local right = vim.fn.strcharpart(bg_line, start_col + fg_w)
  local merged = prefix .. left .. fg_line .. right
  local spans = {}
  local col = #prefix
  if #left > 0 then
    spans[#spans + 1] = { col, col + #left, base_hl }
    col = col + #left
  end
  if #fg_line > 0 then
    spans[#spans + 1] = { col, col + #fg_line, 'HomeTitle' }
    col = col + #fg_line
  end
  if #right > 0 then
    spans[#spans + 1] = { col, col + #right, base_hl }
  end
  return merged, spans
end

local function select_menu(win, idx)
  if not home_buf or not api.nvim_buf_is_valid(home_buf) then
    return
  end
  active_index = math.max(1, math.min(#MENU_ITEMS, idx))
  local row = menu_rows[active_index]
  if row and win and api.nvim_win_is_valid(win) then
    pcall(api.nvim_win_set_cursor, win, { row, 0 })
    M.render(win)
  end
end

local function run_item(idx)
  local item = MENU_ITEMS[idx or active_index]
  if item and item.run then
    item.run()
  end
end

function M.render(win)
  if not home_buf or not api.nvim_buf_is_valid(home_buf) then
    return
  end
  win = win and api.nvim_win_is_valid(win) and win or api.nvim_get_current_win()
  local width = math.max(40, api.nvim_win_get_width(win))
  local height = math.max(20, api.nvim_win_get_height(win))
  local art = spaceship_art()
  local overlay_start = math.max(1, math.floor((#art - #NEOVIM_BANNER) / 2) + 1)

  local lines = {}
  local hls = {}
  menu_rows = {}

  local total_content = #art + 2 + (#MENU_ITEMS * 2 - 1)
  local top_pad = math.max(1, math.floor((height - total_content) / 2))
  for _ = 1, top_pad do
    lines[#lines + 1] = ''
  end

  for i, raw in ipairs(art) do
    local base_hl = ship_line_hl(i)
    local banner_idx = i - overlay_start + 1
    local row_idx = #lines
    if banner_idx >= 1 and banner_idx <= #NEOVIM_BANNER then
      local _, pad = pad_center(raw, width)
      local merged, spans = overlay_line(raw, NEOVIM_BANNER[banner_idx], base_hl, pad)
      lines[#lines + 1] = merged
      for _, sp in ipairs(spans) do
        hls[#hls + 1] = { row_idx, sp[1], sp[2], sp[3] }
      end
    else
      local centered, pad = pad_center(raw, width)
      lines[#lines + 1] = centered
      hls[#hls + 1] = { row_idx, pad, #centered, base_hl }
      -- Highlight cockpit porthole and signature distinctly.
      local o_pos = centered:find('O', pad + 1, true)
      if o_pos and i == 4 then
        hls[#hls + 1] = { row_idx, o_pos - 1, o_pos, 'HomeShipWindow' }
      end
      local sst = centered:find('SSt', pad + 1, true)
      if sst then
        hls[#hls + 1] = { row_idx, sst - 1, sst + 2, 'HomeShipDim' }
      end
    end
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = ''

  local menu_width = 36
  for i, item in ipairs(MENU_ITEMS) do
    local left_text = item.icon .. '  ' .. item.label
    local right_text = item.hint
    local gap = math.max(2, menu_width - vim.fn.strdisplaywidth(left_text) - vim.fn.strdisplaywidth(right_text))
    local row_text = left_text .. string.rep(' ', gap) .. right_text
    local centered, pad = pad_center(row_text, width)
    local row_idx = #lines
    lines[#lines + 1] = centered
    menu_rows[i] = row_idx + 1

    local icon_end = pad + #item.icon
    local label_start = icon_end + 2
    local label_end = label_start + #item.label
    local hint_start = label_end + gap
    hls[#hls + 1] = { row_idx, pad, icon_end, 'HomeMenuIcon' }
    hls[#hls + 1] = { row_idx, label_start, label_end, i == active_index and 'HomeMenuActive' or 'HomeMenuLabel' }
    hls[#hls + 1] = { row_idx, hint_start, #centered, 'HomeMenuHint' }

    if i < #MENU_ITEMS then
      lines[#lines + 1] = ''
    end
  end

  vim.bo[home_buf].modifiable = true
  api.nvim_buf_set_lines(home_buf, 0, -1, false, lines)
  vim.bo[home_buf].modifiable = false
  vim.bo[home_buf].modified = false

  api.nvim_buf_clear_namespace(home_buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    pcall(api.nvim_buf_add_highlight, home_buf, ns, h[4], h[1], h[2], h[3])
  end
end

local function configure_win(win)
  if not api.nvim_win_is_valid(win) then
    return
  end
  if not vim.w[win].home_options then
    local saved = {}
    for _, key in ipairs({ 'number', 'relativenumber', 'signcolumn', 'foldcolumn', 'cursorline', 'wrap' }) do
      saved[key] = vim.wo[win][key]
    end
    vim.w[win].home_options = saved
  end
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
end

local function restore_editor_win(win)
  if not api.nvim_win_is_valid(win) or M.is_home(api.nvim_win_get_buf(win)) then
    return
  end
  local saved = vim.w[win].home_options
  if saved then
    for key, value in pairs(saved) do
      vim.wo[win][key] = value
    end
    vim.w[win].home_options = nil
  end
end

local function bind_keys(buf)
  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set('n', 'j', function()
    select_menu(api.nvim_get_current_win(), active_index % #MENU_ITEMS + 1)
  end, opts)
  vim.keymap.set('n', '<Down>', function()
    select_menu(api.nvim_get_current_win(), active_index % #MENU_ITEMS + 1)
  end, opts)
  vim.keymap.set('n', 'k', function()
    select_menu(api.nvim_get_current_win(), (active_index - 2) % #MENU_ITEMS + 1)
  end, opts)
  vim.keymap.set('n', '<Up>', function()
    select_menu(api.nvim_get_current_win(), (active_index - 2) % #MENU_ITEMS + 1)
  end, opts)
  vim.keymap.set('n', '<CR>', function()
    run_item(active_index)
  end, opts)
  vim.keymap.set('n', '<LeftMouse>', function()
    local pos = vim.fn.getmousepos()
    for i, row in ipairs(menu_rows) do
      if pos.line == row then
        active_index = i
        vim.schedule(function()
          run_item(i)
        end)
        break
      end
    end
    return '<LeftMouse>'
  end, { buffer = buf, expr = true, silent = true })
  for i, item in ipairs(MENU_ITEMS) do
    vim.keymap.set('n', item.key, function()
      active_index = i
      run_item(i)
    end, opts)
  end
end

function M.buf()
  if home_buf and api.nvim_buf_is_valid(home_buf) then
    return home_buf
  end
  home_buf = api.nvim_create_buf(false, true)
  vim.bo[home_buf].buftype = 'nofile'
  vim.bo[home_buf].bufhidden = 'hide'
  vim.bo[home_buf].buflisted = false
  vim.bo[home_buf].swapfile = false
  vim.bo[home_buf].modifiable = false
  vim.bo[home_buf].filetype = 'setup-home'
  pcall(api.nvim_buf_set_name, home_buf, 'Home')
  bind_keys(home_buf)
  return home_buf
end

function M.show(win)
  local buf = M.buf()
  win = win and api.nvim_win_is_valid(win) and win or api.nvim_get_current_win()
  if api.nvim_win_get_buf(win) ~= buf then
    api.nvim_win_set_buf(win, buf)
  end
  configure_win(win)
  M.render(win)
  select_menu(win, active_index)
  return buf
end

function M.menu_items()
  return MENU_ITEMS
end

M.highlights()
local group = api.nvim_create_augroup('NvimSetupHome', { clear = true })
api.nvim_create_autocmd('ColorScheme', { group = group, callback = M.highlights })
api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
  group = group,
  callback = function()
    if not home_buf or not api.nvim_buf_is_valid(home_buf) then
      return
    end
    for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
      if api.nvim_win_get_buf(win) == home_buf then
        M.render(win)
      end
    end
  end,
})
api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  group = group,
  callback = function(ev)
    local win = api.nvim_get_current_win()
    if M.is_home(ev.buf) then
      configure_win(win)
      M.render(win)
    else
      restore_editor_win(win)
    end
  end,
})

return M
