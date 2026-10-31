-- Parse NUL-delimited porcelain status in batches to keep the UI responsive.
local M = {}

function M.parse(raw, current, done)
  local groups = { staged = {}, unstaged = {}, history = {} }
  local branch_end = raw:find('\0', 1, true)
  local branch = branch_end and raw:sub(4, branch_end - 1) or 'Git'
  local pos = branch_end and branch_end + 1 or #raw + 1

  local function batch()
    if not current() then
      return
    end
    local count = 0
    while pos <= #raw and count < 200 do
      local stop = raw:find('\0', pos, true)
      if not stop then
        break
      end
      local record = raw:sub(pos, stop - 1)
      pos = stop + 1
      local xy, path = record:sub(1, 2), record:sub(4)
      if #record >= 4 then
        local old
        if xy:find('R', 1, true) or xy:find('C', 1, true) then
          local old_end = raw:find('\0', pos, true)
          old = old_end and raw:sub(pos, old_end - 1) or nil
          pos = old_end and old_end + 1 or #raw + 1
        end
        if xy:sub(1, 1) ~= ' ' and xy ~= '??' then
          groups.staged[#groups.staged + 1] = { path = path, old = old, status = xy:sub(1, 1), group = 'staged' }
        end
        if xy:sub(2, 2) ~= ' ' then
          groups.unstaged[#groups.unstaged + 1] =
            { path = path, old = old, status = xy == '??' and '?' or xy:sub(2, 2), group = 'unstaged' }
        end
      end
      count = count + 1
    end
    if pos <= #raw and raw:find('\0', pos, true) then
      vim.defer_fn(batch, 1)
    else
      done(branch, groups)
    end
  end
  batch()
end

return M
