-- SOC View Scene - Main Operational Interface (LUIS Version)
-- This scene has been refactored to use the base_scene_luis.lua class.

local BaseSceneLuis = require("src.scenes.base_scene_luis")

local SOCViewLuis = {}
SOCViewLuis.__index = SOCViewLuis
setmetatable(SOCViewLuis, {__index = BaseSceneLuis})


function SOCViewLuis.new(eventBus, luis, systems)
    local self = BaseSceneLuis.new(eventBus, luis, "soc_view")
    setmetatable(self, SOCViewLuis)
    
    self.systems = systems
    
    -- Set the theme
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
    self:setTheme(cyberpunkTheme)
    
    -- Internal State
    self.resources = {}
    self.contracts = {}
    self.specialists = {}
    
    -- Subscribe to events to keep data fresh
    self.eventBus:subscribe("resource_changed", function() self:updateData() end)
    self.eventBus:subscribe("contract_accepted", function() self:updateData() end)
    self.eventBus:subscribe("contract_completed", function() self:updateData() end)
    self.eventBus:subscribe("specialist_hired", function() self:updateData() end)
    self.eventBus:subscribe("upgrade_purchased", function() self:updateData() end)
    
    return self
end

function SOCViewLuis:onLoad(data)
    print("🎮 SOCViewLuis: Entering main SOC operations view")
    self:updateData()
end

function SOCViewLuis:updateData()
    if self.systems.resourceManager then
        self.resources.money = self.systems.resourceManager:getResource("money") or 0
        self.resources.reputation = self.systems.resourceManager:getResource("reputation") or 0
    end
    -- Other data updates would go here

    -- Since LUIS doesn't automatically re-render labels on data change, 
    -- we need to rebuild the UI to show new values.
    self:rebuildUI()
end

function SOCViewLuis:rebuildUI()
    if not self.luis or not self.luis.isLayerEnabled(self.layerName) then return end
    self.luis.clearLayer(self.layerName)
    self:buildUI()
end

function SOCViewLuis:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    -- Title
    luis.insertElement(self.layerName, luis.newLabel("SOC COMMAND CENTER", numCols, 2, 2, 1, "center"))
    
    -- Resource Display
    local moneyText = string.format("💰 Money: $%.0f", self.resources.money or 0)
    luis.insertElement(self.layerName, luis.newLabel(moneyText, 25, 1, 5, 3))
    
    local repText = string.format("🌟 Reputation: %.0f", self.resources.reputation or 0)
    luis.insertElement(self.layerName, luis.newLabel(repText, 25, 1, 6, 3))

    -- Main Action Buttons
    local buttonWidth = 25
    local startCol = math.floor((numCols - buttonWidth) / 2) - 20
    local startRow = 12

    luis.insertElement(self.layerName, luis.newButton("Contracts", buttonWidth, 3, function() print("Contracts Clicked") end, nil, startRow, startCol))
    luis.insertElement(self.layerName, luis.newButton("Specialists", buttonWidth, 3, function() print("Specialists Clicked") end, nil, startRow + 4, startCol))
    luis.insertElement(self.layerName, luis.newButton("Upgrades", buttonWidth, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "upgrade_shop"})
    end, nil, startRow + 8, startCol))

    -- Bottom Nav
    luis.insertElement(self.layerName, luis.newLabel("ESC: Main Menu", numCols, 1, numRows - 2, 1, "center"))
end

function SOCViewLuis:onUpdate(dt)
    -- Game logic updates would go here
end

function SOCViewLuis:onDraw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function SOCViewLuis:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
    end
end

return SOCViewLuis