-- nvim/lua/gov/plugins/codecompanion.lua
--
-- CodeCompanion plugin config: AI-powered coding assistant for Neovim.
-- Supports multiple LLM backends (Groq, OpenRouter, Claude Code)
-- via the openai_compatible adapter interface.
--
-- Env vars required:
--   GROQ_API_KEY      – for Groq adapter
--   OPENROUTER_API_KEY – for OpenRouter adapter
--
return {
  "olimorris/codecompanion.nvim",
  lazy = false, -- load immediately so keymaps are always available
  dependencies = {
    "nvim-lua/plenary.nvim",            -- async utilities
    "nvim-treesitter/nvim-treesitter",  -- syntax-aware context
    "hrsh7th/nvim-cmp",                 -- completion integration
    "stevearc/dressing.nvim",           -- improved UI for select/input
    "nvim-telescope/telescope.nvim",    -- fuzzy finder integration
  },
  config = function()
    local adapters = require("codecompanion.adapters")

    -- 1. Groq adapter – fast inference, free tier available
    local my_groq = adapters.extend("openai_compatible", {
      env = {
        url = "https://api.groq.com/openai",
        api_key = os.getenv("GROQ_API_KEY"),
      },
      schema = {
        model = { default = "llama-3.3-70b-versatile" },
      },
    })

    -- 2. OpenRouter adapter – gateway to many models, using free Gemini tier
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


    -- 4. Main setup – wire adapters into strategies
    --    chat & agent use claude_code; inline uses groq for speed
    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "claude_code" },
        inline = { adapter = my_groq },
        agent = { adapter = "claude_code" },
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

    -- ── Chat: open with specific adapter ─────────────────────────────
    map({ "n", "v" }, "<leader>ak", "<cmd>CodeCompanionChat adapter=kiro<CR>", { desc = "AI: Kiro (default chat)" })
    map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat adapter=claude_code<CR>", { desc = "AI: Claude Code" })
    map({ "n", "v" }, "<leader>ag", "<cmd>CodeCompanionChat adapter=groq<CR>", { desc = "AI: Groq (free)" })
    map({ "n", "v" }, "<leader>ao", "<cmd>CodeCompanionChat adapter=openrouter<CR>", { desc = "AI: OpenRouter" })

    -- ── Inline: quick edits in-place ─────────────────────────────────
    map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<CR>", { desc = "AI: Inline (groq)" })
    map({ "n", "v" }, "<leader>aI", "<cmd>CodeCompanion adapter=openrouter<CR>", { desc = "AI: Inline (openrouter)" })

    -- ── Chat buffer controls ──────────────────────────────────────────
    map({ "n", "v" }, "<leader>at", "<cmd>CodeCompanionChat Toggle<CR>", { desc = "AI: Toggle Chat" })
    map({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<CR>", { desc = "AI: Action Palette" })
    map("v", "ga", "<cmd>CodeCompanionChat Add<CR>", { desc = "AI: Add selection to Chat" })

    -- ── Prompt library (visual selection required) ────────────────────
    map("v", "<leader>ae", "<cmd>CodeCompanion /explain<CR>", { desc = "AI: Explain code" })
    map("v", "<leader>af", "<cmd>CodeCompanion /fix<CR>", { desc = "AI: Fix code" })
    map("v", "<leader>aT", "<cmd>CodeCompanion /tests<CR>", { desc = "AI: Generate tests" })
    map("n", "<leader>am", "<cmd>CodeCompanion /commit<CR>", { desc = "AI: Commit message" })

    -- ── Command abbreviation: type `:cc` instead of `:CodeCompanion` ──
    vim.cmd([[cab cc CodeCompanion]])
  end,
}
