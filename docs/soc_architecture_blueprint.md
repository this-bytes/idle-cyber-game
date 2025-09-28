# SOC Architecture Blueprint

## Mission Objectives

- Replace fragmented legacy systems with a cohesive Security Operations Centre (SOC) stack that powers the idle consultancy fantasy end-to-end.
- Establish a stats-driven growth loop (Offense, Defense, Detection, Analysis) that feeds resources, contracts, threats, and upgrades in a controlled, data-driven manner.
- Deliver a modular dashboards-first UI that treats the SOC as the primary surface while keeping Love2D-friendly rendering hooks.
- Harden the architecture with explicit dependency injection, deterministic simulation surfaces, and targeted automated tests.

## System Topology

```
FortressGame (entry)
├── EventBus
├── GameLoop (priority orchestration)
├── ResourceManager (primary/secondary resource orchestration)
├── StatsSystem (SOC capability vectors)
├── UpgradeHub
│   ├── SecurityUpgrades (defense-centric catalog)
│   └── OperationsUpgrades (income & efficiency catalog)
├── ContractEngine (renovated contract flow)
├── ThreatSimulation (adaptive adversaries)
├── IdleDirector (deterministic idle/tick orchestration)
├── SOCDashboard (UI Manager v2)
└── TelemetryHub (debug + monitoring hooks)
```

### Dependency Injection Matrix

| System            | Receives                                 | Publishes Events                                       |
|-------------------|------------------------------------------|--------------------------------------------------------|
| ResourceManager   | EventBus                                 | `resource_changed`, `resource_generation_changed`     |
| StatsSystem       | EventBus, ResourceManager                | `stats_changed`, `stat_cap_reached`                    |
| SecurityUpgrades  | EventBus, ResourceManager, StatsSystem   | `upgrade_defined`, `upgrade_purchased`, `stat_bonus`   |
| OperationsUpgrades| EventBus, ResourceManager, StatsSystem   | `operations_bonus`, `automation_unlocked`              |
| ThreatSimulation  | EventBus, StatsSystem, SecurityUpgrades  | `threat_detected`, `threat_completed`, `threat_damage` |
| ContractEngine    | EventBus, ResourceManager, StatsSystem   | `contract_offered`, `contract_completed`               |
| IdleDirector      | EventBus, ResourceManager, StatsSystem   | `idle_tick`, `offline_progress_complete`               |
| SOCDashboard      | EventBus, ResourceManager, StatsSystem   | `ui_action`, `panel_toggled`, `shortcut_pressed`       |
| TelemetryHub      | EventBus, GameLoop                       | `telemetry_sampled`, `anomaly_detected`                |

All fortress systems are created inside `FortressGame:initializeFortressSystems()` and registered with the `GameLoop` using explicit priorities (10–90 range). Legacy adapters are removed; remaining legacy modules integrate exclusively through the event bus.

## Stats System

### Core Stats

- **Offense** – Represents proactive threat hunting/pentesting capability. Boosts mission token yield and increases the chance of uncovering premium contracts. Consumed by threat response abilities.
- **Defense** – Hardens infrastructure. Reduces threat damage and lowers breach probability. Scales multiplicatively with relevant upgrades but is capped by facility tier.
- **Detection** – Determines how quickly threats are surfaced. Directly feeds mitigation progress rate and unlocks higher difficulty contract tiers.
- **Analysis** – Converts threat intel into business insights. Provides passive reputation growth, increases XP conversion, and improves reward modifiers.

### Derived Metrics

- **SOC Rating** – Geometric mean of the four stats. Drives overall contract tier gating and prestige unlocks.
- **Incident Response Speed** – Function of Detection and Offense with diminishing returns.
- **Resilience** (optional expansion) – `Defense * Analysis` synergy used for mega-threat balancing; not required for MVP but scaffolding remains in place.

### Formulas

Let `Sx` denote stat base value, `Mx` multiplier, `Cx` caps.

