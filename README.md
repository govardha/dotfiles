# WezTerm Configuration

A simple, modular WezTerm setup that keeps things organized by splitting configuration into separate files.

## What This Does

Instead of having one giant configuration file, this setup breaks everything into smaller, focused modules. Each module handles one specific thing (like colors, keybindings, etc.).

## How It Works

### Main File (`wezterm.lua`)
This is your main config file. It loads all the modules and applies them to your terminal.

### Safe Loading
The `safe_require` function is like a safety net - if a module is missing or broken, your terminal will still work. It just skips the broken part and logs what went wrong.

```lua
-- If this module doesn't exist or has errors, no problem!
local appearance = safe_require("modules.appearance")
```

## Your Modules

Each module lives in the `modules/` folder and does one job:

- **`appearance.lua`** - Colors, fonts, themes
- **`keybindings.lua`** - Keyboard shortcuts  
- **`mouse.lua`** - Mouse settings
- **`format.lua`** - How tabs and windows look
- **`ssh_utils.lua`** - SSH connection stuff
- **`misc.lua`** - Random other settings
- **`platform_specific.lua`** - Mac/Windows/Linux specific tweaks
- **`startup.lua`** - What happens when you open the terminal

## File Structure

```
your-config/
├── wezterm.lua           # Main file
└── modules/              # All your modules
    ├── appearance.lua    
    ├── keybindings.lua   
    ├── mouse.lua         
    └── ...               
```

## How to Use This

1. Put `wezterm.lua` in your WezTerm config folder
2. Create a `modules/` folder next to it
3. Add module files as needed
4. Each module just needs an `apply` function:

```lua
-- Example module
local M = {}

function M.apply(config)
    config.font_size = 14
    -- other settings...
end

return M
```

## Why This is Better

- **Easy to find stuff** - Want to change colors? Look in `appearance.lua`
- **No breaking everything** - If one module breaks, the rest still work
- **Easy to share** - Can share just your keybindings module with others
- **Clean and simple** - No more giant config files

## Adding New Stuff

Want to add something new? Just:
1. Make a new file in `modules/`
2. Add it to the main config file
3. Done!