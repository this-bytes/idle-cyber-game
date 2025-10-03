-- Game Over Scene - SOC Failure Management (LUIS Version)
-- Handles game over scenarios when SOC operations fail catastrophically
-- Provides restart and analysis options
-- Migrated to LUIS (Love UI System) for consistency with new UI framework

local GameOverLuis = {}
GameOverLuis.__index = GameOverLuis

function GameOverLuis.new(eventBus, luis)
    local self = setmetatable({}, GameOverLuis)
    self.eventBus = eventBus
    self.luis = luis  -- Direct LUIS instance
    self.layerName = "game_over"
    self.reason = "Unknown failure"
    self.stats = {}
    print("💀 GameOverLuis: Initialized game over scene")
    return self
end

function GameOverLuis:load(data)
    if data then
        self.reason = data.reason or "SOC operations failed"
        self.stats = data.stats or {}
    end
    print("💀 GameOverLuis: SOC operations terminated - " .. self.reason)
    
    -- Create dedicated layer for this scene
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Build the UI
    self:buildUI()
end

function GameOverLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    -- Calculate center positions
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Dark overlay (full screen background)
    -- Note: LUIS doesn't have a simple overlay widget, so we use a large label
    local bgWidth = math.floor(screenWidth / gridSize)
    local bgHeight = math.floor(screenHeight / gridSize)
    local background = luis.newLabel("", bgWidth, bgHeight, 0, 0)
    luis.insertElement(self.layerName, background)
    
    -- Game over title
    local title = luis.newLabel("💀 SOC OPERATIONS TERMINATED", 30, 3, centerRow - 8, centerCol - 15)
    luis.insertElement(self.layerName, title)
    
    -- Failure reason
    local reasonLabel = luis.newLabel(self.reason, 40, 2, centerRow - 4, centerCol - 20)
    luis.insertElement(self.layerName, reasonLabel)
    
    -- Restart button
    local restartButton = luis.newButton(
        "🔄 Restart SOC",
        20, 3,
        function()
            print("🔄 Restart button clicked")
            if self.eventBus then
                self.eventBus:publish("restart_game_request", {})
            end
        end,
        nil,
        centerRow + 4,
        centerCol - 10
    )
    luis.insertElement(self.layerName, restartButton)
    
    -- Main Menu button
    local menuButton = luis.newButton(
        "🏠 Main Menu",
        20, 3,
        function()
            print("🏠 Main Menu button clicked")
            if self.eventBus then
                self.eventBus:publish("scene_request", {scene = "main_menu"})
            end
        end,
        nil,
        centerRow + 8,
        centerCol - 10
    )
    luis.insertElement(self.layerName, menuButton)
    
    -- Quit button
    local quitButton = luis.newButton(
        "❌ Quit",
        20, 3,
        function()
            print("🚪 Quit button clicked")
            love.event.quit()
        end,
        nil,
        centerRow + 12,
        centerCol - 10
    )
    luis.insertElement(self.layerName, quitButton)
    
    -- Keyboard shortcuts info
    local shortcuts = luis.newLabel("Keyboard: [R] Restart | [M] Menu | [Q] Quit", 40, 1, centerRow + 16, centerCol - 20)
    luis.insertElement(self.layerName, shortcuts)
    
    print("💀 GameOverLuis: UI built with LUIS")
end

function GameOverLuis:exit()
    print("💀 GameOverLuis: Exiting game over scene")
    
    -- Disable the LUIS layer
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
        print("💀 GameOverLuis: Layer '" .. self.layerName .. "' disabled")
    end
end

function GameOverLuis:update(dt)
    -- Scene update logic (if needed)
end

-- Keyboard shortcuts (in addition to LUIS button clicks)
function GameOverLuis:keypressed(key)
    if key == "r" then
        self.eventBus:publish("restart_game_request", {})
    elseif key == "m" then
        self.eventBus:publish("scene_request", {scene = "main_menu"})
    elseif key == "q" then
        love.event.quit()
    end
end

return GameOverLuis
