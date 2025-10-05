# Core Gameplay Loop Test Plan

**Date**: October 5, 2025  
**Status**: 🔴 In Progress  
**Purpose**: Systematically verify the core gameplay loop works 100% before adding complexity

---

## Executive Summary

The game has grown complex with many systems. Before adding more features, we need to verify the **core gameplay loop** is solid and working as intended. This document defines what the core loop is, what systems support it, and how to test each component.

---

## Core Gameplay Loop Definition

The fundamental loop the player experiences:

```
1. Player has RESOURCES (money, reputation)
   ↓
2. Player accepts a CONTRACT
   ↓
3. CONTRACT generates THREATS/INCIDENTS
   ↓
4. Player RESPONDS to incidents (manually or via specialists)
   ↓
5. Contract completes → Player earns REWARDS
   ↓
6. Player spends rewards on UPGRADES/SPECIALISTS
   ↓
7. Loop repeats with increased capability and difficulty
```

### Core Systems Required

Based on `soc_game.lua` analysis, these systems are ACTIVE and loaded:

**Tier 1 - Critical Path Systems:**
- `ResourceManager` - Manages money, reputation, and other currencies
- `DataManager` - Loads all JSON game data
- `ContractSystem` - Contract acceptance, tracking, completion
- `ThreatSystem` - Spawns and manages threats
- `IncidentSpecialistSystem` - Incident lifecycle and resolution

**Tier 2 - Progression Systems:**
- `UpgradeSystem` - Player upgrades and bonuses
- `SpecialistSystem` - Hiring and managing specialists
- `SkillSystem` - Skill tree progression

**Tier 3 - Supporting Systems:**
- `GameStateEngine` - Save/load and state persistence
- `IdleSystem` - Offline earnings calculation
- `AchievementSystem` - Player achievements

**Systems Currently IGNORED by SystemRegistry:**
- `crisis_system.lua` - ⚠️ BROKEN SYNTAX
- `network_save_system.lua` - Missing dependencies
- `player_system.lua` - Missing dependencies
- `effect_processor.lua`, `formula_engine.lua`, `item_registry.lua` - Utilities, not systems
- `save_system.lua` - Deprecated (replaced by GameStateEngine)
- `soc_stats.lua`, `soc_idle_operations.lua` - Deprecated

---

## Test Strategy

### Phase 1: System Isolation Tests ✅ CURRENT PHASE

Test each core system in complete isolation to verify its contract.

### Phase 2: System Integration Tests

Test how systems communicate via EventBus and direct dependencies.

### Phase 3: Full Gameplay Loop Test

End-to-end test of the complete player experience.

---

## Phase 1: System Isolation Tests

### Test 1.1: ResourceManager ⏳ IN PROGRESS

**File**: `tests/systems/test_resource_manager.lua`

**Test Cases:**
- ✅ Initialize with starting resources
- ✅ Add resources (money, reputation)
- ✅ Subtract resources
- ✅ Check resource bounds (no negatives)
- ❓ Set resource generation rates
- ❓ Calculate passive generation over time
- ❓ State persistence (getState/loadState)

**Current Status:**
- System initializes correctly: ✅
- Warning: Missing getState/loadState methods ⚠️

**Action Items:**
1. Run existing test: `tests/systems/test_resource_manager.lua`
2. Verify all operations work correctly
3. Add getState/loadState methods if missing
4. Document actual resource schema

---

### Test 1.2: DataManager

**File**: `tests/systems/test_data_manager.lua`

**Test Cases:**
- ✅ Load all JSON data files successfully
- ❓ Access loaded data (contracts, threats, upgrades, etc.)
- ❓ Verify data schema consistency
- ❓ Handle missing/malformed data gracefully

