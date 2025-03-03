-- Pull in the wezterm API
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action
local mux = wezterm.mux

-- These are vars to put things in later (i dont use em all yet)
local keys = {}
local mouse_bindings = {}
local config = wezterm.config_builder()
local launch_menu = {}

-- stufff for custom shit
local user_name = os.getenv('USERNAME') or os.getenv('USER') or os.getenv('LOGNAME')
local user_domain = os.getenv('USERDOMAIN')
local msys_ssh = "C:/DevSoftware/msys64/usr/bin/ssh.exe"
local win_ssh = "C:/Windows/System32/OpenSSH/ssh.exe"
local ssh_id_file = "C:\\users\\" .. user_name .. "\\.ssh\\id_ed25519"
-- local ssh_id_file = 

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

-- define different ssh luas for home vs work
-- if is_work then
--   local ssh_domains = require('extra.ssh')
-- else
--   local ssh_domains = require('extra.ssh-home')
--   -- local msys_ssh = "C:/Apps/msys64/usr/bin/ssh.exe"
-- end

-- local ssh_domains = require('extra.ssh-home')

-- local dom = os.getenv("USERDOMAIN")
-- require(strings.lower(dom))

config.ssh_domains = wezterm.default_ssh_domains()

for i, dom in ipairs(config.ssh_domains) do
  dom.assume_shell = 'Posix'
  if dom.name and string.match(dom.name ,"SSHMUX:what") then
    dom.remote_wezterm_path = "/home/gundan/bin/wezterm"
  else
    dom.remote_wezterm_path = "/home/ubuntu/bin/wezterm"
  end
  config.ssh_domains[i] = dom
end

config.launch_menu = launch_menu

config.set_environment_variables = {
  -- This changes the default prompt for cmd.exe to report the
  -- current directory using OSC 7, show the current time and
  -- the current directory colored in the prompt.
  prompt = '$E]7;file://localhost/$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ',
}

-- config.color_scheme = 'Dark Ocean (terminal.sexy)'
-- config.color_scheme = 'Hardcore'
-- config.color_scheme = 'Tomorrow Night Bright'
config.color_scheme = 'Google (light) (terminal.sexy)'
config.color_scheme = 'Cai (Gogh)'
config.color_scheme = 'Tokyo Night Light (Gogh)'
config.color_scheme = 'Bamboo'
config.color_scheme = 'Tokyo Night'
config.color_scheme = 'Tokyo Night Storm'

-- First no work nonsense
-- gov home shit
if (wezterm.target_triple == "x86_64-pc-windows-msvc" and not is_work ) then
  
  config.font = wezterm.font('JetBrains Mono')
  config.canonicalize_pasted_newlines = 'CarriageReturn'
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
elseif (wezterm.target_triple == "x86_64-pc-windows-msvc" and is_work) then
  config.font = wezterm.font('JetBrains Mono')
  -- Added this so that copy/paste would work normally in windows
  config.canonicalize_pasted_newlines = 'CarriageReturn'
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
       user_name .. "@dch4i1gws02"
      }
	})
  table.insert(launch_menu, {
	  label = "c2-win",
   	  args = {
   	   win_ssh,
       user_name .. "@dch4i1gws02"
      }
	})
  table.insert(launch_menu, {
	  label = "c1-msys",
   	  args = {
   	   msys_ssh,
       user_name .. "@dch4i1gws01"
      }
	})
  table.insert(launch_menu, {
	  label = "c1-win",
   	  args = {
   	   win_ssh,
       user_name .. "@dch4i1gws01"
      }
	})
  table.insert(launch_menu, {
	  label = "n1-msys",
   	  args = {
   	   msys_ssh,
       user_name .. "@dny2i1gws01"
      }
	})
  table.insert(launch_menu, {
	  label = "n2-msys",
   	  args = {
   	   msys_ssh,
       user_name .. "@dny2i1gws02"
      }
	})
  table.insert(launch_menu, {
	  label = "n1-win",
   	  args = {
   	   win_ssh,
       user_name .. "@dny2i1gws01"
      }
	})
  table.insert(launch_menu, {
	  label = "n2-win",
   	  args = {
   	   win_ssh,
       user_name .. "@dny2i1gws02"
      }
	})
  -- table.insert(launch_menu, {
	--   label = "bsx",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dbm2i1gws01"
  --     }
	-- })
  -- table.insert(launch_menu, {
	--   label = "--- Dev ---",
	-- })
  -- table.insert(launch_menu, {
	--   label = "bds16",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1bds16-em2"
  --     }
	-- })
  -- table.insert(launch_menu, {
	--   label = "bds48",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1bds48-em2"
  --     }
  --  	  -- args = {'C:/Windows/System32/OpenSSH/ssh.exe','ggopal@dny2d1bds16-em2'},
	-- })
  -- table.insert(launch_menu, {
	--   label = "bds60",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1bds60-em2"
  --     }
	-- })
  -- table.insert(launch_menu, {
	--   label = "sds01",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1sds01-em2"
  --     }
	-- })
  -- table.insert(launch_menu, {
	--   label = "sds02",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1sds02-em2"
  --     }
	-- })
  -- table.insert(launch_menu, {
	--   label = "sds03",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1sds03-em2"
  --     }
	-- })
  -- table.insert(launch_menu, {
	--   label = "sds04",
  --  	  args = {
  --  	   msys_ssh,
  --      user_name .. "@dny2d1sds04-em2"
  --     }
	-- })
  table.insert(launch_menu, {
	  label = "--- Utils ---",
	})
  table.insert(launch_menu, {
	  label = "ucrt64",
	  args = { "cmd.exe ", "/k", "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash" },
	})
  table.insert(launch_menu, {
	  label = "msys2",
	  args = { "cmd.exe ", "/k", "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash" },
	})
  table.insert(launch_menu, {
	  label = "---",
	})
