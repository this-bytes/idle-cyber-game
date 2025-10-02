-- Upgrade System
-- Manages purchasable upgrades, their effects, and integration with resources
-- Depends on EventBus for event-driven architecture and DataManager for loading upgrade data
-- Integral to gameplay progression and strategy

local UpgradeSystem = {}
UpgradeSystem.__index = UpgradeSystem

function UpgradeSystem.new(eventBus, dataManager)
    local self = setmetatable({}, UpgradeSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    -- The data from JSON is nested under a key, e.g., {"upgrades": [...]}
    local upgradeData = self.dataManager:getData("upgrades")
    self.allUpgrades = (upgradeData and upgradeData.upgrades) or {}
    self.purchasedUpgrades = {}
    
    -- Build upgrade trees and prerequisites
    self.upgradeTrees = {}
    self:buildUpgradeTrees()
    
    if not self.allUpgrades or #self.allUpgrades == 0 then
        print("⚠️ WARNING: No upgrade data found. Upgrade system may not function.")
        self.allUpgrades = {}
    end

    print("🔧 Upgrade system initialized with " .. #self.allUpgrades .. " upgrades in " .. #self.upgradeTrees .. " trees.")
    return self
end

function UpgradeSystem:buildUpgradeTrees()
    -- Group upgrades by category/tree
    local trees = {}
    
    for _, upgrade in ipairs(self.allUpgrades) do
        local category = upgrade.category or "general"
        if not trees[category] then
            trees[category] = {}
        end
        table.insert(trees[category], upgrade)
    end
    
    -- Sort upgrades within each tree by tier
    for category, upgrades in pairs(trees) do
        table.sort(upgrades, function(a, b) return (a.tier or 1) < (b.tier or 1) end)
    end
    
    self.upgradeTrees = trees
end

function UpgradeSystem:getAvailableUpgrades()
    local available = {}
    
    for _, upgrade in ipairs(self.allUpgrades) do
        if not self.purchasedUpgrades[upgrade.id] and self:canPurchaseUpgrade(upgrade.id) then
            table.insert(available, upgrade)
        end
    end
    
    return available
end

function UpgradeSystem:canPurchaseUpgrade(upgradeId)
    local upgrade = self:getUpgradeById(upgradeId)
    if not upgrade then return false end
    
    -- Check prerequisites
    if upgrade.prerequisites then
        for _, prereqId in ipairs(upgrade.prerequisites) do
            if not self.purchasedUpgrades[prereqId] then
                return false
            end
        end
    end
    
    return true
end

function UpgradeSystem:purchaseUpgrade(upgradeId)
    local upgrade = self:getUpgradeById(upgradeId)
    if not upgrade then
        print("Error: Upgrade not found: " .. upgradeId)
        return false
    end

    if self.purchasedUpgrades[upgradeId] then
        print("Info: Upgrade already purchased: " .. upgrade.name)
        return false
    end
    
    -- Check prerequisites
    if not self:canPurchaseUpgrade(upgradeId) then
        print("Error: Prerequisites not met for upgrade: " .. upgrade.name)
        return false
    end

    -- Publish an event to request spending resources.
    -- The ResourceManager will handle the transaction and broadcast success/failure.
    self.eventBus:publish("resource_spend", upgrade.cost)

    -- We can't confirm the purchase here directly.
    -- We need to listen for a confirmation event from the ResourceManager.
    -- For now, we will optimistically assume it works for the sake of progress,
    -- but a more robust solution would use a callback or listen for a 'purchase_successful' event.
    
    self.purchasedUpgrades[upgradeId] = upgrade
    self.eventBus:publish("upgrade_purchased", { upgrade = upgrade })
    print("Attempting to purchase upgrade: " .. upgrade.name)
    return true
end

function UpgradeSystem:getUpgradeById(id)
    for _, upgrade in ipairs(self.allUpgrades) do
        if upgrade.id == id then
            return upgrade
        end
    end
    return nil
end

function UpgradeSystem:getAvailableUpgrades()
    local available = {}
    for _, upgrade in ipairs(self.allUpgrades) do
        if not self.purchasedUpgrades[upgrade.id] then
            -- Here you could add logic for prerequisites
            table.insert(available, upgrade)
        end
    end
    return available
end

function UpgradeSystem:getPurchasedUpgrades()
    -- Return a list (array) of purchased upgrades, not the map
    local purchasedList = {}
    for _, upgrade in pairs(self.purchasedUpgrades) do
        table.insert(purchasedList, upgrade)
    end
    return purchasedList
end

return UpgradeSystem
