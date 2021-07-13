Port of [nnn](https://github.com/jarun/nnn)'s _type-to-nav_ to [xplr](https://github.com/sayanarijit/xplr) with some tweaks.

## Features

Activate this mode and start to type the beginning of relative path. Current directory is filtered accordingly. You can press complete (`tab`) when all the remaining entries stats with the same prefix. When only one entry remains, if it is a directory this directory is focused, filter is reset and you can continue navigating. If it is a file, `type-to-nav` mode exits, focusing on that file (the behavior can be changed).

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

  require("type-to-nav").setup {
    default_bindings = false,
    -- action triggered when there is only one path in selection and it is a file
    -- or when `custom.type_to_nav_accept` is called when focus is on a file
    accept = { { CallLuaSilently = "custom.type_to_nav_quit_focus" } },
  }
  xplr.config.modes.builtin.default.key_bindings.on_key["ctrl-n"] = {
    help = "type-to-nav",
    messages = {
      { SwitchModeCustom = "type_to_nav" },
    },
  }
  merge_in(xplr.config.modes.custom.type_to_nav.key_bindings.on_key["esc"] = {
    help = "quit mode",
    messages = { { CallLuaSilently = "custom.type_to_nav_quit" } },
  }
  merge_in(xplr.config.modes.custom.type_to_nav.key_bindings.on_key["backspace"] = {
    help = "backspace",
    messages = { { CallLuaSilently = "custom.type_to_nav_backspace" } },
  }
  merge_in(xplr.config.modes.custom.type_to_nav.key_bindings.on_key["tab"] = {
    help = "complete",
    messages = { { CallLuaSilently = "custom.type_to_nav_complete" } },
  }
  merge_in(xplr.config.modes.custom.type_to_nav.key_bindings.on_key["enter"] = {
    help = "accept",
    message = { { CallLuaSilently = "custom.type_to_nav_accept" } },
  }
  ```

  -- this setup reproduces the defaults, work it from there!

## TODO

- Deal with symbolic links.
- Add action to clear filter (so you can move up in path).
- Support automatic completion instead having to press `tab` manually (and symmetric behavior for `backspace`)
- Refuse types that leads to empty selection.
- Restore dot filter if it was automatically removed.
- Improve filter handling in general.
- Bring unicode support. (I don't think this can be achieved in the current state of xplr's API)
