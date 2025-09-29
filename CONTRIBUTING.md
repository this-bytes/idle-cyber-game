# Contributing

This repository follows the development roadmap in `.github/copilot-instructions/12-development-roadmap.instructions.md`.

Guidelines:
- Use feature branches: `feature/<system>-<short>` (e.g., `feature/core-ui`)
- Commit message format: `type(scope): short description`
- Open PRs against `develop` (or `main` if `develop` not used)
- Add tests for new systems under `tests/`

Before submitting a PR:
- Run `lua tests/test_runner.lua`
- Ensure new code follows instruction files in `.github/copilot-instructions/`
