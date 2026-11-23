# AI Coding Agents

FlutterAgentic uses agnostic-ai for Claude Code, Codex CLI, Pi, and OpenCode. These tools share the project rules and workflows from one source.

## Updating instructions

- Edit shared instructions in `.agnostic-ai/AGNOSTIC_AI.md`.
- Edit directory-specific rules in `.agnostic-ai/rules/` and shared skills in `.agnostic-ai/skills/`.
- Use the version in `agnostic-ai.yaml`, run `agnostic-ai sync` and `agnostic-ai sync --check`, then commit the specs and native outputs together.

| Target | Generated instructions and skills |
|---|---|
| Claude Code | `CLAUDE.md`, `.claude/rules/`, `.claude/skills/` |
| Codex CLI | `AGENTS.md`, scoped `AGENTS.md`, `.codex/skills/` |
| Pi | `AGENTS.md`, scoped `AGENTS.md`, `.pi/skills/` |
| OpenCode | `AGENTS.md`, scoped `AGENTS.md`, `.opencode/skills/` |

---

## Claude Code

**Install**
```bash
npm install -g @anthropic-ai/claude-code
```

**Auth**
```bash
claude login
```

**Usage** — run in the project root:
```bash
claude
```

**How context loads** — `CLAUDE.md` is auto-loaded on every session. It includes the shared conventions and imports `docs/reference/architecture.md` and `docs/explanation/end-goal.md`.

**Setup skill** — run `/setup-project` to check all prerequisites.
**Scaffold skill** — run `/add-feature-template` (or `/add-feature-template <name>`) to scaffold a new feature.

---

## Gemini CLI

**Install**
```bash
npm install -g @google/gemini-cli
```

**Auth**
```bash
gemini auth login
```

**Usage** — run in the project root:
```bash
gemini
```

**How context loads** — `GEMINI.md` imports the conventions, architecture, and end-goal docs via `@`.

**Setup skill** — ask *"help me set up this project"*.
**Scaffold skill** — ask *"scaffold a products feature"*.

---

## Gemini in Android Studio

**Install** — Open Android Studio → Plugins → search *Gemini* → Install.

**Usage** — Open the project. Use the Gemini chat panel with Agent mode enabled.

**How context loads** — `AGENTS.md` is auto-loaded. It contains conventions inline and named pointers to `docs/reference/architecture.md` and `docs/explanation/end-goal.md`.

**Setup skill** — ask *"help me set up this project"*.
**Scaffold skill** — ask *"scaffold a products feature"*.

---

## Codex CLI

**Install**
```bash
npm install -g @openai/codex
```

**Auth**
```bash
export OPENAI_API_KEY=your_key
```

**Usage** — run in the project root:
```bash
codex
```

**How context loads** — `AGENTS.md` is auto-loaded at session start. It contains conventions inline and named pointers to `docs/reference/architecture.md` and `docs/explanation/end-goal.md`.

**Setup skill** — type `$setup-project` to run the environment checklist, or ask about project setup and Codex auto-triggers it.
**Scaffold skill** — type `$add-feature-template <name>` to scaffold a new feature.

---

## Quick comparison

| Agent | Instruction file | Setup trigger | Scaffold trigger |
|---|---|---|---|
| Claude Code | `CLAUDE.md` | `/setup-project` | `/add-feature-template` |
| Gemini CLI | `GEMINI.md` | Ask about setup | Ask to scaffold a feature |
| Android Studio | `AGENTS.md` | Ask about setup | Ask to scaffold a feature |
| Codex CLI | `AGENTS.md` | `$setup-project` | `$add-feature-template` |
| Pi | `AGENTS.md` and `.pi/skills/` | Ask to run the `setup-project` skill | Ask to run the `add-feature-template` skill |
| OpenCode | `AGENTS.md` and `.opencode/skills/` | Ask to run the `setup-project` skill | Ask to run the `add-feature-template` skill |
| GitHub Copilot | `.github/copilot-instructions.md` | Ask about setup | Ask to scaffold a feature |
