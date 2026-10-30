-- Shared right-click menu for the tree, Git sidebar, and pane tabs.
local M = {}
local api = vim.api
local menu_win, menu_buf, origin_win, actions
local restoring = false

function M.restoring()
  return restoring
end

local function valid(win)
  return win and api.nvim_win_is_valid(win)
end

function M.visible()
  return valid(menu_win)
end

function M.labels()
  local labels = {}
  for _, item in ipairs(actions or {}) do
    labels[#labels + 1] = item.label
  end
  return labels
end

function M.close(restore)
  local old = menu_win
  menu_win, menu_buf, actions = nil, nil, nil
  restoring = restore == true
  if valid(old) then
    api.nvim_win_close(old, true)
  end
  if restore and valid(origin_win) then
    api.nvim_set_current_win(origin_win)
  end
  restoring = false
  origin_win = nil
end

function M.select(index)
  local item = actions and actions[index]
  if not item then
    return false
  end
  M.close(true)
  vim.schedule(item.run)
  return true
end

function M.show(items, pos)
  if type(items) ~= 'table' or #items == 0 then
    return false
  end
  if M.visible() then
    M.close(false)
  end
  origin_win = api.nvim_get_current_win()
  actions = items
  local labels = M.labels()
  local width = 0
  for _, label in ipairs(labels) do
    width = math.max(width, vim.fn.strdisplaywidth(label))
  end
  width = math.min(math.max(width + 2, 12), math.max(1, vim.o.columns - 4))
  local height = math.min(#labels, math.max(1, vim.o.lines - 4))
  local row = math.max(0, math.min((pos and pos.row or 1) - 1, vim.o.lines - height - 3))
  local col = math.max(0, math.min((pos and pos.col or 1) - 1, vim.o.columns - width - 2))
  menu_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(menu_buf, 0, -1, false, labels)
  vim.bo[menu_buf].buftype = 'nofile'
  vim.bo[menu_buf].bufhidden = 'wipe'
  vim.bo[menu_buf].modifiable = false
  menu_win = api.nvim_open_win(menu_buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    border = 'single',
    style = 'minimal',
    zindex = 80,
  })
  vim.wo[menu_win].cursorline = true
  vim.wo[menu_win].wrap = false
  vim.keymap.set('n', '<CR>', function()
    M.select(api.nvim_win_get_cursor(menu_win)[1])
  end, { buffer = menu_buf })
  vim.keymap.set('n', '<LeftMouse>', function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == menu_win and mouse.line > 0 then
      vim.schedule(function()
        if M.visible() then
          M.select(mouse.line)
        end
      end)
    end
    return '<LeftMouse>'
  end, { buffer = menu_buf, expr = true })
  for _, key in ipairs({ '<Esc>', 'q' }) do
    vim.keymap.set('n', key, function()
      M.close(true)
    end, { buffer = menu_buf })
  end
  api.nvim_create_autocmd('WinLeave', {
    buffer = menu_buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if M.visible() then
          M.close(false)
        end
      end)
    end,
  })
  return true
end

function M.mouse_position()
  local mouse = vim.fn.getmousepos()
  return { row = mouse.screenrow, col = mouse.screencol }
end

local function copy_path(path)
  vim.fn.setreg('+', path)
  vim.notify('Copied ' .. path)
end

