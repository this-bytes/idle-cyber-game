-- Minimal shim for security upgrades used by tests
-- If a systems implementation exists, prefer that; otherwise provide a lightweight stub.
local ok, mod = pcall(require, "src.systems.security_upgrades")
if ok and mod then
    return mod
end

local SecurityUpgrades = {}
SecurityUpgrades.__index = SecurityUpgrades

function SecurityUpgrades.new(eventBus, resourceManager)
    local self = setmetatable({}, SecurityUpgrades)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.upgrades = {}
    return self
end

function SecurityUpgrades:initialize()
    -- No-op for shim
    self.upgrades = {}
end

function SecurityUpgrades:getAvailableUpgrades()
    return {}
end

function SecurityUpgrades:purchaseUpgrade(id)
    -- Not implemented in shim
    return false
end

return SecurityUpgrades
