# Buff System - Cyberspace Tycoon

## Overview

The Buff System adds RPG-style temporary and permanent effects to enhance gameplay progression and strategy. Players can acquire buffs through various activities like completing contracts, resolving crises, upgrading facilities, and developing skills.

## Features

### Buff Types
- **Temporary Buffs** - Time-based effects that expire (contracts, crisis bonuses)
- **Permanent Buffs** - Persistent upgrades from skills and equipment 
- **Stackable Effects** - Buffs that can accumulate (efficiency, threat reduction)
- **Unique Buffs** - Single-instance buffs that replace previous versions

### Effect Categories
- **Resource Effects** - Money/reputation multipliers and generation bonuses
- **Combat Effects** - Threat reduction, defense bonuses, crisis success rates
- **Productivity Effects** - Efficiency improvements, speed boosts, XP multipliers
- **Special Effects** - Unique abilities and breakthrough mechanics

### Visual System
- **Buff Display Panel** - Shows active buffs with icons, timers, and stack counts
- **Rarity System** - Color-coded buffs from common to legendary
- **Interactive UI** - Press 'B' to toggle display, click for details

## Architecture

### Core Components

1. **BuffSystem** (`src/systems/buff_system.lua`) - Main system managing buff lifecycle
2. **BuffData** (`src/data/buffs.lua`) - Data definitions for all buff types
3. **BuffDisplay** (`src/ui/buff_display.lua`) - UI component for showing active buffs

### Integration Points

- **Event Bus** - Automatic buff application from game events
- **Resource Manager** - Effect application to game resources
- **Save System** - Full persistence of buff states
- **Input System** - Toggle display and interaction controls

## Usage

### For Players

#### Controls
- **B Key** - Toggle buff display visibility
- **Mouse** - Click on buff panel for interaction
- **Right Click** - Hide/show buff panel

#### Acquiring Buffs
- **Complete Contracts** - Gain efficiency and income boosts
- **Resolve Crises** - Earn defensive and threat resistance buffs
- **Upgrade Facilities** - Unlock permanent infrastructure bonuses
- **Train Skills** - Access specialized ability enhancements
- **Achieve Milestones** - Receive rare and legendary buffs

### For Developers

#### Adding New Buffs

1. **Define in BuffData** (`src/data/buffs.lua`):
```lua
["my_new_buff"] = {
    name = "🔥 My New Buff",
    description = "Description of the buff effect",
    type = "temporary", -- or "permanent", "stackable", "unique"
    category = "productivity", -- or "resource", "combat", "special"
    duration = 300, -- seconds (for temporary buffs)
    maxStacks = 5, -- for stackable buffs
    effects = {
        efficiency = 0.2, -- +20% efficiency
        resourceMultiplier = {money = 1.5}, -- 1.5x money multiplier
        resourceGeneration = {reputation = 2} -- +2 reputation/sec
    },
    icon = "🔥",
    stackable = true,
    rarity = "uncommon"
}
```

2. **Apply in Code**:
```lua
-- Apply buff manually
buffSystem:applyBuff("my_new_buff", "source_system", duration, stacks)

-- Apply via event (automatic)
eventBus:publish("contract_completed", {contract = {budget = 1000}})
```

#### Effect Types

**Resource Multipliers** (multiplicative stacking):
```lua
effects = {
    resourceMultiplier = {
        money = 1.2,      -- 20% more money
        reputation = 1.5  -- 50% more reputation
    }
}
```

**Resource Generation** (additive stacking):
```lua
effects = {
    resourceGeneration = {
        money = 5,      -- +5 money per second
        reputation = 1  -- +1 reputation per second
    }
}
```

**Special Effects** (additive stacking):
```lua
effects = {
    efficiency = 0.15,           -- +15% efficiency
    threatReduction = 0.25,      -- +25% threat reduction
    xpMultiplier = 2.0,         -- 2x XP gain
    crisisSuccessRate = 0.3     -- +30% crisis success rate
}
```

