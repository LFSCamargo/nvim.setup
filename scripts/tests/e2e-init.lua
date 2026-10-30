-- Child Neovim startup for e2e.lua: load keys/agents/session and open two fake CLI sessions.
vim.o.mouse = 'a'
package.loaded['nvim-web-devicons'] = {
  setup = function() end,
  get_icon = function(_, ext)
    local icons = { txt = 'T', ts = 'S', rs = 'R', lua = 'L', md = 'D' }
    return icons[ext or ''] or 'F', 'DevIconTest'
  end,
}
-- nvim-tree indexes renderer.icons.web_devicons.folder.enable on every Files draw.
package.loaded['nvim-tree.config'] = {
  g = {
    renderer = {
      icons = {
        show = { file = true, folder = true, folder_arrow = true, git = false },
        padding = { icon = ' ', folder_arrow = ' ' },
        web_devicons = {
          file = { enable = true, color = true },
          folder = { enable = false, color = true },
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
  tree = {
    open = function() end,
    close = function() end,
    toggle = function() end,
    reload = function() end,
    resize = function() end,
  },
}
require('config.appearance')
require('config.session')
require('config.keys')
local editor = vim.api.nvim_get_current_win()
local agents = require('config.agents')
agents.new('codex')
agents.new('cursor')
agents.show(1)
vim.api.nvim_set_current_win(editor)
vim.cmd.stopinsert()
