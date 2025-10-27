return {
	"terrastruct/d2-vim",
	ft = "d2", -- lazy-load only when opening .d2 files
	config = function()
		-- The plugin works out of the box with syntax highlighting and indentation
		-- No additional configuration needed unless you want custom keymaps

		-- Optional: Add any d2-specific keymaps here if needed
		-- Example:
		-- vim.keymap.set("n", "<leader>dd", "<cmd>!d2 % %:r.svg<CR>",
		--   { desc = "Compile D2 to SVG", buffer = true })
	end,
}
