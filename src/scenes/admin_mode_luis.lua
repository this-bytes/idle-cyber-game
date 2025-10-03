-- Admin Mode Scene - Active Incident Response (LUIS Version)
-- A focused, terminal-style interface for hands-on Incident management
-- Migrated to LUIS (Love UI System) - Simplified functional version

local AdminModeLuis = {}
AdminModeLuis.__index = AdminModeLuis

function AdminModeLuis.new(eventBus, luis)
    local self = setmetatable({}, AdminModeLuis)
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = "admin_mode"
    self.systems = {} -- Injected by SceneManager
    
    -- Terminal UI State
    self.logs = {"[SYSTEM] Secure channel established. Awaiting incident data..."}
    self.inputBuffer = ""
    self.cursorChar = "▋"
    self.cursorBlinkTimer = 0
    self.showCursor = true
    
    -- Gameplay State
    self.incident = nil
    self.commandHistory = {}
    self.historyIndex = 0
    
    return self
end

function AdminModeLuis:load(data)
    print("🚨 Admin Mode Activated: Engaging active incident response.")
    
    -- Create LUIS layer
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    self.logs = {"[SYSTEM] Secure channel established. Awaiting incident data..."}
    self.incident = data and data.incident or nil
    
    if self.incident then
        table.insert(self.logs, string.format("[ALERT] Threat Level %s incident detected: %s", 
            self.incident.severity, self.incident.name))
        table.insert(self.logs, self.incident.description)
        table.insert(self.logs, "Awaiting your command...")
    else
        table.insert(self.logs, "[WARNING] No incident data received. Operating in standby mode.")
        self.incident = { id = "STANDBY", name = "Standby", description = "No active incident."}
    end
    
    -- Build UI
    self:buildUI()
end

function AdminModeLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Title
    local title = luis.newLabel("🚨 ADMIN MODE - INCIDENT RESPONSE", 40, 2, 2, centerCol - 20)
    luis.insertElement(self.layerName, title)
    
    -- Info
    local info = luis.newLabel("Terminal output displayed below", 40, 1, 4, centerCol - 20)
    luis.insertElement(self.layerName, info)
    
    -- Return button
    local returnButton = luis.newButton(
        "↩ Return to SOC View (ESC)",
        25, 3,
        function()
            if self.eventBus then
                self.eventBus:publish("scene_request", {scene = "soc_view"})
            end
        end,
        nil,
        centerRow + 15,
        centerCol - 12
    )
    luis.insertElement(self.layerName, returnButton)
    
    print("🚨 AdminModeLuis: UI built")
end

function AdminModeLuis:update(dt)
    -- Handle cursor blinking
    self.cursorBlinkTimer = self.cursorBlinkTimer + dt
    if self.cursorBlinkTimer > 0.5 then
        self.showCursor = not self.showCursor
        self.cursorBlinkTimer = 0
    end
end

function AdminModeLuis:draw()
    -- Draw terminal output manually (terminal-style dynamic content)
    love.graphics.setColor(0.2, 1, 0.2) -- Green text
    love.graphics.setFont(love.graphics.newFont(14))
    
    local y = 100
    -- Draw logs
    for _, line in ipairs(self.logs) do
        love.graphics.printf(line, 20, y, love.graphics.getWidth() - 40, "left")
        y = y + 20
    end
    
    -- Draw input line
    local inputPrompt = "> "
    love.graphics.print(inputPrompt .. self.inputBuffer, 20, y)
    
    -- Draw blinking cursor
    if self.showCursor then
        local cursorX = love.graphics.getFont():getWidth(inputPrompt .. self.inputBuffer)
        love.graphics.print(self.cursorChar, 20 + cursorX, y)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function AdminModeLuis:exit()
    print("🚨 Admin Mode Deactivated.")
    
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function AdminModeLuis:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("scene_request", {scene = "soc_view"})
    elseif key == "return" or key == "enter" then
        if #self.inputBuffer > 0 then
            table.insert(self.logs, "> " .. self.inputBuffer)
            table.insert(self.commandHistory, self.inputBuffer)
            -- Process command here
            table.insert(self.logs, "[SYSTEM] Command received: " .. self.inputBuffer)
            self.inputBuffer = ""
        end
    elseif key == "backspace" then
        self.inputBuffer = self.inputBuffer:sub(1, -2)
    end
end

function AdminModeLuis:textinput(text)
    self.inputBuffer = self.inputBuffer .. text
end

return AdminModeLuis
