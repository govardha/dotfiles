# Kiro CLI + CodeCompanion ACP Workflow Guide

Complete step-by-step tutorial for using `kiro-cli` as an ACP (Agent Client Protocol)
agent inside Neovim via CodeCompanion.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [How It Works (Architecture)](#how-it-works)
3. [Step 1: Install & Authenticate kiro-cli](#step-1-install--authenticate-kiro-cli)
4. [Step 2: Plugin Configuration](#step-2-plugin-configuration)
5. [Step 3: Verify the Connection](#step-3-verify-the-connection)
6. [Step 4: Basic Chat Workflow](#step-4-basic-chat-workflow)
7. [Step 5: Sending File Context](#step-5-sending-file-context)
8. [Step 6: ACP-Specific Slash Commands](#step-6-acp-specific-slash-commands)
9. [Step 7: Tool Approvals & Permissions](#step-7-tool-approvals--permissions)
10. [Step 8: Session Management & Resume](#step-8-session-management--resume)
11. [Step 9: Model & Effort Selection](#step-9-model--effort-selection)
12. [Step 10: MCP Servers via Kiro](#step-10-mcp-servers-via-kiro)
13. [Step 11: Multi-Adapter Switching](#step-11-multi-adapter-switching)
14. [Troubleshooting](#troubleshooting)
15. [Tips & Best Practices](#tips--best-practices)
16. [Key Differences: ACP vs HTTP Adapters](#key-differences-acp-vs-http-adapters)
17. [Quick Reference Card](#quick-reference-card)

---

## Prerequisites

| Requirement          | How to check                        | Install                                           |
|----------------------|-------------------------------------|---------------------------------------------------|
| Neovim ≥ 0.10       | `nvim --version`                    | https://github.com/neovim/neovim/releases         |
| kiro-cli ≥ 2.x      | `kiro-cli --version`                | `curl -fsSL https://cli.kiro.dev/install \| bash` |
| codecompanion.nvim   | `:Lazy check codecompanion.nvim`    | Already in your plugin spec                       |
| Authenticated login  | `kiro-cli whoami`                   | `kiro-cli login`                                  |
| kiro-cli on PATH     | `which kiro-cli`                    | Ensure `~/.local/bin` is in PATH                  |

---

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  Neovim                                                 │
│  ┌─────────────────────────────────────────────────┐    │
│  │  CodeCompanion Chat Buffer                      │    │
│  │  (you type messages here)                       │    │
│  └──────────────────────┬──────────────────────────┘    │
│                         │ JSON-RPC over stdio            │
│                         ▼                                │
│  ┌─────────────────────────────────────────────────┐    │
│  │  kiro-cli acp                                   │    │
│  │  (spawned as subprocess)                        │    │
│  │                                                 │    │
│  │  • Manages session state                        │    │
│  │  • Has its own tool set (fs read/write, shell)  │    │
│  │  • Reads .kiro/steering/ for context            │    │
│  │  • Handles auth internally                      │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

Key points:
- CodeCompanion spawns `kiro-cli acp` as a subprocess
- Communication uses ACP Protocol Version 1 (JSON-RPC 2.0 over stdio)
- Kiro is **stateful** — it remembers the conversation (unlike HTTP adapters)
- CodeCompanion only sends *new* messages each turn (not the full history)
- Kiro has its own tools (file read/write, shell) and handles permissions itself

---

## Step 1: Install & Authenticate kiro-cli

```bash
# Install (if not already done)
curl -fsSL https://cli.kiro.dev/install | bash

# Verify installation
kiro-cli --version
# Expected: kiro-cli 2.x.x

# Login (opens browser for auth)
kiro-cli login

# Verify auth
kiro-cli whoami
# Should show your username/email
```

If `kiro-cli` isn't found, ensure `~/.local/bin` is in your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="${HOME}/.local/bin:${PATH}"
```

---

## Step 2: Plugin Configuration

The `kiro` adapter is **built-in** to codecompanion.nvim (v19+). You do NOT need
to define a custom adapter — it ships as a preset ACP adapter.

### Minimal Config (just works)

In your `codecompanion.lua` plugin spec, you just need to reference `kiro` as the
default chat adapter. Here's the relevant portion:

```lua
require("codecompanion").setup({
  strategies = {
    chat = { adapter = "kiro" },   -- Use Kiro as default chat adapter
    agent = { adapter = "kiro" },  -- Use Kiro for agent tasks too
    inline = { adapter = "groq" }, -- Keep fast inline with Groq
  },
})
```

### With Custom Options (effort, timeout, trust-all-tools)

```lua
require("codecompanion").setup({
  adapters = {
    acp = {
      kiro = function()
        return require("codecompanion.adapters").extend("kiro", {
          commands = {
            default = {
              "kiro-cli",
              "acp",
              "--trust-all-tools",  -- skip tool approval prompts
              "--effort", "high",   -- reasoning effort level
            },
          },
          defaults = {
            timeout = 30000, -- 30 seconds (default is 20000)
          },
        })
      end,
    },
  },
  strategies = {
    chat = { adapter = "kiro" },
    agent = { adapter = "kiro" },
    inline = { adapter = "groq" },
  },
})
```

### Available kiro-cli acp flags

| Flag                          | Description                                       |
|-------------------------------|---------------------------------------------------|
| `--trust-all-tools` / `-a`   | Auto-approve all tool permission requests         |
| `--trust-tools <NAMES>`      | Trust only specific tools (comma-separated)       |
| `--effort <LEVEL>`           | low, medium, high, xhigh, max                    |
| `--model <MODEL>`            | Model ID for the session                          |
| `--agent <AGENT>`            | Named agent to use                                |
| `--agent-engine <ENGINE>`    | v1, v2 (default), or v3                           |

### Current Config (your setup)

Your existing `<leader>ak` keymap already works:

```lua
map({ "n", "v" }, "<leader>ak", "<cmd>CodeCompanionChat adapter=kiro<CR>",
  { desc = "AI: Kiro (default chat)" })
```

This opens a chat buffer using the built-in kiro adapter.

---

## Step 3: Verify the Connection

1. Open Neovim in a project directory
2. Press `<leader>ak` (or `:CodeCompanionChat adapter=kiro`)
3. A chat buffer opens — type a simple message:

```
Hello, can you see my project files?
```

4. Press `<CR>` (normal mode) or `<C-s>` (insert mode) to send

**What happens under the hood:**
- CodeCompanion spawns `kiro-cli acp`
- Sends `initialize` request with client capabilities
- Kiro responds with its capabilities
- A session is created
- Your message is sent via `session/message`

**If it works:** You'll see Kiro's response stream into the chat buffer.

**If it fails:** See [Troubleshooting](#troubleshooting).

---

## Step 4: Basic Chat Workflow

### Opening a chat

| Method                                  | Description                    |
|-----------------------------------------|--------------------------------|
| `<leader>ak`                            | Open Kiro chat (your keymap)   |
| `:CodeCompanionChat adapter=kiro`       | Explicit command                |
| `<leader>at`                            | Toggle existing chat           |
| `<C-a>` → select "Open chat (Kiro)"    | Via action palette             |

### Sending messages

| Key       | Mode   | Action       |
|-----------|--------|--------------|
| `<CR>`    | Normal | Send message |
| `<C-s>`   | Insert | Send message |

### Chat is stateful

Unlike HTTP adapters where every request sends the full history, with Kiro ACP:
- The session persists on Kiro's side
- You only send new messages
- Context accumulates naturally
- No token waste on re-sending history

### Stopping a response

Press `q` in normal mode in the chat buffer to stop the current generation.

---

## Step 5: Sending File Context

### Method 1: Add visual selection (`ga`)

1. Select code in any buffer (visual mode)
2. Press `ga` — selection is added to the active chat
3. Switch to the chat buffer and ask your question

### Method 2: Slash commands in chat

While in the chat buffer (insert mode):

```
/file              → pick a file from cwd to include
/buffer            → pick from open buffers
/symbols           → include a treesitter outline of a file
```

### Method 3: Editor context with `#`

Type `#` in insert mode in the chat buffer to get a completion menu of:
- `#buffer` — current buffer content
- `#buffers` — all open buffers
- `#file` — pick a file
- `#selection` — current visual selection (if any)
- `#viewport` — visible lines in the editor

### How file context works with ACP

When you share files with an ACP adapter like Kiro:
- CodeCompanion reads the file content fresh (not from buffer cache)
- Sends it as an embedded resource to the agent
- No `<attachment>` tags — clean content delivery
- Kiro can then use its own tools to read/modify those files

---

## Step 6: ACP-Specific Slash Commands

These slash commands are **only available with ACP adapters** like Kiro:

| Command               | What it does                                              |
|-----------------------|-----------------------------------------------------------|
| `/acp_session_options`| View/change session config (model, mode, effort)          |
| `/command`            | Switch between adapter commands (resets chat)              |
| `/mode`              | Switch agent operating mode                                |
| `/resume`            | Resume a previous session (must be first action in chat)   |

### Kiro's own slash commands

ACP agents can advertise their own commands. Access them with `\` prefix:

```
\help              → Kiro's built-in help
\compact           → Summarize and compact context
```

(Available commands depend on the kiro-cli version)

### Using /acp_session_options

1. Type `/acp_session_options` in the chat buffer
2. A picker appears showing available options (model, effort, etc.)
3. Select an option and set the value
4. The session updates in place

---

## Step 7: Tool Approvals & Permissions

Kiro has its own tool system separate from CodeCompanion's built-in tools. When Kiro
wants to perform an action (write a file, run a command), CodeCompanion will show you
a permission dialog with a diff preview.

### Permission options

When prompted:
- **Allow** — approve this specific action
- **Reject** — deny and provide feedback

### Trust all tools (skip prompts)

If you trust Kiro to do its thing, add `--trust-all-tools` to the adapter command:

```lua
commands = {
  default = {
    "kiro-cli",
    "acp",
    "--trust-all-tools",
  },
},
```

Or trust specific tools only:

```lua
commands = {
  default = {
    "kiro-cli",
    "acp",
    "--trust-tools", "fs_read,fs_write",
  },
},
```

### What Kiro can do (client capabilities)

CodeCompanion tells Kiro it supports:
- `fs.readTextFile` — Kiro can request to read files
- `fs.writeTextFile` — Kiro can request to write/create files
- `terminal` — **NOT supported** (Kiro can't run shell commands through CodeCompanion)

Kiro runs commands through its own subprocess, not Neovim's terminal.

---

## Step 8: Session Management & Resume

### How sessions work

- Each chat buffer creates a new ACP session
- Sessions are managed by kiro-cli (stored in `~/.kiro/sessions/`)
- Closing the chat buffer sends a cleanup signal
- Neovim exit (`VimLeavePre`) properly terminates agents

### Resuming a session

If kiro-cli supports `session/list` (check with `kiro-cli acp --help`):

1. Open a **fresh** chat buffer: `<leader>ak`
2. **Before sending any message**, type: `/resume`
3. A picker shows previous sessions with timestamps
4. Select one — the history loads into the buffer
5. Continue the conversation where you left off

> Important: `/resume` only works on a blank chat buffer before any messages are sent.

### Multiple chats

You can have multiple Kiro chat buffers open simultaneously.
Each gets its own independent session.

---

## Step 9: Model & Effort Selection

### Setting model at config time

```lua
require("codecompanion").setup({
  adapters = {
    acp = {
      kiro = function()
        return require("codecompanion.adapters").extend("kiro", {
          commands = {
            default = {
              "kiro-cli",
              "acp",
              "--model", "auto",
              "--effort", "high",
            },
          },
        })
      end,
    },
  },
})
```

### Changing model mid-session

Use `/acp_session_options` in the chat buffer to switch models without restarting.

### Effort levels

| Level  | Use case                                |
|--------|-----------------------------------------|
| low    | Quick answers, simple questions         |
| medium | Default, balanced                       |
| high   | Complex tasks, multi-file changes       |
| xhigh  | Deep reasoning, architecture decisions  |
| max    | Maximum reasoning, cost-intensive       |

---

## Step 10: MCP Servers via Kiro

Kiro has its own MCP server support. If you've configured MCP servers in kiro-cli:

```bash
# List configured MCP servers
kiro-cli mcp list

# Add a server
kiro-cli mcp add my-server --command "npx" --args "-y @some/mcp-server"
```

### Inheriting MCP servers from CodeCompanion config

If you have MCP servers defined in your CodeCompanion config, tell Kiro to use them:

```lua
require("codecompanion").setup({
  adapters = {
    acp = {
      kiro = function()
        return require("codecompanion.adapters").extend("kiro", {
          defaults = {
            mcpServers = "inherit_from_config",
          },
        })
      end,
    },
  },
})
```

Or configure them explicitly:

```lua
defaults = {
  mcpServers = {
    {
      name = "my-server",
      command = "npx",
      args = { "-y", "@modelcontextprotocol/server-filesystem" },
      env = {},
    },
  },
},
```

---

## Step 11: Multi-Adapter Switching

Your config already has multiple adapters. Here's the workflow:

### Quick switch keymaps (your existing setup)

| Keymap       | Adapter     | Best for                           |
|--------------|-------------|------------------------------------|
| `<leader>ak` | Kiro (ACP)  | Full agentic coding, file changes |
| `<leader>ac` | Claude Code | Alternative agentic coding         |
| `<leader>ag` | Groq (HTTP) | Fast Q&A, explanations             |
| `<leader>ao` | OpenRouter  | Access to many models              |
| `<leader>ai` | Inline      | Quick in-place edits               |

### When to use Kiro vs HTTP adapters

| Scenario                              | Use        | Why                                |
|---------------------------------------|------------|------------------------------------|
| Multi-file refactoring                | Kiro (ACP) | Stateful, has filesystem tools     |
| Quick "explain this" question         | Groq (HTTP)| Fast, stateless, no overhead       |
| Generate a commit message             | Groq (HTTP)| Simple task, fast response         |
| Build a new feature from scratch      | Kiro (ACP) | Can read/write files, run commands |
| Fix a bug with context from many files| Kiro (ACP) | Accumulates context across turns   |
| Inline code transformation            | Groq/OR    | Direct buffer edit, no chat needed |

---

## Troubleshooting

### "kiro-cli: command not found"

```bash
# Check if installed
ls ~/.local/bin/kiro-cli

# Add to PATH in shell rc
export PATH="${HOME}/.local/bin:${PATH}"

# Reload shell and reopen nvim
```

### "Authentication failed" or silent failure

```bash
# Re-authenticate
kiro-cli login

# Verify
kiro-cli whoami
```

### Chat buffer opens but no response

1. Check the debug log:
   - In the chat buffer, open the debug window (check `:h codecompanion` for keymap)
   - Or check `:messages` for errors

2. Test kiro-cli directly:
   ```bash
   echo '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":1,"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true}},"clientInfo":{"name":"test","version":"1.0.0"}}}' | kiro-cli acp
   ```

3. Check if online mode is needed:
   ```bash
   # Your config is offline-first. Ensure .online exists or NVIM_ONLINE=true
   touch ~/.config/nvim/.online
   ```

### Timeout errors

Increase the timeout in your adapter config:

```lua
defaults = {
  timeout = 60000, -- 60 seconds
},
```

### Plugin version too old

The built-in kiro adapter requires codecompanion.nvim with ACP support.
Update the plugin:

```
:Lazy update codecompanion.nvim
```

(Requires online mode: `touch ~/.config/nvim/.online`)

### Debug logging

Your config already has `log_level = "DEBUG"`. Check the log:

```vim
:CodeCompanionLog
```

Or find it at:
```
~/.local/state/nvim/codecompanion.log
```

---

## Tips & Best Practices

### 1. Start conversations with context

Don't just ask a question — give Kiro context first:
```
I'm working on the lsp/mason.lua file. The goal is to add support for
a new language server. Here's the current file: /file
```

### 2. Use steering files

Kiro reads `~/.kiro/steering/` automatically. Your practices, constraints, and
coding style are already picked up. Project-level `.kiro/steering/` works too.

### 3. Keep sessions focused

One task per chat session. If you pivot topics, open a new chat (`<leader>ak`).
The old one stays open — switch with `<leader>at`.

### 4. Leverage statefulness

Unlike HTTP adapters, you don't need to re-explain context every message.
Kiro remembers everything from the session. Build up incrementally:
```
Message 1: "Here's my project structure" + /file
Message 2: "Now let's add pagination to the /users endpoint"
Message 3: "Can you also add tests for that?"
```

### 5. Review file changes before accepting

When Kiro proposes file writes, CodeCompanion shows a diff. Review carefully.
If you're using `--trust-all-tools`, changes happen automatically.

### 6. Compact long conversations

If a session gets long and slow, use `/compact` (if available via `\compact`
from Kiro) to summarize and free up context window space.

### 7. Use visual selection for targeted help

```
1. Select a function in visual mode
2. Press `ga` to add to chat
3. Switch to chat buffer
4. Ask: "This function has a race condition, can you fix it?"
```

### 8. Combine with prompt library

Your existing prompt library shortcuts still work alongside Kiro:
- `<leader>ae` — explain selected code
- `<leader>af` — fix selected code
- `<leader>aT` — generate tests

These use the **inline** adapter (Groq) for speed, not Kiro.

---

## Key Differences: ACP vs HTTP Adapters

| Aspect              | ACP (Kiro)                              | HTTP (Groq, OpenRouter)            |
|---------------------|------------------------------------------|------------------------------------|
| State               | Stateful (agent keeps history)           | Stateless (full history each req)  |
| Message sending     | Only new messages sent                   | Entire conversation re-sent        |
| Tools               | Agent's own tools (fs, shell)            | CodeCompanion's built-in tools     |
| Permissions         | Agent-managed approval UI                | CodeCompanion approval system      |
| Process             | Long-running subprocess                  | One HTTP request per turn          |
| Session resume      | Yes (`/resume`)                          | No (stateless)                     |
| Slash commands      | Agent can advertise its own (`\cmd`)     | Only CodeCompanion's commands      |
| Model selection     | Via `/acp_session_options` or CLI flag   | Via adapter `schema.model`         |
| Context window      | Managed by the agent                     | You manage via message history     |
| System prompt       | Agent uses its own                       | CodeCompanion's system prompt      |
| `@{agent}` tools    | NOT used (those are HTTP-only)           | Used for built-in tool groups      |

---

## Quick Reference Card

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  KIRO ACP WORKFLOW — QUICK REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  OPEN CHAT        <leader>ak
  SEND MESSAGE     <CR> (normal) or <C-s> (insert)
  TOGGLE CHAT      <leader>at
  ADD SELECTION    ga (visual mode)
  ACTION PALETTE   <C-a>

  SHARE CONTEXT
    #buffer        current buffer
    #file          pick a file
    /file          slash command file picker
    /symbols       treesitter outline
    ga             visual selection

  ACP COMMANDS (in chat buffer)
    /resume        restore a previous session
    /mode          switch agent mode
    /command       switch adapter command
    /acp_session_options  change model/effort

  KIRO AGENT COMMANDS (backslash prefix)
    \help          kiro's help
    \compact       summarize context

  STOP RESPONSE    q (normal mode in chat)

  PROMPT LIBRARY (uses inline adapter, not Kiro)
    <leader>ae     explain code (visual)
    <leader>af     fix code (visual)
    <leader>aT     generate tests (visual)
    <leader>am     commit message

  DEBUG
    :CodeCompanionLog     view log file
    :messages             check for errors
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## References

- [CodeCompanion ACP Docs](https://codecompanion.olimorris.dev/agent-client-protocol)
- [CodeCompanion ACP Adapter Config](https://codecompanion.olimorris.dev/configuration/adapters-acp)
- [Kiro CLI Docs](https://kiro.dev/docs/cli/)
- [ACP Specification](https://agentclientprotocol.com/)
- [Kiro Adapter Source](https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/adapters/acp/kiro.lua)
