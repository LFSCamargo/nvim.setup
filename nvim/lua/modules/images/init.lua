-- Open image files in the system viewer instead of loading them in the editor.
-- macOS uses `open`; Linux uses `xdg-open` (or `gio open`).
-- Clipboard images and dropped files are saved or resolved, then sent to chat.

local M = {}

local extensions = {
  avif = true,
  bmp = true,
  gif = true,
  ico = true,
  jpeg = true,
  jpg = true,
  png = true,
  svg = true,
  tif = true,
  tiff = true,
  webp = true,
}

local function extension(path)
  if type(path) ~= 'string' then
    return nil
  end
  return path:lower():match('%.([%w]+)$')
end

function M.is_image(path)
  local ext = extension(path)
  return ext ~= nil and extensions[ext] == true
end

function M.patterns()
  local list = {}
  for ext, _ in pairs(extensions) do
    list[#list + 1] = '*.' .. ext
    list[#list + 1] = '*.' .. ext:upper()
  end
  table.sort(list)
  return list
end

function M.resolve_file(path)
  if type(path) ~= 'string' or path == '' or path:find('\0', 1, true) or path:find('[\r\n]') then
    return nil
  end
  local abs = vim.fn.fnamemodify(path, ':p')
  if abs == '' or abs:find('\0', 1, true) then
    return nil
  end
  if vim.fn.filereadable(abs) ~= 1 or vim.fn.isdirectory(abs) == 1 then
    return nil
  end
  return abs
end

local function decode_uri(value)
  value = value:gsub('^file://localhost', '')
  value = value:gsub('^file://', '')
  value = value:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return value
end

function M.parse_paths(text)
  if type(text) ~= 'string' or text == '' or text:find('\0', 1, true) then
    return {}
  end
  local paths = {}
  for line in vim.gsplit(vim.trim(text), '\n', { plain = true, trimempty = true }) do
    local token = vim.trim(line):gsub('^["\']', ''):gsub('["\']$', '')
    local abs = M.resolve_file(decode_uri(token))
    if not abs then
      return {}
    end
    paths[#paths + 1] = abs
  end
  return paths
end

local function write_bytes(path, data)
  if type(data) ~= 'string' or data == '' then
    return false
  end
  local fd = vim.uv.fs_open(path, 'w', 384)
  if not fd then
    return false
  end
  local ok = vim.uv.fs_write(fd, data, 0)
  vim.uv.fs_close(fd)
  return ok and ok > 0
end

local function clipboard_dir()
  local dir = vim.fn.stdpath('cache') .. '/nvim-setup/clipboard'
  vim.fn.mkdir(dir, 'p')
  return dir
end

local function clipboard_dest()
  local name =
    string.format('paste-%s.png', vim.fn.sha256(('%s:%s'):format(vim.uv.hrtime(), vim.uv.os_getpid())):sub(1, 16))
  return clipboard_dir() .. '/' .. name
end

local function save_macos(dest)
  if vim.fn.executable('osascript') == 0 then
    return false
  end
  local script = [[
    set outPath to POSIX file (system attribute "NVIM_SETUP_CLIP_PATH")
    set pngData to missing value
    try
      set pngData to (the clipboard as «class PNGf»)
    end try
    if pngData is missing value then
      error "no image"
    end if
    set fh to open for access outPath with write permission
    set eof of fh to 0
    write pngData to fh
    close access fh
  ]]
  local env = vim.fn.environ()
  env.NVIM_SETUP_CLIP_PATH = dest
  local result = vim.system({ 'osascript', '-e', script }, { env = env, timeout = 5000, text = true }):wait()
  return result.code == 0 and M.resolve_file(dest) ~= nil
end

local function save_from_command(args, dest)
  if vim.fn.executable(args[1]) == 0 then
    return false
  end
  local result = vim.system(args, { timeout = 5000 }):wait()
  if result.code ~= 0 or type(result.stdout) ~= 'string' or result.stdout == '' then
    return false
  end
  return write_bytes(dest, result.stdout) and M.resolve_file(dest) ~= nil
end

function M.save_clipboard()
  if M._save_clipboard then
    return M._save_clipboard()
  end
  local dest = clipboard_dest()
  if vim.fn.has('macunix') == 1 or vim.fn.has('mac') == 1 then
    if save_macos(dest) then
      return dest
    end
  end
  if vim.env.WAYLAND_DISPLAY and save_from_command({ 'wl-paste', '--type', 'image/png', '--no-newline' }, dest) then
    return dest
  end
  if save_from_command({ 'xclip', '-selection', 'clipboard', '-t', 'image/png', '-o' }, dest) then
    return dest
  end
  pcall(vim.uv.fs_unlink, dest)
  return nil
end

local function attach_paths(paths)
  if type(paths) ~= 'table' or #paths == 0 then
    return false
  end
  return require('modules.agents').attach_files(paths)
end

function M.consume_paste(lines)
  if type(lines) ~= 'table' then
    return false
  end
  local paths = M.parse_paths(table.concat(lines, '\n'))
  if #paths > 0 then
    return attach_paths(paths)
  end
  return false
end

function M.handle_drop(files)
  local paths = {}
  for _, file in ipairs(type(files) == 'table' and files or {}) do
    local abs = M.resolve_file(type(file) == 'string' and decode_uri(vim.trim(file)) or nil)
    if abs then
      paths[#paths + 1] = abs
    end
  end
  if #paths == 0 then
    vim.notify('No dropped file to add to chat', vim.log.levels.WARN)
    return false
  end
  return attach_paths(paths)
end

function M.paste()
  local text = vim.fn.getreg('+')
  if type(text) == 'string' and vim.trim(text) ~= '' then
    local paths = M.parse_paths(text)
    if #paths > 0 then
      return attach_paths(paths)
    end
    return false
  end
  local image = M.save_clipboard()
  return image ~= nil and attach_paths({ image })
end

function M.paste_key()
  if M.paste() then
    return
  end
  local text = vim.fn.getreg('+')
  if type(text) ~= 'string' or text == '' then
    return
  end
  local lines = vim.split(text, '\n', { plain = true })
  local mode = vim.fn.mode()
  if mode == 't' then
    local agents = require('modules.agents')
    local session = agents.sessions[agents.active]
    if session and session.job and session.job > 0 then
      vim.api.nvim_chan_send(session.job, text)
    end
    return
  end
  local after = mode:find('[iR]') == nil
  vim.api.nvim_put(lines, 'c', after, true)
end

function M.opener()
  if M._opener then
    return M._opener()
  end
  if vim.fn.has('macunix') == 1 or vim.fn.has('mac') == 1 then
    local bin = vim.fn.exepath('open')
    if bin ~= '' then
      return { bin }
    end
  end
  local xdg = vim.fn.exepath('xdg-open')
  if xdg ~= '' then
    return { xdg }
  end
  local gio = vim.fn.exepath('gio')
  if gio ~= '' then
    return { gio, 'open' }
  end
  return nil
end

function M.command(path)
  local abs = M.resolve_file(path)
  local opener = M.opener()
  if not abs or not opener then
    return nil
  end
  local args = {}
  for _, part in ipairs(opener) do
    args[#args + 1] = part
  end
  args[#args + 1] = abs
  return args
end

function M.open(path)
  local abs = M.resolve_file(path)
  if not abs then
    return false
  end
  if M._open then
    return M._open(abs) ~= false
  end
  local args = M.command(abs)
  if not args then
    vim.notify('No system opener (open or xdg-open)', vim.log.levels.WARN)
    return false
  end
  vim.system(args, { detach = true })
  return true
end

function M.consume(path)
  if not M.is_image(path) then
    return false
  end
  return M.open(path)
end

local function abandon(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    local ok, tabs = pcall(require, 'modules.tabs')
    if ok then
      tabs.ensure()
    end
  end)
end

function M.handle_read(buf, path)
  M.open(path)
  abandon(buf)
  return true
end

local function current_image()
  local path = vim.api.nvim_buf_get_name(0)
  if M.is_image(path) then
    return path
  end
  vim.notify('Not an image file', vim.log.levels.INFO)
  return nil
end

local group = vim.api.nvim_create_augroup('NvimSetupImages', { clear = true })

vim.api.nvim_create_autocmd('BufReadCmd', {
  group = group,
  pattern = M.patterns(),
  callback = function(ev)
    M.handle_read(ev.buf, ev.file)
  end,
})

pcall(vim.api.nvim_create_autocmd, 'Drop', {
  group = group,
  callback = function()
    M.handle_drop(vim.v.event.files)
  end,
})

if not vim.env.E2E_DIR then
  local native_paste = vim.paste
  vim.paste = function(lines, phase)
    if phase == -1 or phase == 1 then
      local paths = M.parse_paths(table.concat(type(lines) == 'table' and lines or {}, '\n'))
      if #paths > 0 then
        vim.schedule(function()
          attach_paths(paths)
        end)
        return true
      end
    end
    return native_paste(lines, phase)
  end
end

if not vim.env.E2E_DIR then
  local native_paste = vim.paste
  vim.paste = function(lines, phase)
    if phase == -1 or phase == 1 then
      local paths = M.parse_paths(table.concat(type(lines) == 'table' and lines or {}, '\n'))
      if #paths > 0 then
        vim.schedule(function()
          attach_paths(paths)
        end)
        return true
      end
    end
    return native_paste(lines, phase)
  end
end

if not vim.env.E2E_DIR then
  local native_paste = vim.paste
  vim.paste = function(lines, phase)
    if phase == -1 or phase == 1 then
      local paths = M.parse_paths(table.concat(type(lines) == 'table' and lines or {}, '\n'))
      if #paths > 0 then
        vim.schedule(function()
          attach_paths(paths)
        end)
        return true
      end
    end
    return native_paste(lines, phase)
  end
end

vim.api.nvim_create_user_command('ImageOpen', function()
  local path = current_image()
  if path then
    M.open(path)
  end
end, {})

vim.api.nvim_create_user_command('PasteToChat', function()
  if not M.paste() then
    vim.notify('Clipboard has no image or file to add to chat', vim.log.levels.INFO)
  end
end, {})

return M
