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
			"perlnavigator",
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

		-- Guard Mason commands when offline
		local offline_guard = require("gov.core.offline-guard")

		-- Wait a bit for Mason to register its commands
		vim.defer_fn(function()
			local mason_commands_to_guard = {
				{ cmd = "MasonUpdate", needs_online = true },
				{ cmd = "MasonInstall", needs_online = true },
				{ cmd = "MasonUninstall", needs_online = false },
				{ cmd = "Mason", needs_online = false },
				{ cmd = "MasonLog", needs_online = false },
			}

			for _, entry in ipairs(mason_commands_to_guard) do
				local cmd = entry.cmd
				local needs_online = entry.needs_online

				-- Store reference to original command
				local ok, original_def = pcall(vim.api.nvim_get_commands, {})
				if ok and original_def[cmd] then
					-- Delete and recreate with guard
					vim.api.nvim_del_user_command(cmd)
					vim.api.nvim_create_user_command(cmd, function(opts)
						if needs_online and not offline_guard.check_online(cmd) then
							return
						end
						-- Execute original Mason functionality
						require("mason.ui").open()
						if cmd == "MasonUpdate" then
							require("mason-registry").update()
						elseif cmd == "MasonInstall" and opts.args ~= "" then
							require("mason.api.command").MasonInstall(opts.args)
						end
					end, {
						nargs = "*",
						desc = original_def[cmd].definition,
						complete = function(_, line)
							if cmd == "MasonInstall" then
								return require("mason-core.installer.registry").get_all_package_names()
							end
						end,
					})
				end
			end
		end, 100)
	end,
}
