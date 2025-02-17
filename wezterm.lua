-- Pull in the wezterm API
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- These are vars to put things in later (i dont use em all yet)
local keys = {}
local mouse_bindings = {}
local config = wezterm.config_builder()
local launch_menu = {}


-- This will hold the configuration.
-- Basic stuff
-- https://github.com/wezterm/wezterm/discussions/4728


local is_linux = function()
	return wezterm.target_triple:find("linux") ~= nil
end

local is_darwin = function()
	return wezterm.target_triple:find("darwin") ~= nil
end

local is_windows = function()
	return wezterm.target_triple:find("windows") ~= nil
end

config.launch_menu = launch_menu

config.set_environment_variables = {
  -- This changes the default prompt for cmd.exe to report the
  -- current directory using OSC 7, show the current time and
  -- the current directory colored in the prompt.
  prompt = '$E]7;file://localhost/$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ',
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then

  table.insert(launch_menu, {
	  label = "Cmd",
   	  args = { "cmd.exe" },
	})
  table.insert(launch_menu, {
	  label = "---",
	})
  table.insert(launch_menu, {
	  label = "rd2-ts",
   	  args = { "C:/Windows/System32/OpenSSH/ssh.exe","ubuntu@rinku-depot2.pigeon-hamlet.ts.net"},
	})
  table.insert(launch_menu, {
	  label = "rd2",
   	  args = { "C:/Windows/System32/OpenSSH/ssh.exe","ubuntu@rinku-depot2.vadai.org"},
	})
  table.insert(launch_menu, {
	  label = "what",
   	  args = { "C:/Windows/System32/OpenSSH/ssh.exe","gundan@olive.whatbox.ca"},
	})
  table.insert(launch_menu, {
	  label = "---",
	})
  table.insert(launch_menu, {
	  label = "MSYS UCRT64",
	  args = { "cmd.exe ", "/k", "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash" },
	})
	--config.default_prog	= { "cmd.exe ", "/k", "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash" }
    config.default_prog = { "cmd.exe" }
end


wezterm.on( "update-right-status", function(window)
    local date = wezterm.strftime("%Y-%m-%d %H:%M:%S   ")
    -- "Wed Mar 3 08:14"
    local date = wezterm.strftime '%a %b %-d %Y %H:%M:%S '

    window:set_right_status(
        wezterm.format(
            {
                { Text = wezterm.nerdfonts.fa_clock_o .. ' ' .. date },
            }
        )
    )
end)

local window_min = ' 󰖰 '
local window_max = ' 󰖯 '
local window_close = ' 󰅖 '

config.window_background_gradient = {
  -- Can be "Vertical" or "Horizontal".  Specifies the direction
  -- in which the color gradient varies.  The default is "Horizontal",
  -- with the gradient going from left-to-right.
  -- Linear and Radial gradients are also supported; see the other
  -- examples below
  orientation = 'Vertical',

  -- Specifies the set of colors that are interpolated in the gradient.
  -- Accepts CSS style color specs, from named colors, through rgb
  -- strings and more
  colors = {
    '#0f0c29',
    '#302b63',
    '#24243e',
  },

  -- Instead of specifying `colors`, you can use one of a number of
  -- predefined, preset gradients.
  -- A list of presets is shown in a section below.
  -- preset = "BuPu",

  -- Specifies the interpolation style to be used.
  -- "Linear", "Basis" and "CatmullRom" as supported.
  -- The default is "Linear".
  interpolation = 'Linear',

  -- How the colors are blended in the gradient.
  -- "Rgb", "LinearRgb", "Hsv" and "Oklab" are supported.
  -- The default is "Rgb".
  blend = 'Rgb',

  -- To avoid vertical color banding for horizontal gradients, the
  -- gradient position is randomly shifted by up to the `noise` value
  -- for each pixel.
  -- Smaller values, or 0, will make bands more prominent.
  -- The default value is 64 which gives decent looking results
  -- on a retina macbook pro display.
  -- noise = 64,

  -- By default, the gradient smoothly transitions between the colors.
  -- You can adjust the sharpness by specifying the segment_size and
  -- segment_smoothness parameters.
  -- segment_size configures how many segments are present.
  -- segment_smoothness is how hard the edge is; 0.0 is a hard edge,
  -- 1.0 is a soft edge.

  -- segment_size = 11,
  -- segment_smoothness = 0.0,
}

config.font = wezterm.font('Courier New')
config.font = wezterm.font('JetBrains Mono')
config.font = wezterm.font('Consolas')
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
config.window_decorations="INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
config.integrated_title_button_style = 'Windows'
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
  -- font = require('wezterm').font 'Roboto',
  font = require('wezterm').font 'JetBrains Mono',
  font_size = 10,
  border_left_width = '0.5cell',
  border_right_width = '0.5cell',
  border_bottom_height = '0.5cell',
  border_top_height = '0.5cell',
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
config.default_cursor_style = 'BlinkingBar'
config.disable_default_key_bindings = false
config.mouse_bindings = mouse_bindings

-- There are mouse binding to mimc Windows Terminal and let you copy
-- To copy just highlight something and right click. Simple
mouse_bindings = {
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
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

config.window_background_opacity = 0.88

-- This is used to make my foreground (text, etc) brighter than my background
config.foreground_text_hsb = {
  hue = 1.0,
  saturation = 1.0,
  brightness = 1.9,
}

wezterm.on(
  'log-selection', 
  function(window, pane)
    local sel = window:get_selection_text_for_pane(pane)
    local str = sel:gsub("\r?\n", "")
    window:copy_to_clipboard(str, 'Clipboard')
  end
)

config.keys = {
  -- to make sure tmux copy/paste cleans up new line
  { key = "c", mods = "SUPER", action = act.EmitEvent 'log-selection' },
  { key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },
  { key = ',',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
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

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local title = tab_title(tab)
    local hostname = " " .. wezterm.hostname() .. " "
    if tab.is_active then
      return { 
        { Background = { Color = 'purple' } },
        { Text = wezterm.nerdfonts.cod_terminal .. '  [ ' .. tab.tab_index + 1 .. ' ] ' .. title },
      }
    else 
      return {
        { Background = { Color = 'green' } },
        { Text = '[' .. tab.tab_index + 1 .. '] ' .. title },
      }
    end
    return title
  end
)

-- Tmux shit
config.leader = { key = "b", mods = "CTRL" }
require("wez-tmux.plugin").apply_to_config(config, {})

-- and finally, return the configuration to wezterm
return config