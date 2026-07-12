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

    -- ── CodeCompanion adapter/model indicator ───────────────────────
    -- Sourced from `_G.codecompanion_chat_metadata`, a global dict the
    -- plugin itself keeps up to date (keyed by chat bufnr) — see
    -- `:h codecompanion-usage-user-interface` under "Metadata". Only shows
    -- anything while the current buffer IS a codecompanion chat, since
    -- that's the only place "which model is this" is a meaningful question.
    local adapter_colors = {
      Kiro             = colors.green,
      ["Claude Code"]  = colors.violet,
      OpenRouter       = colors.yellow,
    }

    local adapter_icons = {
      Kiro             = "󱙺",
      ["Claude Code"]  = "󰚩",
      OpenRouter       = "󰅩",
    }

    -- Abbreviate for statusline width — full names stay in the metadata/docs
    local adapter_short_names = {
      ["Claude Code"] = "Claude",
    }

    -- "google/gemini-2.5-flash" -> "gemini-2.5-flash"
    local function short_model(model)
      return model and (model:match("([^/]+)$") or model) or nil
    end

    -- Hard cap so this component can never blow out the statusline width,
    -- regardless of window size or how verbose an adapter's model id is.
    -- Uses strchars/strcharpart (Unicode-codepoint-aware), not #str/str:sub
    -- (byte-based) — the nerd font icon prefix is multi-byte, and byte
    -- slicing could otherwise chop it (or any future multi-byte text) mid-character.
    local MAX_LEN = 24
    local function truncate(str)
      if vim.fn.strchars(str) <= MAX_LEN then
        return str
      end
      return vim.fn.strcharpart(str, 0, MAX_LEN - 1) .. "…"
    end

    local function codecompanion_metadata()
      if vim.bo.filetype ~= "codecompanion" then
        return nil
      end
      return _G.codecompanion_chat_metadata and _G.codecompanion_chat_metadata[vim.api.nvim_get_current_buf()]
    end

    -- Context-window usage as a ratio (0-1), HTTP adapters only. ACP
    -- adapters (kiro/claude_code) have no `schema.model.choices[...].meta`
    -- to resolve a context window from, so this returns nil for them —
    -- Kiro/Claude Code's own CLIs track and surface that themselves.
    -- Reuses the plugin's own resolver (`adapters.shared.context_window`),
    -- the same function `context_management`'s editing/compaction triggers
    -- use internally, so this always matches what the plugin itself sees.
    local function context_usage_ratio()
      local meta = codecompanion_metadata()
      if not meta or not meta.adapter or meta.adapter.type ~= "http" then
        return nil
      end

      local ok_chat, chat = pcall(require("codecompanion.interactions.chat").buf_get_chat, vim.api.nvim_get_current_buf())
      if not ok_chat or not chat or not chat.adapter then
        return nil
      end

      local ok_window, window = pcall(require("codecompanion.adapters.shared").context_window, chat.adapter)
      if not ok_window or not window or window <= 0 then
        return nil
      end

      return (meta.tokens or 0) / window
    end

    local function codecompanion_indicator()
      local meta = codecompanion_metadata()
      if not meta or not meta.adapter then return "" end

      local full_name = meta.adapter.name or "?"
      local name = adapter_short_names[full_name] or full_name
      local icon = adapter_icons[full_name] or "󰚩"

      local ratio = context_usage_ratio()
      local text
      if ratio then
        -- Percentage takes priority over the model name here — it's the
        -- thing worth glancing at mid-conversation; the model rarely changes.
        text = string.format("%s %s · %d%%", icon, name, math.floor(ratio * 100))
      else
        local model = short_model(meta.adapter.model)
        text = model and string.format("%s %s · %s", icon, name, model) or string.format("%s %s", icon, name)
      end

      return truncate(text)
    end

    local function codecompanion_color()
      local meta = codecompanion_metadata()
      if not meta or not meta.adapter then return { fg = colors.fg } end

      -- Match the plugin's own context_management trigger thresholds, so
      -- the color means the same thing the plugin will actually act on
      -- (auto-editing older tool output, then auto-compacting the chat).
      local ratio = context_usage_ratio()
      if ratio then
        local cfg = require("codecompanion.config").interactions.chat.opts.context_management
        local compaction_trigger = (cfg.compaction and cfg.compaction.trigger) or 0.85
        local editing_trigger = (cfg.editing and cfg.editing.trigger) or 0.65
        if ratio >= compaction_trigger then
          return { fg = colors.red }
        elseif ratio >= editing_trigger then
          return { fg = colors.yellow }
        end
      end

      return { fg = adapter_colors[meta.adapter.name] or colors.fg }
    end

    -- The ACP model isn't known until the subprocess connects (1-5s after
    -- the chat opens), and HTTP model/token/cycle counts change per
    -- request — redraw promptly on the plugin's own events rather than
    -- waiting for lualine's normal redraw cadence (cursor move, etc).
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("CodeCompanionLualine", { clear = true }),
      pattern = {
        "CodeCompanionChatAdapter",
        "CodeCompanionChatModel",
        "CodeCompanionChatOpened",
        "CodeCompanionRequestFinished",
      },
      callback = function()
        vim.cmd("redrawstatus")
      end,
    })

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
        -- Default lualine_b is { "branch", "diff", "diagnostics" }; dropping
        -- just "branch" here, keeping the other two.
        lualine_b = { "diff", "diagnostics" },
        lualine_x = {
          {
            codecompanion_indicator,
            color = codecompanion_color,
            -- NOTE: deliberately not `pcall(require, "codecompanion")` here —
            -- codecompanion.nvim lazy-loads on its own keymaps/commands, and
            -- requiring it just to check "is it loaded" would force-load it
            -- on the very first statusline redraw. A plain filetype check
            -- costs nothing and never touches the plugin.
            cond = function()
              return vim.bo.filetype == "codecompanion"
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