**Current Status:**
- Loads 16 data files successfully: ✅
- Warning: Missing getState/loadState (expected - it's a loader) ✅

**Action Items:**
1. Create test to verify data access methods
2. Document canonical JSON schemas for each data type
3. Create schema validation tool

---

### Test 1.3: ContractSystem

**File**: `tests/systems/test_contract_system.lua`

**Test Cases:**
- ❓ Generate available contracts
- ❓ Accept a contract
- ❓ Track active contracts
- ❓ Contract duration and completion
- ❓ Reward calculation and distribution
- ❓ SLA tracking integration
- ❓ State persistence

**Current Status:**
- System initializes: ✅
- Existing test exists: `test_game_mechanics.lua:testContractLifecycle` ✅
- Dependencies: DataManager, UpgradeSystem, SpecialistSystem, ResourceManager

**Action Items:**
1. Extract and enhance contract test from test_game_mechanics
2. Test in complete isolation with mocked dependencies
3. Verify reward distribution actually works
4. Document contract state machine

---

### Test 1.4: ThreatSystem

**File**: `tests/systems/test_threat_system.lua`

**Test Cases:**
- ❓ Spawn threats based on contract
- ❓ Threat difficulty scaling
- ❓ Threat lifecycle (active → resolved → expired)
- ❓ Player interaction (click to resolve?)
- ❓ Specialist auto-resolution
- ❓ State persistence

**Current Status:**
- System initializes: ✅
- Constructor params: `(eventBus, dataManager, specialistSystem, skillSystem)`

**Action Items:**
1. Create isolated threat test
2. Map the actual threat lifecycle
3. Verify how player interacts with threats
4. Document threat → incident relationship

---

### Test 1.5: IncidentSpecialistSystem

**File**: `tests/systems/test_incident_specialist_system.lua`

**Test Cases:**
- ❓ Incident spawning
- ❓ Manual incident resolution
- ❓ Specialist auto-resolution
- ❓ SLA tracking and penalties
- ❓ Reward calculation
- ❓ Integration with ContractSystem
- ❓ State persistence

**Current Status:**
- System initializes: ✅
- Has setContractSystem and setSpecialistSystem methods
- Constructor: `(eventBus, resourceManager)`

**Action Items:**
1. Create isolated incident test
2. Map incident lifecycle states
3. Test SLA integration
4. Verify specialist assignment works
5. Document incident data schema

---

### Test 1.6: UpgradeSystem

**File**: `tests/systems/test_upgrade_system.lua`

**Test Cases:**
- ❓ Load upgrades from data
- ❓ Check upgrade requirements
- ❓ Purchase upgrade (cost deduction)
- ❓ Apply upgrade effects
- ❓ Verify effect calculations
- ❓ Upgrade unlocks/dependencies
- ❓ State persistence

**Current Status:**
- Loads 54 upgrades in 0 trees ⚠️ (Why 0 trees?)
- Missing getState/loadState ⚠️

**Action Items:**
1. Investigate "0 trees" - is this correct?
2. Create upgrade purchase test
3. Verify effects are actually applied via EffectProcessor
4. Add state persistence methods
5. Document upgrade schema

---

### Test 1.7: SpecialistSystem

**File**: `tests/systems/test_specialist_system.lua`

**Test Cases:**
- ❓ Load specialists from data
- ❓ Hire specialist (cost, requirements)
- ❓ Assign specialist to incident
- ❓ Specialist auto-resolution mechanics
- ❓ Specialist leveling/experience
- ❓ State persistence

**Current Status:**
- System initializes: ✅
- Constructor: `(eventBus, dataManager, skillSystem)`

**Action Items:**
1. Create specialist hiring test
2. Test assignment mechanics
3. Verify auto-resolution actually works
4. Document specialist schema

---

### Test 1.8: GameStateEngine

**File**: `tests/systems/test_game_state_engine.lua`

**Test Cases:**
- ❓ Register systems for save/load
- ❓ Quick save
- ❓ Full save
- ❓ Load state from file
- ❓ Handle missing save file
- ❓ Offline earnings calculation

**Current Status:**
- System initializes: ✅
- Loads state successfully: ✅
- Several systems missing getState/loadState ⚠️

**Action Items:**
1. Test save/load cycle
2. Add missing getState/loadState to systems that need persistence
3. Verify offline earnings work correctly

---

## Phase 2: Integration Tests (Not Started)

### Test 2.1: Contract → Incidents → Resolution → Rewards

End-to-end test of a single contract lifecycle with all systems working together.

### Test 2.2: Upgrade Purchase → Effect Application

Verify upgrades actually modify gameplay (e.g., incident resolution speed, earnings multiplier).

### Test 2.3: Specialist Hiring → Auto-Resolution

Verify specialists actually do their job when assigned.

---

## Phase 3: Full Gameplay Loop Test (Not Started)

A complete playthrough scenario testing the entire loop from start to finish.

---

## Known Issues Discovered

1. **Multiple systems missing state persistence**: UpgradeSystem, AchievementSystem, etc.
2. **Upgrade trees showing "0 trees"**: Need to investigate upgrade data structure
3. **EventSystem missing DataManager**: Dependency injection issue
4. **Unclear threat vs. incident distinction**: Need to clarify the relationship
5. **Multiple incident/crisis implementations**: Known architectural debt from copilot-instructions

---

## Success Criteria

Before moving to Phase 2, ALL Phase 1 tests must:
- ✅ Pass without errors
- ✅ Document actual behavior (not assumed behavior)
- ✅ Have state persistence working where needed
- ✅ Have clear schema documentation

---

## Next Steps

1. ✅ Run existing test suite: `love tests/run_mechanics_tests.lua`
2. Create missing isolation tests for each system
3. Fix state persistence warnings
4. Document actual data schemas
5. Move to Phase 2 integration testing
