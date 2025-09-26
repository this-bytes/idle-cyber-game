-- Enhanced Player System
-- Handles player position, movement, and interactions across hierarchical locations (buildings/floors/rooms)

local EnhancedPlayerSystem = {}
EnhancedPlayerSystem.__index = EnhancedPlayerSystem

local defs = require("src.data.defs")

-- Create new enhanced player system
function EnhancedPlayerSystem.new(eventBus, locationSystem)
    local self = setmetatable({}, EnhancedPlayerSystem)
    self.eventBus = eventBus
    self.locationSystem = locationSystem
    
    -- Player state
    self.x = 160
    self.y = 120
    self.speed = 120 -- pixels per second
    self.size = 12
    
    -- Movement smoothing
    self.vx = 0
    self.vy = 0
    self.accel = 700 -- pixels/sec^2
    self.friction = 450 -- pixels/sec^2 when no input
    
    -- Input state
    self.input = { up = false, down = false, left = false, right = false }
    
    -- Player stats
    self.stats = {
        attack = 1,
        defense = 1,
        energy = 100,
        maxEnergy = 100,
        focus = 1.0,
        efficiency = 1.0
    }
    
    -- Location-based bonuses cache
    self.locationBonuses = {}
    
    -- Current room layout cache (departments and interactive objects)
    self.currentRoomLayout = {}
    
    -- Subscribe to location changes
    self:subscribeToEvents()
    
    -- Initialize room layout
    self:updateRoomLayout()
    
    return self
end

-- Subscribe to location and game events
function EnhancedPlayerSystem:subscribeToEvents()
    self.eventBus:subscribe("location_changed", function(data)
        self:onLocationChanged(data)
    end)
    
    self.eventBus:subscribe("player_interact", function(data)
        self:onPlayerInteract(data)
    end)
end

-- Handle location change events
function EnhancedPlayerSystem:onLocationChanged(data)
    print("🏠 Player location changed to: " .. data.newBuilding .. "/" .. data.newFloor .. "/" .. data.newRoom)
    
    -- Update location bonuses
    self.locationBonuses = data.bonuses or {}
    
    -- Update current room layout
    self:updateRoomLayout()
    
    -- Reset player position to room center
    local roomData = self.locationSystem:getCurrentLocationData()
    if roomData and roomData.room then
        self.x = roomData.room.x or 160
        self.y = roomData.room.y or 120
    end
    
    -- Apply location bonuses to player stats
    self:applyLocationBonuses()
end

