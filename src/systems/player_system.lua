-- Player System
-- Handles player position, movement, and interactions with office departments

local PlayerSystem = {}
PlayerSystem.__index = PlayerSystem

-- Create new player system
function PlayerSystem.new(eventBus)
    local self = setmetatable({}, PlayerSystem)
    self.eventBus = eventBus

    -- Player state
    self.x = 160
    self.y = 120
    self.speed = 120 -- pixels per second
    self.size = 12

    -- Player stats
    self.stats = {
        attack = 1,
        defense = 1,
        energy = 100
    }

    -- Office departments (simple positions)
    self.departments = {
        { id = "desk", name = "My Desk", x = 160, y = 120, radius = 18 },
        { id = "contracts", name = "Contracts", x = 80, y = 60, radius = 28 },
        { id = "research", name = "Research", x = 300, y = 60, radius = 28 },
        { id = "ops", name = "Operations", x = 520, y = 60, radius = 28 },
        { id = "hr", name = "HR", x = 80, y = 260, radius = 28 },
        { id = "training", name = "Training", x = 300, y = 260, radius = 28 },
        { id = "security", name = "Security", x = 520, y = 260, radius = 28 },
    }

    -- Input state
    self.input = { up = false, down = false, left = false, right = false }

    return self
end

function PlayerSystem:update(dt)
    -- Basic movement using input state
    local dx, dy = 0, 0
    if self.input.up then dy = dy - 1 end
    if self.input.down then dy = dy + 1 end
    if self.input.left then dx = dx - 1 end
    if self.input.right then dx = dx + 1 end

    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    end
end

function PlayerSystem:draw(theme)
    -- Draw departments
    for _, dept in ipairs(self.departments) do
        love.graphics.setColor(0.12, 0.12, 0.16, 1)
        love.graphics.circle("fill", dept.x, dept.y, dept.radius)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(dept.name, dept.x - dept.radius, dept.y - 6, dept.radius * 2, "center")
    end

    -- Draw player
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

function PlayerSystem:setInput(key, isDown)
    if key == "up" or key == "w" then self.input.up = isDown end
    if key == "down" or key == "s" then self.input.down = isDown end
    if key == "left" or key == "a" then self.input.left = isDown end
    if key == "right" or key == "d" then self.input.right = isDown end
end

function PlayerSystem:interact()
    -- Find nearest department within interaction radius
    for _, dept in ipairs(self.departments) do
        local dx = self.x - dept.x
        local dy = self.y - dept.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= dept.radius + self.size + 4 then
            -- Emit event based on department
            self.eventBus:publish("player_interact", { department = dept.id, name = dept.name })
            return true, dept
        end
    end
    return false, nil
end

function PlayerSystem:getState()
    return {
        x = self.x,
        y = self.y,
        stats = self.stats
    }
end

-- Load state from save
function PlayerSystem:loadState(state)
    if not state then return end
    if state.x and state.y then
        self.x = state.x
        self.y = state.y
    end
    if state.stats then
        for k, v in pairs(state.stats) do
            self.stats[k] = v
        end
    end
end

return PlayerSystem
