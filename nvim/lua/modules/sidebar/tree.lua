local M = {}
local api = vim.api

local function setup_highlights()
  api.nvim_set_hl(0, 'GitChangeDeleted', { fg = '#cc241d' })
  api.nvim_set_hl(0, 'GitChangeModified', { fg = '#d79921' })
  api.nvim_set_hl(0, 'GitChangeAdded', { fg = '#98971a' })
  api.nvim_set_hl(0, 'GitHelp', { fg = '#928374' })
  api.nvim_set_hl(0, 'GitButton', { fg = '#83a598', bold = true })

  -- Files tree: white unless git has something to say.
  local white = {
    'NvimTreeFolderName',
    'NvimTreeOpenedFolderName',
    'NvimTreeEmptyFolderName',
    'NvimTreeSymlinkFolderName',
    'NvimTreeRootFolder',
    'NvimTreeExecFile',
    'NvimTreeOpenedFile',
    'NvimTreeOpenedHL',
    'NvimTreeSpecialFile',
    'NvimTreeImageFile',
    'NvimTreeSymlink',
    'NvimTreeGitFileIgnoredHL',
    'NvimTreeGitFolderIgnoredHL',
    'NvimTreeGitIgnoredIcon',
  }
  for _, name in ipairs(white) do
    api.nvim_set_hl(0, name, { link = 'Normal' })
  end
  api.nvim_set_hl(0, 'NvimTreeIndentMarker', { fg = '#665c54' })
  api.nvim_set_hl(0, 'NvimTreeFolderArrowClosed', { fg = '#665c54' })
  api.nvim_set_hl(0, 'NvimTreeFolderArrowOpen', { fg = '#665c54' })
  local git = {
    Dirty = '#d79921',
    New = '#98971a',
    Deleted = '#cc241d',
    Staged = '#689d6a',
    Renamed = '#d65d0e',
    Merge = '#d65d0e',
  }
  for kind, fg in pairs(git) do
    api.nvim_set_hl(0, 'NvimTreeGit' .. kind, { fg = fg })
    api.nvim_set_hl(0, 'NvimTreeGit' .. kind .. 'Icon', { fg = fg })
    api.nvim_set_hl(0, 'NvimTreeGitFile' .. kind .. 'HL', { fg = fg })
    api.nvim_set_hl(0, 'NvimTreeGitFolder' .. kind .. 'HL', { fg = fg })
  end
end
setup_highlights()
api.nvim_create_autocmd('ColorScheme', { callback = setup_highlights })
api.nvim_create_autocmd('User', {
  pattern = { 'LazyLoad', 'VeryLazy' },
  callback = function()
    vim.schedule(setup_highlights)
  end,
})
api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.defer_fn(setup_highlights, 120)
    vim.defer_fn(setup_highlights, 1100)
  end,
})

function M.setup(width)
  return {
    on_attach = function(buf)
      local tree = require('nvim-tree.api')
      if tree.config and tree.config.mappings then
        tree.config.mappings.default_on_attach(buf)
      end
      vim.keymap.set('n', '<RightMouse>', function()
        require('modules.context_menu').tree_at_mouse()
      end, { buffer = buf, silent = true, desc = 'File tree context menu' })
    end,
    view = {
      width = function()
        return width()
      end,
    },
    ui = { confirm = { remove = true } },
    renderer = {
      icons = require('modules.icons').tree_icons(),
      highlight_git = 'name',
      highlight_diagnostics = 'none',
      highlight_opened_files = 'none',
      highlight_modified = 'none',
      root_folder_label = false,
    },
    git = { enable = true, show_on_dirs = true },
    diagnostics = { enable = false },
    modified = { enable = false },
    update_focused_file = { enable = true },
  }
end

return M
