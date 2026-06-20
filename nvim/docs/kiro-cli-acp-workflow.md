# Using Kiro via ACP in This Config

Your personal workflow guide. Refers to your actual keymaps, adapters, and setup.

---

## Your Adapters at a Glance

| Keymap        | Adapter       | Type | Use for                                |
|---------------|---------------|------|----------------------------------------|
| `<leader>ak`  | kiro          | ACP  | Agentic coding — reads/writes files, stateful |
| `<leader>ac`  | claude_code   | ACP  | Same but via Claude Code CLI           |
| `<leader>ag`  | groq          | HTTP | Fast Q&A, cheap/free, stateless        |
| `<leader>ao`  | openrouter    | HTTP | Multi-model gateway, stateless         |
| `<leader>ai`  | groq (inline) | HTTP | In-place edits, no chat buffer         |
| `<leader>aI`  | openrouter    | HTTP | In-place edits, different model        |

Your **default** strategy (in `setup()`) routes `chat` and `agent` to `claude_code`.
The `<leader>ak` keymap **overrides** that per-buffer by passing `adapter=kiro`.

---

## What Kiro ACP Actually Does Differently

When you press `<leader>ak`, CodeCompanion spawns `kiro-cli acp` as a subprocess.
Unlike `<leader>ag` (Groq), which fires a single HTTP request with your full chat
history every turn:

- **Kiro keeps state** — you only send new messages, it remembers everything
- **Kiro has its own tools** — it can read/write your files and run shell commands
  on its own, without CodeCompanion's `@{agent}` tool group
- **Kiro reads your steering** — `~/.kiro/steering/` (practices, constraints,
  coding-style) is loaded automatically, no need to share context manually
- **Kiro handles auth itself** — no env vars needed (unlike `GROQ_API_KEY`)

---

## Typical Workflow: Agentic Task with Kiro

### 1. Open chat in your project dir

```
<leader>ak
```

The chat buffer opens. Kiro spawns and picks up:
- Your `~/.kiro/steering/` rules (practices.md, constraints.md, coding-style.md)
- The cwd as its working directory

### 2. Give it a task

Just describe what you want. Kiro can see your filesystem:

```
Refactor the mason.lua to also install pyrefly on MSYS2
```

You don't need to `/file` or `#buffer` — Kiro will read files itself using its
tools. But you *can* add context explicitly if you want to focus it.

### 3. Approve or reject tool calls

When Kiro wants to write a file or run a command, you'll see a permission prompt
with a diff preview. Options:
- **Allow** — let it proceed
- **Reject** — deny and optionally explain why

### 4. Iterate

Send follow-up messages naturally. Kiro remembers the whole session:

```
Actually, also add hadolint to the mason ensure_installed list
```

### 5. Done — close or toggle

- `<leader>at` hides the chat (keeps session alive)
- `:q` on the chat buffer terminates the session

---

## Typical Workflow: Quick Question (Not Kiro)

For fast stateless questions where you don't need file tools:

```
<leader>ag
```

Type your question, get an answer. Full history resent each turn. No tools, no
file access, no approval prompts. Just fast.

---

## Sharing Context with Kiro

You usually don't need to — Kiro reads files on its own. But when you want to
focus it on specific code:

| Method                   | How                                          |
|--------------------------|----------------------------------------------|
| Visual selection → chat  | Select code, press `ga`                      |
| Pick a file              | In chat (insert mode): type `/file`          |
| Current buffer           | In chat (insert mode): type `#buffer`        |
| Treesitter outline       | In chat (insert mode): type `/symbols`       |

---

## ACP Slash Commands (Only Work with Kiro/Claude Code)

Type these in the chat buffer in insert mode:

| Command                  | What it does                                          |
|--------------------------|-------------------------------------------------------|
| `/resume`                | Restore a previous Kiro session (must be first thing) |
| `/mode`                  | Switch Kiro's operating mode                          |
| `/acp_session_options`   | Change model or effort mid-session                    |
| `/command`               | Switch CLI flags (destructive — resets session)       |

