| Key     | Mode          | Action                                      |
| ------- | ------------- | ------------------------------------------- |
| `<CR>`  | Normal        | Send message                                |
| `<C-s>` | Insert        | Send message                                |
| `ga`    | Visual        | Add selection to current chat               |
| `<C-a>` | Any           | Open action palette                         |
| `#`     | Insert (chat) | Insert editor context (buffers, files, etc) |
| `/`     | Insert (chat) | Slash commands (files, symbols, etc)        |
| `@`     | Insert (chat) | Tools (grep, shell, file write, etc)        |

---

## Prompt Library Quick Reference

| Keymap       | Alias      | What it does            | Mode   |
| ------------ | ---------- | ----------------------- | ------ |
| `<leader>ae` | `/explain` | Explain selected code   | Visual |
| `<leader>af` | `/fix`     | Fix selected code       | Visual |
| `<leader>aT` | `/tests`   | Generate unit tests     | Visual |
| `<leader>am` | `/commit`  | Generate commit message | Normal |
| —            | `/lsp`     | Explain LSP diagnostics | Visual |

> Tip: type `cc` in the command line as shorthand for `CodeCompanion`.  
> e.g. `:cc /explain` or `:cc fix the null check in this function`
