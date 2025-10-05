# Idle SOC Game - Developer Quick Reference

**Status**: ✅ Core systems verified working (Oct 2025)  
**Test Suite**: 9/9 passing  
**Architecture**: Event-driven, auto-discovered systems

---

## 🚀 Quick Start

### Run Game
```bash
love .
```

### Run Tests
```bash
/usr/bin/lua tests/run_mechanics_tests.lua
```

### Syntax Check
```bash
luac -p src/systems/*.lua
```

---

## 📁 Project Structure (The Golden Path)

```
src/
├── systems/          ⭐ CORE LOGIC - All gameplay systems
│   ├── *_system.lua  ✅ Auto-discovered by SystemRegistry
│   ├── *_manager.lua ✅ Auto-discovered utilities
│   └── [other].lua   ⚠️  Check IGNORE_FILES list
├── data/             ⭐ JSON DATA - All game content
│   ├── contracts.json    (28 types)
│   ├── threats.json      (57 types)
│   ├── specialists.json  (24 types)
│   └── upgrades.json     (54 types)
├── ui/               ⭐ LUIS UI - Modern component-based UI
│   └── components/
├── scenes/           ⚠️  MIXED - Modern + legacy code
│   └── *_luis.lua    ✅ Modern LUIS-based scenes
└── core/             ⚠️  DEPRECATED - Old skeleton files
```

---

## 🎮 Core Gameplay Loop

```
1. Player starts with resources (money: $10k, reputation: 50)
2. Accept contract from available contracts
3. Contract generates threats/incidents
4. Assign specialists to resolve incidents
5. Contract completes → earn rewards
6. Purchase upgrades with rewards
7. Idle earnings accumulate while offline
8. Repeat with increased power and difficulty
```

---

## 🔧 Active Systems (23 Total)

### Tier 1 - Core Gameplay
- `DataManager` - Loads all JSON data
- `ResourceManager` - Money, reputation, generation
- `ContractSystem` - Contract lifecycle management
- `ThreatSystem` - Threat spawning and resolution
- `IncidentSpecialistSystem` - Incident handling
- `SpecialistSystem` - Hiring, XP, leveling
- `UpgradeSystem` - Upgrade purchases
- `GameStateEngine` - Save/load orchestration

### Tier 2 - Supporting Systems
- `IdleSystem` - Offline earnings
- `SkillSystem` - Skill trees (9 skills)
- `AchievementSystem` - Achievements (34 total)
- `ProgressionSystem` - Player progression
- `GlobalStatsSystem` - Global statistics

### Tier 3 - Utilities
- `EventBus` - Pub/sub event system
- `InputSystem` - Input handling
- `ParticleSystem` - Visual effects
- `SoundSystem` - Audio (15 sounds)
- `LocationSystem` - Location management
- `RoomSystem`, `ZoneSystem`, `FactionSystem`, etc.

---

## 🚫 Deprecated/Ignored Systems

**DO NOT USE:**
- `crisis_system.lua` - ⚠️ BROKEN SYNTAX
- `network_save_system.lua` - Missing dependencies
- `player_system.lua` - Missing dependencies
- `save_system.lua` - Replaced by GameStateEngine
- `soc_stats.lua` - Deprecated
- `soc_idle_operations.lua` - Deprecated

---

## 📊 System Dependencies (Auto-Resolved)

SystemRegistry automatically handles dependency injection:

```lua
-- In your system file:
YourSystem.metadata = {
    priority = 50,  -- Lower = earlier init (1-100)
    dependencies = {
        "DataManager",
        "ResourceManager"
    }
}

-- Constructor signature must match dependencies:
function YourSystem.new(eventBus, dataManager, resourceManager)
    -- eventBus is ALWAYS first
    -- dependencies follow in declared order
end
```

---

## 🎨 UI Development

### Use LUIS (Modern)
```lua
local MyScene = require("src.scenes.my_scene_luis")
-- Components in: src/ui/components/
```

### Avoid Legacy Patterns
- Direct `love.graphics` drawing in scenes
- Manual UI positioning
- Non-component-based UI

---

## 📝 Adding New Content

### New Contract
1. Edit `src/data/contracts.json`
2. Add contract definition
3. DataManager auto-loads on startup
4. No code changes needed

### New Threat
1. Edit `src/data/threats.json`
2. ThreatSystem auto-loads
3. No code changes needed

