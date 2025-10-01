# Fortress Architecture Removal Analysis

## Current Entry Point Flow

```
main.lua → SOCGame (src/soc_game.lua) → Systems + Scenes
```

### What main.lua Actually Uses:
- `src.utils.event_bus`
- `src.soc_game` (SOCGame controller)

### What SOCGame Uses:
- `src.core.data_manager` ✅ USED
- `src.scenes.*` (scene manager and various scenes) ✅ USED
- `src.systems.*` (contract, specialist, upgrade, event, threat, skill) ✅ USED

### What Is NOT Used:
- ❌ `src.core.fortress_game.lua` - Alternative controller, not used by main.lua
- ❌ `src.core.game_loop.lua` - Only used by fortress_game
- ❌ `src.core.resource_manager.lua` - Only used by fortress_game and idle_game
- ❌ `src.core.security_upgrades.lua` - Only used by fortress_game
- ❌ `src.core.threat_simulation.lua` - Only used by fortress_game
- ❌ `src.core.ui_manager.lua` - Only used by fortress_game and idle_game
- ❌ `src.core.soc_stats.lua` - Only used by fortress_game
- ❌ `src.idle_game.lua` - Alternative controller, not used by main.lua
- ❌ `tests/systems/test_fortress_integration.lua` - Tests for fortress_game
- ❌ `tests/systems/test_game_architecture.lua` - Tests for fortress components

## Files to Remove

### Core Fortress Architecture (7 files)
1. `src/core/fortress_game.lua` (522 lines)
2. `src/core/game_loop.lua` 
3. `src/core/resource_manager.lua`
4. `src/core/security_upgrades.lua`
5. `src/core/threat_simulation.lua`
6. `src/core/ui_manager.lua`
7. `src/core/soc_stats.lua`

### Alternative Controllers (1 file)
8. `src/idle_game.lua` (628 lines)

### Fortress Tests (2 files)
9. `tests/systems/test_fortress_integration.lua`
10. `tests/systems/test_game_architecture.lua`

## Files to Keep

### Actually Used Core Components
- ✅ `src/core/data_manager.lua` - Used by SOCGame
- ✅ `src/soc_game.lua` - Main game controller
- ✅ `src/systems/*` - All systems used by SOCGame
- ✅ `src/scenes/*` - All scenes managed by SceneManager
- ✅ `src/ui/*` - UI framework and components
- ✅ `src/utils/*` - Utilities like EventBus

## Rationale

The fortress architecture was an experimental refactor that never became the primary entry point.
The actual game uses SOCGame which manages systems directly without the fortress layers.
