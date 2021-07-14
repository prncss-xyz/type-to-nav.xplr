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
local dir_card

local function reset_filters(app, messages)
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
end

local function quit(app, messages)
  local focused_node = app.focused_node
  reset_filters(app, messages)
  table.insert(messages, 'ExplorePwdAsync')
  table.insert(messages, 'PopMode')
  table.insert(messages, { SwitchModeBuiltin = 'default' })
  table.insert(messages, { FocusPath = focused_node.absolute_path })
end

local function rebuf(app, messages)
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
    if count == 0 then
      -- This is an hack to make it unicode safe; not enough tested yet
      dir_card = 0
      local input = app.input_buffer
      input = input:sub(1, -2)
      table.insert(messages, { SetInputBuffer = input })
      table.insert(messages, 'ExplorePwd')
      table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_back0' })
      return
    end
    if count == 1 then
      if node.is_dir then
        reset_filters(app, messages)
        table.insert(messages, { ChangeDirectory = node.absolute_path })
        table.insert(messages, { SetInputBuffer = '' })
        table.insert(messages, 'ExplorePwdAsync')
      elseif node.is_file then
        quit(app, messages)
        table.insert(messages, { FocusPath = node.absolute_path })
      end
      return
    end
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
  if app.input_buffer == '.' then
    table.insert(messages, {
      RemoveNodeFilter = {
        filter = 'RelativePathDoesNotStartWith',
        input = '.',
      },
    })
  end
  if #app.input_buffer > 0 then
    table.insert(messages, {
      AddNodeFilter = {
        filter = 'RelativePathDoesStartWith',
        input = app.input_buffer,
      },
    })
  end
  table.insert(messages, 'ExplorePwdAsync')
end

-- local function clear_input(app, messages)
--   reset_filters(app, messages)
--   table.insert(messages, { SetInputBuffer = '' })
--   rebuf(app, messages)
-- end

xplr.config.modes.custom.type_to_nav = {
  name = 'type-to-nav',
}

xplr.fn.custom.type_to_nav_reset_filters = function(app)
  local messages = {}
  reset_filters(app, messages)
  table.insert(messages, 'ExplorePwdAsync')
  return messages
end

xplr.fn.custom.type_to_nav_rebuf = function(app)
  local messages = {}
  rebuf(app, messages)
  return messages
end

xplr.fn.custom.type_to_nav_clear_input = function(app)
  local messages = {}
  reset_filters(app, messages)
  table.insert(messages, { SetInputBuffer = '' })
  table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_rebuf' })
  return messages
end

xplr.fn.custom.type_to_nav_up = function(app)
  local messages = {}
  reset_filters(app, messages)
  table.insert(messages, { SetInputBuffer = '' })
  table.insert(messages, { ChangeDirectory = '..' })
  table.insert(messages, 'ExplorePwd')
  table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_rebuf' })
  return messages
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
  local messages = {}
  table.insert(messages, { SetInputBuffer = input })
  table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_rebuf' })
  return messages
end

-- xplr.fn.custom.type_to_nav_remove_last_character = function(app)
--   local messages = {}
--   table.insert(messages, 'RemoveInputBufferLastCharacter')
--   table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_rebuf' })
--   return messages
-- end

xplr.fn.custom.type_to_nav_start = function(app)
  local messages = {}
  table.insert(messages, { SwitchModeCustom = 'type_to_nav' })
  table.insert(messages, { BufferInput = '' })
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

xplr.fn.custom.type_to_nav_quit = function(app)
  local messages = {}
  quit(app, messages)
  return messages
end

xplr.fn.custom.type_to_nav_accept = function(app)
  local node = app.focused_node
  local cd
  if node.is_dir then
    cd = node.absolute_path
  elseif node.is_symlink then
    if node.symlink.is_dir then
      cd = node.symlink.absolute_path
    end
  end
  if cd then
    local messages = {}
    reset_filters(app, messages)
    table.insert(messages, { SetInputBuffer = '' })
    table.insert(messages, { ChangeDirectory = cd })
    table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_rebuf' })
    return messages
  end
  local messages = {}
  quit(app, messages)
  return messages
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

xplr.fn.custom.type_to_nav_back0 = function(app)
  if #app.directory_buffer.nodes ~= dir_card then
    return
  end
  local input = app.input_buffer
  if #input == 0 then
    return
  end
  local messages = {}
  input = input:sub(1, -2)
  table.insert(messages, { SetInputBuffer = input })
  reset_filters(app, messages)
  table.insert(messages, {
    AddNodeFilter = {
      filter = 'RelativePathDoesStartWith',
      input = input,
    },
  })
  table.insert(messages, 'ExplorePwd')
  table.insert(messages, { CallLuaSilently = 'custom.type_to_nav_back0' })
  return messages
end

xplr.fn.custom.type_to_nav_back = function(app)
  dir_card = #app.directory_buffer.nodes
  return { { CallLuaSilently = 'custom.type_to_nav_back0' } }
end

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
      -- backspace = {
      --   help = 'remove last character',
      --   messages = {
      --     'RemoveInputBufferLastCharacter',
      --     { CallLuaSilently = 'custom.type_to_nav_rebuf' },
      --   },
      -- },
      backspace = {
        help = 'remove last character',
        messages = {
          { CallLuaSilently = 'custom.type_to_nav_back' },
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