### New Specialist
1. Edit `src/data/specialists.json`
2. SpecialistSystem auto-loads
3. No code changes needed

### New Upgrade
1. Edit `src/data/upgrades.json`
2. UpgradeSystem auto-loads
3. No code changes needed

---

## 🧪 Testing Guidelines

### Before Committing
```bash
/usr/bin/lua tests/run_mechanics_tests.lua
```

### Test Coverage
- ✅ Idle income generation
- ✅ Contract acceptance and completion
- ✅ Specialist progression
- ✅ Threat generation and resolution
- ✅ Resource management
- ✅ Upgrade purchasing
- ✅ UI components
- ✅ Game loop integration

### Adding New Tests
1. Follow pattern in `tests/test_game_mechanics.lua`
2. Use `setUp()` to initialize systems
3. Test in isolation when possible
4. Document test purpose and expected outcome

---

## 🐛 Common Issues

### "System not found" Error
- Check if system follows `*_system.lua` naming
- Verify not in `IGNORE_FILES` list in `system_registry.lua`
- Check constructor signature matches dependencies

### "Missing getState/loadState" Warning
- Non-critical - system state won't persist
- Add methods if state needs to persist:
```lua
function YourSystem:getState()
    return { your = "data" }
end

function YourSystem:loadState(state)
    self.your = state.your
end
```

### Test Failures
1. Check constructor argument order
2. Verify system initialized before use
3. Check for nil references
4. Run with verbose output

---

## 📚 Key Documentation

- `docs/CORE_GAMEPLAY_LOOP_TEST_PLAN.md` - Test strategy
- `docs/TEST_RESULTS_OCT_2025.md` - Latest test results
- `docs/TESTING_SESSION_SUMMARY_OCT_2025.md` - Executive summary
- `.github/copilot-instructions.md` - Project mandate
- `ARCHITECTURE.md` - System architecture overview
- `lib/luis/luis-api-documentation.md` - UI framework docs

---

## 🎯 Decision Protocol

### When in Doubt:
1. **Check the tests** - They document actual behavior
2. **Verify in code** - Don't trust old documentation
3. **Follow the Golden Path** - `src/systems/` + JSON data
4. **Avoid DANGER ZONES** - Deprecated code is marked

### For New Features:
1. Create system in `src/systems/`
2. Add metadata for auto-discovery
3. Define data in JSON files
4. Write test to verify
5. Run test suite before commit

---

## 🔥 Hot Commands

```bash
# Run game
love .

# Run tests
/usr/bin/lua tests/run_mechanics_tests.lua

# Check syntax
luac -p src/**/*.lua

# Find system usage
grep -r "SystemName" src/

# View system dependencies
grep -A 5 "metadata" src/systems/*_system.lua

# Check event subscriptions
grep -r "subscribe" src/systems/
```

---

## 💡 Pro Tips

1. **EventBus is your friend** - Use it for cross-system communication
2. **JSON is king** - Keep logic in code, data in JSON
3. **Test early, test often** - Tests run in 2 seconds
4. **State management matters** - Add getState/loadState for persistence
5. **LUIS for UI** - Don't write manual drawing code
6. **Trust the tests** - They verify actual behavior, not assumed behavior

---

## 🚦 Project Health

| Metric | Status | Notes |
|--------|--------|-------|
| Test Suite | ✅ 9/9 passing | All core mechanics verified |
| Systems Active | ✅ 23/30 | 7 correctly deprecated |
| Data Loading | ✅ 16/16 files | All JSON loads successfully |
| Game Stability | ✅ No crashes | Runs without errors |
| Architecture | ✅ Clean | Auto-discovery working |
| Documentation | ✅ Current | Updated Oct 2025 |

---

## 🎓 Learning Resources

### Understanding the Codebase
1. Read `.github/copilot-instructions.md` (project mandate)
2. Run test suite and read test code
3. Check `src/systems/system_registry.lua` (auto-discovery logic)
4. Explore `src/data/*.json` (game content)

### Making Changes
1. Find relevant system in `src/systems/`
2. Check its dependencies in metadata
3. Modify logic or JSON data
4. Run tests to verify
5. Test in game

---

**Last Updated**: October 5, 2025  
**Next Review**: After major feature additions  
**Status**: ✅ **STABLE - Ready for development**
