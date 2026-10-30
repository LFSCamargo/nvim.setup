-- User extension manifest and visual browser. Built-in plugins stay pinned separately.
local M = {}
local api = vim.api
local buf, win, rows
local mason_query = ''
local mason_results = {}
local editing_search = false
local ns = api.nvim_create_namespace('SetupExtensions')
local featured = {
  'lua-language-server',
  'pyright',
  'typescript-language-server',
  'rust-analyzer',
  'gopls',
  'prettierd',
  'stylua',
  'eslint-lsp',
  'bash-language-server',
  'dockerfile-language-server',
  'yaml-language-server',
}
local catalog = {
  { id = 'folke/todo-comments.nvim', description = 'Highlight and search TODO comments' },
  { id = 'kylechui/nvim-surround', description = 'Edit surrounding quotes and brackets' },
  { id = 'windwp/nvim-autopairs', description = 'Insert matching brackets and quotes' },
  { id = 'numToStr/Comment.nvim', description = 'Toggle code comments' },
  { id = 'folke/flash.nvim', description = 'Jump quickly through visible text' },
}

function M.file()
  if vim.env.E2E_DIR and vim.env.E2E_DIR ~= '' then
    return vim.env.E2E_DIR .. '/extensions.json'
  end
  return vim.fn.stdpath('state') .. '/nvim-setup/extensions.json'
end

local function valid_id(id)
  if type(id) ~= 'string' then
    return false
  end
  local owner, repo = id:match('^([%w%-]+)/([%w_.%-]+)$')
  return owner ~= nil and repo ~= '.' and repo ~= '..' and not repo:find('..', 1, true)
end

