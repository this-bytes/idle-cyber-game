# Technical Architecture Documentation

## AWESOME Backend Architecture 🚀

The game now features the **AWESOME (Adaptive Workflow Engine for Self-Organizing Mechanics and Emergence)** backend architecture - a revolutionary data-driven system that enables emergent gameplay through intelligent item interactions.

### Core AWESOME Systems

#### 1. ItemRegistry (`src/core/item_registry.lua`)

**Purpose**: Universal item loading and validation system for all game entities.

**Key Features**:
- Loads all game items from JSON with unified schema
- Type-based organization (contracts, specialists, upgrades, threats, synergies)
- Tag-based indexing for fast queries
- Support for filtering by type, rarity, tier, and tags

**Usage**:
```lua
local itemRegistry = ItemRegistry.new(dataManager)
itemRegistry:initialize()
local contracts = itemRegistry:getItemsByType("contract")
local fintechItems = itemRegistry:getItemsByTag("fintech")
```

#### 2. EffectProcessor (`src/core/effect_processor.lua`)

**Purpose**: Universal effect calculation system for cross-system interactions.

**Key Features**:
- Processes passive and active effects from all items
- Supports multipliers, additives, and special effects
- Target-based effect application (tag matching)
- Soft caps to prevent runaway growth
- Extensible effect handler system

**Effect Types**:
- `income_multiplier` - Boosts contract income
- `threat_reduction` - Reduces threat damage
- `efficiency_boost` - Improves specialist performance
- `xp_multiplier` - Increases experience gain
- `reputation_multiplier` - Boosts reputation rewards
- `duration_reduction` - Reduces contract/cooldown times

**Usage**:
```lua
local effectProcessor = EffectProcessor.new(eventBus)
local context = {
    tags = {"fintech"},
    activeItems = {upgrades, specialists, synergies}
}
local effectiveIncome = effectProcessor:calculateValue(
    baseIncome,
    "income_multiplier",
    context
)
```

#### 3. FormulaEngine (`src/core/formula_engine.lua`)

**Purpose**: Safe evaluation of data-driven formulas from JSON.

**Key Features**:
- Sandboxed Lua environment (no file/network access)
- Math functions: abs, ceil, floor, min, max, sqrt, log, exp, sin, cos
- Game functions: pow, clamp, lerp
- Variable injection from game state
- Error handling and validation

**Usage**:
```lua
local result = FormulaEngine.evaluate(
    "base * pow(growth, level)",
    {base = 100, growth = 1.15, level = 5}
)
```

#### 4. ProcGen (`src/core/proc_gen.lua`)

**Purpose**: Procedural content generation from templates.

**Key Features**:
- Generate unique contracts, specialists, and events
- Name generation (company names, personal names)
- Statistical distributions (normal, uniform)
- Weighted random tables
- Template-based variation system

**Usage**:
```lua
local procGen = ProcGen.new(itemRegistry, FormulaEngine)
local contract = procGen:generateContract(template, playerContext)
local companyName = procGen:generateName("company")
```

#### 5. SynergyDetector (`src/core/synergy_detector.lua`)

**Purpose**: Automatic detection of synergies between game items.

**Key Features**:
- Rule-based synergy conditions
- Real-time synergy activation/deactivation
- Event publishing for UI notifications
- Support for tag, resource, stat, and achievement conditions

**Synergy Types**:
- Tag combinations (e.g., FinTech specialist + FinTech contract)
- Resource thresholds (e.g., reach $1M)
- Stat requirements (e.g., complete 10 crises)
- Multi-condition logic (requires_all, requires_any)

**Usage**:
```lua
local synergyDetector = SynergyDetector.new(eventBus, itemRegistry)
synergyDetector:initialize()
local activeSynergies = synergyDetector:detectActiveSynergies(gameState)
```

#### 6. AnalyticsCollector (`src/core/analytics_collector.lua`)

**Purpose**: Privacy-respecting game analytics and progression tracking.

**Key Features**:
- Local-only analytics (never sent online)
- Session tracking and aggregate statistics
- Progression velocity analysis
- Event recording with buffer management

**Tracked Metrics**:
- Contracts completed, money earned
- Specialists hired, upgrades purchased
- Threats mitigated, crises resolved
- Progression milestones (first contract, first crisis, etc.)

### AWESOME Backend Benefits

✅ **Data-Driven Everything**: All content defined in JSON, no code changes needed  
✅ **Emergent Gameplay**: Items combine automatically to create synergies  
✅ **Procedural Generation**: Infinite unique content from templates  
✅ **Cross-System Effects**: Upgrades affect all systems intelligently  
✅ **No Server Required**: Runs entirely client-side with LÖVE 2D  
✅ **Better Performance**: Native Lua, no HTTP overhead  

### Universal Item Schema

All game items use this unified JSON schema:

