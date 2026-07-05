# Understanding Your CodeCompanion Setup

This is a from-scratch explanation of `lua/gov/plugins/codecompanion.lua` —
what every piece of it does, why it's shaped the way it is, and how it
connects to the rest of your Neovim config. It assumes you know Neovim in
general but haven't yet built a mental model of *this* plugin's moving parts.

Everything here is verified against the plugin version actually installed on
this machine (`~/.local/share/nvim/lazy/codecompanion.nvim`,
v19.18.0-4-gc8bd2d0f), not just the README.

---

## 1. The one idea that explains almost everything else

CodeCompanion talks to two fundamentally different *kinds* of backend, and
which kind you're using changes what features are even possible. Get this
part solid and the rest of the config reads itself.

### ACP adapters — `kiro`, `claude_code`

ACP stands for **Agent Client Protocol**. When you use an ACP adapter,
CodeCompanion doesn't call an LLM API directly — it **spawns the CLI tool
itself as a subprocess** (`kiro-cli acp ...` or `claude-agent-acp`) and talks
to it over JSON-RPC. That subprocess *is* the agent: it has its own
conversation loop, its own memory of the session, and — critically — **its
own tools**. When Kiro decides to read a file or run a shell command, it does
that itself, using its own permission system. CodeCompanion's job here is
just to be a nice frontend: it renders the conversation as a buffer, shows
diffs when files change, and forwards your keystrokes to the subprocess.

### HTTP adapters — `openrouter`

An HTTP adapter is what most people picture when they think "AI chat
plugin": CodeCompanion builds a JSON payload of your message history and
`curl`s it straight to an API endpoint (here, OpenRouter's chat completions
endpoint). There's no subprocess, no persistent session on the other end —
every request carries the full conversation so far. If you want the model to
be able to edit files or run commands, **CodeCompanion has to provide that
tool-calling machinery itself**, which it does (`create_file`, `run_command`,
etc. — see §7).

### Why this distinction matters downstream

| | ACP (`kiro`, `claude_code`) | HTTP (`openrouter`) |
|---|---|---|
| Who executes file edits / shell commands | The CLI's own agent loop | CodeCompanion's built-in tools |
| Does `@agent` / `@files` do anything? | No — tool groups are hidden entirely | Yes |
| Auth | Handled by the CLI tool itself (or its own env var) | `OPENROUTER_API_KEY` |
| Statefulness | Stateful subprocess, remembers the whole session | Stateless HTTP call, full history resent every turn |
| Startup cost | A few seconds to spawn + connect the subprocess | Instant |

This single fact — "ACP bypasses CodeCompanion's own tool system" — is the
reason two separate bugs got fixed in this config recently (rules leaking
across adapters, and a phantom `files` tool tag showing up in ACP chats). See
§6 and §7.

---

## 2. The three "interactions": chat, inline, cli

CodeCompanion calls each mode of talking to an LLM an **interaction**. Your
config wires up three of them, each with its own default adapter:

```lua
interactions = {
  chat   = { adapter = "kiro" },        -- persistent conversation buffer
  inline = { adapter = "openrouter" },  -- one-shot edit-in-place, no buffer
  cli    = { agent = "kiro", agents = { kiro = {...}, claude_code = {...} } },
}
```

- **`chat`** opens a dedicated buffer (`filetype = codecompanion`) with a
  running conversation. This is the "ACP chat" experience — Kiro or Claude
  Code's reasoning, tool calls, and diffs all render here.
- **`inline`** has no buffer of its own — you select code, ask for a
  transformation, and CodeCompanion edits the code in place (or opens a
  scratch buffer for something like generated tests). It always goes through
  an HTTP adapter here (`openrouter`), because inline editing is
  CodeCompanion's own feature, not something the ACP subprocess does.
- **`cli`** is completely different from both: it opens a **raw terminal
  buffer** (`filetype = codecompanion_cli`) running the tool's own native
  interface (`kiro-cli chat` or plain `claude`). CodeCompanion isn't parsing
  the conversation at all here — it's just a `:terminal` wrapper with some
  buffer-switching conveniences (`}`/`{` to move between CLI sessions, and
  auto `:checktime` so edited files reload).

