# Console -> UI Mapping (UX Audit)

This document maps existing console output (print/io.write) to intended in-game UI targets. The goal: stop relying on the external console and show all player-facing feedback in the game UI.

Summary of findings
- Many systems use `print()` for player-visible messages (startup, onboarding, offline earnings, contract events, crisis, promotions, achievements).
- Some UI already draws text via `love.graphics.print()` (debug overlays, enhanced idle panels). We should unify drawing through `ui/ui_manager.lua`.
- Tests and tooling use `print()` heavily; keep test prints unchanged. Focus on runtime game prints.

High-level UI targets
- HUD (top bar): persistent small readouts for Money, Income/sec, Reputation, XP, Mission Tokens, Active Contracts count.
- Toasts: ephemeral, animated messages for short events (money gained, contract complete, hire, promotion, achievement, save success/failure).
- Terminal / Log panel: a scrollable, timestamped panel for verbose messages, history, and crisis logs. Color-coded by severity (info/notice/warn/error).
- Modal dialogs: for important blocking messages (offline summary, new game, save/load failures, promotions with detail).
- Crisis overlay: full-screen neon terminal with action buttons and large event-specific messages (started, resolved, failed, rewards).
- Debug overlay: developer-only panel (toggleable) for FPS, mode, timers, and raw system outputs.

Mapping (representative examples)

- src/game.lua
  - "🚀 Initializing Cyberspace Tycoon..." → Terminal (info) + Toast (short)
  - Asset visibility checks ("FOUND" / "MISSING") → Terminal (diagnostic), shown only in debug mode
  - Offline summary prints ("Processed X minutes", "Offline earnings") → Modal on load (with details) and Terminal
  - Welcome & Controls printed at start → First-run onboarding modal / in-game help overlay
  - "Switched to <mode> mode" → Toast + Debug overlay
  - Save success/failure prints → Toast (success/failure) + Terminal

- src/systems/network_save_system.lua
  - Save/load/network status messages (Server connection, Local save success/failure, Offline earnings) → Modal (offline summary), Toasts (save success/fail), Terminal (full logs)

- src/modes/enhanced_idle_mode.lua
  - Location change, promotions, achievements, training/research completion, contract list → Toasts for short items (contract completed, training done); Modal or Terminal for promotions/achievements with more detail; UI panels for contracts list
  - Active location bonuses and actions already drawn in this mode; keep drawing but remove prints

- src/modes/admin_mode.lua (Crisis Mode)
  - "🚨 Crisis started" → Crisis overlay big header + Terminal (new entry)
  - Crisis resolved / timed out messages → Crisis overlay + Terminal + Reward toast

- src/demo_integration.lua
  - Demo prints (initial state, simulated actions) → Keep as developer/demo output; optionally render summary in Terminal when running demo mode

- src/ui/ui_manager.lua
  - Toggle terminal overlay prints should instead call the Terminal component / log API rather than `print()`

- tools/* and tests/*
  - Leave console prints for tooling and test harnesses unchanged

Replacement guidance and API
- Add a single `ui.log(message, severity)` API (in `src/ui/ui_manager.lua` or `src/ui/logger.lua`) that:
  - Adds an entry to the in-game terminal (timestamped, severity)
  - Optionally triggers a toast for severity `info/notice/success/warn/error`
  - When debug mode is enabled, forward to `print()` as well

- Add `ui.toast(message, type, duration)` for short feedback
- Add `ui.hud.set(key, value)` or a `GameState` object the HUD reads each frame so systems update values via the game's event bus (`utils/event_bus.lua`) rather than printing

Acceptance criteria for UX audit
- All runtime `print()` usages that are player-facing are assigned to a UI target (HUD / toast / terminal / modal / crisis overlay)
- A short implementation plan for the first deliverables is attached below

Immediate implementation priorities (first 48 hours)
1. Implement HUD and wire resource values (money, income/sec, reputation, tokens).
2. Implement `ui.toast` and `ui.log` (terminal) stubs and replace a few high-value prints: offline summary, save/load success/fail, crisis start/resolve, contract completed, promotion/achievement.
3. Implement Crisis overlay to capture crisis-related prints, and ensure the admin_mode publishes to the UI API.

Files to edit (initial pass)
- `src/ui/ui_manager.lua` (add log/toast/HUD rendering)
- `src/game.lua` (replace prints for onboarding, offline summary, save status with UI API calls)
- `src/modes/admin_mode.lua` (route crisis prints to UI API)
- `src/systems/network_save_system.lua` (route save/load/offline prints to UI API)
- `src/modes/enhanced_idle_mode.lua` (route promotions/achievements to UI API)

Notes & next steps
- This mapping is deliberately actionable: next step is to implement the HUD and logging API, then incrementally replace printed messages with UI calls, leaving tests/tools unchanged.
- After the HUD and basic toasts are implemented, we should run the game locally and do a smoke test to ensure no essential message is lost.

---
Generated: 2025-09-27
