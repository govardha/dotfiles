retreturn {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- Detect if running in airgapped environment
		-- Options: check hostname, environment variable, or presence of a marker file
		-- Use XDG_DATA_HOME for portable path resolution
		local data_home = os.getenv("XDG_DATA_HOME") or vim.fn.expand("~/.local/share")
		local config_home = os.getenv("XDG_CONFIG_HOME") or vim.fn.expand("~/.config")
		
		local is_airgapped = os.getenv("AIRGAPPED") == "true" 
			or vim.fn.hostname():match("airgapped") ~= nil
			or vim.fn.filereadable(config_home .. "/nvim/.airgapped") == 1

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
			-- Disable automatic installation on airgapped machine
			automatic_installation = not is_airgapped,
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
			-- Disable automatic installation and updates on airgapped machine
			auto_update = not is_airgapped,
			run_on_start = not is_airgapped,
		})
	end,
}urn {
