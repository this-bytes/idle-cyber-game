-- Smart UI Framework: Panel Component
-- Container with borders, backgrounds, and optional title bar

local Box = require("src.ui.components.box")
local Text = require("src.ui.components.text")

local Panel = setmetatable({}, {__index = Box})
Panel.__index = Panel

function Panel.new(props)
    props = props or {}
    
    -- Set default panel styling
    props.direction = props.direction or "vertical"
    props.backgroundColor = props.backgroundColor or {0.1, 0.1, 0.15, 0.9}
    props.borderColor = props.borderColor or {0, 1, 1, 1}  -- Cyan border
    props.borderWidth = props.borderWidth or 2
    props.padding = props.padding or {8, 8, 8, 8}
    
    local self = Box.new(props)
    setmetatable(self, Panel)
    
    -- Panel-specific properties
    self.title = props.title or nil
    self.titleColor = props.titleColor or {0, 1, 1, 1}  -- Cyan
    self.titleFont = props.titleFont or nil
    self.titleFontSize = props.titleFontSize or 16
    self.titlePadding = props.titlePadding or 4
    self.titleAlign = props.titleAlign or "left"  -- "left" | "center" | "right"
    
    -- Shadow effect
    self.shadow = props.shadow or false
    self.shadowColor = props.shadowColor or {0, 0, 0, 0.5}
    self.shadowOffset = props.shadowOffset or {4, 4}
    
    -- Glow effect (cyberpunk style)
    self.glow = props.glow or false
    self.glowColor = props.glowColor or {0, 1, 1, 0.3}
    self.glowSize = props.glowSize or 4
    
    -- Corner style
    self.cornerStyle = props.cornerStyle or "square"  -- "square" | "rounded" | "cut"
    self.cornerSize = props.cornerSize or 8
    
    -- Create title text component if title provided
    self._titleComponent = nil
    if self.title then
        self:createTitleComponent()
    end
    
    return self
end

-- Create title component
function Panel:createTitleComponent()
    self._titleComponent = Text.new({
        text = self.title,
        color = self.titleColor,
        fontSize = self.titleFontSize,
        font = self.titleFont,
        textAlign = self.titleAlign,
        bold = true
    })
end

-- Set title
function Panel:setTitle(title)
    self.title = title
    if title and not self._titleComponent then
        self:createTitleComponent()
        self:invalidateLayout()
    elseif title and self._titleComponent then
        self._titleComponent:setText(title)
        self:invalidateLayout()
    elseif not title and self._titleComponent then
        self._titleComponent = nil
        self:invalidateLayout()
    end
end

-- Measure with title bar consideration
function Panel:measure(availableWidth, availableHeight)
    local titleHeight = 0
    
    -- Measure title if present
    if self._titleComponent then
        local titleSize = self._titleComponent:measure(availableWidth, availableHeight)
        titleHeight = titleSize.height + self.titlePadding * 2
    end
    
    -- Measure content using parent Box measure
    local contentSize = Box.measure(self, availableWidth, availableHeight - titleHeight)
    
    -- Combine title and content
    self.intrinsicSize = {
        width = contentSize.width,
        height = contentSize.height + titleHeight
    }
    
    self._titleHeight = titleHeight
    
    return self.intrinsicSize
end

-- Layout with title bar
function Panel:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    local titleHeight = self._titleHeight or 0
    
    -- Layout title
    if self._titleComponent then
        local titleX = x + self.padding[4] + self.borderWidth
        local titleY = y + self.borderWidth + self.titlePadding
        local titleWidth = width - self.padding[2] - self.padding[4] - (self.borderWidth * 2)
        
        self._titleComponent:layout(titleX, titleY, titleWidth, titleHeight - self.titlePadding * 2)
    end
    
    -- Layout content area (using Box layout for children)
    local contentY = y + titleHeight
    local contentHeight = height - titleHeight
    
    -- Temporarily adjust position for Box layout
    local originalY = self.y
    self.y = contentY
    Box.layout(self, x, contentY, width, contentHeight)
    self.y = originalY  -- Restore for rendering
end

