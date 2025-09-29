# Expandable Skill System - Idle Sec Ops

## Overview

The skill system is a fully expandable, data-driven progression system that allows specialists and the CEO to learn and improve skills that affect their performance in contracts and crisis situations.

## Architecture

### Core Components

1. **SkillSystem** (`src/systems/skill_system.lua`) - Main system managing skill progression and effects
2. **SkillData** (`src/data/skills.lua`) - Data definitions for all skills, categories, and effects
3. **Integration** - Connected to specialist system for team bonuses and effects

### Key Features

- **XP-based progression** with configurable growth curves
- **Prerequisite system** with automatic skill unlocking
- **Multi-category organization** (Analysis, Network, Incident Response, etc.)
- **Rich effects system** supporting 20+ different effect types
- **Data-driven approach** for easy expansion without code changes
- **Full save/load support** with state persistence

## Skill Categories

| Category | Description | Skills |
|----------|-------------|---------|
| **Analysis & Intelligence** | Threat detection and analysis | Basic Analysis, Advanced Scanning, Threat Hunting, Behavioral Analysis |
| **Network Security** | Infrastructure protection | Network Fundamentals, Firewall Management, Intrusion Detection, Network Forensics |
| **Incident Response** | Crisis management | Basic Response, Containment Procedures, Crisis Management, Disaster Recovery |
| **Leadership & Business** | Team management (CEO only) | Team Coordination, Strategic Planning, Business Development |
| **Technical Operations** | System administration | System Administration, Cloud Security |
| **Specialized Skills** | Advanced disciplines | Malware Analysis, Penetration Testing |

## Adding New Skills

### Step 1: Define Skill in Data File

Edit `src/data/skills.lua` and add your skill to the `SkillData.skills` table:

```lua
["my_new_skill"] = {
    id = "my_new_skill",
    name = "My New Skill",
    description = "Description of what this skill does",
    category = "analysis", -- Choose existing or create new category
    maxLevel = 10,
    baseXpCost = 200,
    xpGrowth = 1.25,
    prerequisites = {"basic_analysis"}, -- Skills that must be learned first
    effects = {
        efficiency = 0.08, -- +8% efficiency per level
        myCustomEffect = 0.1 -- Custom effects need system integration
    },
    unlockRequirements = {
        skills = {basic_analysis = 3}, -- Requires Basic Analysis level 3
        reputation = 50 -- Requires 50 reputation to unlock
    }
}
```

### Step 2: Add Custom Effects (if needed)

If your skill uses new effect types, add them to the `getSkillEffects` method in `skill_system.lua`:

```lua
local effects = {
    -- ... existing effects ...
    myCustomEffect = 0,
    -- Add new effect types here
}
```

### Step 3: Integrate Effects in Other Systems

Update systems that should respond to your new effects:

```lua
-- In specialist_system.lua or other relevant systems
local skillEffects = self.skillSystem:getSkillEffects(specialistId)
if skillEffects.myCustomEffect > 0 then
    -- Apply your custom effect logic here
end
```

## Adding New Categories

Edit `src/data/skills.lua` and add to the `SkillData.categories` table:

```lua
my_category = {
    name = "My Category",
    description = "Description of this skill category",
    color = "#FF5722" -- Hex color for UI
}
```

## Skill Effects Reference

### Core Effects
- `efficiency` - Improves contract income and performance
- `speed` - Reduces contract completion time
- `trace` - Improves crisis mode abilities and threat detection
- `defense` - Reduces threat impact and damage

### Leadership Effects (CEO only)
- `teamEfficiencyBonus` - Boosts entire team's efficiency
- `contractCapacity` - Allows taking more contracts simultaneously
- `reputationMultiplier` - Increases reputation gains
- `contractValueBonus` - Increases contract monetary value

### Advanced Effects
- `crisisSuccessRate` - Improves crisis resolution success
- `automaticThreatDetection` - Chance for automatic threat detection
- `containmentSpeed` - Faster crisis containment
- `recoveryBonus` - Faster post-incident recovery
- `contractGenerationRate` - More contracts become available
- `systemReliability` - Reduces system downtime

## Usage Examples

### Awarding XP
```lua
-- Award 100 XP to specialist ID 5 for "basic_analysis" skill
skillSystem:awardXp(5, "basic_analysis", 100)
```

### Checking Skill Effects
```lua
-- Get all skill effects for a specialist
local effects = skillSystem:getSkillEffects(specialistId)
local totalEfficiency = baseEfficiency * (1 + effects.efficiency)
```

### Unlocking Skills
```lua
-- Initialize skills for a new entity
skillSystem:initializeEntity(entityId, entityType)

-- Check for newly unlockable skills
skillSystem:checkSkillUnlocks(entityId)
```

## Testing

The skill system includes comprehensive tests in `tests/systems/test_skill_system.lua`:

- Skill initialization and entity setup
- XP progression and level-ups
- Prerequisite checking and skill unlocking
- Effect calculation and integration
- Save/load functionality
- Data-driven architecture validation

Run tests with: `lua5.3 tests/test_runner.lua`

## Integration Points

### Specialist System
- Automatic skill initialization for new specialists
- Team bonus calculation includes skill effects
- Skill-based stat modifications

### Contract System  
- Skill effects modify contract performance
- XP awarded on contract completion
- Advanced skills unlock higher-tier contracts

### Crisis Mode
- Crisis-specific skills improve response effectiveness
- XP awarded for successful crisis resolution
- Skill effects modify crisis outcomes

## Performance Considerations

- Skills are loaded once from data file at system initialization
- Skill effects are calculated on-demand, not cached
- Save states only store progress data, not skill definitions
- Prerequisite chains are validated at startup

## Future Expansion Ideas

- **Skill Books** - Items that grant XP or unlock skills
- **Training Missions** - Specific scenarios for skill development
- **Skill Decay** - Skills lose effectiveness without use
- **Specialization Paths** - Mutually exclusive advanced skills
- **Cross-training** - Skills that benefit from other categories
- **Mastery Bonuses** - Special effects at maximum skill level

---

For implementation questions or expansion ideas, refer to the existing code structure and test cases as examples.