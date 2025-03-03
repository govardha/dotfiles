-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
local mux = wezterm.mux

-- These are vars to put things in later (i dont use em all yet)
local keys = {}
local mouse_bindings = {}
local config = wezterm.config_builder()
local launch_menu = {}

-- stufff for custom shit
local user_name = os.getenv("USERNAME") or os.getenv("USER") or os.getenv("LOGNAME")
local user_domain = os.getenv("USERDOMAIN")
local msys_ssh = "C:/DevSoftware/msys64/usr/bin/ssh.exe"
local win_ssh = "C:/Windows/System32/OpenSSH/ssh.exe"

-- This will hold the configuration.
-- Basic stuff
-- https://github.com/wezterm/wezterm/discussions/4728

-- local is_work <const> = string.find(os.getenv('USERDOMAIN')"MIAMIHOLDINGS") ~= nil
-- local is_work <const> = os.getenv('USERDOMAIN'):find("MIAMIHOLDINGS") ~= nil

local is_linux = function()
	return wezterm.target_triple:find("linux") ~= nil
end

local is_darwin = function()
	return wezterm.target_triple:find("darwin") ~= nil
end

local is_windows = function()
	return wezterm.target_triple:find("windows") ~= nil
end

local dom = os.getenv("USERDOMAIN")
-- require(strings.lower(dom))
print(dom)
wezterm.log_info(dom)

config.ssh_domains = wezterm.default_ssh_domains()

local function search_and_replace(local_ssh_domains, match_key, match_value, new_key, new_value)
	for i, local_dom in ipairs(local_ssh_domains) do
		if local_dom[match_key] and string.match(local_dom[match_key], match_value) then
			local_dom[new_key] = new_value
		end
		local_ssh_domains[i] = local_dom
	end
	return local_ssh_domains
end

config.ssh_domains =
	search_and_replace(config.ssh_domains, "name", "^SSHMUX:what$", "remote_wezterm_path", "/home/gundan/bin/wezterm")

config.ssh_domains = search_and_replace(
	config.ssh_domains,
	"name",
	"^SSHMUX:vpn[%w%-]+%-ts$",
	"remote_wezterm_path",
	"/home/ubuntu/bin/wezterm"
)

config.ssh_domains = search_and_replace(
	config.ssh_domains,
	"name",
	"^SSHMUX:[%w%-]+%-depot$",
	"remote_wezterm_path",
	"/home/ubuntu/bin/wezterm"
)

config.launch_menu = launch_menu

config.set_environment_variables = {
	-- This changes the default prompt for cmd.exe to report the
	-- current directory using OSC 7, show the current time and
	-- the current directory colored in the prompt.
	prompt = "$E]7;file://localhost/$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ",
}

-- config.color_scheme = 'Dark Ocean (terminal.sexy)'
-- config.color_scheme = 'Hardcore'
-- config.color_scheme = 'Tomorrow Night Bright'
config.color_scheme = "Google (light) (terminal.sexy)"
config.color_scheme = "Cai (Gogh)"
config.color_scheme = "Tokyo Night Light (Gogh)"
config.color_scheme = "Bamboo"
config.color_scheme = "Tokyo Night"
config.color_scheme = "Tokyo Night Storm"

-- First no work nonsense
-- gov home shit
if wezterm.target_triple == "x86_64-pc-windows-msvc" and dom ~= "MIAMIHOLDINGS" then
	config.font = wezterm.font("JetBrains Mono")
	config.canonicalize_pasted_newlines = "CarriageReturn"
	table.insert(launch_menu, {
		label = "cmd",
		args = { "cmd.exe" },
	})
	table.insert(launch_menu, {
		label = "---",
	})
	table.insert(launch_menu, {
		label = "msys",
		args = { "cmd.exe ", "/k", "C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash" },
	})
	table.insert(launch_menu, {
		label = "ucrt64",
		args = { "cmd.exe ", "/k", "C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash" },
	})
	config.default_prog = { "cmd.exe" }
