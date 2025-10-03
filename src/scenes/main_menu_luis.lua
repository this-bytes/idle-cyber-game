-- Main Menu Scene - Pure LUIS Implementation
-- SOC Game Entry Point using LUIS (Love UI System)
-- No SmartUIManager - Pure community library approach

--[[
    LUIS INTEGRATION PATTERN FOR SCENES
    ====================================
    
    This scene demonstrates the correct pattern for using LUIS (Love UI System)
    directly without any wrapper classes. Follow this pattern when migrating
    other scenes.
    
    INITIALIZATION:
    ---------------
    1. Scene constructor receives the LUIS instance directly from SOCGame:
       function Scene.new(eventBus, luis)
           self.luis = luis  -- Store direct reference, no wrapper
       end
    
    2. LUIS is initialized once in SOCGame.initialize():
       local initLuis = require("luis.init")
       self.luis = initLuis("lib/luis/widgets")
    
    LAYER LIFECYCLE:
    ----------------
    1. CREATE layer in load():
       self.luis.newLayer(self.layerName)
       self.luis.setCurrentLayer(self.layerName)  -- Activates and enables layer
    
    2. BUILD UI in buildUI():
       -- Create widgets using luis.newXXX functions
       local widget = luis.newButton(text, width, height, onClick, onRelease, row, col)
       
       -- Add to layer using insertElement (NOT createElement with existing widget)
       luis.insertElement(self.layerName, widget)
    
    3. DISABLE layer in exit():
       self.luis.disableLayer(self.layerName)  -- Hides layer but preserves it
       -- OR for complete cleanup:
       self.luis.removeLayer(self.layerName)   -- Deletes layer entirely
    
    WIDGET CREATION:
    ----------------
    - Use luis.newXXX() functions to create widgets with grid-based positioning
    - Grid positions start at (1,1), not (0,0)
    - Widget signatures follow pattern: (params..., row, col, [theme])
    - Example: luis.newButton(text, width, height, onClick, onRelease, row, col)
    
    IMPORTANT: Use insertElement, NOT createElement for pre-created widgets!
    - CORRECT:   widget = luis.newButton(...); luis.insertElement(layer, widget)
    - INCORRECT: luis.createElement(layer, "Button", widget)  -- This creates ANOTHER button!
    
    INPUT HANDLING:
    ---------------
    LUIS handles input globally in SOCGame:
    - luis.update(dt) - Called in SOCGame:update()
    - luis.draw() - Called in SOCGame:draw()
    - luis.mousepressed/mousereleased/keypressed/etc - Called in SOCGame input handlers
    
    Scenes don't need to handle LUIS input unless they need custom behavior.
    
    LAYER VISIBILITY:
    -----------------
    - setCurrentLayer(name) - Enables and activates a layer
    - enableLayer(name) - Shows a layer
    - disableLayer(name) - Hides a layer (preserves elements)
    - removeLayer(name) - Deletes a layer entirely
    - isLayerEnabled(name) - Check if layer is visible
    
    DEBUGGING:
    ----------
    Press TAB to toggle LUIS debug view:
    - Grid overlay
    - Element outlines  
    - Layer names
--]]

local MainMenuLuis = {}
MainMenuLuis.__index = MainMenuLuis

-- Create new main menu scene
function MainMenuLuis.new(eventBus, luis)
    local self = setmetatable({}, MainMenuLuis)
    
    -- Scene state
    self.eventBus = eventBus
    self.luis = luis  -- Direct LUIS instance, no wrapper
    self.layerName = "main_menu"
    
    return self
end

-- Load/Enter the main menu scene
function MainMenuLuis:load(data)
    print("🏠 Main Menu (LUIS): Loading main menu")
    
    -- Create dedicated layer for this scene
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Build the UI using LUIS
    self:buildUI()
end

-- Build the main menu UI with LUIS widgets
function MainMenuLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    print(string.format("🏠 Building UI - Screen: %dx%d, GridSize: %d", screenWidth, screenHeight, luis.gridSize))
    
    -- Calculate grid-based positioning
    local gridSize = luis.gridSize
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Create widgets using newXXX, then insert them with insertElement
    -- Title Label
    local titleLabel = luis.newLabel("🛡️ SOC Command Center", 25, 3, centerRow - 10, centerCol - 12)
    luis.insertElement(self.layerName, titleLabel)
    
    -- Start Game Button
    local startButton = luis.newButton(
        "▶ Start Game",
        20, 3,
        function()
            print("🎮 Start Game button clicked")
            if self.eventBus then
                self.eventBus:publish("request_scene_change", {scene = "soc_view"})
            end
        end,
        nil, -- onRelease
        centerRow - 4,
        centerCol - 10
    )
    luis.insertElement(self.layerName, startButton)
    
    -- Continue Button
    local continueButton = luis.newButton(
        "💾 Continue",
        20, 3,
        function()
            print("💾 Continue Game button clicked")
            if self.eventBus then
                self.eventBus:publish("request_scene_change", {scene = "soc_view"})
            end
        end,
        nil,
        centerRow,
        centerCol - 10
    )
    luis.insertElement(self.layerName, continueButton)
    
    -- Settings Button
    local settingsButton = luis.newButton(
        "⚙ Settings",
        20, 3,
        function()
            print("⚙️ Settings button clicked")
        end,
        nil,
        centerRow + 4,
        centerCol - 10
    )
    luis.insertElement(self.layerName, settingsButton)
    
    -- Quit Button
    local quitButton = luis.newButton(
        "❌ Quit",
        20, 3,
        function()
            print("🚪 Quit button clicked")
            love.event.quit()
        end,
        nil,
        centerRow + 8,
        centerCol - 10
    )
    luis.insertElement(self.layerName, quitButton)
    
    print("🎨 Main Menu UI built with 5 LUIS widgets")
end

-- Exit the main menu scene
function MainMenuLuis:exit()
    print("🏠 MainMenu (LUIS): Exiting main menu")
    
    -- CRITICAL: Disable the LUIS layer to hide it from rendering
    -- This is necessary because LUIS renders ALL enabled layers
    -- Just clearing elements isn't enough - the layer remains visible!
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
        print("🏠 MainMenu (LUIS): Layer '" .. self.layerName .. "' disabled")
    end
    
    -- Optional: Remove layer entirely if you won't return to this scene
    -- self.luis.removeLayer(self.layerName)
end

-- Update main menu (LUIS handles its own updates via SOCGame)
function MainMenuLuis:update(dt)
    -- Scene-specific updates can go here
    -- LUIS update is handled globally by SOCGame
end

-- Draw main menu (LUIS handles its own drawing via SOCGame)
function MainMenuLuis:draw()
    -- Scene-specific drawing can go here
    -- LUIS draw is handled globally by SOCGame
    
    -- Optional: Draw scene-specific background
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
    
    -- Draw subtitle/version info
    love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
    love.graphics.print("v0.1.0-alpha | Press TAB for debug view", 10, love.graphics.getHeight() - 20)
end

-- Input handlers (LUIS handles input globally, scenes can override if needed)
function MainMenuLuis:keypressed(key, scancode, isrepeat)
    -- Scene-specific key handling
end

function MainMenuLuis:mousepressed(x, y, button, istouch, presses)
    -- Scene-specific mouse handling
end

return MainMenuLuis
