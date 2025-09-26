-- Location Map UI Component
-- Renders hierarchical locations (buildings/floors/rooms) with navigation

local LocationMap = {}
LocationMap.__index = LocationMap

-- Create new location map
function LocationMap.new(width, height)
    local self = setmetatable({}, LocationMap)
    self.width = width or 640
    self.height = height or 480
    
    -- Rendering state
    self.scale = 1.0
    self.offsetX = 0
    self.offsetY = 0
    
    -- Cached sprites for performance
    self.playerSprite = nil
    self.roomSprites = {}
    self.connectionSprites = {}
    
    return self
end

-- Draw the location map
function LocationMap:draw(player, locationSystem, opts)
    opts = opts or {}
    
    -- Get current location data
    local locationData = locationSystem:getCurrentLocationData()
    if not locationData then
        self:drawError("No location data available")
        return
    end
    
    -- Draw background
    self:drawBackground(locationData, opts)
    
    -- Draw current room
    self:drawRoom(locationData.room, opts)
    
    -- Draw room layout (departments, connections)
    if player and player.getRoomLayout then
        local roomLayout = player:getRoomLayout()
        self:drawRoomLayout(roomLayout, opts)
    end
    
    -- Draw player
    if player then
        self:drawPlayer(player, opts)
    end
    
    -- Draw UI overlays
    self:drawLocationInfo(locationData, opts)
    
    if opts.debug then
        self:drawDebugInfo(locationData, player, opts)
    end
end

-- Draw background based on location type
function LocationMap:drawBackground(locationData, opts)
    local room = locationData.room
    local building = locationData.building
    
    -- Set background color based on building tier
    local bgColor = {0.1, 0.1, 0.12, 1}
    if building.tier == 1 then
        bgColor = {0.12, 0.1, 0.08, 1} -- Warm home office
    elseif building.tier == 2 then
        bgColor = {0.08, 0.1, 0.12, 1} -- Cool corporate
    end
    
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    
    -- Draw building outline/border
    love.graphics.setColor(0.3, 0.3, 0.35, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 10, 10, self.width - 20, self.height - 20, 8, 8)
end

