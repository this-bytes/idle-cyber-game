# Legacy Code Removal Analysis
**Date**: October 1, 2025  
**Purpose**: Identify and remove legacy code and outdated documentation to streamline development

## Analysis Summary

Based on the comprehensive project instruction files in `.github/copilot-instructions/`, particularly `11-technical-architecture.instructions.md`, the project has:

1. **Modern "game" Architecture** (KEEP) - Production-ready systems in `src/core/`
2. **Legacy Architecture** (REMOVE) - Deprecated systems marked for removal
3. **Scattered Documentation** (CONSOLIDATE) - Many root-level .md files that duplicate or contradict the canonical instruction files

## Items to REMOVE

### 1. Legacy Source Code

#### src/legacy/ Directory (REMOVE ENTIRE DIRECTORY)
```
src/legacy/zone_system.lua
src/legacy/room_event_system.lua
src/legacy/particle_system.lua
src/legacy/README.md
src/legacy/room_system.lua
src/legacy/crisis_game_system.lua
src/legacy/network_save_system.lua
src/legacy/sound_system.lua
```
**Rationale**: The architecture document explicitly states "Legacy Architecture (Cool concepts to be migrated and then deprecated and removed)". These files are in a dedicated legacy folder and should be removed.

#### Duplicate Legacy Systems in src/systems/ (Evaluate/Remove)
The following systems in `src/systems/` are listed as legacy in the architecture doc:
- `resource_system.lua` - Legacy resource handling (replaced by `src/core/resource_manager.lua`)
- Note: Other systems (contract_system, specialist_system, skill_system, etc.) are noted as "integrated with game ResourceManager" so they should be evaluated individually

### 2. Outdated Root-Level Documentation (REMOVE)

The canonical documentation is in `.github/copilot-instructions/*.instructions.md`. The following root-level files are development notes that are outdated or superseded:

**Remove These Root-Level .md Files**:
- `API_INTEGRATION_GUIDE.md` - Development note, not part of canonical instructions
- `ARCHITECTURE.md` - Superseded by `.github/copilot-instructions/11-technical-architecture.instructions.md`
- `DEV_PLAN.md` - Superseded by `.github/copilot-instructions/12-development-roadmap.instructions.md`
- `DYNAMIC_EVENTS.md` - Superseded by `.github/copilot-instructions/06-events-encounters.instructions.md`
- `GAME_USAGE.md` - Development note, unclear current status
- `IDLE_MECHANICS.md` - Superseded by `.github/copilot-instructions/03-core-mechanics.instructions.md`
- `IMPLEMENTATION_FINAL_SUMMARY.md` - Implementation note, should be archived or removed
- `IMPLEMENTATION_SUMMARY.md` - Implementation note, should be archived or removed
- `MIGRATION_ANALYSIS.md` - Migration is complete per architecture doc
- `SKILL_INTEGRATION_PLAN.md` - Implementation planning doc, outdated
- `SKILL_SYSTEM.md` - Superseded by instruction files
- `SMART_UI_INTEGRATION_COMPLETE.md` - Implementation note, outdated
- `TODO.md` - Unmaintained, use GitHub issues instead
- `feature_summary.txt` - Development note

