-- Enhanced Office Map UI
-- Renders different room environments with unique layouts and atmospheric elements

local EnhancedOfficeMap = {}
EnhancedOfficeMap.__index = EnhancedOfficeMap

local RoomAmbiance = require("src.ui.room_ambiance")

function EnhancedOfficeMap.new()
    local self = setmetatable({}, EnhancedOfficeMap)
    
    -- Visual state
    self.transitionAlpha = 0
    self.roomAnimations = {}
    self.particleEffects = {}
    
    -- Cached assets
    self.bgImages = {}
    self.sprites = {}
    self.fonts = {}
    
    -- Animation timers
    self.animationTime = 0
    self.pulseTime = 0
    
    return self
end

-- Attempt to load room-specific background images
local function tryLoadRoomImage(roomId)
    local paths = {
        "assets/rooms/" .. roomId .. ".png",
        "assets/rooms/" .. roomId .. ".jpg",
        "assets/rooms/" .. roomId .. ".jpeg",
        "assets/" .. roomId .. "_bg.png"
    }
    
    for _, path in ipairs(paths) do
        if love and love.filesystem and love.filesystem.getInfo(path) then
            local ok, img = pcall(function() return love.graphics.newImage(path) end)
            if ok and img then return img end
        end
    end
    return nil
end

-- Draw the current room environment
function EnhancedOfficeMap:draw(roomSystem, player, opts)
    if not roomSystem then return end
    
    local room = roomSystem:getCurrentRoom()
    if not room then return end
    
    -- Calculate draw area
    local width = room.width or 640
    local height = room.height or 400
    local offsetX = opts and opts.offsetX or 0
    local offsetY = opts and opts.offsetY or 0
    
    -- Draw room background
    self:drawRoomBackground(room, width, height, offsetX, offsetY)
    
    -- Draw room-specific atmospheric elements
    self:drawAtmosphericElements(room, width, height, offsetX, offsetY)
    
    -- Draw interactive areas/departments
    self:drawInteractiveAreas(room, offsetX, offsetY)
    
    -- Draw player
    if player then
        self:drawPlayer(player, room, offsetX, offsetY)
    end
    
    -- Draw room transition effects
    if roomSystem.isTransitioning then
        self:drawTransitionEffect(roomSystem.transitionTime)
    end
    
    -- Draw room UI elements
    self:drawRoomUI(room, width, height, offsetX, offsetY)
end

-- Draw room background with unique styling
function EnhancedOfficeMap:drawRoomBackground(room, width, height, offsetX, offsetY)
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    
    -- Try to load room-specific background
    if not self.bgImages[room.id] then
        self.bgImages[room.id] = tryLoadRoomImage(room.id)
    end
    
    if self.bgImages[room.id] then
        -- Draw custom background image
        love.graphics.setColor(1, 1, 1, 1)
        local bg = self.bgImages[room.id]
        local scaleX = width / bg:getWidth()
        local scaleY = height / bg:getHeight()
        local scale = math.max(scaleX, scaleY)
        
        local imgW = bg:getWidth() * scale
        local imgH = bg:getHeight() * scale
        love.graphics.draw(bg, (width - imgW) / 2, (height - imgH) / 2, 0, scale, scale)
    else
        -- Draw procedural background based on room theme
        love.graphics.setColor(room.bgColor or {0.05, 0.05, 0.08, 1})
        love.graphics.rectangle("fill", 0, 0, width, height)
    end
    
    -- Draw atmospheric grid
    self:drawAtmosphericGrid(room, width, height)
    
    -- Draw room boundaries
    love.graphics.setColor(room.wallColor or {0.15, 0.20, 0.25, 1})
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 2, 2, width - 4, height - 4, 8, 8)
    
    love.graphics.pop()
end

