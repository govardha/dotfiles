local wezterm = require('wezterm')

local M = {}

function M.apply(config)
  -- Helper function to get the title for a tab
  local function tab_title(tab_info)
    local title = tab_info.tab_title
    -- if the tab title is explicitly set, take that
    if title and #title > 0 then
      return title
    end
    -- Otherwise, use the title from the active pane
    -- in that tab
    return tab_info.active_pane.title
  end
  
  -- Register the tab title format handler
  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local title = tab_title(tab)
    local hostname = " " .. wezterm.hostname() .. " "
    if tab.is_active then
        return {
            { Background = { Color = "purple" } },
            { Text = wezterm.nerdfonts.cod_terminal .. "  [ " .. tab.tab_index + 1 .. " ] " .. title },
        }
    else
        return {
            { Background = { Color = "black" } },
            { Text = "[" .. tab.tab_index + 1 .. "] " .. title },
        }
    end
end)

  -- Register the right status update handler for date/time display
  wezterm.on("update-right-status", function(window)
    local date = wezterm.strftime("%a %b %-d %Y %H:%M:%S ")
    window:set_right_status(wezterm.format({
      { Text = wezterm.nerdfonts.fa_clock_o .. " " .. date },
    }))
  end)
end

return M