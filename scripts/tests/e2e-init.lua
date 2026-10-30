-- Child Neovim startup for e2e.lua: load keys/agents/session and open two fake CLI sessions.
vim.o.mouse = 'a'
package.loaded['nvim-web-devicons'] = {
  setup = function() end,
  get_icon = function(_, ext)
    local icons = { txt = 'T', ts = 'S', rs = 'R', lua = 'L', md = 'D' }
    return icons[ext or ''] or 'F', 'DevIconTest'
  end,
}
vim.api.nvim_set_hl(0, 'DevIconTest', { fg = 0x83a598 })
-- nvim-tree indexes renderer.icons.web_devicons.folder.enable on every Files draw.
package.loaded['nvim-tree.config'] = {
  g = {
    renderer = {
      icons = {
        show = { file = true, folder = true, folder_arrow = true, git = false },
        padding = { icon = ' ', folder_arrow = ' ' },
        web_devicons = {
          file = { enable = true, color = true },
          folder = { enable = false, color = false },
        },
        glyphs = {
          default = 'F',
          symlink = 'L',
          folder = {
            default = 'D',
            open = 'O',
            empty = 'E',
            empty_open = 'Q',
            symlink = 'S',
            symlink_open = 'P',
            arrow_closed = '>',
            arrow_open = 'v',
          },
        },
      },
    },
  },
}
package.loaded['nvim-tree.api'] = {
  config = { mappings = { default_on_attach = function() end } },
  fs = {
    create = function()
      vim.g.context_tree_action = 'create'
    end,
    remove = function()
      vim.g.context_tree_action = 'remove'
    end,
    rename = function()
      vim.g.context_tree_action = 'rename'
    end,
  },
  node = { open = {
    edit = function()
      vim.g.context_tree_action = 'toggle'
    end,
  } },
  tree = {
    open = function() end,
    close = function() end,
    toggle = function() end,
    reload = function() end,
    resize = function() end,
    get_node_under_cursor = function()
      return { type = 'file', absolute_path = vim.env.E2E_DIR .. '/repo/app.ts' }
    end,
  },
}
require('config.appearance')
require('config.statusline')
require('config.session')
require('config.keys')
local editor = vim.api.nvim_get_current_win()
local agents = require('config.agents')
agents.new('codex')
agents.new('cursor')
agents.show(1)
vim.api.nvim_set_current_win(editor)
vim.cmd.stopinsert()