-- Draw atmospheric grid based on room type
function EnhancedOfficeMap:drawAtmosphericGrid(room, width, height)
    love.graphics.setColor(room.gridColor or {0.08, 0.12, 0.16, 0.3})
    love.graphics.setLineWidth(1)
    
    local spacing = 40
    local animOffset = math.sin(self.animationTime * 2) * 2
    
    -- Different grid patterns for different room types
    if room.id == "server_room" then
        -- Dense technical grid
        spacing = 20
        love.graphics.setColor(0.1, 0.3, 0.4, 0.4)
    elseif room.id == "emergency_response_center" then
        -- Alert-style hexagonal pattern
        spacing = 30
        love.graphics.setColor(0.4, 0.1, 0.1, 0.3)
    elseif room.id == "kitchen_break_room" then
        -- Soft, warm grid
        spacing = 50
        love.graphics.setColor(0.2, 0.15, 0.1, 0.2)
    end
    
    -- Draw animated grid
    for x = 0, width, spacing do
        love.graphics.line(x + animOffset, 0, x + animOffset, height)
    end
    for y = 0, height, spacing do
        love.graphics.line(0, y + animOffset, width, y + animOffset)
    end
end

-- Draw atmospheric elements specific to each room type
function EnhancedOfficeMap:drawAtmosphericElements(room, width, height, offsetX, offsetY)
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    
    if room.id == "server_room" then
        self:drawServerRoomEffects(width, height)
    elseif room.id == "emergency_response_center" then
        self:drawEmergencyRoomEffects(width, height)
    elseif room.id == "conference_room" then
        self:drawConferenceRoomEffects(width, height)
    elseif room.id == "kitchen_break_room" then
        self:drawKitchenEffects(width, height)
    elseif room.id == "personal_office" then
        self:drawPersonalOfficeEffects(width, height)
    end
    
    love.graphics.pop()
end

-- Server room: Blinking lights and data streams
function EnhancedOfficeMap:drawServerRoomEffects(width, height)
    local blinkTime = math.floor(self.animationTime * 3) % 2
    
    -- Server rack lights
    for i = 1, 8 do
        local x = 50 + (i * 60)
        local y = 80
        
        if blinkTime == 0 or i % 2 == 0 then
            love.graphics.setColor(0, 1, 0, 0.8)
        else
            love.graphics.setColor(0, 0.5, 0, 0.4)
        end
        love.graphics.circle("fill", x, y, 3)
    end
    
    -- Data stream effect
    love.graphics.setColor(0, 0.8, 1, 0.3)
    for i = 1, 20 do
        local x = (i * 35) % width
        local y = 200 + math.sin(self.animationTime * 2 + i) * 20
        love.graphics.circle("fill", x, y, 2)
    end
end

