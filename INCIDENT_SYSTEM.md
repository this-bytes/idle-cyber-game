# Incident and Specialist Management System

## Overview

This system implements the core architectural mechanics for Incident and Specialist Management as defined in the Game Design Document (GDD) `03-core-mechanics.instructions.md`. It provides a complete implementation of the two-tiered resolution system (Idle and Active) with full integration into the game architecture.

## Architecture

The system follows the modular architecture defined in `11-technical-architecture.instructions.md`:

- **Data-Driven**: All specialist and threat definitions are loaded from JSON files
- **Event-Driven**: Integrates with EventBus for system communication
- **Resource Management**: Uses ResourceManager for all resource operations
- **Modular Design**: Clean separation of concerns with distinct functions for each mechanic

## Key Components

### GameState Table

The global runtime state containing:
- `Specialists`: Array of active specialist entities
- `IncidentsQueue`: Array of pending/assigned incident entities
- `ThreatTemplates`: Loaded threat definitions from JSON
- `SpecialistTemplates`: Loaded specialist definitions from JSON
- `GlobalAutoResolveStat`: Threshold for idle resolution (default: 100)
- `IncidentTimer`: Dynamic timer for threat generation
- `UnlockedSpecialists`: Tracking of available specialists

### Specialist Entity Structure

Each specialist has the following GDD-required fields:
- `Level`: Current level (starts at 1)
- `XP`: Experience points (starts at 0)
- `is_busy`: Boolean flag (busy when assigned to incident)
- `cooldown_timer`: Time remaining before available (seconds)
- `defense`: Primary trait used for incident matching
- Additional stats: `efficiency`, `speed`, `trace`

### Incident Entity Structure

Each incident has the following GDD-required fields:
- `id`: Unique identifier
- `trait_required`: The trait type needed (e.g., "Severity")
- `trait_value_needed`: Minimum value required to resolve
- `time_to_resolve`: Duration in seconds
- `base_reward`: Full reward including Mission Tokens
- `status`: Current state (Pending, AutoAssigned, Resolved)
- `resolutionTimeRemaining`: Countdown timer

## Core Mechanics

### 1. Incident Generation (`Incident_Generate_and_Check`)

- Decrements the incident timer each frame
- When timer triggers, selects a random threat template
- Creates an Incident Entity from the template
- Immediately runs Idle Resolution Check
- Timer is randomized (70-130% of base) for unpredictability

### 2. Idle Resolution Check (`Incident_CheckIdleResolve`)

Compares incident severity to GlobalAutoResolveStat:
- **Success**: Auto-resolves with **50% rewards** (no Mission Tokens)
- **Failure**: Escalates to IncidentsQueue for manual resolution

### 3. Specialist Auto-Assignment (`Specialist_AutoAssign`)

- Iterates through pending incidents
- Finds best available specialist whose defense ≥ incident requirement
- Marks specialist as busy and incident as AutoAssigned
- Prefers specialists with closest matching stats

### 4. Incident Resolution Update (`Incident_Resolution_Update`)

- Decrements resolution timer for assigned incidents
- Calls `Incident_Resolve` when timer reaches zero
- Removes completed incidents from queue

### 5. Incident Resolution (`Incident_Resolve`)

- Awards **full rewards** including Mission Tokens
- Awards XP to the assigned specialist
- Sets specialist cooldown timer (5 seconds)
- Updates incident status to Resolved
- Publishes resolution event

### 6. Specialist Cooldown Update (`Specialist_Cooldown_Update`)

- Decrements cooldown timers for all specialists
- Clears `is_busy` flag when cooldown completes
- Publishes availability event

## Usage

### Basic Integration

```lua
local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")

-- Create system with dependencies
local system = IncidentSpecialistSystem.new(eventBus, resourceManager)

-- Initialize (loads JSON data)
system:initialize()

-- In game loop
function love.update(dt)
    system:update(dt)
end

-- Get statistics for UI
local stats = system:getStatistics()
print("Active Specialists:", stats.activeSpecialists)
print("Pending Incidents:", stats.pendingIncidents)
```

