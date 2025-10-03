-- Smart UI Framework: Text Component
-- Smart text rendering with automatic wrapping, truncation, and alignment

local Component = require("src.ui.components.component")

local Text = setmetatable({}, {__index = Component})
Text.__index = Text

function Text.new(props)
    props = props or {}
    local self = Component.new(props)
    setmetatable(self, Text)
    
    -- Text properties
    self.text = props.text or ""
    self.font = props.font or nil                    -- LÖVE Font object
    self.fontSize = props.fontSize or 14
    self.color = props.color or {1, 1, 1, 1}         -- {r, g, b, a}
    
    -- Layout properties
    self.textAlign = props.textAlign or "left"       -- "left" | "center" | "right" | "justify"
    self.verticalAlign = props.verticalAlign or "top" -- "top" | "center" | "bottom"
    self.wrap = props.wrap or false                  -- Enable text wrapping
    self.truncate = props.truncate or false          -- Truncate with ellipsis if too long
    self.maxLines = props.maxLines or nil            -- Max number of lines (nil = unlimited)
    
    -- Styling
    self.bold = props.bold or false
    self.italic = props.italic or false
    self.underline = props.underline or false
    self.lineHeight = props.lineHeight or 1.2        -- Line height multiplier
    
    -- Cache
    self._wrappedText = nil
    self._textDirty = true
    
    return self
end

-- Set text content
function Text:setText(text)
    if self.text ~= text then
        self.text = text
        self._textDirty = true
        self:invalidateLayout()
        -- Keep props in sync for test assertions and external inspection
        if self.props then self.props.text = text end
    end
end

-- Get or create font
function Text:getFont()
    local love = love or _G.love
    
    if not self.font then
        -- Try to use default font or create one
        if love.graphics.getFont then
            self.font = love.graphics.getFont()
        elseif love.graphics.newFont then
            self.font = love.graphics.newFont(self.fontSize)
        end
    end
    
    return self.font
end

-- Measure text size
function Text:measure(availableWidth, availableHeight)
    local font = self:getFont()
    if not font then
        self.intrinsicSize = {width = 0, height = 0}
        return self.intrinsicSize
    end
    
    local paddingX = self.padding[2] + self.padding[4]
    local paddingY = self.padding[1] + self.padding[3]
    
    local innerAvailableWidth = availableWidth - paddingX
    local innerAvailableHeight = availableHeight - paddingY
    
    local textWidth, textHeight
    
    if self.wrap and innerAvailableWidth > 0 then
        -- Wrap text to available width
        local wrappedWidth, wrappedLines = font:getWrap(self.text, innerAvailableWidth)
        self._wrappedText = wrappedLines
        
        -- Apply max lines constraint
        if self.maxLines and #wrappedLines > self.maxLines then
            wrappedLines = {table.unpack(wrappedLines, 1, self.maxLines)}
            -- Add ellipsis to last line if truncated
            if self.truncate then
                local lastLine = wrappedLines[#wrappedLines]
                wrappedLines[#wrappedLines] = lastLine .. "..."
            end
            self._wrappedText = wrappedLines
        end
        
        textWidth = wrappedWidth
        textHeight = font:getHeight() * self.lineHeight * #wrappedLines
    else
        -- Single line
        textWidth = font:getWidth(self.text)
        textHeight = font:getHeight() * self.lineHeight
        self._wrappedText = {self.text}
        
        -- Truncate if needed
        if self.truncate and textWidth > innerAvailableWidth then
            local truncated = self:truncateText(self.text, innerAvailableWidth - font:getWidth("..."))
            self._wrappedText = {truncated .. "..."}
            textWidth = innerAvailableWidth
        end
    end
    
    self._textDirty = false
    
    -- Add padding
    textWidth = textWidth + paddingX
    textHeight = textHeight + paddingY
    
    -- Clamp to constraints
    self.intrinsicSize = {
        width = math.min(math.max(textWidth, self.minWidth), self.maxWidth),
        height = math.min(math.max(textHeight, self.minHeight), self.maxHeight)
    }
    
    return self.intrinsicSize
end

-- Truncate text to fit width
function Text:truncateText(text, maxWidth)
    local font = self:getFont()
    if not font or font:getWidth(text) <= maxWidth then
        return text
    end
    
    -- Binary search for optimal truncation point
    local left = 1
    local right = #text
    local result = ""
    
    while left <= right do
        local mid = math.floor((left + right) / 2)
        local substring = text:sub(1, mid)
        local width = font:getWidth(substring)
        
        if width <= maxWidth then
            result = substring
            left = mid + 1
        else
            right = mid - 1
        end
    end
    
    return result
end

-- Layout (text doesn't have children, but we cache position)
function Text:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Recalculate wrapped text if dimensions changed
    if self._textDirty then
        self:measure(width, height)
    end
end

-- Render text
function Text:render()
    if not self.visible or not self.text or self.text == "" then return end
    
    local love = love or _G.love
    local font = self:getFont()
    if not font then return end
    
    -- Save previous state
    local r, g, b, a = love.graphics.getColor()
    local prevFont = love.graphics.getFont()
    
    -- Set font and color
    love.graphics.setFont(font)
    love.graphics.setColor(self.color)
    
    -- Calculate text position with padding
    local textX = self.x + self.padding[4]
    local textY = self.y + self.padding[1]
    local innerWidth = self.width - self.padding[2] - self.padding[4]
    local innerHeight = self.height - self.padding[1] - self.padding[3]
    
    -- Apply vertical alignment
    local totalTextHeight = font:getHeight() * self.lineHeight * #self._wrappedText
    if self.verticalAlign == "center" then
        textY = textY + (innerHeight - totalTextHeight) / 2
    elseif self.verticalAlign == "bottom" then
        textY = textY + innerHeight - totalTextHeight
    end
    
    -- Render each line
    for i, line in ipairs(self._wrappedText) do
        local lineY = textY + (i - 1) * font:getHeight() * self.lineHeight
        local lineWidth = font:getWidth(line)
        local lineX = textX
        local rendered = false

        -- Apply horizontal alignment
        if self.textAlign == "center" then
            lineX = textX + (innerWidth - lineWidth) / 2
        elseif self.textAlign == "right" then
            lineX = textX + innerWidth - lineWidth
        elseif self.textAlign == "justify" and i < #self._wrappedText then
            -- Justify by distributing space between words
            local words = {}
            for word in line:gmatch("%S+") do
                table.insert(words, word)
            end

            if #words > 1 then
                local totalWordWidth = 0
                for _, word in ipairs(words) do
                    totalWordWidth = totalWordWidth + font:getWidth(word)
                end

                local spaceWidth = (innerWidth - totalWordWidth) / (#words - 1)
                local currentX = lineX

                for _, word in ipairs(words) do
                    love.graphics.print(word, currentX, lineY)
                    currentX = currentX + font:getWidth(word) + spaceWidth
                end

                rendered = true
            end
        end

        -- Regular rendering if not already rendered by justify
        if not rendered then
            love.graphics.print(line, lineX, lineY)
        end
    end
    
    -- Restore state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(prevFont)
end

-- Update text if animated (for future use - typewriter effect, etc.)
function Text:update(dt)
    -- Future: implement text animations here
end

return Text