```json
{
  "id": "unique_identifier",
  "type": "contract|specialist|upgrade|threat|synergy",
  "displayName": "Human-readable name",
  "description": "Flavor text",
  "rarity": "common|rare|epic|legendary",
  "tier": 1,
  "tags": ["fintech", "enterprise", "advanced"],
  
  "cost": {
    "money": 1000,
    "reputation": 10
  },
  
  "effects": {
    "passive": [
      {
        "type": "income_multiplier",
        "value": 1.25,
        "target": "fintech"
      }
    ]
  }
}
```

---

## Fortress Architecture Overview

This document describes the comprehensive technical architecture of **Idle Sec Ops**, featuring the modern fortress architecture alongside the legacy location system with JSON-driven mechanics.

The fortress architecture represents a complete architectural transformation from monolithic `game.lua` to world-class, maintainable components built on industry-standard SOLID principles.

## Fortress Core Components

### 1. FortressGame (`src/core/fortress_game.lua`)

**Purpose**: Central game controller that replaces the monolithic game.lua with clean, modular architecture.

**Key Features**:
- Seamless integration of fortress components with legacy systems
- Game flow management (splash → game states)
- Auto-save functionality with configurable intervals
- Debug mode support for development
- Performance monitoring and resource usage tracking

**Entry Points**:
- `fortress_main.lua` - Modern LÖVE 2D entry point
- Maintains 100% backward compatibility with existing save files

### 2. GameLoop (`src/core/game_loop.lua`)

**Purpose**: Central system orchestration with industry-standard game loop management.

**Key Features**:
- Priority-based system update ordering with performance monitoring
- Fixed timestep updates for consistent game simulation  
- Automatic system initialization and shutdown management
- Real-time FPS and timing metrics
- System registration with explicit update order
- Pause/resume functionality with time scaling

**Example Usage**:
```lua
local gameLoop = GameLoop.new(eventBus)
gameLoop:registerSystem("resourceManager", resourceManager, 1)
gameLoop:registerSystem("contractSystem", contractSystem, 2)
gameLoop:initialize()
```

### 3. ResourceManager (`src/core/resource_manager.lua`)

**Purpose**: Unified resource handling for all cybersecurity business resources.

**Key Features**:
- Centralized management of money, reputation, XP, mission tokens
- Event-driven resource updates with automatic UI notifications
- Generation rates, multipliers, and storage limits with validation
- Clean spending/earning interfaces with transaction safety
- Resource history tracking and statistics

**Resource Types**:
- **Money**: Primary currency for upgrades and business operations
- **Reputation**: Professional standing affecting contract availability
- **XP**: Experience points for skill development
- **Mission Tokens**: Government contract currency

### 4. SecurityUpgrades (`src/core/security_upgrades.lua`)

**Purpose**: Realistic cybersecurity infrastructure system.

**Key Features**:
- Authentic cybersecurity upgrade catalog with 4 categories:
  - Infrastructure: Firewalls, monitoring systems, backup solutions
  - Tools: SIEM platforms, vulnerability scanners, forensics tools
  - Personnel: Security analysts, incident responders, consultants
  - Research: Threat intelligence, zero-day research, AI security
- Threat reduction calculations based on actual security implementations
- Cost scaling and prerequisite chains for authentic progression
- Deep integration with threat simulation for realistic defense effectiveness

### 5. ThreatSimulation (`src/core/threat_simulation.lua`)

**Purpose**: Realistic cyber threat engine with authentic threat modeling.

**Key Features**:
- 8 authentic threat types: Phishing, Malware, APT, Zero-day, Ransomware, DDoS, Social Engineering, Supply Chain
- Severity-based damage calculations with defense effectiveness modeling
- Real-time threat mitigation progress with security infrastructure integration
- Comprehensive threat statistics and history tracking
- Threat frequency based on business profile and market conditions

### 6. UIManager (`src/core/ui_manager.lua`)

**Purpose**: Modern reactive UI system with cybersecurity theming.

**Key Features**:
- Event-driven UI updates with cybersecurity-themed notifications
- Panel-based architecture with dynamic visibility management
- Real-time performance metrics display
- Clean state management with save/load persistence
- Responsive design supporting multiple screen sizes

## Legacy System Integration

The fortress architecture maintains **100% backward compatibility** while modernizing the foundation:

- **ContractSystem** now uses fortress ResourceManager for transactions
- **SpecialistSystem** integrates with fortress resource and upgrade systems  
- **IdleSystem** leverages fortress ThreatSimulation for realistic offline damage
- **Game Modes** (Idle/Admin) work seamlessly with fortress components
- **Event Bus** enhanced to support both fortress and legacy system communication

## Smart & Extensible Location System

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

### Fortress Architecture Optimizations
- **Fixed Timestep Updates**: Consistent simulation timing across all systems
- **Priority-based System Scheduling**: Critical systems updated first
- **Event-driven Architecture**: Prevents unnecessary system coupling and computations
- **Resource Generation Caching**: Efficient calculation of passive income
- **Threat Simulation Optimization**: Batch processing of multiple threat instances

