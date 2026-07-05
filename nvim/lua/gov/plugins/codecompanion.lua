-- nvim/lua/gov/plugins/codecompanion.lua
--
-- CodeCompanion plugin config: AI-powered coding assistant for Neovim.
-- ACP agents (chat): kiro (home default), claude_code (work) — these run
-- their own tool loop over ACP and bypass CodeCompanion's built-in tools.
-- HTTP adapter (chat/inline): openrouter (occasional use) — the only path
-- that exercises CodeCompanion's own tools (file edit, run_command, etc.)
--
-- Env vars required:
--   OPENROUTER_API_KEY – for OpenRouter adapter
--   CLAUDE_CODE_OAUTH_TOKEN – optional; falls back to `claude` CLI's own login
--
return {
  "olimorris/codecompanion.nvim",
  cond = not vim.g.is_msys2,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-telescope/telescope.nvim"
  },
  opts = {
    interactions = {
      chat = {
        adapter = "kiro"
        -- NOTE: no static `tools.opts.default_tools` here. That option applies
        -- to every chat regardless of adapter, so it would tag ACP chats
        -- (kiro/claude_code) with a phantom "files" tool group even though
        -- ACP adapters never call CodeCompanion's own tools. The `files`
        -- group is instead added only for HTTP-adapter chats via the
        -- CodeCompanionChatCreated autocmd below.
      },
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
        extend = {
          kiro = {
            commands = {
              default = { "kiro-cli", "acp", "--trust-all-tools" }
            }
          }
          -- claude_code needs no override: built-in default command
          -- `claude-agent-acp` is on PATH and auths via `claude`'s own login.
        }
      },
      http = {
        extend = {
          openrouter = {
            schema = {
              model = { default = "google/gemini-2.5-flash" }
            }
          }
        }
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
          -- Only "default" is adapter-agnostic and safe to autoload for every
          -- chat. `enabled` on the kiro/claude groups below is ONLY consulted
          -- by the interactive `/rules` picker, NOT by autoload — autoload
          -- blindly loads every name in this list regardless of `enabled`.
          -- So kiro/claude rules are instead loaded conditionally by adapter
          -- via the CodeCompanionChatCreated autocmd below.
          autoload = { "default" }
        }
      }
    },
    opts = {
      log_level = "ERROR"
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
    { "<leader>aT", "<cmd>CodeCompanion /tests<CR>", mode = "v", desc = "AI: Generate tests" },
    { "<leader>am", "<cmd>CodeCompanion /commit<CR>", mode = "n", desc = "AI: Commit message" }
  },
  init = function ()
    vim.cmd([[cab cc CodeCompanion]])

    -- Adapter-conditional rules/tools: the plugin's `enabled` field on a
    -- rules group and its `tools.opts.default_tools` list both apply
    -- unconditionally to every chat, regardless of adapter. This autocmd
    -- fires once per chat, after it's fully created (adapter resolved), and
    -- applies the right rules/tools for that specific adapter:
    --   - kiro chats      -> load ~/.kiro/KIRO.md / KIRO.md
    --   - claude_code chats -> load ~/.claude/CLAUDE.md / CLAUDE.md / CLAUDE.local.md
    --   - http chats (openrouter) -> add the "files" tool group
    local rules_group_by_adapter = { kiro = "kiro", claude_code = "claude" }

    vim.api.nvim_create_autocmd("User", {
      pattern = "CodeCompanionChatCreated",
      callback = function(args)
        local chat = require("codecompanion.interactions.chat").buf_get_chat(args.data.bufnr)
        if not chat or not chat.adapter then
          return
        end

        if chat.adapter.type == "http" then
          chat.tool_registry:add("files")
          return
        end

        local group_name = rules_group_by_adapter[chat.adapter.name]
        local group = group_name and require("codecompanion.config").rules[group_name]
        if not group then
          return
        end

        require("codecompanion.interactions.shared.rules").add_to_chat_from_config(chat, {
          name = group_name,
          opts = group.opts,
          parser = group.parser,
          files = group.files
        })
      end
    })
  end
}
