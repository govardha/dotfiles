-- Core modules load order (no plugins here, just editor fundamentals):
-- [1a] options.lua    — vim.opt settings, clipboard, auto-save autocmds
-- [1b] keymaps.lua    — leader key, general keybindings (non-plugin)
-- [1c] offline-guard  — is_online() utility used by lazy.lua and mason.lua
require("gov.core.options")
require("gov.core.keymaps")
require("gov.core.offline-guard")
