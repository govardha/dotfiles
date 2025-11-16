-- Offline detection and guard for package manager operations
local M = {}

-- Detect if running with internet connectivity
local function is_online()
	local config_home = os.getenv("XDG_CONFIG_HOME") or vim.fn.expand("~/.config")
	return os.getenv("NVIM_ONLINE") == "true"
		or vim.fn.hostname():match("online") ~= nil
		or vim.fn.filereadable(config_home .. "/nvim/.online") == 1
end

M.is_online = is_online

-- Check and warn if offline
function M.check_online(operation)
	if not is_online() then
		local msg = string.format(
			"Operation '%s' requires internet connectivity.\n\n"
				.. "This system is configured as airgapped/offline.\n\n"
				.. "To enable online operations, do ONE of:\n"
				.. "  1. export NVIM_ONLINE=true\n"
				.. "  2. touch ~/.config/nvim/.online\n"
				.. "  3. Set hostname to contain 'online'",
			operation
		)
		vim.notify(msg, vim.log.levels.ERROR, { title = "Offline Mode" })
		return false
	end
	return true
end

return M
