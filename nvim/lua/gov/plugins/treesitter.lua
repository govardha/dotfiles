return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    local ts = require("nvim-treesitter")

    -- Setup (minimal config for main branch)
    ts.setup({
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })

    -- Custom parsers
    local parsers = require("nvim-treesitter.parsers")
    parsers.d2 = {
      install_info = {
        url = "https://github.com/ravsii/tree-sitter-d2",
        files = { "src/parser.c" },
        branch = "main",
      },
      filetype = "d2",
    }
    parsers.jinja2 = {
      install_info = {
        url = "https://github.com/cathaysia/tree-sitter-jinja",
        files = { "src/parser.c" },
        branch = "v0.10.0",
      },
      filetype = "jinja2",
    }

    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
    })

    -- One-time manual install command (run :TSInstallAll when setting up a new machine)
    local offline_guard = require("gov.core.offline-guard")
    vim.api.nvim_create_user_command("TSInstallAll", function()
      if not offline_guard.is_online() then
        vim.notify("Offline: cannot install parsers", vim.log.levels.ERROR)
        return
      end
      ts.install({
        "bash", "c", "css", "dockerfile", "gitignore", "graphql",
        "html", "javascript", "json", "lua", "markdown", "markdown_inline",
        "perl", "python", "query", "tsx", "typescript", "vim", "vimdoc",
        "yaml", "xml",
      })
      vim.notify("TSInstallAll: parser installation started", vim.log.levels.INFO)
    end, { desc = "Install all treesitter parsers (requires NVIM_ONLINE=true)" })
  end,
}