elseif wezterm.target_triple == "aarch64-apple-darwin" then
  config.font = wezterm.font('JetBrains Mono')
  table.insert(launch_menu, {
	  label = "terminal",
   	  args = { "wezterm ", "cli spawn --new-window" },
	})
  table.insert(launch_menu, {
	  label = "---",
	})
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
  orientation = 'Horizontal',

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
	 '#000000',
	 '#191970'
  },


  -- Instead of specifying `colors`, you can use one of a number of
  -- predefined, preset gradients.
  -- A list of presets is shown in a section below.
  -- preset = "CubeHelixDefault",
  -- preset = "Cividis",

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
  -- font = require('wezterm').font 'JetBrains Mono',
  font = require('wezterm').font 'Roboto',
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
		event = { Down = { streak = 1, button = 'Right' } },
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
        { Background = { Color = 'black' } },
        { Text = '[' .. tab.tab_index + 1 .. '] ' .. title },
      }
    end
  end
)

-- Spawn 4 tabs
-- if is_work then
-- wezterm.on('gui-startup', function()
--   -- default shit
--   local _, first_pane, prod_window = mux.spawn_window {
--     workspace = 'prod'
--   }
--   local _, _, _ = prod_window:spawn_tab {
--     args = { "cmd.exe ", "/k", "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash" },
--   }
--   -- local _, _, _ = prod_window:spawn_tab {
--   --   workspace = 'prod',
--   --     args = {
--   --      msys_ssh,
--   --      user_name .. "@dch4i1gws02"
--   --     }
--   -- }
--   -- local _, _, _ = prod_window:spawn_tab {
--   --   workspace = 'prod',
--   --     args = {
--   --      msys_ssh,
--   --      user_name .. "@dch4i1gws02"
--   --     }
--   -- }

--   -- dev shit
--   local _, _, dev_window = mux.spawn_window {
--     workspace = 'dev',
--     args = { "cmd.exe ","/k", "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash" },
--     -- domain = {
--     --   DomainName = 'bds16'
--     -- }
--   }

--   local _, _, _ = dev_window:spawn_tab {
--     domain = {
--       DomainName = 'bds16'
--     }
--   }

--   local _, _, _ = dev_window:spawn_tab {
--     domain = {
--       DomainName = 'bds60'
--     }
--   }

--   -- local _, _, _ = dev_window:spawn_tab {
--   --   args = { "cmd.exe ","/k", "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash" },
--   -- }

--   local _, _, _ = dev_window:spawn_tab {
--     domain = {
--       DomainName = 'sds01'
--     }
--   }

--   local _, _, _ = dev_window:spawn_tab {
--     domain = {
--       DomainName = 'sds05'
--     }
--   }

--   local _, _, _ = dev_window:spawn_tab {
--     domain = {
--       DomainName = 'sds06'
--     }
--   }
--  
--   -- mux.set_active_workspace 'prod'
--   mux.set_active_workspace 'dev'

-- end)
-- -- end

-- -- Tmux shit
config.leader = { key = "b", mods = "CTRL" }
require("wez-tmux.plugin").apply_to_config(config, {})

-- require("wez-pain-control.plugin").apply_to_config(config, {})
-- require("wez-pain-control.plugin").apply_to_config(config, {
--   pane_resize = 5,
-- })

-- and finally, return the configuration to wezterm
return config