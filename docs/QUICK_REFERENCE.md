# 🎯 AWESOME Backend - Quick Reference Card

## 30-Second Overview

**AWESOME** = Universal item system where ALL game content is JSON, effects combine automatically, and emergent gameplay happens naturally.

---

## Core Files You Need to Know

```
src/core/
  ├─ item_registry.lua      → Loads & indexes ALL items
  ├─ effect_processor.lua   → Calculates cross-system effects
  ├─ formula_engine.lua     → Evaluates JSON formulas safely
  ├─ proc_gen.lua           → Generates unique content
  ├─ synergy_detector.lua   → Finds active combos
  └─ difficulty_adapter.lua → Adapts to player skill

src/data/
  ├─ contracts.json         → Contract definitions
  ├─ specialists.json       → Specialist templates
  ├─ upgrades.json          → Upgrade effects
  ├─ threats.json           → Threat definitions
  ├─ synergies.json         → Synergy combos
  └─ templates.json         → Procedural templates
```

---

## Universal Item Schema

Every game item follows this pattern:

```json
{
  "id": "unique_id",
  "type": "contract|specialist|upgrade|threat|event|synergy",
  "displayName": "Human Name",
  "description": "What it does",
  "tags": ["category", "type", "special"],
  
  "requirements": {
    "level": 5,
    "reputation": 100,
    "prerequisites": ["item_id"]
  },
  
  "cost": {
    "money": 1000,
    "reputation": 10,
    "mission_tokens": 5
  },
  
  "effects": {
    "passive": [
      {"type": "effect_type", "value": 1.5, "target": "tag_or_all"}
    ],
    "active": [
      {"type": "ability", "cooldown": 60}
    ]
  },
  
  "scaling": {
    "formula": "base * pow(growth, count)",
    "growth_factor": 1.15
  },
  
  "metadata": {
    "icon": "path/to/icon.png",
    "category": "tier_1"
  }
}
```

---

## Common Effect Types

| Effect Type | Value | Target | Description |
|------------|-------|--------|-------------|
| `income_multiplier` | 1.5 | "all" or tag | Multiply income by 1.5x |
| `threat_reduction` | 0.25 | threat type | Reduce threat by 25% |
| `efficiency_boost` | 1.3 | "specialists" | +30% specialist efficiency |
| `cooldown_reduction` | 0.2 | ability type | -20% cooldown time |
| `xp_multiplier` | 2.0 | "all" | Double XP gain |
| `generate_resource` | 10 | resource name | Generate 10 per tick |

---

## Quick Code Examples

### 1. Load and Query Items

```lua
-- Initialize registry
local itemRegistry = ItemRegistry.new(dataManager)
itemRegistry:initialize()

-- Get item by ID
local contract = itemRegistry:getItem("enterprise_contract")

-- Get all items of a type
local allContracts = itemRegistry:getItemsByType("contract")

-- Query by tags
local fintechItems = itemRegistry:getItemsByTag("fintech")

-- Advanced query
local results = itemRegistry:queryItems({
    type = "specialist",
    tags = {"security", "senior"},
    rarity = "rare"
})
```

### 2. Calculate Effects

```lua
-- Initialize processor
local effectProcessor = EffectProcessor.new(eventBus)

-- Calculate value with effects
local baseIncome = 1000
local context = {
    type = "contract",
    tags = {"enterprise", "fintech"},
    activeItems = {
        itemRegistry:getItem("upgrade_income_boost"),
        itemRegistry:getItem("specialist_fintech_expert")
    },
    soft_cap = 10.0
}

local effectiveIncome = effectProcessor:calculateValue(
    baseIncome,
    "income_multiplier",
    context
)
-- Result: 1000 * 1.5 (upgrade) * 1.25 (specialist) = 1875
```

### 3. Evaluate Formulas

```lua
local FormulaEngine = require("src.core.formula_engine")

local cost = FormulaEngine.evaluate(
    "base * pow(growth, count)",
    {
        base = 100,
        growth = 1.15,
        count = 5
    }
)
-- Result: 100 * (1.15 ^ 5) = 201.14
```

