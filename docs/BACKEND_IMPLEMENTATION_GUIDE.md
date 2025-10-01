# 🔧 Backend Implementation Guide

## Quick Start: Building the AWESOME Backend

This guide provides concrete implementation steps and code examples for transforming the backend architecture.

---

## 📦 Phase 1: Item Registry System

### Step 1.1: Create the ItemRegistry

**File: `src/core/item_registry.lua`**

```lua
-- ItemRegistry - Universal item loading and validation system
-- Loads all game items from JSON and provides unified access

local ItemRegistry = {}
ItemRegistry.__index = ItemRegistry

function ItemRegistry.new(dataManager)
    local self = setmetatable({}, ItemRegistry)
    self.dataManager = dataManager
    
    -- Item storage by type
    self.items = {
        contract = {},
        specialist = {},
        upgrade = {},
        threat = {},
        event = {},
        synergy = {}
    }
    
    -- Quick lookup by ID (across all types)
    self.itemsById = {}
    
    -- Tags index for fast queries
    self.itemsByTag = {}
    
    return self
end

function ItemRegistry:initialize()
    print("🗂️ Initializing Item Registry...")
    
    -- Load all item types
    self:loadItemType("contracts", "contract")
    self:loadItemType("specialists", "specialist")
    self:loadItemType("upgrades", "upgrade")
    self:loadItemType("threats", "threat")
    self:loadItemType("events", "event")
    
    -- Build indices
    self:buildIndices()
    
    print("✅ Item Registry initialized with " .. self:getTotalItemCount() .. " items")
end

function ItemRegistry:loadItemType(dataKey, itemType)
    local data = self.dataManager:getData(dataKey)
    
    if not data then
        print("⚠️ No data found for: " .. dataKey)
        return
    end
    
    -- Handle different data structures
    local items = data
    if type(data) == "table" and data[dataKey] then
        items = data[dataKey]
    end
    
    if type(items) ~= "table" then
        print("⚠️ Invalid data structure for: " .. dataKey)
        return
    end
    
    -- Load each item
    local count = 0
    for _, itemData in ipairs(items) do
        -- Ensure type is set
        itemData.type = itemData.type or itemType
        
        -- Validate and register
        if self:validateItem(itemData) then
            self:registerItem(itemData)
            count = count + 1
        end
    end
    
    print("  📄 Loaded " .. count .. " " .. itemType .. " items")
end

function ItemRegistry:validateItem(item)
    -- Basic validation
    if not item.id then
        print("❌ Item missing ID: " .. (item.displayName or "unknown"))
        return false
    end
    
    if not item.type then
        print("❌ Item missing type: " .. item.id)
        return false
    end
    
    -- Check for duplicate IDs
    if self.itemsById[item.id] then
        print("❌ Duplicate item ID: " .. item.id)
        return false
    end
    
    return true
end

function ItemRegistry:registerItem(item)
    -- Store by type
    if not self.items[item.type] then
        self.items[item.type] = {}
    end
    table.insert(self.items[item.type], item)
    
    -- Store by ID for quick lookup
    self.itemsById[item.id] = item
end

function ItemRegistry:buildIndices()
    -- Build tag index
    self.itemsByTag = {}
    
    for id, item in pairs(self.itemsById) do
        if item.tags then
            for _, tag in ipairs(item.tags) do
                if not self.itemsByTag[tag] then
                    self.itemsByTag[tag] = {}
                end
                table.insert(self.itemsByTag[tag], item)
            end
        end
    end
end

-- Query methods
function ItemRegistry:getItem(id)
    return self.itemsById[id]
end

function ItemRegistry:getItemsByType(itemType)
    return self.items[itemType] or {}
end

function ItemRegistry:getItemsByTag(tag)
    return self.itemsByTag[tag] or {}
end

function ItemRegistry:queryItems(filter)
    local results = {}
    
    for id, item in pairs(self.itemsById) do
        if self:matchesFilter(item, filter) then
            table.insert(results, item)
        end
    end
    
    return results
end

function ItemRegistry:matchesFilter(item, filter)
    -- Type filter
    if filter.type and item.type ~= filter.type then
        return false
    end
    
    -- Tag filter
    if filter.tags then
        if not item.tags then return false end
        for _, requiredTag in ipairs(filter.tags) do
            local hasTag = false
            for _, itemTag in ipairs(item.tags) do
                if itemTag == requiredTag then
                    hasTag = true
                    break
                end
            end
            if not hasTag then return false end
        end
    end
    
    -- Rarity filter
    if filter.rarity and item.rarity ~= filter.rarity then
        return false
    end
    
    return true
end

function ItemRegistry:getTotalItemCount()
    local count = 0
    for id, _ in pairs(self.itemsById) do
        count = count + 1
    end
    return count
end

return ItemRegistry
```

