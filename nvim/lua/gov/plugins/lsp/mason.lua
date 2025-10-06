return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
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
		})
	end,
}
