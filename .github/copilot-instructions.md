Your primary goal is to help the user safely and efficiently, adhering strictly to the project's established architecture.

## Architecture Golden Rules

1.  **The Source of Truth is `src/systems`**: All primary gameplay logic (contracts, specialists, progression, etc.) is located in the `src/systems` directory. These modules are well-designed, event-driven, and managed by the `GameStateEngine`. **Always prefer modifying or adding systems here.**

2.  **Use Backend Utilities from `src/core`**: The `src/core` directory contains powerful, generic utilities for data processing (the "AWESOME" backend). Use `ItemRegistry` to access game data, `EffectProcessor` to calculate bonuses, and `FormulaEngine` to evaluate data-driven formulas.

3.  **Data is in JSON**: All game data (items, events, achievements, etc.) is defined in JSON files in the `src/data` directory. Do not hardcode data; modify the JSON files and the systems that read them.

4.  **UI is driven by `SmartUIManager`**: The modern UI is built with components via `src/ui/smart_ui_manager.lua`. When working on UI, prefer this component-based approach.

## DANGER ZONES: What to Avoid

**CRITICAL:** The codebase contains significant legacy code and architectural problems. Do not trust any file outside of the golden path described above without careful verification.

1.  **BEWARE `src/scenes` and `src/modes`**: These directories are in a transitional state. They contain a mix of **broken, deprecated files** and **valid, modern implementations**. For example, `main_menu.lua` is a valid scene that correctly uses `SmartUIManager`. **Do not assume a file here is deprecated.** Instead, verify if it uses modern patterns (`SmartUIManager`, `GameStateEngine`). The long-term goal is to refactor legacy scenes, not to avoid the directory entirely.

2.  **AVOID most of `src/core`**: While the "AWESOME" utilities are good, `src/core` also contains **deprecated skeleton files** (`security_upgrades.lua`, `soc_stats.lua`, `threat_simulation.lua`). Their functionality has been replaced by modules in `src/systems`. Do not use them.

3.  **BEWARE of the "Incident/Crisis/Admin" mess**: The codebase has at least **four** conflicting implementations of an incident-response system. This is a known architectural flaw. Before working on any feature related to incidents, you must first work with the user to consolidate these into a single, canonical system located in `src/systems`.

## Common Tasks

-   **To Add a New Gameplay Feature**: Create a new module in `src/systems`. Ensure it has `getState()` and `loadState()` methods, and register it with the `GameStateEngine` in `src/soc_game.lua`.
-   **To Add a New Item (e.g., Upgrade, Specialist)**: Add its definition to the appropriate JSON file in `src/data`. Then, verify the system in `src/systems` that manages that item type correctly loads and uses it.
-   **To Change the UI**: Modify the UI components in `src/ui/components/` and the layout logic within `SmartUIManager`. Do not add new manual drawing code to scenes.
-   **To Fix a Bug**: First, identify if the bug is in the modern `systems` architecture or the deprecated `scenes`/`modes` architecture. If it's in the deprecated code, inform the user that the best path forward is to refactor that feature into the modern architecture, not to patch the broken legacy code.