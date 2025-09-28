-- Simple selectable UI component helper
local Selectable = {}
Selectable.__index = Selectable

function Selectable.new(id, x, y, w, h, label, onSelect)
    local self = setmetatable({}, Selectable)
    self.id = id
    self.x = x or 0
    self.y = y or 0
    self.w = w or 32
    self.h = h or 32
    self.label = label or ""
    self.onSelect = onSelect
    self.focused = false
    return self
end

function Selectable:containsPoint(px, py)
    return px >= self.x and px <= self.x + self.w and py >= self.y and py <= self.y + self.h
end

function Selectable:draw(uiManager)
    local colors = uiManager and uiManager.colors or {panel={0.15,0.15,0.2,1}, accent={0.2,0.8,0.9,1}, text={0.9,0.9,0.95,1}}
    -- Simple visual: border changes when focused
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    if self.focused then
        love.graphics.setColor(colors.accent)
    else
        love.graphics.setColor(colors.border or {0.3,0.4,0.5,1})
    end
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.setColor(colors.text)
    if self.label and #self.label > 0 then
        love.graphics.print(self.label, self.x + 4, self.y + 4)
    end
end

function Selectable:activate()
    if type(self.onSelect) == "function" then
        self.onSelect(self)
    end
end

return Selectable
