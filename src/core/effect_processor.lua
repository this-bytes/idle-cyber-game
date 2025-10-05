-- EffectProcessor - Universal effect calculation system
-- Processes passive and active effects from all game items
-- Part of the AWESOME Backend Architecture

local EffectProcessor = {}
EffectProcessor.__index = EffectProcessor

function EffectProcessor.new(eventBus)
    local self = setmetatable({}, EffectProcessor)
    self.eventBus = eventBus
    
    -- Effect handlers by type
    self.effectHandlers = {}
    -- Forwarder: src.core.effect_processor -> src.systems.effect_processor
    return require("src.systems.effect_processor")
end 

return EffectProcessor