**Keep These Root-Level Files**:
- `README.md` - Main project README (but should be updated to reference .github/copilot-instructions/)
- `CONTRIBUTING.md` - Contribution guidelines (verify it references correct docs)
- `TESTING.md` - Testing documentation (verify it's current)
- `LICENSE` - Legal requirement

### 3. Demo/Test Files (Evaluate)

**Likely Remove**:
- `demo_ui.lua` - Demo file, not part of main game
- `demo_ui_conf.lua` - Demo config
- `integration_demo.lua` - Integration demo
- `integration_demo_conf.lua` - Integration demo config
- `integration_demo_dir/` - Entire demo directory
- `run_api_test.lua` - Test runner, check if still used
- `api.lua` - Check if this is used or legacy

### 4. Documentation in docs/ Directory (Evaluate)

Many files in `docs/` appear to be implementation notes rather than current documentation:
- `BACKEND_TRANSFORMATION_SUMMARY.md` - Implementation summary
- `BACKEND_VISION.md` - Vision doc, may be superseded
- `UI_IMPLEMENTATION_SUMMARY.md` - Implementation summary
- `AWESOME_BACKEND_README.md` - Backend-specific, check if current
- `BACKEND_IMPLEMENTATION_GUIDE.md` - May be superseded

**Potentially Keep**:
- `DOCUMENTATION_INDEX.md` - If it's current and accurate
- `QUICK_REFERENCE.md` - If current
- `SMART_UI_FRAMEWORK.md` - If this is current documentation
- `SMART_UI_QUICK_REFERENCE.md` - If current
- `ARCHITECTURE_DIAGRAMS.md` - If diagrams are current

### 5. Orphaned Test Files

**Check and Remove if Obsolete**:
- `tests/systems/test_fortress_integration.lua` - References `fortress_game` which may not exist
- Any other test files testing removed legacy systems

### 6. Unused Entry Points/Config Files

**Evaluate**:
- `api.lua` - Check if used
- Multiple conf.lua files (demo_ui_conf.lua, integration_demo_conf.lua)

## Items to KEEP (Modern Architecture)

### Core Game Architecture (src/core/)
✅ `game.lua` - Central game controller  
✅ `game_loop.lua` - System orchestration  
✅ `resource_manager.lua` - Modern resource handling  
✅ `security_upgrades.lua` - Upgrade system  
✅ `threat_simulation.lua` - Threat engine  
✅ `ui_manager.lua` - Modern UI system  
✅ `data_manager.lua` - Data handling  
✅ `soc_stats.lua` - Statistics tracking  

### Game Modes (src/modes/)
✅ `idle_mode.lua` - Passive gameplay  
✅ `admin_mode.lua` - Active gameplay  
⚠️ `enhanced_idle_mode.lua` - Verify if this is current or legacy

### Main Game Files
✅ `main.lua` - Current entry point  
✅ `src/soc_game.lua` - Main game object  
✅ `src/idle_game.lua` - Idle game logic  
✅ `conf.lua` - LÖVE configuration  

### Canonical Documentation (.github/copilot-instructions/)
✅ All .instructions.md files - These are the source of truth

### Data Files (src/data/)
✅ All JSON data files  
✅ Configuration files  

### Integrated Systems (src/systems/)
Evaluate individually - many integrate with modern architecture:
- `contract_system.lua` - Integrates with ResourceManager
- `specialist_system.lua` - Integrates with game
- `skill_system.lua` - Skill progression
- `location_system.lua` - Location management
- `progression_system.lua` - Progression tracking
- `idle_system.lua` - Offline progress
- `achievement_system.lua` - Achievements
- Others require individual evaluation

## Removal Plan

### Phase 1: Safe Removals (Low Risk)
1. Remove `src/legacy/` directory entirely
2. Remove outdated root-level .md files
3. Remove demo files (demo_ui.*, integration_demo.*)
4. Remove implementation summary files

### Phase 2: Test and Remove (Medium Risk)
1. Identify and remove obsolete test files
2. Remove `resource_system.lua` if fully replaced by ResourceManager
3. Clean up docs/ directory

### Phase 3: Verification (Post-Removal)
1. Run full test suite: `lua5.3 tests/test_runner.lua`
2. Verify game launches: `love .`
3. Update README.md to point to canonical instructions
4. Update CONTRIBUTING.md if needed
5. Create archive branch with removed content if needed

## Recommendations

1. **Create Archive Branch**: Before removal, create `archive/legacy-code` branch
2. **Update README**: Point to `.github/copilot-instructions/` as canonical docs
3. **Consolidate Documentation**: Move any useful content from removed docs into instruction files
4. **Test Thoroughly**: Run all tests after each phase
5. **Git History**: Use clear commit messages referencing this analysis
