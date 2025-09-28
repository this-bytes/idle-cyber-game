-- Buff System - RPG-style temporary and permanent effects system
-- Provides stackable buffs for enhanced gameplay progression and strategy

local BuffSystem = {}
BuffSystem.__index = BuffSystem

-- Import buff data definitions
local BuffData = require("src.data.buffs")

-- Create new buff system
function BuffSystem.new(eventBus, resourceManager)
    local self = setmetatable({}, BuffSystem)
    
    -- Core dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Active buffs storage
    -- Format: [buffId] = {buff_data}
    self.activeBuffs = {}
    
    -- Load buff definitions from data file
    self.buffDefinitions = BuffData.getAllBuffs()
    
    -- Effect cache for performance
    self.effectCache = {
        resourceMultipliers = {},
        resourceGeneration = {},
        specialEffects = {},
        lastUpdated = 0
    }
    
    -- Validate buff system integrity
    local errors = BuffData.validateBuffs()
    if #errors > 0 then
        print("⚠️  Buff system validation errors:")
        for _, error in ipairs(errors) do
            print("   " .. error)
        end
    end
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Apply buff effects to resource manager
function BuffSystem:applyEffectsToResourceManager()
    if not self.resourceManager then return end
    
    local effects = self:getAggregatedEffects()
    
    -- Apply resource generation bonuses
    for resource, bonus in pairs(effects.resourceGeneration) do
        if bonus > 0 then
            self.resourceManager:addGeneration(resource, bonus)
        end
    end
    
    -- Apply resource multipliers
    for resource, multiplier in pairs(effects.resourceMultipliers) do
        if multiplier ~= 1.0 then
            self.resourceManager:setMultiplier(resource, multiplier)
        end
    end
end

-- Define a new buff type
function BuffSystem:defineBuffType(buffId, definition)
    self.buffDefinitions[buffId] = definition
end

-- Apply a buff to the system
function BuffSystem:applyBuff(buffId, sourceEntity, customDuration, customStacks)
    local definition = self.buffDefinitions[buffId]
    if not definition then
        print("⚠️ Unknown buff type: " .. buffId)
        return false
    end
    
    -- Generate unique instance ID for this buff application
    local instanceId = buffId .. "_" .. os.time() .. "_" .. math.random(1000)
    
    -- Create buff instance
    local buffInstance = {
        id = instanceId,
        type = buffId,
        name = definition.name,
        description = definition.description,
        icon = definition.icon or "⭐",
        category = definition.category,
        source = sourceEntity or "system",
        appliedAt = os.time(),
        duration = customDuration or definition.duration,
        remainingTime = customDuration or definition.duration,
        stacks = customStacks or 1,
        maxStacks = definition.maxStacks or 1,
        effects = definition.effects,
        stackable = definition.stackable or false,
        permanent = definition.type == "permanent"
    }
    
    -- Handle stacking logic
    if definition.stackable then
        local existingBuff = self:findExistingStackableBuff(buffId)
        if existingBuff then
            -- Add stacks to existing buff
            existingBuff.stacks = math.min(existingBuff.stacks + (customStacks or 1), definition.maxStacks or 999)
            existingBuff.remainingTime = math.max(existingBuff.remainingTime, buffInstance.remainingTime)
            self:invalidateEffectCache()
            
            self.eventBus:publish("buff_stacked", {
                buffId = buffId,
                stacks = existingBuff.stacks,
                maxStacks = definition.maxStacks
            })
            
            return true
        end
    elseif definition.type == "unique" then
        -- Remove existing instance of unique buff
        self:removeBuff(buffId)
    end
    
    -- Add new buff instance
    self.activeBuffs[instanceId] = buffInstance
    self:invalidateEffectCache()
    
    -- Publish buff applied event
    self.eventBus:publish("buff_applied", {
        buffId = buffId,
        instanceId = instanceId,
        duration = buffInstance.duration,
        stacks = buffInstance.stacks,
        source = sourceEntity
    })
    
    print("✨ Applied buff: " .. definition.name .. " (Stacks: " .. buffInstance.stacks .. ")")
    return true
