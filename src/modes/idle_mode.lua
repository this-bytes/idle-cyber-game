-- Idle Mode
-- Main game mode for empire building progression

local IdleMode = {}
IdleMode.__index = IdleMode

-- Create new idle mode
function IdleMode.new(systems)
    local self = setmetatable({}, IdleMode)
    self.systems = systems
    
    return self
end

function IdleMode:update(dt)
    -- Handle idle mode specific updates
end

function IdleMode:draw()
    -- Draw idle mode UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("🏠 IDLE MODE - Cyberspace Tycoon", 20, 20)
    
    -- Draw resources
    local resources = self.systems.resources:getAllResources()
    local y = 60
    for name, value in pairs(resources) do
        local displayValue = string.format("%.2f", value)
        love.graphics.print(name .. ": " .. displayValue, 20, y)
        y = y + 20
    end
    
    -- Draw current zone
    local currentZone = self.systems.zones:getCurrentZone()
    if currentZone then
        love.graphics.print("📍 Zone: " .. currentZone.name, 20, y + 20)
    end
    
    -- Instructions
    love.graphics.print("Click anywhere to earn Data Bits!", 20, love.graphics.getHeight() - 40)
end

function IdleMode:mousepressed(x, y, button)
    -- Handle clicking for resources
    if button == 1 then -- Left click
        local result = self.systems.resources:click()
        print("💎 Earned " .. string.format("%.2f", result.reward) .. " Data Bits" .. 
              (result.critical and " (CRITICAL!)" or "") ..
              " (combo: " .. string.format("%.1fx", result.combo) .. ")")
        return true
    end
    return false
end

function IdleMode:keypressed(key)
    -- Handle idle mode specific keys
    if key == "u" then
        print("📦 Shop system not implemented yet")
    elseif key == "z" then
        print("🗺️ Zone system loaded")
    elseif key == "h" then
        print("🏆 Achievement system not implemented yet")
    end
end

return IdleMode