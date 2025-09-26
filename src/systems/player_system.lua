-- Player System
-- Handles player position, movement, and interactions with office departments

local PlayerSystem = {}
PlayerSystem.__index = PlayerSystem

local defs = require("src.data.defs")

-- Create new player system
function PlayerSystem.new(eventBus, roomSystem)
    local self = setmetatable({}, PlayerSystem)
    self.eventBus = eventBus
    self.roomSystem = roomSystem  -- Reference to room system

    -- Player state
    self.x = 160
    self.y = 120
    self.speed = 120 -- pixels per second
    self.size = 12
    -- Movement smoothing
    self.vx = 0
    self.vy = 0
    self.accel = 700 -- pixels/sec^2
    self.friction = 450 -- pixels/sec^2 when no input (so we don't stop too abruptly)

    -- Player stats
    self.stats = {
        attack = 1,
        defense = 1,
        energy = 100
    }

    -- Office departments (now dynamically loaded from room system or defaults)
    self.departments = {}
    if self.roomSystem then
        self:updateDepartmentsFromRoom()
    else
        -- Fallback to old system for compatibility
        for _, d in ipairs(defs.Departments) do
            table.insert(self.departments, { id = d.id, name = d.name, x = d.x, y = d.y, radius = d.radius })
        end
    end

    -- Input state
    self.input = { up = false, down = false, left = false, right = false }

    -- Subscribe to room changes
    if self.eventBus and self.roomSystem then
        self.eventBus:subscribe("room_changed", function(data)
            self:onRoomChanged(data)
        end)
    end

    return self
end

function PlayerSystem:update(dt)
    -- Smooth movement using acceleration and friction
    -- Keep input table in sync with real-time keyboard state (handles missed events)
    self.input.up = love.keyboard.isDown('up','w')
    self.input.down = love.keyboard.isDown('down','s')
    self.input.left = love.keyboard.isDown('left','a')
    self.input.right = love.keyboard.isDown('right','d')

    local tx, ty = 0, 0
    if self.input.up then ty = ty - 1 end
    if self.input.down then ty = ty + 1 end
    if self.input.left then tx = tx - 1 end
    if self.input.right then tx = tx + 1 end

    local targetVx, targetVy = 0, 0
    if tx ~= 0 or ty ~= 0 then
        local len = math.sqrt(tx * tx + ty * ty)
        tx = tx / len
        ty = ty / len
        targetVx = tx * self.speed
        targetVy = ty * self.speed
    end

    -- Approach target velocity with acceleration
    local function approach(curr, target, maxDelta)
        if curr < target then
            return math.min(curr + maxDelta, target)
        elseif curr > target then
            return math.max(curr - maxDelta, target)
        end
        return curr
    end

    local accelDelta = self.accel * dt
    self.vx = approach(self.vx, targetVx, accelDelta)
    self.vy = approach(self.vy, targetVy, accelDelta)

    -- If no input, apply friction to slow down
    if tx == 0 and ty == 0 then
        local fricDelta = self.friction * dt
        self.vx = approach(self.vx, 0, fricDelta)
        self.vy = approach(self.vy, 0, fricDelta)
    end

    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Clamp to room bounds if room system is available
    if self.roomSystem then
        local currentRoom = self.roomSystem:getCurrentRoom()
        if currentRoom then
            local minX, minY = 20, 20
            local maxX = (currentRoom.width or 640) - 20
            local maxY = (currentRoom.height or 200) - 20
            if self.x < minX then self.x = minX end
            if self.y < minY then self.y = minY end
            if self.x > maxX then self.x = maxX end
            if self.y > maxY then self.y = maxY end
        end
    else
        -- Fallback to reasonable bounds to avoid leaving the office area
        local minX, minY, maxX, maxY = 0, 0, 2000, 2000
        if self.x < minX then self.x = minX end
        if self.y < minY then self.y = minY end
        if self.x > maxX then self.x = maxX end
        if self.y > maxY then self.y = maxY end
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
    -- Check for room exits first
    if self.roomSystem then
        local exit = self.roomSystem:checkExits(self.x, self.y, self.size)
        if exit then
            -- Use room transition
            self:changeRoom(exit.targetRoom, exit.targetX, exit.targetY)
            return true, exit
        end
    end
    
    -- Find nearest department within interaction radius
    for _, dept in ipairs(self.departments) do
        local dx = self.x - dept.x
        local dy = self.y - dept.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= dept.radius + self.size + 4 then
            -- Emit event based on department
            self.eventBus:publish("player_interact", { department = dept.id, name = dept.name })
            -- TODO: Implement department interaction feedback (e.g., flash, highlight, popup)
            -- Reference: See UI feedback standards in 10-ui-design.instructions.md for consistency

            return true, dept
        end
    end
    return false, nil
end

-- Update departments from current room
function PlayerSystem:updateDepartmentsFromRoom()
    if not self.roomSystem then return end
    
    self.departments = {}
    local currentDepts = self.roomSystem:getCurrentDepartments()
    for _, d in ipairs(currentDepts) do
        table.insert(self.departments, {
            id = d.id,
            name = d.name,
            x = d.x,
            y = d.y,
            radius = d.radius,
            proximity = d.proximity or 40
        })
    end
end

-- Handle room change
function PlayerSystem:onRoomChanged(data)
    -- Update player position to the target position
    if data.playerX and data.playerY then
        self.x = data.playerX
        self.y = data.playerY
        -- Reset velocity
        self.vx = 0
        self.vy = 0
    end
    
    -- Update departments for new room
    self:updateDepartmentsFromRoom()
end

-- Change room (called by interact when near an exit)
function PlayerSystem:changeRoom(targetRoom, targetX, targetY)
    if self.roomSystem then
        return self.roomSystem:changeRoom(targetRoom, targetX, targetY)
    end
    return false
end

-- Get current room exits for drawing
function PlayerSystem:getCurrentExits()
    if self.roomSystem then
        return self.roomSystem:getCurrentExits()
    end
    return {}
end

function PlayerSystem:getState()
    local roomId = nil
    if self.roomSystem then
        roomId = self.roomSystem.currentRoom
    end
    
    return {
        x = self.x,
        y = self.y,
        stats = self.stats,
        currentRoom = roomId
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
    if state.currentRoom and self.roomSystem then
        -- Restore room without triggering events during load
        self.roomSystem.currentRoom = state.currentRoom
        self:updateDepartmentsFromRoom()
    end
end

return PlayerSystem
