local wezterm = require("wezterm")

local M = {}

function M.apply(config)
	-- Window and UI
	config.color_scheme = "Catppuccin Mocha"
	config.font = wezterm.font("JetBrains Mono")
	config.font_size = 11.0
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
	config.window_background_opacity = 0.95
	config.window_background_gradient = {
		orientation = "Horizontal",
		colors = {
			"#000000",
			"#191970",
		},
		interpolation = "Linear",
		blend = "Rgb",
		noise = 25,
	}

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