---

## 🎯 Phase 1: Effect Processor

### Step 1.2: Create the EffectProcessor

**File: `src/core/effect_processor.lua`**

```lua
-- EffectProcessor - Universal effect calculation system
-- Processes passive and active effects from all game items

local EffectProcessor = {}
EffectProcessor.__index = EffectProcessor

function EffectProcessor.new(eventBus)
    local self = setmetatable({}, EffectProcessor)
    self.eventBus = eventBus
    
    -- Track active effects
    self.activeEffects = {}
    
    -- Effect handlers by type
    self.effectHandlers = {}
    self:registerDefaultHandlers()
    
    return self
end

function EffectProcessor:registerDefaultHandlers()
    -- Income multiplier
    self.effectHandlers["income_multiplier"] = function(effect, context)
        return {
            mode = "multiply",
            value = effect.value,
            applies = self:matchesTarget(effect.target, context)
        }
    end
    
    -- Threat reduction
    self.effectHandlers["threat_reduction"] = function(effect, context)
        return {
            mode = "multiply",
            value = 1 - effect.value, -- Reduction is inverse multiplier
            applies = self:matchesTarget(effect.target, context)
        }
    end
    
    -- Efficiency boost
    self.effectHandlers["efficiency_boost"] = function(effect, context)
        return {
            mode = "multiply",
            value = effect.value,
            applies = self:matchesTarget(effect.target, context)
        }
    end
    
    -- Resource generation
    self.effectHandlers["generate_resource"] = function(effect, context)
        return {
            mode = "add",
            value = effect.value,
            applies = true
        }
    end
    
    -- Cooldown reduction
    self.effectHandlers["cooldown_reduction"] = function(effect, context)
        return {
            mode = "multiply",
            value = 1 - effect.value,
            applies = self:matchesTarget(effect.target, context)
        }
    end
end

function EffectProcessor:calculateValue(baseValue, effectType, context)
    local multipliers = 1.0
    local additive = 0
    local overrides = nil
    
    -- Collect all active items with effects
    local activeItems = context.activeItems or {}
    
    for _, item in ipairs(activeItems) do
        if item.effects and item.effects.passive then
            for _, effect in ipairs(item.effects.passive) do
                if effect.type == effectType then
                    local handler = self.effectHandlers[effect.type]
                    if handler then
                        local result = handler(effect, context)
                        
                        if result.applies then
                            if result.mode == "multiply" then
                                multipliers = multipliers * result.value
                            elseif result.mode == "add" then
                                additive = additive + result.value
                            elseif result.mode == "override" then
                                overrides = result.value
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Apply soft caps to prevent runaway growth
    multipliers = self:applySoftCap(multipliers, context.soft_cap)
    
    if overrides then return overrides end
    return (baseValue + additive) * multipliers
end

function EffectProcessor:applySoftCap(value, cap)
    if not cap then return value end
    
    -- Logarithmic soft cap
    if value <= cap then
        return value
    else
        local excess = value - cap
        return cap + math.log(1 + excess) * (cap * 0.1)
    end
end

function EffectProcessor:matchesTarget(target, context)
    if not target or target == "all" then
        return true
    end
    
    -- Check if context has matching tags
    if type(target) == "string" and context.tags then
        for _, tag in ipairs(context.tags) do
            if tag == target then
                return true
            end
        end
    end
    
    -- Check if context type matches
    if type(target) == "string" and context.type == target then
        return true
    end
    
    return false
end

function EffectProcessor:registerEffectHandler(effectType, handler)
    self.effectHandlers[effectType] = handler
end

function EffectProcessor:getActiveEffectSummary(context)
    local summary = {
        multipliers = {},
        additives = {},
        special = {}
    }
    
    local activeItems = context.activeItems or {}
    
    for _, item in ipairs(activeItems) do
        if item.effects and item.effects.passive then
            for _, effect in ipairs(item.effects.passive) do
                if self:matchesTarget(effect.target, context) then
                    local effectType = effect.type
                    
                    if effect.mode == "multiply" or 
                       self.effectHandlers[effectType] and 
                       self.effectHandlers[effectType](effect, context).mode == "multiply" then
                        
                        if not summary.multipliers[effectType] then
                            summary.multipliers[effectType] = 1.0
                        end
                        summary.multipliers[effectType] = 
                            summary.multipliers[effectType] * effect.value
                    elseif effect.mode == "add" then
                        if not summary.additives[effectType] then
                            summary.additives[effectType] = 0
                        end
                        summary.additives[effectType] = 
                            summary.additives[effectType] + effect.value
                    else
                        table.insert(summary.special, {
                            item = item.id,
                            effect = effect
                        })
                    end
                end
            end
        end
    end
    
    return summary
end

return EffectProcessor
```

