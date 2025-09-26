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
    -- Try the exact path first
    if love.filesystem.getInfo(path) then
        local ok, img = pcall(function() return love.graphics.newImage(path) end)
        if ok and img then return img end
    end

    -- If path has an extension, try common alternatives (png, jpeg, jpg)
    local alternatives = {}
    local base, ext = string.match(path, "^(.*)%.([^.]+)$")
    if base and ext then
        alternatives = { base .. ".png", base .. ".jpeg", base .. ".jpg" }
    else
        alternatives = { path .. ".png", path .. ".jpeg", path .. ".jpg" }
    end

    for _, p in ipairs(alternatives) do
        if love.filesystem.getInfo(p) then
            local ok, img = pcall(function() return love.graphics.newImage(p) end)
            if ok and img then return img end
        end
    end

    return nil
end

-- Fallback to embedded placeholders
local PlaceholderAssets = nil
local function getPlaceholders()
    if not PlaceholderAssets then
        local ok, mod = pcall(require, "src.ui.asset_placeholders")
        if ok and mod then PlaceholderAssets = mod end
    end
    return PlaceholderAssets
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

function OfficeMap:draw(player, departments, opts)
    -- Draw background panel
    -- Draw background (image first if available)
    if not self.officeBgTried then
        -- Try to load an office background image (png/jpeg/jpg)
        self.officeBg = tryLoadImage("assets/office.png") or tryLoadImage("assets/office.jpeg") or tryLoadImage("assets/office.jpg")
        self.officeBgTried = true
        if self.officeBg then
            -- Cache scale later when drawing
            self.officeBgW = self.officeBg:getWidth()
            self.officeBgH = self.officeBg:getHeight()
        end
    end

    if self.officeBg then
        love.graphics.setColor(1,1,1,1)
        -- Cover background into the panel while preserving aspect (may crop)
        local scale = math.max(self.width / self.officeBgW, self.height / self.officeBgH)
        local imgW = self.officeBgW * scale
        local imgH = self.officeBgH * scale
        love.graphics.draw(self.officeBg, (self.width - imgW) / 2, (self.height - imgH) / 2, 0, scale, scale)
    else
        love.graphics.setColor(self.bgColor)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height, 6, 6)
    end

    -- Always draw subtle grid
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

    -- Debug outline if requested
    if opts and opts.debug then
        love.graphics.setColor(1,0,0,0.2)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 1, 1, self.width - 2, self.height - 2, 6, 6)
    end
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
                -- Try to load embedded placeholders first
                local placeholders = getPlaceholders()
                if placeholders then
                    local pPlayer, pDept = placeholders.getImages()
                    if pDept and pPlayer then
                        self.deptSprite = pDept
                        self.deptSpriteSize = math.max(pDept:getWidth(), pDept:getHeight())
                        self.playerSprite = pPlayer
                        self.playerSpriteSize = math.max(pPlayer:getWidth(), pPlayer:getHeight())
                    else
                        local fillColor = {0.15, 0.15, 0.18, 1}
                        local innerColor = {0.9, 0.9, 0.95, 1}
                        self.deptSprite, self.deptSpriteSize = makeCircleSprite(28, fillColor, innerColor)
                        self.playerSprite, self.playerSpriteSize = makeCircleSprite(14, {0.1,0.6,1,1}, {0.8,0.95,1,1})
                    end
                else
                    local fillColor = {0.15, 0.15, 0.18, 1}
                    local innerColor = {0.9, 0.9, 0.95, 1}
                    self.deptSprite, self.deptSpriteSize = makeCircleSprite(28, fillColor, innerColor)
                    self.playerSprite, self.playerSpriteSize = makeCircleSprite(14, {0.1,0.6,1,1}, {0.8,0.95,1,1})
                end
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

    -- Debug overlays: draw department proximity ranges if opts.debug is true
    local debug = opts and opts.debug
    if debug and departments then
        love.graphics.setLineWidth(1)
        for _, dept in ipairs(departments) do
            -- Proximity circle (semi-transparent)
            love.graphics.setColor(1, 0.2, 0.2, 0.25)
            love.graphics.circle("fill", dept.x, dept.y, dept.radius + (dept.proximity or 0))
            love.graphics.setColor(1, 0.2, 0.2, 0.9)
            love.graphics.circle("line", dept.x, dept.y, dept.radius + (dept.proximity or 0))
            -- Numeric range label
            local rangeVal = math.floor((dept.proximity or 0) + dept.radius)
            local label = "Range: " .. tostring(rangeVal) .. "px"
            local lx = dept.x + (dept.radius or 0) + 8
            local ly = dept.y - (dept.radius or 0) - 8
            love.graphics.setColor(1,1,1,0.95)
            love.graphics.printf(label, lx, ly, 120, "left")
        end
        love.graphics.setColor(1,1,1,1)
    end
end

return OfficeMap
