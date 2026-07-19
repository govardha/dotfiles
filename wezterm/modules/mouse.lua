local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
	config.mouse_bindings = {
		-- Triple-click to select semantic zone
		{
			event = { Down = { streak = 3, button = "Left" } },
			action = act.SelectTextAtMouseCursor("SemanticZone"),
			mods = "NONE",
		},
		-- Right-click to copy selection or paste
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

	-- Windows only: WezTerm's default middle-click paste uses PrimarySelection,
	-- which isn't tied to the real Windows clipboard the way it is on macOS.
	-- Re-add middle-click here, but pull from the actual Clipboard instead.
	if wezterm.target_triple == "x86_64-pc-windows-msvc" then
		table.insert(config.mouse_bindings, {
			event = { Down = { streak = 1, button = "Middle" } },
			mods = "NONE",
			action = act.PasteFrom("Clipboard"),
		})
	end
end

return M