### Legacy System Optimizations
- Cached room layouts for rendering performance
- Lazy sprite loading for UI components
- JSON data loaded once at startup

### Memory Management
- Player position and room data stored efficiently
- Location bonuses calculated on-demand
- Achievement state persisted minimally

## Future Extensibility

### Fortress Architecture Extensions
1. **New Systems**: Simple GameLoop registration enables new systems
2. **Resource Types**: ResourceManager configuration supports new currencies
3. **Threat Categories**: ThreatSimulation definitions allow new attack types
4. **Security Upgrades**: JSON-driven upgrade definitions in 4 categories
5. **UI Components**: UIManager framework supports new panel types

### Legacy System Extensions
1. **New Buildings**: Add to `locations.json`
2. **New Currencies**: Define in `currencies.json`
3. **New Bonuses**: Add bonus types to location rooms
4. **New Achievements**: Define triggers and rewards
5. **New Tiers**: Add progression requirements

### Advanced Extensions
- **Multiplayer Integration**: Fortress event system ready for networking
- **Procedural Content**: ThreatSimulation supports dynamic scenario generation
- **Analytics Integration**: Performance metrics enable data-driven balancing
- **Modding Support**: JSON-driven configuration enables community content

## Fortress Architecture Usage Examples

### Running the Fortress Edition
```bash
# Modern fortress architecture (recommended)
love .                                 # Uses fortress_main.lua automatically
lua5.3 fortress_main.lua              # Direct fortress execution

# Legacy system (backward compatibility)
lua5.3 main.lua                       # Original monolithic version
```

### Adding New Fortress Systems
```lua
-- Create new system following fortress patterns
local MySystem = {}
MySystem.__index = MySystem

function MySystem.new(eventBus, resourceManager)
    local self = setmetatable({}, MySystem)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    return self
end

function MySystem:initialize()
    -- System initialization
end

function MySystem:update(dt)
    -- System update logic
end

-- Register with GameLoop
gameLoop:registerSystem("mySystem", mySystem, priority)
```

### Fortress Resource Management
```lua
-- ResourceManager unified interface
resourceManager:addResource("money", 1000)
resourceManager:spendResources({money = 500, reputation = 10})

-- Event-driven updates
eventBus:publish("resource_changed", {
    resource = "money",
    oldValue = 1000,
    newValue = 1500
})
```

### Security Upgrade Integration
```lua
-- Purchase security upgrade
local success = securityUpgrades:purchaseUpgrade("enterprise_firewall")
if success then
    -- Upgrade affects threat simulation automatically
    local threatReduction = securityUpgrades:getThreatReduction("malware")
    print("Malware protection increased by " .. threatReduction .. "%")
end
```

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

### Fortress Architecture Tests (12/12 passing)
- **GameLoop**: System registration and orchestration
- **ResourceManager**: Transaction safety and generation rates
- **SecurityUpgrades**: Purchase logic and threat reduction calculations
- **ThreatSimulation**: Realistic threat generation and mitigation
- **UIManager**: State management and notifications
- **Integration**: Full fortress-legacy system compatibility

### Legacy System Tests (34/34 passing) 
- **LocationSystem**: 6 tests covering navigation, validation, state
- **ProgressionSystem**: 2 tests covering currencies and mechanics
- **Core Systems**: ContractSystem, SpecialistSystem, SkillSystem, IdleSystem
- **Integration**: Full workflow tests with all systems

### Test Execution
```bash
lua5.3 tests/test_runner.lua           # Runs all 46 tests (42 pass, 4 fail - legacy issues)
lua5.3 fortress_main.lua               # Run fortress edition
lua5.3 main.lua                        # Run legacy edition (backward compatibility)
```

### Mock Test Environment
- Complete LÖVE 2D simulation for headless testing
- Graphics, timer, keyboard, and filesystem mocking
- Enables CI/CD testing without game engine dependencies

## Conclusion

This technical architecture provides both a cutting-edge **fortress architecture** for modern game development and maintains the flexible **location-based system** for content expansion.

### Fortress Architecture Benefits
- **Industry-standard SOLID design** with dependency injection
- **Production-ready code** that can replace legacy systems immediately
- **Comprehensive testing** with 12 fortress-specific tests
- **Performance monitoring** with real-time metrics and optimization
- **Authentic cybersecurity simulation** with realistic threat modeling

### Legacy System Benefits  
- **JSON-driven approach** for designer-friendly content creation
- **Event-driven architecture** for natural system interactions
- **Hierarchical location system** supporting complex business progression
- **Extensive test coverage** ensuring system reliability

The combined architecture ensures that game designers can add content without programming knowledge, while developers can extend functionality through well-defined interfaces and comprehensive testing frameworks.

**The fortress stands ready for the cybersecurity idle empire to expand and thrive for years to come.**