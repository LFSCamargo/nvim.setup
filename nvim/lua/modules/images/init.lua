-- Open image files in the system viewer instead of loading them in the editor.
-- macOS uses `open`; Linux uses `xdg-open` (or `gio open`).

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

local function resolve(path)
  if type(path) ~= 'string' or path == '' or path:find('\0', 1, true) then
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
  local abs = resolve(path)
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
  local abs = resolve(path)
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

vim.api.nvim_create_user_command('ImageOpen', function()
  local path = current_image()
  if path then
    M.open(path)
  end
end, {})

return M
