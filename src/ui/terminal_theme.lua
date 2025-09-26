-- Terminal Theme System
-- Provides cyberpunk terminal styling and visual effects

local TerminalTheme = {}
TerminalTheme.__index = TerminalTheme

-- Cyberpunk color palette
TerminalTheme.colors = {
    -- Background colors
    background = {0, 0, 0},           -- Pure black terminal background
    backgroundAlt = {0.05, 0.05, 0.1}, -- Slightly tinted black for panels
    
    -- Primary text colors
    primary = {0, 1, 0},              -- Classic hacker green
    secondary = {0, 0.8, 1},          -- Cyan for highlights
    accent = {1, 0, 1},               -- Magenta for important items
    warning = {1, 1, 0},              -- Yellow for warnings
    danger = {1, 0.2, 0.2},           -- Red for alerts/threats
    success = {0, 1, 0.5},            -- Bright green for success
    
    -- UI element colors  
    border = {0, 0.6, 0.6},           -- Cyan borders
    panel = {0.1, 0.1, 0.2, 0.8},    -- Semi-transparent dark panels
    highlight = {0, 1, 1, 0.3},       -- Cyan highlight overlay
    
    -- Text variations
    dimmed = {0.4, 0.8, 0.4},         -- Dimmed green text
    muted = {0.3, 0.3, 0.5},          -- Very dim purple for inactive
}

-- Terminal visual effects
TerminalTheme.effects = {
    scanlineOpacity = 0.1,
    scanlineSpeed = 2.0,
    cursorBlinkSpeed = 1.5,
    textGlowIntensity = 0.2,
}

-- Create new terminal theme
function TerminalTheme.new()
    local self = setmetatable({}, TerminalTheme)
    self.time = 0
    self.scanlineOffset = 0
    return self
end

function TerminalTheme:update(dt)
    self.time = self.time + dt
    self.scanlineOffset = (self.scanlineOffset + self.effects.scanlineSpeed * dt) % love.graphics.getHeight()
end

-- Draw terminal background with effects
function TerminalTheme:drawBackground()
    local width, height = love.graphics.getDimensions()
    
    -- Fill with pure black background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Draw subtle scan lines effect
    love.graphics.setColor(self.colors.primary[1], self.colors.primary[2], self.colors.primary[3], self.effects.scanlineOpacity)
    for y = 0, height, 4 do
        local offsetY = (y + self.scanlineOffset) % height
        love.graphics.line(0, offsetY, width, offsetY)
    end
end

-- Draw a terminal panel/window
function TerminalTheme:drawPanel(x, y, width, height, title)
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Panel border
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title bar if provided
    if title then
        love.graphics.setColor(self.colors.secondary)
        love.graphics.print("═══ " .. title .. " ═══", x + 5, y - 15)
    end
end

-- Draw terminal-style text with glow effect
function TerminalTheme:drawText(text, x, y, color, glowEnabled)
    color = color or self.colors.primary
    glowEnabled = glowEnabled ~= false -- Default to true
    
    if glowEnabled then
        -- Draw glow effect
        local glowColor = {color[1], color[2], color[3], self.effects.textGlowIntensity}
        love.graphics.setColor(glowColor)
        for offsetX = -1, 1 do
            for offsetY = -1, 1 do
                if offsetX ~= 0 or offsetY ~= 0 then
                    love.graphics.print(text, x + offsetX, y + offsetY)
                end
            end
        end
    end
    
    -- Draw main text
    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
end

-- Draw blinking cursor
function TerminalTheme:drawCursor(x, y)
    local alpha = (math.sin(self.time * self.effects.cursorBlinkSpeed) + 1) / 2
    love.graphics.setColor(self.colors.primary[1], self.colors.primary[2], self.colors.primary[3], alpha)
    love.graphics.rectangle("fill", x, y, 8, 14)
end

-- Draw ASCII art terminal header
function TerminalTheme:drawHeader(title, subtitle)
    local width = love.graphics.getWidth()
    
    -- Main title with ASCII styling
    self:drawText("╔══════════════════════════════════════════════════════════════════════════════════════╗", 10, 10, self.colors.border, false)
    
    -- Pad title to fit within border (86 chars max)
    local paddedTitle = title
    if string.len(title) > 82 then
        paddedTitle = string.sub(title, 1, 82)
    end
    local titlePadding = math.max(0, 82 - string.len(paddedTitle))
    
    self:drawText("║  " .. paddedTitle .. string.rep(" ", titlePadding) .. "  ║", 10, 25, self.colors.secondary)
    
    if subtitle then
        local paddedSubtitle = subtitle
        if string.len(subtitle) > 82 then
            paddedSubtitle = string.sub(subtitle, 1, 82)
        end
        local subtitlePadding = math.max(0, 82 - string.len(paddedSubtitle))
        
        self:drawText("║  " .. paddedSubtitle .. string.rep(" ", subtitlePadding) .. "  ║", 10, 40, self.colors.dimmed)
        self:drawText("╚══════════════════════════════════════════════════════════════════════════════════════╝", 10, 55, self.colors.border, false)
        return 70 -- Return Y offset for content
    else
        self:drawText("╚══════════════════════════════════════════════════════════════════════════════════════╝", 10, 40, self.colors.border, false)
        return 55 -- Return Y offset for content
    end
end

-- Draw status bar at bottom of screen
function TerminalTheme:drawStatusBar(statusText)
    local width, height = love.graphics.getDimensions()
    local barHeight = 25
    
    -- Status bar background
    love.graphics.setColor(self.colors.backgroundAlt)
    love.graphics.rectangle("fill", 0, height - barHeight, width, barHeight)
    
    -- Status bar border
    love.graphics.setColor(self.colors.border)
    love.graphics.line(0, height - barHeight, width, height - barHeight)
    
    -- Status text
    self:drawText(statusText or "SYSTEM READY", 10, height - 20, self.colors.primary)
    
    -- Current time in corner
    local timeStr = os.date("%H:%M:%S")
    local textWidth = string.len(timeStr) * 8 -- Approximate character width
    self:drawText(timeStr, width - textWidth - 10, height - 20, self.colors.dimmed)
end

-- Get color by name for easy access
function TerminalTheme:getColor(colorName)
    return self.colors[colorName] or self.colors.primary
end

return TerminalTheme