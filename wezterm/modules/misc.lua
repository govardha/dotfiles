-- ~/.config/wezterm/modules/misc.lua
local wezterm = require('wezterm')

local M = {}

function M.apply(config)
  -- Controls how pasted newlines are canonicalized.
  -- "CarriageReturn": converts all newlines to \r (Carriage Return).
  -- This is often useful for tmux and shell interactions, as \r usually
  -- acts like hitting Enter, without adding an extra newline character
  -- that might interfere with prompts or command history.
  config.canonicalize_pasted_newlines = "CarriageReturn"

  -- You can add other general, miscellaneous configurations here in the future.
  -- For example:
  -- config.default_cursor_style = "SteadyBlock"
  -- config.tab_bar_height = 28
end

return M