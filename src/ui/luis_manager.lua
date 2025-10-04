-- LUIS Integration Manager
-- Initializes and manages the LUIS (Love UI System) for the game
-- Provides a global LUIS instance and manages layer lifecycle

local LuisManager = {}
LuisManager.__index = LuisManager

-- Global LUIS instance (accessible game-wide)
local luis = nil

function LuisManager.new()
    local self = setmetatable({}, LuisManager)
    
    -- Require LUIS (require is overridden in main.lua to handle "luis.*" paths)
    local initLuis = require("luis.init")
    luis = initLuis("lib/luis/widgets")
    
    -- Debug: Check what widgets were loaded
    print("🎨 LUIS Widgets loaded:")
    for name, widget in pairs(luis.widgets or {}) do
        print("   - " .. name .. " -> newfunction: " .. tostring(luis["new" .. name:gsub("^%l", string.upper)]))
    end
    
    -- Register flux for animations (required by some LUIS widgets)
    luis.flux = require("luis.3rdparty.flux")
    
    -- Configure LUIS defaults
    luis.showGrid = false           -- Don't show debug grid by default
    luis.showLayerNames = false     -- Don't show layer names by default
    luis.showElementOutlines = false -- Don't show element outlines by default
    
    -- Create default main layer
    luis.newLayer("main")
    luis.setCurrentLayer("main")
    
    -- Store reference
    self.luis = luis
    self.time = 0
    
    print("🎨 LUIS Manager initialized with grid size: " .. luis.gridSize)
    
    return self
end

-- Get the global LUIS instance
function LuisManager:getLuis()
    return self.luis
end

-- Update LUIS (handles animations via flux)
function LuisManager:update(dt)
    -- Flux requires accumulated time, not delta
    self.time = self.time + dt
    if self.time >= 1/60 then
        self.luis.flux.update(self.time)
        self.time = 0
    end
    
    -- Update LUIS itself
    self.luis.update(dt)
end

-- Draw LUIS elements
function LuisManager:draw()
    self.luis.draw()
end

-- Mouse input handlers
function LuisManager:mousepressed(x, y, button, istouch)
    return self.luis.mousepressed(x, y, button, istouch)
end

function LuisManager:mousereleased(x, y, button, istouch)
    return self.luis.mousereleased(x, y, button, istouch)
end

function LuisManager:mousemoved(x, y, dx, dy, istouch)
    -- LUIS doesn't have mousemoved - it handles hover internally during update/draw
    -- Return false to let other systems handle mouse movement
    return false
end

function LuisManager:wheelmoved(x, y)
    return self.luis.wheelmoved(x, y)
end

-- Keyboard input handlers
function LuisManager:keypressed(key)
    -- Toggle debug view with Tab key
    if key == "tab" then
        self.luis.showGrid = not self.luis.showGrid
        self.luis.showLayerNames = not self.luis.showLayerNames
        self.luis.showElementOutlines = not self.luis.showElementOutlines
        return true
    end
    
    return self.luis.keypressed(key)
end

function LuisManager:keyreleased(key)
    return self.luis.keyreleased(key)
end

function LuisManager:textinput(text)
    return self.luis.textinput(text)
end

-- Touch input handlers (for mobile support)
function LuisManager:touchpressed(id, x, y, dx, dy, pressure)
    return self.luis.touchpressed(id, x, y, dx, dy, pressure)
end

function LuisManager:touchreleased(id, x, y, dx, dy, pressure)
    return self.luis.touchreleased(id, x, y, dx, dy, pressure)
end

function LuisManager:touchmoved(id, x, y, dx, dy, pressure)
    return self.luis.touchmoved(id, x, y, dx, dy, pressure)
end

-- Gamepad input handlers
function LuisManager:gamepadpressed(joystick, button)
    return self.luis.gamepadpressed(joystick, button)
end

function LuisManager:gamepadreleased(joystick, button)
    return self.luis.gamepadreleased(joystick, button)
end

function LuisManager:gamepadaxis(joystick, axis, value)
    return self.luis.gamepadaxis(joystick, axis, value)
end

-- Layer management helpers
function LuisManager:createLayer(name)
    self.luis.newLayer(name)
end

function LuisManager:setLayer(name)
    self.luis.setCurrentLayer(name)
end

function LuisManager:getLayer(name)
    return self.luis.layers[name]
end

function LuisManager:clearLayer(name)
    if self.luis.layers[name] then
        self.luis.layers[name].elements = {}
    end
end

-- Resize handler
function LuisManager:resize(w, h)
    -- LUIS automatically handles resize through love.graphics dimensions
    -- No manual intervention needed
end

-- Cleanup
function LuisManager:cleanup()
    -- Clear all layers
    for name, _ in pairs(self.luis.layers) do
        self:clearLayer(name)
    end
end

-- Helper to check if LUIS consumed input (useful for input routing)
function LuisManager:checkInputConsumed(x, y)
    -- LUIS doesn't expose this directly, but we can check if mouse is over any element
    -- This is a simplified version - LUIS handles this internally
    return false -- Let LUIS handle it via its own input methods
end

return LuisManager
