return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- Helper function to check if executable exists in PATH
		local function executable_exists(name)
			return vim.fn.executable(name) == 1
		end

		-- Build linters_by_ft table based on available executables
		local linters_by_ft = {}

		-- Python
		if executable_exists("ruff") then
			linters_by_ft.python = { "ruff" }
		end

		-- Shell
		if executable_exists("shellcheck") then
			linters_by_ft.sh = { "shellcheck" }
			linters_by_ft.bash = { "shellcheck" }
		end

		lint.linters_by_ft = linters_by_ft

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
