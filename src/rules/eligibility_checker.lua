-- Eligibility Checker Interface - Rules Engine Component
-- Configurable interface for eligibility checking rules
-- Architected for future binding to external data/config formats

local EligibilityChecker = {}
EligibilityChecker.__index = EligibilityChecker

-- Create new eligibility checker
function EligibilityChecker.new()
    local self = setmetatable({}, EligibilityChecker)
    
    -- Eligibility rules (placeholder interfaces)
    self.requirements = {}
    self.restrictions = {}
    self.conditions = {}
    
    return self
end

-- Interface: Check if player meets basic requirements
function EligibilityChecker:checkBasicRequirements(itemType, itemId, playerState)
    -- TODO: Load requirements from external data/config
    -- Placeholder implementation
    
    local requirements = self:getRequirements(itemType, itemId)
    
    for requirementType, threshold in pairs(requirements) do
        local playerValue = playerState[requirementType] or 0
        
        if playerValue < threshold then
            return false, "Insufficient " .. requirementType .. 
                         " (need " .. threshold .. ", have " .. playerValue .. ")"
        end
    end
    
    return true
end

-- Interface: Check prerequisites (dependencies)
function EligibilityChecker:checkPrerequisites(itemType, itemId, playerState)
    -- TODO: Load from external config
    -- Placeholder implementation
    
    local prereqs = self:getPrerequisites(itemType, itemId)
    
    for _, prereqId in ipairs(prereqs) do
        if not self:hasPrerequisite(prereqId, playerState) then
            return false, "Missing prerequisite: " .. prereqId
        end
    end
    
    return true
end

-- Interface: Check restrictions (blocking conditions)
function EligibilityChecker:checkRestrictions(itemType, itemId, playerState)
    -- TODO: Load from external config
    -- Placeholder implementation
    
    local restrictions = self:getRestrictions(itemType, itemId)
    
    for restrictionType, limit in pairs(restrictions) do
        local currentValue = playerState[restrictionType] or 0
        
        if currentValue >= limit then
            return false, "Restriction violated: " .. restrictionType .. 
                         " limit " .. limit .. " reached"
        end
    end
    
    return true
end

-- Interface: Check time-based conditions
function EligibilityChecker:checkTimeConditions(itemType, itemId, playerState)
    -- TODO: Load from external config
    -- Placeholder implementation
    
    local timeConditions = self:getTimeConditions(itemType, itemId)
    local currentTime = os.time()
    
    -- Check cooldowns
    if timeConditions.cooldown then
        local lastPurchase = playerState.lastPurchase and playerState.lastPurchase[itemType]
        if lastPurchase and (currentTime - lastPurchase) < timeConditions.cooldown then
            local remaining = timeConditions.cooldown - (currentTime - lastPurchase)
            return false, "Cooldown active (" .. remaining .. "s remaining)"
        end
    end
    
    -- Check availability windows
    if timeConditions.availableFrom and currentTime < timeConditions.availableFrom then
        return false, "Not yet available"
    end
    
    if timeConditions.availableUntil and currentTime > timeConditions.availableUntil then
        return false, "No longer available"
    end
    
    return true
end

-- Interface: Comprehensive eligibility check
function EligibilityChecker:checkEligibility(itemType, itemId, playerState)
    -- Check all eligibility criteria
    local checks = {
        self:checkBasicRequirements(itemType, itemId, playerState),
        self:checkPrerequisites(itemType, itemId, playerState),
        self:checkRestrictions(itemType, itemId, playerState),
        self:checkTimeConditions(itemType, itemId, playerState)
    }
    
    for _, result in ipairs(checks) do
        local eligible, reason = result[1], result[2]
        if not eligible then
            return false, reason
        end
    end
    
    return true
end

-- Helper methods (placeholder implementations)

function EligibilityChecker:getRequirements(itemType, itemId)
    -- TODO: Load from external data
    if not self.requirements[itemType] then
        return {}
    end
    return self.requirements[itemType][itemId] or {}
end

function EligibilityChecker:getPrerequisites(itemType, itemId)
    -- TODO: Load from external data
    local key = itemType .. "_" .. itemId
    return self.conditions[key] and self.conditions[key].prerequisites or {}
end

function EligibilityChecker:getRestrictions(itemType, itemId)
    -- TODO: Load from external data
    if not self.restrictions[itemType] then
        return {}
    end
    return self.restrictions[itemType][itemId] or {}
end

function EligibilityChecker:getTimeConditions(itemType, itemId)
    -- TODO: Load from external data
    local key = itemType .. "_" .. itemId
    return self.conditions[key] and self.conditions[key].timeConditions or {}
end

function EligibilityChecker:hasPrerequisite(prereqId, playerState)
    -- Check if player has a specific prerequisite
    -- TODO: Implement based on external config
    return playerState.purchased and playerState.purchased[prereqId] == true
end

-- Configuration methods (for future data-driven binding)

-- Set requirements for an item
function EligibilityChecker:setRequirements(itemType, itemId, requirements)
    if not self.requirements[itemType] then
        self.requirements[itemType] = {}
    end
    self.requirements[itemType][itemId] = requirements
end

-- Set restrictions for an item
function EligibilityChecker:setRestrictions(itemType, itemId, restrictions)
    if not self.restrictions[itemType] then
        self.restrictions[itemType] = {}
    end
    self.restrictions[itemType][itemId] = restrictions
end

-- Set conditions (prerequisites, time windows) for an item
function EligibilityChecker:setConditions(itemType, itemId, conditions)
    local key = itemType .. "_" .. itemId
    self.conditions[key] = conditions
end

-- Load eligibility rules from external data (placeholder for future implementation)
function EligibilityChecker:loadFromConfig(configData)
    -- TODO: Implement data loading from JSON/external format
    -- This is where external data/config binding would happen
    
    if configData.requirements then
        self.requirements = configData.requirements
    end
    
    if configData.restrictions then
        self.restrictions = configData.restrictions
    end
    
    if configData.conditions then
        self.conditions = configData.conditions
    end
end

return EligibilityChecker