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

    -- 1. Create GROQ object (the working one)
    local my_groq = adapters.extend("openai_compatible", {
      env = {
        url = "https://api.groq.com/openai",
        api_key = os.getenv("GROQ_API_KEY"),
      },
      schema = {
        model = { default = "llama-3.3-70b-versatile" },
      },
    })

    -- 2. Create OPENROUTER object (the same way)
    local my_openrouter = adapters.extend("openai_compatible", {
      env = {
        url = "https://openrouter.ai/api/v1",
        api_key = os.getenv("OPENROUTER_API_KEY"),
      },
      headers = {
        ["HTTP-Referer"] = "https://github.com/olimorris/codecompanion.nvim",
        ["X-Title"] = "CodeCompanion",
      },
      schema = {
        model = {
          default = "google/gemini-2.0-flash-lite-preview-02-05:free",
        },
      },
    })

    -- 3. Pass the objects directly to setup
    require("codecompanion").setup({
      strategies = {
        chat = { adapter = my_groq },
        inline = { adapter = my_groq },
      },
      adapters = {
        groq = my_groq,
        openrouter = my_openrouter,
      },
    })

    -- ── Keymaps ──────────────────────────────────────────────────────
    local map = vim.keymap.set
    -- Groq (Still working)
    map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat adapter=groq<CR>", { desc = "AI: Groq" })
    -- OpenRouter (Added via the same stable method)
    map({ "n", "v" }, "<leader>ao", "<cmd>CodeCompanionChat adapter=openrouter<CR>", { desc = "AI: OpenRouter" })
    map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<CR>", { desc = "AI: Inline" })
  end,
}
