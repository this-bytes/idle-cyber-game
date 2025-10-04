--[[
    Base Scene for LUIS (Love UI System)
    ------------------------------------
    This file provides a reusable "base class" for all scenes that use the LUIS UI.
    It handles the common boilerplate for LUIS integration, such as layer management,
    and provides hooks for subclasses to add their specific content.
]]

local BaseSceneLuis = {}
BaseSceneLuis.__index = BaseSceneLuis

function BaseSceneLuis.new(eventBus, luis, layerName)
    local self = setmetatable({}, BaseSceneLuis)
    
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = layerName or "luis_scene_" .. tostring(math.random(1, 10000))

    return self
end

--[[
    setTheme(themeTable)
    --------------------
    Sets the active LUIS theme for the UI. This function should be called
    in the constructor of a child scene.
    
    *** CORRECTED IMPLEMENTATION ***
    Based on the documentation and error logs, this function now correctly
    passes a theme TABLE directly to the LUIS `setTheme` function.
--]]
function BaseSceneLuis:setTheme(themeTable)
    if self.luis.setTheme then
        if type(themeTable) == "table" then
            print("🎨 Applying LUIS theme from theme table.")
            self.luis.setTheme(themeTable)
        else
            print(string.format("WARNING: setTheme requires a table. Got %s instead.", type(themeTable)))
        end
    else
        print("WARNING: luis.setTheme() function does not exist. UI will use default theme.")
    end
end

--[[
    Core Scene Lifecycle - Managed by the Base Class
--]]

function BaseSceneLuis:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:onLoad(data)
    self:buildUI()
end

function BaseSceneLuis:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
    self:onExit()
end

function BaseSceneLuis:update(dt)
    self:onUpdate(dt)
end

function BaseSceneLuis:draw()
    self:onDraw()
end

--[[
    Hooks for Subclasses
--]]

function BaseSceneLuis:onLoad(data) end
function BaseSceneLuis:onExit() end
function BaseSceneLuis:buildUI() 
    print("WARNING: BaseSceneLuis:buildUI() was called. The child scene should implement this.")
end
function BaseSceneLuis:onUpdate(dt) end
function BaseSceneLuis:onDraw() end

--[[
    Global Input Handlers
--]]
function BaseSceneLuis:keypressed(key, scancode, isrepeat) end
function BaseSceneLuis:mousepressed(x, y, button, istouch, presses) end

return BaseSceneLuis
