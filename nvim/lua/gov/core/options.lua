local opt = vim.opt -- for conciseness

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- Conditional clipboard setup
if os.getenv("SSH_TTY") then
	-- Custom OSC 52 implementation (built-in module is broken)
	local function osc52_copy(lines, _)
		local text = table.concat(lines, "\n")
		local b64 = vim.base64.encode(text)
		io.stdout:write(string.format("\027]52;c;%s\007", b64))
		io.stdout:flush()
	end

	local function osc52_paste()
		return {}
	end

	vim.g.clipboard = {
		name = "OSC 52 (custom)",
		copy = {
			["+"] = osc52_copy,
			["*"] = osc52_copy,
		},
		paste = {
			["+"] = osc52_paste,
			["*"] = osc52_paste,
		},
	}

	-- Auto-copy ALL yanks to system clipboard via OSC 52
	vim.api.nvim_create_autocmd("TextYankPost", {
		callback = function()
			if vim.v.event.operator == "y" then
				local text = table.concat(vim.fn.getreg('"', 1, 1), "\n")
				local b64 = vim.base64.encode(text)
				io.stdout:write(string.format("\027]52;c;%s\007", b64))
				io.stdout:flush()
			end
		end,
	})
else
	-- Use system clipboard when local
	vim.opt.clipboard = "unnamedplus"
end

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false
opt.scrolloff = 999
opt.virtualedit = "block"
-- vim.g.clipboard = "osc52" -- need for weztermm cuopy/pasta

-- -- Auto-save on text change, focus lost, and buffer switch
local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = auto_save_group,
	callback = function()
		if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
			vim.cmd("silent! write")
		end
	end,
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
	group = auto_save_group,
	callback = function()
		if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
			vim.cmd("silent! wall") -- Save all modified buffers
		end
	end,
})
