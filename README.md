# multi-agent-shogun

<div align="center">

**Multi-Agent Orchestration System for Claude Code**

*One command. Eight AI agents working in parallel + Quality Assurance.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai)
[![tmux](https://img.shields.io/badge/tmux-required-green)](https://github.com/tmux/tmux)

[English](README.md) | [Japanese / 日本語](README_ja.md)

</div>

---

## What is this?

**multi-agent-shogun** is a system that runs multiple Claude Code instances simultaneously, organized like a feudal Japanese army.

**Why use this?**
- Give one command, get 8 AI workers executing in parallel
- No waiting - you can keep giving commands while tasks run in background
- AI remembers your preferences across sessions (Memory MCP)
- Real-time progress tracking via dashboard

```
        You (The Lord)
             │
             ▼ Give orders
      ┌─────────────┐
      │   SHOGUN    │  ← Receives your command, delegates immediately
      └──────┬──────┘
             │ YAML files + tmux
      ┌──────▼──────┐     ┌─────────────┐
      │    KARO     │─────│    SANBO    │  ← Test & Quality Assurance
      └──────┬──────┘     └─────────────┘
             │                 Staff Officer
    ┌─┬─┬─┬─┴─┬─┬─┬─┐
    │1│2│3│4│5│6│7│8│  ← 8 workers execute in parallel
    └─┴─┴─┴─┴─┴─┴─┴─┘
        ASHIGARU
```

---

## 🚀 Quick Start

### 🪟 Windows Users (Most Common)

<table>
<tr>
<td width="60">

**Step 1**

</td>
<td>

📥 **Download this repository**

[Download ZIP](https://github.com/yohey-w/multi-agent-shogun/archive/refs/heads/main.zip) and extract to `C:\tools\multi-agent-shogun`

*Or use git:* `git clone https://github.com/yohey-w/multi-agent-shogun.git C:\tools\multi-agent-shogun`

</td>
</tr>
<tr>
<td>

**Step 2**

</td>
<td>

🖱️ **Double-click `install.bat`**

That's it! The installer handles everything automatically.

</td>
</tr>
<tr>
<td>

**Step 3**

</td>
<td>

✅ **Done!** 10 AI agents are now running.

</td>
</tr>
</table>

#### 📅 Daily Startup (After First Install)

Open **Ubuntu terminal** (WSL) and run:

```bash
cd /mnt/c/tools/multi-agent-shogun
./shutsujin_departure.sh
```

---

<details>
<summary>🐧 <b>Linux / Mac Users</b> (Click to expand)</summary>

### First-Time Setup

```bash
# 1. Clone the repository
git clone https://github.com/yohey-w/multi-agent-shogun.git ~/multi-agent-shogun
cd ~/multi-agent-shogun

# 2. Make scripts executable
chmod +x *.sh

# 3. Run setup (dependencies + extensions auto-configured)
./first_setup.sh
```

### Daily Startup

```bash
cd ~/multi-agent-shogun
./shutsujin_departure.sh
```

Watchdog (report monitoring & auto-restart) starts by default.

</details>

---

<details>
<summary>❓ <b>What is WSL2? Why do I need it?</b> (Click to expand)</summary>

### About WSL2

**WSL2 (Windows Subsystem for Linux)** lets you run Linux inside Windows. This system uses `tmux` (a Linux tool) to manage multiple AI agents, so WSL2 is required on Windows.

### Don't have WSL2 yet?

No problem! When you run `install.bat`, it will:
1. Check if WSL2 is installed
2. If not, show you exactly how to install it
3. Guide you through the entire process

**Quick install command** (run in PowerShell as Administrator):
```powershell
wsl --install
```

Then restart your computer and run `install.bat` again.

</details>

---

<details>
<summary>📋 <b>Script Reference</b> (Click to expand)</summary>

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `install.bat` | Windows: First-time setup (runs first_setup.sh via WSL) | First time only |
| `first_setup.sh` | Installs tmux, Node.js, Claude Code CLI | First time only |
| `shutsujin_departure.sh` | Creates tmux sessions + starts Claude Code + loads instructions | Every day |

### What `install.bat` does automatically:
- ✅ Checks if WSL2 is installed
- ✅ Opens Ubuntu and runs `first_setup.sh`
- ✅ Installs tmux, Node.js, and Claude Code CLI
- ✅ Creates necessary directories

### What `shutsujin_departure.sh` does:
- ✅ Creates tmux sessions (shogun + multiagent)
- ✅ Launches Claude Code on all 10 agents
- ✅ Automatically loads instruction files for each agent
- ✅ Resets queue files for a fresh start

**After running, all agents are ready to receive commands immediately!**

</details>

---

<details>
<summary>🔧 <b>Prerequisites (for manual setup)</b> (Click to expand)</summary>

If you prefer to install dependencies manually:

| Requirement | How to install | Notes |
|-------------|----------------|-------|
| WSL2 + Ubuntu | `wsl --install` in PowerShell | Windows only |
| tmux | `sudo apt install tmux` | Terminal multiplexer |
| Node.js v20+ | `nvm install 20` | Required for Claude Code CLI |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` | Anthropic's official CLI |

</details>

---

### ✅ What Happens After Setup

After running either option, **11 AI agents** will start automatically:

| Agent | Role | Quantity |
|-------|------|----------|
| 🏯 Shogun | Commander - receives your orders | 1 |
| 📋 Karo | Manager - distributes tasks | 1 |
| ⚔️ Ashigaru | Workers - execute tasks in parallel | 8 |
| 🧠 Sanbo | Quality Assurance - runs tests & linting | 1 |

You'll see tmux sessions created:
- `shogun` - Connect here to give commands
- `multiagent` - Karo & Ashigaru running in background
- `sanbo` - Staff officer for test execution

---

## 📖 Basic Usage

### Step 1: Connect to Shogun

After running `shutsujin_departure.sh`, all agents automatically load their instructions and are ready to work.

Open a new terminal and connect to the Shogun:

```bash
tmux attach-session -t shogun
```

### Step 2: Give Your First Order

The Shogun is already initialized! Just give your command:

```
Investigate the top 5 JavaScript frameworks and create a comparison table.
```

The Shogun will:
1. Write the task to a YAML file
2. Notify the Karo (manager)
3. Return control to you immediately (you don't have to wait!)

Meanwhile, the Karo distributes the work to Ashigaru workers who execute in parallel.

### Step 3: Check Progress

Open `dashboard.md` in your editor to see real-time status:

```markdown
## In Progress
| Worker | Task | Status |
|--------|------|--------|
| Ashigaru 1 | React research | Running |
| Ashigaru 2 | Vue research | Running |
| Ashigaru 3 | Angular research | Done |
```

---

## ✨ Key Features

### ⚡ 1. Parallel Execution

One command can spawn up to 8 parallel tasks:

```
You: "Research 5 MCP servers"
→ 5 Ashigaru start researching simultaneously
→ Results ready in minutes, not hours
```

### 🔄 2. Non-Blocking Workflow

The Shogun delegates immediately and returns control to you:

```
You: Give order → Shogun: Delegates → You: Can give next order immediately
                                           ↓
                         Workers: Execute in background
                                           ↓
                         Dashboard: Shows results
```

You never have to wait for long tasks to complete.

### 🧠 3. Memory Across Sessions (Memory MCP)

The AI remembers your preferences:

```
Session 1: You say "I prefer simple solutions"
           → Saved to Memory MCP

Session 2: AI reads memory at startup
           → Won't suggest over-engineered solutions
```

### 📡 4. Event-Driven (No Polling)

Agents communicate via YAML files and wake each other with tmux send-keys.
**No API calls are wasted on polling loops.**

### 📸 5. Screenshot Support

VSCode's Claude Code extension lets you paste screenshots to explain issues. This CLI system brings the same capability:

```
# Configure your screenshot folder in config/settings.yaml
screenshot:
  path: "/mnt/c/Users/YourName/Pictures/Screenshots"

# Then just tell the Shogun:
You: "Check the latest screenshot"
You: "Look at the last 2 screenshots"
→ AI reads and analyzes your screenshots instantly
```

**💡 Windows Tip:** Press `Win + Shift + S` to take a screenshot. Configure the save location to match your `settings.yaml` path for seamless integration.

Perfect for:
- Explaining UI bugs visually
- Showing error messages
- Comparing before/after states

### 🧠 Model Configuration

| Agent | Model | Thinking | Reason |
|-------|-------|----------|--------|
| Shogun | Opus | Disabled | Delegation & dashboard updates don't need deep reasoning |
| Karo | Default | Enabled | Task distribution requires careful judgment |
| Ashigaru | Default | Enabled | Actual implementation needs full capabilities |

The Shogun uses `MAX_THINKING_TOKENS=0` to disable extended thinking, reducing latency and cost while maintaining Opus-level judgment for high-level decisions.

### 📁 Context Management

The system uses a three-layer context structure for efficient knowledge sharing:

| Layer | Location | Purpose |
|-------|----------|---------|
| Memory MCP | `memory/shogun_memory.jsonl` | Persistent memory across sessions (preferences, decisions) |
| Global | `memory/global_context.md` | System-wide settings, user preferences |
| Project | `context/{project}.md` | Project-specific knowledge and state |

This design allows:
- Any Ashigaru to pick up work on any project
- Consistent context across agent switches
- Clear separation of concerns
- Knowledge persistence across sessions

### Universal Context Template

All projects use the same 7-section template:

| Section | Purpose |
|---------|---------|
| What | Brief description of the project |
| Why | Goals and success criteria |
| Who | Stakeholders and responsibilities |
| Constraints | Deadlines, budget, limitations |
| Current State | Progress, next actions, blockers |
| Decisions | Decision log with rationale |
| Notes | Free-form notes and insights |

This standardized structure ensures:
- Quick onboarding for any agent
- Consistent information across all projects
- Easy handoffs between Ashigaru workers

### 🛠️ Skills

Skills are not included in this repository by default.
As you use the system, skill candidates will appear in `dashboard.md`.
Review and approve them to grow your personal skill library.

---

## 🏛️ Design Philosophy

### Why Hierarchical Structure?

The Shogun → Karo → Ashigaru hierarchy exists for:

1. **Immediate Response**: Shogun delegates instantly and returns control to you
2. **Parallel Execution**: Karo distributes to multiple Ashigaru simultaneously
3. **Separation of Concerns**: Shogun decides "what", Karo decides "who"

### Why YAML + send-keys?

- **YAML files**: Structured communication that survives agent restarts
- **send-keys**: Event-driven wakeups (no polling = no wasted API calls)
- **No direct calls**: Agents can't interrupt each other or your input

### Why Only Karo Updates Dashboard?

- **Single responsibility**: One writer = no conflicts
- **Information hub**: Karo receives all reports, knows the full picture
- **Consistency**: All updates go through one quality gate

### How Skills Work

Skills (`.claude/commands/`) are **not committed to this repository** by design.

**Why?**
- Each user's workflow is different
- Skills should grow organically based on your needs
- No one-size-fits-all solution

**How to create new skills:**
1. Ashigaru report "skill candidates" when they notice repeatable patterns
2. Candidates appear in `dashboard.md` under "Skill Candidates"
3. You review and approve (or reject)
4. Approved skills are created by Karo

This keeps skills **user-driven** — only what you find useful gets added.

---

## 🔌 MCP Setup Guide

MCP (Model Context Protocol) servers extend Claude's capabilities. Here's how to set them up:

### What is MCP?

MCP servers give Claude access to external tools:
- **Notion MCP** → Read/write Notion pages
- **GitHub MCP** → Create PRs, manage issues
- **Memory MCP** → Remember things across sessions

### Installing MCP Servers

Run these commands to add MCP servers:

```bash
# 1. Notion - Connect to your Notion workspace
claude mcp add notion -e NOTION_TOKEN=your_token_here -- npx -y @notionhq/notion-mcp-server

# 2. Playwright - Browser automation
claude mcp add playwright -- npx @playwright/mcp@latest
# Note: Run `npx playwright install chromium` first

# 3. GitHub - Repository operations
claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=your_pat_here -- npx -y @modelcontextprotocol/server-github

# 4. Sequential Thinking - Step-by-step reasoning for complex problems
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# 5. Memory - Long-term memory across sessions (Recommended!)
claude mcp add memory -e MEMORY_FILE_PATH="$PWD/memory/shogun_memory.jsonl" -- npx -y @modelcontextprotocol/server-memory
```

### Verify Installation

```bash
claude mcp list
```

You should see all servers with "Connected" status.

---

## 🌍 Real-World Use Cases

### Example 1: Research Task

```
You: "Research the top 5 AI coding assistants and compare them"

What happens:
1. Shogun delegates to Karo
2. Karo assigns:
   - Ashigaru 1: Research GitHub Copilot
   - Ashigaru 2: Research Cursor
   - Ashigaru 3: Research Claude Code
   - Ashigaru 4: Research Codeium
   - Ashigaru 5: Research Amazon CodeWhisperer
3. All 5 research simultaneously
4. Results compiled in dashboard.md
```

### Example 2: PoC Preparation

```
You: "Prepare a PoC for the project in this Notion page: [URL]"

What happens:
1. Karo fetches Notion content via MCP
2. Ashigaru 2: Lists items to clarify
3. Ashigaru 3: Researches technical feasibility
4. Ashigaru 4: Creates PoC plan document
5. All results in dashboard.md, ready for your meeting
```

---

## ⚙️ Configuration

### Language Setting

Edit `config/settings.yaml`:

```yaml
language: ja   # Japanese only
language: en   # Japanese + English translation
```

---

## 🛠️ Advanced Usage

<details>
<summary><b>Script Architecture</b> (Click to expand)</summary>

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FIRST-TIME SETUP (Run Once)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  install.bat (Windows)                                              │
│      │                                                              │
│      └──▶ first_setup.sh (via WSL)                                  │
│                │                                                    │
│                ├── Check/Install tmux                               │
│                ├── Check/Install Node.js v20+ (via nvm)             │
│                └── Check/Install Claude Code CLI                    │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                      DAILY STARTUP (Run Every Day)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  shutsujin_departure.sh                                             │
│      │                                                              │
│      ├──▶ Create tmux sessions                                      │
│      │         • "shogun" session (1 pane)                          │
│      │         • "multiagent" session (9 panes, 3x3 grid)           │
│      │                                                              │
│      ├──▶ Reset queue files and dashboard                           │
│      │                                                              │
│      └──▶ Launch Claude Code on all agents                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

</details>

<details>
<summary><b>shutsujin_departure.sh Options</b> (Click to expand)</summary>

```bash
# Default: Full startup (with watchdog)
./shutsujin_departure.sh

# Session setup only (without launching Claude Code)
./shutsujin_departure.sh -s
./shutsujin_departure.sh --setup-only

# Full startup + open Windows Terminal tabs
./shutsujin_departure.sh -t
./shutsujin_departure.sh --terminal

# Without watchdog (usually not needed)
./shutsujin_departure.sh --no-watchdog

# Show help
./shutsujin_departure.sh -h
./shutsujin_departure.sh --help
```

</details>

<details>
<summary><b>Common Workflows</b> (Click to expand)</summary>

**Normal Daily Usage:**
```bash
./shutsujin_departure.sh          # Start everything
tmux attach-session -t shogun     # Connect to give commands
```

**Debug Mode (manual control):**
```bash
./shutsujin_departure.sh -s       # Create sessions only

# Manually start Claude Code on specific agents
tmux send-keys -t shogun:0 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t multiagent:0.0 'claude --dangerously-skip-permissions' Enter
```

**Restart After Crash:**
```bash
# Kill existing sessions
tmux kill-session -t shogun
tmux kill-session -t multiagent

# Start fresh
./shutsujin_departure.sh
```

</details>

---

## 📁 File Structure

<details>
<summary><b>Click to expand file structure</b></summary>

```
multi-agent-shogun/
│
│  ┌─────────────────── SETUP SCRIPTS ───────────────────┐
├── install.bat               # Windows: First-time setup
├── first_setup.sh            # Ubuntu/Mac: Install dependencies
├── setup.sh                  # Extensions setup (hooks, etc.)
├── shutsujin_departure.sh    # Daily startup (auto-loads instructions)
│  └────────────────────────────────────────────────────┘
│
├── instructions/             # Agent instruction files
│   ├── shogun.md             # Commander instructions
│   ├── karo.md               # Manager instructions
│   ├── ashigaru.md           # Worker instructions
│   └── sanbo.md              # Staff officer instructions
│
├── extensions/               # Extension features
│   ├── hooks/                # Claude Code hooks
│   │   ├── role-detector.sh      # Role detection
│   │   ├── permission-guard.sh   # Permission control
│   │   └── post-task-report.sh   # Auto-notification
│   ├── scripts/              # Utilities
│   │   ├── watchdog.sh           # Report monitoring & auto-restart
│   │   └── agent-status.sh       # Agent status check
│   └── policies/             # Policy definitions
│
├── config/
│   └── settings.yaml         # Language and other settings
│
├── queue/                    # Communication files
│   ├── shogun_to_karo.yaml   # Commands from Shogun to Karo
│   ├── tasks/                # Individual worker task files
│   └── reports/              # Worker reports
│
├── memory/                   # Memory MCP storage
├── dashboard.md              # Real-time status overview
└── CLAUDE.md                 # Project context for Claude
```

</details>

---

## 🔌 Extensions

### Watchdog (Report Monitoring & Auto-Restart)

Monitors report files and automatically wakes up Karo when workers complete tasks.
**Starts by default.**

```bash
# Check status
./extensions/scripts/watchdog.sh --status

# Manual stop/start
./extensions/scripts/watchdog.sh --stop     # Stop
./extensions/scripts/watchdog.sh --daemon   # Start in background
```

### Agent Status Check

View all agents' running status:

```bash
# Check status
./extensions/scripts/agent-status.sh

# Wake up idle agents
./extensions/scripts/agent-status.sh --wake
```

### Hooks

Automatically configured by `setup.sh`:

| Hook | Function |
|------|----------|
| `permission-guard.sh` | Role-based permission control |
| `post-task-report.sh` | Auto-notification on report completion |
| `role-detector.sh` | Detect role from tmux pane name |

### Sanbo (Staff Officer)

Specialized agent for test execution & quality assurance:

```bash
# Connect to sanbo session
tmux attach-session -t sanbo
```

| Allowed | Forbidden |
|---------|-----------|
| npm test, pytest, cargo test | Source code editing |
| eslint, tsc, mypy | Production file changes |
| Coverage measurement | - |

---

## 🔧 Troubleshooting

<details>
<summary><b>MCP tools not working?</b></summary>

MCP tools are "deferred" and need to be loaded first:

```
# Wrong - tool not loaded
mcp__memory__read_graph()  ← Error!

# Correct - load first
ToolSearch("select:mcp__memory__read_graph")
mcp__memory__read_graph()  ← Works!
```

</details>

<details>
<summary><b>Agents asking for permissions?</b></summary>

Make sure to start with `--dangerously-skip-permissions`:

```bash
claude --dangerously-skip-permissions --system-prompt "..."
```

</details>

<details>
<summary><b>Workers stuck?</b></summary>

Check the worker's pane:
```bash
tmux attach-session -t multiagent
# Use Ctrl+B then number to switch panes
```

Or use the status script:
```bash
./extensions/scripts/agent-status.sh         # Check status
./extensions/scripts/agent-status.sh --wake  # Wake up stuck agents
```

</details>

<details>
<summary><b>Karo not responding?</b></summary>

Use watchdog to automatically wake Karo when reports complete:

```bash
# Start watchdog
./extensions/scripts/watchdog.sh --daemon

# Or use -w flag on startup
./shutsujin_departure.sh -w
```

</details>

---

## 📚 tmux Quick Reference

| Command | Description |
|---------|-------------|
| `tmux attach -t shogun` | Connect to Shogun |
| `tmux attach -t multiagent` | Connect to workers |
| `Ctrl+B` then `0-8` | Switch between panes |
| `Ctrl+B` then `d` | Detach (leave running) |
| `tmux kill-session -t shogun` | Stop Shogun session |
| `tmux kill-session -t multiagent` | Stop worker sessions |

---

## 🙏 Credits

Based on [Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication) by Akira-Papa.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

<div align="center">

**Command your AI army. Build faster.**

</div>
