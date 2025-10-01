# Idle Sec Ops - Idle Cybersecurity Game

A comprehensive idle cybersecurity simulation built with Lua and LÖVE 2D, featuring modern fortress architecture, authentic threat modeling, and a production-ready Smart UI Framework.

## 🎨 NEW: Smart UI Framework

**Phase 1 Complete! ✅** We've built a production-ready component-based UI system with:

- **Automatic Layout**: Flexbox and Grid containers with intelligent sizing
- **Component Library**: Panel, Box, Grid, Text, Button, and more
- **Cyberpunk Styling**: Neon borders, glow effects, cut corners
- **Event System**: Mouse interactions with automatic propagation
- **Full Documentation**: Comprehensive guides and quick references

**Try the Demo:**
```bash
love ui_demo  # Interactive showcase of all components
```

**Documentation:**
- [Smart UI Framework Guide](docs/SMART_UI_FRAMEWORK.md) - Complete API reference and patterns
- [Quick Reference](docs/SMART_UI_QUICK_REFERENCE.md) - Cheat sheets and common snippets
- [Implementation Summary](docs/UI_IMPLEMENTATION_SUMMARY.md) - What we built and why

## Architecture Overview

### Fortress Architecture (Recommended)
Modern, production-ready architecture with industry-standard SOLID design principles:

- **GameLoop**: Central system orchestration with priority-based updates
- **ResourceManager**: Unified resource handling (money, reputation, XP, mission tokens)
- **SecurityUpgrades**: Authentic cybersecurity infrastructure with 4 categories
- **ThreatSimulation**: Realistic threat engine with 8 threat types
- **UIManager**: Modern reactive UI with cybersecurity theming
- **FortressGame**: Clean controller replacing monolithic game.lua

### Legacy Systems (Maintained)
Original systems maintained for backward compatibility:
- Location-based progression with JSON configuration
- Contract and specialist management systems
- Achievement and skill progression systems

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