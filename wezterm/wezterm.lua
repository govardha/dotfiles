local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()
local HOME = os.getenv("HOME")

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

-- Load modules
local appearance = safe_require("modules.appearance")
local mouse = safe_require("modules.mouse")
local format = safe_require("modules.format")
local keybindings = safe_require("modules.keybindings")
local misc = safe_require("modules.misc")
local platform_specific = safe_require("modules.platform_specific")
--local startup = safe_require("modules.startup")

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
misc.apply(config)
platform_specific.apply(config)
--startup.apply(config)

-- >>> Add this line for debugging <<<
-- wezterm.log_info("Final config.ssh_domains:", config.ssh_domains) -- Pass the table directly

return config
