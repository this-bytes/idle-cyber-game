-- Toast Notification Manager - Smart UI Framework
-- Manages stacked toast notifications with animations and auto-dismiss
-- Implements Phase 4 of Smart UI Framework: Toast Notifications

local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Box = require("src.ui.components.box")

local ToastManager = {}
ToastManager.__index = ToastManager

-- Toast types with associated colors and icons
local TOAST_TYPES = {
    info = {
        color = {0.2, 0.8, 1.0, 1.0},
        icon = "ℹ",
        borderColor = {0.2, 0.8, 1.0, 1.0}
    },
    success = {
        color = {0.2, 0.8, 0.4, 1.0},
        icon = "✓",
        borderColor = {0.2, 0.8, 0.4, 1.0}
    },
    warning = {
        color = {1.0, 0.8, 0.2, 1.0},
        icon = "⚠",
        borderColor = {1.0, 0.8, 0.2, 1.0}
    },
    error = {
        color = {1.0, 0.4, 0.2, 1.0},
        icon = "✗",
        borderColor = {1.0, 0.4, 0.2, 1.0}
    }
}

function ToastManager.new()
    local self = setmetatable({}, ToastManager)
    
    -- Toast queue
    self.toasts = {}
    self.nextId = 1
    
    -- Display configuration
    self.maxToasts = 5
    self.toastWidth = 300
    self.toastHeight = 60
    self.padding = 10
    self.position = "top-right" -- top-right, top-left, bottom-right, bottom-left
    
    -- Animation settings
    self.slideInDuration = 0.3
    self.fadeOutDuration = 0.5
    
    return self
end

-- Show a toast notification
function ToastManager:show(message, options)
    options = options or {}
    
    local toast = {
        id = self.nextId,
        message = message,
        type = options.type or "info",
        duration = options.duration or 3.0,
        icon = options.icon,
        
        -- Animation state
        elapsed = 0,
        state = "sliding-in", -- sliding-in, visible, fading-out, dismissed
        alpha = 0,
        slideOffset = self.toastWidth,
        
        -- Component (created on first render)
        component = nil
    }
    
    self.nextId = self.nextId + 1
    table.insert(self.toasts, toast)
    
    -- Remove oldest toasts if we exceed max
    while #self.toasts > self.maxToasts do
        table.remove(self.toasts, 1)
    end
    
    return toast.id
end

-- Dismiss a specific toast by ID
function ToastManager:dismiss(toastId)
    for i, toast in ipairs(self.toasts) do
        if toast.id == toastId then
            if toast.state ~= "fading-out" and toast.state ~= "dismissed" then
                toast.state = "fading-out"
                toast.fadeStartTime = toast.elapsed
            end
            return true
        end
    end
    return false
end

-- Create UI component for a toast
function ToastManager:createToastComponent(toast)
    local typeInfo = TOAST_TYPES[toast.type] or TOAST_TYPES.info
    
    -- Main container
    local container = Box.new({
        direction = "horizontal",
        align = "center",
        gap = 10,
        padding = {10, 15, 10, 15},
        backgroundColor = {0.1, 0.1, 0.15, 0.95},
        borderColor = typeInfo.borderColor,
        borderWidth = 2,
        cornerRadius = 4
    })
    
    -- Icon text
    local icon = toast.icon or typeInfo.icon
    local iconText = Text.new({
        text = icon,
        color = typeInfo.color,
        fontSize = 20,
        minWidth = 20
    })
    container:addChild(iconText)
    
    -- Message text
    local messageText = Text.new({
        text = toast.message,
        color = {0.9, 0.9, 0.9, 1.0},
        wrap = true,
        maxLines = 2,
        flex = 1
    })
    container:addChild(messageText)
    
    return container
end

