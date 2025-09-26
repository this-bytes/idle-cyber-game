# Cyberspace Tycoon - Idle Cybersecurity Game

A comprehensive idle game with cybersecurity theme, built with Lua and LÖVE 2D.

## Project Structure

Based on the modular instruction system in `.github/copilot-instructions/`, this game features:

### Game Modes
- **Idle Empire Building**: Main progression through resource management and upgrades
- **"The Admin's Watch"**: Real-time operations mode for advanced players

### Core Systems
- Multi-resource economy (Data Bits, Processing Power, Security Rating, etc.)
- Zone-based progression system
- Faction relationships and interactions
- Dynamic threat and defense systems
- Achievement and prestige mechanics

### Development Phases
- **Phase 1**: Foundation - Basic mechanics and UI
- **Phase 2**: Expansion - Multiple resources and zones  
- **Phase 3**: Depth - Complex systems and progression
- **Phase 4**: Community - Multiplayer and social features

## Running the Game

Use the project directory when launching LÖVE (do not pass a single file path). From the project root run:

```bash
# run using the helper script
bash run-love.sh

# or run love directly from the project directory
love .
```

Troubleshooting:

- If you see: "Cannot load game at path '/.../main.lua'" then you passed a file path to LÖVE. Use `love .` instead so LÖVE loads the folder containing `main.lua`.
- Ensure LÖVE is installed and on your PATH.

## Development

This project follows a Git-first workflow with feature branches for each major system. See `.github/copilot-instructions/12-development-roadmap.instructions.md` for detailed development guidelines.

## Architecture

The game is built with a modular architecture allowing easy expansion and maintenance. Each major system is self-contained with clear interfaces.

## License

MIT License - see LICENSE file for details.