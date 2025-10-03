# Testing Framework

## Overview

The Idle Cyber Game has a comprehensive testing framework that validates game mechanics without requiring the LÖVE GUI. This allows for fast, automated testing of core gameplay systems.

## Test Suites

### 1. Comprehensive Mechanics Tests ⭐ **[PRIMARY]**
- **Command**: `/usr/bin/lua tests/run_mechanics_tests.lua`
- **Location**: `tests/test_game_mechanics.lua`
- **Purpose**: Validate all four core game pillars (Idle, Tycoon, RPG, RTS)
- **Tests**:
  - ✅ Idle income generation over time
  - ✅ Contract lifecycle (generation, acceptance, completion)
  - ✅ Specialist progression (XP, leveling, skills)
  - ✅ Threat generation and resolution
  - ✅ Incident system integration
  - ✅ Resource flow integrity
  - ✅ Upgrade purchase mechanics
- **Status**: **ALL TESTS PASSING** ✅
- **Documentation**: See [Testing Framework Guide](docs/TESTING_FRAMEWORK.md)

### 2. Integration Tests (`./dev.sh test`)
- **Location**: `tests/integration/`
- **Purpose**: Test system integration and interactions
- **Tests**:
  - Scene transitions
  - Damage calculations with JSON data
  - Input system delegation
  - Gameplay loop integration
- **Status**: All passing

### 3. Behavior Tests (`./dev.sh behavior`)
- **Location**: `tests/test_behavior.lua`
- **Purpose**: Verify game logic without LÖVE
- **Tests**:
  - Data-driven damage calculation
  - Event flow (threat → scene change)
  - Specialist cooldown mechanics
- **Status**: All passing

### 4. Run All Tests (`./dev.sh test-all`)
- Runs integration tests and behavior tests
- Does NOT include comprehensive mechanics tests (run separately)

## Quick Start

### Run Comprehensive Mechanics Validation
```bash
/usr/bin/lua tests/run_mechanics_tests.lua
```

### Run All Dev Suite Tests
```bash
./dev.sh test-all
```

### Run Specific Test Suite
```bash
./dev.sh test      # Integration tests
./dev.sh behavior  # Behavior tests
```

## Test Coverage

### ✅ Fully Validated
- Idle income generation and passive gameplay
- Contract system (generation, acceptance, completion, rewards)
- Specialist progression (XP gain, leveling, skill unlocking)
- Threat system (generation from templates, resolution, rewards)
- Resource management (adding, spending, boundary enforcement)
- Upgrade purchasing and effects
- System integration and event flow

### ⚠️ Partial Coverage
- Save/load persistence
- Achievement unlocking
- Faction reputation mechanics
- UI rendering and interaction

### ❌ Not Yet Tested
- Performance under load
- Network save/sync
- Complex synergy calculations
- Edge cases in event chains

## Benefits

1. **Validates Core Mechanics**: Tests verify that the game WORKS, not just compiles
2. **Fast Feedback**: Headless tests run in seconds
3. **Regression Prevention**: Automated validation catches breaking changes
4. **Confidence**: Developers can refactor knowing tests will catch issues
5. **Documentation**: Tests serve as executable specifications

## Usage

```bash
# Run behavior tests before making changes
./dev.sh behavior

# Make your changes to src/

# Run tests again to verify nothing broke
./dev.sh behavior

# Run all tests before committing
./dev.sh test-all
```

## Future Improvements

- Add more behavior tests for:
  - Contract system
  - Upgrade system
  - Skill progression
  - Save/load functionality
- Create visual test reports
- Add performance benchmarks
- Integrate with CI/CD pipeline
