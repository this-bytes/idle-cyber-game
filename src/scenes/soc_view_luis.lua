-- SOC View Scene - Main Operational Interface (LUIS Version)
-- Living operational dashboard showing all active game systems

local SOCViewLuis = {}
SOCViewLuis.__index = SOCViewLuis

function SOCViewLuis.new(eventBus, luis, systems)
    local self = setmetatable({}, SOCViewLuis)
    
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "soc_view"
    
    local cyberpunkTheme = {
        textColor = {0, 1, 180/255, 1},                      
        bgColor = {10/255, 25/255, 20/255, 0.8},            
        borderColor = {0, 1, 180/255, 0.4},                 
        borderWidth = 1,
        hoverTextColor = {20/255, 30/255, 25/255, 1},       
        hoverBgColor = {0, 1, 180/255, 1},                    
        hoverBorderColor = {0, 1, 180/255, 1},
        activeTextColor = {20/255, 30/255, 25/255, 1},
        activeBgColor = {0.8, 1, 1, 1},                       
        activeBorderColor = {0.8, 1, 1, 1},
        Label = { textColor = {0, 1, 180/255, 0.9} },
    }
    if self.luis.setTheme then
        self.luis.setTheme(cyberpunkTheme)
    end
    
    self.updateTimer = 0
    self.isBuilt = false
    
    -- UI element references for dynamic updates
    self.moneyLabel = nil
    self.repLabel = nil
    self.incomeRateLabel = nil
    self.contractLabels = {}
    self.specialistLabels = {}
    self.threatLabels = {}
    
    -- Subscribe to game events for real-time updates
    self.eventBus:subscribe("resource_changed", function() self:quickUpdateResources() end)
    self.eventBus:subscribe("contract_accepted", function() self:scheduleRebuild() end)
    self.eventBus:subscribe("contract_completed", function() self:scheduleRebuild() end)
    self.eventBus:subscribe("threat_generated", function() self:scheduleRebuild() end)
    self.eventBus:subscribe("threat_resolved", function() self:scheduleRebuild() end)
    self.eventBus:subscribe("specialist_hired", function() self:scheduleRebuild() end)
    
    self.needsRebuild = false
    
    return self
end

function SOCViewLuis:load(data)
    print("🎮 SOCViewLuis: Entering main SOC operations view")
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    if not self.isBuilt then
        self:buildUI()
        self.isBuilt = true
    end
    
    self:updateAll()
end

function SOCViewLuis:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function SOCViewLuis:scheduleRebuild()
    self.needsRebuild = true
end

function SOCViewLuis:quickUpdateResources()
    -- Fast update for just resources without rebuilding entire UI
    if not self.systems or not self.systems.resourceManager or not self.isBuilt then return end
    
    local money = self.systems.resourceManager:getResource("money") or 0
    local rep = self.systems.resourceManager:getResource("reputation") or 0
    
    -- Calculate income rate
    local incomeRate = 0
    if self.systems.contractSystem and self.systems.contractSystem.activeContracts then
        for _, contract in pairs(self.systems.contractSystem.activeContracts) do
            if contract.incomePerSecond then
                incomeRate = incomeRate + contract.incomePerSecond
            end
        end
    end
    
    if self.moneyLabel and self.moneyLabel.setText then
        self.moneyLabel:setText(string.format("💰 Money: $%.0f", money))
    end
    if self.repLabel and self.repLabel.setText then
        self.repLabel:setText(string.format("🌟 Reputation: %.0f", rep))
    end
    if self.incomeRateLabel and self.incomeRateLabel.setText then
        self.incomeRateLabel:setText(string.format("📈 Income: $%.1f/s", incomeRate))
    end
end

function SOCViewLuis:updateAll()
    -- Comprehensive update when game state changes significantly
    if self.needsRebuild then
        self:rebuildUI()
        self.needsRebuild = false
    else
        self:quickUpdateResources()
        self:updateDynamicPanels()
    end
end

function SOCViewLuis:updateDynamicPanels()
    -- Update contract progress bars, threat timers, etc.
    if not self.isBuilt then return end
    
    -- Update contracts
    if self.systems.contractSystem then
        local activeContracts = self.systems.contractSystem.activeContracts or {}
        local i = 1
        for _, contract in pairs(activeContracts) do
            if self.contractLabels[i] then
                local progress = 100 - ((contract.remainingTime / contract.duration) * 100)
                local text = string.format("%s: %.0f%%", contract.displayName or contract.clientName, progress)
                if self.contractLabels[i].setText then
                    self.contractLabels[i]:setText(text)
                end
            end
            i = i + 1
            if i > 3 then break end -- Limit to 3 displayed contracts
        end
    end
    
    -- Update threats
    if self.systems.threatSystem then
        local activeThreats = self.systems.threatSystem.activeThreats or {}
        local i = 1
        for _, threat in pairs(activeThreats) do
            if self.threatLabels[i] then
                local timeLeft = threat.timeToResolve or 0
                local text = string.format("🚨 %s (%.0fs)", threat.name, timeLeft)
                if self.threatLabels[i].setText then
                    self.threatLabels[i]:setText(text)
                end
            end
            i = i + 1
            if i > 3 then break end -- Limit to 3 displayed threats
        end
    end
end

function SOCViewLuis:rebuildUI()
    if not self.luis then return end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self.contractLabels = {}
    self.specialistLabels = {}
    self.threatLabels = {}
    self:buildUI()
    self:quickUpdateResources()
end