**Important distinction people often trip on:** the ACP **chat** for kiro
(`<leader>ak`) and the **cli** terminal for kiro (`<leader>aK`) both ultimately
run `kiro-cli`, but they are not the same thing:

| | `<leader>ak` (ACP chat) | `<leader>aK` (CLI terminal) |
|---|---|---|
| Command spawned | `kiro-cli acp --trust-all-tools` | `kiro-cli chat --trust-all-tools` |
| UI | CodeCompanion's own chat buffer, markdown-rendered, diff previews | Kiro's actual terminal TUI |
| Config that controls it | `adapters.acp.extend.kiro` | `interactions.cli.agents.kiro` |
| Rules (KIRO.md) auto-loaded? | Yes (see §6) | No — Kiro handles its own context in its native TUI |

These two are configured in **completely separate parts of the file** —
`adapters.acp.extend.kiro.commands` vs. `interactions.cli.agents.kiro` — and
changing one has zero effect on the other. If you ever want to tweak Kiro's
flags, you generally need to update both places.

---

## 3. Adapters, in depth

### `kiro` (ACP)

```lua
adapters = {
  acp = {
    extend = {
      kiro = {
        commands = {
          default = { "kiro-cli", "acp", "--trust-all-tools" }
        }
      }
    }
  }
}
```

`kiro` is a **built-in** adapter shipped with the plugin
(`lua/codecompanion/adapters/acp/kiro.lua`) — its stock command is just
`{"kiro-cli", "acp"}`. The `extend` block above doesn't redefine the adapter
from scratch; it deep-merges `--trust-all-tools` onto the existing default
command list, so Kiro auto-approves its own tool calls instead of prompting
you for every file write. Authentication is handled by `kiro-cli` itself
(you log in once via the CLI, separately from Neovim) — the adapter's `auth`
handler in the plugin just always returns success and lets `kiro-cli`
enforce its own login.

### `claude_code` (ACP)

There is **no override for this one at all** — it isn't mentioned anywhere in
`codecompanion.lua`. That's intentional: the built-in default
(`lua/codecompanion/adapters/acp/claude_code.lua`) already spawns
`claude-agent-acp`, and that binary is present on this machine
(`~/.nvm/versions/node/v24.18.0/bin/claude-agent-acp` — a separate ACP bridge
package, *not* the `claude` CLI binary itself, though it uses your existing
`claude` login under the hood). If `CLAUDE_CODE_OAUTH_TOKEN` isn't set (it
isn't, here), the adapter's auth handler returns `false`, but the connection
code then checks whether the agent advertises any of its own auth methods —
since `claude-agent-acp` doesn't require one when you're already logged in
via `claude`, the connection proceeds anyway.

### `openrouter` (HTTP)

```lua
adapters = {
  http = {
    extend = {
      openrouter = {
        schema = { model = { default = "google/gemini-2.5-flash" } }
      }
    }
  }
}
```

Also a built-in adapter (`lua/codecompanion/adapters/http/openrouter.lua`).
The only thing overridden here is the default model — stock default is
`openai/gpt-5.4-mini`; yours is pinned to `google/gemini-2.5-flash`. Needs
`OPENROUTER_API_KEY` in the environment. This adapter is a real "send the
whole conversation as JSON, get a completion back" HTTP client — it supports
reasoning-effort, temperature, and the rest of the usual sampling knobs (all
exposed on-demand via the chat buffer's settings, `gs`/`ga` keymaps — see
§8), and it's the *only* adapter in this config that goes through
CodeCompanion's own tool-calling system (§7).

---

## 4. The CLI terminal agents (a separate, parallel config)

```lua
interactions = {
  cli = {
    agent = "kiro",   -- default agent when you don't specify one
    agents = {
      kiro = {
        cmd = "kiro-cli",
        args = { "chat", "--trust-all-tools" },
        description = "Kiro CLI"
      },
      claude_code = {
        cmd = "claude",
        args = {},
        description = "Claude Code CLI"
      }
    }
  }
}
```

This is a small, self-contained registry: "what command do I run in a
terminal buffer when the user asks for the `kiro` or `claude_code` CLI
agent." Note `claude_code` here runs plain `claude` (the interactive CLI you
already use in a normal terminal), not `claude-agent-acp` — because this path
doesn't speak ACP at all, it's just embedding the tool's native terminal
session inside Neovim.

