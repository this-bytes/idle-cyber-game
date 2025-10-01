# Idle Sec Ops - Idle Cybersecurity Game

A comprehensive idle cybersecurity simulation built with Lua and LÖVE 2D, featuring modern game architecture, authentic threat modeling, and a production-ready Smart UI Framework.

## 📚 Documentation

**The canonical project documentation is located in `.github/copilot-instructions/`**

This modular instruction system provides comprehensive guidance for all aspects of development:

- **[01-project-overview](. /copilot-instructions/01-project-overview.instructions.md)** - Core principles and workflow
- **[02-game-story-narrative](.github/copilot-instructions/02-game-story-narrative.instructions.md)** - World setting and narrative
- **[03-core-mechanics](.github/copilot-instructions/03-core-mechanics.instructions.md)** - Game systems and mechanics
- **[04-defense-threat-systems](.github/copilot-instructions/04-defense-threat-systems.instructions.md)** - Threat classification and defense
- **[05-progression-prestige](.github/copilot-instructions/05-progression-prestige.instructions.md)** - Character advancement
- **[06-events-encounters](.github/copilot-instructions/06-events-encounters.instructions.md)** - Dynamic events
- **[07-endgame-meta](.github/copilot-instructions/07-endgame-meta.instructions.md)** - Endgame content
- **[08-quality-accessibility](.github/copilot-instructions/08-quality-accessibility.instructions.md)** - QoL features
- **[09-balancing-math](.github/copilot-instructions/09-balancing-math.instructions.md)** - Game balance formulas
- **[10-ui-design](.github/copilot-instructions/10-ui-design.instructions.md)** - Visual design
- **[11-technical-architecture](.github/copilot-instructions/11-technical-architecture.instructions.md)** - System architecture
- **[12-development-roadmap](.github/copilot-instructions/12-development-roadmap.instructions.md)** - Development phases

## 🎨 Smart UI Framework - INTEGRATED! ✅

**The Smart UI Framework is fully integrated into the game!** 🎉

- ✅ **Component-Based Architecture** - Automatic layout with flexbox/grid
- ✅ **Toast Notifications** - Animated notifications with auto-dismiss
- ✅ **Cyberpunk Styling** - Neon borders, glow effects, cut corners

**See It In Action:**
```bash
love .           # Main game with Smart UI
love ui_demo     # UI component showcase
```

**Documentation:**
- [Smart UI Framework Guide](docs/SMART_UI_FRAMEWORK.md) - Complete API reference
- [Quick Reference](docs/SMART_UI_QUICK_REFERENCE.md) - Cheat sheets

## Architecture Overview

### Modern Game Architecture (Current)
Production-ready architecture implementing industry-standard SOLID design principles:

- **GameLoop**: Central system orchestration with priority-based updates
- **ResourceManager**: Unified resource handling (money, reputation, XP, mission tokens)
- **SecurityUpgrades**: Authentic cybersecurity infrastructure with 4 categories
- **ThreatSimulation**: Realistic threat engine with 8 threat types
- **UIManager**: Modern reactive UI with cybersecurity theming
- **SOCGame**: Main game controller integrating all systems

See [11-technical-architecture.instructions.md](.github/copilot-instructions/11-technical-architecture.instructions.md) for complete details.

## Running the Game

### Fortress Edition (Recommended)
```bash
love .                    # Uses fortress_main.lua automatically
lua5.3 fortress_main.lua  # Direct fortress execution
```

### Legacy Edition  
```bash
lua5.3 main.lua          # Original monolithic version
```

## Testing

```bash
lua5.3 tests/test_runner.lua  # Runs all 46 tests (42 pass, 4 legacy issues)
```

**Test Coverage**:
- ✅ 12 fortress architecture tests (all passing)
- ✅ 34 legacy system tests (30 passing, 4 known issues)
- ✅ Integration tests for fortress-legacy compatibility

## Development

This project follows a Git-first workflow with feature branches for each major system. See `.github/copilot-instructions/12-development-roadmap.instructions.md` for detailed development guidelines.

## Architecture

The game is built with a modular architecture allowing easy expansion and maintenance. Each major system is self-contained with clear interfaces.

## License

MIT License - see LICENSE file for details.