-- Emergency center: Pulsing red alerts and radar sweeps
function EnhancedOfficeMap:drawEmergencyRoomEffects(width, height)
    local pulseAlpha = (math.sin(self.animationTime * 4) + 1) / 4
    
    -- Alert pulse overlay
    love.graphics.setColor(1, 0, 0, pulseAlpha * 0.1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Radar sweep effect
    love.graphics.setColor(0, 1, 0, 0.6)
    local centerX, centerY = width / 2, height / 2
    local sweepAngle = self.animationTime * 2
    love.graphics.line(
        centerX, 
        centerY,
        centerX + math.cos(sweepAngle) * 100,
        centerY + math.sin(sweepAngle) * 100
    )
    
    -- Status indicators
    local statuses = {"🟢", "🟡", "🔴"}
    for i, status in ipairs(statuses) do
        local x = width - 100
        local y = 30 + i * 25
        if love.graphics.printf then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(status, x, y, 50, "center")
        end
    end
end

-- Conference room: Professional lighting and presentation effects
function EnhancedOfficeMap:drawConferenceRoomEffects(width, height)
    -- Soft professional lighting
    love.graphics.setColor(1, 1, 0.9, 0.1)
    love.graphics.circle("fill", width / 2, height / 4, 80)
    
    -- Presentation screen glow
    love.graphics.setColor(0.5, 0.7, 1, 0.3)
    love.graphics.rectangle("fill", width / 2 - 100, 30, 200, 100, 10, 10)
end

-- Kitchen: Warm ambient lighting and steam effects
function EnhancedOfficeMap:drawKitchenEffects(width, height)
    -- Warm ambient glow
    love.graphics.setColor(1, 0.8, 0.6, 0.15)
    love.graphics.circle("fill", 150, 120, 60)
    
    -- Steam from coffee machine
    for i = 1, 5 do
        local steamY = 80 - (self.animationTime * 20 + i * 10) % 100
        love.graphics.setColor(1, 1, 1, 0.3 - (steamY / 300))
        love.graphics.circle("fill", 220 + math.sin(steamY / 10) * 5, steamY, 3)
    end
end

-- Personal office: Focused work lighting and document effects
function EnhancedOfficeMap:drawPersonalOfficeEffects(width, height)
    -- Desk lamp glow
    love.graphics.setColor(1, 1, 0.8, 0.2)
    love.graphics.circle("fill", 320, 180, 70)
    
    -- Monitor glow
    love.graphics.setColor(0.3, 0.5, 1, 0.4)
    love.graphics.rectangle("fill", 300, 60, 80, 50, 5, 5)
end

-- Draw interactive areas with enhanced visuals
function EnhancedOfficeMap:drawInteractiveAreas(room, offsetX, offsetY)
    if not room.areas then return end
    
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    
    for _, area in ipairs(room.areas) do
        self:drawInteractiveArea(area, room)
    end
    
    love.graphics.pop()
end

-- Draw a single interactive area
function EnhancedOfficeMap:drawInteractiveArea(area, room)
    local pulseScale = 1 + math.sin(self.pulseTime * 3 + area.x / 50) * 0.1
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", area.x + 3, area.y + 3, area.radius * pulseScale)
    
    -- Base area circle
    love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
    love.graphics.circle("fill", area.x, area.y, area.radius * pulseScale)
    
    -- Inner highlight
    love.graphics.setColor(0.4, 0.6, 0.8, 0.6)
    love.graphics.circle("fill", area.x, area.y, (area.radius - 8) * pulseScale)
    
    -- Border
    love.graphics.setColor(0.6, 0.8, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", area.x, area.y, area.radius * pulseScale)
    
    -- Icon/Label (if text rendering is available)
    love.graphics.setColor(1, 1, 1, 1)
    if love.graphics.printf then
        local iconText = area.icon or "●"
        love.graphics.printf(iconText, area.x - 20, area.y - 8, 40, "center")
        
        -- Area name below
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf(area.name, area.x - 60, area.y + area.radius + 5, 120, "center")
    end
end

-- Draw player with room-specific styling
function EnhancedOfficeMap:drawPlayer(player, room, offsetX, offsetY)
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    
    local playerX = player.x or 0
    local playerY = player.y or 0
    local playerSize = player.size or 12
    
    -- Player glow effect based on room
    local glowColor = {0.5, 0.8, 1, 0.4}
    if room.id == "emergency_response_center" then
        glowColor = {1, 0.3, 0.3, 0.4}
    elseif room.id == "server_room" then
        glowColor = {0.3, 1, 0.3, 0.4}
    elseif room.id == "kitchen_break_room" then
        glowColor = {1, 0.8, 0.3, 0.4}
    end
    
    -- Player glow
    love.graphics.setColor(glowColor)
    love.graphics.circle("fill", playerX, playerY, playerSize + 6)
    
    -- Player shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", playerX + 2, playerY + 2, playerSize)
    
    -- Player body
    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.circle("fill", playerX, playerY, playerSize)
    
    -- Player highlight
    love.graphics.setColor(0.4, 0.6, 1, 1)
    love.graphics.circle("fill", playerX - 3, playerY - 3, playerSize / 2)
    
    -- Player border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", playerX, playerY, playerSize)
    
    -- Player indicator
    love.graphics.setColor(1, 1, 1, 0.9)
    if love.graphics.printf then
        love.graphics.printf("You", playerX - 20, playerY - playerSize - 16, 40, "center")
    end
    
    love.graphics.pop()
end

-- Draw room transition effects
function EnhancedOfficeMap:drawTransitionEffect(transitionTime)
    local alpha = math.max(0, transitionTime * 2) -- Fade based on remaining time
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

-- Draw room-specific UI elements
function EnhancedOfficeMap:drawRoomUI(room, width, height, offsetX, offsetY)
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    
    -- Room title and description
    love.graphics.setColor(1, 1, 1, 0.9)
    if love.graphics.printf then
        love.graphics.printf(room.name, 10, 10, width - 20, "left")
        
        love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
        love.graphics.printf(room.description, 10, 35, width - 20, "left")
        
        -- Add atmospheric description
        local ambiance = RoomAmbiance.getDescription(room.id)
        love.graphics.setColor(0.6, 0.8, 1.0, 0.6)
        love.graphics.printf("🌟 " .. ambiance, 10, 55, width - 20, "left")
    end
    
    -- Room capacity indicator
    if room.maxOccupancy then
        love.graphics.setColor(0.6, 0.8, 1, 0.8)
        if love.graphics.printf then
            local capacityText = "Capacity: " .. (room.currentOccupancy or 1) .. "/" .. room.maxOccupancy
            love.graphics.printf(capacityText, width - 150, height - 25, 140, "right")
        end
    end
    
    -- Room bonuses display
    if room.bonuses then
        love.graphics.setColor(0.8, 1, 0.8, 0.7)
        local y = height - 100
        if love.graphics.printf then
            love.graphics.printf("Active Bonuses:", 10, y, 200, "left")
            y = y + 15
            
            local count = 0
            for bonusName, value in pairs(room.bonuses) do
                if count < 3 and type(value) == "number" and value > 1 then -- Show max 3 bonuses to avoid clutter
                    local bonusText = bonusName:gsub("Multiplier", ""):gsub("Bonus", "") .. ": +" .. math.floor((value - 1) * 100) .. "%"
                    love.graphics.printf("• " .. bonusText, 10, y, 300, "left")
                    y = y + 12
                    count = count + 1
                end
            end
        end
    end
    
    -- Environmental details (from ambiance system)
    local details = RoomAmbiance.getEnvironmentalDetails(room.id)
    if details and #details > 0 then
        love.graphics.setColor(0.7, 0.9, 1.0, 0.5)
        local detailY = height - 150
        if love.graphics.printf then
            love.graphics.printf("Environment:", width - 200, detailY, 190, "left")
            detailY = detailY + 12
            
            for i = 1, math.min(2, #details) do -- Show max 2 details
                love.graphics.printf("• " .. details[i], width - 200, detailY, 190, "left")
                detailY = detailY + 10
            end
        end
    end
    
    love.graphics.pop()
end

-- Update animation timers
function EnhancedOfficeMap:update(dt)
    self.animationTime = self.animationTime + dt
    self.pulseTime = self.pulseTime + dt * 2
    
    -- Wrap timers to prevent overflow
    if self.animationTime > 1000 then
        self.animationTime = self.animationTime - 1000
    end
    if self.pulseTime > 1000 then
        self.pulseTime = self.pulseTime - 1000
    end
end

-- Check if a point is within an interactive area
function EnhancedOfficeMap:getAreaAtPosition(room, x, y, offsetX, offsetY)
    if not room or not room.areas then return nil end
    
    local adjustedX = x - (offsetX or 0)
    local adjustedY = y - (offsetY or 0)
    
    for _, area in ipairs(room.areas) do
        local dx = adjustedX - area.x
        local dy = adjustedY - area.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance <= area.radius then
            return area
        end
    end
    
    return nil
end

return EnhancedOfficeMap