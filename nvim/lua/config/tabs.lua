-- Clickable winbar tabs for editor buffers and chat sessions.
-- Statusline-format clicks call the _G helpers below (Neovim's %T / @v:lua protocol).

local M = {}
local api = vim.api

local function editor_buf(buf)
  return api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ''
end

local function editor_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if editor_buf(api.nvim_win_get_buf(win)) then return win end
  end
end

-- Winbar clicks report the window under the mouse; fall back to the current window.
local function clicked_win()
  local win = vim.fn.getmousepos().winid
  return win ~= 0 and api.nvim_win_is_valid(win) and win or api.nvim_get_current_win()
end

-- Statusline items treat % as a control character, so escape it in labels.
local function escape(s)
  return s:gsub('%%', '%%%%'):gsub('[\r\n]', ' ')
end

local function tab(id, label, active, callback)
  return '%#' .. (active and 'PaneTabActive' or 'PaneTabInactive')
    .. '#%' .. id .. '@v:lua.' .. callback .. '@ ' .. escape(label) .. ' %T'
end

function M.render()
  local win = vim.g.statusline_winid
  if not win or not api.nvim_win_is_valid(win) then win = api.nvim_get_current_win() end
  local buf = api.nvim_win_get_buf(win)
  local agents = require('config.agents')
  local out = {}
  local available = math.max(8, api.nvim_win_get_width(win) - 16)

  -- Show a window of tabs around the active one when they overflow the pane width.
  local function append(items, callback)
    local active = 1
    for i, item in ipairs(items) do
      if item.active then active = i end
    end
    local slots = math.max(1, math.floor(available / 14))
    local first = math.max(1, math.min(active - math.floor(slots / 2), #items - slots + 1))
    local last = math.min(#items, first + slots - 1)
    local label_width = math.max(4, math.floor(available / math.max(1, last - first + 1)) - 2)
    for i = first, last do
      local item = items[i]
      local label = item.label
      if vim.fn.strdisplaywidth(label) > label_width then
        label = vim.fn.strcharpart(label, 0, label_width - 1) .. '…'
      end
      out[#out + 1] = tab(item.id, label, item.active, callback)
    end
    if #items > slots then
      out[#out + 1] = '%#PaneTabInactive#%1@v:lua.PaneTabCycle@ ‹ %T%2@v:lua.PaneTabCycle@ › %T'
    end
  end

  if agents.is_chat(buf) then
    local ids = vim.tbl_keys(agents.sessions)
    table.sort(ids)
    local items = {}
    for _, id in ipairs(ids) do
      local s = agents.sessions[id]
      items[#items + 1] = {
        id = id,
        label = s.label .. (s.exited and ' (exited)' or ''),
        active = s.buf == buf,
      }
    end
    append(items, 'ChatTabClick')
    out[#out + 1] = '%#PaneTabInactive#%0@v:lua.ChatTabNew@ + %T%0@v:lua.PaneTabClose@ × %T'
  elseif editor_buf(buf) then
    local items = {}
    for _, b in ipairs(api.nvim_list_bufs()) do
      if editor_buf(b) then
        local name = api.nvim_buf_get_name(b)
        local label = name == '' and '[New]' or vim.fn.fnamemodify(name, ':t')
        items[#items + 1] = {
          id = b,
          label = label .. (vim.bo[b].modified and ' ●' or ''),
          active = b == buf,
        }
      end
    end
    append(items, 'EditorTabClick')
    out[#out + 1] = '%#PaneTabInactive#%0@v:lua.EditorTabNew@ + %T%0@v:lua.PaneTabClose@ × %T'
  end
  return table.concat(out) .. '%#Normal#'
end

function M.new()
  local win = editor_win()
  if win then api.nvim_set_current_win(win) else vim.cmd('topleft vsplit') end
  vim.cmd.enew()
end

function M.close()
  local buf = api.nvim_get_current_buf()
  local agents = require('config.agents')
  if agents.is_chat(buf) then
    agents.close(vim.b[buf].chat_id)
    return
  end
  if not editor_buf(buf) then return end
  if vim.bo[buf].modified then
    vim.notify('Save changes before closing this file (Ctrl+S)', vim.log.levels.WARN)
    return
  end
  local replacement
  for _, b in ipairs(api.nvim_list_bufs()) do
    if b ~= buf and editor_buf(b) then
      replacement = b
      break
    end
  end
  replacement = replacement or api.nvim_create_buf(true, false)
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_get_buf(win) == buf then api.nvim_win_set_buf(win, replacement) end
  end
  api.nvim_buf_delete(buf, {})
end

-- Ctrl+T / "+" : new chat picker in the chat pane, otherwise a new editor buffer.
function M.new_context()
  if require('config.agents').is_chat(api.nvim_get_current_buf()) then
    require('config.agents').select()
  else
    M.new()
  end
end

function M.save()
  local win = editor_buf(api.nvim_get_current_buf()) and api.nvim_get_current_win() or editor_win()
  if not win then return end
  api.nvim_win_call(win, function()
    if api.nvim_buf_get_name(0) == '' then
      vim.ui.input({ prompt = 'Save file as: ', completion = 'file' }, function(path)
        if path and path ~= '' then
          local buf = api.nvim_win_get_buf(win)
          api.nvim_buf_call(buf, function()
            vim.cmd('write ' .. vim.fn.fnameescape(path))
          end)
        end
      end)
    else
      vim.cmd.write()
    end
  end)
end

_G.PaneTabCycle = function(direction, _, button)
  if button ~= 'l' then return end
  local win = clicked_win()
  local buf = api.nvim_win_get_buf(win)
  local agents = require('config.agents')
  local ids, current = {}, 1
  local chat = agents.is_chat(buf)
  if chat then
    ids = vim.tbl_keys(agents.sessions)
    table.sort(ids)
  else
    for _, b in ipairs(api.nvim_list_bufs()) do
      if editor_buf(b) then ids[#ids + 1] = b end
    end
  end
  for i, id in ipairs(ids) do
    if (chat and agents.sessions[id].buf or id) == buf then current = i end
  end
  if #ids == 0 then return end
  local id = ids[(current - 1 + (direction == 1 and -1 or 1)) % #ids + 1]
  if chat then
    agents.show(id)
  else
    api.nvim_set_current_win(win)
    api.nvim_win_set_buf(win, id)
  end
end

_G.EditorTabClick = function(id, _, button)
  if button ~= 'l' or not editor_buf(id) then return end
  local win = clicked_win()
  if not editor_buf(api.nvim_win_get_buf(win)) then win = editor_win() end
  if win then
    api.nvim_set_current_win(win)
    api.nvim_win_set_buf(win, id)
  end
end

_G.ChatTabClick = function(id, _, button)
  if button == 'l' then require('config.agents').show(id) end
end

_G.EditorTabNew = function(_, _, button)
  if button == 'l' then M.new() end
end

_G.ChatTabNew = function(_, _, button)
  if button == 'l' then require('config.agents').select() end
end

_G.PaneTabClose = function(_, _, button)
  if button == 'l' then
    api.nvim_set_current_win(clicked_win())
    M.close()
  end
end

local function highlights()
  api.nvim_set_hl(0, 'PaneTabActive', { fg = '#fabd2f', bold = true, underline = true })
  api.nvim_set_hl(0, 'PaneTabInactive', { fg = '#a89984' })
end
highlights()
api.nvim_create_autocmd('ColorScheme', { callback = highlights })
vim.opt.showtabline = 0
vim.opt.hidden = true

local function refresh()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local buf = api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'NvimTree' or vim.bo[buf].filetype == 'git-composer' then
      vim.wo[win].winbar = "%!v:lua.require'config.sidebar'.winbar()"
    elseif vim.bo[buf].filetype == 'git-changes' then
      vim.wo[win].winbar = ''
    else
      vim.wo[win].winbar = (editor_buf(buf) or require('config.agents').is_chat(buf))
        and "%!v:lua.require'config.tabs'.render()" or ''
    end
  end
  vim.cmd('redrawstatus')
end

api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'WinEnter', 'BufModifiedSet', 'VimEnter' }, {
  callback = refresh,
})
vim.schedule(refresh)
return M
