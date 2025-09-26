## Project: Cyberspace Tycoon - Idle Cybersecurity Game

**Goal:** To develop an idle game using Lua and LÖVE 2D, focusing on learning software development principles, particularly Git version control, through an engaging cybersecurity theme.

---

## Modular Instruction System

This project uses a comprehensive modular approach to copilot instructions. Each aspect of development has its own focused instruction file in the `.github/copilot-instructions/` directory:

### Core Development Files
- **[01-project-overview.instructions.md](./copilot-instructions/01-project-overview.instructions.md)** - Project goals, core principles, and development workflow
- **[12-development-roadmap.instructions.md](./copilot-instructions/12-development-roadmap.instructions.md)** - Development phases, git workflow, and testing strategy

### Game Design Files
- **[02-game-story-narrative.instructions.md](./copilot-instructions/02-game-story-narrative.instructions.md)** - World setting, player origins, factions, and narrative context
- **[03-core-mechanics.instructions.md](./copilot-instructions/03-core-mechanics.instructions.md)** - Resources, generation systems, and upgrade mechanics
- **[04-defense-threat-systems.instructions.md](./copilot-instructions/04-defense-threat-systems.instructions.md)** - Comprehensive threat classification and defense infrastructure
- **[05-progression-prestige.instructions.md](./copilot-instructions/05-progression-prestige.instructions.md)** - Character advancement, zones, achievements, and prestige systems
- **[06-events-encounters.instructions.md](./copilot-instructions/06-events-encounters.instructions.md)** - Dynamic events, random encounters, and faction relations
- **[07-endgame-meta.instructions.md](./copilot-instructions/07-endgame-meta.instructions.md)** - Singularity path, New Game Plus, and community features

### Technical Implementation Files
- **[08-quality-accessibility.instructions.md](./copilot-instructions/08-quality-accessibility.instructions.md)** - QoL features, automation, and accessibility options
- **[09-balancing-math.instructions.md](./copilot-instructions/09-balancing-math.instructions.md)** - Mathematical frameworks and balancing formulas
- **[10-ui-design.instructions.md](./copilot-instructions/10-ui-design.instructions.md)** - Visual design, audio concepts, and interface goals
- **[11-technical-architecture.instructions.md](./copilot-instructions/11-technical-architecture.instructions.md)** - Platform considerations and performance optimization

---

## Quick Start Guide

### For New Contributors
1. Read `01-project-overview.instructions.md` for core principles and workflow
2. Review `12-development-roadmap.instructions.md` for current development phase
3. Consult the relevant specialized instruction file for your area of work

### For Specific Development Tasks
- **Working on gameplay mechanics?** → `03-core-mechanics.instructions.md` + `04-defense-threat-systems.instructions.md`
- **Implementing UI/UX?** → `10-ui-design.instructions.md` + `08-quality-accessibility.instructions.md`
- **Balancing game systems?** → `09-balancing-math.instructions.md`
- **Adding story content?** → `02-game-story-narrative.instructions.md` + `06-events-encounters.instructions.md`
- **Working on progression?** → `05-progression-prestige.instructions.md` + `07-endgame-meta.instructions.md`
- **Technical implementation?** → `11-technical-architecture.instructions.md`
- **Developing "The Admin's Watch" mode?** → `02-game-story-narrative.instructions.md` + `03-core-mechanics.instructions.md` + `04-defense-threat-systems.instructions.md` + `10-ui-design.instructions.md`

---

## Benefits of This Modular Approach

- **Focused Instructions:** Each file targets specific development aspects
- **Easier Maintenance:** Update individual sections without affecting others
- **Better Collaboration:** Multiple developers can work on different aspects simultaneously
- **Specialized AI Guidance:** AI agents can receive targeted instructions for their specific tasks
- **Scalable Documentation:** Easy to add new instruction files as the project grows

When working on any aspect of the game, consult the appropriate instruction file for detailed, actionable guidance specific to that area of development.

<tool_calling>
You have the capability to call multiple tools in a single response. For maximum efficiency, whenever you need to perform multiple independent operations, ALWAYS invoke all relevant tools simultaneously rather than sequentially. Especially when exploring repository, reading files, viewing directories, validating changes or replying to comments.
</tool_calling>

## Development Environment

### Technologies Used
- **Language:** Lua 5.3+
- **Framework:** LÖVE 2D (Love2D) game engine
- **Testing:** Custom Lua test runner (`tests/test_runner.lua`)
- **Data Format:** JSON for game data, Lua tables for configuration

### Running Tests
```bash
lua tests/test_runner.lua
```

### Building and Running
```bash
# Development mode
love .

# Or using the development script
./dev.sh
```

### Project Structure
```
src/            # Main game source code
  systems/      # Core game systems (resources, contracts, etc.)
  modes/        # Game modes (idle, admin watch)
  ui/           # User interface components
  data/         # Game data files (JSON)
tests/          # Test suite
  systems/      # System-specific tests
assets/         # Game assets (art, audio, etc.)
tools/          # Development and utility scripts
```

### Best Practices for Development
- **Always run tests** before committing changes: `lua tests/test_runner.lua`
- **Use feature branches** as outlined in `12-development-roadmap.instructions.md`
- **Follow modular architecture** described in `11-technical-architecture.instructions.md`
- **Test game balance** using simulation tools in `tools/` directory
- **Validate save/load** functionality after changes to core systems

### Common Development Workflows

#### For Bug Fixes
1. Run tests to understand current state: `lua tests/test_runner.lua`
2. Identify the failing system and consult relevant instruction file
3. Make minimal changes following the established patterns
4. Test changes thoroughly
5. Run full test suite before committing

#### For New Features
1. Consult the relevant instruction files for the feature area
2. Review `12-development-roadmap.instructions.md` for current development phase
3. Create feature branch following naming conventions
4. Implement following modular architecture principles
5. Add tests for new functionality
6. Validate integration with existing systems

#### For Game Balance Changes
1. Review `09-balancing-math.instructions.md` for mathematical frameworks  
2. Use simulation tools in `tools/` directory to test balance
3. Consult `03-core-mechanics.instructions.md` for system interactions
4. Test extensively in different game states
5. Document changes for future reference

## Repository-Specific Guidelines

### File Organization
- Game logic belongs in `src/systems/` with clear module separation
- UI components go in `src/ui/` following the component-based architecture
- Game data (contracts, specialists, etc.) stored in `src/data/` as JSON files
- Tests mirror the source structure in `tests/` directory
- Assets organized by type in `assets/` (images, audio, etc.)

### Code Style and Conventions
- Follow Lua best practices and existing code patterns
- Use descriptive variable and function names
- Comment complex game mechanics and mathematical formulas
- Keep functions focused and modular
- Use the event bus system for cross-system communication

### Testing Requirements
- All new systems should have corresponding tests in `tests/systems/`
- Test both happy path and edge cases
- Validate game balance with simulation tools
- Ensure save/load compatibility after data structure changes

### Dependencies and Constraints
- **Lua 5.3+ required** - Do not use features from newer versions
- **LÖVE 2D framework** - Follow Love2D conventions and limitations
- **No external dependencies** - Keep the game self-contained
- **Cross-platform compatibility** - Ensure code works on Windows, Mac, and Linux
- **Performance considerations** - Game must run smoothly on modest hardware
