-- src/systems/upgrade_system.lua

local UpgradeSystem = {}
UpgradeSystem.__index = UpgradeSystem

function UpgradeSystem.new(eventBus, dataManager)
    local self = setmetatable({}, UpgradeSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.allUpgrades = self.dataManager:getData("upgrades") or {}
    self.purchasedUpgrades = {}
    
    if not self.allUpgrades or #self.allUpgrades == 0 then
        print("⚠️ WARNING: No upgrade data found. Upgrade system may not function.")
        self.allUpgrades = {}
    end

    print("🔧 Upgrade system initialized.")
    return self
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

    -- This is a simplified check. In a real scenario, you'd use the resource manager.
    -- For now, we'll assume the caller has checked the cost.
    
    self.purchasedUpgrades[upgradeId] = upgrade
    self.eventBus:publish("upgrade_purchased", { upgrade = upgrade })
    print("Purchased upgrade: " .. upgrade.name)
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
