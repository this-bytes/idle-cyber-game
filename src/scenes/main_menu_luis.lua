--[[
    Main Menu Scene (LUIS)
    ----------------------
    This scene inherits from `base_scene_luis.lua` and demonstrates the correct,
    final pattern for creating a themed UI scene.
]]

local BaseSceneLuis = require("src.scenes.base_scene_luis")

local MainMenuLuis = {}
MainMenuLuis.__index = MainMenuLuis
setmetatable(MainMenuLuis, {__index = BaseSceneLuis})


function MainMenuLuis.new(eventBus, luis)
    local self = BaseSceneLuis.new(eventBus, luis, "main_menu")
    setmetatable(self, MainMenuLuis)

    --[[
        Visuals & Theming
        -----------------
        Define the theme table and pass it to the base class's `setTheme` function.
        This sets the global theme for all UI elements created in this scene.
    --]]
    local cyberpunkTheme = {
        -- Default properties for all widgets
        textColor = {0, 1, 180/255, 1},                      -- Bright Teal
        bgColor = {10/255, 25/255, 20/255, 0.8},            -- Dark, semi-transparent green
        borderColor = {0, 1, 180/255, 0.4},                 -- Semi-transparent teal
        borderWidth = 1,
        -- Hover state
        hoverTextColor = {20/255, 30/255, 25/255, 1},       -- Dark (for contrast)
        hoverBgColor = {0, 1, 180/255, 1},                    -- Solid bright teal
        hoverBorderColor = {0, 1, 180/255, 1},
        -- Active state (when clicked)
        activeTextColor = {20/255, 30/255, 25/255, 1},
        activeBgColor = {0.8, 1, 1, 1},                       -- Bright flash color
        activeBorderColor = {0.8, 1, 1, 1},
        -- Specific widget types
        Label = {
            textColor = {0, 1, 180/255, 0.9},
        },
    }
    self:setTheme(cyberpunkTheme)

    -- Load assets for custom drawing effects
    self.backgroundImage = love.graphics.newImage("assets/splash.jpeg")
    self.fontTitle = love.graphics.newFont("assets/fonts/FiraCode-Bold.ttf", 64)
    self.fontVersion = love.graphics.newFont("assets/fonts/FiraCode-Light.ttf", 14)
    self.fontDecor = love.graphics.newFont("assets/fonts/FiraCode-Regular.ttf", 12)

    -- Animation state variables
    self.glitchTimer = 0
    self.glitchFrequency = 3.0
    self.glitchDuration = 0.15
    self.isGlitching = false
    self.scanlineOffset = 0

    return self
end


--[[
    buildUI() - Required Hook
    ---------------------------
    This function now arranges buttons in a vertically centered stack.
--]]
function MainMenuLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local gridSize = luis.gridSize
    local numCols = math.floor(screenWidth / gridSize)
    local numRows = math.floor(screenHeight / gridSize)
    
    -- Define button dimensions in grid units.
    local buttonWidth = 30
    local buttonHeight = 3
    local buttonGap = 2 -- The space between buttons in grid rows.

    -- Calculate horizontal center for the buttons.
    local centerCol = math.floor((numCols - buttonWidth) / 2)
    
    -- Calculate vertical center for the entire stack of buttons.
    local numButtons = 5 -- Increased to 5 to make room for the Admin button
    local totalStackHeight = (buttonHeight * numButtons) + (buttonGap * (numButtons - 1))
    local startRow = math.floor((numRows - totalStackHeight) / 2) + 4 -- Nudge the stack down a bit from true center

    local currentRow = startRow

    -- Create the buttons in a vertical stack.
    local newOpButton = luis.newButton("NEW OPERATION", buttonWidth, buttonHeight, function()
        self.eventBus:publish("request_scene_change", {scene = "soc_view", new_game = true})
    end, nil, currentRow, centerCol)
    luis.insertElement(self.layerName, newOpButton)
    currentRow = currentRow + buttonHeight + buttonGap

    local loadOpButton = luis.newButton("LOAD OPERATION", buttonWidth, buttonHeight, function()
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
    end, nil, currentRow, centerCol)
    luis.insertElement(self.layerName, loadOpButton)
    currentRow = currentRow + buttonHeight + buttonGap

    local settingsButton = luis.newButton("SYSTEM CONFIG", buttonWidth, buttonHeight, function()
        print("⚙️ System Config button clicked")
    end, nil, currentRow, centerCol)
    luis.insertElement(self.layerName, settingsButton)
    currentRow = currentRow + buttonHeight + buttonGap

    local quitButton = luis.newButton("TERMINATE", buttonWidth, buttonHeight, function()
        love.event.quit()
    end, nil, currentRow, centerCol)
    luis.insertElement(self.layerName, quitButton)
    currentRow = currentRow + buttonHeight + buttonGap

    -- Add the new Admin Console button
    local adminButton = luis.newButton("ADMIN CONSOLE", buttonWidth, buttonHeight, function()
        self.eventBus:publish("request_scene_change", {scene = "incident_admin_luis"})
    end, nil, currentRow, centerCol)
    luis.insertElement(self.layerName, adminButton)
    
    print("🎨 Main Menu UI rebuilt with vertical layout and Admin button.")
