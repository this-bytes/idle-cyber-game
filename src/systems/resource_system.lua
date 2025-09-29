-- Resource System - Legacy Compatibility Bridge
-- Bridges legacy ResourceSystem calls to the new ResourceManager architecture
-- Provides backward compatibility for existing tests and systems

local ResourceManager = require("src.core.resource_manager")

local ResourceSystem = {}
ResourceSystem.__index = ResourceSystem

-- Legacy compatibility - ResourceSystem.new() now creates ResourceManager
function ResourceSystem.new(eventBus)
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    return resourceManager
end

return ResourceSystem