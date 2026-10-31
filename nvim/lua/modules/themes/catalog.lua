-- Fixed list of supported dark colorschemes. Order is familiarity-first.
local function modes(normal, insert, visual, replace, command)
  return {
    Normal = normal,
    Insert = insert,
    Visual = visual,
    Replace = replace,
    Command = command,
    Terminal = normal,
  }
end

local function chrome(spec)
  return {
    tab_accent = spec.accent,
    tab_ink = spec.ink,
    bar_fill = spec.bar,
    powerline_fill = spec.power,
    muted = spec.muted,
    fg = spec.fg,
    sep = spec.sep,
    modes = modes(spec.normal, spec.insert, spec.visual, spec.replace, spec.command),
  }
end

return {
  {
    id = 'gruvbox',
    label = 'Gruvbox Dark',
    flavor = 'Warm',
    aliases = { 'gruvbox' },
    plugin = 'ellisonleao/gruvbox.nvim',
    colorscheme = 'gruvbox',
    shipped = true,
    setup = function()
      local ok, plugin = pcall(require, 'gruvbox')
      if ok then
        plugin.setup({
          transparent_mode = require('modules.settings').get().transparent,
          terminal_colors = false,
          inverse = false,
        })
      end
    end,
    chrome = chrome({
      accent = '#fabd2f',
      ink = '#1d2021',
      bar = '#3c3836',
      power = '#504a31',
      muted = '#a89984',
      fg = '#ebdbb2',
      sep = '#665c54',
      normal = '#d79921',
      insert = '#cc241d',
      visual = '#d65d0e',
      replace = '#9d0006',
      command = '#b57614',
    }),
  },
  {
    id = 'cursor-dark',
    label = 'Cursor Dark',
    flavor = 'Cursor',
    aliases = { 'cursor' },
    plugin = 'ydkulks/cursor-dark.nvim',
    colorscheme = 'cursor-dark',
    setup = function()
      pcall(function()
        require('cursor-dark').setup({
          style = 'dark',
          transparent = require('modules.settings').get().transparent,
        })
      end)
    end,
    chrome = chrome({
      accent = '#3794ff',
      ink = '#181818',
      bar = '#1f1f1f',
      power = '#2b2b2b',
      muted = '#9d9d9d',
      fg = '#d6d6dd',
      sep = '#3c3c3c',
      normal = '#3794ff',
      insert = '#f14c4c',
      visual = '#cca700',
      replace = '#f14c4c',
      command = '#b180d7',
    }),
  },
  {
    id = 'cursor-dark-midnight',
    label = 'Cursor Dark Midnight',
    flavor = 'Cursor',
    aliases = { 'cursor', 'midnight' },
    plugin = 'ydkulks/cursor-dark.nvim',
    colorscheme = 'cursor-dark-midnight',
    setup = function()
      pcall(function()
        require('cursor-dark').setup({
          style = 'dark-midnight',
          transparent = require('modules.settings').get().transparent,
        })
      end)
    end,
    chrome = chrome({
      accent = '#79c0ff',
      ink = '#0d1117',
      bar = '#161b22',
      power = '#21262d',
      muted = '#8b949e',
      fg = '#e6edf3',
      sep = '#30363d',
      normal = '#79c0ff',
      insert = '#ff7b72',
      visual = '#d2a8ff',
      replace = '#ffa198',
      command = '#d2a8ff',
    }),
  },
  {
    id = 'vscode',
    label = 'VS Code Dark+',
    flavor = 'VS Code',
    aliases = { 'vscode', 'vs code', 'dark+' },
    plugin = 'Mofiqul/vscode.nvim',
    colorscheme = 'vscode',
    setup = function()
      pcall(function()
        require('vscode').setup({
          transparent = require('modules.settings').get().transparent,
          italic_comments = true,
        })
      end)
    end,
    chrome = chrome({
      accent = '#007acc',
      ink = '#1e1e1e',
      bar = '#252526',
      power = '#333333',
      muted = '#858585',
      fg = '#d4d4d4',
      sep = '#3c3c3c',
      normal = '#007acc',
      insert = '#16825d',
      visual = '#68217a',
      replace = '#c72e0f',
      command = '#c586c0',
    }),
  },
  {
    id = 'github-dark',
    label = 'GitHub Dark',
    flavor = 'GitHub',
    aliases = { 'github' },
    plugin = 'projekt0n/github-nvim-theme',
    colorscheme = 'github_dark',
    setup = function()
      pcall(function()
        require('github-theme').setup({
          options = { transparent = require('modules.settings').get().transparent },
        })
      end)
    end,
    chrome = chrome({
      accent = '#58a6ff',
      ink = '#0d1117',
      bar = '#161b22',
      power = '#21262d',
      muted = '#8b949e',
      fg = '#c9d1d9',
      sep = '#30363d',
      normal = '#58a6ff',
      insert = '#3fb950',
      visual = '#d2a8ff',
      replace = '#f85149',
      command = '#e3b341',
    }),
  },
  {
    id = 'onedark',
    label = 'One Dark',
    flavor = 'VS Code',
    aliases = { 'atom', 'one dark' },
    plugin = 'navarasu/onedark.nvim',
    colorscheme = 'onedark',
    setup = function()
      pcall(function()
        require('onedark').setup({
          style = 'dark',
          transparent = require('modules.settings').get().transparent,
          ending_tildes = false,
        })
      end)
    end,
    chrome = chrome({
      accent = '#61afef',
      ink = '#1e2127',
      bar = '#2c313c',
      power = '#3b4048',
      muted = '#5c6370',
      fg = '#abb2bf',
      sep = '#3e4452',
      normal = '#61afef',
      insert = '#98c379',
      visual = '#c678dd',
      replace = '#e06c75',
      command = '#e5c07b',
    }),
  },
  {
    id = 'dracula',
    label = 'Dracula',
    flavor = 'Cool',
    aliases = { 'dracula' },
    plugin = 'Mofiqul/dracula.nvim',
    colorscheme = 'dracula',
    setup = function()
      pcall(function()
        require('dracula').setup({
          transparent_bg = require('modules.settings').get().transparent,
        })
      end)
    end,
    chrome = chrome({
      accent = '#bd93f9',
      ink = '#282a36',
      bar = '#21222c',
      power = '#44475a',
      muted = '#6272a4',
      fg = '#f8f8f2',
      sep = '#44475a',
      normal = '#bd93f9',
      insert = '#50fa7b',
      visual = '#ffb86c',
      replace = '#ff5555',
      command = '#f1fa8c',
    }),
  },
  {
    id = 'catppuccin-mocha',
    label = 'Catppuccin Mocha',
    flavor = 'Cool',
    aliases = { 'catppuccin', 'mocha' },
    plugin = 'catppuccin/nvim',
    plugin_name = 'catppuccin',
    colorscheme = 'catppuccin-mocha',
    setup = function()
      pcall(function()
        require('catppuccin').setup({
          flavour = 'mocha',
          transparent_background = require('modules.settings').get().transparent,
        })
      end)
    end,
    chrome = chrome({
      accent = '#cba6f7',
      ink = '#1e1e2e',
      bar = '#181825',
      power = '#313244',
      muted = '#6c7086',
      fg = '#cdd6f4',
      sep = '#45475a',
      normal = '#cba6f7',
      insert = '#a6e3a1',
      visual = '#fab387',
      replace = '#f38ba8',
      command = '#f9e2af',
    }),
  },
  {
    id = 'catppuccin-macchiato',
    label = 'Catppuccin Macchiato',
    flavor = 'Cool',
    aliases = { 'catppuccin', 'macchiato' },
    plugin = 'catppuccin/nvim',
    plugin_name = 'catppuccin',
    colorscheme = 'catppuccin-macchiato',
    setup = function()
      pcall(function()
        require('catppuccin').setup({
          flavour = 'macchiato',
          transparent_background = require('modules.settings').get().transparent,
        })
      end)
    end,
    chrome = chrome({
      accent = '#c6a0f6',
      ink = '#24273a',
      bar = '#1e2030',
      power = '#363a4f',
      muted = '#6e738d',
      fg = '#cad3f5',
      sep = '#494d64',
      normal = '#c6a0f6',
      insert = '#a6da95',
      visual = '#f5a97f',
      replace = '#ed8796',
      command = '#eed49f',
    }),
  },
  {
    id = 'tokyonight',
    label = 'Tokyo Night',
    flavor = 'Cool',
    aliases = { 'tokyo', 'tokyonight' },
    plugin = 'folke/tokyonight.nvim',
    colorscheme = 'tokyonight-night',
    setup = function()
      pcall(function()
        require('tokyonight').setup({
          style = 'night',
          transparent = require('modules.settings').get().transparent,
          terminal_colors = false,
        })
      end)
    end,
    chrome = chrome({
      accent = '#7aa2f7',
      ink = '#1a1b26',
      bar = '#16161e',
      power = '#292e42',
      muted = '#565f89',
      fg = '#c0caf5',
      sep = '#3b4261',
      normal = '#7aa2f7',
      insert = '#9ece6a',
      visual = '#bb9af7',
      replace = '#f7768e',
      command = '#e0af68',
    }),
  },
  {
    id = 'tokyonight-storm',
    label = 'Tokyo Night Storm',
    flavor = 'Cool',
    aliases = { 'tokyo', 'storm' },
    plugin = 'folke/tokyonight.nvim',
    colorscheme = 'tokyonight-storm',
    setup = function()
      pcall(function()
        require('tokyonight').setup({
          style = 'storm',
          transparent = require('modules.settings').get().transparent,
          terminal_colors = false,
        })
      end)
    end,
    chrome = chrome({
      accent = '#7aa2f7',
      ink = '#1f2335',
      bar = '#1a1b26',
      power = '#292e42',
      muted = '#565f89',
      fg = '#c0caf5',
      sep = '#3b4261',
      normal = '#7aa2f7',
      insert = '#9ece6a',
      visual = '#bb9af7',
      replace = '#f7768e',
      command = '#e0af68',
    }),
  },
  {
    id = 'kanagawa-wave',
    label = 'Kanagawa Wave',
    flavor = 'Warm',
    aliases = { 'kanagawa' },
    plugin = 'rebelot/kanagawa.nvim',
    colorscheme = 'kanagawa-wave',
    setup = function()
      pcall(function()
        require('kanagawa').setup({
          theme = 'wave',
          transparent = require('modules.settings').get().transparent,
          colors = { theme = { all = { ui = { bg_gutter = 'none' } } } },
        })
      end)
    end,
    chrome = chrome({
      accent = '#dca561',
      ink = '#1f1f28',
      bar = '#16161d',
      power = '#2a2a37',
      muted = '#727169',
      fg = '#dcd7ba',
      sep = '#363646',
      normal = '#dca561',
      insert = '#98bb6c',
      visual = '#957fb8',
      replace = '#c34043',
      command = '#e6c384',
    }),
  },
  {
    id = 'kanagawa-dragon',
    label = 'Kanagawa Dragon',
    flavor = 'Warm',
    aliases = { 'kanagawa', 'dragon' },
    plugin = 'rebelot/kanagawa.nvim',
    colorscheme = 'kanagawa-dragon',
    setup = function()
      pcall(function()
        require('kanagawa').setup({
          theme = 'dragon',
          transparent = require('modules.settings').get().transparent,
          colors = { theme = { all = { ui = { bg_gutter = 'none' } } } },
        })
      end)
    end,
    chrome = chrome({
      accent = '#c4b28a',
      ink = '#181616',
      bar = '#12120f',
      power = '#282727',
      muted = '#7a7167',
      fg = '#c5c9c5',
      sep = '#393836',
      normal = '#c4b28a',
      insert = '#87a987',
      visual = '#a292a3',
      replace = '#c4746e',
      command = '#c4b28a',
    }),
  },
  {
    id = 'rose-pine',
    label = 'Rosé Pine',
    flavor = 'Warm',
    aliases = { 'rose', 'pine' },
    plugin = 'rose-pine/neovim',
    plugin_name = 'rose-pine',
    colorscheme = 'rose-pine',
    setup = function()
      pcall(function()
        require('rose-pine').setup({
          variant = 'main',
          styles = { transparency = require('modules.settings').get().transparent },
        })
      end)
    end,
    chrome = chrome({
      accent = '#ebbcba',
      ink = '#191724',
      bar = '#1f1d2e',
      power = '#26233a',
      muted = '#6e6a86',
      fg = '#e0def4',
      sep = '#403d52',
      normal = '#ebbcba',
      insert = '#9ccfd8',
      visual = '#c4a7e7',
      replace = '#eb6f92',
      command = '#f6c177',
    }),
  },
  {
    id = 'rose-pine-moon',
    label = 'Rosé Pine Moon',
    flavor = 'Warm',
    aliases = { 'rose', 'moon' },
    plugin = 'rose-pine/neovim',
    plugin_name = 'rose-pine',
    colorscheme = 'rose-pine-moon',
    setup = function()
      pcall(function()
        require('rose-pine').setup({
          variant = 'moon',
          styles = { transparency = require('modules.settings').get().transparent },
        })
      end)
    end,
    chrome = chrome({
      accent = '#c4a7e7',
      ink = '#232136',
      bar = '#2a273f',
      power = '#393552',
      muted = '#6e6a86',
      fg = '#e0def4',
      sep = '#44415a',
      normal = '#c4a7e7',
      insert = '#9ccfd8',
      visual = '#ea9a97',
      replace = '#eb6f92',
      command = '#f6c177',
    }),
  },
  {
    id = 'nord',
    label = 'Nord',
    flavor = 'Cool',
    aliases = { 'nord' },
    plugin = 'gbprod/nord.nvim',
    colorscheme = 'nord',
    setup = function()
      pcall(function()
        require('nord').setup({
          transparent = require('modules.settings').get().transparent,
        })
      end)
    end,
    chrome = chrome({
      accent = '#88c0d0',
      ink = '#2e3440',
      bar = '#3b4252',
      power = '#434c5e',
      muted = '#7b88a1',
      fg = '#eceff4',
      sep = '#4c566a',
      normal = '#88c0d0',
      insert = '#a3be8c',
      visual = '#b48ead',
      replace = '#bf616a',
      command = '#ebcb8b',
    }),
  },
  {
    id = 'everforest',
    label = 'Everforest',
    flavor = 'Warm',
    aliases = { 'everforest', 'forest' },
    plugin = 'neanias/everforest-nvim',
    colorscheme = 'everforest',
    setup = function()
      pcall(function()
        require('everforest').setup({
          background = 'hard',
          transparent_background_level = require('modules.settings').get().transparent and 2 or 0,
        })
      end)
    end,
    chrome = chrome({
      accent = '#a7c080',
      ink = '#272e33',
      bar = '#2d353b',
      power = '#3a464c',
      muted = '#7a8478',
      fg = '#d3c6aa',
      sep = '#4f5b58',
      normal = '#a7c080',
      insert = '#83c092',
      visual = '#d699b6',
      replace = '#e67e80',
      command = '#dbbc7f',
    }),
  },
  {
    id = 'nightfox',
    label = 'Nightfox',
    flavor = 'Cool',
    aliases = { 'nightfox', 'fox' },
    plugin = 'EdenEast/nightfox.nvim',
    colorscheme = 'nightfox',
    setup = function()
      pcall(function()
        require('nightfox').setup({
          options = { transparent = require('modules.settings').get().transparent },
        })
      end)
    end,
    chrome = chrome({
      accent = '#719cd6',
      ink = '#192330',
      bar = '#131a24',
      power = '#212e3f',
      muted = '#738091',
      fg = '#cdcecf',
      sep = '#39506d',
      normal = '#719cd6',
      insert = '#81b29a',
      visual = '#9d79d6',
      replace = '#c94f6d',
      command = '#dbc074',
    }),
  },
  {
    id = 'carbonfox',
    label = 'Carbonfox',
    flavor = 'Minimal',
    aliases = { 'carbon', 'fox' },
    plugin = 'EdenEast/nightfox.nvim',
    colorscheme = 'carbonfox',
    setup = function()
      pcall(function()
        require('nightfox').setup({
          options = { transparent = require('modules.settings').get().transparent },
        })
      end)
    end,
    chrome = chrome({
      accent = '#78a9ff',
      ink = '#161616',
      bar = '#0c0c0c',
      power = '#252525',
      muted = '#7b7c7e',
      fg = '#f2f4f8',
      sep = '#353535',
      normal = '#78a9ff',
      insert = '#25be6a',
      visual = '#be95ff',
      replace = '#ee5396',
      command = '#08bdba',
    }),
  },
  {
    id = 'moonfly',
    label = 'Moonfly',
    flavor = 'Minimal',
    aliases = { 'moonfly' },
    plugin = 'bluz71/vim-moonfly-colors',
    colorscheme = 'moonfly',
    setup = function()
      vim.g.moonflyTransparent = require('modules.settings').get().transparent
      vim.g.moonflyItalics = true
    end,
    chrome = chrome({
      accent = '#80a0ff',
      ink = '#080808',
      bar = '#1c1c1c',
      power = '#262626',
      muted = '#9e9e9e',
      fg = '#c6c6c6',
      sep = '#373737',
      normal = '#80a0ff',
      insert = '#8cc85f',
      visual = '#ae81ff',
      replace = '#ff5454',
      command = '#e3c78a',
    }),
  },
}