---

## 🧮 Phase 1: Formula Engine

### Step 1.3: Create the FormulaEngine

**File: `src/core/formula_engine.lua`**

```lua
-- FormulaEngine - Safe evaluation of data-driven formulas
-- Enables designers to define complex calculations in JSON

local FormulaEngine = {}

-- Safe math environment for formula evaluation
local function createSafeEnv()
    return {
        -- Math functions
        abs = math.abs,
        ceil = math.ceil,
        floor = math.floor,
        max = math.max,
        min = math.min,
        sqrt = math.sqrt,
        log = math.log,
        exp = math.exp,
        
        -- Custom game functions
        pow = function(a, b) return a ^ b end,
        clamp = function(val, min, max) 
            return math.max(min, math.min(max, val))
        end,
        lerp = function(a, b, t)
            return a + (b - a) * t
        end,
        
        -- Constants
        pi = math.pi,
        e = math.exp(1),
    }
end

function FormulaEngine.evaluate(formula, variables)
    if type(formula) ~= "string" then
        print("❌ Formula must be a string")
        return 0
    end
    
    -- Create safe environment
    local env = createSafeEnv()
    
    -- Inject variables
    if variables then
        for k, v in pairs(variables) do
            if type(v) == "number" then
                env[k] = v
            end
        end
    end
    
    -- Compile formula
    local func, err = load("return " .. formula, "formula", "t", env)
    
    if not func then
        print("❌ Formula compilation error: " .. tostring(err))
        print("   Formula: " .. formula)
        return 0
    end
    
    -- Execute with error handling
    local success, result = pcall(func)
    
    if not success then
        print("❌ Formula execution error: " .. tostring(result))
        print("   Formula: " .. formula)
        return 0
    end
    
    -- Ensure result is a number
    if type(result) ~= "number" then
        print("❌ Formula must return a number, got: " .. type(result))
        return 0
    end
    
    -- Check for invalid results
    if result ~= result then -- NaN check
        print("❌ Formula returned NaN")
        return 0
    end
    
    if result == math.huge or result == -math.huge then
        print("❌ Formula returned infinity")
        return 0
    end
    
    return result
end

function FormulaEngine.test()
    print("🧪 Testing FormulaEngine...")
    
    local tests = {
        {
            formula = "base * (1 + level * 0.05)",
            vars = {base = 100, level = 5},
            expected = 125
        },
        {
            formula = "base * pow(growth, count)",
            vars = {base = 100, growth = 1.15, count = 3},
            expected = 152.0875
        },
        {
            formula = "min(max_value, base * multiplier)",
            vars = {base = 100, multiplier = 5, max_value = 400},
            expected = 400
        },
        {
            formula = "floor(base * (1 + sqrt(level)))",
            vars = {base = 100, level = 9},
            expected = 400
        },
        {
            formula = "clamp(value, 0, 100)",
            vars = {value = 150},
            expected = 100
        }
    }
    
    local passed = 0
    for i, test in ipairs(tests) do
        local result = FormulaEngine.evaluate(test.formula, test.vars)
        local diff = math.abs(result - test.expected)
        if diff < 0.0001 then
            print("  ✅ Test " .. i .. " passed")
            passed = passed + 1
        else
            print("  ❌ Test " .. i .. " failed")
            print("     Expected: " .. test.expected)
            print("     Got: " .. result)
        end
    end
    
    print("🧪 Tests completed: " .. passed .. "/" .. #tests .. " passed")
end

return FormulaEngine
```

