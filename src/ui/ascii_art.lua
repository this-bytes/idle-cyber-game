-- Dynamic ASCII Art System for Cyber Empire Command
-- Data-driven terminal art that scales with window size

local json = require("dkjson")

local AsciiArt = {}

-- Character cell size for grid calculations (Love2D font metrics)
local CHAR_WIDTH = 8
local CHAR_HEIGHT = 16

-- Color themes for cyberpunk aesthetic
local COLOR_THEMES = {
    matrix = {
        primary = {0, 1, 0},      -- Bright green
        secondary = {0, 0.7, 0},  -- Medium green
        accent = {0, 0.4, 0},     -- Dark green
        background = {0, 0.1, 0}, -- Very dark green
        text = {0.9, 1, 0.9}      -- Light green
    },
    cyberpunk = {
        primary = {0, 1, 1},      -- Cyan
        secondary = {1, 0, 1},    -- Magenta
        accent = {0.5, 0, 1},     -- Purple
        background = {0.1, 0, 0.2}, -- Dark purple
        text = {0.9, 0.9, 1}      -- Light blue
    },
    neon = {
        primary = {0, 0.5, 1},    -- Neon blue
        secondary = {1, 0.2, 0.8}, -- Hot pink
        accent = {0.3, 1, 0.5},   -- Neon green
        background = {0.05, 0.05, 0.15}, -- Dark blue
        text = {0.8, 0.9, 1}      -- Ice blue
    }
}

-- Character sprites for different roles
local CHARACTER_SPRITES = {
    ceo = {
        sprite = {"👤", "💼"},
        name = "CEO",
        skills = {"Leadership", "Strategy"}
    },
    security_analyst = {
        sprite = {"👩‍💻", "🔍"},
        name = "Security Analyst", 
        skills = {"Analysis", "Detection"}
    },
    incident_responder = {
        sprite = {"🚨", "⚡"},
        name = "Incident Responder",
        skills = {"Response", "Recovery"}
    },
    penetration_tester = {
        sprite = {"🎯", "⚔️"},
        name = "Penetration Tester",
        skills = {"Testing", "Exploitation"}
    }
}

-- UI elements for terminal interface
local UI_ELEMENTS = {
    status_online = "🟢",
    status_warning = "🟡", 
    status_critical = "🔴",
    button_arrow = "►",
    checkbox_empty = "☐",
    checkbox_filled = "☑",
    progress_empty = "□",
    progress_filled = "■",
    separator = "─",
    corner_tl = "┌",
    corner_tr = "┐", 
    corner_bl = "└",
    corner_br = "┘",
    vertical = "│",
    horizontal = "─",
    alert_icon = "⚠️",
    success_icon = "✅",
    error_icon = "❌"
}

-- Resource icons
local RESOURCE_ICONS = {
    money = "💰",
    reputation = "⭐",
    energy = "⚡",
    focus = "🎯"
}

-- Room class for dynamic generation
AsciiArt.Room = {}
AsciiArt.Room.__index = AsciiArt.Room

function AsciiArt.Room.new(roomType, windowWidth, windowHeight)
    local self = setmetatable({}, AsciiArt.Room)
    
    -- Window and grid dimensions
    self.windowWidth = windowWidth or 1024
    self.windowHeight = windowHeight or 768
    self.charWidth = math.floor(self.windowWidth / CHAR_WIDTH)
    self.charHeight = math.floor(self.windowHeight / CHAR_HEIGHT)
    
    -- Minimum grid size constraints
    self.charWidth = math.max(self.charWidth, 40)
    self.charHeight = math.max(self.charHeight, 20)
    
    -- Room properties
    self.roomType = roomType
    self.layout = {}
    self.interactiveAreas = {}
    
    -- Load and generate the room
    self:loadRoomSchema()
    self:generateRoom()
    
    return self
end

function AsciiArt.Room:loadRoomSchema()
    -- Load room schemas from JSON
    local schemaPath = "src/data/room_schemas.json"
    local schemaData = nil
    
    -- Try to load JSON file
    if love and love.filesystem and love.filesystem.getInfo(schemaPath) then
        local content = love.filesystem.read(schemaPath)
        if content then
            schemaData = json.decode(content)
        end
    else
        -- Fallback for non-Love2D environments
        local file = io.open(schemaPath, "r")
        if file then
            local content = file:read("*all")
            file:close()
            schemaData = json.decode(content)
        end
    end
    
    if schemaData and schemaData.room_schemas then
        self.schema = schemaData.room_schemas[self.roomType]
    end
    
    -- Fallback for unknown room types
    if not self.schema then
        self.schema = {
            title = "Unknown Room Type: " .. (self.roomType or "nil"),
            elements = {
                {
                    id = "fallback_area",
                    type = "interactive_box",
                    x = 0.3,
                    y = 0.4,
                    width = 16,
                    height = 4,
                    title = "❓ UNKNOWN",
                    content = {"New room type", "Define in JSON"},
                    icon = "❓",
                    action = "EXPLORE"
                }
            }
        }
    end
end

function AsciiArt.Room:generateRoom()
    -- Initialize empty grid
    self.layout = {}
    for y = 1, self.charHeight do
        self.layout[y] = {}
        for x = 1, self.charWidth do
            self.layout[y][x] = " "
        end
    end
    
    self.interactiveAreas = {}
    
    -- Draw room border
    self:drawBorder()
    
    -- Draw room title
    self:drawTitle()
    
    -- Draw elements from schema
    if self.schema and self.schema.elements then
        for _, element in ipairs(self.schema.elements) do
            self:drawElement(element)
        end
    end
end

