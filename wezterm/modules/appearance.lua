local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  -- Window and UI
  -- config.color_scheme = "Catppuccin Mocha"
  -- config.color_scheme = 'Tokyo Night (Gogh)'
  -- config.color_scheme = "Tokyo Night"
  -- config.color_scheme = "Tokyo Night Storm"
  -- config.color_scheme = 'Gruvbox Material-Dark (Gogh)'
  -- config.color_scheme = 'Selenized Black (Gogh)'
  config.color_scheme = 'Everforest Dark Hard (Gogh)'

  config.colors = {
    foreground = "#CBE0F0",
    background = "#011628",
    cursor_bg = "#CBE0F0",
    cursor_fg = "#011628",
    cursor_border = "#CBE0F0",
    selection_fg = "#CBE0F0",
    selection_bg = "#275378",    -- Your bg_visual
    scrollbar_thumb = "#143652", -- Your bg_highlight
    split = "#011423",           -- Your bg_dark

    ansi = {
      "#1d202f", -- black
      "#f7768e", -- red
      "#9ece6a", -- green
      "#e0af68", -- yellow
      "#7aa2f7", -- blue
      "#bb9af7", -- magenta
      "#7dcfff", -- cyan
      "#a9b1d6", -- white
    },
    brights = {
      "#414868", -- bright black
      "#f7768e", -- bright red
      "#9ece6a", -- bright green
      "#e0af68", -- bright yellow
      "#7aa2f7", -- bright blue
      "#bb9af7", -- bright magenta
      "#7dcfff", -- bright cyan
      "#c0caf5", -- bright white
    },

    -- Arbitrary colors for use in the tab bar
    tab_bar = {
      background = "#1f2335", -- Darker background for contrast

      active_tab = {
        bg_color = "#3d59a1", -- Deeper blue, more saturated
        fg_color = "#c0caf5", -- Bright foreground text
      },

      inactive_tab = {
        bg_color = "#1f2335", -- Match tab bar background
        fg_color = "#9aa5ce", -- Lighter gray-blue for visibility
      },

      inactive_tab_hover = {
        bg_color = "#364a82", -- Selection blue background
        fg_color = "#c0caf5", -- Bright text on hover
      },

      new_tab = {
        bg_color = "#1f2335",
        fg_color = "#7aa2f7", -- Bright blue
      },

      new_tab_hover = {
        bg_color = "#364a82",
        fg_color = "#c0caf5",
      },
    },
  }

  config.font = wezterm.font("JetBrains Mono")
  config.font_size = 12.0
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.integrated_title_buttons = { "Hide", "Maximize", "Close" }
  config.integrated_title_button_style = "Windows"
  config.enable_scroll_bar = true

  -- Window padding
  config.window_padding = {
    top = 10,
    bottom = 10,
    left = 10,
    right = 10,
  }

  -- Tab bar
  config.use_fancy_tab_bar = true
  config.tab_bar_at_bottom = false
  config.tab_max_width = 999
  config.hide_tab_bar_if_only_one_tab = false

  -- Background and transparency
  config.window_background_opacity = 0.97
  --config.window_background_gradient = {
  -- orientation = "Horizontal",
  -- colors = {
  --	"#1e1e2e",
  -- "#191970",
  -- "#24283b",
  -- "#1a1b26",
  -- "#222436",
  -- },
  -- interpolation = "Linear",
  -- blend = "Rgb",
  -- noise = 25,
  --		colors = {
  --			"#000000",
  --			"#191970",
  --		},
  --interpolation = "Linear",
  -- blend = "Rgb",
  -- noise = 25,
  --}

  -- Text appearance
  config.foreground_text_hsb = {
    hue = 1.0,
    saturation = 1.5,
    brightness = 1.9,
  }

  -- Terminal behavior
  config.scrollback_lines = 10000
  config.term = "xterm-256color"
  config.default_cursor_style = "BlinkingBar"

  config.text_min_contrast_ratio = 4.5 -- Standard accessibility ratio

  -- Window frame configuration
  config.window_frame = {
    font = wezterm.font("Roboto"),
    font_size = 10,
    border_left_width = "0.5cell",
    border_right_width = "0.5cell",
    border_bottom_height = "0.5cell",
    border_top_height = "0.5cell",
  }

  -- Window control icons
  local window_min = " 󰖰 "
  local window_max = " 󰖯 "
  local window_close = " 󰅖 "

  -- Tab bar style with window control icons
  config.tab_bar_style = {
    window_hide = window_min,
    window_hide_hover = window_min,
    window_maximize = window_max,
    window_maximize_hover = window_max,
    window_close = window_close,
    window_close_hover = window_close,
  }
end

return M
