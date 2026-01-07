-- ~/.config/wezterm/modules/platform_specific.lua
local wezterm = require("wezterm")
local nodes_config = require("modules.nodes_config")

local M = {}

function M.apply(config)
  local user_name = os.getenv("USERNAME") or os.getenv("USER") or os.getenv("LOGNAME")
  local dom = os.getenv("USERDOMAIN")
  local WORK_DOMAIN_NAME = "MIAMIHOLDINGS"

  -- Initialize launch_menu as an empty table if it's not already defined.
  -- This ensures we can safely insert items.
  config.launch_menu = config.launch_menu or {}
  local launch_menu = config.launch_menu

  -- Determine the OS and domain for configuration
  if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    -- Windows-specific configurations
    if dom and string.upper(dom) == WORK_DOMAIN_NAME then
      -- Windows Work Environment
      config.background = {
        {
          source = {
            File = "C:/DevSoftware/WezTerm/images/miax-background.png",
          },
          opacity = 0.2,
        },
      }

      config.default_prog = { "cmd.exe" }
      table.insert(launch_menu, { label = "cmd", args = { "cmd.exe" } })
      table.insert(launch_menu, { label = "cmd", args = { "cmd.exe" } })
      table.insert(launch_menu, { label = "--- Prod GW ---" })
      table.insert(launch_menu, { label = "c2-msys", args = { msys_ssh, user_name .. "@dch4i1gws02" } })
      table.insert(launch_menu, { label = "c1-msys", args = { msys_ssh, user_name .. "@dch4i1gws01" } })
      table.insert(launch_menu, { label = "n1-msys", args = { msys_ssh, user_name .. "@dny2i1gws01" } })
      table.insert(launch_menu, { label = "n2-msys", args = { msys_ssh, user_name .. "@dny2i1gws02" } })
      -- table.insert(launch_menu, { label = "c2-win", args = { win_ssh, user_name .. "@dch4i1gws02" } })
      -- table.insert(launch_menu, { label = "c1-win", args = { win_ssh, user_name .. "@dch4i1gws01" } })
      -- table.insert(launch_menu, { label = "n1-win", args = { win_ssh, user_name .. "@dny2i1gws01" } })
      -- table.insert(launch_menu, { label = "n2-win", args = { win_ssh, user_name .. "@dny2i1gws02" } })

      -- Add nodes from central config (replaces all the hardcoded node entries)
      -- local node_entries = nodes_config.get_launch_menu_entries()
      -- for _, entry in ipairs(node_entries) do
      --   table.insert(launch_menu, entry)
      -- end


      -- Utils section
      table.insert(launch_menu, { label = "--- Utils ---" })
      table.insert(launch_menu, {
        label = "ucrt64",
        args = {
          "cmd.exe ",
          "/k",
          "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
        },
      })
      table.insert(launch_menu, {
        label = "msys2",
        args = {
          "cmd.exe ",
          "/k",
          "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash",
        },
      })
      table.insert(launch_menu, { label = "---" })
    else
      -- Windows Home Environment
      config.default_prog = {
        "cmd.exe",
        "/k",
        "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
      }
      -- config.default_prog = { "cmd.exe" }
      table.insert(launch_menu, { label = "cmd", args = { "cmd.exe" } })

      -- Add nodes from central config (replaces all the hardcoded node entries)
      local node_entries = nodes_config.get_launch_menu_entries()
      for _, entry in ipairs(node_entries) do
        table.insert(launch_menu, entry)
      end

      -- Utils section
      table.insert(launch_menu, { label = "--- Utils ---" })
      table.insert(launch_menu, {
        label = "msys",
        args = {
          "cmd.exe ",
          "/k",
          "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys2 -shell bash",
        },
      })
      table.insert(launch_menu, {
        label = "ucrt64",
        args = {
          "cmd.exe ",
          "/k",
          "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
        },
      })
    end
  elseif wezterm.target_triple == "aarch64-apple-darwin" or wezterm.target_triple == "x86_64-apple-darwin" then
    -- macOS Specific Configurations
    config.font = wezterm.font("JetBrains Mono")

    table.insert(launch_menu, {
      label = "local shell",
    })

    -- Add nodes from central config (replaces all the hardcoded node entries)
    local node_entries = nodes_config.get_launch_menu_entries()
    for _, entry in ipairs(node_entries) do
      table.insert(launch_menu, entry)
    end

    table.insert(launch_menu, { label = "---" })
  end
end

return M