### Unlocking New Specialists

```lua
-- Unlock a specialist from templates
local success = system:unlockSpecialist("network_specialist")

if success then
    print("New specialist unlocked!")
end
```

### Accessing GameState

```lua
-- Get current state
local state = system:getState()

-- Iterate specialists
for _, specialist in ipairs(state.Specialists) do
    print(specialist.name, specialist.Level, specialist.XP)
end

-- Check incidents queue
for _, incident in ipairs(state.IncidentsQueue) do
    print(incident.name, incident.status)
end
```

## Testing

### Run Test Suite

```bash
lua5.3 test_incident_system.lua
```

All 10 tests validate:
1. System initialization and JSON loading
2. Specialist instantiation with GDD fields
3. Incident generation from templates
4. Idle resolution logic
5. Specialist auto-assignment
6. Incident resolution and rewards
7. Cooldown system
8. Full update cycle simulation
9. Specialist unlocking mechanism
10. Statistics reporting

### Run Interactive Demo

```bash
lua5.3 demo_incident_system.lua
```

The demo simulates 30 seconds of gameplay showing:
- Incident generation
- Auto-resolve vs. escalation
- Specialist assignment
- Resource accumulation
- Live statistics

## Data Files

### specialists.json

Located at `src/data/specialists.json`, defines specialist templates:

```json
{
  "specialists": {
    "intern": {
      "id": "intern",
      "name": "Security Intern",
      "efficiency": 1.3,
      "defense": 1.0,
      "cost": {"money": 2000}
    }
  }
}
```

### threats.json

Located at `src/data/threats.json`, defines threat templates:

```json
[
  {
    "id": "phishing_attempt",
    "name": "Phishing Email Campaign",
    "baseSeverity": 3,
    "baseTimeToResolve": 45
  }
]
```

## Rewards

### Idle Resolution (Auto-Resolve)
- 50% of base money reward
- 50% of base reputation reward
- 50% of base XP reward
- **0 Mission Tokens**

### Manual/Auto-Assigned Resolution
- 100% of base money reward
- 100% of base reputation reward
- 100% of base XP reward
- **1 Mission Token** (primary incentive)

Reward formula:
- Money: `severity × 50`
- Reputation: `floor(severity / 2)`
- XP: `severity × 10`
- Mission Tokens: `1` (only for active resolution)

## Configuration

Key parameters that can be adjusted:

```lua
-- In GameState initialization
GlobalAutoResolveStat = 100        -- Idle resolution threshold
IncidentTimerMax = 10             -- Base seconds between checks

-- In Incident_Resolve
cooldown_timer = 5.0              -- Specialist cooldown in seconds

-- In Incident_CheckIdleResolve
reducedReward = base_reward * 0.5 -- Idle resolution penalty
```

## Events Published

The system publishes the following events via EventBus:

- `incident_auto_resolved`: When incident resolves automatically
- `incident_escalated`: When incident added to queue
- `incident_auto_assigned`: When specialist auto-assigned
- `incident_resolved`: When incident completed
- `specialist_available`: When specialist cooldown completes
- `specialist_unlocked`: When new specialist unlocked

## Performance

The system is designed for efficient operation:
- JSON data loaded once at initialization
- O(1) specialist lookup by ID
- O(n) queue iteration for assignment (where n = pending incidents)
- Minimal memory allocation during runtime
- Event-driven updates prevent unnecessary coupling

## Future Enhancements

Potential extensions (not yet implemented):
- Manual assignment UI
- Specialist abilities and unique effects
- Multi-trait matching system
- Incident priorities
- Specialist leveling system
- Save/load state persistence
- Integration with contract system

## License

Part of the Idle Sec Ops game project.