---

## 🎲 Phase 3: Procedural Generation

### Step 3.1: Create the ProcGen System

**File: `src/core/proc_gen.lua`**

```lua
-- ProcGen - Procedural content generation system
-- Creates unique game items from templates

local ProcGen = {}
ProcGen.__index = ProcGen

function ProcGen.new(itemRegistry, formulaEngine)
    local self = setmetatable({}, ProcGen)
    self.itemRegistry = itemRegistry
    self.formulaEngine = formulaEngine
    
    -- Name generation parts
    self.nameParts = {
        adjectives = {
            "Agile", "Secure", "Digital", "Cloud", "Quantum", "Cyber",
            "Smart", "Rapid", "Global", "Dynamic", "Elite", "Prime"
        },
        techNouns = {
            "Systems", "Solutions", "Technologies", "Networks", "Security",
            "Data", "Analytics", "Platforms", "Services", "Labs"
        },
        companySuffixes = {
            "Inc", "Corp", "LLC", "Ltd", "Group", "Partners", "Ventures"
        },
        founderNames = {
            "Alice", "Bob", "Carol", "Dave", "Eve", "Frank", "Grace"
        }
    }
    
    math.randomseed(os.time())
    
    return self
end

function ProcGen:generateContract(template, playerContext)
    -- Get base template
    local baseItem = self.itemRegistry:getItem(template.base_template)
    if not baseItem then
        print("❌ Base template not found: " .. template.base_template)
        return nil
    end
    
    -- Deep copy base
    local generated = self:deepCopy(baseItem)
    
    -- Generate unique ID
    generated.id = "proc_" .. self:generateUUID()
    
    -- Apply variations
    if template.variations then
        -- Generate name
        if template.variations.client_name then
            generated.clientName = self:generateName(
                template.variations.client_name
            )
        end
        
        -- Apply risk multiplier
        if template.variations.risk_multiplier then
            local riskMult = self:sampleDistribution(
                template.variations.risk_multiplier
            )
            generated.riskMultiplier = riskMult
            
            -- Scale difficulty
            if generated.riskLevel then
                if riskMult > 1.5 then
                    generated.riskLevel = "EXTREME"
                elseif riskMult > 1.2 then
                    generated.riskLevel = "HIGH"
                elseif riskMult < 0.8 then
                    generated.riskLevel = "LOW"
                end
            end
        end
        
        -- Calculate scaled budget
        if template.variations.budget_scaling then
            generated.baseBudget = self.formulaEngine.evaluate(
                template.variations.budget_scaling.formula,
                {
                    base = baseItem.baseBudget,
                    player_level = playerContext.level or 1,
                    risk_multiplier = generated.riskMultiplier or 1.0,
                    random = function(min, max)
                        return min + math.random() * (max - min)
                    end
                }
            )
        end
        
        -- Add special modifiers
        if template.variations.special_modifiers then
            generated.modifiers = self:rollWeightedTable(
                template.variations.special_modifiers
            )
        end
    end
    
    -- Add procedural tag
    if not generated.tags then generated.tags = {} end
    table.insert(generated.tags, "procedural")
    
    return generated
end

function ProcGen:generateName(template)
    -- Simple template parser: {{category}}
    local name = template[math.random(#template)]
    
    for category, values in pairs(self.nameParts) do
        local pattern = "{{" .. category .. "}}"
        if name:find(pattern, 1, true) then
            local replacement = values[math.random(#values)]
            name = name:gsub(pattern, replacement, 1)
        end
    end
    
    return name
end

function ProcGen:sampleDistribution(dist)
    if dist.distribution == "uniform" then
        return dist.min + math.random() * (dist.max - dist.min)
    elseif dist.distribution == "normal" then
        -- Box-Muller transform for normal distribution
        local u1 = math.random()
        local u2 = math.random()
        local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
        
        local value = dist.mean + z0 * dist.stddev
        
        -- Clamp to min/max
        if dist.min then value = math.max(value, dist.min) end
        if dist.max then value = math.min(value, dist.max) end
        
        return value
    else
        return dist.mean or 1.0
    end
end

function ProcGen:rollWeightedTable(table)
    -- Calculate total weight
    local totalWeight = 0
    for _, entry in ipairs(table) do
        totalWeight = totalWeight + entry.weight
    end
    
    -- Roll random value
    local roll = math.random() * totalWeight
    
    -- Find matching entry
    local accumulated = 0
    for _, entry in ipairs(table) do
        accumulated = accumulated + entry.weight
        if roll <= accumulated then
            return entry.value
        end
    end
    
    return nil
end

function ProcGen:generateUUID()
    -- Simple UUID v4 generation
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

function ProcGen:deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for k, v in pairs(original) do
            copy[k] = self:deepCopy(v)
        end
    else
        copy = original
    end
    return copy
end

return ProcGen
```

