return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim", -- Add this dependency
  },
  config = function()
    -- import mason
    local mason = require("mason")
    
    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")
    
    -- import mason-tool-installer
    local mason_tool_installer = require("mason-tool-installer") 
    
    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })
    
    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "basedpyright",
        "bashls",
        "awk_ls",
        "ansiblels",
        "jsonls",
        "yamlls",
        "docker_compose_language_service",
        "lua_ls",
      }
    })
    
    mason_tool_installer.setup({
      ensure_installed = {
        "shellcheck", -- Shell script linter
        "ruff",       -- Python linter (you're already using this)
        "stylua",     -- Lua formatter
        "black",      -- Python formatter
      },
    })
  end,
}
