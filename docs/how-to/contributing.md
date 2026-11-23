# Contributing

## First-time setup

```bash
make setup   # wires git hooks + root flutter pub get
```

This is a **Dart pub-workspace monorepo** (`packages/core` + `apps/*`). `make setup` runs two things:
- `git config core.hooksPath .githooks` — activates the pre-commit hook
- `flutter pub get` at the repo root — resolves every package in the workspace in one pass

Run `make` targets from the repo root; run an app from its own folder (`apps/<app>`).

---

## Pre-commit hook (`.githooks/pre-commit`)

The hook runs automatically on every `git commit` and does two things:

### 1. Dart formatting
Formats any staged `.dart` files with `dart format` and re-stages them.
The commit is never blocked by formatting — it's fixed automatically.

### 2. Static analysis
Runs `flutter analyze --no-pub --fatal-infos`.
The commit is **blocked** if any issue is found. Fix the issues and re-commit.

---

## AI agent rule files

Edit `.agnostic-ai/AGNOSTIC_AI.md` for shared instructions, `.agnostic-ai/rules/` for scoped rules, and `.agnostic-ai/skills/` for shared skills. To add a reference all agents should see, add a pointer in the shared instructions.

Generate the native files and check for drift before committing:

```bash
agnostic-ai sync
agnostic-ai sync --check
```

Commit the source changes with the generated files so contributors can use their agents after cloning. See `docs/explanation/ai-agents.md` for the generated tool paths.

---

## Makefile targets

Run all targets from the repo root.

| Target | What it does |
|---|---|
| `make setup` | First-time setup: git hooks + root `flutter pub get` |
| `make run-jokes` | Run the jokes app (`cd apps/jokes && flutter run`) |
| `make run-doc-scanner` | Run the doc_scanner app |
| `make web-jokes` / `make web-doc-scanner` | Run an app on Chrome |
| `make test` | `flutter test` in each app |
| `make analyze` | `flutter analyze` — covers the whole workspace |
| `make gen` | `build_runner` in core + each app |
| `make clean` | `flutter clean` per package, then root `flutter pub get` |
