-- Antigravity CLI keeps the latest conversation ID for each workspace here.
local M = {}

function M.latest(cwd, known, path)
  path = path
    or (vim.env.E2E_DIR and vim.env.E2E_DIR .. '/agy-cache.json')
    or vim.fn.expand('~/.gemini/antigravity-cli/cache/last_conversations.json')
  local fd = vim.uv.fs_open(path, 'r', 384)
  if not fd then
    return nil
  end
  local stat = vim.uv.fs_fstat(fd)
  local raw = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
  vim.uv.fs_close(fd)
  if not raw then
    return nil
  end
  local ok, cache = pcall(vim.json.decode, raw)
  if not ok or type(cache) ~= 'table' then
    return nil
  end
  local workspace = vim.fn.fnamemodify(cwd, ':p'):gsub('/+$', '')
  local id = cache[workspace]
  if type(id) ~= 'string' or #id < 6 or #id > 80 or not id:match('^[%w%-_]+$') then
    return nil
  end
  return not (known and known[id]) and id or nil
end

return M
