return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		-- used to enable autocompletion
		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰌵 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
		})

		-- Helper function to check if executable exists in PATH
		local function executable_exists(name)
			return vim.fn.executable(name) == 1
		end

		-- Configure lua_ls
		if executable_exists("lua-language-server") or executable_exists("lua_ls") then
			vim.lsp.config.lua_ls = {
				cmd = { "lua-language-server" },
				root_markers = {
					".luarc.json",
					".luarc.jsonc",
					".luacheckrc",
					".stylua.toml",
					"stylua.toml",
					"selene.toml",
					"selene.yml",
				},
				filetypes = { "lua" },
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
						completion = {
							callSnippet = "Replace",
						},
					},
				},
			}
			vim.lsp.enable("lua_ls")
		end

		-- Configure basedpyright
		if executable_exists("basedpyright") or executable_exists("pyright") then
			vim.lsp.config.basedpyright = {
				cmd = { "basedpyright-langserver", "--stdio" },
				root_markers = {
					"pyproject.toml",
					"setup.py",
					"setup.cfg",
					"requirements.txt",
					"Pipfile",
					"pyrightconfig.json",
				},
				filetypes = { "python" },
				capabilities = capabilities,
				settings = {
					basedpyright = {
						analysis = {
							typeCheckingMode = "basic",
							autoSearchPaths = true,
							diagnosticMode = "workspace",
							useLibraryCodeForTypes = true,
						},
					},
				},
			}
			vim.lsp.enable("basedpyright")
		end

		-- Configure bashls
		if executable_exists("bash-language-server") then
			vim.lsp.config.bashls = {
				cmd = { "bash-language-server", "start" },
				root_markers = { ".git" },
				filetypes = { "sh" },
				capabilities = capabilities,
			}
			vim.lsp.enable("bashls")
		end

		-- Configure ansiblels
		if executable_exists("ansible-language-server") then
			vim.lsp.config.ansiblels = {
				cmd = { "ansible-language-server", "--stdio" },
				root_markers = { "ansible.cfg", ".ansible-lint" },
				filetypes = { "yaml.ansible" },
				capabilities = capabilities,
			}
			vim.lsp.enable("ansiblels")
		end

		-- Configure jsonls
		if executable_exists("vscode-json-language-server") or executable_exists("json-languageserver") then
			vim.lsp.config.jsonls = {
				cmd = { "vscode-json-language-server", "--stdio" },
				root_markers = { ".git" },
				filetypes = { "json", "jsonc" },
				capabilities = capabilities,
			}
			vim.lsp.enable("jsonls")
		end

		-- Configure yamlls
		if executable_exists("yaml-language-server") then
			vim.lsp.config.yamlls = {
				cmd = { "yaml-language-server", "--stdio" },
				root_markers = { ".git" },
				filetypes = { "yaml", "yaml.docker-compose" },
				capabilities = capabilities,
			}
			vim.lsp.enable("yamlls")
		end

		-- Configure docker_compose_language_service
		if executable_exists("docker-compose-langserver") then
			vim.lsp.config.docker_compose_language_service = {
				cmd = { "docker-compose-langserver", "--stdio" },
				root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml" },
				filetypes = { "yaml.docker-compose" },
				capabilities = capabilities,
			}
			vim.lsp.enable("docker_compose_language_service")
		end
	end,
}
