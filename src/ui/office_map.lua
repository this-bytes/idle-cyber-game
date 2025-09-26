-- Office Map UI
-- Draws a simple office floorplan with department "sprites" and player sprite

local OfficeMap = {}
OfficeMap.__index = OfficeMap

function OfficeMap.new(width, height)
    local self = setmetatable({}, OfficeMap)
    self.width = width or 640
    self.height = height or 200

    -- Decoration colours
    self.bgColor = {0.02, 0.02, 0.03, 0.95}
    self.gridColor = {0.06, 0.12, 0.1, 0.6}
    self.wallColor = {0.12, 0.18, 0.24, 1}

    -- Department sprite style (simple shapes and icons)
    self.departmentStyle = {
        radius = 24,
        fill = {0.15, 0.15, 0.18, 1},
        textColor = {1,1,1,1}
    }

    return self
end

-- Attempt to load external assets if available
local function tryLoadImage(path)
    if love.filesystem.getInfo(path) then
        local ok, img = pcall(function() return love.graphics.newImage(path) end)
        if ok and img then return img end
    end
    return nil
end

-- Helper to create a simple circular sprite on a Canvas
local function makeCircleSprite(radius, fillColor, innerColor)
    local size = math.ceil(radius * 2)
    local canvas = love.graphics.newCanvas(size, size)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Shadow
    love.graphics.setColor(0,0,0,0.35)
    love.graphics.circle("fill", radius + 2, radius + 3, radius + 2)
    -- Outer
    love.graphics.setColor(fillColor)
    love.graphics.circle("fill", radius, radius, radius)
    -- Inner
    love.graphics.setColor(innerColor)
    love.graphics.circle("fill", radius, radius, math.max(1, radius - 8))
    love.graphics.setCanvas()
    return canvas, size
end

-- Draw helper for a department node
function OfficeMap:drawDepartment(dept)
    local style = self.departmentStyle
    -- Use sprite if available
    if self.deptSprite then
        local s = self.deptSpriteSize
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(self.deptSprite, dept.x - s/2, dept.y - s/2)
    else
        -- Fallback to primitive drawing
        love.graphics.setColor(0,0,0,0.35)
        love.graphics.circle("fill", dept.x + 3, dept.y + 4, dept.radius + 2)
        love.graphics.setColor(style.fill)
        love.graphics.circle("fill", dept.x, dept.y, dept.radius)
        love.graphics.setColor(0.9, 0.9, 0.95, 1)
        love.graphics.circle("fill", dept.x, dept.y, dept.radius - 10)
    end

    -- Label
    love.graphics.setColor(style.textColor)
    love.graphics.printf(dept.label or dept.name or "", dept.x - dept.radius - 10, dept.y + dept.radius + 6, dept.radius*2 + 20, "center")
end

-- Draw player sprite at player.x, player.y
function OfficeMap:drawPlayer(player)
    if self.playerSprite then
        local s = self.playerSpriteSize
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(self.playerSprite, player.x - s/2, player.y - s/2)
    else
        -- Shadow
        love.graphics.setColor(0,0,0,0.4)
        love.graphics.circle("fill", player.x + 4, player.y + 6, player.size + 4)
        -- Body
        love.graphics.setColor(0.1, 0.6, 1, 1)
        love.graphics.circle("fill", player.x, player.y, player.size)
        love.graphics.setColor(0.8, 0.95, 1, 0.9)
        love.graphics.circle("line", player.x, player.y, player.size + 2)
    end
    -- Optional indicator
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.printf("You", player.x - 20, player.y - player.size - 16, 40, "center")
end

function OfficeMap:draw(player, departments)
    -- Draw background panel
    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height, 6, 6)

    -- Draw subtle grid
    love.graphics.setColor(self.gridColor)
    local spacing = 32
    for gx = 0, self.width, spacing do
        love.graphics.line(gx, 0, gx, self.height)
    end
    for gy = 0, self.height, spacing do
        love.graphics.line(0, gy, self.width, gy)
    end

    -- Draw walls / border
    love.graphics.setColor(self.wallColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 2, 2, self.width - 4, self.height - 4, 6, 6)

    -- Draw departments if provided, otherwise draw default placeholders
    if departments then
        -- Create sprites lazily if possible
        if not self.deptSprite then
            -- First try to load external images from assets/
            local deptImg = tryLoadImage("assets/department.png")
            local playerImg = tryLoadImage("assets/player.png")
            if deptImg and playerImg then
                self.deptSprite = deptImg
                self.deptSpriteSize = math.max(deptImg:getWidth(), deptImg:getHeight())
                self.playerSprite = playerImg
                self.playerSpriteSize = math.max(playerImg:getWidth(), playerImg:getHeight())
            else
                -- Fallback to procedural canvases
                local fillColor = {0.15, 0.15, 0.18, 1}
                local innerColor = {0.9, 0.9, 0.95, 1}
                self.deptSprite, self.deptSpriteSize = makeCircleSprite(28, fillColor, innerColor)
                self.playerSprite, self.playerSpriteSize = makeCircleSprite(14, {0.1,0.6,1,1}, {0.8,0.95,1,1})
            end
        end
        for _, dept in ipairs(departments) do
            self:drawDepartment(dept)
        end
    end

    -- Draw the player
    if player then
        self:drawPlayer(player)
    end
end

return OfficeMap