`:CodeCompanionCLI` (bound to `<leader>aK`) opens the default agent (`kiro`);
`:CodeCompanionCLI agent=claude_code` (bound to `<leader>aC`) opens the other
one. You can also pass a prompt directly: `:CodeCompanionCLI fix the auth bug`
sends that text to a fresh or existing CLI session.

---

## 5. The rules system — and the bug that was fixed here

**What "rules" are:** files like `CLAUDE.md`, `KIRO.md`, or `.cursorrules`
that describe your conventions, which CodeCompanion can auto-insert as
context into a new chat so you don't have to paste them in by hand.

```lua
rules = {
  default = {
    description = "Common rules for all adapters",
    is_preset = true,
    files = { ".cursorrules", ".clinerules", "AGENT.md" }
  },
  kiro = {
    description = "Kiro CLI rules",
    enabled = function(chat)
      return chat and chat.adapter and chat.adapter.name == "kiro"
    end,
    files = { "~/.kiro/KIRO.md", "KIRO.md" }
  },
  claude = {
    description = "Claude Code rules",
    enabled = function(chat)
      return chat and chat.adapter and chat.adapter.name == "claude_code"
    end,
    parser = "claude",
    files = { "~/.claude/CLAUDE.md", "CLAUDE.md", "CLAUDE.local.md" }
  },
  opts = {
    chat = {
      enabled = true,
      autoload = { "default" }
    }
  }
}
```

Three named groups are defined: `default` (generic convention files, applies
to any adapter), `kiro` (only Kiro's memory file), and `claude` (only Claude
Code's memory file, parsed with the `claude` parser which understands
`CLAUDE.md`'s specific structure).

### The bug

Each group has an `enabled(chat)` predicate that looks like it should gate
*whether that group loads automatically*. It doesn't. Inside the plugin
(`lua/codecompanion/interactions/shared/rules/helpers.lua`), `enabled` is
**only consulted by the interactive `/rules` picker** (the list you get if
you type `/rules` inside a chat and choose one manually). The *automatic*
loading path (`rules.opts.chat.autoload`) ignores `enabled` completely — it
just blindly loads every name in that list for every chat. With the original
`autoload = { "default", "kiro", "claude" }`, **every chat got both KIRO.md
and CLAUDE.md as context, regardless of which adapter it was using.** That's
why you were seeing:

```
> Context:
> - <rules>/home/govardha/.kiro/KIRO.md</rules>
> - <rules>KIRO.md</rules>
> - <rules>/home/govardha/.claude/CLAUDE.md</rules>
```

in a Claude Code chat, when only the `claude` group should have applied.

### The fix

`autoload` was trimmed to just `{ "default" }` — the one group that's
genuinely adapter-agnostic and safe to always load. The `kiro`/`claude`
groups are instead attached by a `CodeCompanionChatCreated` autocmd
(registered in this file's `init` function), which fires once a chat is
fully created — meaning `chat.adapter.name` is already known — and adds
*only* the matching group:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "CodeCompanionChatCreated",
  callback = function(args)
    local chat = require("codecompanion.interactions.chat").buf_get_chat(args.data.bufnr)
    ...
    local group_name = rules_group_by_adapter[chat.adapter.name]  -- "kiro" -> "kiro", "claude_code" -> "claude"
    local group = group_name and require("codecompanion.config").rules[group_name]
    ...
    require("codecompanion.interactions.shared.rules").add_to_chat_from_config(chat, {
      name = group_name, opts = group.opts, parser = group.parser, files = group.files
    })
  end
})
```

This calls the exact same internal function
(`Rules.add_to_chat_from_config`) that the plugin's own autoload mechanism
uses — it's just gated by a real adapter check first. The `enabled`
predicates on the `kiro`/`claude` groups are still useful and were kept: they
still correctly hide the "wrong" group from the interactive `/rules` picker
inside a chat.

**Net effect today:**
- Open a `kiro` chat → only `KIRO.md` loads as context.
- Open a `claude_code` chat → only `CLAUDE.md` loads as context.
- Open an `openrouter` chat → neither loads (rules groups only apply to the
  two ACP adapters they're written for); `default` would still load if
  `.cursorrules`/`.clinerules`/`AGENT.md` existed in the project.

---

## 6. The tools system — and the second half of that fix

CodeCompanion ships its own tool-calling system for HTTP adapters:
`create_file`, `delete_file`, `read_file`, `insert_edit_into_file`,
`run_command`, `grep_search`, etc., bundled into named groups — most
relevantly `files` (read/search/edit files) and `agent` (everything in
`files`, plus `run_command`, i.e. shell execution). You invoke a group inside
a chat by typing `@agent` or `@files`.

**These groups mean nothing to an ACP chat.** As established in §1, Kiro and
Claude Code bring their own tool loop over the ACP protocol — the plugin's
own tool-calling machinery is simply never engaged for `chat.adapter.type ==
"acp"`. Concretely,
`lua/codecompanion/providers/completion/init.lua`'s `M.tools()` function
returns an empty list whenever the adapter type is `"acp"`, which is why
`@agent`/`@files` show no completion at all inside a kiro/claude chat.

### The bug

`interactions.chat.tools.opts.default_tools` is a *global* option — "which
tool groups should be pre-loaded into every new chat, no matter its
adapter." The original config set this to `{ "files" }` to make file tools
available without typing `@files` every time. But because it applies
unconditionally, it also tagged every ACP chat with a `files` group marker in
its context display — a cosmetic no-op (Kiro/Claude never call it), but
confusing clutter:

```
> Context:
> - <group>files</group>
```

showing up even in a plain Kiro chat.

### The fix

`default_tools` was removed from the static config entirely, and the same
`CodeCompanionChatCreated` autocmd from §5 now adds the `files` group only
when the chat's adapter is HTTP:

```lua
if chat.adapter.type == "http" then
  chat.tool_registry:add("files")
  return
