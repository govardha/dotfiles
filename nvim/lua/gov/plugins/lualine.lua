-- nvim/lua/gov/plugins/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    local colors = {
      blue = "#65D1FF",
      green = "#3EFFDC",
      violet = "#FF61EF",
      yellow = "#FFDA7B",
      red = "#FF4A4A",
      fg = "#c3ccdc",
      bg = "#112638",
      inactive_bg = "#2c3043",
    }

    -- ── CodeCompanion adapter indicator ─────────────────────────────
    local adapter_colors = {
      groq       = colors.green,
      gemini     = colors.blue,
      openrouter = colors.yellow,
      anthropic  = colors.violet,
    }

    local adapter_labels = {
      groq       = "󱙺 groq",
      gemini     = "󰊭 gemini",
      openrouter = "󰅩 openrouter",
      anthropic  = "󰜚 anthropic",
    }

    local function codecompanion_indicator()
      local ok, codecompanion = pcall(require, "codecompanion")
      if not ok then return "" end

      -- only show when a chat buffer is active or codecompanion is loaded
      local ok2, config = pcall(require, "codecompanion.config")
      if not ok2 then return "" end

      local adapter = config.options
        and config.options.strategies
        and config.options.strategies.chat
        and config.options.strategies.chat.adapter
        or nil

      if not adapter then return "" end
      return adapter_labels[adapter] or ("󰅩 " .. adapter)
    end

    local function codecompanion_color()
      local ok, config = pcall(require, "codecompanion.config")
      if not ok then return { fg = colors.fg } end

      local adapter = config.options
        and config.options.strategies
        and config.options.strategies.chat
        and config.options.strategies.chat.adapter
        or nil

      return { fg = adapter_colors[adapter] or colors.fg }
    end

    -- ── Theme (unchanged from your original) ────────────────────────
    local my_lualine_theme = {
      normal = {
        a = { bg = colors.blue,        fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg,          fg = colors.fg },
        c = { bg = colors.bg,          fg = colors.fg },
      },
      insert = {
        a = { bg = colors.green,       fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg,          fg = colors.fg },
        c = { bg = colors.bg,          fg = colors.fg },
      },
      visual = {
        a = { bg = colors.violet,      fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg,          fg = colors.fg },
        c = { bg = colors.bg,          fg = colors.fg },
      },
      command = {
        a = { bg = colors.yellow,      fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg,          fg = colors.fg },
        c = { bg = colors.bg,          fg = colors.fg },
      },
      replace = {
        a = { bg = colors.red,         fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg,          fg = colors.fg },
        c = { bg = colors.bg,          fg = colors.fg },
      },
      inactive = {
        a = { bg = colors.inactive_bg, fg = colors.fg, gui = "bold" },
        b = { bg = colors.inactive_bg, fg = colors.fg },
        c = { bg = colors.inactive_bg, fg = colors.fg },
      },
    }

    lualine.setup({
      options = {
        theme = my_lualine_theme,
      },
      sections = {
        lualine_x = {
          {
            codecompanion_indicator,
            color = codecompanion_color,
            cond = function()
              local ok, _ = pcall(require, "codecompanion")
              return ok
            end,
          },
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#ff9e64" },
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })
  end,
}
