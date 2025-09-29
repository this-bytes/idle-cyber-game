# Idle Sec Ops - Game Usage Guide

## Quick Start

The game now has a **single, unified entry point** that works out of the box:

```bash
# Run the game (LÖVE 2D will automatically use main.lua)
love .

# Or if love is in your PATH
love /path/to/idle-cyber-game
```

## Game Flow

1. **Splash Screen** - Shows game title and continues after 2 seconds or any key press
2. **Dashboard** - Main idle game interface with resource management
3. **Offline Progress Modal** - Shows what happened while you were away (if > 30 seconds)

## Core Features

### Resources
- **Money**: Primary currency, generates automatically at $10/second
- **Reputation**: Unlocks better contracts and opportunities  
- **Experience (XP)**: General progression currency
- **Mission Tokens**: Rare currency for special upgrades

### Idle Mechanics
- **Automatic Money Generation**: Earn money while playing ($10/sec base rate)
- **Offline Progress**: Resources continue generating while game is closed
- **Auto-Contracts**: Toggle with SPACEBAR to automatically complete contracts
- **Data-Driven Content**: All contracts and currencies loaded from JSON files

### Controls
- **Any Key**: Continue from splash screen
- **SPACEBAR**: Toggle auto-contract system
- **Click/Key**: Dismiss offline progress modal

## Architecture

The game uses a clean, modular architecture:

- `main.lua` - Single LÖVE 2D entry point
- `src/idle_game.lua` - Main game controller with fortress architecture
- `src/core/` - Core game systems (ResourceManager, UIManager, etc.)
- `src/data/` - JSON data files for dynamic content loading

## File Structure

```
main.lua                    # Main entry point (LÖVE 2D standard)
src/
  idle_game.lua            # Unified game controller  
  core/                    # Core systems
    resource_manager.lua   # Handles all resource operations
    ui_manager.lua         # UI rendering and state management
  data/                    # Game data files
    contracts.json         # Available contracts
    currencies.json        # Currency definitions
    defs.json             # Game definitions
```

## Legacy Files

Legacy entry points have been preserved:
- `src/game.lua.legacy` - Original complex game controller
- `fortress_main.lua.legacy` - Fortress-specific entry point

## Development

The new architecture is designed for rapid development:
- **Single entry point** - No confusion about which file to run
- **Data-driven** - Modify JSON files to change game content
- **Modular systems** - Easy to extend and modify
- **Clean separation** - UI, resources, and game logic are separate

## Troubleshooting

If you get "module not found" errors:
- Make sure you're running from the project root directory
- Ensure all files in `src/` are present
- Check that LÖVE 2D is properly installed

Audio warnings are normal in headless environments and don't affect gameplay.