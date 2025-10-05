#!/bin/bash

# A script to create a portable, self-contained backup of a Neovim setup.
# The backup is structured to work seamlessly with XDG_CONFIG_HOME and XDG_DATA_HOME.

# Define the base backup directory with a random suffix for uniqueness
RANDOM_SUFFIX=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
BACKUP_DIR="nvim-portable-${RANDOM_SUFFIX}"

# Create the new, self-contained directory structure
mkdir -p "$BACKUP_DIR/config"
mkdir -p "$BACKUP_DIR/share" 

echo "Creating a complete backup of your Neovim setup..."
echo "Backup directory: $BACKUP_DIR"

# Backup source directories with proper error handling
backup_directory() {
    local src="$1"
    local dest="$2"
    local desc="$3"
    local exclude="$4"
    
    if [[ -d "$src" ]]; then
        echo "Backing up $desc ($src)..."
        if [[ -n "$exclude" ]]; then
            echo "  Excluding: $exclude"
            # Use rsync to exclude specific directories
            rsync -rL --exclude="$exclude" "$src/" "$dest/" || {
                echo "Warning: Failed to backup $desc from $src"
                return 1
            }
        else
            # The -rL flag copies recursively, following symlinks if they exist
            cp -rL "$src" "$dest" || {
                echo "Warning: Failed to backup $desc from $src"
                return 1
            }
        fi
    else
        echo "Warning: $desc not found at $src - skipping"
        return 1
    fi
}

# Copy the Neovim config and plugin data directories
backup_directory "$HOME/src/dotfiles/nvim.work" "$BACKUP_DIR/config/nvim" "dotfiles nvim.work config"
backup_directory "$HOME/.config/local/nvim" "$BACKUP_DIR/config/nvim-local" "local nvim config"
backup_directory "$HOME/.local/share/nvim" "$BACKUP_DIR/share/nvim" "nvim share data" "mason"
backup_directory "$HOME/.local/share/nvim-tools" "$BACKUP_DIR" "nvim-tools"

# Create a README with instructions for running the portable instance
README_CONTENT="### Portable Neovim Instance

To run this portable Neovim setup, first navigate to this directory.

Then, you can export the following environment variables before launching Neovim:

\`\`\`bash
export XDG_CONFIG_HOME=\"\$PWD/config\"
export XDG_DATA_HOME=\"\$PWD/share\"
export PATH=\"\$HOME:\$(pwd)/nvim-tools/bin:\$PATH\"
nvim
\`\`\`

This will tell Neovim to use the configuration and data from this portable directory,
leaving your primary setup untouched. The PATH export ensures that nvim-tools are available.

### Directory Structure

- \`config/nvim/\` - Main nvim configuration from ~/src/dotfiles/nvim.work
- \`config/nvim-local/\` - Local nvim configuration from ~/.config/local/nvim
- \`share/nvim/\` - Nvim data directory from ~/.local/share/nvim (excluding mason)
- \`nvim-tools/\` - Development tools from ~/.local/share/nvim-tools

### Notes

If you have a local config that should override the main config, you may need to 
source it manually from within nvim or set up your init.lua to load both configs.

"

echo "$README_CONTENT" > "$BACKUP_DIR/README.md"

echo ""
echo "Backup complete!"
echo "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "You can now run 'cd $BACKUP_DIR' to see the backup and the new README.md."
