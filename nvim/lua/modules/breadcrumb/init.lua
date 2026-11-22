-- VS Code-style file path breadcrumb rendered directly underneath the editor winbar.

local M = {}
local api = vim.api
local ns = api.nvim_create_namespace('nvim_setup_breadcrumb')

function M.highlights()
  local appearance = require('modules.appearance')
  api.nvim_set_hl(0, 'BreadcrumbDir', { fg = appearance.tab_ink, bg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbSep', { fg = appearance.tab_ink, bg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbIcon', { fg = appearance.tab_ink, bg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbCap', { fg = appearance.tab_accent })
  api.nvim_set_hl(0, 'BreadcrumbFile', { fg = appearance.tab_ink, bg = appearance.tab_accent, bold = true })
end

function M.segments(buf)
  if not api.nvim_buf_is_valid(buf) then
    return nil
  end
  local tabs = package.loaded['modules.tabs']
  if tabs and not tabs.editor_buf(buf) then
    return nil
  end
  local name = api.nvim_buf_get_name(buf)
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
  }
end

function M.format(buf, width)
  local seg = M.segments(buf)
  if not seg then
    return nil, nil
  end
  if width then
    local shortened = false
    while
      #seg.dirs > 0 and vim.fn.strdisplaywidth(table.concat(seg.dirs, '  ') .. '  ' .. seg.file) > width - 8
    do
      table.remove(seg.dirs, 1)
      shortened = true
    end
    if shortened then
      table.insert(seg.dirs, 1, '…')
    end
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
  return table.concat(plain, '  '), chunks
end

function M.clear(buf)
  if api.nvim_buf_is_valid(buf) then
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

function M.render(win)
  local function one(w)
    if not api.nvim_win_is_valid(w) then
      return
    end
    local ok, cfg = pcall(api.nvim_win_get_config, w)
    if ok and type(cfg) == 'table' and cfg.relative ~= '' then
      return
    end
    local buf = api.nvim_win_get_buf(w)
    M.clear(buf)
    local _, chunks = M.format(buf, api.nvim_win_get_width(w))
    if not chunks then
      return
    end
    local count = api.nvim_buf_line_count(buf)
    if count < 1 then
      return
    end
    local top = vim.fn.getwininfo(w)[1].topline
    local row = math.max(0, math.min(count - 1, top - 1))
    pcall(api.nvim_buf_set_extmark, buf, ns, row, 0, {
      virt_lines = { chunks },
      virt_lines_above = true,
      virt_lines_leftcol = true,
      priority = 100,
    })
    if w == api.nvim_get_current_win() then
      local view = vim.fn.winsaveview()
      view.topfill = 1
      vim.fn.winrestview(view)
    end
  end
  if win then
    one(win)
    return
  end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    one(w)
  end
end

M.highlights()
local group = api.nvim_create_augroup('NvimSetupBreadcrumb', { clear = true })
api.nvim_create_autocmd('ColorScheme', { group = group, callback = M.highlights })
api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'WinEnter', 'WinScrolled', 'DirChanged', 'BufFilePost' }, {
  group = group,
  callback = function()
    M.render()
  end,
})

return M
