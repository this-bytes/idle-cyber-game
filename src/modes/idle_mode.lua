-- Idle Mode - Cyber Empire Command
-- Main game mode for empire building progression
-- Updated for bootstrap architecture

local IdleMode = {}
IdleMode.__index = IdleMode

local format = require("src.utils.format")
local GameConfig = require("src.config.game_config")

-- Create new idle mode
function IdleMode.new(systems)
    local self = setmetatable({}, IdleMode)
    self.systems = systems
    
    return self
end

function IdleMode:update(dt)
    -- Handle idle mode specific updates
end

function IdleMode:draw()
    -- Draw Cyber Empire Command UI with cyberpunk theme  
    love.graphics.setColor(0, 1, 0) -- Bright terminal green
    love.graphics.print("🔐 " .. GameConfig.GAME_TITLE .. " - HQ Dashboard", 20, 20)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(GameConfig.GAME_SUBTITLE, 20, 40)
    
    local y = 80
    
    -- Show core business resources from config
    local resources = self.systems.resources:getAllResources()
    love.graphics.setColor(0, 1, 0) -- Terminal green
    love.graphics.print("💼 BUSINESS RESOURCES:", 20, y)
    y = y + 25
    
    -- Display resources dynamically from config
    love.graphics.setColor(0, 0.8, 1) -- Cyan for values
    for resourceName, resourceConfig in pairs(GameConfig.RESOURCES) do
        local value = resources[resourceName] or 0
        love.graphics.print(string.format("   %s %s: %s", 
            resourceConfig.symbol, 
            resourceConfig.name, 
            format.number(value, 0)), 30, y)
        y = y + 20
    end
    y = y + 10
    
    -- Contract information
    local contractStats = self.systems.contracts:getStats()
    local specialistStats = self.systems.specialists:getStats()
    love.graphics.print("📋 OPERATIONS STATUS:", 20, y)
    y = y + 25
    love.graphics.print("   Active Contracts: " .. contractStats.activeContracts, 30, y)
    y = y + 20
    love.graphics.print("   Available Contracts: " .. contractStats.availableContracts, 30, y)
    y = y + 20
    love.graphics.print("   Income Rate: $" .. format.number(contractStats.totalIncomeRate, 2) .. "/sec", 30, y)
    y = y + 20
    love.graphics.print("   Team: " .. specialistStats.available .. "/" .. specialistStats.total .. " specialists available", 30, y)
    y = y + 30
    
    -- Available contracts list
    local availableContracts = self.systems.contracts:getAvailableContracts()
    local hasAvailable = false
    for _ in pairs(availableContracts) do
        hasAvailable = true
        break
    end
    
    if hasAvailable then
        love.graphics.print("📝 AVAILABLE CONTRACTS:", 20, y)
        y = y + 25
        
        local count = 0
        for contractId, contract in pairs(availableContracts) do
            if count >= 3 then break end -- Show max 3 contracts
            
            love.graphics.print("   " .. contract.clientName, 30, y)
            y = y + 15
            love.graphics.print("      Budget: $" .. format.number(contract.totalBudget, 0) .. 
                              " | Duration: " .. math.floor(contract.duration) .. "s" ..
                              " | Rep: +" .. contract.reputationReward, 30, y)
            y = y + 15
            love.graphics.print("      \"" .. contract.description .. "\"", 30, y)
            y = y + 25
            count = count + 1
        end
    end
    
    -- Legacy resources (TODO: Remove after full refactor)
    if resources.dataBits and resources.dataBits > 0 then
        y = y + 20
        love.graphics.setColor(0.7, 0.7, 0.7) -- Dimmed for legacy
        love.graphics.print("🔧 LEGACY SYSTEMS (Migration in progress):", 20, y)
        y = y + 20
        love.graphics.print("   Data Bits: " .. format.number(resources.dataBits, 0), 30, y)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Instructions  
    y = love.graphics.getHeight() - 100
    love.graphics.print("Controls:", 20, y)
    y = y + 20
    love.graphics.print("• Click to accept first available contract", 20, y)
    y = y + 15
    love.graphics.print("• Press 'A' to enter Admin Mode (Crisis Response)", 20, y)
    y = y + 15
    love.graphics.print("• Press 'C' to view all contracts • Press 'U' for upgrades", 20, y)
end

function IdleMode:mousepressed(x, y, button)
    -- Handle clicking to accept contracts (Cyber Empire Command core mechanic)
    if button == 1 then -- Left click
        -- Try to accept the first available contract
        local availableContracts = self.systems.contracts:getAvailableContracts()
        
        for contractId, contract in pairs(availableContracts) do
            local success = self.systems.contracts:acceptContract(contractId)
            if success then
                print("📝 Accepted contract: " .. contract.clientName .. 
                      " - Budget: $" .. contract.totalBudget .. 
                      " | Duration: " .. math.floor(contract.duration) .. "s")
                return true
            end
            break -- Only try the first one
        end
        
        -- Fallback: Legacy clicking for data bits (TODO: Remove after full refactor)
        local result = self.systems.resources:click()
        if result then
            local message = "💎 Legacy click: " .. format.number(result.reward, 2) .. " Data Bits"
            if result.critical then
                message = message .. " (CRITICAL!)"
            end
            if result.combo > 1 then
                message = message .. " (combo: " .. format.number(result.combo, 1) .. "x)"
            end
            print(message)
        end
    end
    return false
