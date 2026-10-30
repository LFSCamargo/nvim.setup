-- Devicons for the Files tree and Git sidebar. Nerd Font glyphs occupy one cell.
local M = {}

pcall(function()
  require('nvim-web-devicons').setup({ default = true, color_icons = true, strict = false })
end)

function M.file_icon(path)
  local name = vim.fn.fnamemodify(path or '', ':t')
  local ext = vim.fn.fnamemodify(name, ':e')
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if ok and devicons.get_icon then
    local icon, hl = devicons.get_icon(name, ext, { default = true })
    if type(icon) == 'string' and icon ~= '' then return icon, hl or 'Normal' end
  end
  return ' ', 'Normal'
end

function M.tree_icons()
  return {
    show = { file = true, folder = true, folder_arrow = true, git = false },
    padding = { icon = ' ', folder_arrow = ' ' },
    web_devicons = {
      file = { enable = true, color = true },
      -- nvim-tree would call get_icon(folder_name) and draw .git / apps as files.
      folder = { enable = false, color = true },
    },
    glyphs = {
      folder = {
        arrow_closed = '>',
        arrow_open = 'v',
        default = '',
        open = '',
        empty = '',
        empty_open = '',
        symlink = '',
        symlink_open = '',
      },
    },
  }
end

return M
