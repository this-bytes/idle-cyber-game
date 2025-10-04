-- SOC View Scene - Main Operational Interface (LUIS Version)
-- Central command view for SOC operations
-- Migrated to LUIS (Love UI System) - Simplified functional version
-- Note: Full feature parity with original requires significant development time
-- This version provides core functionality with LUIS framework

local SOCViewLuis = {}
SOCViewLuis.__index = SOCViewLuis

function SOCViewLuis.new(eventBus, luis)
    local self = setmetatable({}, SOCViewLuis)
    
    -- Dependencies
    self.systems = {} -- Injected by SceneManager on enter
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = "soc_view"
    
    -- Internal State
    self.resources = {}
    self.contracts = {}
    self.specialists = {}
    self.upgrades = {}
    
    -- Panel navigation
    self.selectedPanel = "resources" -- Default panel
    self.panels = {
        {name = "Resources", key = "resources", icon = "💰"},
        {name = "Contracts", key = "contracts", icon = "📋"},
        {name = "Specialists", key = "specialists", icon = "👥"},
        {name = "Upgrades", key = "upgrades", icon = "⬆️"}
    }
    
    -- Subscribe to events
    if self.eventBus then
        self.eventBus:subscribe("resource_changed", function() self:updateData() end)
        self.eventBus:subscribe("contract_accepted", function() self:updateData() end)
        self.eventBus:subscribe("contract_completed", function() self:updateData() end)
        self.eventBus:subscribe("specialist_hired", function() self:updateData() end)
        self.eventBus:subscribe("upgrade_purchased", function() self:updateData() end)
    end
    
    return self
end

function SOCViewLuis:load(data)
    print("🎮 SOCViewLuis: Entering main SOC operations view")
    
    -- Create LUIS layer
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Update data from systems
    self:updateData()
    
    -- Build UI
    self:buildUI()
end

function SOCViewLuis:updateData()
    -- Update cached data from systems
    if self.systems.resourceManager then
        self.resources.money = self.systems.resourceManager:getResource("money") or 0
        self.resources.reputation = self.systems.resourceManager:getResource("reputation") or 0
        self.resources.xp = self.systems.resourceManager:getResource("xp") or 0
    end
    
    if self.systems.contractSystem then
        local activeContracts = self.systems.contractSystem.activeContracts or {}
        self.contracts.active = 0
        for _ in pairs(activeContracts) do
            self.contracts.active = self.contracts.active + 1
        end
    end
    
    if self.systems.specialistSystem then
        local team = self.systems.specialistSystem:getTeam() or {}
        self.specialists.total = 0
        for _ in pairs(team) do
            self.specialists.total = self.specialists.total + 1
        end
    end
end

function SOCViewLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Title
    local title = luis.newLabel("🛡️ SOC COMMAND CENTER", 35, 2, 2, centerCol - 17)
    luis.insertElement(self.layerName, title)
    
    -- Resource display
    local moneyText = string.format("💰 Money: $%.0f", self.resources.money or 0)
    local moneyLabel = luis.newLabel(moneyText, 20, 1, 5, 2)
    luis.insertElement(self.layerName, moneyLabel)
    
    local repText = string.format("🌟 Reputation: %.0f", self.resources.reputation or 0)
    local repLabel = luis.newLabel(repText, 20, 1, 6, 2)
    luis.insertElement(self.layerName, repLabel)
    
    local xpText = string.format("📈 XP: %.0f", self.resources.xp or 0)
    local xpLabel = luis.newLabel(xpText, 20, 1, 7, 2)
    luis.insertElement(self.layerName, xpLabel)
    
    -- Panel navigation buttons
    local startRow = 10
    local leftCol = 2
    
    for i, panel in ipairs(self.panels) do
        local button = luis.newButton(
            panel.icon .. " " .. panel.name,
            18, 2,
            function()
                self.selectedPanel = panel.key
                print("Selected panel: " .. panel.name)
            end,
            nil,
            startRow + (i-1) * 3,
            leftCol
        )
        luis.insertElement(self.layerName, button)
    end
    
    -- Info display area
    local infoText = "Welcome to SOC Command Center"
    local infoLabel = luis.newLabel(infoText, 50, 2, centerRow, centerCol - 25)
    luis.insertElement(self.layerName, infoLabel)
    
    -- Quick action buttons (center-right)
    local rightCol = centerCol + 15
    
    local contractsButton = luis.newButton(
        "📋 View Contracts",
        18, 2,
        function()
            print("View Contracts clicked")
            -- Navigate to contracts view
        end,
        nil,
        startRow,
        rightCol
    )
    luis.insertElement(self.layerName, contractsButton)
    
    local specialistsButton = luis.newButton(
        "👥 Manage Team",
        18, 2,
        function()
            print("Manage Team clicked")
            -- Navigate to specialists view
        end,
        nil,
        startRow + 3,
        rightCol
    )
    luis.insertElement(self.layerName, specialistsButton)
    
    local upgradesButton = luis.newButton(
        "⬆️ Upgrade Shop",
        18, 2,
        function()
            if self.eventBus then
                self.eventBus:publish("scene_request", {scene = "upgrade_shop"})
            end
        end,
        nil,
        startRow + 6,
        rightCol
    )
    luis.insertElement(self.layerName, upgradesButton)
    
    -- Bottom info
    local statsText = string.format("Active Contracts: %d | Specialists: %d", 
        self.contracts.active or 0, self.specialists.total or 0)
    local statsLabel = luis.newLabel(statsText, 50, 1, centerRow + 15, centerCol - 25)
    luis.insertElement(self.layerName, statsLabel)
    
    -- Instructions
    local helpText = "ESC: Main Menu | F3: Debug Overlay | TAB: LUIS Debug"
    local helpLabel = luis.newLabel(helpText, 50, 1, centerRow + 17, centerCol - 25)
    luis.insertElement(self.layerName, helpLabel)
    
    print("🎮 SOCViewLuis: UI built")
end

function SOCViewLuis:update(dt)
    -- Update game state periodically
    if self.updateTimer then
        self.updateTimer = self.updateTimer + dt
        if self.updateTimer >= 1.0 then -- Update every second
            self:updateData()
            self.updateTimer = 0
            -- Rebuild UI to show updated values
            self:rebuildUI()
        end
    else
        self.updateTimer = 0
    end
end

function SOCViewLuis:rebuildUI()
    -- Rebuild UI with updated data
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
    self.luis.enableLayer(self.layerName)
end

function SOCViewLuis:exit()
    print("🎮 SOCViewLuis: Exiting main SOC operations view")
    
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function SOCViewLuis:keypressed(key)
    if key == "escape" then
        -- Return to main menu
        if self.eventBus then
            self.eventBus:publish("scene_request", {scene = "main_menu"})
        end
    elseif key == "tab" then
        -- Cycle through panels
        local currentIndex = 1
        for i, panel in ipairs(self.panels) do
            if panel.key == self.selectedPanel then
                currentIndex = i
                break
            end
        end
        local nextIndex = (currentIndex % #self.panels) + 1
        self.selectedPanel = self.panels[nextIndex].key
        print("Switched to panel: " .. self.panels[nextIndex].name)
    end
end

function SOCViewLuis:mousepressed(x, y, button)
    -- Mouse input handled by LUIS
end

function SOCViewLuis:mousereleased(x, y, button)
    -- Mouse input handled by LUIS
end

return SOCViewLuis