---

## 📊 Integration Example

### Step 4.1: Update ContractSystem to use new architecture

**File: `src/systems/contract_system_enhanced.lua`** (example integration)

```lua
local ContractSystem = {}
ContractSystem.__index ContractSystem

function ContractSystem.new(eventBus, itemRegistry, effectProcessor)
    local self = setmetatable({}, ContractSystem)
    self.eventBus = eventBus
    self.itemRegistry = itemRegistry
    self.effectProcessor = effectProcessor
    
    self.activeContracts = {}
    self.availableContracts = {}
    
    return self
end

function ContractSystem:generateIncome(dt)
    local totalIncome = 0
    
    for id, activeContract in pairs(self.activeContracts) do
        -- Get contract item definition
        local contractItem = self.itemRegistry:getItem(activeContract.itemId)
        
        if contractItem then
            -- Build context for effect calculation
            local context = {
                type = "contract",
                tags = contractItem.tags,
                activeItems = self:getActiveEffectItems(),
                soft_cap = 10.0 -- Prevent runaway growth
            }
            
            -- Calculate income with all active effects
            local baseIncome = contractItem.baseBudget / contractItem.baseDuration
            local effectiveIncome = self.effectProcessor:calculateValue(
                baseIncome,
                "income_multiplier",
                context
            )
            
            totalIncome = totalIncome + (effectiveIncome * dt)
        end
    end
    
    if totalIncome > 0 then
        self.eventBus:publish("resource_add", {
            money = totalIncome
        })
    end
end

function ContractSystem:getActiveEffectItems()
    local items = {}
    
    -- Include all purchased upgrades
    local upgrades = self.upgradeSystem:getPurchasedUpgrades()
    for _, upgrade in ipairs(upgrades) do
        local item = self.itemRegistry:getItem(upgrade.id)
        if item then
            table.insert(items, item)
        end
    end
    
    -- Include all active specialists
    local specialists = self.specialistSystem:getActiveSpecialists()
    for _, specialist in ipairs(specialists) do
        local item = self.itemRegistry:getItem(specialist.itemId)
        if item then
            table.insert(items, item)
        end
    end
    
    return items
end

return ContractSystem
```

---

## 🎯 Testing the New Systems

### Test File: `tests/systems/test_awesome_backend.lua`

