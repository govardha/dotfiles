# Navigation Cheatsheet — Buffers, Windows, Tabs

Build muscle memory for moving around in this config. Leader = `Space`.

## Buffers

| Key | Action |
|-----|--------|
| `:e <file>` | Open file in current buffer |
| `:bd` | Close (delete) current buffer |
| `:bn` / `:bp` | Next / previous buffer |
| `:ls` | List open buffers |
| `:b <name>` | Switch to buffer by partial name |
| `:b#` | Toggle between last two buffers |
| `<C-^>` | Alternate file (same as `:b#`) |

## Windows (Splits)

### Creating

| Key | Action |
|-----|--------|
| `<leader>sv` | Split vertically |
| `<leader>sh` | Split horizontally |
| `<leader>se` | Equalize split sizes |
| `<leader>sx` | Close current split |
| `<leader>sm` | Maximize/minimize current split |

### Moving Between

| Key | Action |
|-----|--------|
| `<C-h>` | Move to left window (vim-tmux-navigator) |
| `<C-j>` | Move to below window |
| `<C-k>` | Move to above window |
| `<C-l>` | Move to right window |

### Resizing

| Key | Action |
|-----|--------|
| `<C-w>>` / `<C-w><` | Wider / narrower |
| `<C-w>+` / `<C-w>-` | Taller / shorter |
| `<C-w>=` | Reset all to equal |

## Tabs

| Key | Action |
|-----|--------|
| `<leader>to` | New tab |
| `<leader>tx` | Close tab |
| `<leader>tn` | Next tab |
| `<leader>tp` | Previous tab |
| `<leader>tf` | Open current buffer in new tab |

## File Explorers

| Key | Action |
|-----|--------|
| `<leader>ee` | Toggle NvimTree |
| `<leader>ef` | NvimTree reveal current file |
| `<leader>ec` | Collapse NvimTree |
| `-` | Oil: open parent directory |
| `<Space>-` | Oil: floating parent directory |

## Telescope (Finding & Opening)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fr` | Recent files |
| `<leader>fs` | Live grep |
| `<leader>fc` | Grep word under cursor |

## Sessions

| Key | Action |
|-----|--------|
| `<leader>ws` | Save session |
| `<leader>wr` | Restore session |

## Quick Combos to Practice

```
# Open a file in a vertical split
<leader>sv  then  <leader>ff  (pick file)

# Compare two files side by side
<leader>sv  →  <leader>ff (file A)  →  <C-l>  →  <leader>ff (file B)

# Maximize a split to focus, then restore
<leader>sm  (work)  <leader>sm

# Close everything except current window
<C-w>o

# Jump back to file explorer showing current file
<leader>ef
```
