-- Headless packaging check: Neovim version, plugins, Mason tools, parsers, keys, transparency.
local api = vim.api
assert(vim.fn.has('nvim-0.12') == 1, 'Neovim 0.12+ required')
assert(vim.g.colors_name == 'gruvbox', 'Gruvbox did not load')
assert(vim.o.mouse:find('a'), 'Mouse support missing')
assert(vim.o.showtabline == 0, 'Global tab bar must be hidden')
for _, key in ipairs({ '<C-s>', '<C-t>', '<C-w>', '<C-]>', '<C-,>' }) do
  assert(vim.fn.maparg(key, 'n') ~= '', 'Missing keybinding: ' .. key)
end
for _, name in ipairs({
  'modules.agents',
  'modules.session',
  'modules.tabs',
  'modules.icons',
  'modules.statusline',
  'modules.format',
  'modules.settings',
  'modules.images',
  'cmp',
  'nvim-tree.api',
  'dap',
  'conform',
  'fzf-lua',
  'nvim-web-devicons',
}) do
  assert(pcall(require, name), 'Could not load module: ' .. name)
end
local registry = require('mason-registry')
for _, name in ipairs(require('modules.tooling').packages) do
  assert(registry.get_package(name):is_installed(), 'Missing Mason package: ' .. name)
end
for _, lang in ipairs(require('modules.tooling').parsers) do
  assert(pcall(vim.treesitter.language.add, lang), 'Missing syntax parser: ' .. lang)
end
for _, pair in ipairs({ { 'vim', 'let g:example = 1' }, { 'zsh', 'export EXAMPLE=ok' } }) do
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, { pair[2] })
  vim.bo[buf].filetype = pair[1]
  vim.treesitter.start(buf)
  assert(vim.treesitter.highlighter.active[buf], 'Highlighting failed: ' .. pair[1])
  api.nvim_buf_delete(buf, { force = true })
end
-- Let deferred plugin highlights and transparency cleanup finish before checking.
vim.defer_fn(function()
  local ok, err = pcall(function()
    local appearance = require('modules.appearance')
    for name, hl in pairs(api.nvim_get_hl(0, { link = false })) do
      if not appearance.keeps_fill(name) then
        assert(not hl.bg and not hl.ctermbg and not hl.reverse, 'Unexpected background: ' .. name)
      end
    end
    local visual = api.nvim_get_hl(0, { name = 'Visual', link = false })
    assert(visual.bg or visual.ctermbg or visual.reverse, 'Visual selection needs a background')
    for _, name in ipairs(require('modules.statusline').fill_highlights) do
      local hl = api.nvim_get_hl(0, { name = name, link = false })
      assert(hl.bg or hl.ctermbg, 'statusline fill missing: ' .. name)
    end
    assert(vim.o.laststatus == 3, 'statusline must be global')
    assert(vim.o.showmode == false, 'mode must live in the statusline')
    local winbar = api.nvim_get_hl(0, { name = 'WinBar', link = false })
    local sep = api.nvim_get_hl(0, { name = 'PaneTabSep', link = false })
    for _, name in ipairs({ 'PaneTabActive', 'SidebarTabActive' }) do
      local hl = api.nvim_get_hl(0, { name = name, link = false })
      assert(hl.bg == tonumber(appearance.tab_accent:sub(2), 16), name .. ' needs a yellow background')
      assert(hl.fg == tonumber(appearance.tab_ink:sub(2), 16), name .. ' needs black text and icons')
    end
    assert(not winbar.bg and not winbar.ctermbg, 'WinBar must stay transparent')
    assert(not sep.bg and not sep.ctermbg, 'PaneTabSep must stay transparent')
    assert(not winbar.underline, 'WinBar must not use a bright underline')
    local formatters = require('modules.format').formatters_by_ft
    assert(formatters.lua[1] == 'stylua', 'Lua must format with StyLua')
    assert(formatters.html[1] == 'prettierd', 'HTML must format with prettierd')
    assert(formatters.sh[1] == 'shfmt', 'shell must format with shfmt')
    assert(vim.tbl_isempty(require('modules.agents').sessions), 'Headless startup launched chats')
    print('PASS: configuration, plugins, Mason tools, parsers, highlighting, transparency and shortcuts')
  end)
  if not ok then
    print(err)
    vim.cmd('cquit 1')
  else
    vim.cmd('qa!')
  end
end, 1300)
