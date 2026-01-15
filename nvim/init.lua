require("gov.core")
-- Filetype detection
vim.filetype.add({
  extension = {
    d2 = "d2",
    locator = "xml",
    j2 = "jinja",
    jinja = "jinja",
    jinja2 = "jinja",
  },
  pattern = {
    [".*%.yaml%.j2"] = "yaml.jinja",
    [".*%.yml%.j2"] = "yaml.jinja",
    [".*%.json%.j2"] = "json.jinja",
    [".*%.xml%.j2"] = "xml.jinja",
  },
})


if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
  -- Force Unix line endings
  vim.opt.fileformat = 'unix'
  vim.opt.fileformats = 'unix,dos'
end

require("gov.lazy")