end

-- Find existing stackable buff of the same type
function BuffSystem:findExistingStackableBuff(buffType)
    for instanceId, buff in pairs(self.activeBuffs) do
        if buff.type == buffType and buff.stackable then
            return buff
        end
    end
    return nil
end

-- Remove a specific buff instance
function BuffSystem:removeBuff(buffId)
    local removed = false
    for instanceId, buff in pairs(self.activeBuffs) do
        if buff.type == buffId or buff.id == buffId then
            self.activeBuffs[instanceId] = nil
            removed = true
            
            self.eventBus:publish("buff_removed", {
                buffId = buff.type,
                instanceId = instanceId
            })
            
            print("🔻 Removed buff: " .. buff.name)
        end
    end
    
    if removed then
        self:invalidateEffectCache()
    end
    
    return removed
end

-- Update buff timers and remove expired buffs
function BuffSystem:update(dt)
    local currentTime = os.time()
    local expiredBuffs = {}
    
    -- Update timers for temporary buffs
    for instanceId, buff in pairs(self.activeBuffs) do
        if not buff.permanent and buff.remainingTime then
            buff.remainingTime = buff.remainingTime - dt
            
            if buff.remainingTime <= 0 then
                table.insert(expiredBuffs, instanceId)
            end
        end
    end
    
    -- Remove expired buffs
    for _, instanceId in ipairs(expiredBuffs) do
        local buff = self.activeBuffs[instanceId]
        if buff then
            self.activeBuffs[instanceId] = nil
            
            self.eventBus:publish("buff_expired", {
                buffId = buff.type,
                instanceId = instanceId,
                name = buff.name
            })
            
            print("⏰ Buff expired: " .. buff.name)
        end
    end
    
    -- Invalidate cache if buffs changed
    if #expiredBuffs > 0 then
        self:invalidateEffectCache()
        self:applyEffectsToResourceManager()
    end
end

-- Get aggregated effects from all active buffs
function BuffSystem:getAggregatedEffects()
    local currentTime = os.time()
    
    -- Use cache if still valid (updated within last second)
    if currentTime - self.effectCache.lastUpdated < 1 then
        return self.effectCache
    end
    
    -- Recalculate effects
    local effects = {
        resourceMultipliers = {},
        resourceGeneration = {},
        specialEffects = {},
        lastUpdated = currentTime
    }
    
    -- Aggregate effects from all active buffs
    for instanceId, buff in pairs(self.activeBuffs) do
        local stackMultiplier = buff.stacks or 1
        
        -- Resource multipliers
        if buff.effects.resourceMultiplier then
            for resource, multiplier in pairs(buff.effects.resourceMultiplier) do
                if not effects.resourceMultipliers[resource] then
                    effects.resourceMultipliers[resource] = 1.0
                end
                -- Multiplicative stacking for resource multipliers
                effects.resourceMultipliers[resource] = effects.resourceMultipliers[resource] * 
                    (1 + (multiplier - 1) * stackMultiplier)
            end
        end
        
        -- Resource generation bonuses
        if buff.effects.resourceGeneration then
            for resource, generation in pairs(buff.effects.resourceGeneration) do
                if not effects.resourceGeneration[resource] then
                    effects.resourceGeneration[resource] = 0
                end
                -- Additive stacking for generation bonuses
                effects.resourceGeneration[resource] = effects.resourceGeneration[resource] + 
                    (generation * stackMultiplier)
            end
        end
        
        -- Special effects (efficiency, defense, etc.)
        for effectType, value in pairs(buff.effects) do
            if effectType ~= "resourceMultiplier" and effectType ~= "resourceGeneration" then
                if not effects.specialEffects[effectType] then
                    effects.specialEffects[effectType] = 0
                end
                -- Additive stacking for most special effects
                effects.specialEffects[effectType] = effects.specialEffects[effectType] + 
                    (value * stackMultiplier)
            end
        end
    end
    
    -- Cache the results
    self.effectCache = effects
    return effects
end

-- Invalidate effect cache to force recalculation
function BuffSystem:invalidateEffectCache()
    self.effectCache.lastUpdated = 0
