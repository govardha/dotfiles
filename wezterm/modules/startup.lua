local wezterm = require("wezterm")
local mux = wezterm.mux

local M = {}

local WORK_DOMAIN_NAME = "MIAMIHOLDINGS"

local function detect_environment()
  local dom = os.getenv("USERDOMAIN")
  local env_info = { is_work_windows = false, is_home_windows = false, is_home_osx = false, is_home_linux = false }

  if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    if dom and string.upper(dom) == WORK_DOMAIN_NAME then
      env_info.is_work_windows = true
      wezterm.log_info("Detected: Work Windows environment")
    else
      env_info.is_home_windows = true
      wezterm.log_info("Detected: Home Windows environment")
    end
  elseif wezterm.target_triple:match("apple") then
    env_info.is_home_osx = true
    wezterm.log_info("Detected: Home macOS environment")
  elseif wezterm.target_triple:match("linux") then
    env_info.is_home_linux = true
    wezterm.log_info("Detected: Home Linux environment")
  end

  return env_info
end

-- Returns true only when WezTerm is launched normally (double-click / shortcut),
-- not when invoked as: wezterm ssh, wezterm connect, wezterm cli, etc.
local function is_normal_startup()
  -- wezterm.executable_path points to the binary that was invoked.
  -- When used as an SSH client the argv[0] subcommand is "ssh" / "connect" etc.
  -- The cleanest check available in lua is looking at the mux domain count:
  -- on a fresh GUI start there are no existing windows yet.
  local gui_wins = wezterm.gui and wezterm.gui.gui_windows and wezterm.gui.gui_windows() or {}
  if #gui_wins > 0 then
    return false -- already running, this is a new window attach
  end

  -- Check WEZTERM_PANE — if set, we're running inside an existing wezterm session
  if os.getenv("WEZTERM_PANE") then
    return false
  end

  -- Check common SSH/subcommand env markers
  if os.getenv("WEZTERM_UNIX_SOCKET") then
    return false
  end

  return true
end

function M.setup_workspaces(env_info)
  local is_work_windows = env_info.is_work_windows
  local is_home_windows = env_info.is_home_windows
  local is_home_osx = env_info.is_home_osx
  local is_home_linux = env_info.is_home_linux

  local bash_args = {
    "cmd.exe", "/k", "C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash"
  }

  if is_work_windows then
    wezterm.log_info("Setting up workspaces for work Windows environment")

    local _, _, prod_window = mux.spawn_window({ workspace = "prod", args = bash_args })
    prod_window:spawn_tab({ args = bash_args })
    prod_window:spawn_tab({ args = bash_args })
    mux.set_active_workspace("prod")
    prod_window:gui_window():set_position(200, 100)
  elseif is_home_windows then
    wezterm.log_info("Setting up workspaces for home Windows environment")

    local _, _, vpn_window = mux.spawn_window({ workspace = "vpns", args = bash_args })
    vpn_window:spawn_tab({ args = bash_args })
    vpn_window:spawn_tab({ args = bash_args })

    local _, _, depot_window = mux.spawn_window({ workspace = "depot", args = bash_args })
    depot_window:spawn_tab({ args = bash_args })

    mux.set_active_workspace("vpns")
    vpn_window:gui_window():set_position(200, 100)
  elseif is_home_osx then
    wezterm.log_info("Setting up workspaces for home macOS environment")

    local _, _, vpn_window = mux.spawn_window({ workspace = "vpns" })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn" } })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn2" } })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn3" } })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn4" } })

    local _, _, depot_window = mux.spawn_window({ workspace = "depot" })
    depot_window:spawn_tab({ args = { "ssh", "ubuntu@rinku-depot" } })
    depot_window:spawn_tab({ args = { "ssh", "ubuntu@rinku-depot2" } })

    mux.set_active_workspace("depot")
  elseif is_home_linux then
    wezterm.log_info("Setting up workspaces for home Linux environment")

    local _, _, vpn_window = mux.spawn_window({ workspace = "vpns" })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn" } })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn2" } })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn3" } })
    vpn_window:spawn_tab({ args = { "ssh", "ubuntu@vpn4" } })

    local _, _, depot_window = mux.spawn_window({ workspace = "depot" })
    depot_window:spawn_tab({ args = { "ssh", "ubuntu@rinku-depot" } })
    depot_window:spawn_tab({ args = { "ssh", "ubuntu@rinku-depot2" } })

    mux.set_active_workspace("depot")
  else
    wezterm.log_info("Unknown environment - skipping workspace setup")
  end
end

function M.apply(config)
  wezterm.on("gui-startup", function (cmd)
    -- cmd is non-nil when wezterm was invoked with a subcommand (ssh, connect, etc.)
    -- In that case, skip workspace setup entirely.
    if cmd then
      wezterm.log_info("gui-startup: invoked with subcommand, skipping workspace setup")
      return
    end

    if not is_normal_startup() then
      wezterm.log_info("gui-startup: not a normal startup, skipping workspace setup")
      return
    end

    local env_info = detect_environment()
    M.setup_workspaces(env_info)
  end)
end

return M
