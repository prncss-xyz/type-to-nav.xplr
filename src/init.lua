local M = {}

local function merge_in(t1, t2)
  for k, v in pairs(t2) do
    t1[k] = v
  end
end

local function longest_common_chain(a, b)
  local j = 1
  while true do
    if j == #a + 1 then
      break
    end
    if j == #b + 1 then
      break
    end
    if a:sub(j, j) ~= b:sub(j, j) then
      break
    end
    j = j + 1
  end
  return a:sub(1, j - 1)
end

local opts = {
  default_bindings = true,
}

local is_dot_filter

xplr.fn.custom.type_to_nav_rebuf = function(app)
  if #app.input_buffer > 0 then
    local count = 0
    local node
    for _, node0 in ipairs(app.directory_buffer.nodes) do
      local p = node0.relative_path
      -- check if node's relative_path starts with input buffer
      if p:sub(1, #app.input_buffer) == app.input_buffer then
        count = count + 1
        node = node0
      end
    end
    if count == 1 then
      local messages = {}
      if node.is_dir then
        table.insert(
          messages,
          { CallLuaSilently = 'custom.type_to_nav_reset_filters' }
        )
        table.insert(messages, { ChangeDirectory = node.absolute_path })
        table.insert(messages, { SetInputBuffer = '' })
        table.insert(messages, 'ExplorePwdAsync')
      elseif node.is_file then
        table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_quit' })
      end
      return messages
    end
  end
  local messages = {}
  for _, filter in ipairs(app.explorer_config.filters) do
    if filter.filter == 'RelativePathDoesStartWith' then
      table.insert(messages, {
        RemoveNodeFilter = {
          filter = 'RelativePathDoesStartWith',
          input = filter.input,
        },
      })
    end
  end
  if app.input_buffer == '.' then
    table.insert(messages, {
      RemoveNodeFilter = {
        filter = 'RelativePathDoesNotStartWith',
        input = '.',
      },
    })
  end
  table.insert(messages, {
    AddNodeFilter = {
      filter = 'RelativePathDoesStartWith',
      input = app.input_buffer,
    },
  })
  table.insert(messages, 'ExplorePwdAsync')
  return messages
end

xplr.fn.custom.type_to_nav_clear_input = function()
  local messages = {}
  table.insert(
    messages,
    { CallLuaSilently = 'custom.type_to_nav_reset_filters' }
  )
  table.insert(messages, { SetInputBuffer = '' })
  table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_rebuf' })
  return messages
end

xplr.fn.custom.type_to_nav_up = function()
  return {
    { SetInputBuffer = '' },
    { ChangeDirectory = '..' },
    { CallLuaSilently = 'custom.type_to_nav_rebuf' },
  }
end

xplr.fn.custom.type_to_nav_complete = function(app)
  if not app.directory_buffer then
    return
  end
  local input = nil
  for _, node in ipairs(app.directory_buffer.nodes) do
    local p = node.relative_path
    if not input then
      input = p
    else
      input = longest_common_chain(input, p)
    end
  end
  return {
    { SetInputBuffer = input },
    { CallLuaSilently = 'custom.type_to_nav_rebuf' },
  }
end

xplr.fn.custom.type_to_nav_remove_last_character = function(app)
  local input = app.input_buffer
  if #input == 0 then
    return
  end
  input = input:sub(1, -2)
  return {
    { SetInputBuffer = input },
    { CallLuaSilently = 'custom.type_to_nav_rebuf' },
  }
end

xplr.config.modes.custom.type_to_nav = {
  name = 'type-to-nav',
}

xplr.fn.custom.type_to_nav_start = function(app)
  local messages = {
    { SwitchModeCustom = 'type_to_nav' },
    { BufferInput = '' },
  }
  is_dot_filter = false
  for _, filter in ipairs(app.explorer_config.filters) do
    if
      filter.filter == 'RelativePathDoesNotStartWith' and filter.input == '.'
    then
      is_dot_filter = true
    elseif filter.filter == 'RelativePathDoesStartWith' then
      table.insert(messages, {
        RemoveNodeFilter = {
          filter = 'RelativePathDoesStartWith',
          input = filter.input,
        },
      })
    end
  end
  table.insert(messages, 'ExplorePwdAsync')
  return messages
end

xplr.fn.custom.type_to_nav_reset_filters = function(app)
  local messages = {}
  if is_dot_filter then
    table.insert(messages, {
      AddNodeFilter = {
        filter = 'RelativePathDoesNotStartWith',
        input = '.',
      },
    })
  end
  for _, filter in ipairs(app.explorer_config.filters) do
    if filter.filter == 'RelativePathDoesStartWith' then
      table.insert(messages, {
        RemoveNodeFilter = {
          filter = 'RelativePathDoesStartWith',
          input = filter.input,
        },
      })
    end
  end
  return messages
end

xplr.fn.custom.type_to_nav_quit = function(app)
  local messages = {}
  table.insert(
    messages,
    { CallLuaSilently = 'custom.type_to_nav_reset_filters' }
  )
  table.insert(
    messages,
    { CallLuaSilently = 'custom.type_to_nav_reset_filters' }
  )
  table.insert(messages, 'ExplorePwdAsync')
  table.insert(messages, 'PopMode')
  table.insert(messages, { SwitchModeBuiltin = 'default' })
  return messages
end

-- TODO deal with symlinks
xplr.fn.custom.type_to_nav_accept = function(app)
  local node = app.focused_node
  if node.is_dir then
    local messages = {}
    table.insert(
      messages,
      { CallLuaSilently = 'custom.type_to_nav_reset_filters' }
    )
    table.insert(messages, { SetInputBuffer = '' })
    table.insert(messages, { ChangeDirectory = node.absolute_path })
    table.insert(messages, {
      CallLuaSilently = 'custom.type_to_nav_rebuf',
    })
    return messages
  end
  return xplr.fn.custom.type_to_nav_quit(app)
end

local char_bindings = {
  messages = {
    'BufferInputFromKey',
    { CallLuaSilently = 'custom.type_to_nav_rebuf' },
  },
}

xplr.config.modes.custom.type_to_nav.key_bindings = {
  on_alphabet = char_bindings,
  on_number = char_bindings,
  on_special_character = char_bindings,
  on_key = {},
}

M.setup = function(lopts)
  if lopts then
    merge_in(opts, lopts)
  end
  if opts.default_bindings then
    xplr.config.modes.builtin.default.key_bindings.on_key['ctrl-n'] = {
      help = 'type-to-nav',
      messages = {
        { CallLuaSilently = 'custom.type_to_nav_start' },
      },
    }
    merge_in(xplr.config.modes.custom.type_to_nav.key_bindings.on_key, {
      esc = {
        help = 'quit mode',
        messages = { { CallLuaSilently = 'custom.type_to_nav_quit' } },
      },
      ['ctrl-u'] = {
        help = 'clear input',
        messages = { { CallLuaSilently = 'custom.type_to_nav_clear_input' } },
      },
      ['ctrl-h'] = {
        help = 'up',
        messages = { { CallLuaSilently = 'custom.type_to_nav_up' } },
      },
      backspace = {
        help = 'remove last character',
        messages = {
          { CallLuaSilently = 'custom.type_to_nav_remove_last_character' },
        },
      },
      tab = {
        help = 'complete',
        messages = { { CallLuaSilently = 'custom.type_to_nav_complete' } },
      },
      enter = {
        help = 'accept',
        messages = { { CallLuaSilently = 'custom.type_to_nav_accept' } },
      },
      ['ctrl-p'] = { help = 'focus previous', messages = { 'FocusPrevious' } },
      ['ctrl-n'] = { help = 'focus next', messages = { 'FocusNext' } },
      ['ctrl-s'] = { help = 'toggle select', messages = { 'ToggleSelection' } },
      ['ctrl-a'] = {
        help = 'toggle select all',
        messages = { 'ToggleSelectAll' },
      },
    })
  end
end

return M
