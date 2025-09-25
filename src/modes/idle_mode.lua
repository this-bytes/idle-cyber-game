-- Idle Mode
-- Main game mode for empire building progression

local IdleMode = {}
IdleMode.__index = IdleMode

local format = require("src.utils.format")

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
    -- Draw idle mode UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("🏠 IDLE MODE - Cyberspace Tycoon", 20, 20)
    love.graphics.print("Build your cybersecurity empire through strategic upgrades", 20, 40)
    
    -- Draw resources with proper formatting
    local resources = self.systems.resources:getAllResources()
    local generation = self.systems.resources:getAllGeneration()
    local y = 80
    
    love.graphics.print("💼 RESOURCES:", 20, y)
    y = y + 25
    
    for name, value in pairs(resources) do
        if value > 0 or generation[name] > 0 then
            local displayValue = format.number(value, 2)
            local rate = generation[name]
            local rateText = rate > 0 and " (+" .. format.rate(rate, 1) .. ")" or ""
            
            local emoji = ""
            if name == "dataBits" then emoji = "💎"
            elseif name == "processingPower" then emoji = "⚡"
            elseif name == "securityRating" then emoji = "🛡️"
            elseif name == "reputationPoints" then emoji = "⭐"
            elseif name == "researchData" then emoji = "🔬"
            end
            
            love.graphics.print(emoji .. " " .. name .. ": " .. displayValue .. rateText, 30, y)
            y = y + 20
        end
    end
    
    -- Draw current zone
    local currentZone = self.systems.zones:getCurrentZone()
    if currentZone then
        y = y + 10
        love.graphics.print("🗺️ LOCATION:", 20, y)
        love.graphics.print("📍 " .. currentZone.name, 30, y + 20)
        love.graphics.print("   " .. currentZone.description, 30, y + 40)
        y = y + 70
    end
    
    -- Draw click info
    local clickInfo = self.systems.resources:getClickInfo()
    love.graphics.print("🖱️ CLICK POWER:", 20, y)
    love.graphics.print("   Power: " .. format.number(clickInfo.power, 0) .. " DB per click", 30, y + 20)
    love.graphics.print("   Combo: " .. format.number(clickInfo.combo, 1) .. "x (max " .. clickInfo.maxCombo .. "x)", 30, y + 40)
    
    -- Instructions
    love.graphics.print("Click anywhere to earn Data Bits! Hold clicks for combo bonus!", 20, love.graphics.getHeight() - 60)
    love.graphics.print("Press U for upgrades, Z for zones, H for achievements", 20, love.graphics.getHeight() - 40)
    love.graphics.print("Press A to switch to Admin Mode (\"The Admin's Watch\")", 20, love.graphics.getHeight() - 20)
end

function IdleMode:mousepressed(x, y, button)
    -- Handle clicking for resources
    if button == 1 then -- Left click
        local result = self.systems.resources:click()
        local message = "💎 Earned " .. format.number(result.reward, 2) .. " Data Bits"
        if result.critical then
            message = message .. " (CRITICAL!)"
        end
        if result.combo > 1 then
            message = message .. " (combo: " .. format.number(result.combo, 1) .. "x)"
        end
        print(message)
        return true
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
        print("🏆 Achievement system not fully implemented yet")
        print("   Progress tracking and rewards coming soon!")
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