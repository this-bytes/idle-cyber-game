--[[
    Main Menu Scene (LUIS)
    ----------------------
    This is a self-contained scene file that follows the original, working architecture.
    It includes the enhanced visuals and corrected vertical button layout.
]]

local MainMenuLuis = {}
MainMenuLuis.__index = MainMenuLuis

function MainMenuLuis.new(eventBus, luis)
    local self = setmetatable({}, MainMenuLuis)
    
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = "main_menu"

    -- Define and apply the theme directly in the constructor.
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

function MainMenuLuis:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end

function MainMenuLuis:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function MainMenuLuis:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    local buttonWidth = 30
    local buttonHeight = 3
    local buttonGap = 2

    local centerCol = math.floor((numCols - buttonWidth) / 2)
    
    local numButtons = 4
    local totalStackHeight = (buttonHeight * numButtons) + (buttonGap * (numButtons - 1))
    local startRow = math.floor((numRows - totalStackHeight) / 2) + 4

    local currentRow = startRow

    luis.insertElement(self.layerName, luis.newButton("NEW OPERATION", buttonWidth, buttonHeight, function()
        self.eventBus:publish("request_scene_change", {scene = "soc_joker", new_run = true})
    end, nil, currentRow, centerCol))
    currentRow = currentRow + buttonHeight + buttonGap

    luis.insertElement(self.layerName, luis.newButton("CONTINUE OPERATION", buttonWidth, buttonHeight, function()
        self.eventBus:publish("request_scene_change", {scene = "soc_joker"})
    end, nil, currentRow, centerCol))
    currentRow = currentRow + buttonHeight + buttonGap

    luis.insertElement(self.layerName, luis.newButton("SYSTEM CONFIG", buttonWidth, buttonHeight, function()
        print("⚙️ System Config button clicked")
    end, nil, currentRow, centerCol))
    currentRow = currentRow + buttonHeight + buttonGap

    luis.insertElement(self.layerName, luis.newButton("TERMINATE", buttonWidth, buttonHeight, function()
        love.event.quit()
    end, nil, currentRow, centerCol))
end

function MainMenuLuis:update(dt)
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

function MainMenuLuis:draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.push("all")

    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    if self.backgroundImage then
        local scaleX = w / self.backgroundImage:getWidth()
        local scaleY = h / self.backgroundImage:getHeight()
        love.graphics.draw(self.backgroundImage, 0, 0, 0, scaleX, scaleY)
    else
        love.graphics.clear(0.05, 0.05, 0.1, 1.0)
    end

    love.graphics.setFont(self.fontTitle)
    love.graphics.setColor(0, 1, 180/255, 1)
    local titleText = "IDLE CYBER OPS"
    local titleY = h * 0.20
    if self.isGlitching then
        self:drawGlitchedText(titleText, titleY)
    else
        love.graphics.printf(titleText, 0, titleY, w, "center")
    end

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

    love.graphics.setColor(0, 0, 0, 0.4)
    for y = 0, h / 4, 1 do
        love.graphics.rectangle("fill", 0, y * 4 + self.scanlineOffset, w, 2)
    end

    love.graphics.pop()
end

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

function MainMenuLuis:keypressed(key, scancode, isrepeat) end
function MainMenuLuis:mousepressed(x, y, button, istouch, presses) end

return MainMenuLuis