-- keybindings.lua
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
	config.keys = {
		-- to make sure tmux copy/paste cleans up new line
		-- { key = "c", mods = "SUPER", action = act.EmitEvent 'log-selection' },
		{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },

		-- Existing Leader+, for tab renaming
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

	-- Tmux shit
	config.leader = { key = "b", mods = "CTRL" }
	require("plugins.wez-tmux.plugin").apply_to_config(config, {})
end

return M
