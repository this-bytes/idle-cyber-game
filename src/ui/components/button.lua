-- Smart UI Framework: Button Component
-- Interactive button with hover/press states and callbacks

local Box = require("src.ui.components.box")
local Text = require("src.ui.components.text")

local Button = setmetatable({}, {__index = Box})
Button.__index = Button

function Button.new(props)
    props = props or {}
    
    -- Set default button styling
    props.direction = props.direction or "horizontal"
    props.align = props.align or "center"
    props.justify = props.justify or "center"
    props.padding = props.padding or {8, 16, 8, 16}
    props.minWidth = props.minWidth or 80
    props.minHeight = props.minHeight or 32
    props.className = props.className or "Button"  -- Identify as Button in logs
    
    local self = Box.new(props)
    setmetatable(self, Button)
    
    -- Button properties
    self.label = props.label or "Button"
    self.labelColor = props.labelColor or {1, 1, 1, 1}
    self.labelFont = props.labelFont or nil
    self.labelFontSize = props.labelFontSize or 14
    
    -- State colors
    self.normalColor = props.normalColor or {0.2, 0.2, 0.3, 1}
    self.hoverColor = props.hoverColor or {0.3, 0.3, 0.4, 1}
    self.pressColor = props.pressColor or {0.1, 0.1, 0.2, 1}
    self.disabledColor = props.disabledColor or {0.15, 0.15, 0.2, 0.5}
    
    self.normalBorderColor = props.normalBorderColor or {0, 1, 1, 1}
    self.hoverBorderColor = props.hoverBorderColor or {0, 1, 1, 1}
    self.pressBorderColor = props.pressBorderColor or {1, 0, 1, 1}  -- Magenta when pressed
    self.disabledBorderColor = props.disabledBorderColor or {0.5, 0.5, 0.5, 0.5}
    
    -- Border and styling
    self.borderWidth = props.borderWidth or 2
    self.cornerStyle = props.cornerStyle or "square"  -- "square" | "rounded" | "cut"
    self.cornerSize = props.cornerSize or 4
    
    -- Icon support (future)
    self.icon = props.icon or nil
    self.iconPosition = props.iconPosition or "left"  -- "left" | "right"
    
    -- Callbacks (in addition to props.onClick, etc.)
    self.onHoverEnter = props.onHoverEnter
    self.onHoverLeave = props.onHoverLeave
    
    -- Create label text component
    self._labelComponent = Text.new({
        text = self.label,
        color = self.labelColor,
        fontSize = self.labelFontSize,
        font = self.labelFont,
        textAlign = "center",
        verticalAlign = "center",
        className = "ButtonLabel"  -- Identify button labels in logs
    })
    
    -- Add label as child
    self:addChild(self._labelComponent)
    
    return self
end

-- Set label text
function Button:setLabel(label)
    self.label = label
    if self._labelComponent then
        self._labelComponent:setText(label)
        self:invalidateLayout()
    end
end

-- Set enabled state
function Button:setEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled
        if not enabled then
            self.hovered = false
            self.pressed = false
        end
        self:invalidateLayout()
    end
end

-- Get current state colors
function Button:getCurrentColors()
    if not self.enabled then
        return self.disabledColor, self.disabledBorderColor
    elseif self.pressed then
        return self.pressColor, self.pressBorderColor
    elseif self.hovered then
        return self.hoverColor, self.hoverBorderColor
    else
        return self.normalColor, self.normalBorderColor
    end
end

-- Render button with state-based styling
function Button:render()
    if not self.visible then return end
    
    local love = love or _G.love
    
    -- Save state
    local r, g, b, a = love.graphics.getColor()
    local lineWidth = love.graphics.getLineWidth()
    
    -- Get current colors based on state
    local bgColor, borderColor = self:getCurrentColors()
    
    -- Draw background
    love.graphics.setColor(bgColor)
    
    if self.cornerStyle == "rounded" then
        -- Rounded corners
        local rad = self.cornerSize
        love.graphics.rectangle("fill", self.x + rad, self.y, self.width - rad * 2, self.height)
        love.graphics.rectangle("fill", self.x, self.y + rad, self.width, self.height - rad * 2)
        love.graphics.circle("fill", self.x + rad, self.y + rad, rad)
        love.graphics.circle("fill", self.x + self.width - rad, self.y + rad, rad)
        love.graphics.circle("fill", self.x + rad, self.y + self.height - rad, rad)
        love.graphics.circle("fill", self.x + self.width - rad, self.y + self.height - rad, rad)
    elseif self.cornerStyle == "cut" then
        -- Cut corners
        local c = self.cornerSize
        local points = {
            self.x + c, self.y,
            self.x + self.width - c, self.y,
            self.x + self.width, self.y + c,
            self.x + self.width, self.y + self.height - c,
            self.x + self.width - c, self.y + self.height,
            self.x + c, self.y + self.height,
            self.x, self.y + self.height - c,
            self.x, self.y + c
        }
        love.graphics.polygon("fill", points)
    else
        -- Square
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
    
    -- Draw border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(self.borderWidth)
    
    if self.cornerStyle == "rounded" then
        local r = self.cornerSize
        local segments = 16
        love.graphics.arc("line", "open", self.x + r, self.y + r, r, math.pi, math.pi * 1.5, segments)
        love.graphics.line(self.x + r, self.y, self.x + self.width - r, self.y)
        love.graphics.arc("line", "open", self.x + self.width - r, self.y + r, r, math.pi * 1.5, 0, segments)
        love.graphics.line(self.x + self.width, self.y + r, self.x + self.width, self.y + self.height - r)
        love.graphics.arc("line", "open", self.x + self.width - r, self.y + self.height - r, r, 0, math.pi * 0.5, segments)
        love.graphics.line(self.x + self.width - r, self.y + self.height, self.x + r, self.y + self.height)
        love.graphics.arc("line", "open", self.x + r, self.y + self.height - r, r, math.pi * 0.5, math.pi, segments)
        love.graphics.line(self.x, self.y + self.height - r, self.x, self.y + r)
    elseif self.cornerStyle == "cut" then
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
        love.graphics.rectangle("line", 
            self.x + self.borderWidth/2, 
            self.y + self.borderWidth/2, 
            self.width - self.borderWidth, 
            self.height - self.borderWidth
        )
    end
    
    -- Render label
    love.graphics.setColor(r, g, b, a)
    if self._labelComponent then
        self._labelComponent:render()
    end

    if DEBUG_UI then
        print(string.format("[UI DRAW] Button:render id=%s label='%s' hovered=%s pressed=%s", tostring(self.id), tostring(self.label), tostring(self.hovered), tostring(self.pressed)))
    end
    
    -- Restore state
    love.graphics.setLineWidth(lineWidth)
    love.graphics.setColor(r, g, b, a)
end

-- Override mouse events to handle button interactions
function Button:onMouseMove(x, y)
    local result = Box.onMouseMove(self, x, y)
    
    -- Fire custom callbacks
    if self.hovered and self.onHoverEnter then
        self.onHoverEnter(self)
    elseif not self.hovered and self.onHoverLeave then
        self.onHoverLeave(self)
    end
    
    return result
end

return Button