Kiro can also advertise its own commands — access with `\` prefix (e.g. `\help`).

---

## Resuming a Previous Session

1. Open a fresh chat: `<leader>ak`
2. **Before typing anything**, enter: `/resume`
3. Pick from the session list
4. Continue where you left off

---

## Prompt Library Shortcuts (These Use Groq, Not Kiro)

These are your visual-mode shortcuts. They use the **inline** adapter (Groq) for
speed — they don't go through Kiro:

| Keymap        | What                    | Mode   |
|---------------|-------------------------|--------|
| `<leader>ae`  | Explain selected code   | Visual |
| `<leader>af`  | Fix selected code       | Visual |
| `<leader>aT`  | Generate tests          | Visual |
| `<leader>am`  | Generate commit message | Normal |

---

## When to Use Which

| I want to...                          | Press          |
|---------------------------------------|----------------|
| Have Kiro refactor/build across files | `<leader>ak`   |
| Quick explain/fix of selected code    | `<leader>ae/af` |
| Ask a fast question, no tools needed  | `<leader>ag`   |
| Inline edit without opening chat      | `<leader>ai`   |
| Use Claude Code instead of Kiro       | `<leader>ac`   |
| Generate a commit message             | `<leader>am`   |
| Add code to an open chat              | `ga` (visual)  |
| Open the action palette               | `<C-a>`        |
| Toggle the chat buffer                | `<leader>at`   |

---

## Gotchas Specific to Your Config

1. **Default strategy is `claude_code`, not `kiro`** — your `setup()` sets
   `chat = { adapter = "claude_code" }`. The `<leader>ak` keymap overrides this
   per-buffer. If you open a chat without specifying an adapter (e.g. from the
   action palette), it uses Claude Code.

2. **Kiro is NOT in your `adapters` table** — it's a built-in preset. It works
   without being declared. Your `adapters = { groq = ..., openrouter = ... }`
   only declares the HTTP adapters.

3. **Log level is DEBUG** — `opts.log_level = "DEBUG"` means verbose logs.
   Check with `:CodeCompanionLog` if something seems wrong.

4. **Inline uses Groq** — `strategies.inline = { adapter = my_groq }` means
   `<leader>ai` and prompt library commands go through Groq, not Kiro.

5. **Offline mode** — Kiro needs network. If you're in airgapped mode (no
   `.online` file), CodeCompanion loads but Kiro ACP will fail to connect.

6. **`:cc` abbreviation** — you can type `:cc /explain` or `:cc adapter=kiro`
   instead of the full `:CodeCompanion` command.

---

## Troubleshooting

| Problem                           | Fix                                            |
|-----------------------------------|------------------------------------------------|
| Chat opens, no response           | Run `kiro-cli whoami` — re-login if needed     |
| "kiro-cli: command not found"     | Ensure `~/.local/bin` is in PATH, reopen nvim  |
| Timeout / slow first response     | First ACP connection takes a few seconds       |
| Permission prompt won't go away   | Press a choice key (allow/reject)              |
| Want to skip all approvals        | Extend the kiro adapter with `--trust-all-tools` |
| Session feels stale               | Close chat (`:q`), open fresh (`<leader>ak`)   |

---

## Optional: Customize Kiro's CLI Flags

If you want to tweak Kiro's behavior (effort, trust), add this to your setup:

```lua
adapters = {
  acp = {
    kiro = function()
      return require("codecompanion.adapters").extend("kiro", {
        commands = {
          default = {
            "kiro-cli",
            "acp",
            "--effort", "high",
            "--trust-all-tools",
          },
        },
      })
    end,
  },
  groq = my_groq,
  openrouter = my_openrouter,
},
```

This goes in the `require("codecompanion").setup({...})` call alongside your
existing `groq` and `openrouter` adapter declarations.
