-- SOC View Scene - Main Operational Interface (LUIS Version)
-- This scene has been refactored to use the correct, efficient UI update pattern.

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
    self.moneyLabel = nil
    self.repLabel = nil
    
    self.eventBus:subscribe("resource_changed", function() self:updateLabels() end)
    
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
    
    self:updateLabels()
end

function SOCViewLuis:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function SOCViewLuis:updateLabels()
    if not self.systems or not self.systems.resourceManager or not self.isBuilt then return end
    local money = self.systems.resourceManager:getResource("money") or 0
    local rep = self.systems.resourceManager:getResource("reputation") or 0
    if self.moneyLabel and self.moneyLabel.setText then
        self.moneyLabel:setText(string.format("💰 Money: $%.0f", money))
    end
    if self.repLabel and self.repLabel.setText then
        self.repLabel:setText(string.format("🌟 Reputation: %.0f", rep))
    end
end

function SOCViewLuis:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    luis.insertElement(self.layerName, luis.newLabel("SOC COMMAND CENTER", numCols, 2, 2, 1, "center"))
    
    self.moneyLabel = luis.newLabel("", 25, 1, 5, 3)
    luis.insertElement(self.layerName, self.moneyLabel)
    
    self.repLabel = luis.newLabel("", 25, 1, 6, 3)
    luis.insertElement(self.layerName, self.repLabel)

    local buttonWidth = 25
    local startCol = math.floor((numCols - buttonWidth) / 2) - 20
    local startRow = 12
    local buttonGap = 4

    luis.insertElement(self.layerName, luis.newButton("Contracts", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "contracts_board"})
    end, nil, startRow, startCol))
    luis.insertElement(self.layerName, luis.newButton("Specialists", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "specialist_management"})
    end, nil, startRow + buttonGap, startCol))
    luis.insertElement(self.layerName, luis.newButton("Upgrades", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "upgrade_shop"})
    end, nil, startRow + buttonGap * 2, startCol))
    luis.insertElement(self.layerName, luis.newButton("Skills", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "skill_tree"})
    end, nil, startRow + buttonGap * 3, startCol))

    luis.insertElement(self.layerName, luis.newButton("Test Modal", buttonWidth, 3, function() 
        self.eventBus:publish("push_scene", {scene = "modal_dialog", data = {title = "LEVEL UP!", message = "You have reached a new level of proficiency."}})
    end, nil, startRow + buttonGap * 4, startCol))

    luis.insertElement(self.layerName, luis.newLabel("ESC: Main Menu", numCols, 1, numRows - 2, 1, "center"))
end

function SOCViewLuis:update(dt)
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer > 1.0 then
        self:updateLabels()
        self.updateTimer = 0
    end
end

function SOCViewLuis:draw()
    -- *** BUG FIX ***
    -- Restore a basic background draw call so the screen is not blank.
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function SOCViewLuis:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
        return true
    end
end

return SOCViewLuis