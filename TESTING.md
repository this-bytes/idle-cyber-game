# Testing Framework Improvements

## Problem
The previous testing approach only checked syntax, not actual game behavior. This meant that code could pass tests but still have broken functionality (like the scene transition and input handling bugs we encountered).

## Solution
Added **Behavior Tests** that verify actual game logic without requiring the full LÖVE framework.

## New Testing Structure

### 1. Unit Tests (`./dev.sh test`)
- **Purpose**: Test individual functions and modules in isolation
- **Location**: `tests/test_runner.lua`
- **Scope**: Syntax validation, basic function testing

### 2. Behavior Tests (`./dev.sh behavior`) **[NEW]**
- **Purpose**: Verify core game logic and mechanics
- **Location**: `tests/test_behavior.lua`
- **Tests**:
  - ✅ Data-driven damage calculation
  - ✅ Event flow (threat → scene change)
  - ✅ Specialist cooldown mechanics
- **Advantages**:
  - Runs without LÖVE framework
  - Fast execution
  - Tests actual game logic, not just syntax
  - Catches implementation bugs

### 3. Run All Tests (`./dev.sh test-all`)
- Runs both unit tests and behavior tests

## What The Behavior Tests Validate

### Data-Driven Damage
```lua
-- Verifies that abilities deal damage based on skills.json data
- Network Scan: 25 damage
- Traffic Analysis: 75 damage
- Unknown skills: fallback damage
```

### Event Flow
```lua
-- Verifies threat severity triggers correct behavior
- Low-severity (< 7): No scene change
- High-severity (>= 7): Triggers admin mode
```

### Specialist Cooldown
```lua
-- Verifies specialist state management
- Deployment: status = "busy"
- During cooldown: remains busy
- After cooldown: status = "available"
```

## Benefits

1. **Catch Logic Errors**: Tests verify the *behavior* of the code, not just syntax
2. **Fast Feedback**: Run in seconds without launching the game
3. **Regression Prevention**: Future changes won't break existing behavior
4. **Credit Efficient**: Tests catch problems before making changes to the actual game

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
