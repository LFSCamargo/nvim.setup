-- Devicons for the Files tree, Git sidebar, and editor tabs. Nerd Font glyphs occupy one cell.
local M = {}

function M.enabled()
  local ok, settings = pcall(require, 'config.settings')
  return not ok or settings.get().icons
end

pcall(function()
  require('nvim-web-devicons').setup({ default = true, color_icons = M.enabled(), strict = false })
end)

function M.file_icon(path)
  if not M.enabled() then
    return ' ', 'Normal'
  end
  local name = vim.fn.fnamemodify(path or '', ':t')
  local ext = vim.fn.fnamemodify(name, ':e')
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if ok and devicons.get_icon then
    local icon, hl = devicons.get_icon(name, ext, { default = true })
    if type(icon) == 'string' and icon ~= '' then
      return icon, hl or 'Normal'
    end
  end
  return ' ', 'Normal'
end

function M.apply()
  local on = M.enabled()
  pcall(function()
    require('nvim-web-devicons').setup({ default = true, color_icons = on, strict = false })
  end)
  pcall(function()
    local cfg = require('nvim-tree.config')
    if cfg.g and cfg.g.renderer then
      cfg.g.renderer.icons = M.tree_icons()
    end
  end)
  pcall(function()
    require('nvim-tree.api').tree.reload()
  end)
end

function M.tree_icons()
  local on = M.enabled()
  return {
    show = { file = on, folder = true, folder_arrow = true, git = false },
    padding = { icon = ' ', folder_arrow = ' ' },
    web_devicons = {
      file = { enable = on, color = on },
      -- nvim-tree would call get_icon(folder_name) and draw .git / apps as files.
      folder = { enable = false, color = false },
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