-- Then work nonsense
elseif wezterm.target_triple == "x86_64-pc-windows-msvc" and dom == "MIAMIHOLDINGS" then
	config.font = wezterm.font("JetBrains Mono")
	-- Added this so that copy/paste would work normally in windows
	config.canonicalize_pasted_newlines = "CarriageReturn"
	config.background = {
		{
			source = {
				File = "C:/DevSoftware/WezTerm/images/miax-background.png",
			},
			opacity = 0.2,
			-- height = 50%,
			-- width = 50%,
		},
	}

	config.default_prog = { "cmd.exe" }
	table.insert(launch_menu, {
		label = "cmd",
		args = { "cmd.exe" },
	})
	table.insert(launch_menu, {
		label = "--- Prod GW ---",
	})
	table.insert(launch_menu, {
		label = "c2-msys",
		args = {
			msys_ssh,
			user_name .. "@dch4i1gws02",
		},
	})
	table.insert(launch_menu, {
		label = "c2-win",
		args = {
			win_ssh,
			user_name .. "@dch4i1gws02",
		},
	})
	table.insert(launch_menu, {
		label = "c1-msys",
		args = {
			msys_ssh,
			user_name .. "@dch4i1gws01",
		},
	})
	table.insert(launch_menu, {
		label = "c1-win",
		args = {
			win_ssh,
			user_name .. "@dch4i1gws01",
		},
	})
	table.insert(launch_menu, {
		label = "n1-msys",
		args = {
			msys_ssh,
			user_name .. "@dny2i1gws01",
		},
	})
	table.insert(launch_menu, {
		label = "n2-msys",
		args = {
			msys_ssh,
			user_name .. "@dny2i1gws02",
		},
	})
	table.insert(launch_menu, {
		label = "n1-win",
		args = {
			win_ssh,
			user_name .. "@dny2i1gws01",
		},
	})
	table.insert(launch_menu, {
		label = "n2-win",
		args = {
			win_ssh,
			user_name .. "@dny2i1gws02",
		},
	})

	table.insert(launch_menu, {
		label = "--- Utils ---",
	})
	table.insert(launch_menu, {
		label = "ucrt64",
		args = {
			"cmd.exe ",
			"/k",
			"C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
		},
	})
	table.insert(launch_menu, {
		label = "msys2",
		args = {
			"cmd.exe ",
			"/k",
			"C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash",
		},
	})
	table.insert(launch_menu, {
		label = "---",
	})
elseif wezterm.target_triple == "aarch64-apple-darwin" then
	config.font = wezterm.font("JetBrains Mono")
	table.insert(launch_menu, {
		label = "terminal",
		args = { "wezterm ", "cli spawn --new-window" },
	})
	table.insert(launch_menu, {
		label = "---",
	})
end

wezterm.on("update-right-status", function(window)
	local date = wezterm.strftime("%Y-%m-%d %H:%M:%S   ")
	-- "Wed Mar 3 08:14"
	local date = wezterm.strftime("%a %b %-d %Y %H:%M:%S ")

	window:set_right_status(wezterm.format({
		{ Text = wezterm.nerdfonts.fa_clock_o .. " " .. date },
	}))
end)

local window_min = " 󰖰 "
local window_max = " 󰖯 "
local window_close = " 󰅖 "

config.window_background_gradient = {
	-- Can be "Vertical" or "Horizontal".  Specifies the direction
	-- in which the color gradient varies.  The default is "Horizontal",
	-- with the gradient going from left-to-right.
	-- Linear and Radial gradients are also supported; see the other
	-- examples below
	orientation = "Vertical",
	orientation = "Horizontal",

	-- Specifies the set of colors that are interpolated in the gradient.
	-- Accepts CSS style color specs, from named colors, through rgb
	-- strings and more
	-- colors = {
	--   '#009B93',
	--   '#2ABC24',
	--   '#F15822',
	--   '#414042',
	--   '#1A1A1A',
	-- },

	-- colors = {
	--   '#F15822',
	--   '#009E9F',
	--   '#2A8C24',
	--   '#015EFF',
	-- },

	colors = {
		"#000000",
		"#191970",
	},

	-- Instead of specifying `colors`, you can use one of a number of
	-- predefined, preset gradients.
	-- A list of presets is shown in a section below.
	-- preset = "CubeHelixDefault",
	-- preset = "Cividis",

	-- Specifies the interpolation style to be used.
	-- "Linear", "Basis" and "CatmullRom" as supported.
	-- The default is "Linear".
	interpolation = "Linear",

	-- How the colors are blended in the gradient.
	-- "Rgb", "LinearRgb", "Hsv" and "Oklab" are supported.
	-- The default is "Rgb".
	blend = "Rgb",

	-- To avoid vertical color banding for horizontal gradients, the
	-- gradient position is randomly shifted by up to the `noise` value
	-- for each pixel.
	-- Smaller values, or 0, will make bands more prominent.
	-- The default value is 64 which gives decent looking results
	-- on a retina macbook pro display.
	noise = 25,

	-- By default, the gradient smoothly transitions between the colors.
	-- You can adjust the sharpness by specifying the segment_size and
	-- segment_smoothness parameters.
	-- segment_size configures how many segments are present.
	-- segment_smoothness is how hard the edge is; 0.0 is a hard edge,
	-- 1.0 is a soft edge.

	-- segment_size = 11,
	-- segment_smoothness = 0.0,
}

