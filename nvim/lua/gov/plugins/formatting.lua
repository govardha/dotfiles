return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        -- Python (ruff handles both formatting and import sorting)
        python = { "ruff_organize_imports", "ruff_format" },
        
        -- Shell/Bash
        sh = { "shfmt" },
        bash = { "shfmt" },
        
        -- Ansible/YAML
        yaml = { "prettier" },
        
        -- Config files
        json = { "prettier" },
        jsonc = { "prettier" },
        
        -- Lua
        lua = { "stylua" },
        
        -- Markdown
        markdown = { "prettier" },
      },
      
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 3000,
      },
      
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
