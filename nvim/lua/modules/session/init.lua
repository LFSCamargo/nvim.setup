-- Per-project session: editor tabs (including unsaved snapshots) and AI chat UUIDs.
-- NVIM_CLEAN=1 skips restore and save so a clean window cannot clobber the last session.
-- Swap files are off: unsaved buffers live in session snapshots, and leftover
-- .swp ATTENTION dialogs must not block restore or VimLeavePre cleanup.

vim.o.swapfile = false

local M = { busy = false, exiting = false }
local api = vim.api

local function editor_buf(buf)
  return api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buflisted
    and vim.bo[buf].buftype == ''
    and vim.bo[buf].filetype ~= 'NvimTree'
end

local function editor_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if editor_buf(api.nvim_win_get_buf(win)) then
      return win
    end
  end
end

local function persist_uuid(value)
  return type(value) == 'string' and value:match('^[%x%-]+$') ~= nil and #value >= 8 and #value <= 64
end

local function uuid()
  local hex = vim.fn.sha256(('%s:%s:%s'):format(vim.uv.hrtime(), math.random(), vim.uv.os_getpid()))
  return table.concat({
    hex:sub(1, 8),
    hex:sub(9, 12),
    hex:sub(13, 16),
    hex:sub(17, 20),
    hex:sub(21, 32),
  }, '-')
end

local function write_file(path, text)
  local fd, err = vim.uv.fs_open(path, 'w', 384)
  if not fd then
    return false, err
  end
  vim.uv.fs_write(fd, text)
  vim.uv.fs_close(fd)
  vim.uv.fs_chmod(path, 384)
  return true
end

local function read_file(path)
  local fd = vim.uv.fs_open(path, 'r', 384)
  if not fd then
    return nil
  end
  local stat = vim.uv.fs_fstat(fd)
  local data = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
  vim.uv.fs_close(fd)
  return data
end

function M.clean()
  return vim.env.NVIM_CLEAN == '1'
end

function M.dir()
  local hash = vim.fn.sha256(vim.fn.getcwd())
  return vim.fn.stdpath('state') .. '/nvim-setup-sessions/' .. hash
end

function M.file()
  return M.dir() .. '/session.json'
end

local function snapshot_path(id)
  if not persist_uuid(id) then
    return nil
  end
  return M.dir() .. '/buffers/' .. id
end

local function buf_cursor(buf)
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_get_buf(win) == buf then
      return api.nvim_win_get_cursor(win)
    end
  end
  return { 1, 0 }
end

local function collect_tabs()
  local tabs = {}
  vim.fn.mkdir(M.dir() .. '/buffers', 'p', 448)
  local keep = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if editor_buf(buf) then
      local name = api.nvim_buf_get_name(buf)
      local modified = vim.bo[buf].modified
      local id = vim.b[buf].session_uuid
      if modified then
        if not persist_uuid(id) then
          id = uuid()
          vim.b[buf].session_uuid = id
        end
        local path = snapshot_path(id)
        if path then
          write_file(path, vim.json.encode(api.nvim_buf_get_lines(buf, 0, -1, true)))
          keep[id] = true
        end
      elseif persist_uuid(id) then
        keep[id] = true
      else
        id = nil
      end
      tabs[#tabs + 1] = {
        path = name,
        cursor = buf_cursor(buf),
        modified = modified,
        uuid = id,
      }
    end
  end
  local snap = M.dir() .. '/buffers'
  local handle = vim.uv.fs_scandir(snap)
  while handle do
    local name = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if not keep[name] and persist_uuid(name) then
      vim.uv.fs_unlink(snap .. '/' .. name)
    end
  end
  return tabs
end

