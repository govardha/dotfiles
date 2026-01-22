return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  lazy = false,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  init = function()
    -- Disable default keymaps (we'll set our own)
    vim.g.no_plugin_maps = true
  end,
  config = function()
    -- Setup textobjects config
    require("nvim-treesitter-textobjects").setup({
      select = {
        lookahead = true,
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V',  -- linewise
          ['@class.outer'] = '<c-v>', -- blockwise
        },
        include_surrounding_whitespace = false,
      },
      move = {
        enable = true,
        set_jumps = true,
      },
      swap = {
        enable = true,
      },
    })

    -- Get the modules
    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")
    local swap = require("nvim-treesitter-textobjects.swap")
    local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

    -- SELECT keymaps (your dam, vim, etc.)
    vim.keymap.set({ "x", "o" }, "a=", function()
      select.select_textobject("@assignment.outer", "textobjects")
    end, { desc = "Select outer assignment" })
    vim.keymap.set({ "x", "o" }, "i=", function()
      select.select_textobject("@assignment.inner", "textobjects")
    end, { desc = "Select inner assignment" })

    vim.keymap.set({ "x", "o" }, "aa", function()
      select.select_textobject("@parameter.outer", "textobjects")
    end, { desc = "Select outer parameter" })
    vim.keymap.set({ "x", "o" }, "ia", function()
      select.select_textobject("@parameter.inner", "textobjects")
    end, { desc = "Select inner parameter" })

    vim.keymap.set({ "x", "o" }, "ai", function()
      select.select_textobject("@conditional.outer", "textobjects")
    end, { desc = "Select outer conditional" })
    vim.keymap.set({ "x", "o" }, "ii", function()
      select.select_textobject("@conditional.inner", "textobjects")
    end, { desc = "Select inner conditional" })

    vim.keymap.set({ "x", "o" }, "al", function()
      select.select_textobject("@loop.outer", "textobjects")
    end, { desc = "Select outer loop" })
    vim.keymap.set({ "x", "o" }, "il", function()
      select.select_textobject("@loop.inner", "textobjects")
    end, { desc = "Select inner loop" })

    vim.keymap.set({ "x", "o" }, "af", function()
      select.select_textobject("@call.outer", "textobjects")
    end, { desc = "Select outer function call" })
    vim.keymap.set({ "x", "o" }, "if", function()
      select.select_textobject("@call.inner", "textobjects")
    end, { desc = "Select inner function call" })

    -- CRITICAL: Function/method textobjects (your dam/vim)
    vim.keymap.set({ "x", "o" }, "am", function()
      select.select_textobject("@function.outer", "textobjects")
    end, { desc = "Select outer function" })
    vim.keymap.set({ "x", "o" }, "im", function()
      select.select_textobject("@function.inner", "textobjects")
    end, { desc = "Select inner function" })

    vim.keymap.set({ "x", "o" }, "ac", function()
      select.select_textobject("@class.outer", "textobjects")
    end, { desc = "Select outer class" })
    vim.keymap.set({ "x", "o" }, "ic", function()
      select.select_textobject("@class.inner", "textobjects")
    end, { desc = "Select inner class" })

    -- MOVE keymaps (]m, [m, etc.)
    vim.keymap.set({ "n", "x", "o" }, "]m", function()
      move.goto_next("@function.outer", "textobjects")
    end, { desc = "Next function start" })
    vim.keymap.set({ "n", "x", "o" }, "[m", function()
      move.goto_previous("@function.outer", "textobjects")
    end, { desc = "Prev function start" })

    vim.keymap.set({ "n", "x", "o" }, "]M", function()
      move.goto_next("@function.outer", "textobjects", { goto_end = true })
    end, { desc = "Next function end" })
    vim.keymap.set({ "n", "x", "o" }, "[M", function()
      move.goto_previous("@function.outer", "textobjects", { goto_end = true })
    end, { desc = "Prev function end" })

    vim.keymap.set({ "n", "x", "o" }, "]c", function()
      move.goto_next("@class.outer", "textobjects")
    end, { desc = "Next class start" })
    vim.keymap.set({ "n", "x", "o" }, "[c", function()
      move.goto_previous("@class.outer", "textobjects")
    end, { desc = "Prev class start" })

    vim.keymap.set({ "n", "x", "o" }, "]i", function()
      move.goto_next("@conditional.outer", "textobjects")
    end, { desc = "Next conditional" })
    vim.keymap.set({ "n", "x", "o" }, "[i", function()
      move.goto_previous("@conditional.outer", "textobjects")
    end, { desc = "Prev conditional" })

    vim.keymap.set({ "n", "x", "o" }, "]l", function()
      move.goto_next("@loop.outer", "textobjects")
    end, { desc = "Next loop" })
    vim.keymap.set({ "n", "x", "o" }, "[l", function()
      move.goto_previous("@loop.outer", "textobjects")
    end, { desc = "Prev loop" })

    -- SWAP keymaps
    vim.keymap.set("n", "<leader>na", function()
      swap.swap_next("@parameter.inner", "textobjects")
    end, { desc = "Swap with next parameter" })
    vim.keymap.set("n", "<leader>pa", function()
      swap.swap_previous("@parameter.inner", "textobjects")
    end, { desc = "Swap with prev parameter" })

    vim.keymap.set("n", "<leader>nm", function()
      swap.swap_next("@function.outer", "textobjects")
    end, { desc = "Swap with next function" })
    vim.keymap.set("n", "<leader>pm", function()
      swap.swap_previous("@function.outer", "textobjects")
    end, { desc = "Swap with prev function" })

    -- REPEATABLE MOVES (; and ,)
    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
    vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
  end,
}