### 4. Generate Procedural Content

```lua
local procGen = ProcGen.new(itemRegistry, formulaEngine)

local template = {
    base_template = "enterprise_contract",
    variations = {
        client_name = {"{{adjective}} {{tech_noun}} {{company_suffix}}"},
        risk_multiplier = {
            distribution = "normal",
            mean = 1.0,
            stddev = 0.3,
            min = 0.6,
            max = 2.0
        },
        budget_scaling = {
            formula = "base * player_level * risk_multiplier"
        }
    }
}

local playerContext = {level = 15}
local newContract = procGen:generateContract(template, playerContext)
```

### 5. Publish and Subscribe to Events

```lua
-- Subscribe to events
eventBus:subscribe("contract_completed", function(data)
    print("Contract completed:", data.contractId)
    print("Reward:", data.reward)
end)

-- Publish events
eventBus:publish("contract_completed", {
    contractId = "contract_123",
    reward = 1000,
    xpAwarded = 50
})
```

---

## Effect Target Patterns

| Target | Matches |
|--------|---------|
| `"all"` | Everything |
| `"fintech"` | Items with "fintech" tag |
| `"contract"` | Items of type "contract" |
| `"specialists"` | All specialist items |
| `["tag1", "tag2"]` | Items with either tag |

---

## Formula Variables

Safe variables available in formulas:

| Variable | Description | Example |
|----------|-------------|---------|
| `base` | Base value | 100 |
| `level` | Player/item level | 15 |
| `count` | Number of purchases | 3 |
| `growth` | Growth factor | 1.15 |
| `efficiency` | Efficiency multiplier | 1.25 |
| `risk_multiplier` | Risk scaling | 1.5 |
| `player_level` | Current player level | 20 |

Safe functions:

| Function | Description | Example |
|----------|-------------|---------|
| `pow(a, b)` | a to the power of b | `pow(2, 3)` = 8 |
| `min(a, b)` | Minimum of a and b | `min(10, 5)` = 5 |
| `max(a, b)` | Maximum of a and b | `max(10, 5)` = 10 |
| `clamp(v, min, max)` | Clamp v between min and max | `clamp(15, 0, 10)` = 10 |
| `floor(x)` | Round down | `floor(3.7)` = 3 |
| `ceil(x)` | Round up | `ceil(3.2)` = 4 |
| `sqrt(x)` | Square root | `sqrt(16)` = 4 |

---

## Common Patterns

### Pattern 1: Cross-System Synergy

```json
{
  "id": "synergy_fintech_bonus",
  "type": "synergy",
  "conditions": {
    "requires_all": [
      {"item_tag": "fintech", "item_type": "specialist"},
      {"item_tag": "fintech", "item_type": "contract", "state": "active"}
    ]
  },
  "effects": {
    "passive": [
      {"type": "income_multiplier", "value": 1.25, "target": "fintech"}
    ]
  }
}
```

### Pattern 2: Leveling System

```json
{
  "id": "specialist_analyst",
  "type": "specialist_template",
  "baseStats": {"efficiency": 1.0},
  "scaling": {
    "efficiency": {
      "formula": "base * (1 + level * 0.05)",
      "per_level": 0.05
    }
  }
}
```

### Pattern 3: Conditional Effects

```json
{
  "id": "upgrade_conditional",
  "type": "upgrade",
  "effects": {
    "conditional": [
      {
        "condition": {"time_of_day": "night"},
        "effects": [
          {"type": "income_multiplier", "value": 1.5}
        ]
      }
    ]
  }
}
```

### Pattern 4: Temporary Effects

```json
{
  "id": "event_market_boom",
  "type": "event",
  "duration": 300,
  "effects": {
    "temporary": [
      {"type": "income_multiplier", "value": 2.0, "target": "all"}
    ]
  }
}
```

---

## Testing Checklist