end
```

So today: an `openrouter` chat gets `create_file`, `read_file`,
`file_search`, `grep_search`, `insert_edit_into_file`,
`get_changed_files`, and `delete_file` pre-loaded (everything in the `files`
group) — but **not** `run_command`, which stays behind an explicit `@agent`
you have to type yourself. That's a deliberate safety choice: shell execution
is one keystroke away, but never silently pre-armed. Every risky tool
(`create_file`, `delete_file`, `run_command`) still requires an approval
prompt by plugin default regardless (`require_approval_before = true`), and
if you want to blanket-approve everything for a session, the chat buffer has
a built-in `gty` keymap (`yolo_mode`) for exactly that.

---

## 7. Keymaps, walked through

All under `<leader>a*` (mnemonic: "AI"), defined via lazy.nvim's `keys` spec
— meaning `codecompanion.nvim` doesn't load at Neovim startup at all, it
loads the first time you press one of these (see §10).

| Keymap | Mode | What actually happens |
|---|---|---|
| `<leader>ak` | n, v | Opens (or switches to) an **ACP chat** on `kiro`. Spawns `kiro-cli acp --trust-all-tools` if not already running for this buffer. |
| `<leader>ac` | n, v | Same, but adapter `claude_code` → spawns `claude-agent-acp`. |
| `<leader>ao` | n, v | Same, but adapter `openrouter` → plain HTTP chat, gets the `files` tool group (§6), no subprocess. |
| `<leader>ai` | n, v | **Inline** edit using the default inline adapter (`openrouter`). Prompts you for instructions, edits the code in place. |
| `<leader>aI` | n, v | Inline edit, but forces adapter `kiro` instead — note this is one of the few places an ACP adapter is used for inline rather than chat. |
| `<leader>aK` | n, v | Opens the **CLI terminal** running `kiro-cli chat --trust-all-tools` (raw TUI, not CodeCompanion's chat UI — see §2/§4). |
| `<leader>aC` | n, v | CLI terminal running plain `claude`. |
| `<leader>at` | n, v | Toggles visibility of the last-used chat buffer (keeps the ACP session alive, just hides the window). |
| `<C-a>` | n, v | Opens the action palette — a picker over every static action, prompt-library entry, and rule/adapter shortcut. |
| `ga` | v | Adds the visually selected code to the **current/last chat** (creates one with the default adapter, `kiro`, if none is open yet). |
| `<leader>ae` | v | Runs the `explain` prompt-library entry — see §8, this is a **chat** interaction, not inline. |
| `<leader>af` | v | Runs `fix` — also a **chat** interaction. |
| `<leader>aT` | v | Runs `tests` — this one *is* an **inline** interaction. |
| `<leader>am` | n | Runs `commit` — a **chat** interaction, pulls in your git diff. |

Note that the visual-mode `ga` here is a **global** keymap you've defined
(distinct from the plugin's own buffer-local `ga` keymap inside an *already
open* chat buffer, which is bound to `change_adapter` — normal mode only, so
there's no actual conflict: yours is visual-mode-global, the plugin's is
normal-mode-buffer-local).

---

## 8. Prompt library shortcuts — the non-obvious part

`<leader>ae`, `<leader>af`, `<leader>aT`, `<leader>am` all go through
`:CodeCompanion /alias`, which resolves an entry from the plugin's **prompt
library** (`lua/codecompanion/prompt_library/builtins/*.md` — markdown files
with YAML frontmatter). Each entry declares which **interaction type** it
runs as, and that determines which of your configured adapters actually
handles it:

| Keymap | Prompt | `interaction:` | Adapter actually used | What happens |
|---|---|---|---|---|
| `<leader>ae` | `explain` | `chat` | **`kiro`** (`interactions.chat.adapter`) | Opens a real ACP chat with Kiro, auto-submits a pre-filled "explain this code" prompt |
| `<leader>af` | `fix` | `chat` | **`kiro`** | Same — a real Kiro chat, pre-filled "fix this code" prompt |
| `<leader>am` | `commit` | `chat` | **`kiro`** | Same — Kiro chat, prompt includes your git diff, does *not* auto-submit (you review/send manually) |
| `<leader>aT` | `tests` | `inline` | **`openrouter`** (`interactions.inline.adapter`) | No chat buffer — edits/creates code in place via HTTP |

**This is easy to get wrong intuitively:** none of these prompt files specify
an adapter of their own (checked — no `adapter:` key in their frontmatter),
so each one simply inherits whatever adapter is configured as the default
for its `interaction` type. Since your default *chat* adapter is `kiro`,
pressing `<leader>ae` to "just quickly explain this code" actually **spawns
a full Kiro ACP session** (a few seconds of connection overhead) rather than
firing a fast, stateless HTTP call. Only the `tests` shortcut (`<leader>aT`)
is a lightweight `openrouter` call, because it's the one entry marked
`interaction: inline`.

If you want `explain`/`fix`/`commit` to be fast HTTP calls instead of full
Kiro sessions, the fix is *not* in this file at all — it's changing
`interactions.chat.adapter` (which would also change every other `chat`
default, including plain `<leader>ao`... no, wait, that keymap already
force-selects `openrouter` explicitly). The clean way would be to author your
own prompt-library entries (or extend the built-ins) with an explicit
`opts.adapter` — not something this config does today.

---

## 9. Completion integration (blink.cmp) — why it's invisible here

You won't find `codecompanion` mentioned anywhere in
`lua/gov/plugins/blink-cmp.lua`, and that's correct, not missing. blink.cmp
is configured completely independently as its own plugin; CodeCompanion
registers its own completion source **dynamically at setup time**, scoped
only to its own buffers:

- `CodeCompanion.setup()` detects blink.cmp is installed
  (`lua/codecompanion/providers/init.lua` tries `blink > cmp > coc > default`
  in that order) and requires
  `codecompanion.providers.completion.blink.setup`.
- That file calls `blink.add_filetype_source("codecompanion", "codecompanion")`
  and the same for `"codecompanion_input"` — i.e. it tells blink.cmp "only
  offer this source inside these two filetypes," rather than adding itself to
  your global `sources.default` list.

This is filetype-scoped, not adapter-scoped, so `/` (slash commands), `#`
(editor context), and `\` (ACP-specific commands like `/resume`,
`/command`) all trigger blink completion identically whether you're in a
`kiro`, `claude_code`, or `openrouter` chat. The one adapter-dependent
difference is `@` (tool completion): it shows nothing in ACP chats and the
`files`/`agent` groups in HTTP chats, per §6 — that's the tool filter, not
blink.cmp, drawing the distinction.

The `codecompanion_input` filetype specifically belongs to a small floating
input box used by shared prompts (e.g. `:CodeCompanionCLI Ask`) — it is
*not* the raw CLI terminal buffer itself (that one is plain `filetype =
codecompanion_cli`, a real terminal, no completion applies there at all).

---

## 10. Markdown rendering and Tree-sitter

Two other plugins quietly make the chat buffer legible:

- `lua/gov/plugins/render-markdown.lua` sets `ft = { "markdown",
  "codecompanion" }` — so chat buffers get the same heading/code-block/list
  rendering as regular markdown files.
- `lua/gov/plugins/treesitter.lua` installs the `markdown` and
  `markdown_inline` parsers (via its `TSInstallAll` command) that both
  render-markdown.nvim and CodeCompanion's own syntax highlighting
  (`plugin/codecompanion.lua` registers `markdown` as the parser for the
  `codecompanion`/`codecompanion_input` filetypes) depend on. Without those
  parsers installed, the chat buffer would render as plain, unstyled text.

`:checkhealth codecompanion` confirms both parsers, plus `curl`, `rg`, and
`sqlite3` (used for reading Copilot's token store, irrelevant to your
adapters but checked anyway) are present.

---

## 11. Why the plugin loads when it does

```lua
return {
  "olimorris/codecompanion.nvim",
  cond = not vim.g.is_msys2,
  ...
  keys = { ... },
  init = function() ... end,
}
```

There's no `lazy = false` here (it was removed — see git history). With only
`keys` present, lazy.nvim defers loading `codecompanion.nvim` until you
actually press one of the `<leader>a*` mappings — startup stays fast. The
`init` function is the one exception: lazy.nvim always runs a plugin's
`init` at startup *regardless* of whether the plugin itself is loaded yet,
which is why the `cab cc CodeCompanion` command abbreviation and the
`CodeCompanionChatCreated` autocmd (§§5–6) are registered immediately, before
you've ever opened a chat — they need to exist *before* the event they react
to can possibly fire.

`cond = not vim.g.is_msys2` disables the whole plugin on an MSYS2 (Git Bash
on Windows) environment — presumably because the ACP subprocess model or one
of the CLI tools doesn't behave well there.

---

## 12. Environment variables

| Variable | Required for | Notes |
|---|---|---|
| `OPENROUTER_API_KEY` | `openrouter` adapter (chat, inline) | Set on this machine. |
| `CLAUDE_CODE_OAUTH_TOKEN` | `claude_code` ACP adapter | *Not* set here — falls back to `claude-agent-acp` reusing your existing `claude` CLI login instead. Only needed if you want a token-based auth path independent of that login. |

Kiro CLI has no env var requirement in this config — you authenticate once
via `kiro-cli` itself, outside of Neovim entirely.

---

## 13. Quick mental checklist for "what will pressing this key actually do"

1. **Is it a `chat` or `cli` keymap?** `cli` = raw terminal, tool's own UI,
   nothing CodeCompanion-specific happens to the conversation. `chat` =
   CodeCompanion's own buffer/UI wrapping either an ACP subprocess or an HTTP
   call.
2. **If `chat`, which adapter?** Explicit `adapter=...` in the keymap wins;
   otherwise it's whatever `interactions.chat.adapter` defaults to (`kiro`).
3. **Is that adapter ACP or HTTP?** ACP (`kiro`, `claude_code`) → the tool's
   own agent loop does file/shell work, rules load via the
   `CodeCompanionChatCreated` autocmd matching that adapter name, `@`-tools
   are inert. HTTP (`openrouter`) → CodeCompanion's own tools apply, `files`
   group pre-loaded, `agent`/`run_command` opt-in via `@agent`.
4. **Prompt-library shortcuts** (`explain`/`fix`/`commit`/`tests`) don't
   carry their own adapter — they inherit whichever default applies to their
   declared `interaction:` type (`chat` → kiro, `inline` → openrouter). See
   §8 if a shortcut feels slower or faster than you expected.

---

## Related docs in this repo

- `docs/codecompanion.md` — terse keymap/slash-command quick reference.
- `docs/kiro-cli-acp-workflow.md` — **currently stale**: it references a
  `groq` adapter and a `strategies` config key that no longer exist in this
  setup, and describes `claude_code` (not `kiro`) as the default chat
  adapter. Worth a rewrite or removal so it doesn't contradict this document
  — flagged here rather than silently deleted, since it may still hold
  workflow tips you wrote deliberately.
