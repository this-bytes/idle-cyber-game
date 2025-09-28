#!/usr/bin/env lua5.3
-- Buff System Demo - Demonstrates the RPG-style buffs and stacks system
-- This script shows how the buff system works independently and within the game context

print("🔮 Cyberspace Tycoon - Buff System Demo")
print("=====================================")

-- Add current directory to package path so we can require our modules
package.path = package.path .. ";./src/?.lua;./src/?/init.lua"

-- Mock LÖVE 2D functions for headless testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = love.timer.getTime or function() return os.clock() end

-- Import required systems
local BuffSystem = require("src.systems.buff_system")
local BuffData = require("src.data.buffs")

-- Mock event bus for demo
local MockEventBus = {}
function MockEventBus.new()
    local self = {}
    self.events = {}
    
    function self:publish(eventName, data)
        if not self.events[eventName] then
            self.events[eventName] = {}
        end
        table.insert(self.events[eventName], data)
        print("📨 Event published: " .. eventName)
    end
    
    function self:subscribe(eventName, callback)
        -- In real implementation, this would store callbacks
        print("📬 Subscribed to event: " .. eventName)
    end
    
    return self
end

-- Mock resource manager for demo
local MockResourceManager = {}
function MockResourceManager.new()
    local self = {}
    self.multipliers = {}
    self.generation = {}
    
    function self:setMultiplier(resource, multiplier)
        self.multipliers[resource] = multiplier
        print("💰 Resource multiplier set: " .. resource .. " = " .. multiplier)
    end
    
    function self:addGeneration(resource, amount)
        self.generation[resource] = (self.generation[resource] or 0) + amount
        print("⚡ Resource generation added: " .. resource .. " +" .. amount)
    end
    
    return self
end

