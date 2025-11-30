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

	-- OVERRIDE ANSI COLORS - Fix that god-awful dark blue
	config.colors = {
		-- Basic 8 ANSI colors (indices 0-7)
		ansi = {
			"#000000", -- 0: black
			"#ff5555", -- 1: red
			"#50fa7b", -- 2: green
			"#f1fa8c", -- 3: yellow
			"#89b4fa", -- 4: blue (BRIGHTENED - was dark blue, now visible)
			"#ff79c6", -- 5: magenta
			"#8be9fd", -- 6: cyan
			"#bbbbbb", -- 7: white
		},
		-- Bright variants (indices 8-15) - used with bold/bright attribute
		brights = {
			"#555555", -- 8: bright black (gray)
			"#ff6e67", -- 9: bright red
			"#5af78e", -- 10: bright green
			"#f4f99d", -- 11: bright yellow
			"#a6c7ff", -- 12: bright blue (VERY BRIGHT - ensures visibility)
			"#ff92d0", -- 13: bright magenta
			"#9aedfe", -- 14: bright cyan
			"#ffffff", -- 15: bright white
		},
	}
end

return M