-- config.font = wezterm.font('Symbols Nerd Font Mono')
-- config.font = wezterm.font {
--  family = 'JetBrains Mono'
--}
config.font_size = 12

-- tab bar stuff
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.tab_max_width = 999
config.scrollback_lines = 10000
-- https://wezterm.org/config/lua/config/window_decorations.html
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_buttons = { "Hide", "Maximize", "Close" }
config.integrated_title_button_style = "Windows"
config.enable_scroll_bar = true
-- config.integrated_title_button_color = "Auto"

-- https://wezterm.org/config/lua/config/window_frame.html
config.tab_bar_style = {
	window_hide = window_min,
	window_hide_hover = window_min,
	window_maximize = window_max,
	window_maximize_hover = window_max,
	window_close = window_close,
	window_close_hover = window_close,
}

config.window_frame = {
	-- font = require('wezterm').font 'JetBrains Mono',
	font = require("wezterm").font("Roboto"),
	font_size = 10,
	border_left_width = "0.5cell",
	border_right_width = "0.5cell",
	border_bottom_height = "0.5cell",
	border_top_height = "0.5cell",
	-- border_left_color = 'silver',
	-- border_right_color = 'silver',
	-- border_bottom_color = 'silver',
	-- border_top_color = 'silver',
}

config.window_padding = {
	top = 10,
	bottom = 10,
	left = 10,
	right = 10,
}

config.term = "xterm-256color"

---- Startup wezterm on full screen mode
-- wezterm.on("gui-startup", function(cmd)
--  local tab, pane, window = mux.spawn_window(cmd or {})
-- window:gui_window():maximize()
-- end)

-- config.launch_menu = launch_menu
-- makes my cursor blink
config.default_cursor_style = "BlinkingBar"
config.disable_default_key_bindings = false
config.mouse_bindings = mouse_bindings

-- There are mouse binding to mimc Windows Terminal and let you copy
-- To copy just highlight something and right click. Simple
mouse_bindings = {
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

config.window_background_opacity = 0.95

-- This is used to make my foreground (text, etc) brighter than my background
config.foreground_text_hsb = {
	hue = 1.0,
	saturation = 1.5,
	brightness = 1.9,
}

-- wezterm.on(
--   'log-selection',
--   function(window, pane)
--     local sel = window:get_selection_text_for_pane(pane)
--     local str = sel:gsub("\r?\n", "")
--     window:copy_to_clipboard(str, 'Clipboard')
--   end
-- )

config.keys = {
	-- to make sure tmux copy/paste cleans up new line
	-- { key = "c", mods = "SUPER", action = act.EmitEvent 'log-selection' },
	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

--
-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane
	-- in that tab
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab_title(tab)
	local hostname = " " .. wezterm.hostname() .. " "
	if tab.is_active then
		return {
			{ Background = { Color = "purple" } },
			{ Text = wezterm.nerdfonts.cod_terminal .. "  [ " .. tab.tab_index + 1 .. " ] " .. title },
		}
	else
		return {
			{ Background = { Color = "black" } },
			{ Text = "[" .. tab.tab_index + 1 .. "] " .. title },
		}
	end
end)

-- -- Tmux shit
config.leader = { key = "b", mods = "CTRL" }
require("wez-tmux.plugin").apply_to_config(config, {})

-- and finally, return the configuration to wezterm
return config

