# Agent Skills

My reusable skills for AI coding agents. One `SKILL.md` works in every agent that follows the open [Agent Skills](https://agentskills.io) standard.

## Skills

| Skill | What it does |
|---|---|
| `ai-coding` | Build full-stack AI apps fast: SOLID folders, readable code, shadcn UI, Docker optional, same code local + AWS, OTel zero-code tracing with baggage, security, tests, LLM evals, human-in-loop only for key decisions |

## Install

### Option 1: one command (all agents)

```bash
npx skills add shreenu/agent-skills
```

Pick the agents you use (Claude Code, Codex, Cursor, Copilot, Gemini CLI, ...). It installs into each agent's skills folder.

### Option 2: install script (no npx)

Into one project:

```bash
# Mac / Linux
./scripts/install.sh /path/to/project

# Windows PowerShell
.\scripts\install.ps1 C:\path\to\project
```

Global (all projects on this machine):

```bash
./scripts/install.sh --global
.\scripts\install.ps1 -Global
```

## Where each agent looks

| Agent | Project folder | Global folder |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| OpenAI Codex | `.agents/skills/` | `~/.codex/skills/` |
| Cursor | `.agents/skills/` or `.cursor/skills/` | `~/.cursor/skills/` |
| GitHub Copilot | `.agents/skills/` or `.github/skills/` | `~/.copilot/skills/` |
| Gemini CLI | `.agents/skills/` or `.gemini/skills/` | `~/.gemini/skills/` |

The install script copies the skill to `.agents/skills/` (shared) and `.claude/skills/`, and adds a short pointer to the project's `AGENTS.md` so agents without skill support still follow it.

## How to use

- Most agents pick the skill automatically from its description ("build a coding project", "full-stack app").
- To force it, say: `use the ai-coding skill` (or `/ai-coding` in Claude Code).

## Update a skill

1. Edit `skills/<name>/SKILL.md` (single source of truth)
2. Commit and push
3. Re-run `npx skills add ...` or the install script in your projects
