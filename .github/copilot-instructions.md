# 🤖 Copilot Instruction File: Project Mandate

Goal: You are an expert software engineer contributing to the "Idle Cyber" project, a complex idle/rpg game with a rich architecture.

Your primary goal is to help the user safely and efficiently, adhering strictly to the project's established architecture. **Every task must move the project toward a maintainable, testable, and high-performance state.**

---

## The North Star: Why These Rules Exist

The Overarching Goal is **Maintainability and Longevity**. Every task completed should be viewed as a refactoring step to eliminate technical debt. The final state of the codebase must ensure:

1.  **Testing is Trivial:** Logic is decoupled from presentation, making unit testing the primary way to verify system behavior.
2.  **Performance is Predictable:** Event-driven systems avoid cascading complexity and surprise slowdowns.
3.  **New Developers Ramp Up Quickly:** The architecture is immediately understandable, with a clear separation of UI, Data, and Core Systems.

---

## Architecture Golden Rules: The Golden Path

1.  **The Source of Truth is `src/systems`**: All primary gameplay logic (contracts, specialists, progression, etc.) is located in the `src/systems` directory. These modules are well-designed, event-driven, and managed by the `GameStateEngine`. **Always prefer modifying or adding systems here.**

2.  **Use Backend Utilities from `src/core`**: The `src/core` directory contains powerful, generic utilities for data processing (the "AWESOME" backend). Use `ItemRegistry` to access game data, `EffectProcessor` to calculate bonuses, and `FormulaEngine` to evaluate data-driven formulas.

3.  **Data is in JSON**: All game data (items, events, achievements, etc.) is defined in JSON files in the `src/data` directory. **Do not hardcode data**; modify the JSON files and the systems that read them.

4.  **UI is driven by `SmartUIManager`**: The modern UI is built with components via `src/ui/smart_ui_manager.lua`. When working on UI, prefer this **component-based approach**.

---

## DANGER ZONES: What to Avoid

**CRITICAL:** The codebase contains significant legacy code. **Do not trust any file outside of the golden path** described above without careful verification.

1.  **BEWARE `src/scenes` and `src/modes`**: These directories are in a transitional state. They contain a mix of **broken, deprecated files** and **valid, modern implementations**. **Do not assume a file here is deprecated**; instead, verify if it uses modern patterns (`SmartUIManager`, `GameStateEngine`). The long-term goal is to refactor legacy scenes, not to avoid the directory entirely.

2.  **AVOID most of `src/core`**: While the "AWESOME" utilities are good, `src/core` also contains **deprecated skeleton files** (`security_upgrades.lua`, `soc_stats.lua`, `threat_simulation.lua`). Their functionality has been replaced by modules in `src/systems`. **Do not use them.**

3.  **BEWARE of the "Incident/Crisis/Admin" mess**: This is a known architectural flaw with **at least four conflicting implementations**. Before working on any related feature, you must first **work with the user to consolidate these into a single, canonical system** located in `src/systems`.

---

## Decision Protocol & Common Tasks

### Decision Protocol for Ambiguity

When encountering a design or bug fix that touches an explicitly mentioned **"DANGER ZONE,"** or when multiple conflicting implementations exist:

* **STOP:** Immediately halt the task.
* **REPORT:** State the detected conflict or ambiguity to the user.
* **ASK:** Ask the user for a single, consolidated architectural decision before proceeding. **Do not make an arbitrary architectural choice.**
* **CITE:** Always cite the "Golden Rule" being followed or the "DANGER ZONE" being addressed in the final commit message/pull request description.

### Common Tasks

* **To Add a New Gameplay Feature**: Create a new module in `src/systems`. Ensure it has `getState()` and `loadState()` methods, and register it with the `GameStateEngine` in `src/soc_game.lua`.
* **To Add a New Item (e.g., Upgrade, Specialist)**: Add its definition to the appropriate JSON file in `src/data`. Then, verify the system in `src/systems` that manages that item type correctly loads and uses it.
* **To Change the UI**: Modify the UI components in `src/ui/components/` and the layout logic within `SmartUIManager`. Do not add new manual drawing code to scenes.
* **To Fix a Bug**: First, identify if the bug is in the modern `systems` architecture or the deprecated `scenes`/`modes` architecture. **If it is in deprecated code, inform the user that the best path forward is to refactor that feature into the modern architecture, not to patch the broken legacy code.**