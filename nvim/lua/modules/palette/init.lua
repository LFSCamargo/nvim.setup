-- Searchable quick actions for coding and configuration.
local M = {}

local actions = {
  {
    'Find file',
    'files',
    function()
      vim.cmd.FindProjectFiles()
    end,
  },
  {
    'Search project text',
    'search',
    function()
      vim.cmd.FindProjectText()
    end,
  },
  {
    'Save file',
    'write',
    function()
      vim.cmd.PaneSave()
    end,
  },
  {
    'Format current file',
    'format',
    function()
      require('conform').format({ async = true, lsp_format = 'fallback' })
    end,
  },
  {
    'Show diagnostics',
    'errors',
    function()
      vim.cmd('Trouble diagnostics toggle')
    end,
  },
  {
    'Git changes',
    'source control',
    function()
      require('modules.sidebar').git()
    end,
  },
  {
    'Open Settings',
    'preferences',
    function()
      require('modules.sidebar').settings()
    end,
  },
  {
    'Open Extensions',
    'plugins tools',
    function()
      require('modules.sidebar').extensions()
    end,
  },
  {
    'Toggle file icons',
    'appearance',
    function()
      local s = require('modules.settings')
      s.set('icons', not s.get().icons)
    end,
  },
  {
    'Toggle line numbers',
    'appearance',
    function()
      local s = require('modules.settings')
      s.set('number', not s.get().number)
    end,
  },
  {
    'Reload settings',
    'preferences',
    function()
      require('modules.settings').reload()
    end,
  },
  {
    'Install extension',
    'plugins',
    function()
      require('modules.extensions').search()
    end,
  },
  {
    'Restart Neovim',
    'reload',
    function()
      require('modules.extensions').restart()
    end,
  },
}

function M.open()
  local labels, lookup = {}, {}
  for _, item in ipairs(actions) do
    local label = item[1] .. '  ·  ' .. item[2]
    labels[#labels + 1] = label
    lookup[label] = item[3]
  end
  require('fzf-lua').fzf_exec(labels, {
    prompt = 'Command > ',
    actions = {
      ['default'] = function(selected)
        local action = selected and lookup[selected[1]]
        if action then
          vim.schedule(action)
        end
      end,
    },
  })
end

return M