-- Demo function: Basic buff operations
local function demoBasicBuffs()
    print("\n🔮 Demo 1: Basic Buff Operations")
    print("----------------------------------")
    
    local eventBus = MockEventBus.new()
    local resourceManager = MockResourceManager.new()
    local buffSystem = BuffSystem.new(eventBus, resourceManager)
    
    -- Apply some basic buffs
    print("Applying contract efficiency boost...")
    buffSystem:applyBuff("contract_efficiency_boost", "demo_source")
    
    print("Applying focus enhancement with 3 stacks...")
    buffSystem:applyBuff("focus_enhancement", "demo_source", nil, 3)
    
    print("Applying threat resistance...")
    buffSystem:applyBuff("threat_resistance", "demo_source", 300)
    
    -- Show active buffs
    local activeBuffs = buffSystem:getActiveBuffs()
    print("\n📋 Active Buffs (" .. #activeBuffs .. " total):")
    for i, buff in ipairs(activeBuffs) do
        local timeStr = buff.permanent and "∞" or (buff.remainingTime and string.format("%.1fs", buff.remainingTime) or "N/A")
        local stackStr = (buff.stacks and buff.stacks > 1) and (" x" .. buff.stacks) or ""
        print("  " .. i .. ". " .. buff.icon .. " " .. buff.name .. stackStr .. " (" .. timeStr .. ")")
    end
    
    return buffSystem
end

-- Demo function: Effect aggregation
local function demoEffectAggregation()
    print("\n🔮 Demo 2: Effect Aggregation")
    print("------------------------------")
    
    local eventBus = MockEventBus.new()
    local resourceManager = MockResourceManager.new()
    local buffSystem = BuffSystem.new(eventBus, resourceManager)
    
    -- Apply multiple buffs with overlapping effects
    buffSystem:applyBuff("contract_efficiency_boost", "source1", nil, 2)  -- efficiency +0.15*2
    buffSystem:applyBuff("focus_enhancement", "source2", nil, 3)          -- efficiency +0.1*3
    buffSystem:applyBuff("client_satisfaction", "source3")                -- money multiplier 1.3
    
    -- Get aggregated effects
    local effects = buffSystem:getAggregatedEffects()
    
    print("📊 Aggregated Effects:")
    print("  Resource Multipliers:")
    for resource, multiplier in pairs(effects.resourceMultipliers) do
        print("    " .. resource .. ": " .. string.format("%.2fx", multiplier))
    end
    
    print("  Resource Generation Bonuses:")
    for resource, bonus in pairs(effects.resourceGeneration) do
        print("    " .. resource .. ": +" .. bonus .. "/sec")
    end
    
    print("  Special Effects:")
    for effect, value in pairs(effects.specialEffects) do
        print("    " .. effect .. ": +" .. string.format("%.2f", value * 100) .. "%")
    end
    
    return buffSystem
end

-- Demo function: Buff stacking
local function demoBuffStacking()
    print("\n🔮 Demo 3: Buff Stacking")
    print("-------------------------")
    
    local eventBus = MockEventBus.new()
    local resourceManager = MockResourceManager.new()
    local buffSystem = BuffSystem.new(eventBus, resourceManager)
    
    print("Applying focus enhancement buffs with different stack amounts...")
    
    -- Apply stackable buff multiple times
    buffSystem:applyBuff("focus_enhancement", "source1", nil, 2)
    print("After first application: 2 stacks")
    
    buffSystem:applyBuff("focus_enhancement", "source2", nil, 3)
    print("After second application: 5 stacks (2+3)")
    
    buffSystem:applyBuff("focus_enhancement", "source3", nil, 10)
    print("After third application: 10 stacks (capped at max)")
    
    local activeBuffs = buffSystem:getActiveBuffs()
    for _, buff in ipairs(activeBuffs) do
        if buff.type == "focus_enhancement" then
            print("Final stacks: " .. buff.stacks .. " (max: 10)")
            break
        end
    end
    
    return buffSystem
end

-- Demo function: Permanent vs temporary buffs
local function demoPermanentBuffs()
    print("\n🔮 Demo 4: Permanent vs Temporary Buffs")
    print("----------------------------------------")
    
    local eventBus = MockEventBus.new()
    local resourceManager = MockResourceManager.new()
    local buffSystem = BuffSystem.new(eventBus, resourceManager)
    
    -- Apply permanent buff
    buffSystem:applyBuff("advanced_infrastructure", "upgrade_source")
    print("Applied permanent infrastructure buff")
    
    -- Apply temporary buff
    buffSystem:applyBuff("contract_efficiency_boost", "contract_source", 2) -- 2 seconds
    print("Applied temporary efficiency buff (2 seconds)")
    
    print("\nBefore time passes:")
    local activeBuffs = buffSystem:getActiveBuffs()
    for _, buff in ipairs(activeBuffs) do
        local type_str = buff.permanent and "PERMANENT" or "TEMPORARY"
        print("  " .. buff.name .. " (" .. type_str .. ")")
    end
    
    -- Simulate time passing
    print("\nSimulating 3 seconds passing...")
    buffSystem:update(3)
    
    print("After time passes:")
    activeBuffs = buffSystem:getActiveBuffs()
    for _, buff in ipairs(activeBuffs) do
        local type_str = buff.permanent and "PERMANENT" or "TEMPORARY"
        print("  " .. buff.name .. " (" .. type_str .. ")")
    end
    
    return buffSystem
end

-- Demo function: Event-driven buff application
local function demoEventDrivenBuffs()
    print("\n🔮 Demo 5: Event-Driven Buff Application")
    print("-----------------------------------------")
    
    local eventBus = MockEventBus.new()
    local resourceManager = MockResourceManager.new()
    local buffSystem = BuffSystem.new(eventBus, resourceManager)
    
    print("Buffs are automatically applied when game events occur:")
    print("- Contract completion → Efficiency boost")
    print("- Crisis resolution → Threat resistance")
    print("- Player interactions → Focus enhancement")
    print("- Upgrades purchased → Permanent infrastructure buffs")
    print("- Skill progression → Various specialized buffs")
    
    print("\nThis integration happens through the event bus system,")
    print("making the buff system highly modular and extensible.")
    
    return buffSystem
end

-- Demo function: Buff data validation
local function demoBuffDataValidation()
    print("\n🔮 Demo 6: Buff Data Validation")
    print("--------------------------------")
    
    print("Validating buff data integrity...")
    local errors = BuffData.validateBuffs()
    
    if #errors == 0 then
        print("✅ All buff definitions are valid!")
        
        local allBuffs = BuffData.getAllBuffs()
        local buffCount = 0
        local categories = {}
        
        for buffId, buff in pairs(allBuffs) do
            buffCount = buffCount + 1
            categories[buff.category] = (categories[buff.category] or 0) + 1
        end
        
        print("📊 Buff Statistics:")
        print("  Total buffs: " .. buffCount)
        for category, count in pairs(categories) do
            print("  " .. category .. ": " .. count .. " buffs")
        end
    else
        print("❌ Found " .. #errors .. " validation errors:")
        for _, error in ipairs(errors) do
            print("  - " .. error)
        end
    end
end

-- Run all demos
local function runAllDemos()
    print("Starting buff system demonstrations...")
    
    demoBasicBuffs()
    demoEffectAggregation()
    demoBuffStacking()
    demoPermanentBuffs()
    demoEventDrivenBuffs()
    demoBuffDataValidation()
    
    print("\n🎉 All demos completed successfully!")
    print("The buff system is ready for integration into Cyberspace Tycoon.")
    print("Players can now enjoy RPG-style progression with stackable effects!")
end

-- Execute demos
runAllDemos()