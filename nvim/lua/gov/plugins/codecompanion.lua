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

      -- ── Adapters ────────────────────────────────────────────────────
      adapters = {
        groq = function()
          local openai_compatible = require("codecompanion.adapters.http.openai_compatible")
          return require("codecompanion.adapters").extend(openai_compatible, {
            name = "groq",
            formatted_name = "Groq",
            env = {
              url = "https://api.groq.com/openai",
              api_key = "GROQ_API_KEY",
            },
            schema = {
              model = {
                default = "llama-3.3-70b-versatile",
              },
            },
          })
        end,

        openrouter = function()
          local openai_compatible = require("codecompanion.adapters.http.openai_compatible")
          return require("codecompanion.adapters").extend(openai_compatible, {
            name = "openrouter",
            formatted_name = "OpenRouter",
            env = {
              url = "https://openrouter.ai/api",
              api_key = "OPENROUTER_API_KEY",
            },
            headers = {
              ["HTTP-Referer"] = "https://github.com/olimorris/codecompanion.nvim",
              ["X-Title"] = "CodeCompanion",
            },
            schema = {
              model = {
                default = "anthropic/claude-sonnet-4-6",
              },
            },
          })
        end,

        gemini = function()
          local gemini = require("codecompanion.adapters.http.gemini")
          return require("codecompanion.adapters").extend(gemini, {
            env = { api_key = "GEMINI_API_KEY" },
            schema = {
              model = {
                default = "gemini-2.0-flash",
              },
            },
          })
        end,

        anthropic = function()
          local anthropic = require("codecompanion.adapters.http.anthropic")
          return require("codecompanion.adapters").extend(anthropic, {
            env = { api_key = "ANTHROPIC_API_KEY" },
            schema = {
              model = {
                default = "claude-sonnet-4-6",
              },
            },
          })
        end,
      },

      -- ── Strategy defaults (free tier first) ─────────────────────────
      strategies = {
        chat   = { adapter = "groq" },
        inline = { adapter = "groq" },
        agent  = { adapter = "groq" },
      },

      -- ── Display ─────────────────────────────────────────────────────
      display = {
        chat = {
          window = {
            layout = "vertical",
            width = 0.35,
          },
        },
        inline = {
          layout = "buffer",
        },
      },

      -- ── cmp source for slash commands inside chat buffers ────────────
      opts = {
        completion_provider = "cmp",
      },

    })

    -- ── cmp source registration ──────────────────────────────────────
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.setup.filetype({ "codecompanion" }, {
        sources = cmp.config.sources({
          { name = "codecompanion" },
        }),
      })
    end

    -- ── Keymaps (all under <leader>a) ────────────────────────────────
    local keymap = vim.keymap
    local map = function(mode, lhs, rhs, desc)
      keymap.set(mode, lhs, rhs, { desc = desc, noremap = true, silent = true })
    end

    map("n", "<leader>ac", "<cmd>CodeCompanionChat toggle<CR>", "AI: toggle chat")
    map("v", "<leader>ac", "<cmd>CodeCompanionChat toggle<CR>", "AI: toggle chat")

    map("n", "<leader>ag", "<cmd>CodeCompanionChat groq<CR>", "AI: chat (Groq free)")
    map("n", "<leader>am", "<cmd>CodeCompanionChat gemini<CR>", "AI: chat (Gemini free)")
    map("n", "<leader>ao", "<cmd>CodeCompanionChat openrouter<CR>", "AI: chat (OpenRouter)")
    map("n", "<leader>aa", "<cmd>CodeCompanionChat anthropic<CR>", "AI: chat (Anthropic)")

    map("n", "<leader>ai", "<cmd>CodeCompanion<CR>", "AI: inline prompt")
    map("v", "<leader>ai", "<cmd>CodeCompanion<CR>", "AI: inline (selection)")

    map("v", "<leader>as", "<cmd>CodeCompanionChat Add<CR>", "AI: add selection to chat")

    map("n", "<leader>ap", "<cmd>CodeCompanionActions<CR>", "AI: action picker")
    map("v", "<leader>ap", "<cmd>CodeCompanionActions<CR>", "AI: action picker")

    -- ── Offline guard ────────────────────────────────────────────────
    vim.api.nvim_create_user_command("AI", function(opts)
      if not offline_guard.check_online("CodeCompanion") then
        return
      end
      vim.cmd("CodeCompanion " .. opts.args)
    end, { nargs = "*", desc = "CodeCompanion with offline guard" })
  end,
}
