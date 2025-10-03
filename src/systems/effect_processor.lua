local EffectProcessor = {}
EffectProcessor.__index = EffectProcessor

function EffectProcessor.new(eventBus)
    local self = setmetatable({}, EffectProcessor)
    self.eventBus = eventBus
    self.effectHandlers = {}
    -- register defaults
    self:registerDefaultHandlers()
    return self
end

function EffectProcessor:registerDefaultHandlers()
    self.effectHandlers["income_multiplier"] = function(effect, context)
        return { mode = "multiply", value = effect.value, applies = self:matchesTarget(effect.target, context) }
    end
    self.effectHandlers["threat_reduction"] = function(effect, context)
        return { mode = "multiply", value = 1 - effect.value, applies = self:matchesTarget(effect.target, context) }
    end
    self.effectHandlers["efficiency_boost"] = function(effect, context)
        return { mode = "multiply", value = effect.value, applies = self:matchesTarget(effect.target, context) }
    end
    self.effectHandlers["generate_resource"] = function(effect, context) return { mode = "add", value = effect.value, applies = true } end
    self.effectHandlers["cooldown_reduction"] = function(effect, context) return { mode = "multiply", value = 1 - effect.value, applies = self:matchesTarget(effect.target, context) } end
    self.effectHandlers["duration_reduction"] = function(effect, context) return { mode = "multiply", value = 1 - effect.value, applies = self:matchesTarget(effect.target, context) } end
    self.effectHandlers["success_rate_boost"] = function(effect, context) return { mode = "add", value = effect.value, applies = self:matchesTarget(effect.target, context) } end
    self.effectHandlers["xp_multiplier"] = function(effect, context) return { mode = "multiply", value = effect.value, applies = self:matchesTarget(effect.target, context) } end
    self.effectHandlers["reputation_multiplier"] = function(effect, context) return { mode = "multiply", value = effect.value, applies = self:matchesTarget(effect.target, context) } end
end

function EffectProcessor:calculateValue(baseValue, effectType, context)
    local multipliers = 1.0
    local additive = 0
    local overrides = nil
    local activeItems = context.activeItems or {}
    for _, item in ipairs(activeItems) do
        if item.effects and item.effects.passive then
            for _, effect in ipairs(item.effects.passive) do
                if effect.type == effectType then
                    local handler = self.effectHandlers[effect.type]
                    if handler then
                        local result = handler(effect, context)
                        if result.applies then
                            if result.mode == "multiply" then multipliers = multipliers * result.value
                            elseif result.mode == "add" then additive = additive + result.value
                            elseif result.mode == "override" then overrides = result.value end
                        end
                    end
                end
            end
        end
    end
    multipliers = self:applySoftCap(multipliers, context.soft_cap or 10.0)
    if overrides then return overrides end
    return (baseValue + additive) * multipliers
end

function EffectProcessor:applySoftCap(value, cap)
    if not cap then return value end
    if value <= cap then return value end
    local excess = value - cap
    return cap + math.log(1 + excess) * (cap * 0.1)
end

function EffectProcessor:matchesTarget(target, context)
    if not target or target == "all" then return true end
    if type(target) == "string" and context.tags then
        for _, tag in ipairs(context.tags) do if tag == target then return true end end
    end
    if type(target) == "string" and context.type == target then return true end
    return false
end

function EffectProcessor:registerEffectHandler(effectType, handler)
    self.effectHandlers[effectType] = handler
end

function EffectProcessor:getActiveEffectSummary(context)
    local summary = { multipliers = {}, additives = {}, special = {} }
    local activeItems = context.activeItems or {}
    for _, item in ipairs(activeItems) do
        if item.effects and item.effects.passive then
            for _, effect in ipairs(item.effects.passive) do
                if self:matchesTarget(effect.target, context) then
                    local effectType = effect.type
                    if effect.mode == "multiply" or (self.effectHandlers[effectType] and self.effectHandlers[effectType](effect, context).mode == "multiply") then
                        if not summary.multipliers[effectType] then summary.multipliers[effectType] = 1.0 end
                        summary.multipliers[effectType] = summary.multipliers[effectType] * effect.value
                    elseif effect.mode == "add" then
                        if not summary.additives[effectType] then summary.additives[effectType] = 0 end
                        summary.additives[effectType] = summary.additives[effectType] + effect.value
                    else
                        table.insert(summary.special, { item = item.id, effect = effect })
                    end
                end
            end
        end
    end
    return summary
end

function EffectProcessor:calculateAllEffects(baseValues, activeItems, context)
    local fullContext = { activeItems = activeItems, type = context.type, tags = context.tags, soft_cap = context.soft_cap }
    local results = {}
    for key, baseValue in pairs(baseValues) do
        local effectType = key .. "_multiplier"
        results[key] = self:calculateValue(baseValue, effectType, fullContext)
    end
    return results
end

return EffectProcessor
