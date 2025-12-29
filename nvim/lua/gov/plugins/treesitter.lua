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
    local treesitter = require("nvim-treesitter")

    -- Custom parser registration - NEW API using autocmd
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers').d2 = {
          install_info = {
            url = "https://github.com/ravsii/tree-sitter-d2",
            files = { "src/parser.c" },
            branch = "main",
          },
          filetype = "d2",
        }
      end
    })

    -- Minimal setup (only parser installation directory customization)
    treesitter.setup({
      install_dir = vim.fn.stdpath('data') .. '/site',
    })

    -- Install parsers explicitly
    treesitter.install({
      "json", "javascript", "typescript", "tsx",
      "yaml", "html", "css", "python", "perl",
      "markdown", "markdown_inline", "graphql",
      "bash", "lua", "vim", "dockerfile",
      "gitignore", "query", "vimdoc", "c", "d2",
    }, { summary = false })

    -- Enable syntax highlighting via Neovim's native API
    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local lang = vim.bo[buf].filetype
        pcall(vim.treesitter.start, buf, lang)
      end,
    })

    -- Enable indentation (optional)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    -- Incremental selection (still works via setup)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      callback = function()
        local opts = { buffer = true, silent = true }

        vim.keymap.set({ 'n', 'x' }, '<C-space>', function()
          require('nvim-treesitter.incremental_selection').init_selection()
        end, vim.tbl_extend('force', opts, { desc = 'Init selection' }))

        vim.keymap.set('x', '<C-space>', function()
          require('nvim-treesitter.incremental_selection').node_incremental()
        end, vim.tbl_extend('force', opts, { desc = 'Increment selection' }))

        vim.keymap.set('x', '<bs>', function()
          require('nvim-treesitter.incremental_selection').node_decremental()
        end, vim.tbl_extend('force', opts, { desc = 'Decrement selection' }))
      end,
    })
  end,
}
