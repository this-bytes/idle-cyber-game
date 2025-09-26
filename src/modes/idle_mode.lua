-- Idle Mode
-- Main game mode for empire building progression

local IdleMode = {}
IdleMode.__index = IdleMode

local format = require("src.utils.format")

-- Create new idle mode
function IdleMode.new(systems)
    local self = setmetatable({}, IdleMode)
    self.systems = systems
    
    -- UI state for contract selection
    self.contractAreas = {}  -- Store clickable areas for contracts
    self.selectedContract = nil
    
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
    opsY = opsY + 20
    
    -- Network status
    if self.systems.save and self.systems.save.getConnectionStatus then
        local status = self.systems.save:getConnectionStatus()
        theme:drawText("NETWORK:", rightPanelX + 10, opsY, theme:getColor("secondary"))
        local networkColor = status.isOnline and theme:getColor("success") or theme:getColor("error")
        local networkText = status.isOnline and "ONLINE" or "OFFLINE"
        if status.offlineMode then
            networkText = "DISABLED"
            networkColor = theme:getColor("muted")
        end
        theme:drawText(networkText, rightPanelX + 200, opsY, networkColor)
        opsY = opsY + 20
        
        theme:drawText("SAVE MODE:", rightPanelX + 10, opsY, theme:getColor("secondary"))
        theme:drawText(string.upper(status.saveMode), rightPanelX + 200, opsY, theme:getColor("accent"))
    end
    
    -- Available contracts panel with improved selection
    y = y + 220
    theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 180, "AVAILABLE CONTRACTS")
    local contractY = y + 25
    
    -- Clear previous contract areas and rebuild them
    self.contractAreas = {}
    
    local availableContracts = self.systems.contracts:getAvailableContracts()
    local count = 0
    for contractId, contract in pairs(availableContracts) do
        if count >= 3 then break end -- Show max 3 contracts
        
        -- Track clickable area for this contract
        local contractHeight = 60
        self.contractAreas[count + 1] = {
            x = leftPanelX + 10,
            y = contractY,
            width = panelWidth * 2,
            height = contractHeight,
            contractId = contractId,
            contract = contract
        }
        
        -- Highlight selected contract
        local isSelected = (self.selectedContract == contractId)
        if isSelected then
            theme:drawPanel(leftPanelX + 5, contractY - 5, panelWidth * 2 + 10, contractHeight, nil)
        end
        
        -- Contract display
        local arrowColor = isSelected and theme:getColor("warning") or theme:getColor("accent")
        theme:drawText("►", leftPanelX + 10, contractY, arrowColor)
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
    else
        theme:drawText("Click contract to select, then SPACE to accept | Selected: " .. 
                      (self.selectedContract and "Contract " .. (self:getSelectedContractIndex() or "?") or "None"), 
                      leftPanelX + 30, contractY + 10, theme:getColor("warning"))
    end
    
    -- Active contracts panel (NEW: Show running contracts for better idle feedback)
    y = y + 200
    theme:drawPanel(leftPanelX, y, panelWidth * 2 + 20, 160, "ACTIVE CONTRACTS")
    local activeY = y + 25
    
    local activeContracts = self.systems.contracts:getActiveContracts()
    local activeCount = 0
    for contractId, contract in pairs(activeContracts) do
        if activeCount >= 2 then break end -- Show max 2 active contracts
        
        -- Calculate progress
        local progress = 1.0 - (contract.remainingTime / contract.originalDuration)
        local progressPercent = math.floor(progress * 100)
        local incomeRate = contract.totalBudget / contract.originalDuration
        
        -- Contract display
        theme:drawText("►", leftPanelX + 10, activeY, theme:getColor("success"))
        theme:drawText(contract.clientName, leftPanelX + 30, activeY, theme:getColor("primary"))
        activeY = activeY + 15
        
        -- Progress bar
        local barWidth = panelWidth * 2 - 40
        local progressWidth = math.floor(barWidth * progress)
        
        -- Draw progress bar background
        love.graphics.setColor(theme:getColor("muted"))
        love.graphics.rectangle("fill", leftPanelX + 30, activeY, barWidth, 8)
        
        -- Draw progress bar fill
        love.graphics.setColor(theme:getColor("success"))
        love.graphics.rectangle("fill", leftPanelX + 30, activeY, progressWidth, 8)
        
        activeY = activeY + 12
        
        theme:drawText("  PROGRESS: " .. progressPercent .. "% | REMAINING: " .. 
                      math.ceil(contract.remainingTime) .. "s | INCOME: $" .. 
                      format.number(incomeRate, 2) .. "/sec", 
                      leftPanelX + 30, activeY, theme:getColor("dimmed"))
        activeY = activeY + 25
        activeCount = activeCount + 1
    end
    
    if activeCount == 0 then
        theme:drawText("[ NO ACTIVE CONTRACTS - ACCEPT CONTRACTS TO START EARNING ]", leftPanelX + 30, activeY, theme:getColor("muted"))
    end
    
    -- Status bar with controls  
    theme:drawStatusBar("READY | [CLICK] Select Contract | [SPACE] Accept Selected | [A] Crisis Mode | [ESC] Quit")
