# Kiro CLI Setup

Set up custom agent config and coding style prompts on a new machine.

## Prerequisites

- Kiro CLI installed
- This dotfiles repo cloned to `~/src/dotfiles`

## Steps

1. Create the `~/.kiro` directory if it doesn't exist:

   ```bash
   mkdir -p ~/.kiro
   ```

2. Symlink agents and prompts:

   ```bash
   ln -sf ~/src/dotfiles/kiro/agents ~/.kiro/agents
   ln -sf ~/src/dotfiles/kiro/prompts ~/.kiro/prompts
   ```

3. Update the prompt path in `kiro/agents/default.json` to match your home directory:

   ```bash
   sed -i "s|/home/[^/]*/|/home/$(whoami)/|g" ~/src/dotfiles/kiro/agents/default.json
   ```

## What This Does

- `~/.kiro/agents/default.json` — Overrides the default agent to inject your coding style prompt into every session
- `~/.kiro/prompts/coding-style.md` — Defines formatting rules (ruff, shfmt, prettier) and git workflow (feature branches, atomic commits, no direct push to main)

## File Structure

```
~/.kiro/
├── agents/ → ~/src/dotfiles/kiro/agents/
│   └── default.json
└── prompts/ → ~/src/dotfiles/kiro/prompts/
    └── coding-style.md
```
