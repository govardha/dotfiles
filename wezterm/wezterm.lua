local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local HOME = os.getenv("HOME")

-- In your main wezterm.lua, before requiring any plugins
wezterm.on("init", function(cmd_args)
	wezterm.log_info("init hook for package.path setup")
	package.path = HOME .. "/.config/wezterm/plugins/?.lua;" .. package.path
	-- Or wherever you place your plugins, e.g.,
	-- package.path = wezterm.home_dir .. "/.config/wezterm/plugins/?.lua;" .. package.path
end)

-- Load modules
local function safe_require(module_name)
	local status, module = pcall(require, module_name)
	if status then
		return module
	else
		wezterm.log_info("Could not load module: " .. module_name)
		-- Return a dummy module that does nothing
		return {
			apply = function(config) end,
		}
	end
end

local appearance = safe_require("modules.appearance")
local mouse = safe_require("modules.mouse")
local format = safe_require("modules.format")
local ssh_utils = safe_require("modules.ssh_utils")
local keybindings = safe_require("modules.keybindings")
local misc = safe_require("modules.misc")
local platform_specific = safe_require("modules.platform_specific")

-- IMPORTANT: Populate ssh_domains *before* applying ssh_path_config
-- If you are not explicitly setting config.ssh_domains, wezterm.default_ssh_domains()
-- will be called internally when you try to access the ssh domains later,
-- but it's good practice to make sure it's populated for the module to work on it.
config.ssh_domains = wezterm.default_ssh_domains()

-- Apply modules to configuration
appearance.apply(config)
mouse.apply(config)
format.apply(config)
keybindings.apply(config)
ssh_utils.apply(config)
misc.apply(config)
platform_specific.apply(config)

-- >>> Add this line for debugging <<<
wezterm.log_info("Final config.ssh_domains:", config.ssh_domains) -- Pass the table directly
return config
