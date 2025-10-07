return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- Detect if running with internet connectivity
		-- By default, assume NO internet (airgapped/offline)
		-- Only enable updates if explicitly set to online
		local data_home = os.getenv("XDG_DATA_HOME") or vim.fn.expand("~/.local/share")
		local config_home = os.getenv("XDG_CONFIG_HOME") or vim.fn.expand("~/.config")

		local is_online = os.getenv("NVIM_ONLINE") == "true"
			or vim.fn.hostname():match("online") ~= nil
			or vim.fn.filereadable(config_home .. "/nvim/.online") == 1

		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- ONLY LSP servers here
		mason_lspconfig.setup({
			ensure_installed = {
				--        "basedpyright",
				"pyrefly",
				"bashls",
				"ansiblels",
				"jsonls",
				"yamlls",
				"docker_compose_language_service",
				"lua_ls",
			},
			-- Only enable automatic installation when online
			automatic_installation = is_online,
		})

		-- All formatters, linters, and other tools here
		mason_tool_installer.setup({
			ensure_installed = {
				-- Formatters
				"prettier",
				"shfmt",
				"stylua",
				"ruff", -- ruff handles both formatting and linting

				-- Linters
				"shellcheck",
				"jsonlint",
				"yamllint",
				"hadolint",
				"ansible-lint",
			},
			-- Only enable automatic installation and updates when online
			auto_update = is_online,
			run_on_start = is_online,
		})
	end,
}
