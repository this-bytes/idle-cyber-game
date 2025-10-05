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
  - **`SLASystem` (Phase 1)**: Service Level Agreement tracking for contracts. Monitors incident counts, breach rates, and calculates compliance scores with rewards/penalties.
  - **`IncidentSpecialistSystem` (Phase 2)**: Three-stage incident lifecycle management (Detect → Respond → Resolve). Handles specialist assignments, stage progression, and SLA tracking per stage.
  - **`GlobalStatsSystem` (Phase 3)**: Company-wide performance metrics and analytics. Tracks contracts, specialists, incidents, milestones, and manual assignment statistics.

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

## SOC Simulation Enhancement (Phases 1-5)

A comprehensive 5-phase enhancement project was completed to add sophisticated Service Level Agreement (SLA) tracking, incident lifecycle management, and performance analytics to the game.

### Phase 1: Core SLA System

**Implementation**: `src/systems/sla_system.lua`

**Features**:
- SLA tracking per contract with compliance scoring
- Event-driven integration (contract events)
- Incident recording and breach detection
- Reward/penalty calculation based on performance
- Overall metrics tracking (compliance rate, rewards, penalties)
- Configuration loading from JSON (`src/data/sla_config.json`)
- State persistence
- Compliance rating system (EXCELLENT, GOOD, ACCEPTABLE, POOR, CRITICAL)

**Contract System Enhancements**:
- Dynamic capacity calculation (1 contract per 3 specialists)
- Efficiency multiplier based on specialist levels
- Performance degradation when over capacity
- Capacity validation before accepting contracts
- Zero specialist guard with helpful error messages

### Phase 2: Three-Stage Incident Lifecycle

**Implementation**: Enhanced `src/systems/incident_specialist_system.lua`

**Features**:
- Three-stage incident progression: Detect → Respond → Resolve
- Stage tracking with status, timing, and SLA limits
- Specialist assignment per stage
- Automatic stage advancement based on progress
- Per-stage SLA compliance tracking
- Event publication for stage transitions
- Division by zero guards in progress calculations

**Stage Requirements**:
- **Detect Stage**: Requires "trace" stat from specialists
- **Respond Stage**: Requires "speed" stat from specialists
- **Resolve Stage**: Requires "efficiency" stat from specialists

### Phase 3: Global Statistics System

**Implementation**: `src/systems/global_stats_system.lua`

**Features**:
- Company-wide performance tracking
- Contract metrics (completed, failed, revenue, SLA compliance, streaks)
- Specialist metrics (hired, active, levels, efficiency, XP)
- Incident metrics (generated, resolved, resolution times)
- Performance indicators (SLA compliance, workload status, efficiency rating)
- Automatic milestone unlocking system
- Manual assignment tracking
- Real-time dashboard data API

**Milestones**:
- First Contract Completed
- 10 Contracts Completed
- 100 Incidents Resolved
- 10 Specialists Hired
- $1M Revenue Earned
- Perfect Contract (100% SLA compliance)

### Phase 4: Enhanced Admin Mode

**Implementation**: `src/scenes/admin_mode_enhanced_luis.lua`

**Features**:
- Performance dashboard with real-time metrics
- Active incidents list with progress indicators
- Specialists panel with workload visualization
- Manual specialist assignment workflow
- Color-coded workload status (OPTIMAL, HIGH, CRITICAL, OVERLOADED)
- Event-driven UI updates
- Integration with GlobalStatsSystem

**Manual Assignment**:
- Allows tactical specialist deployment to specific incident stages
- Tracks manual vs automatic assignments separately
- Updates specialist workload indicators in real-time
- Validates assignments to prevent conflicts

### Phase 5: Integration, Testing, and Polish

**Implementation**: Production-ready quality improvements

**Features**:
- Comprehensive integration test suite (`tests/integration/test_phase5_integration.lua`)
- Critical bug fixes:
  - Zero specialists guard in contract acceptance
  - Division by zero guards in progress calculations
  - Manual assignment to completed incidents prevention
  - SLA tracker memory leak prevention (keeps last 100)
- Balance improvements:
  - Capacity formula: 1 per 3 specialists (was 1 per 5)
  - More forgiving for early game
  - Ensures minimum 1 capacity when specialists exist
- Improved error messages with user-friendly feedback

### Event Flow Example

```
Contract Accepted
    ↓
SLASystem: Initialize tracker
    ↓
Incident Generated (for contract)
    ↓
IncidentSpecialistSystem: Create 3-stage incident
    ↓
Stage 1: Detect (auto-assign specialists)
    ↓
Progress calculated based on specialist stats
    ↓
Stage completed → Event published
    ↓
SLASystem: Record stage completion time
    ↓
Stage 2: Respond (auto or manual assign)
    ↓
... (repeat for Resolve stage)
    ↓
Incident fully resolved
    ↓
GlobalStatsSystem: Update metrics
    ↓
Contract Completed
    ↓
SLASystem: Calculate compliance, apply rewards/penalties
    ↓
GlobalStatsSystem: Check milestones
```

### Data Flow

```
JSON Data (contracts.json, sla_config.json)
    ↓
DataManager → Systems
    ↓
SLASystem ←→ EventBus ←→ ContractSystem
    ↓                        ↓
IncidentSpecialistSystem ←→ SpecialistSystem
    ↓
GlobalStatsSystem (aggregates all events)
    ↓
UI (Admin Mode, Debug Overlay)
```

### Performance Characteristics

- **SLA Tracker Memory**: Keeps only last 100 completed trackers
- **GlobalStatsSystem Update**: <0.1ms per update (tested with 100 iterations)
- **Event Bus**: O(n) where n = number of subscribers per event
- **Incident Processing**: O(m) where m = number of active incidents
- **Target**: 60 FPS with 100+ concurrent incidents

### Testing

All phases have comprehensive test coverage:
- Unit tests for individual system methods
- Integration tests for cross-system workflows
- Performance benchmarks
- Edge case validation

See `tests/integration/test_phase5_integration.lua` for the complete test suite.

### Configuration

Balance and behavior can be tuned via JSON files:
- `src/data/sla_config.json`: SLA thresholds, penalties, rewards
- `src/data/contracts.json`: Contract SLA requirements and rewards
- No code changes required for balance adjustments

### Future Enhancements

Potential improvements for future phases:
- Real-time SLA status visualization in main UI
- Historical performance graphs and trends
- Specialist specialization bonuses for specific incident types
- Dynamic difficulty scaling based on performance
- Team composition synergies
