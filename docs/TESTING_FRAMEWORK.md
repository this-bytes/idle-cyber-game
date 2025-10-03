# Testing Framework Documentation

## Overview

This document describes the comprehensive testing framework for the Idle Cyber Game. The framework validates all core game mechanics (idle, tycoon, RPG, RTS) in a headless environment without requiring LÖVE GUI dependencies.

## Test Architecture

### Headless Execution

Tests run in pure Lua without LÖVE's graphical interface, using mock implementations of LÖVE APIs:

- **Mock Location**: `tests/headless_mock.lua`
- **Mocked APIs**: `love.filesystem`, `love.timer`, `love.graphics`
- **Execution**: Via standard Lua interpreter (`/usr/bin/lua`)

### Test Runner

**File**: `tests/run_mechanics_tests.lua`

The runner:
1. Initializes LÖVE mocks before loading game code
2. Executes all test methods in the test suite
3. Reports pass/fail status with detailed output
4. Returns appropriate exit codes (0 = success, 1 = failure)

### Comprehensive Test Suite

**File**: `tests/test_game_mechanics.lua`

Tests validate all four core game pillars:

#### 1. Idle Mechanics (`testIdleIncomeGeneration`)
- Validates passive resource generation over time
- Simulates 60 seconds of idle play
- Verifies money increases according to generation rate

#### 2. Tycoon Mechanics (`testContractLifecycle`)
- Tests contract generation (time-based spawning)
- Validates contract acceptance and assignment
- Verifies contract completion and reward payout
- Tests specialist XP gain from contracts

#### 3. RPG Mechanics (`testSpecialistProgression`)
- Validates XP awarding to specialists
- Tests level-up mechanics and stat increases
- Verifies skill unlocking system

#### 4. RTS Mechanics (`testThreatResolution`)
- Tests threat generation from template pool
- Validates specialist assignment to threats
- Verifies threat resolution and reward distribution

#### 5. Integration Tests
- `testIncidentSystem`: Validates IncidentSpecialistSystem
- `testResourceFlow`: Tests resource addition/spending/bounds
- `testUpgradeSystem`: Validates upgrade purchase mechanics

## Running Tests

### Command Line

```bash
# Run all mechanics tests
/usr/bin/lua tests/run_mechanics_tests.lua

# Or use the convenience script
./test_game_state.sh
```

### Expected Output

```
======================================================================
🚀 COMPREHENSIVE GAME MECHANICS TEST SUITE
======================================================================
[System initialization messages...]

🧪 Test: Idle Income Generation Over Time
   ✅ Generated $12360 over 60 seconds
   ✅ Money increased from $20000 to $32360

🧪 Test: Contract Lifecycle (Tycoon Mechanic)
   ✅ Generated 2 available contracts
   ✅ Accepted contract: [Contract Name]
   ✅ Contract completed, earned $[Amount]

[... more test output ...]

======================================================================
📊 RESULTS: 7 passed, 0 failed
======================================================================
```

## Key Testing Patterns

### System Setup

Each test suite instance:
1. Creates isolated EventBus
2. Initializes DataManager with JSON data
3. Creates all required game systems
4. Initializes systems in correct dependency order
5. Sets up starting resources

```lua
function GameMechanicsTest:setUp()
    self.eventBus = EventBus:new()
    self.systems = {}
    
    -- Initialize core systems
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()
    
    self.systems.resourceManager = ResourceManager.new(self.eventBus)
    -- ... more system initialization
    
    -- Initialize systems in correct order
    self.systems.specialistSystem:initialize()
    self.systems.contractSystem:initialize()
    self.systems.threatSystem:initialize()
    self.systems.incidentSystem:initialize()
end
```

### Time Simulation

Tests simulate time passage by calling `update(dt)` with large delta values:

```lua
-- Simulate 60 seconds for idle income
self.systems.idleSystem:update(60)

-- Simulate 11 seconds to trigger contract generation
self.systems.contractSystem:update(11)
```

### Test Isolation

Important considerations:
- Disable auto-accept features when testing manual actions
- Use deterministic actions (direct method calls) over time-based events
- Reset system state between tests if needed

## Mock Implementation Details

### Filesystem Mock

The `love.filesystem` mock provides:
- `getInfo(path)`: Uses Lua `io.open()` to check file existence
- `read(path)`: Reads file content using standard Lua I/O
- `write(path, content)`: Writes files using standard Lua I/O
- `getDirectoryItems(dir)`: Uses shell `ls` command to list directories

### Timer Mock

The `love.timer` mock provides:
- `getTime()`: Uses `os.clock()` for elapsed time
- `getFPS()`: Returns constant 60 FPS

### Graphics Mock

The `love.graphics` mock provides:
- No-op implementations for drawing functions
- Basic font width calculations
- Default window dimensions (1024x768)

## Test Coverage

### Currently Tested
✅ Idle income generation  
✅ Contract lifecycle (generation, acceptance, completion)  
✅ Specialist leveling and XP  
✅ Threat generation and resolution  
✅ Resource management (add/spend/bounds)  
✅ Upgrade purchasing  
✅ IncidentSpecialistSystem integration  

### Not Yet Tested
⚠️ Event system edge cases  
⚠️ Save/load persistence  
⚠️ UI rendering and interaction  
⚠️ Achievement unlocking  
⚠️ Faction reputation  
⚠️ Complex synergy calculations  

## Extending the Test Suite

### Adding New Tests

1. Add test method to `GameMechanicsTest` class:

```lua
function GameMechanicsTest:testMyNewFeature()
    print("\n🧪 Test: My New Feature")
    
    -- Setup test conditions
    -- Execute feature
    -- Assert expected outcomes
    
    assert(condition, "❌ Error message")
    print("   ✅ Success message")
end
```

2. Register test in `runAll()` method:

```lua
function GameMechanicsTest:runAll()
    self:runTest(self.testIdleIncomeGeneration)
    self:runTest(self.testContractLifecycle)
    -- ... existing tests
    self:runTest(self.testMyNewFeature)  -- Add here
end
```

### Mock Extension

If new LÖVE APIs are needed:

1. Add mock implementation to `tests/headless_mock.lua`
2. Export via returned table
3. Document mock behavior

## Troubleshooting

### Common Issues

**Problem**: `attempt to index field 'filesystem' (a nil value)`  
**Solution**: Ensure `headless_mock.lua` is loaded BEFORE game code

**Problem**: Tests fail with "No contracts/threats generated"  
**Solution**: Call system's `initialize()` method before testing

**Problem**: Contract acceptance fails  
**Solution**: Disable auto-accept: `contractSystem.autoAcceptEnabled = false`

**Problem**: Time-based events don't trigger  
**Solution**: Call `update(dt)` with sufficient delta time (e.g., 11+ seconds for contracts)

## Future Improvements

- [ ] Add performance benchmarking tests
- [ ] Implement fuzzing for edge case discovery
- [ ] Add regression test suite for fixed bugs
- [ ] Create UI interaction tests (requires display mock)
- [ ] Add network save/load tests
- [ ] Implement CI/CD pipeline integration
