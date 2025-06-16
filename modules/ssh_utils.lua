-- modules/ssh_path_config.lua
local wezterm = require('wezterm')

local M = {}

function M.apply(config)
  -- Ensure ssh_domains is initialized, for example, if you're using default_ssh_domains
  if not config.ssh_domains then
    config.ssh_domains = wezterm.default_ssh_domains()
  end

  for i, domain in ipairs(config.ssh_domains) do
    if domain.name then
      if domain.name:match("^SSHMUX:vpn.*") or domain.name:match("^SSHMUX:.*-depot$") then
        wezterm.log_info("Setting remote_wezterm_path for: " .. domain.name .. " to /home/ubuntu/bin/wezterm")
        domain.remote_wezterm_path = "/home/ubuntu/bin/wezterm"
      elseif domain.name:match("^SSHMUX:what.*") then
        wezterm.log_info("Setting remote_wezterm_path for: " .. domain.name .. " to /home/gundan/bin/wezterm")
        domain.remote_wezterm_path = "/home/gundan/bin/wezterm"
      end
    end
  end
end

return M