-- Admin Mode - "The Admin's Watch"
-- Real-time operations mode for advanced gameplay

local AdminMode = {}
AdminMode.__index = AdminMode

-- Create new admin mode
function AdminMode.new(systems)
    local self = setmetatable({}, AdminMode)
    self.systems = systems
    
    -- Admin mode specific state
    self.corporateClient = {
        name = "TechCorp Industries",
        sector = "Technology",
        uptime = 99.9,
        budget = 50000
    }
    
    self.operationalResources = {
        cpuCycles = 100,
        bandwidth = 1000,
        personnelHours = 40,
        emergencyFunds = 10000
    }
    
    return self
end

function AdminMode:update(dt)
    -- Handle admin mode specific updates
end

function AdminMode:draw()
    -- Draw admin mode UI
    love.graphics.setColor(0.1, 0.8, 0.1) -- Green text for "hacker" feel
    love.graphics.print("👨‍💻 THE ADMIN'S WATCH - Real-Time Operations", 20, 20)
    
    love.graphics.setColor(1, 1, 1)
    
    -- Client information
    love.graphics.print("🏢 Client: " .. self.corporateClient.name, 20, 60)
    love.graphics.print("📊 Uptime: " .. self.corporateClient.uptime .. "%", 20, 80)
    love.graphics.print("💰 Budget: $" .. self.corporateClient.budget, 20, 100)
    
    -- Operational resources
    local y = 140
    love.graphics.print("🔧 OPERATIONAL RESOURCES:", 20, y)
    y = y + 30
    for resource, value in pairs(self.operationalResources) do
        love.graphics.print("  " .. resource .. ": " .. value, 30, y)
        y = y + 20
    end
    
    -- Network status
    y = y + 20
    love.graphics.print("🌐 NETWORK STATUS:", 20, y)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print("  All systems operational", 30, y + 25)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Press 'A' to return to Idle Mode", 20, love.graphics.getHeight() - 40)
end

function AdminMode:mousepressed(x, y, button)
    -- Handle admin mode clicking
    return false
end

function AdminMode:keypressed(key)
    -- Handle admin mode specific keys
    if key == "1" or key == "2" or key == "3" then
        print("🚨 Incident response " .. key .. " activated")
    end
end

return AdminMode