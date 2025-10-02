-- SecurityUpgrades - Authentic cybersecurity infrastructure system
-- Categories: Infrastructure, Tools, Personnel, Research

local SecurityUpgrades = {}
SecurityUpgrades.__index = SecurityUpgrades

function SecurityUpgrades.new(eventBus, resourceManager)
    local self = setmetatable({}, SecurityUpgrades)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Upgrade categories
    self.categories = {
        infrastructure = {name = "Infrastructure", upgrades = {}},
        tools = {name = "Tools", upgrades = {}},
        personnel = {name = "Personnel", upgrades = {}},
        research = {name = "Research", upgrades = {}}
    }
    
    return self
end

function SecurityUpgrades:initialize()
    -- Initialize upgrade system
    return true
end

function SecurityUpgrades:getUpgradeCategories()
    return self.categories
end

return SecurityUpgrades