-- Update room layout based on current location
function EnhancedPlayerSystem:updateRoomLayout()
    self.currentRoomLayout = {}
    
    -- Get current room data
    local locationData = self.locationSystem:getCurrentLocationData()
    if not locationData or not locationData.room then
        return
    end
    
    local room = locationData.room
    local departments = room.departments or {}
    
    -- Create department interaction points based on room layout
    for i, deptId in ipairs(departments) do
        -- Find department definition
        local deptDef = self:findDepartmentDefinition(deptId)
        if deptDef then
            -- Position departments within the room bounds
            local roomX = room.x or 160
            local roomY = room.y or 120
            local roomW = room.width or 100
            local roomH = room.height or 80
            
            -- Distribute departments in a grid within the room
            local cols = math.ceil(math.sqrt(#departments))
            local rows = math.ceil(#departments / cols)
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            
            local deptX = roomX + (roomW / (cols + 1)) * (col + 1)
            local deptY = roomY + (roomH / (rows + 1)) * (row + 1)
            
            table.insert(self.currentRoomLayout, {
                id = deptId,
                name = deptDef.name,
                x = deptX,
                y = deptY,
                radius = deptDef.radius or 28,
                proximity = 40,
                type = "department"
            })
        end
    end
    
    -- Add room connections (doors, elevators, stairs)
    local floor = locationData.floor
    if floor.connections then
        for connectionType, connectionData in pairs(floor.connections) do
            table.insert(self.currentRoomLayout, {
                id = connectionType,
                name = connectionType:gsub("_", " "):gsub("(%a)(%w*)", function(a,b) return a:upper()..b end),
                x = connectionData.x,
                y = connectionData.y,
                radius = 25,
                proximity = 35,
                type = "connection",
                leadsTo = connectionData.leads_to
            })
        end
    end
end

-- Find department definition from defs
function EnhancedPlayerSystem:findDepartmentDefinition(deptId)
    for _, dept in ipairs(defs.Departments) do
        if dept.id == deptId then
            return dept
        end
    end
    return nil
end

-- Apply location bonuses to player stats
function EnhancedPlayerSystem:applyLocationBonuses()
    -- Reset base stats
    self.stats.focus = 1.0
    self.stats.efficiency = 1.0
    
    -- Apply location bonuses
    for bonusType, multiplier in pairs(self.locationBonuses) do
        if bonusType == "focus" then
            self.stats.focus = self.stats.focus * multiplier
        elseif bonusType == "energy_regen" then
            self.stats.energyRegen = (self.stats.energyRegen or 1.0) * multiplier
        end
    end
    
    print("📊 Applied location bonuses - Focus: " .. string.format("%.2f", self.stats.focus))
end

-- Update player movement and interactions
function EnhancedPlayerSystem:update(dt)
    -- Handle input for movement
    local inputX, inputY = 0, 0
    if self.input.left then inputX = inputX - 1 end
    if self.input.right then inputX = inputX + 1 end
    if self.input.up then inputY = inputY - 1 end
    if self.input.down then inputY = inputY + 1 end
    
    -- Normalize diagonal movement
    if inputX ~= 0 and inputY ~= 0 then
        inputX = inputX * 0.707
        inputY = inputY * 0.707
    end
    
    -- Apply acceleration
    if inputX ~= 0 or inputY ~= 0 then
        self.vx = self.vx + inputX * self.accel * dt
        self.vy = self.vy + inputY * self.accel * dt
    else
        -- Apply friction
        self.vx = self.vx * (1 - self.friction * dt / self.speed)
        self.vy = self.vy * (1 - self.friction * dt / self.speed)
    end
    
    -- Cap velocity
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > self.speed then
        self.vx = self.vx / speed * self.speed
        self.vy = self.vy / speed * self.speed
    end
    
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Keep player within room bounds
    self:constrainToRoom()
    
    -- Update energy regeneration based on location bonuses
    if self.stats.energyRegen then
        self.stats.energy = math.min(self.stats.maxEnergy, 
            self.stats.energy + (10 * self.stats.energyRegen * dt))
    end
end

-- Constrain player movement to current room bounds
function EnhancedPlayerSystem:constrainToRoom()
    local locationData = self.locationSystem:getCurrentLocationData()
    if not locationData or not locationData.room then
        return
    end
    
    local room = locationData.room
    local roomX = room.x or 0
    local roomY = room.y or 0
    local roomW = room.width or 640
    local roomH = room.height or 480
    
    -- Keep player within room boundaries
    self.x = math.max(roomX + self.size, math.min(roomX + roomW - self.size, self.x))
    self.y = math.max(roomY + self.size, math.min(roomY + roomH - self.size, self.y))
end

-- Handle player interaction
function EnhancedPlayerSystem:interact()
    -- Find nearest interactive object within interaction radius
    for _, obj in ipairs(self.currentRoomLayout) do
        local dx = self.x - obj.x
        local dy = self.y - obj.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist <= obj.radius + self.size + 4 then
            if obj.type == "department" then
                -- Emit department interaction event
                self.eventBus:publish("player_interact", { 
                    department = obj.id, 
                    name = obj.name,
                    type = "department"
                })
                return true, obj
            elseif obj.type == "connection" then
                -- Handle room/floor transitions
                self:handleConnection(obj)
                return true, obj
            end
        end
    end
    
    return false, nil
end

-- Handle connection interactions (doors, elevators, stairs)
function EnhancedPlayerSystem:handleConnection(connection)
    if not connection.leadsTo then
        return
    end
    
    local currentLocation = self.locationSystem:getCurrentLocation()
    
    -- For now, simple floor navigation within same building
    if connection.id == "elevator" or connection.id == "stairs" then
        -- Move to the specified floor
        self.eventBus:publish("player_move_to_floor", {
            building = currentLocation.building,
            floor = connection.leadsTo
        })
    end
    
    print("🚪 Used " .. connection.name .. " to go to " .. connection.leadsTo)
end

-- Handle player interaction events
function EnhancedPlayerSystem:onPlayerInteract(data)
    if data.type == "department" then
        print("🤝 Interacted with department: " .. data.name .. " (Focus: " .. string.format("%.2f", self.stats.focus) .. ")")
        
        -- Dispatch department-specific events
        if data.department == "training" then
            self.eventBus:publish("training_accessed", { focus_bonus = self.stats.focus })
        elseif data.department == "research" then
            self.eventBus:publish("research_accessed", { focus_bonus = self.stats.focus })
        elseif data.department == "hr" then
            self.eventBus:publish("hr_accessed", { efficiency_bonus = self.stats.efficiency })
        elseif data.department == "contracts" then
            self.eventBus:publish("contracts_accessed", { location_bonuses = self.locationBonuses })
        end
    end
end

-- Movement input methods
function EnhancedPlayerSystem:setInput(key, isDown)
    if key == "up" or key == "w" then self.input.up = isDown end
    if key == "down" or key == "s" then self.input.down = isDown end
    if key == "left" or key == "a" then self.input.left = isDown end
    if key == "right" or key == "d" then self.input.right = isDown end
end

-- Get current player state
function EnhancedPlayerSystem:getState()
    return {
        x = self.x,
        y = self.y,
        vx = self.vx,
        vy = self.vy,
        stats = self.stats,
        location = self.locationSystem:getCurrentLocation(),
        locationBonuses = self.locationBonuses
    }
end

-- Get current room layout for rendering
function EnhancedPlayerSystem:getRoomLayout()
    return self.currentRoomLayout
end

-- Get location-aware departments for compatibility
function EnhancedPlayerSystem:getDepartments()
    local departments = {}
    for _, obj in ipairs(self.currentRoomLayout) do
        if obj.type == "department" then
            table.insert(departments, obj)
        end
    end
    return departments
end

return EnhancedPlayerSystem