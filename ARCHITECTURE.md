# Technical Architecture Documentation

## Smart & Extensible Location System

This document describes the comprehensive technical architecture implemented for the hierarchical location system with JSON-driven progression mechanics.

## Overview

The system implements a three-tier hierarchical location structure: **Buildings → Floors → Rooms**, with JSON-driven configuration and comprehensive progression mechanics.

## Core Systems

### 1. LocationSystem (`src/systems/location_system.lua`)

**Purpose**: Manages hierarchical location navigation and bonuses.

**Key Features**:
- JSON-driven configuration from `locations.json`
- Hierarchical validation (building/floor/room)
- Location bonuses that affect gameplay
- Event-driven navigation
- State persistence for saves

**Example Usage**:
```lua
local locationSystem = LocationSystem.new(eventBus)
locationSystem:moveToRoom("corporate_office", "main_floor", "my_office")
local bonuses = locationSystem:getCurrentLocationBonuses()
```

### 2. ProgressionSystem (`src/systems/progression_system.lua`)

**Purpose**: Manages currencies, achievements, and tier progression.

**Key Features**:
- 6 currency types (money, reputation, XP, energy, focus, influence)
- JSON-driven progression configuration
- Achievement tracking with event triggers
- Tier-based progression with requirements
- Location-aware bonuses integration

**Currency Types**:
- **Money**: Primary currency for upgrades and unlocks
- **Reputation**: Professional standing for better opportunities
- **Experience**: Knowledge for skill development
- **Energy**: Current work capacity with location-based regen
- **Focus**: Mental clarity affecting work quality
- **Influence**: Network connections for elite opportunities

### 3. EnhancedPlayerSystem (`src/systems/enhanced_player_system.lua`)

**Purpose**: Location-aware player movement and interactions.

**Key Features**:
- Physics-based smooth movement
- Location-constrained navigation
- Department and connection interactions
- Location bonus application to player stats
- Room layout management

### 4. LocationMap (`src/ui/location_map.lua`)

**Purpose**: Advanced UI rendering for hierarchical locations.

**Key Features**:
- Room boundary visualization
- Department and connection rendering
- Location information overlays
- Bonus display and navigation hints
- Click-to-navigate interface

## JSON Configuration

### locations.json Structure

```json
{
  "buildings": {
    "building_id": {
      "name": "Building Name",
      "description": "Building description",
      "unlocked": true,
      "tier": 1,
      "floors": {
        "floor_id": {
          "name": "Floor Name",
          "rooms": {
            "room_id": {
              "name": "Room Name",
              "x": 160, "y": 120,
              "width": 100, "height": 80,
              "departments": ["desk", "contracts"],
              "bonuses": {
                "focus": 1.1,
                "energy_regen": 1.2
              },
              "atmosphere": "Description text"
            }
          },
          "connections": {
            "elevator": {
              "x": 350, "y": 150,
              "leads_to": "other_floor"
            }
          }
        }
      },
      "unlockRequirements": {
        "money": 25000,
        "reputation": 75
      }
    }
  }
}
```

### currencies.json Structure

```json
{
  "currencies": {
    "currency_id": {
      "name": "Currency Name",
      "symbol": "$",
      "startingAmount": 1000,
      "maxAmount": 999999,
      "displayFormat": "currency",
      "sources": ["contracts", "passive_income"],
      "uses": ["unlock_buildings", "upgrades"]
    }
  },
  "progression": {
    "tiers": {
      "tier_id": {
        "name": "Tier Name",
        "requirements": {
          "money": 5000,
          "reputation": 25
        },
        "rewards": {
          "money": 2000,
          "influence": 5
        }
      }
    }
  }
}
```

## Event-Driven Architecture

The system uses an EventBus for decoupled communication:

### Key Events

- `location_changed`: Fired when player moves between locations
- `building_unlocked`: When new buildings become available
- `contract_completed`: When work generates resources
- `achievement_unlocked`: When achievements are earned
- `tier_promoted`: When player advances tiers

### Event Flow Example

```
Player moves → LocationSystem publishes location_changed → 
ProgressionSystem updates stats → Achievement checks → 
UI updates bonuses display
```

## Smart & Extensible Design

### 1. Data-Driven Configuration
- All locations defined in JSON (no code changes needed)
- Currency rules configurable via JSON
- Achievement triggers and rewards in data files

### 2. Modular System Architecture
- Each system operates independently
- Communication via events (loose coupling)
- Easy to add new systems without modifying existing ones

### 3. Hierarchical Validation
- Building → Floor → Room validation chain
- Graceful fallbacks for invalid locations
- Comprehensive error handling

### 4. Extensible Bonus System
- Location bonuses stack multiplicatively
- Easy to add new bonus types via JSON
- Real-time bonus calculation and application

### 5. Comprehensive Testing
- 30+ automated tests covering all systems
- Integration tests validate system interactions
- Location validation and state persistence tests

## Performance Considerations

### Optimization Strategies
- Cached room layouts for rendering performance
- Lazy sprite loading for UI components
- Event bus prevents unnecessary system coupling
- JSON data loaded once at startup

### Memory Management
- Player position and room data stored efficiently
- Location bonuses calculated on-demand
- Achievement state persisted minimally

## Future Extensibility

### Easy Additions
1. **New Buildings**: Add to `locations.json`
2. **New Currencies**: Define in `currencies.json`
3. **New Bonuses**: Add bonus types to location rooms
4. **New Achievements**: Define triggers and rewards
5. **New Tiers**: Add progression requirements

### System Extensions
- Network multiplayer locations
- Procedural room generation
- Dynamic location events
- Weather/time-based bonuses
- Social features (visitor system)

## Usage Examples

### Adding a New Building
```json
"research_institute": {
  "name": "🔬 Research Institute",
  "tier": 3,
  "floors": {
    "lab_floor": {
      "rooms": {
        "main_lab": {
          "bonuses": { "research_speed": 2.0 }
        }
      }
    }
  },
  "unlockRequirements": {
    "reputation": 200,
    "influence": 50
  }
}
```

### Adding a New Currency
```json
"innovation_points": {
  "name": "Innovation Points",
  "symbol": "💡",
  "startingAmount": 0,
  "sources": ["research", "training"],
  "uses": ["unlock_technologies", "boost_research"]
}
```

## Testing Strategy

### Test Coverage
- **LocationSystem**: 6 tests covering navigation, validation, state
- **ProgressionSystem**: 6 tests covering currencies, achievements, persistence
- **Integration**: Full workflow tests with all systems
- **Legacy Systems**: Maintained existing 18 tests

### Test Execution
```bash
lua tests/test_runner.lua  # Runs all 30+ tests
lua src/demo_integration.lua  # Integration demo
lua src/ui_demo.lua  # UI architecture demo
```

## Conclusion

This technical architecture provides a smart, extensible foundation for location-based gameplay that can grow with the game's needs while maintaining clean separation of concerns and comprehensive test coverage.

The JSON-driven approach ensures that game designers can add content without programming knowledge, while the event-driven architecture allows systems to interact naturally without tight coupling.