- `EffectiveStat = min((Sx + Σ upgradeFlat) * (1 + Σ upgradeMultiplier), Cx)`
- `SOC_Rating = (EffectiveOffense * EffectiveDefense * EffectiveDetection * EffectiveAnalysis) ^ 0.25`
- `ThreatMitigationRate = base_rate * (1 + DetectionEff) * (1 + OffenseEff * 0.5)`
- `DamageMitigation = clamp(DefenseEff, 0, 0.95)`
- `RewardMultiplier = 1 + AnalysisEff * 0.3`

Base stats start at 10 with soft caps at 500 (Phase 2 scaling). Caps increase via Facilities/Upgrades. Every stat change publishes `stats_changed` with delta and derived metrics.

### Offline Progress

Stats feed idle calculations via `IdleDirector`:

```
IdleIncome = BaseContractIncome * (1 + AnalysisEff * 0.2)
IdleThreatRisk = BaselineRisk * (1 - DefenseEff)
OfflineCapHours = 8 + floor(DetectionEff / 50)
```

## Upgrade Framework

Split upgrade catalog into two fortress modules for clarity:

1. **SecurityUpgrades** (defense/threat-focused) – existing module refactored to consume StatsSystem and publish stat bonuses rather than direct resource multipliers.
2. **OperationsUpgrades** (economic/automation) – new module that manages revenue, contract automation, facility scaling, and stat caps.

### Upgrade Definition Schema (Lua table driven)

```lua
local upgrade = {
  id = "aiThreatHunting",
  category = "security",
  tier = 3,
  cost = { money = 15000, missionTokens = 3 },
  requirements = {
    stats = { detection = 120 },
    upgrades = { "siem" },
    companyTier = 2
  },
  effects = {
    stats = { detection = { flat = 15, multiplier = 0.1 } },
    threat = { responseSpeed = 0.2 },
    resources = { reputationGeneration = 1.5 }
  }
}
```

Effects are normalized so that ResourceManager, StatsSystem, and ThreatSimulation each own their domains; Upgrade modules only publish events with structured payloads.

## Contract Engine Revamp

- Contracts sourced from `src/data/contracts.json` with new fields: `requiredSOC`, `threatProfile`, `rewardCurve`, `idleWeight`.
- Acceptance flow consults StatsSystem; if stats below requirement, contract is locked with hint.
- Completion uses new formula:
  - `Payout = baseMoney * RewardMultiplier * ContractDifficultyScalar`
  - `ReputationGain = baseRep * (1 + AnalysisEff * 0.4)`
  - `ThreatTriggerChance = baseline - DefenseEff * threatProfile.defenseScalar`

## Idle Director

- Replaces legacy `idle_system.lua` loops.
- Owns deterministic tick accumulator (leveraging `GameLoop` fixed timestep).
- Calculates passive resource gains, triggers contract ticks, and queues threat rolls using StatsSystem + ContractEngine data.
- Supports offline catch-up by simulating up to `OfflineCapHours` with fail-safe clamp and event emission for UI summary.

## SOC Dashboard (UI Manager v2)

### Layout

```
┌─────────────────────────────────────────────────────┐
│ SOC Overview (SOC Rating, Active Alerts, Clock)     │
├───────────────┬───────────────────────┬──────────────┤
│ Stat Matrix    │ Active Operations     │ Threat Queue │
│ (radar chart + │ (contracts, upgrades) │ (scrollable) │
│ spark lines)   │                       │              │
├───────────────┴───────────────────────┴──────────────┤
│ Event Log / Notifications (timeline with filters)   │
└─────────────────────────────────────────────────────┘
```

- Keyboard shortcuts remapped: `Space` toggles pause, `Tab` cycles panels, number keys trigger contextual actions.
- Rendering pipeline consolidated into `src/ui/soc_dashboard.lua`, consumed by `UIManager`.
- Panels respond to `stats_changed`, `contract_offered`, `threat_detected`, `upgrade_purchased` events.
- Supports compact overlay for crisis mode by toggling `UIManager:setLayout("compact")`.