function AsciiArt.Room:drawBorder()
    -- Top and bottom borders
    for x = 1, self.charWidth do
        self.layout[1][x] = UI_ELEMENTS.horizontal
        self.layout[self.charHeight][x] = UI_ELEMENTS.horizontal
    end
    
    -- Left and right borders
    for y = 1, self.charHeight do
        self.layout[y][1] = UI_ELEMENTS.vertical
        self.layout[y][self.charWidth] = UI_ELEMENTS.vertical
    end
    
    -- Corners
    self.layout[1][1] = UI_ELEMENTS.corner_tl
    self.layout[1][self.charWidth] = UI_ELEMENTS.corner_tr
    self.layout[self.charHeight][1] = UI_ELEMENTS.corner_bl
    self.layout[self.charHeight][self.charWidth] = UI_ELEMENTS.corner_br
end

function AsciiArt.Room:drawTitle()
    if not self.schema or not self.schema.title then return end
    
    local title = self.schema.title
    local titleX = math.floor((self.charWidth - #title) / 2) + 1
    local titleY = 2
    
    -- Ensure title fits within bounds
    if titleX > 0 and titleX + #title <= self.charWidth then
        for i = 1, #title do
            if titleX + i - 1 <= self.charWidth then
                self.layout[titleY][titleX + i - 1] = title:sub(i, i)
            end
        end
    end
end

function AsciiArt.Room:drawElement(element)
    if element.type == "interactive_box" then
        self:drawInteractiveBox(element)
    end
    -- Future: Add support for other element types
end

function AsciiArt.Room:drawInteractiveBox(element)
    -- Calculate absolute position from relative coordinates
    local startX = math.floor(element.x * self.charWidth) + 1
    local startY = math.floor(element.y * self.charHeight) + 1
    local width = element.width or 10
    local height = element.height or 3
    
    -- Ensure bounds
    startX = math.max(2, math.min(startX, self.charWidth - width))
    startY = math.max(3, math.min(startY, self.charHeight - height))
    local endX = math.min(startX + width - 1, self.charWidth - 1)
    local endY = math.min(startY + height - 1, self.charHeight - 1)
    
    -- Draw box border
    for x = startX, endX do
        self.layout[startY][x] = UI_ELEMENTS.horizontal
        self.layout[endY][x] = UI_ELEMENTS.horizontal
    end
    for y = startY, endY do
        self.layout[y][startX] = UI_ELEMENTS.vertical
        self.layout[y][endX] = UI_ELEMENTS.vertical
    end
    
    -- Draw corners
    self.layout[startY][startX] = UI_ELEMENTS.corner_tl
    self.layout[startY][endX] = UI_ELEMENTS.corner_tr
    self.layout[endY][startX] = UI_ELEMENTS.corner_bl
    self.layout[endY][endX] = UI_ELEMENTS.corner_br
    
    -- Draw title
    if element.title then
        local titleX = startX + 1
        local titleY = startY + 1
        for i = 1, math.min(#element.title, endX - startX - 1) do
            self.layout[titleY][titleX + i - 1] = element.title:sub(i, i)
        end
    end
    
    -- Draw content lines
    if element.content then
        for i, line in ipairs(element.content) do
            local contentY = startY + 1 + i
            if contentY < endY then
                local contentX = startX + 1
                for j = 1, math.min(#line, endX - startX - 1) do
                    self.layout[contentY][contentX + j - 1] = line:sub(j, j)
                end
            end
        end
    end
    
    -- Store interactive area for click detection
    table.insert(self.interactiveAreas, {
        id = element.id,
        x = startX * CHAR_WIDTH,
        y = startY * CHAR_HEIGHT,
        width = (endX - startX + 1) * CHAR_WIDTH,
        height = (endY - startY + 1) * CHAR_HEIGHT,
        action = element.action,
        icon = element.icon
    })
end

function AsciiArt.Room:renderToString()
    local lines = {}
    for y = 1, self.charHeight do
        local line = ""
        for x = 1, self.charWidth do
            line = line .. (self.layout[y][x] or " ")
        end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

function AsciiArt.Room:getInteractiveAreaAt(mouseX, mouseY)
    for _, area in ipairs(self.interactiveAreas) do
        if mouseX >= area.x and mouseX <= area.x + area.width and
           mouseY >= area.y and mouseY <= area.y + area.height then
            return area
        end
    end
    return nil
end

function AsciiArt.Room:resize(newWidth, newHeight)
    self.windowWidth = newWidth
    self.windowHeight = newHeight
    self.charWidth = math.floor(newWidth / CHAR_WIDTH)
    self.charHeight = math.floor(newHeight / CHAR_HEIGHT)
    
    -- Apply minimum constraints
    self.charWidth = math.max(self.charWidth, 40)
    self.charHeight = math.max(self.charHeight, 20)
    
    -- Regenerate layout
    self:generateRoom()
end

-- Legacy compatibility functions
function AsciiArt.renderRoom(roomType, width, height)
    local room = AsciiArt.Room.new(roomType, width, height)
    return room:renderToString()
end

function AsciiArt.renderCharacter(characterType)
    local char = CHARACTER_SPRITES[characterType]
    if not char then return "❓" end
    return char.sprite[1] .. " " .. char.name
end

function AsciiArt.getIcon(iconType)
    return RESOURCE_ICONS[iconType] or UI_ELEMENTS[iconType] or "❓"
end

function AsciiArt.getUIElement(elementType)
    return UI_ELEMENTS[elementType] or "?"
end

function AsciiArt.getColorTheme(themeName)
    return COLOR_THEMES[themeName or "cyberpunk"]
end

-- Export character sprites and UI elements for external access
AsciiArt.characters = CHARACTER_SPRITES
AsciiArt.ui = UI_ELEMENTS
AsciiArt.resources = RESOURCE_ICONS
AsciiArt.themes = COLOR_THEMES

return AsciiArt