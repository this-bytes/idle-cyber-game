# Testing Methodology — Cyberspace Tycoon

This file documents the testing approach used by the project. It should be referenced by contributors when writing or running tests.

Overview
- Test framework: busted (Lua unit testing framework). Use LuaRocks to install: `luarocks install busted`.
- Test runner script: `run-tests.sh` (calls `busted --verbose spec`).
- Mocks: the repo includes `spec/helpers/love_mock.lua` and `spec/spec_helper.lua` to provide minimal `love` functionality while running tests outside the LÖVE runtime.

Test structure
- All specs live under `spec/` and follow `*_spec.lua` naming.
- `spec/spec_helper.lua` is loaded by tests to inject mocks and global configuration before any source modules are required.
- Each unit test should keep dependencies isolated; use the `src.utils.event_bus` and small helper mocks rather than spinning up LÖVE.

Best practices
- Keep unit tests fast and deterministic. Avoid time-sensitive behavior where possible; if needed, mock `love.timer.getTime`.
- Use `spec/helpers/love_mock.lua` to simulate `love.filesystem` for tests that exercise save/load operations.
- Favor small, focused tests: one logical assertion per test when practical.
- Use `pending(...)` for unimplemented behavior you plan to add later.

Mocks & Helpers
- `spec/helpers/love_mock.lua` provides `timer.getTime()` and an in-memory `filesystem` that implements `write`, `read`, `getInfo`, and `remove`.
- Import the helper by requiring `spec.spec_helper` at the top of specs (the helper sets `love = love or {}` and injects the mocks).

Integration tests
- Integration tests that exercise multiple systems (e.g., `Game.init()` wiring ResourceSystem + SaveSystem) should run in a controlled environment and use the mocks to avoid filesystem or LÖVE dependencies.
- Place integration specs under `spec/integration/` and keep them optional (can be marked pending or gated behind an environment variable).

Continuous Integration
- Provide a GitHub Actions workflow that runs on pushes and PRs:
  - Install Lua and LuaRocks
  - Install busted via LuaRocks
  - Run `busted --verbose spec`
  - Optionally run luacheck for linting

Example CI snippet (high-level):
  - name: Run tests
    run: |
      luarocks install busted
      busted --verbose spec

Writing tests for new systems
- Create a spec file under `spec/` named `<system>_spec.lua`.
- Require `spec.spec_helper` at the top.
- Mock external dependencies (love.*, filesystem, network, etc.) instead of calling them directly.

Debugging tests
- Run a single test with: `busted spec/<file> --pattern '<test name substring>'`
- Use `print()` to debug within tests; busted captures stdout alongside failures.

Notes
- Keep tests and mocks updated whenever source modules change their require-time behaviour. If a module uses `love.*` during require, ensure `spec.spec_helper` injects the necessary stubs before the module is required.
