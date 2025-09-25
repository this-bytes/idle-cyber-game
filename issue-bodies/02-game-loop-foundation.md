## Description
Implement the core game loop, state management, and update systems that will drive all game mechanics. This is the foundation that all other systems will build upon.

## Acceptance Criteria
- [ ] LÖVE 2D game loop (love.update, love.draw) properly structured
- [ ] Game state management system (playing, paused, menu)
- [ ] Delta time handling for frame-independent updates
- [ ] Save/load system foundation
- [ ] Resource tracking system foundation
- [ ] Event system for game mechanics communication

## Technical Requirements
- **Update Rate:** 60 FPS target, frame-independent calculations
- **State Management:** Finite state machine or similar pattern
- **Data Persistence:** JSON-based save format initially
- **Performance:** Smooth updates with 1000+ game objects
- **Architecture:** Modular system design

## Implementation Notes
- Reference `.github/copilot-instructions/11-technical-architecture.md`
- Use delta time for all time-based calculations
- Implement observer pattern for system communication
- Design save format to be version-compatible
- Create foundation for idle mechanics (offline progress)

## Files to Create/Modify
- `main.lua` - LÖVE 2D callbacks
- `core/gamestate.lua` - State management
- `core/updateloop.lua` - Update system
- `core/savedata.lua` - Save/load functionality
- `core/events.lua` - Event system
- `core/resources.lua` - Resource tracking foundation

## Testing Checklist
- [ ] Game maintains stable 60 FPS
- [ ] Save/load preserves game state
- [ ] State transitions work smoothly
- [ ] Delta time calculations are accurate
- [ ] Memory usage stays reasonable over time
- [ ] No memory leaks during extended play

## Definition of Done
- [ ] Core systems implemented and tested
- [ ] Documentation for system architecture
- [ ] Performance benchmarks meet targets
- [ ] Save/load functionality validated
- [ ] Event system working for basic communication

## Branch
`feature/game-loop`

## Dependencies
None (Foundation system)