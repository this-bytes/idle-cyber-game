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

The UI is in a transitional state and is the area most in need of refactoring.

- **`SmartUIManager`**: The modern, intended UI architecture. It uses a component-based system to build reusable UI elements. This is the correct path forward.
- **Legacy Scenes**: Many scenes (`soc_view.lua`, `upgrade_shop.lua`) contain large amounts of manual `love.graphics` drawing calls. This is the legacy approach and should be refactored to use the `SmartUIManager`.
- **`SceneManager`**: A clean, effective manager that handles transitions between different game scenes.

## Known Architectural Issues & Refactor Roadmap

The codebase contains several critical issues that must be addressed.

1.  **Redundant and Conflicting "Incident" Systems**: The codebase contains at least **four** different implementations of a crisis/incident/admin mode (`modes/admin_mode.lua`, `scenes/admin_mode.lua`, `scenes/incident_response.lua`, `systems/crisis_system.lua`).
    -   **Action**: This is the highest priority architectural issue. A single, canonical implementation must be chosen, and the other three must be deleted to resolve the confusion.

2.  **Broken UI Scenes**: The primary UI scenes are non-functional due to critical bugs.
    -   `modes/idle_mode.lua`: Has duplicate functions (`enter`, `mousepressed`) that break initialization and input.
    -   `scenes/soc_view.lua`: Has duplicate functions and a mix of two incompatible UI rendering strategies that leaves most of the code dead.
    -   **Action**: These files must be fixed and refactored to use a single, consistent UI strategy, preferably the `SmartUIManager`.

3.  **Deprecated `src/core` Skeletons**: The `src/core` directory contains several skeleton files (`security_upgrades.lua`, `soc_stats.lua`, `threat_simulation.lua`) whose logic has been superseded by modules in `src/systems`.
    -   **Action**: These files should be deleted. The documentation for the "Fortress Architecture," which described these files, was inaccurate and has been removed.
