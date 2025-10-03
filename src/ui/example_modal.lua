local ExampleModal = {}
ExampleModal.__index = ExampleModal

function ExampleModal.new(title, width, height)
    local self = setmetatable({}, ExampleModal)
    self.title = title or "Modal"
    self.width = width or 400
    self.height = height or 200
    self.visible = false
    return self
end

function ExampleModal:enter()
    self.visible = true
end

function ExampleModal:exit()
    self.visible = false
end

function ExampleModal:update(dt) end

function ExampleModal:draw()
    if not self.visible then return end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    love.graphics.setColor(0,0,0,0.6)
    love.graphics.rectangle('fill', 0,0,w,h)
    love.graphics.setColor(0.2,0.2,0.25,1)
    local x = (w - self.width)/2
    local y = (h - self.height)/2
    love.graphics.rectangle('fill', x, y, self.width, self.height, 6,6)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(self.title, x + 12, y + 12)
end

function ExampleModal:mousepressed(x,y,button)
    if not self.visible then return false end
    -- Click anywhere closes modal
    self.visible = false
    return true
end

function ExampleModal:keypressed(key)
    if not self.visible then return false end
    if key == 'escape' then
        self.visible = false
        return true
    end
    return true
end

return ExampleModal
