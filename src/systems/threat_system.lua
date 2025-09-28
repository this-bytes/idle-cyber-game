-- Threat System - ECS-Based Threat Management
-- Manages threat lifecycle, detection, and mitigation using ECS architecture
-- Placeholder system managing threat lifecycle hooks as specified in requirements

local System = require("src.ecs.system")
local ThreatSystem = setmetatable({}, {__index = System})
ThreatSystem.__index = ThreatSystem

-- Create new threat system  
function ThreatSystem.new(eventBus)
    local self = System.new("ThreatSystem", nil, eventBus)
    setmetatable(self, ThreatSystem)
    
    -- Threat system specific data
    self.threats = {}
    self.threatTypes = {
        "malware", "phishing", "ddos", "insider", "ransomware"
    }
    self.activeThreatCount = 0
    
    -- Set component requirements (placeholder)
    self:setRequiredComponents({"threat", "position"})
    
    return self
end

-- Initialize threat system
function ThreatSystem:initialize()
    System.initialize(self)
    
    -- Subscribe to threat-related events
    if self.eventBus then
        self.eventBus:subscribe("threat_detected", function(data)
            self:handleThreatDetected(data)
        end)
        
        self.eventBus:subscribe("threat_mitigated", function(data)
            self:handleThreatMitigated(data)
        end)
    end
end

-- Main threat processing logic (placeholder)
function ThreatSystem:processEntity(entityId, dt)
    -- Get threat component
    local threatComponent = self:getComponent(entityId, "threat")
    if not threatComponent then
        return
    end
    
    -- Update threat state based on type and severity
    threatComponent.duration = (threatComponent.duration or 0) + dt
    threatComponent.severity = threatComponent.severity or 1.0
    
    -- Check if threat should expire
    if threatComponent.duration > (threatComponent.maxDuration or 30) then
        self:removeThreat(entityId)
    end
end

-- Add a new threat (placeholder implementation)
function ThreatSystem:addThreat(threatType, severity)
    if not self.world then
        -- Legacy mode - store threat data directly
        local threat = {
            id = #self.threats + 1,
            type = threatType or "malware",
            severity = severity or 1.0,
            timestamp = os.time(),
            active = true
        }
        
        table.insert(self.threats, threat)
        self.activeThreatCount = self.activeThreatCount + 1
        
        return threat.id
    else
        -- ECS mode - create entity with threat component
        local entityId = self.world:createEntity()
        
        self.world:addComponent(entityId, "threat", {
            type = threatType or "malware",
            severity = severity or 1.0,
            duration = 0,
            maxDuration = 30,
            active = true
        })
        
        self.world:addComponent(entityId, "position", {
            x = 0, y = 0, z = 0
        })
        
        self.activeThreatCount = self.activeThreatCount + 1
        
        return entityId
    end
end

-- Remove a threat
function ThreatSystem:removeThreat(threatId)
    if not self.world then
        -- Legacy mode
        for i, threat in ipairs(self.threats) do
            if threat.id == threatId and threat.active then
                threat.active = false
                self.activeThreatCount = math.max(0, self.activeThreatCount - 1)
                return true
            end
        end
        return false
    else
        -- ECS mode
        if self.world:entityExists(threatId) then
            self.world:destroyEntity(threatId)
            self.activeThreatCount = math.max(0, self.activeThreatCount - 1)
            return true
        end
        return false
    end
end

-- Get active threat count
function ThreatSystem:getActiveThreatCount()
    return self.activeThreatCount
end

-- Get all threats (legacy compatibility)
function ThreatSystem:getAllThreats()
    if not self.world then
        return self.threats
    else
        -- Query all entities with threat components
        local threatEntities = self.world:query({"threat"})
        local threats = {}
        
        for _, entityId in ipairs(threatEntities) do
            local threatComponent = self.world:getComponent(entityId, "threat")
            if threatComponent then
                table.insert(threats, {
                    id = entityId,
                    type = threatComponent.type,
                    severity = threatComponent.severity,
                    duration = threatComponent.duration,
                    active = threatComponent.active
                })
            end
        end
        
        return threats
    end
end

-- Handle threat detected event
function ThreatSystem:handleThreatDetected(data)
    -- Placeholder for threat detection logic
    if data and data.threatType then
        self:addThreat(data.threatType, data.severity)
    end
end

-- Handle threat mitigated event
function ThreatSystem:handleThreatMitigated(data)
    -- Placeholder for threat mitigation logic
    if data and data.threatId then
        self:removeThreat(data.threatId)
    end
end

-- Get threat statistics
function ThreatSystem:getStats()
    return {
        activeThreatCount = self.activeThreatCount,
        totalThreats = #self.threats,
        threatTypes = self.threatTypes
    }
end

return ThreatSystem