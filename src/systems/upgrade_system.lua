-- Upgrade System - ECS-Based Upgrade Management
-- Skeleton for applying upgrades and checking prerequisites using ECS architecture
-- Manages upgrade purchases, effects, and prerequisite validation

local System = require("src.ecs.system")
local UpgradeSystem = setmetatable({}, {__index = System})
UpgradeSystem.__index = UpgradeSystem

-- Create new upgrade system
function UpgradeSystem.new(eventBus)
    local self = System.new("UpgradeSystem", nil, eventBus)
    setmetatable(self, UpgradeSystem)
    
    -- Upgrade system specific data
    self.availableUpgrades = {}
    self.purchasedUpgrades = {}
    self.upgradeCategories = {
        "security", "performance", "capacity", "automation"
    }
    
    -- Set component requirements (placeholder)
    self:setRequiredComponents({"upgrade", "cost"})
    
    -- Initialize basic upgrades
    self:initializeUpgrades()
    
    return self
end

-- Initialize available upgrades (placeholder data)
function UpgradeSystem:initializeUpgrades()
    -- Basic security upgrades
    self:defineUpgrade("firewall_basic", {
        name = "Basic Firewall",
        category = "security",
        cost = {money = 500},
        effects = {securityRating = 10},
        prerequisites = {},
        description = "Basic network firewall protection"
    })
    
    self:defineUpgrade("antivirus_basic", {
        name = "Basic Antivirus",
        category = "security", 
        cost = {money = 300},
        effects = {threatDetection = 15},
        prerequisites = {},
        description = "Basic malware detection and removal"
    })
    
    -- Performance upgrades
    self:defineUpgrade("server_upgrade", {
        name = "Server Upgrade", 
        category = "performance",
        cost = {money = 1000},
        effects = {processingSpeed = 25},
        prerequisites = {},
        description = "Improved server hardware for faster processing"
    })
end

-- Define a new upgrade
function UpgradeSystem:defineUpgrade(upgradeId, upgradeData)
    self.availableUpgrades[upgradeId] = upgradeData
end

-- Check if upgrade prerequisites are met (placeholder implementation)
function UpgradeSystem:checkPrerequisites(upgradeId, resources)
    local upgrade = self.availableUpgrades[upgradeId]
    if not upgrade then
        return false, "Upgrade not found"
    end
    
    -- Check if already purchased
    if self.purchasedUpgrades[upgradeId] then
        return false, "Already purchased"
    end
    
    -- Check resource requirements
    if upgrade.cost then
        for resource, amount in pairs(upgrade.cost) do
            local available = resources and resources[resource] or 0
            if available < amount then
                return false, "Insufficient " .. resource
            end
        end
    end
    
    -- Check prerequisite upgrades
    if upgrade.prerequisites then
        for _, prereqId in ipairs(upgrade.prerequisites) do
            if not self.purchasedUpgrades[prereqId] then
                return false, "Missing prerequisite: " .. prereqId
            end
        end
    end
    
    return true
end

-- Purchase an upgrade (placeholder implementation)
function UpgradeSystem:purchaseUpgrade(upgradeId, resources)
    local canPurchase, reason = self:checkPrerequisites(upgradeId, resources)
    if not canPurchase then
        return false, reason
    end
    
    local upgrade = self.availableUpgrades[upgradeId]
    
    -- Deduct costs (caller should handle this, we just validate)
    local costs = upgrade.cost or {}
    
    -- Mark as purchased
    self.purchasedUpgrades[upgradeId] = {
        upgradeId = upgradeId,
        purchaseTime = os.time(),
        effects = upgrade.effects or {}
    }
    
    -- Publish purchase event
    if self.eventBus then
        self.eventBus:publish("upgrade_purchased", {
            upgradeId = upgradeId,
            upgrade = upgrade,
            costs = costs
        })
    end
    
    return true, costs
end

-- Get available upgrades
function UpgradeSystem:getAvailableUpgrades()  
    local available = {}
    
    for upgradeId, upgrade in pairs(self.availableUpgrades) do
        if not self.purchasedUpgrades[upgradeId] then
            available[upgradeId] = upgrade
        end
    end
    
    return available
end

-- Get purchased upgrades
function UpgradeSystem:getPurchasedUpgrades()
    return self.purchasedUpgrades
end

-- Calculate total effects from all purchased upgrades
function UpgradeSystem:getTotalEffects()
    local totalEffects = {}
    
    for upgradeId, purchase in pairs(self.purchasedUpgrades) do
        for effectType, value in pairs(purchase.effects) do
            totalEffects[effectType] = (totalEffects[effectType] or 0) + value
        end
    end
    
    return totalEffects
end

-- ECS update logic (placeholder)
function UpgradeSystem:processEntity(entityId, dt)
    -- Get upgrade component
    local upgradeComponent = self:getComponent(entityId, "upgrade")
    if not upgradeComponent then
        return
    end
    
    -- Apply upgrade effects over time if needed
    if upgradeComponent.duration then
        upgradeComponent.duration = upgradeComponent.duration - dt
        
        if upgradeComponent.duration <= 0 then
            -- Upgrade effect expired
            self:removeComponent(entityId, "upgrade")
        end
    end
end

-- Check if specific upgrade is purchased
function UpgradeSystem:isUpgradePurchased(upgradeId)
    return self.purchasedUpgrades[upgradeId] ~= nil
end

-- Get upgrade by ID
function UpgradeSystem:getUpgrade(upgradeId)
    return self.availableUpgrades[upgradeId]
end

-- Reset all upgrades (useful for testing)
function UpgradeSystem:reset()
    self.purchasedUpgrades = {}
end

-- Get upgrade statistics
function UpgradeSystem:getStats()
    local purchasedCount = 0
    for _ in pairs(self.purchasedUpgrades) do
        purchasedCount = purchasedCount + 1
    end
    
    local availableCount = 0
    for _ in pairs(self.availableUpgrades) do
        availableCount = availableCount + 1
    end
    
    return {
        purchasedCount = purchasedCount,
        availableCount = availableCount,
        totalEffects = self:getTotalEffects()
    }
end

return UpgradeSystem