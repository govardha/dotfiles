-- Detect if running with internet connectivity
-- By default, assume NO internet (airgapped/offline)
-- Only enable updates if explicitly set to online
local config_home = os.getenv("XDG_CONFIG_HOME") or vim.fn.expand("~/.config")
local is_online = os.getenv("NVIM_ONLINE") == "true"
	or vim.fn.hostname():match("online") ~= nil
	or vim.fn.filereadable(config_home .. "/nvim/.online") == 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	-- Only attempt to clone if explicitly online
	if is_online then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable", -- latest stable release
			lazypath,
		})
	else
		vim.notify(
			"Lazy.nvim not found at "
				.. lazypath
				.. " and NVIM_ONLINE is not set. Please install manually or set NVIM_ONLINE=true.",
			vim.log.levels.ERROR
		)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "gov.plugins" }, { import = "gov.plugins.lsp" } }, {
	checker = {
		enabled = is_online, -- Only check for updates when online
		notify = false,
	},
	change_detection = {
		enabled = is_online, -- Only detect changes when online
		notify = false,
	},
	git = {
		timeout = is_online and 120 or 0, -- Disable git operations when offline
	},
	install = {
		missing = is_online, -- Only install missing plugins when online
	},
	ui = {
		border = "rounded",
	},
})

-- Guard Lazy commands when offline
local offline_guard = require("gov.core.offline-guard")

-- Commands that require internet connectivity
local lazy_commands_that_need_online = {
	{ cmd = "LazyUpdate", desc = "Update plugins" },
	{ cmd = "LazySync", desc = "Run install, clean and update" },
	{ cmd = "LazyInstall", desc = "Install missing plugins" },
	{ cmd = "LazyClean", desc = "Clean plugins that are no longer needed" },
	{ cmd = "LazyCheck", desc = "Check for updates" },
}

-- Commands that can work offline (viewing only)
local lazy_commands_offline_ok = {
	{ cmd = "Lazy", desc = "Show Lazy UI" },
	{ cmd = "LazyLog", desc = "Show recent updates" },
	{ cmd = "LazyProfile", desc = "Show profile information" },
	{ cmd = "LazyDebug", desc = "Show debug information" },
	{ cmd = "LazyHealth", desc = "Run health checks" },
}

-- Wait for Lazy to register its commands
vim.defer_fn(function()
	-- Guard commands that need internet
	for _, entry in ipairs(lazy_commands_that_need_online) do
		local cmd = entry.cmd

		-- Check if command exists
		local ok, original_def = pcall(vim.api.nvim_get_commands, {})
		if ok and original_def[cmd] then
			-- Delete and recreate with guard
			vim.api.nvim_del_user_command(cmd)
			vim.api.nvim_create_user_command(cmd, function(opts)
				if not offline_guard.check_online(cmd) then
					return
				end
				-- Execute original Lazy command
				require("lazy").sync({
					show = false,
					wait = false,
				})
				if cmd == "LazyUpdate" then
					require("lazy").update()
				elseif cmd == "LazySync" then
					require("lazy").sync()
				elseif cmd == "LazyInstall" then
					require("lazy").install()
				elseif cmd == "LazyClean" then
					require("lazy").clean()
				elseif cmd == "LazyCheck" then
					require("lazy").check()
				end
			end, {
				nargs = "*",
				desc = entry.desc .. " (with offline guard)",
			})
		end
	end

	-- Add offline warnings to view-only commands
	for _, entry in ipairs(lazy_commands_offline_ok) do
		local cmd = entry.cmd

		local ok, original_def = pcall(vim.api.nvim_get_commands, {})
		if ok and original_def[cmd] then
			vim.api.nvim_del_user_command(cmd)
			vim.api.nvim_create_user_command(cmd, function(opts)
				-- Show info message if offline
				if not is_online then
					vim.notify(
						"Running in offline mode. Updates/installs disabled.\n"
							.. "To enable: export NVIM_ONLINE=true or touch ~/.config/nvim/.online",
						vim.log.levels.INFO,
						{ title = "Lazy (Offline Mode)" }
					)
				end
				-- Execute original command
				if cmd == "Lazy" then
					require("lazy").show()
				elseif cmd == "LazyLog" then
					require("lazy").log()
				elseif cmd == "LazyProfile" then
					require("lazy").profile()
				elseif cmd == "LazyDebug" then
					require("lazy").debug()
				elseif cmd == "LazyHealth" then
					require("lazy").health()
				end
			end, {
				nargs = "*",
				desc = entry.desc,
			})
		end
	end
end, 100)
