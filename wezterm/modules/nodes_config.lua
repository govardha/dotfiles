local wezterm = require("wezterm")

local M = {}

-- Detect environment helper
local function detect_env()
	local WORK_DOMAIN_NAME = "WORKDOMAIN"
	local dom = os.getenv("USERDOMAIN")
	local is_work = dom and string.upper(dom) == WORK_DOMAIN_NAME
	local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"
	local is_macos = wezterm.target_triple:match("darwin") ~= nil

	return {
		is_work_windows = is_windows and is_work,
		is_home_windows = is_windows and not is_work,
		is_macos = is_macos,
	}
end

-- SSH command helper based on platform
local function get_ssh_command(is_windows)
	if is_windows then
		-- Try msys ssh first, fallback to Windows ssh
		local msys_paths = {
			"C:/DevSoftware/msys64/usr/bin/ssh.exe", -- Work
			"C:/Apps/msys64/usr/bin/ssh.exe", -- Home
		}
		for _, path in ipairs(msys_paths) do
			if vim.loop and vim.loop.fs_stat(path) then
				return path
			end
		end
		return "C:/Windows/System32/OpenSSH/ssh.exe"
	else
		return "ssh"
	end
end

-- Define your nodes here - single source of truth
function M.get_nodes()
	local env = detect_env()
	local ssh_cmd = get_ssh_command(env.is_work_windows or env.is_home_windows)

	local nodes = {}

	if env.is_work_windows then
		-- Work production nodes
		table.insert(nodes, {
			label = "--- Prod GW ---",
			separator = true,
		})
		table.insert(nodes, {
			name = "c2",
			host = "dch4i1gws02",
			user = os.getenv("USERNAME"),
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "c1",
			host = "dch4i1gws01",
			user = os.getenv("USERNAME"),
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "n1",
			host = "dny2i1gws01",
			user = os.getenv("USERNAME"),
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "n2",
			host = "dny2i1gws02",
			user = os.getenv("USERNAME"),
			ssh_cmd = ssh_cmd,
		})

		-- Add your BDS workstations here
		table.insert(nodes, {
			label = "--- BDS Workstations ---",
			separator = true,
		})
		table.insert(nodes, {
			name = "bds16",
			host = "bds16",
			user = ggopal,
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "bds60",
			host = "bds60",
			user = ggopal,
			ssh_cmd = ssh_cmd,
		})
		-- Add any other sections you need
		table.insert(nodes, {
			label = "--- Other Nodes ---",
			separator = true,
		})
	elseif env.is_home_windows or env.is_macos then
		-- Home nodes - VPN servers
		table.insert(nodes, {
			label = "--- VPN Nodes ---",
			separator = true,
		})
		table.insert(nodes, {
			name = "vpn",
			host = "vpn.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "vpn2",
			host = "vpn2.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "vpn3",
			host = "vpn3.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})

		-- Depot nodes
		table.insert(nodes, {
			label = "--- Depot Nodes ---",
			separator = true,
		})
		table.insert(nodes, {
			name = "rinku-depot",
			host = "rinku-depot.vadai.org",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "rinku-depot-ts",
			host = "rinku-depot.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "rinku-depot2",
			host = "rinku-depot2.vadai.org",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "rinku-depot2-ts",
			host = "rinku-depot2.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "bala-depot",
			host = "bala-depot.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "venky-depot",
			host = "venky-depot.pigeon-hamlet.ts.net",
			user = "ubuntu",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "imac-ubuntu-ts",
			host = "imac-ubuntu.pigeon-hamlet.ts.net",
			user = "govardha",
			ssh_cmd = ssh_cmd,
		})
		table.insert(nodes, {
			name = "what",
			host = "olive.whatbox.ca",
			user = "gundan",
			ssh_cmd = ssh_cmd,
		})
	end

	return nodes
end

-- Generate launch menu entries from nodes
function M.get_launch_menu_entries()
	local nodes = M.get_nodes()
	local entries = {}

	for _, node in ipairs(nodes) do
		if node.separator then
			table.insert(entries, { label = node.label })
		else
			-- Create entry with proper tab naming
			local connection_string = string.format("%s@%s", node.user, node.host)
			table.insert(entries, {
				label = node.name,
				args = { node.ssh_cmd, connection_string },
			})
		end
	end

	return entries
end

-- Helper to spawn a tab with auto-naming
function M.spawn_node_tab(window, node)
	local connection_string = string.format("%s@%s", node.user, node.host)
	local tab, pane, _ = window:spawn_tab({
		args = { node.ssh_cmd, connection_string },
	})

	-- Set tab title to node name
	tab:set_title(node.name)

	return tab, pane
end

return M
