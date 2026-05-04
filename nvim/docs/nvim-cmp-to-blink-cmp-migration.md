# Migration: nvim-cmp → blink.cmp

## Why

- Faster async completion (0.5-4ms, Rust fuzzy matcher)
- Typo-resistant fuzzy matching with frecency/proximity bonus
- Built-in snippet, auto-bracket, and signature help support
- Fewer plugins to manage (drops ~6 cmp-related packages)

## Files Changed

### Deleted
- `lua/gov/plugins/nvim-cmp.lua` — replaced entirely by blink-cmp.lua

### Created
- `lua/gov/plugins/blink-cmp.lua` — new completion config using `saghen/blink.cmp` v1

### Modified
- `lua/gov/plugins/lsp/lspconfig.lua`
  - Dependency: `hrsh7th/cmp-nvim-lsp` → `saghen/blink.cmp`
  - Capabilities: `cmp_nvim_lsp.default_capabilities()` → `require('blink.cmp').get_lsp_capabilities()`
- `lua/gov/plugins/autopairs.lua`
  - Removed `hrsh7th/nvim-cmp` dependency
  - Removed cmp confirm_done hook (blink.cmp has built-in auto-brackets)
- `lua/gov/plugins/codecompanion.lua`
  - Removed `hrsh7th/nvim-cmp` from dependencies

## Plugins Removed
- `hrsh7th/nvim-cmp`
- `hrsh7th/cmp-buffer`
- `hrsh7th/cmp-path`
- `hrsh7th/cmp-nvim-lsp`
- `L3MON4D3/LuaSnip`
- `saadparwaiz1/cmp_luasnip`
- `onsails/lspkind.nvim`

## Plugins Added
- `saghen/blink.cmp` (v1.*)

## Plugins Kept
- `rafamadriz/friendly-snippets` (works with blink.cmp natively)

## Keybinding Mapping

| Action              | nvim-cmp (old)  | blink.cmp (new) |
|---------------------|-----------------|------------------|
| Previous item       | `C-k`           | `C-k`            |
| Next item           | `C-j`           | `C-j`            |
| Scroll docs up      | `C-b`           | `C-b`            |
| Scroll docs down    | `C-f`           | `C-f`            |
| Trigger completion  | `C-Space`       | `C-Space`        |
| Abort               | `C-e`           | `C-e`            |
| Confirm             | `CR`            | `CR`             |

## Post-Migration

Run `:Lazy sync` to install blink.cmp and remove old cmp plugins.
