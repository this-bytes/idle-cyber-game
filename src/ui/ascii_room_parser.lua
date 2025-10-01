-- Not implemented: src/ui/ascii_room_parser.lua
-- ======================================================================
-- But the idea is decent so keeping around for future exploration.
-- ======================================================================

-- ASCII Room Parser - Dynamic Room Generation from locations.json
-- Creates ASCII art representations of rooms, floors, and buildings
-- Supports interactive navigation and visual room layouts

local ASCIIRoomParser = {}
ASCIIRoomParser.__index = ASCIIRoomParser

-- Box drawing characters for different styles
local BOX_CHARS = {
    single = {
        horizontal = "─",
        vertical = "│", 
        topLeft = "┌",
        topRight = "┐",
        bottomLeft = "└",
        bottomRight = "┘",
        cross = "┼",
        teeUp = "┴",
        teeDown = "┬",
        teeLeft = "┤",
        teeRight = "├"
    },
    double = {
        horizontal = "═",
        vertical = "║",
        topLeft = "╔",
        topRight = "╗", 
        bottomLeft = "╚",
        bottomRight = "╝",
        cross = "╬",
        teeUp = "╩",
        teeDown = "╦",
        teeLeft = "╣",
        teeRight = "╠"
    },
    thick = {
        horizontal = "━",
        vertical = "┃",
        topLeft = "┏",
        topRight = "┓",
        bottomLeft = "┗",
        bottomRight = "┛",
        cross = "╋",
        teeUp = "┻",
        teeDown = "┳",
        teeLeft = "┫",
        teeRight = "┣"
    }
}

-- Department icons for visual identification
local DEPT_ICONS = {
    desk = "🖥️",
    contracts = "📋",
    security = "🛡️",
    ops = "⚙️",
    hr = "👥",
    training = "📚",
    research = "🔬",
    server = "💾",
    kitchen = "☕",
    meeting = "🏢"
}

-- Bonus type icons
local BONUS_ICONS = {
    focus = "🎯",
    energy_regen = "⚡",
    reputation = "⭐",
    threat_defense = "🛡️",
    processing_power = "💻",
    contract_success = "✅",
    team_morale = "😊",
    specialist_efficiency = "👔",
    skill_gain = "📈",
    xp_multiplier = "🚀",
    research_speed = "🔬",
    innovation_rate = "💡",
    data_capacity = "💾"
}

function ASCIIRoomParser.new()
    local self = setmetatable({}, ASCIIRoomParser)
    self.boxStyle = "single"
    self.showBonuses = true
    self.showDepartments = true
    self.compactMode = false
    return self
end

-- Generate ASCII art for a single room
function ASCIIRoomParser:generateRoom(room, options)
    options = options or {}
    local style = BOX_CHARS[options.style or self.boxStyle]
    local width = options.width or math.max(20, math.min(50, room.width and math.floor(room.width / 8) or 25))
    local height = options.height or math.max(5, math.min(12, room.height and math.floor(room.height / 15) or 8))
    
    local lines = {}
    
    -- Top border
    local topLine = style.topLeft .. string.rep(style.horizontal, width - 2) .. style.topRight
    table.insert(lines, topLine)
    
    -- Room content
    local contentLines = height - 2
    for i = 1, contentLines do
        local line = style.vertical
        local content = ""
        
        if i == 1 then
            -- Room name with proper centering
            local name = room.name or "Unnamed Room"
            if #name > width - 4 then
                name = name:sub(1, width - 7) .. "..."
            end
            local padding = width - 2 - #name
            local leftPad = math.floor(padding / 2)
            local rightPad = padding - leftPad
            content = string.rep(" ", leftPad) .. name .. string.rep(" ", rightPad)
            
        elseif i == 2 and self.showDepartments and room.departments and #room.departments > 0 then
            -- Department indicators
            local deptString = ""
            for _, dept in ipairs(room.departments) do
                local icon = DEPT_ICONS[dept] or "📁"
                deptString = deptString .. icon
            end
            
            if #deptString > 0 then
                local padding = width - 2 - #deptString
                local leftPad = math.floor(padding / 2)
                local rightPad = padding - leftPad
                content = string.rep(" ", leftPad) .. deptString .. string.rep(" ", rightPad)
            else
                content = string.rep(" ", width - 2)
            end
            
        elseif i == 3 and room.description and not self.compactMode then
            -- Room description (truncated)
            local desc = room.description
            if #desc > width - 4 then
                desc = desc:sub(1, width - 7) .. "..."
            end
            local padding = width - 2 - #desc
            local leftPad = math.floor(padding / 2)
            local rightPad = padding - leftPad
            content = string.rep(" ", leftPad) .. desc .. string.rep(" ", rightPad)
            
        elseif i == contentLines - 1 and self.showBonuses and room.bonuses then
            -- Bonus indicators
            local bonusString = ""
            local bonusCount = 0
            for bonusType, _ in pairs(room.bonuses) do
                if bonusCount < 3 then -- Limit to prevent overflow
                    local icon = BONUS_ICONS[bonusType] or "+"
                    bonusString = bonusString .. icon
                    bonusCount = bonusCount + 1
                end
            end
            
            if #bonusString > 0 then
                local padding = width - 2 - #bonusString
                local leftPad = math.floor(padding / 2)
                local rightPad = padding - leftPad
                content = string.rep(" ", leftPad) .. bonusString .. string.rep(" ", rightPad)  
            else
                content = string.rep(" ", width - 2)
            end
            
        elseif i == contentLines and room.atmosphere and not self.compactMode then
            -- Atmosphere on last line
            local atm = "\"" .. (room.atmosphere or "") .. "\""
            if #atm > width - 4 then
                atm = atm:sub(1, width - 7) .. "...\""
            end
            local padding = width - 2 - #atm
            local leftPad = math.floor(padding / 2)
            local rightPad = padding - leftPad
            content = string.rep(" ", leftPad) .. atm .. string.rep(" ", rightPad)
            
        else
            -- Empty line
            content = string.rep(" ", width - 2)
        end
        
        line = line .. content .. style.vertical
        table.insert(lines, line)
    end
    
    -- Bottom border
    local bottomLine = style.bottomLeft .. string.rep(style.horizontal, width - 2) .. style.bottomRight
    table.insert(lines, bottomLine)
    
    return lines
