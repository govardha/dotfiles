return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- Detect OS
		local uname = vim.loop.os_uname()
		local is_mac = uname.sysname == "Darwin"
		local is_linux = uname.sysname == "Linux"
		local is_rhel = is_linux and vim.fn.filereadable("/etc/redhat-release") == 1
		local is_ubuntu = is_linux and vim.fn.filereadable("/etc/lsb-release") == 1

		-- Detect if running with internet connectivity
		local data_home = os.getenv("XDG_DATA_HOME") or vim.fn.expand("~/.local/share")
		local config_home = os.getenv("XDG_CONFIG_HOME") or vim.fn.expand("~/.config")

		local is_online = os.getenv("NVIM_ONLINE") == "true"
			or vim.fn.hostname():match("online") ~= nil
			or vim.fn.filereadable(config_home .. "/nvim/.online") == 1

		-- Common LSP servers for all platforms
		local common_lsp_servers = {
			"pyrefly",
			"bashls",
			"jsonls",
			"yamlls",
			"emmylua_ls", -- Use EmmyLua on RHEL8 due to GLIBC issues
			"docker_compose_language_service",
		}

		-- OS-specific LSP servers
		local os_specific_lsp = {}
		if is_rhel then
			os_specific_lsp = {
				"ansiblels",
			}
		elseif is_ubuntu then
			os_specific_lsp = {
				"ansiblels",
			}
		elseif is_mac then
			os_specific_lsp = {}
		else
			-- Default fallback for other systems
			os_specific_lsp = {
				"emmylua_ls",
			}
		end

		-- Combine common and OS-specific servers
		local lsp_servers = vim.list_extend(vim.deepcopy(common_lsp_servers), os_specific_lsp)

		-- Common tools for all platforms
		local common_tools = {
			-- Formatters
			"prettier",
			"shfmt",
			"ruff", -- ruff handles both formatting and linting

			-- Linters
			"shellcheck",
			"jsonlint",
			"yamllint",
			"hadolint",
		}

		-- OS-specific tools
		local os_specific_tools = {}
		if is_rhel then
			os_specific_tools = {}
		elseif is_ubuntu then
			os_specific_tools = {}
		elseif is_mac then
			os_specific_tools = {}
		else
			os_specific_tools = {
				"emmylua-codeformat",
			}
		end

		-- Combine common and OS-specific tools
		local all_tools = vim.list_extend(vim.deepcopy(common_tools), os_specific_tools)

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
			ensure_installed = lsp_servers,
			automatic_installation = is_online,
		})

		-- All formatters, linters, and other tools here
		mason_tool_installer.setup({
			ensure_installed = all_tools,
			auto_update = is_online,
			run_on_start = is_online,
		})
	end,
}
