Inspired by [nnn](https://github.com/jarun/nnn)'s _type-to-nav_ mode for [xplr](https://github.com/sayanarijit/xplr), with some tweaks.

## Features

Activate _type-to-nav_ mode and type the first character of relative path. Current directory is filtered accordingly. If the same characters follows on all files, you don't need to type them.When only one entry remains, if it is a directory or a valid symlink to a directory, this directory is entered, filter is reset and you can continue navigating. If it is a file, _type-to-nav_ mode exits, focusing on that file.

In selecting mode, when entries are narrowed to a single file, the file is toggled to selection and filter is reset without exiting _type-to-nav_. Accepting (`enter`) toggle the file to selection without resetting filters.

Also:

- When user types '.' as a first character, plugin temporarily disable filter that hides files starting with '.'.
- If user types a key that would lead to an empty entries, this key is canceled.
- Always focus on the shortest path, so you never need to use up/down to select an entry (`accept` key and printable characters will suffice). Amongst equally short paths, will focus the first one.

## Installation

### Install manually

- Add the following line in `~/.config/xplr/init.lua`

  ```lua
  package.path = os.getenv("HOME") .. '/.config/xplr/plugins/?/src/init.lua'
  ```

- Clone the plugin

  ```bash
  mkdir -p ~/.config/xplr/plugins

  git clone https://github.com/prncss-xyz/type-to-nav.xplr ~/.config/xplr/plugins/type-to-nav
  ```

- Require the module in `~/.config/xplr/init.lua`

  ```lua
  require("type-to-nav").setup()

  -- Or

  require("type-to-nav").setup({
    default_bindings = false,
  })

  local function merge_in(t1, t2)
    for k, v in pairs(t2) do
      t1[k] = v
    end
  end

  xplr.config.modes.builtin.default.key_bindings.on_key['ctrl-n'] = {
    help = 'type-to-nav',
    messages = {
      { CallLuaSilently = 'custom.type_to_nav_start' },
    },
  }
  xplr.config.modes.builtin.default.key_bindings.on_key['N'] = {
    help = 'type-to-nav',
    messages = {
      { CallLuaSilently = 'custom.type_to_nav_start_selecting' },
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
    ['h'] = {
      help = 'up',
      messages = { { CallLuaSilently = 'custom.type_to_nav_up' } },
    },
    backspace = {
      help = 'remove last characters',
      messages = {
        { CallLuaSilently = 'custom.type_to_nav_back' },
      },
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
  ```

## TODO

- cover cases relative to entering directory where all files starts the same
- refactor code
  - break big function
  - merge redundent code