```lua
local ItemRegistry = require("src.core.item_registry")
local EffectProcessor = require("src.core.effect_processor")
local FormulaEngine = require("src.core.formula_engine")

local function runTests()
    print("\n🧪 Testing AWESOME Backend Systems\n")
    
    -- Test FormulaEngine
    print("Testing FormulaEngine...")
    FormulaEngine.test()
    
    -- Test EffectProcessor
    print("\nTesting EffectProcessor...")
    local eventBus = {} -- Mock
    local processor = EffectProcessor.new(eventBus)
    
    local mockContext = {
        tags = {"fintech", "enterprise"},
        activeItems = {
            {
                id = "upgrade_income_boost",
                effects = {
                    passive = {
                        {type = "income_multiplier", value = 1.5, target = "all"}
                    }
                }
            }
        }
    }
    
    local baseIncome = 100
    local effectiveIncome = processor:calculateValue(
        baseIncome,
        "income_multiplier",
        mockContext
    )
    
    print("  Base income: " .. baseIncome)
    print("  Effective income: " .. effectiveIncome)
    print("  Expected: 150")
    
    if math.abs(effectiveIncome - 150) < 0.001 then
        print("  ✅ Effect calculation correct")
    else
        print("  ❌ Effect calculation failed")
    end
    
    print("\n✅ All tests completed!")
end

return runTests
```

---

## 🚀 Quick Start Checklist

### Day 1: Foundation
- [ ] Create `src/core/item_registry.lua`
- [ ] Create `src/core/effect_processor.lua`
- [ ] Create `src/core/formula_engine.lua`
- [ ] Add tests for each system
- [ ] Run tests: `lua tests/systems/test_awesome_backend.lua`

### Day 2: Data Migration
- [ ] Update contract JSON to include `tags` and `effects`
- [ ] Update specialist JSON to include `effects`
- [ ] Update upgrade JSON to include `effects`
- [ ] Validate all JSON files

### Day 3: Integration
- [ ] Integrate ItemRegistry into game initialization
- [ ] Update ContractSystem to use EffectProcessor
- [ ] Update SpecialistSystem to use EffectProcessor
- [ ] Test in-game

### Day 4: Advanced Features
- [ ] Create `src/core/proc_gen.lua`
- [ ] Add procedural contract generation
- [ ] Create synergy definitions
- [ ] Test procedural generation

### Day 5: Polish
- [ ] Add error handling and logging
- [ ] Performance profiling
- [ ] Documentation updates
- [ ] Create examples for designers

---

## 📝 Example JSON Updates

### contracts.json (updated)
```json
[
  {
    "id": "basic_small_business",
    "type": "contract",
    "clientName": "Small Business",
    "description": "Provide basic security audit and recommendations.",
    "baseBudget": 100,
    "baseDuration": 30,
    "reputationReward": 1,
    "riskLevel": "LOW",
    "tags": ["small_business", "audit", "beginner"],
    "effects": {
      "passive": [
        {"type": "generate_resource", "resource": "reputation", "value": 0.033}
      ]
    },
    "requirements": {},
    "metadata": {
      "icon": "contract_small.png",
      "category": "tier_1"
    }
  }
]
```

### upgrades.json (updated)
```json
{
  "upgrades": [
    {
      "id": "advanced_firewall",
      "type": "upgrade",
      "name": "Advanced Firewall",
      "description": "Reduces threat success rate by 15%",
      "cost": {"money": 500},
      "tags": ["infrastructure", "defense"],
      "effects": {
        "passive": [
          {"type": "threat_reduction", "value": 0.15, "target": "all"}
        ]
      },
      "metadata": {
        "icon": "firewall.png",
        "category": "defense"
      }
    }
  ]
}
```

---

## 🎉 Success Metrics

After implementation, you should be able to:

✅ Add a new contract type in <5 minutes (pure JSON)  
✅ Create complex cross-system effects without code changes  
✅ Test balance changes with hot-reload  
✅ Generate procedural content that feels unique  
✅ Query items by tags, type, or properties  
✅ Calculate effects correctly across all systems  

---

**Next Steps**: Start with ItemRegistry and FormulaEngine, then gradually migrate existing systems to use the new architecture. The beauty is that it's all backwards-compatible!