function SOCViewLuis:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    -- Header: Title and Resources
    luis.insertElement(self.layerName, luis.newLabel("SOC COMMAND CENTER", numCols, 2, 2, 1, "center"))
    
    self.moneyLabel = luis.newLabel("💰 Money: $0", 25, 1, 5, 3)
    luis.insertElement(self.layerName, self.moneyLabel)
    
    self.repLabel = luis.newLabel("🌟 Reputation: 0", 25, 1, 6, 3)
    luis.insertElement(self.layerName, self.repLabel)
    
    self.incomeRateLabel = luis.newLabel("📈 Income: $0/s", 25, 1, 7, 3)
    luis.insertElement(self.layerName, self.incomeRateLabel)
    
    -- Left Panel: Active Contracts
    local leftPanelCol = 3
    local leftPanelWidth = math.floor(numCols * 0.3)
    
    luis.insertElement(self.layerName, luis.newLabel("ACTIVE CONTRACTS", leftPanelWidth, 2, 10, leftPanelCol, "left"))
    
    local contractsExist = false
    if self.systems.contractSystem then
        local activeContracts = self.systems.contractSystem.activeContracts or {}
        local contractRow = 12
        local count = 0
        for _, contract in pairs(activeContracts) do
            if count >= 3 then break end
            contractsExist = true
            local progress = 100 - ((contract.remainingTime / contract.duration) * 100)
            local contractLabel = luis.newLabel(
                string.format("%s: %.0f%%", contract.displayName or contract.clientName, progress),
                leftPanelWidth - 2,
                2,
                contractRow,
                leftPanelCol,
                "left"
            )
            luis.insertElement(self.layerName, contractLabel)
            table.insert(self.contractLabels, contractLabel)
            contractRow = contractRow + 2
            count = count + 1
        end
        
        if not contractsExist then
            luis.insertElement(self.layerName, luis.newLabel("No active contracts", leftPanelWidth - 2, 1, 12, leftPanelCol, "left"))
        end
    end
    
    -- Middle Panel: Active Threats
    local midPanelCol = leftPanelCol + leftPanelWidth + 2
    local midPanelWidth = math.floor(numCols * 0.3)
    
    luis.insertElement(self.layerName, luis.newLabel("ACTIVE THREATS", midPanelWidth, 2, 10, midPanelCol, "left"))
    
    local threatsExist = false
    if self.systems.threatSystem then
        local activeThreats = self.systems.threatSystem.activeThreats or {}
        local threatRow = 12
        local count = 0
        for _, threat in pairs(activeThreats) do
            if count >= 3 then break end
            threatsExist = true
            local timeLeft = threat.timeToResolve or 0
            local threatLabel = luis.newLabel(
                string.format("🚨 %s (%.0fs)", threat.name, timeLeft),
                midPanelWidth - 2,
                2,
                threatRow,
                midPanelCol,
                "left"
            )
            luis.insertElement(self.layerName, threatLabel)
            table.insert(self.threatLabels, threatLabel)
            threatRow = threatRow + 2
            count = count + 1
        end
        
        if not threatsExist then
            luis.insertElement(self.layerName, luis.newLabel("All systems secure", midPanelWidth - 2, 1, 12, midPanelCol, "left"))
        end
    end
    
    -- Right Panel: Team Summary
    local rightPanelCol = midPanelCol + midPanelWidth + 2
    local rightPanelWidth = numCols - rightPanelCol - 2
    
    luis.insertElement(self.layerName, luis.newLabel("TEAM STATUS", rightPanelWidth, 2, 10, rightPanelCol, "left"))
    
    if self.systems.specialistSystem then
        local team = self.systems.specialistSystem:getTeam() or {}
        if #team > 0 then
            luis.insertElement(self.layerName, luis.newLabel(
                string.format("%d Specialists", #team),
                rightPanelWidth - 2,
                1,
                12,
                rightPanelCol,
                "left"
            ))
            local specRow = 13
            for i = 1, math.min(3, #team) do
                local spec = team[i]
                luis.insertElement(self.layerName, luis.newLabel(
                    string.format("• %s (L%d)", spec.name or spec.displayName, spec.level or 1),
                    rightPanelWidth - 2,
                    1,
                    specRow,
                    rightPanelCol,
                    "left"
                ))
                specRow = specRow + 1
            end
        else
            luis.insertElement(self.layerName, luis.newLabel("No specialists hired", rightPanelWidth - 2, 1, 12, rightPanelCol, "left"))
        end
    end
    
    -- Bottom: Action Buttons (centered)
    local buttonWidth = 25
    local buttonStartCol = math.floor((numCols - (buttonWidth * 2 + 5)) / 2)
    local buttonRow = numRows - 12
    
    luis.insertElement(self.layerName, luis.newButton("📋 Contracts", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "contracts_board"})
    end, nil, buttonRow, buttonStartCol))
    
    luis.insertElement(self.layerName, luis.newButton("👥 Specialists", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "specialist_management"})
    end, nil, buttonRow, buttonStartCol + buttonWidth + 3))
    
    buttonRow = buttonRow + 4
    
    luis.insertElement(self.layerName, luis.newButton("⬆️ Upgrades", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "upgrade_shop"})
    end, nil, buttonRow, buttonStartCol))
    
    luis.insertElement(self.layerName, luis.newButton("🎯 Skills", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "skill_tree"})
    end, nil, buttonRow, buttonStartCol + buttonWidth + 3))

    -- Footer
    luis.insertElement(self.layerName, luis.newLabel("ESC: Main Menu | F3: Debug Stats", numCols, 1, numRows - 2, 1, "center"))
end

function SOCViewLuis:update(dt)
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer > 0.5 then -- Update twice per second
        self:updateAll()
        self.updateTimer = 0
    end
end

function SOCViewLuis:draw()
    -- Background ensures consistent rendering
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function SOCViewLuis:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
        return true
    end
end

return SOCViewLuis