# Technical Architecture — Cyber Empire Command

Goals
- Provide a robust, modular architecture for LÖVE (Lua) implementation while keeping systems engine-agnostic where possible.
- Full data-driven design: contracts, specialists, threats, events defined by data files.

Core Modules (map to `src/`)
- `systems/resource_system.lua` — handles idle resource accrual and contract payouts.
- `systems/upgrade_system.lua` — handles upgrades, costs, and facility effects.
- `systems/threat_system.lua` — threat generation, escalation, and Crisis Mode triggers.
- `systems/save_system.lua` — JSON-based saves with versioning and checksums.
- `systems/achievement_system.lua` — achievements and milestones.
- `modes/idle_mode.lua` & `modes/admin_mode.lua` — HQ and Crisis Mode orchestration.
- `ui/ui_manager.lua` — draws HUD and Crisis UI; handles input routing.
- `utils/event_bus.lua` — event pub/sub between systems.

Data formats & content
- Use Lua tables or JSON for data files with clear schemas.
- Keep balancing constants in a dedicated file for easy tuning.

Runtime & performance
- Load large assets (music) as streaming; SFX as static.
- Use object pooling for particle effects and crisis log entries.
- Limit per-frame work during idle to occasional ticks (no heavy frame-by-frame loops).

Testing & tooling
- Provide small harness scripts to simulate days/weeks of play for balancing (`tools/simulate.lua`).
- Logging and telemetry hooks for debugging and analytics.
- Versioned save format with migration helpers.

Integration & deployment
- Base LÖVE entry points (`love.load`, `love.update`, `love.draw`) should be minimal and route to `Game` manager with mode switching.
- Asset layout should match `assets/` conventions in the main instruction file.
- Provide build steps and packaging notes for desktop and mobile in the repo README.

Security & content integrity
- Save checksums to detect corrupt files.
- Anti-cheat: local-only heuristics for impossible values; server-side validation recommended if multiplayer is considered.

Deliverables
- A technical mapping file that lists functions / events each module emits/consumes (design-only), to help implementation.
