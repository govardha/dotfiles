-- nvim/lua/gov/plugins/codecompanion.lua
return {
  "olimorris/codecompanion.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "stevearc/dressing.nvim",
  },
  config = function()
    local offline_guard = require("gov.core.offline-guard")

    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "openai_compatible" },
        inline = { adapter = "openai_compatible" },
        agent = { adapter = "openai_compatible" },
      },
      adapters = {
        -- We label this 'openai_compatible' so the plugin finds the base immediately
        openai_compatible = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            env = {
              url = "https://api.groq.com/openai/v1",
              api_key = "GROQ_API_KEY",
              chat_url = "/chat/completions",
            },
            schema = {
              model = {
                default = "llama-3.3-70b-versatile",
              },
            },
          })
        end,
        -- Gemini uses its own internal string ID
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = { api_key = "GEMINI_API_KEY" },
            schema = {
              model = { default = "gemini-2.0-flash" },
            },
          })
        end,
      },
      display = {
        chat = { window = { layout = "vertical", width = 0.40 } },
      },
      opts = {
        log_level = "DEBUG",
      },
    })

    -- ── Keymaps ──────────────────────────────────────────────────────
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, noremap = true, silent = true })
    end

    -- Update these to target the specific adapters correctly
    map("n", "<leader>ag", "<cmd>CodeCompanionChat openai_compatible<CR>", "AI: chat (Groq)")
    map("n", "<leader>am", "<cmd>CodeCompanionChat gemini<CR>", "AI: chat (Gemini)")
    map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat toggle<CR>", "AI: toggle chat")
    map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<CR>", "AI: inline prompt")
    map({ "n", "v" }, "<leader>ap", "<cmd>CodeCompanionActions<CR>", "AI: action picker")

    -- ── User Command with Offline Guard ──────────────────────────────
    vim.api.nvim_create_user_command("AI", function(cmd_opts)
      if not offline_guard.check_online("CodeCompanion") then return end
      vim.cmd("CodeCompanion " .. cmd_opts.args)
    end, { nargs = "*", desc = "CodeCompanion with offline guard" })
  end,
}