-- Draw current room boundaries and features
function LocationMap:drawRoom(room, opts)
    if not room then return end
    
    local roomX = room.x or 50
    local roomY = room.y or 50
    local roomW = room.width or 200
    local roomH = room.height or 150
    
    -- Draw room floor
    love.graphics.setColor(0.2, 0.2, 0.22, 1)
    love.graphics.rectangle("fill", roomX, roomY, roomW, roomH, 6, 6)
    
    -- Draw room walls
    love.graphics.setColor(0.4, 0.4, 0.45, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", roomX, roomY, roomW, roomH, 6, 6)
    
    -- Draw room atmosphere indicator (corner decoration)
    local atmosphere = room.atmosphere or ""
    if atmosphere ~= "" then
        love.graphics.setColor(0.6, 0.6, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf(atmosphere, roomX + 5, roomY + roomH - 15, roomW - 10, "left")
    end
end

-- Draw room layout elements (departments, connections)
function LocationMap:drawRoomLayout(roomLayout, opts)
    for _, obj in ipairs(roomLayout) do
        if obj.type == "department" then
            self:drawDepartment(obj, opts)
        elseif obj.type == "connection" then
            self:drawConnection(obj, opts)
        end
    end
end

-- Draw a department interaction point
function LocationMap:drawDepartment(dept, opts)
    -- Create or get cached sprite
    if not self.roomSprites[dept.id] then
        self.roomSprites[dept.id] = self:createDepartmentSprite(dept)
    end
    
    -- Draw department base
    love.graphics.setColor(0.15, 0.4, 0.6, 0.8)
    love.graphics.circle("fill", dept.x, dept.y, dept.radius)
    
    -- Draw department border
    love.graphics.setColor(0.3, 0.6, 0.9, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", dept.x, dept.y, dept.radius)
    
    -- Draw department icon/label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    local textW = love.graphics.getFont():getWidth(dept.name)
    love.graphics.print(dept.name, dept.x - textW/2, dept.y - 6)
    
    -- Draw proximity range in debug mode
    if opts.debug then
        love.graphics.setColor(0.3, 0.6, 0.9, 0.2)
        love.graphics.circle("fill", dept.x, dept.y, dept.radius + dept.proximity)
    end
end

-- Draw a connection point (door, elevator, stairs)
function LocationMap:drawConnection(conn, opts)
    local iconColor = {0.8, 0.6, 0.2, 1}
    local iconSize = conn.radius or 25
    
    if conn.id == "elevator" then
        iconColor = {0.6, 0.8, 0.3, 1}
    elseif conn.id == "stairs" then
        iconColor = {0.5, 0.5, 0.8, 1}
    end
    
    -- Draw connection base
    love.graphics.setColor(iconColor[1], iconColor[2], iconColor[3], 0.6)
    love.graphics.rectangle("fill", conn.x - iconSize/2, conn.y - iconSize/2, iconSize, iconSize, 4, 4)
    
    -- Draw connection border
    love.graphics.setColor(iconColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", conn.x - iconSize/2, conn.y - iconSize/2, iconSize, iconSize, 4, 4)
    
    -- Draw connection label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    local textW = love.graphics.getFont():getWidth(conn.name)
    love.graphics.print(conn.name, conn.x - textW/2, conn.y + iconSize/2 + 5)
    
    if conn.leadsTo then
        love.graphics.setFont(love.graphics.newFont(8))
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local leadText = "→ " .. conn.leadsTo
        local leadW = love.graphics.getFont():getWidth(leadText)
        love.graphics.print(leadText, conn.x - leadW/2, conn.y + iconSize/2 + 18)
    end
end

-- Draw the player
function LocationMap:drawPlayer(player, opts)
    local state = player:getState()
    local x, y = state.x, state.y
    
    -- Create player sprite if needed
    if not self.playerSprite then
        self.playerSprite = self:createPlayerSprite()
    end
    
    -- Draw player shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", x + 2, y + 3, player.size + 2)
    
    -- Draw player
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.circle("fill", x, y, player.size)
    
    -- Draw player border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, player.size)
    
    -- Draw direction indicator
    if state.vx ~= 0 or state.vy ~= 0 then
        local angle = math.atan2(state.vy, state.vx)
        local dirX = x + math.cos(angle) * (player.size + 5)
        local dirY = y + math.sin(angle) * (player.size + 5)
        
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.circle("fill", dirX, dirY, 3)
    end
end

-- Draw location information overlay
function LocationMap:drawLocationInfo(locationData, opts)
    local building = locationData.building
    local floor = locationData.floor
    local room = locationData.room
    
    -- Draw location breadcrumb
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, self.width - 20, 60, 6, 6)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    
    local breadcrumb = building.name .. " → " .. floor.name .. " → " .. room.name
    love.graphics.print(breadcrumb, 20, 20)
    
    -- Draw room description
    if room.description then
        love.graphics.setFont(love.graphics.newFont(11))
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.print(room.description, 20, 40)
    end
    
    -- Draw location bonuses
    if room.bonuses then
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(0.8, 0.9, 0.6, 1)
        local bonusText = "Bonuses: "
        local bonusList = {}
        for bonus, value in pairs(room.bonuses) do
            table.insert(bonusList, bonus .. " +" .. string.format("%.0f%%", (value - 1) * 100))
        end
        bonusText = bonusText .. table.concat(bonusList, ", ")
        love.graphics.print(bonusText, 20, self.height - 25)
    end
end

-- Draw debug information
function LocationMap:drawDebugInfo(locationData, player, opts)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setFont(love.graphics.newFont(10))
    
    local debugLines = {
        "DEBUG MODE",
        "Player: (" .. string.format("%.1f", player:getState().x) .. ", " .. string.format("%.1f", player:getState().y) .. ")",
        "Speed: " .. string.format("%.1f", math.sqrt(player:getState().vx^2 + player:getState().vy^2)),
        "Room: " .. locationData.room.name,
        "Departments: " .. #(locationData.room.departments or {})
    }
    
    for i, line in ipairs(debugLines) do
        love.graphics.print(line, self.width - 200, 20 + (i-1) * 15)
    end
end

-- Draw error message
function LocationMap:drawError(message)
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local textW = love.graphics.getFont():getWidth(message)
    love.graphics.print(message, self.width/2 - textW/2, self.height/2)
end

-- Helper methods for sprite creation
function LocationMap:createDepartmentSprite(dept)
    -- In a full implementation, this would create proper sprites
    -- For now, just return a placeholder
    return { type = "department", id = dept.id }
end

function LocationMap:createPlayerSprite()
    -- In a full implementation, this would create a proper player sprite
    return { type = "player" }
end

-- Handle mouse clicks for navigation
function LocationMap:mousepressed(x, y, button, locationSystem, player)
    if button ~= 1 then return false end
    
    -- Check if clicking on connections for navigation
    if player and player.getRoomLayout then
        local roomLayout = player:getRoomLayout()
        for _, obj in ipairs(roomLayout) do
            if obj.type == "connection" then
                local dx = x - obj.x
                local dy = y - obj.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist <= (obj.radius or 25) then
                    -- Trigger connection interaction
                    player:handleConnection(obj)
                    return true
                end
            end
        end
    end
    
    return false
end

return LocationMap