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
  local columns = math.max(1, vim.o.columns)
  local lines = math.max(1, vim.o.lines)
  width = math.min(math.max(width + 2, 12), math.max(1, columns - 4))
  local height = math.min(#labels, math.max(1, lines - 4))
  if height < 1 or width < 1 then
    actions = nil
    return false
  end
  local click = pos
  if type(click) ~= 'table' or type(click.row) ~= 'number' or type(click.col) ~= 'number' then
    click = { row = vim.fn.screenrow(), col = vim.fn.screencol() }
  end
  local row = math.max(0, math.min(click.row - 1, lines - height - 3))
  local col = math.max(0, math.min(click.col - 1, columns - width - 2))
  menu_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(menu_buf, 0, -1, false, labels)
  vim.bo[menu_buf].buftype = 'nofile'
  vim.bo[menu_buf].bufhidden = 'wipe'
  vim.bo[menu_buf].modifiable = false
  vim.bo[menu_buf].filetype = 'NvimSetupMenu'
  local ok, win = pcall(api.nvim_open_win, menu_buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    border = 'single',
    style = 'minimal',
    zindex = 80,
  })
  if not ok or not valid(win) then
    pcall(api.nvim_buf_delete, menu_buf, { force = true })
    menu_buf, actions = nil, nil
    return false
  end
  menu_win = win
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
          require('modules.tabs').open(path)
        end,
      }
      items[#items + 1] = {
        label = 'Open in new editor tab',
        run = function()
          require('modules.tabs').new()
          require('modules.tabs').open(path)
        end,
      }
      items[#items + 1] = {
        label = 'Add file to chat',
        run = function()
          require('modules.agents').attach_files({ path })
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
  if not require('modules.tabs').editor_buf(id) then
    return false
  end
  local tabs = require('modules.tabs')
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
      label = 'Add file to chat',
      run = function()
        require('modules.agents').attach_files({ name })
      end,
    })
    table.insert(items, 3, {
      label = 'Copy file path',
      run = function()
        copy_path(name)
      end,
    })
  end
  return M.show(items, pos)
end

function M.editor(buf, pos)
  buf = buf or api.nvim_get_current_buf()
  if not require('modules.tabs').editor_buf(buf) then
    return false
  end
  if pos == nil then
    pos = { row = vim.fn.screenrow(), col = vim.fn.screencol() }
  end
  local agents = require('modules.agents')
  local range = agents.current_range(buf)
  local first, last = range.first, range.last
  local mode = vim.fn.mode()
  local visual = mode == 'v' or mode == 'V' or mode == '\22' or (first ~= last)
  local function range_lines()
    if not api.nvim_buf_is_valid(buf) then
      return {}
    end
    local count = api.nvim_buf_line_count(buf)
    local s = math.max(1, math.min(first, count))
    local e = math.max(1, math.min(last, count))
    if s > e then
      s, e = e, s
    end
    return api.nvim_buf_get_lines(buf, s - 1, e, false)
  end
  local items = {
    {
      label = 'Open in web browser',
      run = function()
        pcall(vim.cmd, 'normal! gx')
      end,
    },
    {
      label = 'Inspect',
      run = function()
        pcall(vim.cmd, 'Inspect')
      end,
    },
    {
      label = 'Go to definition',
      run = function()
        pcall(vim.lsp.buf.definition)
      end,
    },
    {
      label = 'Show Diagnostics',
      run = function()
        if vim.diagnostic and vim.diagnostic.open_float then
          pcall(vim.diagnostic.open_float)
        end
      end,
    },
    {
      label = 'Undo',
      run = function()
        pcall(vim.cmd, 'undo')
      end,
    },
    {
      label = 'Redo',
      run = function()
        pcall(vim.cmd, 'redo')
      end,
    },
  }
  if visual then
    items[#items + 1] = {
      label = 'Cut',
      run = function()
        local lines = range_lines()
        if #lines == 0 then
          return
        end
        vim.fn.setreg('+', table.concat(lines, '\n'))
        local s = math.min(first, last)
        local e = math.max(first, last)
        pcall(api.nvim_buf_set_lines, buf, s - 1, e, false, {})
      end,
    }
    items[#items + 1] = {
      label = 'Copy',
      run = function()
        local lines = range_lines()
        if #lines > 0 then
          vim.fn.setreg('+', table.concat(lines, '\n'))
        end
      end,
    }
  end
  items[#items + 1] = {
    label = 'Paste',
    run = function()
      pcall(vim.cmd, 'normal! "+gP')
    end,
  }
  if visual then
    items[#items + 1] = {
      label = 'Delete',
      run = function()
        local s = math.min(first, last)
        local e = math.max(first, last)
        pcall(api.nvim_buf_set_lines, buf, s - 1, e, false, {})
      end,
    }
  end
  items[#items + 1] = {
    label = 'Select All',
    run = function()
      pcall(vim.cmd, 'normal! ggVG')
    end,
  }
  -- Custom chat actions stay appended after every default entry.
  items[#items + 1] = {
    label = 'Add file to chat',
    run = function()
      agents.attach_files({ api.nvim_buf_get_name(buf) })
    end,
  }
  items[#items + 1] = {
    label = 'Add selection to chat',
    run = function()
      agents.attach_range(buf, range)
    end,
  }
  return M.show(items, pos)
end

function M.chat_tab(id, pos)
  local agents = require('modules.agents')
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
  local sidebar = require('modules.sidebar')
  local open = {
    files = sidebar.files,
    git = sidebar.git,
    settings = sidebar.settings,
    themes = sidebar.themes,
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

-- Keep every default PopUp entry and append the chat actions for mouse
-- right-clicks. The editor no longer overrides <RightMouse>, so Neovim's
-- built-in popup (Cut/Copy/Paste, LSP entries, ...) stays intact.
local popup_ready = false
local function ensure_popup()
  if popup_ready then
    return
  end
  popup_ready = true
  pcall(vim.cmd, [[anoremenu PopUp.-NvimSetupChatSep- <Nop>]])
  pcall(vim.cmd, [[noremenu PopUp.Add\ file\ to\ chat <Cmd>lua require('modules.agents').attach_current_file()<CR>]])
  pcall(vim.cmd, [[noremenu PopUp.Add\ selection\ to\ chat <Cmd>lua require('modules.agents').attach_selection()<CR>]])
  pcall(vim.cmd, [[vnoremenu PopUp.Add\ selection\ to\ chat <Cmd>lua require('modules.agents').attach_selection()<CR>]])
end

ensure_popup()

function M.popup_ready()
  return popup_ready
end

function M.current()
  local buf = api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  if ft == 'NvimTree' then
    local tree = require('nvim-tree.api')
    return M.tree(tree.tree.get_node_under_cursor())
  elseif ft == 'git-changes' then
    return require('modules.sidebar').context_menu()
  elseif ft == 'git-log' then
    return require('modules.sidebar').context_menu('log')
  elseif require('modules.agents').is_chat(buf) then
    return M.chat_tab(vim.b[buf].chat_id)
  elseif require('modules.tabs').editor_buf(buf) then
    return M.editor(buf, { row = vim.fn.screenrow(), col = vim.fn.screencol() })
  end
  return false
end

return M
