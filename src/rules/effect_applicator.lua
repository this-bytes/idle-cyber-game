-- Effect Applicator Interface - Rules Engine Component
-- Configurable interface for effect application rules
-- Architected for future binding to external data/config formats

local EffectApplicator = {}
EffectApplicator.__index = EffectApplicator

-- Create new effect applicator
function EffectApplicator.new()
    local self = setmetatable({}, EffectApplicator)
    
    -- Effect application rules (placeholder interfaces)
    self.effects = {}
    self.modifiers = {}
    self.triggers = {}
    
    return self
end

-- Interface: Apply immediate effects (stat changes, resource modifications)
function EffectApplicator:applyImmediateEffects(effectId, targetState, context)
    -- TODO: Load effect definitions from external data/config
    -- Placeholder implementation
    
    local effectData = self:getEffectData(effectId)
    if not effectData then
        return false, "Effect not found: " .. effectId
    end
    
    local results = {}
    
    -- Apply stat modifications
    if effectData.statChanges then
        for stat, change in pairs(effectData.statChanges) do
            local oldValue = targetState[stat] or 0
            local newValue = oldValue + change
            
            targetState[stat] = newValue
            
            table.insert(results, {
                type = "stat_change",
                stat = stat,
                oldValue = oldValue,
                newValue = newValue,
                change = change
            })
        end
    end
    
    -- Apply resource modifications
    if effectData.resourceChanges then
        for resource, change in pairs(effectData.resourceChanges) do
            local oldValue = targetState[resource] or 0
            local newValue = math.max(0, oldValue + change) -- Prevent negative resources
            
            targetState[resource] = newValue
            
            table.insert(results, {
                type = "resource_change", 
                resource = resource,
                oldValue = oldValue,
                newValue = newValue,
                change = change
            })
        end
    end
    
    return true, results
end

-- Interface: Apply persistent effects (ongoing modifiers)
function EffectApplicator:applyPersistentEffects(effectId, targetState, duration)
    -- TODO: Load from external config
    -- Placeholder implementation
    
    local effectData = self:getEffectData(effectId)
    if not effectData or not effectData.persistentEffects then
        return false, "No persistent effects found for: " .. effectId
    end
    
    -- Initialize persistent effects storage if needed
    if not targetState.persistentEffects then
        targetState.persistentEffects = {}
    end
    
    local persistentEffect = {
        effectId = effectId,
        effects = effectData.persistentEffects,
        duration = duration or -1, -- -1 = permanent
        startTime = os.time(),
        active = true
    }
    
    table.insert(targetState.persistentEffects, persistentEffect)
    
    return true, persistentEffect
end

-- Interface: Remove persistent effects
function EffectApplicator:removePersistentEffect(effectId, targetState)
    if not targetState.persistentEffects then
        return false
    end
    
    for i, effect in ipairs(targetState.persistentEffects) do
        if effect.effectId == effectId then
            table.remove(targetState.persistentEffects, i)
            return true
        end
    end
    
    return false
end

-- Interface: Update persistent effects (call this each update cycle)
function EffectApplicator:updatePersistentEffects(targetState, dt)
    if not targetState.persistentEffects then
        return
    end
    
    local currentTime = os.time()
    local expiredEffects = {}
    
    -- Check for expired effects
    for i, effect in ipairs(targetState.persistentEffects) do
        if effect.duration > 0 then
            local elapsed = currentTime - effect.startTime
            if elapsed >= effect.duration then
                table.insert(expiredEffects, i)
            end
        end
    end
    
    -- Remove expired effects (iterate backwards to maintain indices)
    for i = #expiredEffects, 1, -1 do
        table.remove(targetState.persistentEffects, expiredEffects[i])
    end
    
    return #expiredEffects > 0
end

-- Interface: Calculate total modifiers from all persistent effects
function EffectApplicator:calculateTotalModifiers(targetState)
    local totalModifiers = {}
    
    if not targetState.persistentEffects then
        return totalModifiers
    end
    
    for _, effect in ipairs(targetState.persistentEffects) do
        if effect.active and effect.effects then
            for modifier, value in pairs(effect.effects) do
                totalModifiers[modifier] = (totalModifiers[modifier] or 0) + value
            end
        end
    end
    
    return totalModifiers
end

-- Interface: Apply conditional effects based on triggers
function EffectApplicator:applyConditionalEffects(triggerId, targetState, triggerData)
    -- TODO: Load trigger conditions from external config
    -- Placeholder implementation
    
    local triggerEffects = self:getTriggerEffects(triggerId)
    if not triggerEffects then
        return false, "No effects for trigger: " .. triggerId
    end
    
    local appliedEffects = {}
    
    for _, effectConfig in ipairs(triggerEffects) do
        -- Check conditions
        if self:checkTriggerConditions(effectConfig.conditions, targetState, triggerData) then
            local success, result = self:applyImmediateEffects(effectConfig.effectId, targetState, triggerData)
            if success then
                table.insert(appliedEffects, {
                    effectId = effectConfig.effectId,
                    result = result
                })
            end
        end
    end
    
    return #appliedEffects > 0, appliedEffects
end

-- Helper methods (placeholder implementations)

function EffectApplicator:getEffectData(effectId)
    -- TODO: Load from external data
    return self.effects[effectId]
end

function EffectApplicator:getTriggerEffects(triggerId)
    -- TODO: Load from external data
    return self.triggers[triggerId]
end

function EffectApplicator:checkTriggerConditions(conditions, targetState, triggerData)
    -- TODO: Implement condition checking logic
    if not conditions then
        return true
    end
    
    -- Simple placeholder condition checking
    for condition, value in pairs(conditions) do
        local currentValue = targetState[condition] or 0
        if currentValue < value then
            return false
        end
    end
    
    return true
end

-- Configuration methods (for future data-driven binding)

-- Define an effect
function EffectApplicator:defineEffect(effectId, effectData)
    self.effects[effectId] = effectData
end

-- Define a trigger
function EffectApplicator:defineTrigger(triggerId, triggerData)
    self.triggers[triggerId] = triggerData
end

-- Add modifier rule
function EffectApplicator:addModifier(modifierId, modifierRule)
    self.modifiers[modifierId] = modifierRule
end

-- Load effect rules from external data (placeholder for future implementation)
function EffectApplicator:loadFromConfig(configData)
    -- TODO: Implement data loading from JSON/external format
    -- This is where external data/config binding would happen
    
    if configData.effects then
        self.effects = configData.effects
    end
    
    if configData.triggers then
        self.triggers = configData.triggers
    end
    
    if configData.modifiers then
        self.modifiers = configData.modifiers
    end
end

return EffectApplicator