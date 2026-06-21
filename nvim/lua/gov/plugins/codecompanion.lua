-- nvim/lua/gov/plugins/codecompanion.lua
--
-- CodeCompanion plugin config: AI-powered coding assistant for Neovim.
-- ACP agents: kiro (home default), claude_code (work)
-- HTTP adapters: openrouter (occasional use)
--
-- Env vars required:
--   OPENROUTER_API_KEY – for OpenRouter adapter
--   CLAUDE_CODE_OAUTH_TOKEN – for Claude Code (or use API key auth)
--
return {
  "olimorris/codecompanion.nvim",
  cond = not vim.g.is_msys2,
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-telescope/telescope.nvim"
  },
  opts = {
    interactions = {
      chat = { adapter = "kiro" },
      inline = { adapter = "openrouter" },
      cli = {
        agent = "kiro",
        agents = {
          kiro = {
            cmd = "kiro-cli",
            args = { "chat", "--trust-all-tools" },
            description = "Kiro CLI"
          },
          claude_code = {
            cmd = "claude",
            args = {},
            description = "Claude Code CLI"
          }
        }
      }
    },
    adapters = {
      acp = {
        kiro = function ()
          return require("codecompanion.adapters").extend("kiro", {
            commands = {
              default = {
                "kiro-cli",
                "acp",
                "--trust-all-tools"
              }
            }
          })
        end,
        claude_code = function ()
          return require("codecompanion.adapters").extend("claude_code", {})
        end
      },
      http = {
        openrouter = function ()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "openrouter",
            formatted_name = "OpenRouter",
            env = {
              url = "https://openrouter.ai/api",
              api_key = "OPENROUTER_API_KEY",
              chat_url = "/v1/chat/completions"
            },
            headers = {
              ["HTTP-Referer"] = "https://github.com/olimorris/codecompanion.nvim",
              ["X-Title"] = "CodeCompanion"
            },
            schema = {
              model = {
                default = "google/gemini-2.5-flash"
              }
            }
          })
        end
      }
    },
    rules = {
      default = {
        description = "Common rules for all adapters",
        is_preset = true,
        files = {
          ".cursorrules",
          ".clinerules",
          "AGENT.md"
        }
      },
      kiro = {
        description = "Kiro CLI rules",
        enabled = function(chat)
          return chat and chat.adapter and chat.adapter.name == "kiro"
        end,
        files = {
          "~/.kiro/KIRO.md",
          "KIRO.md"
        }
      },
      claude = {
        description = "Claude Code rules",
        enabled = function(chat)
          return chat and chat.adapter and chat.adapter.name == "claude_code"
        end,
        parser = "claude",
        files = {
          "~/.claude/CLAUDE.md",
          "CLAUDE.md",
          "CLAUDE.local.md"
        }
      },
      opts = {
        chat = {
          enabled = true,
          autoload = { "default", "kiro", "claude" }
        }
      }
    },
    opts = {
      log_level = "DEBUG"
    }
  },
  keys = {
    -- Chat: open with specific adapter
    { "<leader>ak", "<cmd>CodeCompanionChat adapter=kiro<CR>", mode = { "n", "v" }, desc = "AI: Kiro (default)" },
    { "<leader>ac", "<cmd>CodeCompanionChat adapter=claude_code<CR>", mode = { "n", "v" }, desc = "AI: Claude Code" },
    { "<leader>ao", "<cmd>CodeCompanionChat adapter=openrouter<CR>", mode = { "n", "v" }, desc = "AI: OpenRouter" },

    -- Inline
    { "<leader>ai", "<cmd>CodeCompanion<CR>", mode = { "n", "v" }, desc = "AI: Inline (openrouter)" },
    { "<leader>aI", "<cmd>CodeCompanion adapter=kiro<CR>", mode = { "n", "v" }, desc = "AI: Inline (kiro)" },

    -- CLI (terminal)
    { "<leader>aK", "<cmd>CodeCompanionCLI<CR>", mode = { "n", "v" }, desc = "AI: Kiro CLI (terminal)" },
    {
      "<leader>aC",
      "<cmd>CodeCompanionCLI agent=claude_code<CR>",
      mode = { "n", "v" },
      desc = "AI: Claude CLI (terminal)"
    },

    -- Chat buffer controls
    { "<leader>at", "<cmd>CodeCompanionChat Toggle<CR>", mode = { "n", "v" }, desc = "AI: Toggle Chat" },
    { "<C-a>", "<cmd>CodeCompanionActions<CR>", mode = { "n", "v" }, desc = "AI: Action Palette" },
    { "ga", "<cmd>CodeCompanionChat Add<CR>", mode = "v", desc = "AI: Add selection to Chat" },

    -- Prompt library
    { "<leader>ae", "<cmd>CodeCompanion /explain<CR>", mode = "v", desc = "AI: Explain code" },
    { "<leader>af", "<cmd>CodeCompanion /fix<CR>", mode = "v", desc = "AI: Fix code" },
    { "<leader>au", "<cmd>CodeCompanion /usage<CR>", mode = "v", desc = "AI: Usage" },
    { "<leader>aT", "<cmd>CodeCompanion /tests<CR>", mode = "v", desc = "AI: Generate tests" },
    { "<leader>am", "<cmd>CodeCompanion /commit<CR>", mode = "n", desc = "AI: Commit message" }
  },
  init = function ()
    vim.cmd([[cab cc CodeCompanion]])
  end
}
