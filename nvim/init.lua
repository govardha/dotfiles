require("gov.core")

-- Detect MSYS2 environment (UCRT64, MINGW64, CLANG64, etc.)
vim.g.is_msys2 = vim.fn.has("win32") == 1 and os.getenv("MSYSTEM") ~= nil

-- Filetype detection
vim.filetype.add({
  extension = {
    d2 = "d2",
    locator = "xml",
    j2 = "jinja",
    jinja = "jinja",
    jinja2 = "jinja",
    json = "jsonc",
  },
  pattern = {
    [".*%.yaml%.j2"] = "yaml.jinja",
    [".*%.yml%.j2"] = "yaml.jinja",
    [".*%.json%.j2"] = "json.jinja",
    [".*%.xml%.j2"] = "xml.jinja",
  },
})

-- Use the json treesitter parser for jsonc filetype
vim.treesitter.language.register("json", "jsonc")

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  -- Force Unix line endings
  vim.opt.fileformat = "unix"
  vim.opt.fileformats = "unix,dos"
end

if not vim.g.vscode then
  -- Full TTY neovim: load lazy.nvim and all plugins
  require("gov.lazy")
end
