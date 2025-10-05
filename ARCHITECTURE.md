# Architecture Documentation

## High-Level Overview

The game follows a modern, decoupled architecture centered around a main **GameStateEngine**. This engine is responsible for managing a collection of independent **Systems**, which encapsulate all major gameplay logic (e.g., contracts, specialists, achievements).

Communication between systems is handled via an **EventBus**, preventing tight coupling and allowing for flexible extension. A suite of powerful backend utilities, referred to as the "AWESOME" backend, provides data management and processing capabilities to all systems.

## Core Architecture Layers

### 1. Game State Engine (`src/systems/game_state_engine.lua`)

This is the heart of the application.
- **Responsibilities**: Manages the overall game state, including loading, saving, and auto-saving. It orchestrates the game loop by calling the `update()` method on all registered systems.
- **State Management**: It gathers state from all registered systems via a `getState()` method and re-hydrates them via `loadState()`. This provides robust and centralized persistence.
- **Offline Progress**: It calculates offline time and calls the `IdleSystem` to determine and apply offline earnings.

### 2. Gameplay Systems (`src/systems/`)

This directory contains the "true" implementation of the game's core features. Each system is a self-contained module responsible for a specific domain.

- **Key Systems**:
  - `ContractSystem`: Manages the lifecycle of contracts, the primary income source.
  - `SpecialistSystem`: Manages the hiring and progression of specialists.
  - `UpgradeSystem`: Manages the purchase and effects of permanent upgrades.
  - `AchievementSystem`: Tracks and unlocks achievements based on game events.
  - `EventSystem`: Triggers random, weighted dynamic events.
  - `IdleSystem`: Calculates passive resource generation.
  - `ProgressionSystem`: Manages player progression, tiers, and prestige mechanics.
  - `SkillSystem`: Manages the skill trees for specialists.
  - `ThreatSystem`: Manages the generation and resolution of security threats.

### 3. "AWESOME" Backend Utilities (`src/core/`)

This is a collection of powerful, generic utilities that support the gameplay systems.

- **`ItemRegistry`**: Loads and indexes all game data (upgrades, threats, etc.) from JSON files, providing a single source of truth.
- **`EffectProcessor`**: Calculates the combined result of various status effects (e.g., multipliers from different upgrades and specialist skills).
- **`FormulaEngine`**: Safely evaluates mathematical formulas defined in JSON data.
- **`SynergyDetector`**: Detects combinations of active items, specialists, and upgrades to grant bonus effects.
- **`AnalyticsCollector`**: Tracks game events for local-only analytics.

### 4. UI Layer (`src/scenes/` and `src/ui/`)

The UI architecture is currently undergoing a major refactor to use community-maintained libraries.

#### Current State (October 2025)
- **`SceneryAdapter`**: Wraps the Scenery scene management library, providing backward compatibility with existing scenes.
- **`LovelyToastWrapper`**: Integrates the Lovely-Toasts notification library while maintaining the old ToastManager API.
- **`LUIS`**: Component-based UI system, migrated to LUIS (Love UI System).
- **Scenes**: All existing scenes work with the new SceneryAdapter without modification.

#### Migration Status
- ✅ **Toast System**: Migrated to Lovely-Toasts (via wrapper)
- ✅ **Scene Management**: Migrated to Scenery (via adapter)
- ✅ **UI Components**: LUIS integration completed

See `docs/COMMUNITY_UI_INTEGRATION_SUMMARY.md` and `docs/UI_REFACTOR_MIGRATION.md` for complete details.

## Known Architectural Issues & Refactor Roadmap

The codebase contains several critical issues that must be addressed.

1.  **Redundant and Conflicting "Incident" Systems**: The codebase previously contained multiple implementations of a crisis/incident/admin mode (`modes/admin_mode.lua`, `scenes/admin_mode.lua`, `scenes/incident_response.lua`, `systems/crisis_system.lua`).
    -   **Status**: Resolved. The project now uses a single canonical implementation: `src/systems/incident_specialist_system.lua`.
    -   **Action Taken**: Duplicate legacy files have been removed and the canonical system is registered with the `GameStateEngine`. See `docs/INCIDENT_REFACTOR.md` for details.

2.  **UI Architecture Migration**: The UI layer is being migrated to community-maintained libraries.
    -   **Status**: In Progress (October 2025).
    -   **Completed**: Toast system (Lovely-Toasts), Scene management (Scenery).
    -   **Pending**: LUIS UI framework integration for components.
    -   **Action**: See `docs/COMMUNITY_UI_INTEGRATION_SUMMARY.md` for status and migration guide.

3.  **Deprecated `src/core` Skeletons**: The `src/core` directory contains several skeleton files (`security_upgrades.lua`, `soc_stats.lua`, `threat_simulation.lua`) whose logic has been superseded by modules in `src/systems`.
    -   **Action**: These files should be deleted. The documentation for the "Fortress Architecture," which described these files, was inaccurate and has been removed.

4.  **Deprecated UI Managers**: The following files are deprecated and will be removed after LUIS migration completes:
    -   `src/ui/toast_manager.lua` - Replaced by Lovely-Toasts
    -   `src/scenes/scene_manager.lua` - Replaced by Scenery