#### Event Integration

The buff system automatically responds to these events:
- `contract_completed` - Efficiency and income boosts
- `crisis_resolved` - Defensive and resistance buffs
- `player_interact` - Focus and productivity enhancements
- `upgrade_purchased` - Permanent facility improvements
- `skill_leveled` - Specialized ability bonuses

#### Custom Event Handlers

Add custom buff triggers:
```lua
eventBus:subscribe("my_custom_event", function(data)
    if data.shouldApplyBuff then
        buffSystem:applyBuff("my_buff_type", "my_system", 300)
    end
end)
```

## Buff Definitions Reference

### Productivity Buffs
- **Contract Efficiency Boost** - Income and efficiency from contracts
- **Focus Enhancement** - Concentration and XP bonuses
- **Research Acceleration** - Skill and upgrade speed boosts

### Combat Buffs  
- **Threat Resistance** - Defense against cyber threats
- **Firewall Fortification** - Network security enhancements
- **Crisis Veteran** - Experience bonuses from surviving incidents

### Resource Buffs
- **Client Satisfaction** - Reputation and income multipliers
- **Market Recognition** - Industry bonuses and prestige
- **Advanced Infrastructure** - Permanent facility benefits

### Special Buffs
- **Innovation Streak** - Research and breakthrough bonuses
- **Adrenaline Rush** - Emergency response enhancements
- **Threat Intelligence Network** - Advanced detection systems

## Balancing Guidelines

### Duration Scaling
- **Short-term** (1-3 minutes) - High impact, frequent acquisition
- **Medium-term** (5-15 minutes) - Moderate impact, skill-based
- **Long-term** (30+ minutes) - Low impact, achievement-based
- **Permanent** - Milestone rewards, upgrade bonuses

### Stack Limits
- **Low stacks** (1-3) - High per-stack value, rare acquisition
- **Medium stacks** (5-10) - Moderate per-stack value, regular play
- **High stacks** (10+) - Low per-stack value, incremental progress

### Effect Magnitudes
- **Resource Multipliers** - 1.1x to 2.0x range
- **Resource Generation** - 1-10 per second range  
- **Percentage Bonuses** - 5% to 50% range
- **Unique Effects** - Boolean or special mechanics

## Testing

Run comprehensive buff system tests:
```bash
lua5.3 tests/systems/test_buff_system.lua
```

Run interactive demo:
```bash
lua5.3 demo_buff_system.lua
```

## Performance Considerations

- **Effect Caching** - Aggregated effects cached for 1 second
- **Batch Updates** - Multiple buffs updated together
- **Memory Management** - Expired buffs automatically cleaned up
- **Event Efficiency** - Minimal overhead per game event

## Future Extensions

### Planned Features
- **Buff Combinations** - Synergy effects between specific buffs
- **Conditional Buffs** - Effects that trigger under certain conditions
- **Buff Trading** - Multiplayer buff sharing mechanics
- **Visual Effects** - Particle systems for buff applications
- **Audio Feedback** - Sound effects for buff events

### Data Extensions
- **Buff Trees** - Prerequisite chains for advanced buffs
- **Seasonal Buffs** - Time-limited special events
- **Faction Buffs** - Organization-specific bonuses
- **Location Buffs** - Area-based environmental effects

## Troubleshooting

### Common Issues

**Buffs Not Appearing**
- Check buff system initialization in game.lua
- Verify event bus connections
- Confirm buff definitions are valid

**Effects Not Applying**
- Ensure resource manager integration
- Check effect cache invalidation
- Verify system update calls

**UI Not Responding**
- Confirm BuffDisplay initialization
- Check input handler registration
- Verify system render order

### Debug Commands

Enable debug output:
```lua
gameState.debugMode = true
```

Check active buffs:
```lua
local buffs = buffSystem:getActiveBuffs()
print("Active buffs: " .. #buffs)
```

Validate buff data:
```lua
local errors = BuffData.validateBuffs()
print("Validation errors: " .. #errors)
```