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


    -- 4. Pass the objects directly to setup
    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "kiro" },
        inline = { adapter = "kiro" },
        agent = { adapter = "kiro" },
      },
      adapters = {
        groq = my_groq,
        openrouter = my_openrouter,
      },
      opts = {
        log_level = "DEBUG", -- TRACE|DEBUG|ERROR|INFO
      },
    })

    -- ── Keymaps ──────────────────────────────────────────────────────
    local map = vim.keymap.set
    map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat adapter=groq<CR>", { desc = "AI: Groq" })
    map({ "n", "v" }, "<leader>ao", "<cmd>CodeCompanionChat adapter=openrouter<CR>", { desc = "AI: OpenRouter" })
    map({ "n", "v" }, "<leader>al", "<cmd>CodeCompanionChat adapter=claude_code<CR>", { desc = "AI: Claude Code" })
    map({ "n", "v" }, "<leader>ak", "<cmd>CodeCompanionChat adapter=kiro<CR>", { desc = "AI: Kiro" })
    map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<CR>", { desc = "AI: Inline" })

    -- Recommended additions from the docs
    map({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<CR>", { desc = "AI: Action Palette" })
    map({ "n", "v" }, "<leader>at", "<cmd>CodeCompanionChat Toggle<CR>", { desc = "AI: Toggle Chat" })
    map("v", "ga", "<cmd>CodeCompanionChat Add<CR>", { desc = "AI: Add to Chat" })

    -- Prompt library shortcuts (visual mode only)
    map("v", "<leader>ae", "<cmd>CodeCompanion /explain<CR>", { desc = "AI: Explain" })
    map("v", "<leader>af", "<cmd>CodeCompanion /fix<CR>", { desc = "AI: Fix" })
    map("v", "<leader>aT", "<cmd>CodeCompanion /tests<CR>", { desc = "AI: Tests" })
    map("n", "<leader>am", "<cmd>CodeCompanion /commit<CR>", { desc = "AI: Commit msg" })

    -- Command line abbreviation (type 'cc' instead of 'CodeCompanion')
    vim.cmd([[cab cc CodeCompanion]])
  end,
}
