local wezterm = require("wezterm")
local mux = wezterm.mux

local M = {}

-- Environment detection
local function detect_environment()
	local WORK_DOMAIN_NAME = "WORKDOMAIN" -- Move this here or make it configurable
	local dom = os.getenv("USERDOMAIN")
	local env_info = {
		is_work_windows = false,
		is_home_windows = false,
		is_home_osx = false,
	}

	if wezterm.target_triple == "x86_64-pc-windows-msvc" then
		if dom and string.upper(dom) == WORK_DOMAIN_NAME then
			env_info.is_work_windows = true
			wezterm.log_info("Detected: Work Windows environment")
		else
			env_info.is_home_windows = true
			wezterm.log_info("Detected: Home Windows environment")
		end
	elseif wezterm.target_triple == "aarch64-apple-darwin" or wezterm.target_triple == "x86_64-apple-darwin" then
		env_info.is_home_osx = true
		wezterm.log_info("Detected: Home macOS environment")
	end

	return env_info
end

function M.setup_workspaces(env_info)
	-- You can use env_info to customize behavior based on environment
	local is_work_windows = env_info.is_work_windows
	local is_home_windows = env_info.is_home_windows
	local is_home_osx = env_info.is_home_osx

	-- Set up workspaces based on environment
	if is_home_windows then
		wezterm.log_info("Setting up workspaces for home Windows environment")

		-- VPN workspace setup with home Windows args
		local _, first_pane, vpn_window = mux.spawn_window({
			workspace = "vpns",
			args = {
				"cmd.exe ",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})
		local _, second_pane, _ = vpn_window:spawn_tab({
			args = {
				"cmd.exe ",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})
		local _, third_pane, _ = vpn_window:spawn_tab({
			args = {
				"cmd.exe ",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})

		-- Depot workspace setup with home Windows args
		local _, first_pane, depot_window = mux.spawn_window({
			workspace = "depot",
			args = {
				"cmd.exe ",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})
		local _, second_pane, _ = depot_window:spawn_tab({
			args = {
				"cmd.exe ",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})

		-- Set active workspace
		mux.set_active_workspace("vpns")

		-- Position the VPN window (since it's the active workspace)
		vpn_window:gui_window():set_position(200, 100)
	elseif is_work_windows then
		wezterm.log_info("Setting up workspaces for work Windows environment")

		-- Prod workspace setup with work Windows args
		local _, first_pane, prod_window = mux.spawn_window({
			workspace = "prod",
			args = {
				"cmd.exe ",
				"/k",
				"C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})
		local _, second_pane, _ = prod_window:spawn_tab({
			args = {
				"cmd.exe ",
				"/k",
				"C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})
		local _, third_pane, _ = prod_window:spawn_tab({
			args = {
				"cmd.exe ",
				"/k",
				"C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})

		-- Set active workspace
		mux.set_active_workspace("prod")

		-- Position the prod window
		prod_window:gui_window():set_position(200, 100)
	elseif is_home_osx then
		wezterm.log_info("Setting up workspaces for home macOS environment")

		-- VPN workspace setup (no custom args for macOS)
		local _, first_pane, vpn_window = mux.spawn_window({
			workspace = "vpns",
		})
		local _, second_pane, _ = vpn_window:spawn_tab({
			args = { "ssh", "ubuntu@vpn.pigeon-hamlet.ts.net" },
		})
		local _, third_pane, _ = vpn_window:spawn_tab({
			args = { "ssh", "ubuntu@vpn2.pigeon-hamlet.ts.net" },
		})
		local _, fourth_pane, _ = vpn_window:spawn_tab({
			args = { "ssh", "ubuntu@vpn-x86.pigeon-hamlet.ts.net" },
		})

		-- Depot workspace setup with SSH connections
		local _, first_pane, depot_window = mux.spawn_window({
			workspace = "depot",
		})
		local _, second_pane, _ = depot_window:spawn_tab({
			args = { "ssh", "ubuntu@rinku-depot" },
		})
		local _, third_pane, _ = depot_window:spawn_tab({
			args = { "ssh", "ubuntu@rinku-depot2" },
		})
		local _, third_pane, _ = depot_window:spawn_tab({
			args = { "ssh", "what" },
		})

		-- Set active workspace
		mux.set_active_workspace("depot")
	else
		wezterm.log_info("Unknown environment - skipping workspace setup")
	end
end

-- Optional: More granular functions
function M.setup_vpn_workspace()
	local _, first_pane, vpn_window = mux.spawn_window({
		workspace = "vpns",
	})
	local _, second_pane, _ = vpn_window:spawn_tab({})
	local _, third_pane, _ = vpn_window:spawn_tab({})
	return vpn_window
end

function M.setup_depot_workspace()
	local _, first_pane, depot_window = mux.spawn_window({
		workspace = "depot",
	})
	local _, second_pane, _ = depot_window:spawn_tab({})
	return depot_window
end

-- Main apply function that sets up the gui-startup event
function M.apply(config)
	wezterm.on("gui-startup", function()
		local env_info = detect_environment()
		M.setup_workspaces(env_info)
	end)
end

return M
