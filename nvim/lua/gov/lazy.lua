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
