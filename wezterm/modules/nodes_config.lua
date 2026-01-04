local wezterm = require("wezterm")
local io = require("io")
local string = require("string")

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
		local msys_paths = {
			"C:/DevSoftware/msys64/usr/bin/ssh.exe",
		}
		for _, path in ipairs(msys_paths) do
			local f = io.open(path, "r")
			if f then
				f:close()
				return path
			end
		end
		return "C:/Windows/System32/OpenSSH/ssh.exe"
	else
		return "ssh"
	end
end

-- Parse SSH config file and extract Host entries
local function parse_ssh_config()
	local env = detect_env()
	local ssh_config_path

	if env.is_macos or env.is_home_windows then
		local home = os.getenv("HOME")
		ssh_config_path = home .. "/.ssh/config"
	elseif env.is_work_windows then
		local userprofile = os.getenv("USERPROFILE")
		ssh_config_path = userprofile .. "\\.ssh\\config"
	end

	local hosts = {}

	if not ssh_config_path then
		return hosts
	end

	local file = io.open(ssh_config_path, "r")
	if not file then
		wezterm.log_info("Could not open SSH config at: " .. ssh_config_path)
		return hosts
	end

	local current_host = nil
	for line in file:lines() do
		-- Match "Host <name>" lines
		local host = line:match("^%s*Host%s+([^%s*?]+)%s*$")
		if host then
			-- Skip wildcard patterns like "i-*" or "mi-*"
			if not host:match("[*?]") then
				current_host = {
					alias = host,
					hostname = nil,
					user = nil,
				}
				table.insert(hosts, current_host)
			else
				current_host = nil
			end
		elseif current_host then
			-- Extract HostName
			local hostname = line:match("^%s*HostName%s+(.+)%s*$")
			if hostname then
				current_host.hostname = hostname
			end

			-- Extract User
			local user = line:match("^%s*User%s+(.+)%s*$")
			if user then
				current_host.user = user
			end
		end
	end

	file:close()
	return hosts
end

-- Group configuration - define your patterns here
local function get_group_config(env)
	if env.is_work_windows then
		return {
			{
				label = "--- Prod GW ---",
				pattern = "^[cn]%d+$", -- Matches c1, c2, n1, n2, etc.
			},
			{
				label = "--- BDS Workstations ---",
				pattern = "^bds%d+$", -- Matches bds16, bds17, etc.
			},
		}
	else
		-- Home/macOS groups
		return {
			{
				label = "--- Depot Nodes ---",
				pattern = "depot", -- Matches anything with "depot" in hostname
				explicit = { "rd", "rd2", "bala", "venky", "mikelee" }, -- Or explicit list
			},
			{
				label = "--- Other Hosts ---",
				explicit = { "what", "imac-ubuntu" }, -- Specific hosts
			},
			{
				label = "--- VPN Nodes ---",
				pattern = "^vpn%d*$", -- Matches vpn, vpn2, vpn3, ... vpn9
			},
		}
	end
end

-- Check if a host matches a group
local function host_matches_group(host, group)
	-- Check explicit list first
	if group.explicit then
		for _, name in ipairs(group.explicit) do
			if host.alias == name then
				return true
			end
		end
		return false
	end

	-- Check pattern matching
	if group.pattern then
		-- Try matching alias
		if host.alias:match(group.pattern) then
			return true
		end
		-- Try matching hostname if available
		if host.hostname and host.hostname:match(group.pattern) then
			return true
		end
	end

	return false
end

-- Define your nodes here - now auto-generated from SSH config
function M.get_nodes()
	local env = detect_env()
	local ssh_cmd = get_ssh_command(env.is_work_windows or env.is_home_windows)

	-- Parse SSH config
	local all_hosts = parse_ssh_config()

	-- Get grouping configuration
	local groups = get_group_config(env)

	local nodes = {}

	-- For work, also add nodes not in SSH config (if needed)
	if env.is_work_windows then
		-- If you have work nodes NOT in SSH config, add them here manually
		-- Otherwise, they'll come from SSH config parsing
	end

	-- Organize hosts into groups
	for _, group in ipairs(groups) do
		-- Add separator
		table.insert(nodes, {
			label = group.label,
			separator = true,
		})

		-- Find all hosts matching this group
		for _, host in ipairs(all_hosts) do
			if host_matches_group(host, group) then
				table.insert(nodes, {
					name = host.alias,
					ssh_config_alias = host.alias,
					ssh_cmd = ssh_cmd,
				})
			end
		end
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
			local args
			if node.ssh_config_alias then
				-- Use SSH config alias as-is
				args = { node.ssh_cmd, node.ssh_config_alias }
			else
				-- Build user@host connection string
				local connection_string = string.format("%s@%s", node.user, node.host)
				args = { node.ssh_cmd, connection_string }
			end

			table.insert(entries, {
				label = node.name,
				args = args,
			})
		end
	end

	return entries
end

-- Helper to spawn a tab with auto-naming
function M.spawn_node_tab(window, node)
	local args
	if node.ssh_config_alias then
		-- Use SSH config alias
		args = { node.ssh_cmd, node.ssh_config_alias }
	else
		-- Build user@host connection string
		local connection_string = string.format("%s@%s", node.user, node.host)
		args = { node.ssh_cmd, connection_string }
	end

	local tab, pane, _ = window:spawn_tab({ args = args })

	-- Set tab title to node name
	tab:set_title(node.name)

	return tab, pane
end

return M
