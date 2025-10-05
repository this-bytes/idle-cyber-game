-- Lovely Toast Wrapper
-- Provides compatibility layer between old ToastManager API and Lovely-Toasts library
-- Maintains the same API surface while using community-maintained toast system

local lovelyToasts = require("lib.lovely-toasts.lovelyToasts")

local ToastWrapper = {}
ToastWrapper.__index = ToastWrapper

-- Type mapping from old system to Lovely-Toasts positioning
local TYPE_CONFIG = {
    info = {
        position = "top",
        style = "info"
    },
    success = {
        position = "top", 
        style = "success"
    },
    warning = {
        position = "middle",
        style = "warning"
    },
    error = {
        position = "middle",
        style = "error"
    }
}

function ToastWrapper.new()
    local self = setmetatable({}, ToastWrapper)
    
    -- Configure Lovely-Toasts styling to match game theme
    lovelyToasts.style.backgroundColor = {0.1, 0.15, 0.2, 0.95}
    lovelyToasts.style.textColor = {0.9, 0.9, 0.95, 1.0}
    lovelyToasts.style.paddingLR = 20
    lovelyToasts.style.paddingTB = 15
    
    -- Set MSAA-friendly rendering (if not already set in conf.lua)
    -- lovelyToasts requires MSAA for best appearance
    
    -- Configure options
    lovelyToasts.options.tapToDismiss = false -- Match old behavior
    lovelyToasts.options.queueEnabled = true  -- Allow multiple toasts
    lovelyToasts.options.animationDuration = 0.3
    
    print("🍞 Lovely Toast Wrapper initialized")
    
    return self
end

-- Show a toast notification (compatible with old ToastManager API)
function ToastWrapper:show(message, options)
    options = options or {}
    
    -- Handle both old and new API styles
    -- Old: show(message, {type = "success", duration = 3.0})
    -- New: show(message, duration, position)
    
    local toastType = options.type or "info"
    local duration = options.duration or 3.0
    local config = TYPE_CONFIG[toastType] or TYPE_CONFIG.info
    local position = options.position or config.position
    
    -- Show the toast using Lovely-Toasts
    lovelyToasts.show(message, duration, position)
    
    return true
end

-- Shortcut methods for common toast types (backward compatibility)
function ToastWrapper:info(message, duration)
    return self:show(message, {type = "info", duration = duration})
end

function ToastWrapper:success(message, duration)
    return self:show(message, {type = "success", duration = duration})
end

function ToastWrapper:warning(message, duration)
    return self:show(message, {type = "warning", duration = duration})
end

function ToastWrapper:error(message, duration)
    return self:show(message, {type = "error", duration = duration})
end

-- Dismiss method (Lovely-Toasts doesn't support direct dismissal by ID)
-- This is a no-op for compatibility.
-- NOTE: This method always returns false because Lovely-Toasts does not support manual dismissal of toasts by ID.
-- If your code relies on dismiss() returning true for successful dismissal, you must implement your own tracking or switch to a toast library that supports this feature.
function ToastWrapper:dismiss(toastId)
    -- Lovely-Toasts handles dismissal automatically
    -- Manual dismissal not supported by library
    return false
end

-- Update toasts (delegates to Lovely-Toasts)
function ToastWrapper:update(dt)
    lovelyToasts.update(dt)
end

-- Draw toasts (delegates to Lovely-Toasts)
function ToastWrapper:draw()
    lovelyToasts.draw()
end

-- Mouse release handler for tap-to-dismiss (if enabled)
function ToastWrapper:mousereleased(x, y, button)
    if lovelyToasts.options.tapToDismiss then
        lovelyToasts.mousereleased(x, y, button)
    end
end

-- Touch release handler for mobile tap-to-dismiss (if enabled)
function ToastWrapper:touchreleased(id, x, y, dx, dy, pressure)
    if lovelyToasts.options.tapToDismiss then
        lovelyToasts.touchreleased(id, x, y, dx, dy, pressure)
    end
end

-- Configure canvas size for scaled rendering (e.g., with TLfres)
function ToastWrapper:setCanvasSize(width, height)
    lovelyToasts.canvasSize = {width, height}
end

-- Direct access to underlying Lovely-Toasts library for advanced usage
function ToastWrapper:getLovelyToasts()
    return lovelyToasts
end

return ToastWrapper