```lua
-- Test ItemRegistry
✓ Load all JSON files without errors
✓ Index items by ID, type, and tags
✓ Query returns correct results
✓ Validation catches malformed items

-- Test EffectProcessor
✓ Multiplier effects stack correctly
✓ Additive effects sum properly
✓ Soft caps prevent runaway growth
✓ Target matching works with tags

-- Test FormulaEngine
✓ Safe evaluation (no code injection)
✓ Math functions work correctly
✓ Invalid formulas return 0
✓ NaN and infinity handled

-- Test ProcGen
✓ Generated items are valid
✓ Templates apply variations correctly
✓ Distribution sampling works
✓ Unique IDs generated

-- Integration Tests
✓ Contract completion triggers effects
✓ Upgrades modify calculations
✓ Specialists contribute to income
✓ Synergies activate automatically
```

---

## Performance Tips

1. **Cache effect calculations** when context doesn't change
2. **Use tags** instead of scanning all items
3. **Batch event publishing** for multiple updates
4. **Index lookup** is O(1), use it!
5. **Profile before optimizing** - measure first

---

## Common Gotchas

❌ **Don't** mutate item definitions at runtime  
✅ **Do** create new instances or use state flags

❌ **Don't** hardcode item properties in systems  
✅ **Do** query ItemRegistry and use EffectProcessor

❌ **Don't** tightly couple systems  
✅ **Do** use EventBus for communication

❌ **Don't** put game logic in JSON  
✅ **Do** put data and formulas in JSON

---

## Debug Commands

```lua
-- Dump all loaded items
itemRegistry:debug_printAllItems()

-- Show active effects for context
local summary = effectProcessor:getActiveEffectSummary(context)
print(summary)

-- Test formula
local result = FormulaEngine.evaluate("pow(2, 3)", {})
print(result) -- Should be 8

-- Validate JSON
dataManager:validateAllData()
```

---

## When to Use What

| Need | Use | Example |
|------|-----|---------|
| Load game content | ItemRegistry | `itemRegistry:getItem(id)` |
| Calculate modified values | EffectProcessor | `effectProcessor:calculateValue()` |
| Evaluate data formulas | FormulaEngine | `FormulaEngine.evaluate(formula)` |
| Generate unique content | ProcGen | `procGen:generateContract()` |
| Find active combos | SynergyDetector | `synergyDetector:detectActive()` |
| Communicate between systems | EventBus | `eventBus:publish(event, data)` |

---

## Quick Migration Guide

### Old Way (Hardcoded):
```lua
function ContractSystem:calculateIncome()
    local income = self.baseIncome
    
    -- Manually check each upgrade
    if self.upgrades["income_boost"] then
        income = income * 1.5
    end
    if self.upgrades["another_boost"] then
        income = income * 1.2
    end
    
    return income
end
```

### New Way (Effect-Based):
```lua
function ContractSystem:calculateIncome()
    local context = {
        type = "contract",
        tags = self.currentContract.tags,
        activeItems = self:getActiveEffectItems()
    }
    
    return self.effectProcessor:calculateValue(
        self.baseIncome,
        "income_multiplier",
        context
    )
end
```

**Result**: Automatic synergy detection, no code changes for new upgrades! ✨

---

## Resources

- **Full Vision**: BACKEND_VISION.md
- **Implementation**: BACKEND_IMPLEMENTATION_GUIDE.md
- **Creative Examples**: DESIGNER_PLAYGROUND.md
- **Architecture**: ARCHITECTURE_DIAGRAMS.md
- **Summary**: BACKEND_TRANSFORMATION_SUMMARY.md

---

## Emergency Contacts

- **Questions?** Check BACKEND_IMPLEMENTATION_GUIDE.md
- **Design Ideas?** See DESIGNER_PLAYGROUND.md
- **Architecture?** Review ARCHITECTURE_DIAGRAMS.md
- **Philosophy?** Read BACKEND_VISION.md

---

**Remember**: Data drives content, effects create synergies, events enable modularity. Keep it AWESOME! 🚀