end

-- Get all active buffs for display
function BuffSystem:getActiveBuffs()
    local buffs = {}
    for instanceId, buff in pairs(self.activeBuffs) do
        table.insert(buffs, {
            id = buff.id,
            type = buff.type,
            name = buff.name,
            description = buff.description,
            icon = buff.icon,
            stacks = buff.stacks,
            remainingTime = buff.remainingTime,
            permanent = buff.permanent,
            category = buff.category
        })
    end
    
    -- Sort by category and remaining time
    table.sort(buffs, function(a, b)
        if a.category ~= b.category then
            return a.category < b.category
        end
        if a.permanent ~= b.permanent then
            return a.permanent -- Permanent buffs first
        end
        return (a.remainingTime or 999999) > (b.remainingTime or 999999)
    end)
    
    return buffs
end

-- Subscribe to game events for automatic buff application
function BuffSystem:subscribeToEvents()
    -- Apply buffs on contract completion
    self.eventBus:subscribe("contract_completed", function(data)
        local contractValue = data.contract.budget or 1000
        local duration = math.min(600, 60 + contractValue * 0.1) -- Scale duration with contract value
        
        self:applyBuff("contract_efficiency_boost", "contract_system", duration)
        
        -- Chance for research boost on high-value contracts
        if contractValue > 5000 and math.random() < 0.3 then
            self:applyBuff("research_acceleration", "contract_system", 180)
        end
    end)
    
    -- Apply defensive buffs during/after crisis events
    self.eventBus:subscribe("crisis_resolved", function(data)
        local difficulty = data.difficulty or 1
        local duration = 300 + difficulty * 120 -- Scale with crisis difficulty
        local stacks = math.min(3, math.floor(difficulty / 2))
        
        self:applyBuff("threat_resistance", "crisis_system", duration, stacks)
    end)
    
    -- Apply focus buffs from player interactions
    self.eventBus:subscribe("player_interact", function(data)
        if data.department and data.department == "research" then
            self:applyBuff("focus_enhancement", "player_interaction", 240)
        end
    end)
    
    -- Apply permanent buffs from upgrades
    self.eventBus:subscribe("upgrade_purchased", function(data)
        if data.upgradeId == "advancedInfrastructure" then
            self:applyBuff("advanced_infrastructure", "upgrade_system")
        elseif data.upgradeId == "eliteTraining" then
            self:applyBuff("elite_training", "upgrade_system")
        end
    end)
    
    -- Apply buffs from skill progression
    self.eventBus:subscribe("skill_leveled", function(data)
        if data.skillId == "focus_mastery" then
            self:applyBuff("focus_enhancement", "skill_system", 300, data.level)
        end
    end)
end

-- Clear all buffs (for testing or prestige)
function BuffSystem:clearAllBuffs()
    local count = 0
    for instanceId, buff in pairs(self.activeBuffs) do
        if not buff.permanent then
            self.activeBuffs[instanceId] = nil
            count = count + 1
        end
    end
    
    self:invalidateEffectCache()
    
    if count > 0 then
        self.eventBus:publish("buffs_cleared", {count = count})
        print("🧹 Cleared " .. count .. " temporary buffs")
    end
    
    return count
end

-- Save buff state
function BuffSystem:getState()
    local state = {
        activeBuffs = {},
        buffDefinitions = self.buffDefinitions
    }
    
    -- Only save non-expired buffs
    local currentTime = os.time()
    for instanceId, buff in pairs(self.activeBuffs) do
        if buff.permanent or (buff.remainingTime and buff.remainingTime > 0) then
            state.activeBuffs[instanceId] = buff
        end
    end
    
    return state
end

-- Load buff state
function BuffSystem:loadState(state)
    if not state then return end
    
    if state.activeBuffs then
        self.activeBuffs = state.activeBuffs
        self:invalidateEffectCache()
    end
    
    if state.buffDefinitions then
        -- Merge with existing definitions, allowing for updates
        for buffId, definition in pairs(state.buffDefinitions) do
            self.buffDefinitions[buffId] = definition
        end
    end
end

return BuffSystem