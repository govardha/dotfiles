return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		-- Helper function to check if executable exists in PATH
		local function executable_exists(name)
			return vim.fn.executable(name) == 1
		end

		-- Build formatters_by_ft table based on available executables
		local formatters_by_ft = {}

		-- Web formats (if prettier is available)
		if executable_exists("prettier") then
			formatters_by_ft.html = { "prettier" }
			formatters_by_ft.json = { "prettier" }
			formatters_by_ft.yaml = { "prettier" }
			formatters_by_ft.markdown = { "prettier" }
		end

		-- Lua
		if executable_exists("stylua") then
			formatters_by_ft.lua = { "stylua" }
		end

		-- Python
		local python_formatters = {}

		if executable_exists("ruff") then
			table.insert(python_formatters, "ruff")
		end

		if executable_exists("black") then
			table.insert(python_formatters, "black")
		end

		if #python_formatters > 0 then
			formatters_by_ft.python = python_formatters
		end

		-- Shell
		if executable_exists("shfmt") then
			formatters_by_ft.sh = { "shfmt" }
		end

		conform.setup({
			formatters_by_ft = formatters_by_ft,
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 500,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 500,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