local function collect_chats()
  local agents = require('modules.agents')
  agents.capture_pending()
  local ids = vim.tbl_keys(agents.sessions)
  table.sort(ids)
  local sessions = {}
  local active = 1
  for i, id in ipairs(ids) do
    local s = agents.sessions[id]
    sessions[#sessions + 1] = { name = s.name, uuid = s.uuid, label = s.label }
    if agents.active == id then
      active = i
    end
  end
  return { active = active, sessions = sessions }
end

function M.snapshot()
  local win = editor_win()
  local buf = win and api.nvim_win_get_buf(win)
  local tabs = collect_tabs()
  local active = { path = '', uuid = nil }
  if buf and editor_buf(buf) then
    active.path = api.nvim_buf_get_name(buf)
    active.uuid = vim.b[buf].session_uuid
  end
  return {
    cwd = vim.fn.getcwd(),
    editor = { active = active, tabs = tabs },
    chats = collect_chats(),
  }
end

function M.save()
  if M.busy or M.clean() or #api.nvim_list_uis() == 0 then
    return false
  end
  vim.fn.mkdir(M.dir(), 'p', 448)
  local ok, encoded = pcall(vim.json.encode, M.snapshot())
  if not ok then
    return false
  end
  return write_file(M.file(), encoded)
end

function M.load()
  local raw = read_file(M.file())
  if not raw or raw == '' then
    return nil
  end
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= 'table' then
    return nil
  end
  return data
end

local function find_buf(path, id)
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if editor_buf(buf) then
      if persist_uuid(id) and vim.b[buf].session_uuid == id then
        return buf
      end
      if path ~= '' and api.nvim_buf_get_name(buf) == path then
        return buf
      end
    end
  end
end

local function apply_snapshot(buf, id)
  local path = snapshot_path(id)
  if not path then
    return
  end
  local raw = read_file(path)
  if not raw then
    return
  end
  local ok, lines = pcall(vim.json.decode, raw)
  if not ok or type(lines) ~= 'table' then
    return
  end
  api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.bo[buf].modified = true
  vim.b[buf].session_uuid = id
end

local function set_cursor(win, cursor)
  if type(cursor) ~= 'table' or not cursor[1] then
    return
  end
  pcall(api.nvim_win_set_cursor, win, { math.max(1, cursor[1]), math.max(0, cursor[2] or 0) })
end

function M.restore_editor(data)
  local tabs = data and data.editor and data.editor.tabs
  if type(tabs) ~= 'table' or #tabs == 0 then
    return
  end
  local win = editor_win()
  if not win then
    return
  end
  local kept = {}
  for _, tab in ipairs(tabs) do
    local path = type(tab.path) == 'string' and tab.path or ''
    local buf = find_buf(path, tab.uuid)
    api.nvim_set_current_win(win)
    if not buf then
      if path ~= '' then
        pcall(function()
          vim.cmd('edit ' .. vim.fn.fnameescape(path))
        end)
        buf = api.nvim_get_current_buf()
      else
        vim.cmd.enew()
        buf = api.nvim_get_current_buf()
      end
    else
      api.nvim_win_set_buf(win, buf)
    end
    if persist_uuid(tab.uuid) then
      vim.b[buf].session_uuid = tab.uuid
    end
    if tab.modified then
      apply_snapshot(buf, tab.uuid)
    end
    set_cursor(win, tab.cursor)
    kept[buf] = true
  end
  local active = data.editor.active or {}
  local focus = find_buf(active.path or '', active.uuid)
  if focus then
    api.nvim_win_set_buf(win, focus)
  end
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if editor_buf(buf) and not kept[buf] then
      local name = api.nvim_buf_get_name(buf)
      local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
      local empty = name == '' and not vim.bo[buf].modified and (#lines == 0 or (#lines == 1 and lines[1] == ''))
      if empty then
        for _, w in ipairs(api.nvim_list_wins()) do
          if api.nvim_win_get_buf(w) == buf then
            api.nvim_win_set_buf(w, api.nvim_win_get_buf(win))
          end
        end
        pcall(api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

function M.restore_chats(data)
  local chats = data and data.chats
  if type(chats) ~= 'table' or type(chats.sessions) ~= 'table' then
    return
  end
  local agents = require('modules.agents')
  local created = {}
  for _, chat in ipairs(chats.sessions) do
    if type(chat) == 'table' and agents.is_cli(chat.name) then
      local before = agents.active
      agents.new(chat.name, { uuid = chat.uuid, label = chat.label })
      created[#created + 1] = agents.active or before
    end
  end
  local active = tonumber(chats.active)
  if active and created[active] then
    agents.show(created[active])
  end
end

function M.restore()
  if M.clean() or #api.nvim_list_uis() == 0 then
    return false
  end
  local data = M.load()
  if not data then
    return false
  end
  M.busy = true
  local ok, err = pcall(function()
    M.restore_editor(data)
    M.restore_chats(data)
  end)
  M.busy = false
  if not ok then
    error(err)
  end
  return true
end

function M.quit()
  M.exiting = true
  M.save()
  vim.cmd('qa!')
end

vim.api.nvim_create_user_command('SessionQuit', M.quit, {})
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = api.nvim_create_augroup('NvimSetupSession', { clear = true }),
  callback = function()
    M.save()
  end,
})

return M