-- Render panel with decorations
function Panel:render()
    if not self.visible then return end
    
    local love = love or _G.love
    
    -- Save state
    local r, g, b, a = love.graphics.getColor()
    local lineWidth = love.graphics.getLineWidth()
    
    -- Draw shadow
    if self.shadow then
        love.graphics.setColor(self.shadowColor)
        love.graphics.rectangle("fill", 
            self.x + self.shadowOffset[1], 
            self.y + self.shadowOffset[2], 
            self.width, 
            self.height
        )
    end
    
    -- Draw glow effect
    if self.glow then
        love.graphics.setColor(self.glowColor)
        for i = 1, self.glowSize do
            local offset = i
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", 
                self.x - offset, 
                self.y - offset, 
                self.width + offset * 2, 
                self.height + offset * 2
            )
        end
    end
    
    -- Draw background
    if self.backgroundColor then
        love.graphics.setColor(self.backgroundColor)
        
        if self.cornerStyle == "rounded" then
            -- Rounded corners (approximate with rectangles and circles)
            local r = self.cornerSize
            love.graphics.rectangle("fill", self.x + r, self.y, self.width - r * 2, self.height)
            love.graphics.rectangle("fill", self.x, self.y + r, self.width, self.height - r * 2)
            love.graphics.circle("fill", self.x + r, self.y + r, r)
            love.graphics.circle("fill", self.x + self.width - r, self.y + r, r)
            love.graphics.circle("fill", self.x + r, self.y + self.height - r, r)
            love.graphics.circle("fill", self.x + self.width - r, self.y + self.height - r, r)
        elseif self.cornerStyle == "cut" then
            -- Cut corners (cyberpunk style)
            local c = self.cornerSize
            local points = {
                self.x + c, self.y,                          -- Top left
                self.x + self.width - c, self.y,            -- Top right corner start
                self.x + self.width, self.y + c,            -- Top right
                self.x + self.width, self.y + self.height - c,  -- Bottom right corner start
                self.x + self.width - c, self.y + self.height,  -- Bottom right
                self.x + c, self.y + self.height,           -- Bottom left corner start
                self.x, self.y + self.height - c,           -- Bottom left
                self.x, self.y + c                          -- Top left corner end
            }
            love.graphics.polygon("fill", points)
        else
            -- Square corners
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        end
    end
    
    -- Draw title bar background
    if self._titleComponent and self._titleHeight then
        local titleBarColor = {
            self.backgroundColor[1] * 1.2,
            self.backgroundColor[2] * 1.2,
            self.backgroundColor[3] * 1.2,
            self.backgroundColor[4]
        }
        love.graphics.setColor(titleBarColor)
        love.graphics.rectangle("fill", 
            self.x, 
            self.y, 
            self.width, 
            self._titleHeight
        )
        
        -- Title bar separator line
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(1)
        love.graphics.line(
            self.x + self.borderWidth, 
            self.y + self._titleHeight,
            self.x + self.width - self.borderWidth, 
            self.y + self._titleHeight
        )
    end
    
    -- Draw border
    if self.borderColor and self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        
        if self.cornerStyle == "rounded" then
            -- Rounded border (approximate)
            local r = self.cornerSize
            local segments = 16
            
            -- Draw rounded rectangle outline
            love.graphics.arc("line", "open", self.x + r, self.y + r, r, math.pi, math.pi * 1.5, segments)
            love.graphics.line(self.x + r, self.y, self.x + self.width - r, self.y)
            love.graphics.arc("line", "open", self.x + self.width - r, self.y + r, r, math.pi * 1.5, 0, segments)
            love.graphics.line(self.x + self.width, self.y + r, self.x + self.width, self.y + self.height - r)
            love.graphics.arc("line", "open", self.x + self.width - r, self.y + self.height - r, r, 0, math.pi * 0.5, segments)
            love.graphics.line(self.x + self.width - r, self.y + self.height, self.x + r, self.y + self.height)
            love.graphics.arc("line", "open", self.x + r, self.y + self.height - r, r, math.pi * 0.5, math.pi, segments)
            love.graphics.line(self.x, self.y + self.height - r, self.x, self.y + r)
        elseif self.cornerStyle == "cut" then
            -- Cut corners border
            local c = self.cornerSize
            love.graphics.line(
                self.x + c, self.y,
                self.x + self.width - c, self.y,
                self.x + self.width, self.y + c,
                self.x + self.width, self.y + self.height - c,
                self.x + self.width - c, self.y + self.height,
                self.x + c, self.y + self.height,
                self.x, self.y + self.height - c,
                self.x, self.y + c,
                self.x + c, self.y
            )
        else
            -- Square border
            love.graphics.rectangle("line", 
                self.x + self.borderWidth/2, 
                self.y + self.borderWidth/2, 
                self.width - self.borderWidth, 
                self.height - self.borderWidth
            )
        end
    end
    
    -- Render title
    if self._titleComponent then
        self._titleComponent:render()
    end
    
    -- Render children (content area)
    love.graphics.setColor(r, g, b, a)
    for _, child in ipairs(self.children) do
        child:render()
    end
    
    -- Restore state
    love.graphics.setLineWidth(lineWidth)
    love.graphics.setColor(r, g, b, a)
end

return Panel
