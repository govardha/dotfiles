require("gov.core")
-- Filetype detection
vim.filetype.add({
  extension = {
    d2 = "d2",
    locator = "xml",
  },
})

if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
  -- Force Unix line endings
  vim.opt.fileformat = 'unix'
  vim.opt.fileformats = 'unix,dos'
end

require("gov.lazy")