end

-- Helper function to get selected contract index for display
function IdleMode:getSelectedContractIndex()
    if not self.selectedContract then return nil end
    
    for i, area in ipairs(self.contractAreas) do
        if area.contractId == self.selectedContract then
            return i
        end
    end
    return nil
end

function IdleMode:mousepressed(x, y, button)
    -- Handle clicking to select contracts (improved UI framework)
    if button == 1 then -- Left click
        -- Check if click is within any contract area
        for i, area in ipairs(self.contractAreas) do
            if x >= area.x and x <= area.x + area.width and
               y >= area.y and y <= area.y + area.height then
                -- Select this contract
                self.selectedContract = area.contractId
                print("📋 Selected contract: " .. area.contract.clientName .. 
                      " - Budget: $" .. area.contract.totalBudget)
                return true
            end
        end
        
        -- If no contract area was clicked, try to accept selected contract
        if self.selectedContract then
            local success = self.systems.contracts:acceptContract(self.selectedContract)
            if success then
                local contract = self:getSelectedContractData()
                if contract then
                    print("📝 Accepted contract: " .. contract.clientName .. 
                          " - Budget: $" .. contract.totalBudget .. 
                          " | Duration: " .. math.floor(contract.duration) .. "s")
                    
                    -- Show immediate feedback
                    if self.systems.ui then
                        self.systems.ui.lastAction = {
                            message = "Contract accepted: " .. contract.clientName,
                            timer = 3.0
                        }
                    end
                    self.selectedContract = nil -- Clear selection
                    return true
                end
            end
        else
            print("💼 Click on a contract to select it, then press SPACE to accept or click again to accept directly.")
        end
    end
    return false
end

-- Helper function to get selected contract data
function IdleMode:getSelectedContractData()
    if not self.selectedContract then return nil end
    
    local availableContracts = self.systems.contracts:getAvailableContracts()
    return availableContracts[self.selectedContract]
end

function IdleMode:keypressed(key)
    -- Handle idle mode specific keys
    if key == "space" then
        -- Accept selected contract
        if self.selectedContract then
            local success = self.systems.contracts:acceptContract(self.selectedContract)
            if success then
                local contract = self:getSelectedContractData()
                if contract then
                    print("📝 Accepted contract: " .. contract.clientName .. 
                          " - Budget: $" .. contract.totalBudget .. 
                          " | Duration: " .. math.floor(contract.duration) .. "s")
                    self.selectedContract = nil -- Clear selection
                end
            else
                print("❌ Failed to accept contract. Check requirements.")
            end
        else
            print("💼 No contract selected. Click on a contract first.")
        end
    elseif key == "enter" then
        -- Show detailed information about selected contract
        if self.selectedContract then
            local contract = self:getSelectedContractData()
            if contract then
                print("📋 CONTRACT DETAILS:")
                print("   Client: " .. contract.clientName)
                print("   Description: " .. contract.description)
                print("   Budget: $" .. format.number(contract.totalBudget, 0))
                print("   Duration: " .. math.floor(contract.duration) .. "s")
                print("   Reputation Reward: +" .. contract.reputationReward)
                print("   Risk Level: " .. (contract.riskLevel or "LOW"))
            end
        else
            print("💼 No contract selected. Click on a contract to view details.")
        end
    elseif key == "i" then
        -- Show information about current business status
        print("💼 BUSINESS INFORMATION:")
        local resources = self.systems.resources:getAllResources()
        print("   Current Funds: $" .. format.number(resources.money or 0, 0))
        print("   Reputation Level: " .. format.number(resources.reputation or 0, 0))
        print("   Experience Points: " .. format.number(resources.xp or 0, 0))
        print("   Mission Tokens: " .. format.number(resources.missionTokens or 0, 0))
        
        local contractStats = self.systems.contracts:getStats()
        print("   Active Contracts: " .. contractStats.activeContracts)
        print("   Revenue Rate: $" .. format.number(contractStats.totalIncomeRate, 2) .. "/sec")
        
        -- Network status information
        if self.systems.save and self.systems.save.getConnectionStatus then
            local status = self.systems.save:getConnectionStatus()
            print("🌐 NETWORK STATUS:")
            print("   Server Connection: " .. (status.isOnline and "ONLINE" or "OFFLINE"))
            print("   Save Mode: " .. string.upper(status.saveMode))
            print("   Player ID: " .. status.username)
            if status.offlineMode then
                print("   Mode: OFFLINE (Network disabled)")
            end
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
                reqText = " (Achievement system needs update)"
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