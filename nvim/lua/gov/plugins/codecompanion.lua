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
-- Kiro's ACP server doesn't use the standard ACP `configOptions` field for
-- model/mode selection, so CodeCompanion's built-in `ga` (change adapter)
-- picker is always empty for kiro chats. Verified directly against the wire
-- protocol: `session/new`'s result instead carries its own
-- `models.availableModels[].{modelId,name,description}` and
-- `modes.availableModes[].{id,name,description}` blocks, which CodeCompanion
-- reads nowhere. `session/set_model`/`session/set_mode` (both non-standard,
-- Kiro-specific RPC methods, params `{sessionId, modelId|modeId}`) do work
-- when called directly though. The patch + keymaps below capture that data
-- (since CodeCompanion itself discards it) and act on it: <leader>km / <leader>kM.
local kiro_rpc_patched = false

---Capture Kiro's custom models/modes blocks from session/new, onto the ACP
---connection itself, the moment CodeCompanion is guaranteed to be loaded
---(this runs from inside the ChatCreated autocmd below).
local function ensure_kiro_rpc_patch()
  if kiro_rpc_patched then
    return
  end
  kiro_rpc_patched = true

  local acp = require("codecompanion.acp")
  local orig_send_rpc_request = acp.send_rpc_request
  acp.send_rpc_request = function(self, method, params)
    local result = orig_send_rpc_request(self, method, params)
    if method == "session/new" and type(result) == "table" and (result.models or result.modes) then
      self._kiro_catalog = { models = result.models, modes = result.modes }

      -- Also fix the chat's *initial* metadata: CodeCompanion's own
      -- update_metadata() reads the model via get_models(), which is always
      -- nil for Kiro, so without this a fresh chat shows a wrong/generic
      -- "default" model until a manual <leader>km change corrects it.
      -- Deferred to the main loop since this runs from inside RPC response
      -- handling — find the chat this connection belongs to by matching
      -- acp_connection against every open chat buffer (Connection has no
      -- bufnr of its own to look up directly).
      if result.models and result.models.currentModelId then
        local connection = self
        vim.schedule(function()
          for _, bufnr in ipairs(_G.codecompanion_buffers or {}) do
            local chat = require("codecompanion.interactions.chat").buf_get_chat(bufnr)
            if chat and chat.acp_connection == connection then
              chat:update_metadata()
              local meta = _G.codecompanion_chat_metadata and _G.codecompanion_chat_metadata[bufnr]
              if meta and meta.adapter then
                meta.adapter.model = result.models.currentModelId
              end
              vim.cmd("redrawstatus")
              break
            end
          end
        end)
      end
    end
    return result
  end
end

---@return CodeCompanion.Chat|nil
local function get_kiro_chat()
  if vim.bo.filetype ~= "codecompanion" then
    vim.notify("Not in a CodeCompanion chat buffer", vim.log.levels.WARN)
    return nil
  end

  local chat = require("codecompanion.interactions.chat").buf_get_chat(vim.api.nvim_get_current_buf())
  if not chat or not chat.adapter or chat.adapter.name ~= "kiro" then
    vim.notify("Not a Kiro chat", vim.log.levels.WARN)
    return nil
  end

  if not chat.acp_connection or not chat.acp_connection.session_id then
    vim.notify("Kiro session isn't connected yet", vim.log.levels.WARN)
    return nil
  end

  return chat
end

local function kiro_select_model()
  local chat = get_kiro_chat()
  if not chat then
    return
  end

  local catalog = chat.acp_connection._kiro_catalog
  local models = catalog and catalog.models and catalog.models.availableModels
  if not models or #models == 0 then
    return vim.notify("No Kiro models captured for this session yet", vim.log.levels.WARN)
  end

  vim.ui.select(models, {
    prompt = "Kiro: select model",
    format_item = function(m)
      local marker = (m.modelId == catalog.models.currentModelId) and "* " or "  "
      return marker .. m.name .. (m.description and (" — " .. m.description) or "")
    end,
  }, function(choice)
    if not choice then
      return
    end

    local ok, result = pcall(chat.acp_connection.send_rpc_request, chat.acp_connection, "session/set_model", {
      sessionId = chat.acp_connection.session_id,
      modelId = choice.modelId,
    })

    if ok and result then
      catalog.models.currentModelId = choice.modelId

      -- chat:update_metadata() would overwrite this with "default" — it
      -- reads the model via CodeCompanion's own get_models(), which is
      -- always nil for Kiro (that's the whole reason this file exists).
      -- Set it directly from what we know is actually true instead.
      chat:update_metadata()
      local meta = _G.codecompanion_chat_metadata and _G.codecompanion_chat_metadata[chat.bufnr]
      if meta and meta.adapter then
        meta.adapter.model = choice.modelId
      end

      -- We bypassed chat:change_model(), so no ChatModel event fired to
      -- tell lualine's redraw hook to refresh — do it ourselves.
      vim.cmd("redrawstatus")

      vim.notify("Kiro model: " .. choice.name, vim.log.levels.INFO)
    else
      vim.notify("Failed to set Kiro model" .. (ok and "" or (": " .. tostring(result))), vim.log.levels.ERROR)
    end
  end)
end

local function kiro_select_mode()
  local chat = get_kiro_chat()
  if not chat then
    return
  end

  local catalog = chat.acp_connection._kiro_catalog
  local modes = catalog and catalog.modes and catalog.modes.availableModes
  if not modes or #modes == 0 then
    return vim.notify("No Kiro modes captured for this session yet", vim.log.levels.WARN)
  end

  vim.ui.select(modes, {
    prompt = "Kiro: select mode",
    format_item = function(m)
      local marker = (m.id == catalog.modes.currentModeId) and "* " or "  "
      return marker .. m.name .. (m.description and (" — " .. m.description) or "")
    end,
  }, function(choice)
    if not choice then
      return
    end

    local ok, result = pcall(chat.acp_connection.send_rpc_request, chat.acp_connection, "session/set_mode", {
      sessionId = chat.acp_connection.session_id,
      modeId = choice.id,
    })

    if ok and result then
      catalog.modes.currentModeId = choice.id
      vim.notify("Kiro mode: " .. choice.name, vim.log.levels.INFO)
    else
      vim.notify("Failed to set Kiro mode" .. (ok and "" or (": " .. tostring(result))), vim.log.levels.ERROR)
    end
  end)
end

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
    { "<leader>am", "<cmd>CodeCompanion /commit<CR>", mode = "n", desc = "AI: Commit message" },

    -- Kiro-specific: model/mode switching (CodeCompanion's generic `ga`
    -- picker can't do this for kiro — see the note at the top of this file)
    { "<leader>km", kiro_select_model, mode = "n", desc = "Kiro: select model" },
    { "<leader>kM", kiro_select_mode, mode = "n", desc = "Kiro: select mode" }
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
        ensure_kiro_rpc_patch()

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