-- Update toast animations
function ToastManager:update(dt)
    local toastsToRemove = {}
    
    for i, toast in ipairs(self.toasts) do
        toast.elapsed = toast.elapsed + dt
        
        if toast.state == "sliding-in" then
            -- Slide in animation
            local progress = math.min(1.0, toast.elapsed / self.slideInDuration)
            toast.slideOffset = self.toastWidth * (1 - progress)
            toast.alpha = progress
            
            if progress >= 1.0 then
                toast.state = "visible"
                toast.visibleStartTime = toast.elapsed
            end
            
        elseif toast.state == "visible" then
            toast.alpha = 1.0
            toast.slideOffset = 0
            
            -- Check if duration expired
            local visibleTime = toast.elapsed - (toast.visibleStartTime or 0)
            if visibleTime >= toast.duration then
                toast.state = "fading-out"
                toast.fadeStartTime = toast.elapsed
            end
            
        elseif toast.state == "fading-out" then
            -- Fade out animation
            local fadeTime = toast.elapsed - (toast.fadeStartTime or toast.elapsed)
            local progress = math.min(1.0, fadeTime / self.fadeOutDuration)
            toast.alpha = 1.0 - progress
            
            if progress >= 1.0 then
                toast.state = "dismissed"
                table.insert(toastsToRemove, i)
            end
        end
    end
    
    -- Remove dismissed toasts (in reverse to maintain indices)
    for i = #toastsToRemove, 1, -1 do
        table.remove(self.toasts, toastsToRemove[i])
    end
end

-- Render all toasts
function ToastManager:render()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate position based on configuration
    local startX, startY
    if self.position == "top-right" then
        startX = screenWidth - self.toastWidth - self.padding
        startY = self.padding
    elseif self.position == "top-left" then
        startX = self.padding
        startY = self.padding
    elseif self.position == "bottom-right" then
        startX = screenWidth - self.toastWidth - self.padding
        startY = screenHeight - self.padding
    elseif self.position == "bottom-left" then
        startX = self.padding
        startY = screenHeight - self.padding
    end
    
    -- Render each toast
    local currentY = startY
    for i, toast in ipairs(self.toasts) do
        if toast.state ~= "dismissed" then
            -- Create component if needed
            if not toast.component then
                toast.component = self:createToastComponent(toast)
            end
            
            -- Apply slide offset and alpha
            local x = startX + toast.slideOffset
            local y = currentY
            
            -- Measure and layout component
            toast.component:measure(self.toastWidth, self.toastHeight)
            toast.component:layout(x, y, self.toastWidth, self.toastHeight)
            
            -- Render with alpha
            love.graphics.push()
            love.graphics.setColor(1, 1, 1, toast.alpha)
            toast.component:render()
            love.graphics.pop()
            
            -- Move down for next toast
            if self.position:find("top") then
                currentY = currentY + self.toastHeight + self.padding
            else
                currentY = currentY - self.toastHeight - self.padding
            end
        end
    end
end

-- Handle mouse events
function ToastManager:mousepressed(x, y, button)
    -- Allow clicking on toasts to dismiss them
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local startX, startY
    if self.position == "top-right" then
        startX = screenWidth - self.toastWidth - self.padding
        startY = self.padding
    elseif self.position == "top-left" then
        startX = self.padding
        startY = self.padding
    elseif self.position == "bottom-right" then
        startX = screenWidth - self.toastWidth - self.padding
        startY = screenHeight - self.padding
    elseif self.position == "bottom-left" then
        startX = self.padding
        startY = screenHeight - self.padding
    end
    
    local currentY = startY
    for i, toast in ipairs(self.toasts) do
        if toast.state ~= "dismissed" then
            local toastX = startX + toast.slideOffset
            local toastY = currentY
            
            -- Check if click is within toast bounds
            if x >= toastX and x <= toastX + self.toastWidth and
               y >= toastY and y <= toastY + self.toastHeight then
                self:dismiss(toast.id)
                return true
            end
            
            -- Move to next toast position
            if self.position:find("top") then
                currentY = currentY + self.toastHeight + self.padding
            else
                currentY = currentY - self.toastHeight - self.padding
            end
        end
    end
    
    return false
end

return ToastManager