end


--[[
    onUpdate(dt) - Optional Hook
--]]
function MainMenuLuis:onUpdate(dt)
    self.glitchTimer = self.glitchTimer + dt
    if self.glitchTimer > self.glitchFrequency then
        self.glitchTimer = -love.math.random() * 1.5
        self.isGlitching = true
        self.glitchEffectTimer = 0
    end

    if self.isGlitching then
        self.glitchEffectTimer = self.glitchEffectTimer + dt
        if self.glitchEffectTimer > self.glitchDuration then
            self.isGlitching = false
        end
    end

    self.scanlineOffset = (self.scanlineOffset + dt * 20) % 4
end


--[[
    onDraw() - Optional Hook
--]]
function MainMenuLuis:onDraw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.push("all") -- Isolate drawing state.

    -- 1. Background
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    if self.backgroundImage then
        local scaleX = w / self.backgroundImage:getWidth()
        local scaleY = h / self.backgroundImage:getHeight()
        love.graphics.draw(self.backgroundImage, 0, 0, 0, scaleX, scaleY)
    else
        love.graphics.clear(0.05, 0.05, 0.1, 1.0)
    end

    -- 2. Title
    love.graphics.setFont(self.fontTitle)
    love.graphics.setColor(0, 1, 180/255, 1)
    local titleText = "IDLE CYBER OPS"
    local titleY = h * 0.20 -- Moved title up slightly
    if self.isGlitching then
        self:drawGlitchedText(titleText, titleY)
    else
        love.graphics.printf(titleText, 0, titleY, w, "center")
    end

    -- 3. Decorative Text
    love.graphics.setFont(self.fontVersion)
    love.graphics.setColor(0, 1, 180/255, 0.7)
    love.graphics.printf("v0.1.0-alpha // PROTOCOL-7 ACTIVE", 0, titleY + 70, w, "center")
    love.graphics.setFont(self.fontDecor)
    love.graphics.setColor(0, 1, 180/255, 0.5)
    love.graphics.print("SYSTEM STATUS: ONLINE", 20, h - 60)
    love.graphics.print("UPLINK: SECURE", 20, h - 45)
    love.graphics.print("THREAT LEVEL: NOMINAL", 20, h - 30)
    local debugText = "Press TAB for LUIS debug view"
    local textWidth = self.fontDecor:getWidth(debugText)
    love.graphics.print(debugText, w - textWidth - 20, h - 30)

    -- 4. Scanline Overlay
    love.graphics.setColor(0, 0, 0, 0.4)
    for y = 0, h / 4, 1 do
        love.graphics.rectangle("fill", 0, y * 4 + self.scanlineOffset, w, 2)
    end

    love.graphics.pop() -- Restore drawing state.
end


--[[
    drawGlitchedText(text, y)
--]]
function MainMenuLuis:drawGlitchedText(text, y)
    local w = love.graphics.getWidth()
    local x_offset = (love.math.random() - 0.5) * 25
    local y_offset = (love.math.random() - 0.5) * 15

    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.printf(text, x_offset - 2, y + y_offset, w, "center")
    
    love.graphics.setColor(0, 1, 1, 0.5)
    love.graphics.printf(text, x_offset + 2, y - y_offset, w, "center")

    love.graphics.setColor(0, 1, 180/255, 1)
    love.graphics.printf(text, x_offset, y, w, "center")
end


return MainMenuLuis