end

-- Generate ASCII floor plan with multiple rooms
function ASCIIRoomParser:generateFloor(floor, building, options)
    options = options or {}
    local rooms = floor.rooms or {}
    local connections = floor.connections or {}
    
    -- Calculate floor dimensions based on room positions
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, room in pairs(rooms) do
        local x, y = room.x or 0, room.y or 0
        local w, h = room.width or 100, room.height or 80
        minX = math.min(minX, x)
        minY = math.min(minY, y)
        maxX = math.max(maxX, x + w)
        maxY = math.max(maxY, y + h)
    end
    
    -- Scale to ASCII dimensions
    local scaleX = (options.width or 80) / math.max(1, maxX - minX)
    local scaleY = (options.height or 25) / math.max(1, maxY - minY)
    local scale = math.min(scaleX, scaleY, 1.0)
    
    local floorWidth = math.floor((maxX - minX) * scale) + 4
    local floorHeight = math.floor((maxY - minY) * scale) + 4
    
    -- Initialize floor grid
    local grid = {}
    for y = 1, floorHeight do
        grid[y] = {}
        for x = 1, floorWidth do
            grid[y][x] = " "
        end
    end
    
    -- Draw rooms on grid
    for roomId, room in pairs(rooms) do
        local roomX = math.floor((room.x - minX) * scale) + 2
        local roomY = math.floor((room.y - minY) * scale) + 2
        local roomW = math.max(3, math.floor(room.width * scale))
        local roomH = math.max(2, math.floor(room.height * scale))
        
        -- Draw room outline
        local style = BOX_CHARS[self.boxStyle]
        
        -- Top and bottom borders
        for x = roomX, roomX + roomW - 1 do
            if x <= floorWidth then
                grid[roomY][x] = style.horizontal
                if roomY + roomH - 1 <= floorHeight then
                    grid[roomY + roomH - 1][x] = style.horizontal
                end
            end
        end
        
        -- Left and right borders
        for y = roomY, roomY + roomH - 1 do
            if y <= floorHeight then
                grid[y][roomX] = style.vertical
                if roomX + roomW - 1 <= floorWidth then
                    grid[y][roomX + roomW - 1] = style.vertical
                end
            end
        end
        
        -- Corners
        if roomY <= floorHeight and roomX <= floorWidth then
            grid[roomY][roomX] = style.topLeft
        end
        if roomY <= floorHeight and roomX + roomW - 1 <= floorWidth then  
            grid[roomY][roomX + roomW - 1] = style.topRight
        end
        if roomY + roomH - 1 <= floorHeight and roomX <= floorWidth then
            grid[roomY + roomH - 1][roomX] = style.bottomLeft  
        end
        if roomY + roomH - 1 <= floorHeight and roomX + roomW - 1 <= floorWidth then
            grid[roomY + roomH - 1][roomX + roomW - 1] = style.bottomRight
        end
        
        -- Room label
        local nameY = roomY + math.floor(roomH / 2)
        if nameY <= floorHeight then
            local name = room.name or roomId
            if #name > roomW - 2 then
                name = name:sub(1, roomW - 5) .. "..."
            end
            
            local startX = roomX + math.floor((roomW - #name) / 2)
            for i = 1, #name do
                local x = startX + i - 1
                if x > roomX and x < roomX + roomW - 1 and x <= floorWidth then
                    grid[nameY][x] = name:sub(i, i)
                end
            end
        end
    end
    
    -- Draw connections (elevators, stairs, etc.)
    for connId, conn in pairs(connections) do
        local connX = math.floor((conn.x - minX) * scale) + 2
        local connY = math.floor((conn.y - minY) * scale) + 2
        
        if connY <= floorHeight and connX <= floorWidth then
            local icon = "⬆"
            if connId:find("elevator") then
                icon = "🛗"
            elseif connId:find("stair") then
                icon = "🪜"
            end
            grid[connY][connX] = icon
        end
    end
    
    -- Convert grid to strings
    local lines = {}
    for y = 1, floorHeight do
        local line = ""
        for x = 1, floorWidth do
            line = line .. grid[y][x]
        end
        table.insert(lines, line)
    end
    
    -- Add floor header
    local headerStyle = BOX_CHARS.double
    local header = headerStyle.topLeft .. " " .. (floor.name or "Floor") .. " " .. headerStyle.topRight
    table.insert(lines, 1, header)
    
    return lines
end

-- Generate building overview with all floors
function ASCIIRoomParser:generateBuilding(building, options)
    options = options or {}
    local lines = {}
    
    -- Building header
    local headerStyle = BOX_CHARS.thick
    local buildingName = building.name or "Building"
    local header = headerStyle.topLeft .. " " .. buildingName .. " " .. headerStyle.topRight
    table.insert(lines, header)
    
    -- Building description
    if building.description then
        table.insert(lines, "  " .. building.description)
        table.insert(lines, "")
    end
    
    -- Floor listings
    if building.floors then
        for floorId, floor in pairs(building.floors) do
            table.insert(lines, "📋 Floor: " .. (floor.name or floorId))
            
            -- Room count and types
            local roomCount = 0
            local deptTypes = {}
            if floor.rooms then
                for _, room in pairs(floor.rooms) do
                    roomCount = roomCount + 1
                    if room.departments then
                        for _, dept in ipairs(room.departments) do
                            deptTypes[dept] = true
                        end
                    end
                end
            end
            
            table.insert(lines, "  Rooms: " .. roomCount)
            
            -- Department summary
            local deptList = {}
            for dept, _ in pairs(deptTypes) do
                local icon = DEPT_ICONS[dept] or "📁"
                table.insert(deptList, icon .. dept)
            end
            
            if #deptList > 0 then
                table.insert(lines, "  Departments: " .. table.concat(deptList, ", "))
            end
            
            table.insert(lines, "")
        end
    end
    
    -- Building requirements
    if building.unlockRequirements then
        table.insert(lines, "🔓 Unlock Requirements:")
        for req, value in pairs(building.unlockRequirements) do
            table.insert(lines, "  • " .. req .. ": " .. tostring(value))
        end
    end
    
    return lines
end

-- Parse locations.json and generate all ASCII representations  
function ASCIIRoomParser:parseLocationsData(locationsData)
    local result = {
        buildings = {},
        rooms = {},
        floors = {}
    }
    
    if locationsData.buildings then
        for buildingId, building in pairs(locationsData.buildings) do
            -- Generate building overview
            result.buildings[buildingId] = self:generateBuilding(building)
            
            -- Generate floors
            if building.floors then
                result.floors[buildingId] = {}
                for floorId, floor in pairs(building.floors) do
                    result.floors[buildingId][floorId] = self:generateFloor(floor, building)
                    
                    -- Generate individual rooms
                    if floor.rooms then
                        result.rooms[buildingId] = result.rooms[buildingId] or {}
                        result.rooms[buildingId][floorId] = {}
                        for roomId, room in pairs(floor.rooms) do
                            result.rooms[buildingId][floorId][roomId] = self:generateRoom(room)
                        end
                    end
                end
            end
        end
    end
    
    return result
end

-- Helper to get ASCII for specific location
function ASCIIRoomParser:getLocationASCII(locationsData, buildingId, floorId, roomId)
    local asciiData = self:parseLocationsData(locationsData)
    
    if roomId and asciiData.rooms[buildingId] and asciiData.rooms[buildingId][floorId] then
        return asciiData.rooms[buildingId][floorId][roomId]
    elseif floorId and asciiData.floors[buildingId] then
        return asciiData.floors[buildingId][floorId]  
    elseif buildingId and asciiData.buildings[buildingId] then
        return asciiData.buildings[buildingId]
    end
    
    return {"No ASCII data available for this location"}
end

-- Set rendering options
function ASCIIRoomParser:setOptions(options)
    self.boxStyle = options.style or self.boxStyle
    self.showBonuses = options.showBonuses ~= nil and options.showBonuses or self.showBonuses
    self.showDepartments = options.showDepartments ~= nil and options.showDepartments or self.showDepartments
    self.compactMode = options.compactMode ~= nil and options.compactMode or self.compactMode
end

return ASCIIRoomParser