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
    -- Get terminal theme from UI manager
    local theme = self.systems.ui.theme
    
    -- Draw terminal header
    local contentY = theme:drawHeader("CYBER EMPIRE COMMAND v2.1.7", "Security Consultancy Management Terminal")
    
    local y = contentY + 20
    local leftPanelX = 20
    local rightPanelX = 520
    local panelWidth = 480
    
    -- Left panel: Business Resources
    theme:drawPanel(leftPanelX, y, panelWidth, 200, "BUSINESS RESOURCES")
    local resourceY = y + 25
    
    local resources = self.systems.resources:getAllResources()
    theme:drawText("BUDGET:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
    theme:drawText("$" .. format.number(resources.money or 0, 0), leftPanelX + 200, resourceY, theme:getColor("success"))
    resourceY = resourceY + 20
    
    theme:drawText("REPUTATION:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
    theme:drawText(format.number(resources.reputation or 0, 0) .. " pts", leftPanelX + 200, resourceY, theme:getColor("accent"))
    resourceY = resourceY + 20
    
    theme:drawText("EXPERIENCE:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
    theme:drawText(format.number(resources.xp or 0, 0) .. " XP", leftPanelX + 200, resourceY, theme:getColor("primary"))
    resourceY = resourceY + 20
    
    theme:drawText("MISSION TOKENS:", leftPanelX + 10, resourceY, theme:getColor("secondary"))
    theme:drawText(format.number(resources.missionTokens or 0, 0), leftPanelX + 200, resourceY, theme:getColor("warning"))
    
    -- Right panel: Operations Status
    theme:drawPanel(rightPanelX, y, panelWidth, 200, "OPERATIONS STATUS")
    local opsY = y + 25
    
    local contractStats = self.systems.contracts:getStats()
    local specialistStats = self.systems.specialists:getStats()
    
    theme:drawText("ACTIVE CONTRACTS:", rightPanelX + 10, opsY, theme:getColor("secondary"))
    theme:drawText(tostring(contractStats.activeContracts or 0), rightPanelX + 200, opsY, theme:getColor("warning"))
    opsY = opsY + 20
    
    theme:drawText("AVAILABLE CONTRACTS:", rightPanelX + 10, opsY, theme:getColor("secondary"))
    theme:drawText(tostring(contractStats.availableContracts or 0), rightPanelX + 200, opsY, theme:getColor("accent"))
    opsY = opsY + 20
    
    theme:drawText("REVENUE/SEC:", rightPanelX + 10, opsY, theme:getColor("secondary"))
    theme:drawText("$" .. format.number(contractStats.totalIncomeRate or 0, 2), rightPanelX + 200, opsY, theme:getColor("success"))
    opsY = opsY + 20
    
    theme:drawText("TEAM STATUS:", rightPanelX + 10, opsY, theme:getColor("secondary"))
    theme:drawText(specialistStats.available .. "/" .. specialistStats.total .. " ready", rightPanelX + 200, opsY, theme:getColor("primary"))
    
    -- Available contracts panel
    y = y + 220
    theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 180, "AVAILABLE CONTRACTS - [CLICK TO ACCEPT]")
    local contractY = y + 25
    
    local availableContracts = self.systems.contracts:getAvailableContracts()
    local count = 0
    for contractId, contract in pairs(availableContracts) do
        if count >= 3 then break end -- Show max 3 contracts
        
        theme:drawText("►", leftPanelX + 10, contractY, theme:getColor("accent"))
        theme:drawText(contract.clientName, leftPanelX + 30, contractY, theme:getColor("primary"))
        contractY = contractY + 15
        
        theme:drawText("  BUDGET: $" .. format.number(contract.totalBudget, 0) .. 
                      " | DURATION: " .. math.floor(contract.duration) .. "s" ..
                      " | REP: +" .. contract.reputationReward, leftPanelX + 30, contractY, theme:getColor("dimmed"))
        contractY = contractY + 15
        
        theme:drawText("  \"" .. contract.description .. "\"", leftPanelX + 30, contractY, theme:getColor("secondary"))
        contractY = contractY + 25
        count = count + 1
    end
    
    if count == 0 then
        theme:drawText("[ NO CONTRACTS AVAILABLE - BUILDING REPUTATION... ]", leftPanelX + 30, contractY, theme:getColor("muted"))
    end
    
    -- Legacy systems notice (if any exist)
    if resources.dataBits and resources.dataBits > 0 then
        y = y + 200
        theme:drawPanel(leftPanelX, y, panelWidth, 60, "LEGACY SYSTEMS")
        theme:drawText("Data Bits: " .. format.number(resources.dataBits, 0), leftPanelX + 10, y + 25, theme:getColor("muted"))
        theme:drawText("(Migration in progress...)", leftPanelX + 10, y + 40, theme:getColor("muted"))
    end
    
    -- Status bar with controls
    theme:drawStatusBar("READY | [CLICK] Accept Contract | [A] Crisis Mode | [U] Upgrades | [ESC] Quit")
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