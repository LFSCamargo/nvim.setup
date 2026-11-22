-- Devicons for the Files tree, Git sidebar, editor tabs, and AI agent brand glyphs.
-- Nerd Font and custom agent glyphs occupy one cell.
local M = {}

-- Sidebar header tabs. Git/settings/extensions use heavier glyphs so they
-- fill the cell the way the file icon already does.
M.sidebar = {
  files = '',
  git = '',
  settings = '',
  themes = '',
  extensions = '',
}

-- Custom 1-cell pixel brand glyphs baked into Monocraft Nerd Font and Symbols Nerd Font
-- at unused BMP PUA codepoints U+E100..U+E104 (scripts/python/overlay_fonts.py).
M.agents = {
  codex = { codepoint = 0xE100, glyph = vim.fn.nr2char(0xE100), hl = 'AgentIconCodex', color = '#10a37f' },
  cursor = { codepoint = 0xE101, glyph = vim.fn.nr2char(0xE101), hl = 'AgentIconCursor', color = '#38bdf8' },
  claude = { codepoint = 0xE102, glyph = vim.fn.nr2char(0xE102), hl = 'AgentIconClaude', color = '#d97757' },
  opencode = { codepoint = 0xE103, glyph = vim.fn.nr2char(0xE103), hl = 'AgentIconOpenCode', color = '#e2e8f0' },
  antigravity = { codepoint = 0xE104, glyph = vim.fn.nr2char(0xE104), hl = 'AgentIconAntigravity', color = '#a78bfa' },
}

function M.agent_highlights()
  for _, spec in pairs(M.agents) do
    vim.api.nvim_set_hl(0, spec.hl, { fg = spec.color })
  end
end
M.agent_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = M.agent_highlights })

function M.enabled()
  local settings = package.loaded['modules.settings']
  return type(settings) ~= 'table' or settings.get().icons
end

pcall(function()
  require('nvim-web-devicons').setup({ default = true, color_icons = M.enabled(), strict = false })
end)

function M.agent_glyph(name)
  local spec = type(name) == 'string' and M.agents[name] or nil
  if not spec then
    return ' ', 'Normal'
  end
  return spec.glyph, spec.hl
end

function M.agent_icon(name)
  if not M.enabled() then
    return ' ', 'Normal'
  end
  return M.agent_glyph(name)
end

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
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == 'NvimTree' then
      pcall(function()
        require('nvim-tree.api').tree.reload()
      end)
      break
    end
  end
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
