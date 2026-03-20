-- nvim/lua/gov/plugins/codecompanion.lua
return {
  "olimorris/codecompanion.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "stevearc/dressing.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local adapters = require("codecompanion.adapters")

    -- 1. Create the adapter object directly in a variable
    local groq_adapter = adapters.extend("openai_compatible", {
      env = {
        url = "https://api.groq.com/openai/v1",
        chat_url = "/chat/completions",
        api_key = "GROQ_API_KEY",
      },
      schema = {
        model = {
          default = "llama-3.3-70b-versatile",
        },
      },
    })

    require("codecompanion").setup({
      strategies = {
        -- 2. PASS THE OBJECT DIRECTLY. No strings, no "resolve" call.
        chat = { adapter = groq_adapter },
        slash_commands = {
          ["file"] = {
            callback = "helpers.slash_commands.file",
            description = "Select a file with Telescope",
            opts = {
              provider = "telescope", -- Forces it to use Telescope
              contains_code = true,
            },
          },
        },
        inline = { adapter = groq_adapter },
      },
      -- We still map it here so the UI knows what to call it
      adapters = {
        groq = groq_adapter,
      },
      opts = { log_level = "TRACE" }, -- Crank this up to see everything
    })

    -- ── Keymaps ──────────────────────────────────────────────────────
    local map = vim.keymap.set
    map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat toggle<CR>", { desc = "AI: Toggle Chat" })
    map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<CR>", { desc = "AI: Inline" })
  end,
}
