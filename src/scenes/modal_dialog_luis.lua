--[[
    Modal Dialog Scene
    ------------------
    A generic, reusable modal dialog that is pushed onto the scene stack.
]]

local ModalDialog = {}
ModalDialog.__index = ModalDialog

function ModalDialog.new(eventBus, luis, sceneManager)
    local self = setmetatable({}, ModalDialog)
    self.eventBus = eventBus
    self.luis = luis
    self.sceneManager = sceneManager
    self.layerName = "modal_dialog"
    
    -- UI element references
    self.titleLabel = nil
    self.messageLabel = nil

    local cyberpunkTheme = {
        textColor = {0, 1, 180/255, 1},                      
        bgColor = {10/255, 25/255, 20/255, 0.95},            
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

    return self
end

function ModalDialog:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Build the UI structure first.
    self:buildUI()

    -- Then, populate it with data. This prevents a race condition where
    -- the modal could draw with empty text.
    if self.titleLabel then
        self.titleLabel:setText(data.title or "ALERT")
    end
    if self.messageLabel then
        self.messageLabel:setText(data.message or "")
    end
end

function ModalDialog:exit()
    self.luis.disableLayer(self.layerName)
end

function ModalDialog:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)

    local modalWidth = 40
    local modalHeight = 15
    local modalCol = math.floor((numCols - modalWidth) / 2)
    local modalRow = math.floor((numRows - modalHeight) / 2)

    local bg = luis.newButton("", modalWidth, modalHeight, nil, nil, modalRow, modalCol)
    bg.focusable = false
    bg.onClick = nil
    luis.insertElement(self.layerName, bg)

    -- Create labels with empty text and store references to them.
    self.titleLabel = luis.newLabel("", modalWidth, 2, modalRow + 1, modalCol, "center")
    luis.insertElement(self.layerName, self.titleLabel)

    self.messageLabel = luis.newLabel("", modalWidth - 4, 6, modalRow + 4, modalCol + 2, "center")
    luis.insertElement(self.layerName, self.messageLabel)

    local okButton = luis.newButton("OK", 12, 3, function() 
        self.sceneManager:popScene()
    end, nil, modalRow + modalHeight - 4, modalCol + (modalWidth/2) - 6)
    luis.insertElement(self.layerName, okButton)
end

function ModalDialog:draw()
end

function ModalDialog:update(dt) end

function ModalDialog:keypressed(key)
    if key == "escape" or key == "return" or key == "kpenter" then
        self.sceneManager:popScene()
        return true
    end
end

return ModalDialog