### Visual System

- Use neon cyberpunk palette defined in `UIManager.colors` but add accent shades for stats.
- Introduce small sparkline renderer (simple polyline) for stat trends (captures last N emitted `stats_changed`).

## Telemetry & Monitoring

- `TelemetryHub` subscribes to resource, stats, contract, and threat events, aggregates into ring buffer.
- Exposes `TelemetryHub:getSnapshots()` for debug overlay and dev tooling.
- Hooks into `tests/systems/test_fortress_architecture.lua` to assert that core events fire at least once during integration test.

## Removal / Migration Plan

- **Delete**: `src/systems/resource_system.lua`, `src/systems/upgrade_system.lua`, legacy UI overlays in `src/ui/terminal_theme.lua`, and unused love callbacks.
- **Deprecate**: Idle and admin modes replaced with SOC dashboard + crisis overlay; keep stub adapters until crisis rewrite lands.
- **Migrate Data**: Move upgrade definitions into fortress modules; ensure JSON stays source of truth for contracts/factions.

## Testing Strategy

1. **Unit Tests**
   - `tests/systems/test_stats_system.lua`: stat calculations, caps, event emission.
   - `tests/systems/test_operations_upgrades.lua`: cost validation, effect routing.
   - `tests/systems/test_idle_director.lua`: deterministic tick results, offline catch-up clamps.
2. **Integration Tests**
   - Extend fortress architecture test to instantiate StatsSystem, IdleDirector, SOCDashboard and assert event flow.
3. **UI Snapshot Hooks**
   - Add Love test harness that renders SOC dashboard to an offscreen canvas and checks panel registry (no pixel comparison yet).

## Rollout Phases (per Incident Plan)

1. **Core SOC Overhaul** – Implement StatsSystem, OperationsUpgrades, TelemetryHub; remove critical legacy modules.
2. **Idle & Stat Growth** – Replace idle loops with IdleDirector, wire contract scaling formulas, enforce stat caps.
3. **SOC Dashboard** – Replace UI overlays with dashboard & shortcut map; ensure accessibility toggles stay intact.
4. **Room Interaction Redesign** – Convert rooms to SOC units referencing stats/operations; optional for initial merge but scaffolding included.
5. **Hardening** – Add comprehensive tests, telemetry assertions, and doc updates.

## Data Contracts & APIs

- **StatsSystem API**
  - `stats:get(statName)` → returns effective stat & breakdown
  - `stats:applyModifier(sourceId, payload)` → registers modifier (flat/mult)
  - `stats:removeModifier(sourceId)` → clean removal on upgrade sell / temporary buff expire
  - `stats:getDerived()` → returns SOC_Rating, mitigation rates, reward multiplier

- **Upgrade Modules API**
  - `upgrades:getAvailable(category)` → filtered and costed list
  - `upgrades:purchase(id)` → validates cost, applies modifiers via events
  - `upgrades:getOwned()` → for UI display

- **IdleDirector API**
  - `idle:initializeOfflineProgress(timestamp)`
  - `idle:update(dt)` – consumes GameLoop fixed timestep
  - `idle:getSummary()` – returns last tick summary for UI log

- **SOCDashboard API**
  - `dashboard:setLayout(mode)` – `full`, `compact`, `crisis`
  - `dashboard:draw()` – Love draw hook invoked by `UIManager`
  - `dashboard:handleInput(action)` – keyboard/mouse mapping decoupled from Love events

## Next Steps

- Implement StatsSystem + OperationsUpgrades modules under `src/core/`.
- Refactor `FortressGame` initialization to construct the new modules and register them with the GameLoop.
- Begin migrating IdleSystem responsibilities into `IdleDirector`, leaving adapters for crisis mode until Phase 3.
- Replace HUD rendering in `UIManager` with SOC Dashboard integration.
- Update `ARCHITECTURE.md` to reflect the new fortress-centric SOC layout once implementation lands.