end

function IdleMode:keypressed(key)
    -- Handle idle mode specific keys
    if key == "u" then
        print("📦 Upgrade Shop:")
        local upgrades = self.systems.upgrades:getUnlockedUpgrades()
        local count = 0
        for upgradeId, upgrade in pairs(upgrades) do
            local cost = self.systems.upgrades:getUpgradeCost(upgradeId)
            local owned = self.systems.upgrades:getUpgradeCount(upgradeId)
            local costText = ""
            for resource, amount in pairs(cost) do
                costText = costText .. format.number(amount, 0) .. " " .. resource .. " "
            end
            print("   [" .. (count + 1) .. "] " .. upgrade.name .. " (x" .. owned .. "/" .. upgrade.maxCount .. ") - " .. costText)
            count = count + 1
        end
        if count == 0 then
            print("   No upgrades available yet. Keep playing to unlock more!")
        else
            print("   Press 1-" .. count .. " to purchase upgrades")
        end
    elseif key == "z" then
        print("🗺️ Zone System:")
        local zones = self.systems.zones:getUnlockedZones()
        local currentZoneId = self.systems.zones:getCurrentZoneId()
        for zoneId, zone in pairs(zones) do
            local current = zoneId == currentZoneId and " (CURRENT)" or ""
            print("   " .. zone.name .. current .. " - " .. zone.description)
        end
    elseif key == "h" then
        print("🏆 Achievements:")
        local achievements = self.systems.achievements:getAllAchievements()
        local progress = self.systems.achievements:getProgress()
        
        print("   📊 Progress:")
        print("      Total Clicks: " .. progress.totalClicks)
        print("      Data Bits Earned: " .. format.number(progress.totalDataBitsEarned, 0))
        print("      Upgrades Purchased: " .. progress.totalUpgradesPurchased)
        print("      Max Combo: " .. format.number(progress.maxClickCombo, 1) .. "x")
        print("      Critical Hits: " .. progress.criticalHits)
        print("")
        
        local unlockedCount = 0
        local totalCount = 0
        for achievementId, achievement in pairs(achievements) do
            totalCount = totalCount + 1
            local status = achievement.unlocked and "✅" or "❌"
            local reqText = ""
            
            if achievement.requirement.type == "clicks" then
                reqText = " (" .. progress.totalClicks .. "/" .. achievement.requirement.value .. " clicks)"
            elseif achievement.requirement.type == "maxCombo" then
                reqText = " (" .. format.number(progress.maxClickCombo, 1) .. "/" .. achievement.requirement.value .. "x combo)"
            elseif achievement.requirement.type == "upgrades" then
                reqText = " (" .. progress.totalUpgradesPurchased .. "/" .. achievement.requirement.value .. " upgrades)"
            elseif achievement.requirement.type == "totalEarned" then
                reqText = " (" .. format.number(progress.totalDataBitsEarned, 0) .. "/" .. format.number(achievement.requirement.value, 0) .. " DB)"
            end
            
            print("   " .. status .. " " .. achievement.name .. reqText)
            print("      " .. achievement.description)
            
            if achievement.unlocked then
                unlockedCount = unlockedCount + 1
            end
        end
        
        print("")
        print("   🎯 Progress: " .. unlockedCount .. "/" .. totalCount .. " achievements unlocked")
    elseif key >= "1" and key <= "9" then
        -- Purchase upgrade by number
        local upgradeIndex = tonumber(key)
        local upgrades = self.systems.upgrades:getUnlockedUpgrades()
        local upgradeIds = {}
        for upgradeId, upgrade in pairs(upgrades) do
            table.insert(upgradeIds, upgradeId)
        end
        
        if upgradeIndex <= #upgradeIds then
            local upgradeId = upgradeIds[upgradeIndex]
            local success = self.systems.upgrades:purchaseUpgrade(upgradeId)
            if not success then
                local upgrade = self.systems.upgrades:getUpgrade(upgradeId)
                local cost = self.systems.upgrades:getUpgradeCost(upgradeId)
                local owned = self.systems.upgrades:getUpgradeCount(upgradeId)
                
                if owned >= upgrade.maxCount then
                    print("❌ Cannot purchase: Already at maximum count (" .. upgrade.maxCount .. ")")
                else
                    local costText = ""
                    for resource, amount in pairs(cost) do
                        costText = costText .. format.number(amount, 0) .. " " .. resource .. " "
                    end
                    print("❌ Cannot afford: Need " .. costText)
                end
            end
        end
    end
end

return IdleMode