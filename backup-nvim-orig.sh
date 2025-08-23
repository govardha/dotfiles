#!/bin/bash

# A script to create a portable, self-contained backup of a Neovim setup.
# The backup is structured to work seamlessly with XDG_CONFIG_HOME and XDG_DATA_HOME.

# Define the base backup directory with a random suffix for uniqueness
RANDOM_SUFFIX=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
BACKUP_DIR="nvim-portable-${RANDOM_SUFFIX}"

# Create the new, self-contained directory structure
mkdir -p "$BACKUP_DIR/config/nvim"
mkdir -p "$BACKUP_DIR/share/nvim"

echo "Creating a complete backup of your Neovim setup..."
echo "Backup directory: $BACKUP_DIR"

# Copy the Neovim config and plugin data directories
echo "Backing up config (~/.config/nvim)..."
echo "Backing up plugins and data (~/.local/share/nvim)..."

# The -rL flag copies recursively, following symlinks if they exist
cp -rL ~/.config/nvim "$BACKUP_DIR/config/"
cp -rL ~/.local/share/nvim "$BACKUP_DIR/share/"

# Create a README with instructions for running the portable instance
README_CONTENT="### Portable Neovim Instance

To run this portable Neovim setup, first navigate to this directory.

Then, you can export the following environment variables before launching Neovim:

\`\`\`bash
export XDG_CONFIG_HOME=\"\$PWD/config\"
export XDG_DATA_HOME=\"\$PWD/share\"
nvim
\`\`\`

This will tell Neovim to use the configuration and data from this portable directory,
leaving your primary setup untouched.

"

echo "$README_CONTENT" > "$BACKUP_DIR/README.md"

echo ""
echo "Backup complete!"
echo "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "You can now run 'cd $BACKUP_DIR' to see the backup and the new README.md."