function M.read()
  local fd = vim.uv.fs_open(M.file(), 'r', 384)
  if not fd then
    return {}
  end
  local stat = vim.uv.fs_fstat(fd)
  local raw = stat and vim.uv.fs_read(fd, stat.size, 0) or ''
  vim.uv.fs_close(fd)
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= 'table' then
    return {}
  end
  local result = {}
  for _, id in ipairs(data) do
    if valid_id(id) then
      result[#result + 1] = id
    end
  end
  return result
end

local function write(list)
  vim.fn.mkdir(vim.fn.fnamemodify(M.file(), ':h'), 'p')
  local fd, err = vim.uv.fs_open(M.file(), 'w', 384)
  if not fd then
    return false, err
  end
  vim.uv.fs_write(fd, vim.json.encode(list))
  vim.uv.fs_close(fd)
  vim.uv.fs_chmod(M.file(), 384)
  return true
end

function M.specs()
  local specs = {}
  for _, id in ipairs(M.read()) do
    specs[#specs + 1] = { id }
  end
  return specs
end

function M.add(id)
  if not valid_id(id) then
    return false, 'Use owner/repository'
  end
  local list = M.read()
  if not vim.tbl_contains(list, id) then
    list[#list + 1] = id
  end
  local ok, err = write(list)
  if ok then
    vim.notify(id .. ' added. Restart Neovim to install and load it.')
  end
  if M.visible() then
    M.render()
  end
  return ok, err
end

function M.remove(id)
  local list = M.read()
  local result = {}
  for _, item in ipairs(list) do
    if item ~= id then
      result[#result + 1] = item
    end
  end
  local ok, err = write(result)
  if ok then
    vim.notify(id .. ' removed. Restart Neovim to unload it.')
  end
  if M.visible() then
    M.render()
  end
  return ok, err
end

function M.restart()
  require('config.session').save()
  if vim.fn.exists(':restart') == 2 then
    vim.cmd.restart()
  else
    vim.notify('Close and reopen Neovim to load extension changes.', vim.log.levels.INFO)
  end
end

local function show_results(entries)
  local items, lookup = {}, {}
  for _, entry in ipairs(entries) do
    local label = entry.id .. '  ·  ' .. entry.description
    items[#items + 1] = label
    lookup[label] = entry.id
  end
  require('fzf-lua').fzf_exec(items, {
    prompt = 'Extensions > ',
    actions = {
      ['default'] = function(selected)
        local id = selected and lookup[selected[1]]
        if id then
          vim.schedule(function()
            M.add(id)
          end)
        end
      end,
    },
  })
end

function M.parse_search(raw)
  local ok, data = pcall(vim.json.decode, raw or '')
  local result = {}
  if not ok or type(data) ~= 'table' or type(data.items) ~= 'table' then
    return result
  end
  for _, item in ipairs(data.items) do
    if type(item) == 'table' and valid_id(item.full_name) then
      local description = type(item.description) == 'string' and item.description:gsub('[%c]', ' '):sub(1, 90) or ''
      result[#result + 1] = { id = item.full_name, description = description }
    end
  end
  return result
end

function M.search()
  vim.ui.input({ prompt = 'Search GitHub plugins (blank: suggestions): ' }, function(query)
    if query == nil then
      return
    end
    if query == '' then
      show_results(catalog)
      return
    end
    vim.system({
      'curl',
      '--fail',
      '--silent',
      '--show-error',
      '--max-time',
      '10',
      '--get',
      '--data-urlencode',
      'q=' .. query .. ' neovim',
      '--data-urlencode',
      'per_page=30',
      'https://api.github.com/search/repositories',
    }, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify('GitHub search failed: ' .. (result.stderr or ''), vim.log.levels.ERROR)
          return
        end
        local entries = M.parse_search(result.stdout)
        if #entries == 0 then
          vim.notify('No matching repositories found')
          return
        end
        show_results(entries)
      end)
    end)
  end)
end

function M.visible()
  return win and api.nvim_win_is_valid(win) and buf and api.nvim_buf_is_valid(buf)
end

function M.close()
  if M.visible() then
    api.nvim_win_close(win, true)
  end
  buf, win, rows = nil, nil, nil
end

local function mason_registry()
  local ok, registry = pcall(require, 'mason-registry')
  if not ok then
    vim.notify('Mason is unavailable', vim.log.levels.ERROR)
    return nil
  end
  return registry
end

local function refresh_mason()
  local registry = mason_registry()
  if not registry then
    return
  end
  registry.refresh(function()
    vim.schedule(function()
      if M.visible() then
        M.render()
      end
    end)
  end)
end

function M.search_mason(query)
  local registry = mason_registry()
  if not registry then
    return false
  end
  mason_query = vim.trim(query or ''):lower()
  mason_results = {}
  local specs = registry.get_all_package_specs and registry.get_all_package_specs() or nil
  local by_name = {}
  if specs then
    for _, spec in ipairs(specs) do
      by_name[spec.name] = spec
    end
  else
    for _, name in ipairs(registry.get_all_package_names()) do
      by_name[name] = { name = name }
    end
  end
  if mason_query == '' then
    for _, name in ipairs(featured) do
      if by_name[name] then
        mason_results[#mason_results + 1] = by_name[name]
      end
    end
  else
    for _, spec in pairs(by_name) do
      local haystack = (spec.name .. ' ' .. (spec.description or '') .. ' ' .. table.concat(spec.categories or {}, ' ')):lower()
      if haystack:find(mason_query, 1, true) then
        mason_results[#mason_results + 1] = spec
      end
    end
    table.sort(mason_results, function(a, b)
      return a.name < b.name
    end)
  end
  if M.visible() then
    M.render()
  end
  return true
end

local function short(value, width)
  value = tostring(value or ''):gsub('[%c]', ' ')
  return vim.fn.strcharpart(value, 0, width)
end

local function mark(line, group)
  api.nvim_buf_add_highlight(buf, ns, group, line - 1, 0, -1)
end

function M.mason_action(name)
  local registry = mason_registry()
  if not registry then
    return false
  end
  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    vim.notify('Unknown Mason package: ' .. name, vim.log.levels.ERROR)
    return false
  end
  if pkg:is_installing() or pkg:is_uninstalling() then
    return false
  end
  local action = pkg:is_installed() and 'uninstall' or 'install'
  pkg:once(action .. ':success', function()
    vim.schedule(function()
      vim.notify('Mason ' .. action .. 'ed ' .. name)
      if M.visible() then
        M.render()
      end
    end)
  end)
  pkg:once(action .. ':failed', function()
    vim.schedule(function()
      vim.notify('Mason ' .. action .. ' failed for ' .. name .. '. See :MasonLog', vim.log.levels.ERROR)
      if M.visible() then
        M.render()
      end
    end)
  end)
  pkg[action](pkg)
  if M.visible() then
    M.render()
  end
  return true
end

function M.render()
  if not M.visible() then
    return
  end
  local width = math.max(20, api.nvim_win_get_width(win) - 4)
  local lines = {
    '  EXTENSIONS',
    '  Mason tools and Neovim plugins',
    '  > ' .. (mason_query == '' and 'Search Mason extensions...' or mason_query),
    '',
  }
  rows = { [3] = { kind = 'mason_search' } }
  local ok, registry = pcall(require, 'mason-registry')
  if ok then
    local installed = registry.get_installed_package_names()
    table.sort(installed)
    lines[#lines + 1] = '  MARKETPLACE  '
      .. (mason_query == '' and 'Featured' or tostring(#mason_results) .. ' results')
    if #mason_results == 0 then
      lines[#lines + 1] = '  No matches. Try another search.'
    end
    for i = 1, math.min(#mason_results, 40) do
      local spec = mason_results[i]
      local name = spec.name
      local installed_now = registry.is_installed(name)
      local action = { kind = 'mason_package', name = name }
      lines[#lines + 1] = '  ◆ ' .. short(name, width - 4)
      rows[#lines] = action
      lines[#lines + 1] = '    ' .. short(spec.description or 'Mason package', width - 4)
      rows[#lines] = action
      local category = spec.categories and spec.categories[1] or 'Tool'
      lines[#lines + 1] = '    '
        .. short(category, math.max(1, width - 17))
        .. '  ['
        .. (installed_now and 'Installed' or 'Install')
        .. ']'
      rows[#lines] = action
      lines[#lines + 1] = ''
    end
    lines[#lines + 1] = '  INSTALLED  ' .. #installed
    for _, name in ipairs(installed) do
      lines[#lines + 1] = '  ◆ ' .. short(name, width - 4) .. '  [Remove]'
      rows[#lines] = { kind = 'mason_package', name = name }
    end
  else
    lines[#lines + 1] = '  Mason unavailable'
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  MORE ACTIONS'
  local actions = {
    { 'Search Neovim plugins', 'search' },
    { 'Add GitHub repository', 'add' },
    { 'Open Mason full manager', 'mason' },
    { 'Refresh Mason registry', 'mason_refresh' },
    { 'Install syntax parser', 'parser' },
    { 'Reload Neovim', 'restart' },
  }
  for _, item in ipairs(actions) do
    lines[#lines + 1] = '  [' .. item[1] .. ']'
    rows[#lines] = { kind = item[2] }
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  NEOVIM PLUGINS'
  local plugins = M.read()
  if #plugins == 0 then
    lines[#lines + 1] = '  None added yet'
  end
  for _, id in ipairs(plugins) do
    lines[#lines + 1] = '  ◆ ' .. short(id, width - 4) .. '  [Remove]'
    rows[#lines] = { kind = 'plugin', name = id }
  end
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, line in ipairs(lines) do
    if i == 1 then
      mark(i, 'SetupTitle')
    elseif i == 2 then
      mark(i, 'SetupHelp')
    elseif i == 3 then
      mark(i, 'SetupButton')
    elseif line:match('^  [A-Z][A-Z ]+%s') then
      mark(i, 'SetupSection')
    elseif line:find('%[Install%]') or line:find('%[Installed%]') then
      mark(i, 'SetupChoiceOn')
    elseif line:match('^  %[') then
      mark(i, 'SetupButton')
    elseif line:match('^  ◆') then
      mark(i, 'SetupTitle')
    elseif line:match('^    ') then
      mark(i, 'SetupHelp')
    end
  end
end

local function begin_search()
  if not M.visible() then
    return
  end
  editing_search = true
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 2, 3, false, { '  > ' .. mason_query })
  api.nvim_win_set_cursor(win, { 3, #('  > ' .. mason_query) })
  vim.cmd('startinsert!')
end

local function activate(line)
  local action = rows and rows[line]
  if not action then
    return
  end
  if action.kind == 'search' then
    M.search()
  elseif action.kind == 'add' then
    vim.ui.input({ prompt = 'GitHub owner/repository: ' }, function(id)
      if id and id ~= '' then
        local ok, err = M.add(id)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end)
  elseif action.kind == 'mason' then
    vim.cmd.Mason()
  elseif action.kind == 'mason_search' then
    begin_search()
  elseif action.kind == 'mason_refresh' then
    refresh_mason()
  elseif action.kind == 'mason_package' then
    M.mason_action(action.name)
  elseif action.kind == 'parser' then
    vim.ui.input({ prompt = 'Tree-sitter parser name: ' }, function(name)
      if name and name:match('^[%w_]+$') then
        vim.cmd('TSInstall ' .. name)
      end
    end)
  elseif action.kind == 'restart' then
    M.restart()
  elseif action.kind == 'plugin' then
    M.remove(action.name)
  end
end

function M.open(width)
  if M.visible() then
    api.nvim_set_current_win(win)
    M.render()
    return
  end
  vim.cmd('topleft vsplit')
  win = api.nvim_get_current_win()
  buf = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'setup-extensions'
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  api.nvim_win_set_width(win, width)
  vim.keymap.set('n', '<CR>', function()
    activate(api.nvim_win_get_cursor(win)[1])
  end, { buffer = buf })
  vim.keymap.set('n', '/', begin_search, { buffer = buf, desc = 'Search extensions' })
  vim.keymap.set('i', '<CR>', '<Esc>', { buffer = buf, desc = 'Apply extension search' })
  api.nvim_create_autocmd('InsertLeave', {
    buffer = buf,
    callback = function()
      if not editing_search or not M.visible() then
        return
      end
      editing_search = false
      local query = api.nvim_buf_get_lines(buf, 2, 3, false)[1]:gsub('^%s*>%s*', '')
      vim.bo[buf].modifiable = false
      M.search_mason(query)
    end,
  })
  vim.keymap.set('n', 'q', function()
    require('config.sidebar').files()
  end, { buffer = buf })
  vim.keymap.set('n', '<LeftMouse>', function()
    local pos = vim.fn.getmousepos()
    if pos.winid == win then
      vim.schedule(function()
        if M.visible() then
          activate(pos.line)
        end
      end)
    end
    return '<LeftMouse>'
  end, { buffer = buf, expr = true })
  M.render()
  if #mason_results == 0 then
    M.search_mason('')
  end
end

return M