function M.tree(node, pos)
  local tree = require('nvim-tree.api')
  local items = {}
  if node and type(node.absolute_path) == 'string' then
    local path = node.absolute_path
    if node.type == 'directory' then
      items[#items + 1] = {
        label = 'Expand / collapse',
        run = function()
          tree.node.open.edit(node)
        end,
      }
    else
      items[#items + 1] = {
        label = 'Open file',
        run = function()
          require('config.tabs').open(path)
        end,
      }
      items[#items + 1] = {
        label = 'Open in new editor tab',
        run = function()
          require('config.tabs').new()
          require('config.tabs').open(path)
        end,
      }
    end
    items[#items + 1] = {
      label = 'Copy relative path',
      run = function()
        copy_path(vim.fn.fnamemodify(path, ':.'))
      end,
    }
    items[#items + 1] = {
      label = 'Rename',
      run = function()
        tree.fs.rename(node)
      end,
    }
    items[#items + 1] = {
      label = 'Delete',
      run = function()
        tree.fs.remove(node)
      end,
    }
  end
  items[#items + 1] = {
    label = 'New file or folder',
    run = function()
      tree.fs.create(node)
    end,
  }
  items[#items + 1] = {
    label = 'Refresh tree',
    run = function()
      tree.tree.reload()
    end,
  }
  return M.show(items, pos)
end

function M.tree_at_mouse()
  local mouse = vim.fn.getmousepos()
  if not valid(mouse.winid) or mouse.line < 1 then
    return false
  end
  api.nvim_set_current_win(mouse.winid)
  local target = api.nvim_win_get_buf(mouse.winid)
  local node
  local tree = require('nvim-tree.api')
  if mouse.line <= api.nvim_buf_line_count(target) then
    pcall(api.nvim_win_set_cursor, mouse.winid, { mouse.line, 0 })
    node = tree.tree.get_node_under_cursor()
  end
  return M.tree(node, M.mouse_position())
end

function M.editor_tab(id, pos)
  if not require('config.tabs').editor_buf(id) then
    return false
  end
  local tabs = require('config.tabs')
  local name = api.nvim_buf_get_name(id)
  local items = {
    {
      label = 'Focus tab',
      run = function()
        local win = tabs.focus()
        if win then
          api.nvim_win_set_buf(win, id)
        end
      end,
    },
    {
      label = 'Close tab',
      run = function()
        tabs.close_editor(id)
      end,
    },
    {
      label = 'Close other editor tabs',
      run = function()
        for _, b in ipairs(api.nvim_list_bufs()) do
          if b ~= id and tabs.editor_buf(b) then
            tabs.close_editor(b)
          end
        end
        local win = tabs.focus()
        if win and api.nvim_buf_is_valid(id) then
          api.nvim_win_set_buf(win, id)
        end
      end,
    },
  }
  if name ~= '' then
    table.insert(items, 2, {
      label = 'Copy file path',
      run = function()
        copy_path(name)
      end,
    })
  end
  return M.show(items, pos)
end

function M.chat_tab(id, pos)
  local agents = require('config.agents')
  if not agents.sessions[id] then
    return false
  end
  return M.show({
    {
      label = 'Focus chat',
      run = function()
        agents.show(id)
      end,
    },
    {
      label = 'Close chat',
      run = function()
        agents.close(id)
      end,
    },
  }, pos)
end

function M.sidebar_tab(view, pos)
  local sidebar = require('config.sidebar')
  local open = {
    files = sidebar.files,
    git = sidebar.git,
    settings = sidebar.settings,
    extensions = sidebar.extensions,
  }
  if not open[view] then
    return false
  end
  return M.show({
    { label = 'Open ' .. view, run = open[view] },
    {
      label = 'Refresh ' .. view,
      run = function()
        open[view]()
        if view == 'git' then
          sidebar.refresh()
        elseif view == 'files' then
          require('nvim-tree.api').tree.reload()
        end
      end,
    },
  }, pos)
end

function M.current()
  local buf = api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  if ft == 'NvimTree' then
    local tree = require('nvim-tree.api')
    return M.tree(tree.tree.get_node_under_cursor())
  elseif ft == 'git-changes' then
    return require('config.sidebar').context_menu()
  elseif ft == 'git-log' then
    return require('config.sidebar').context_menu('log')
  elseif require('config.agents').is_chat(buf) then
    return M.chat_tab(vim.b[buf].chat_id)
  elseif require('config.tabs').editor_buf(buf) then
    return M.editor_tab(buf)
  end
  return false
end

return M
