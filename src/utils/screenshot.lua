-- Screenshot Utility for UI Development
-- Captures ONLY the game window (not entire screen) for privacy
-- Usage: Press F12 to capture screenshot

local Screenshot = {}

function Screenshot.new()
    local self = {}
    
    self.screenshotDir = "screenshots"
    self.enabled = true
    
    -- Create screenshots directory if it doesn't exist
    local success = love.filesystem.createDirectory(self.screenshotDir)
    if success then
        print("Screenshot directory created: " .. love.filesystem.getSaveDirectory() .. "/" .. self.screenshotDir)
    end
    
    return self
end

-- Capture the current frame buffer
function Screenshot:capture()
    if not self.enabled then return end
    
    -- Get canvas/screen data
    local canvas = love.graphics.getCanvas()
    local imageData = love.graphics.readbackTexture(love.graphics.newCanvas(love.graphics.getDimensions()))
    
    -- Generate filename with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("%s/screenshot_%s.png", self.screenshotDir, timestamp)
    
    -- Save the screenshot
    local success = imageData:encode("png", filename)
    
    if success then
        local fullPath = love.filesystem.getSaveDirectory() .. "/" .. filename
        print("Screenshot saved: " .. fullPath)
        return fullPath
    else
        print("Failed to save screenshot")
        return nil
    end
end

-- Alternative method using Canvas for better quality
function Screenshot:captureCanvas()
    if not self.enabled then return end
    
    local width, height = love.graphics.getDimensions()
    
    -- Create a canvas to render to
    local canvas = love.graphics.newCanvas(width, height)
    
    -- Set canvas as render target
    love.graphics.setCanvas(canvas)
    
    -- Re-render the current frame (this needs to be called from your main render function)
    -- For now, just capture what's currently in the buffer
    love.graphics.setCanvas()
    
    -- Get image data from canvas
    local imageData = canvas:newImageData()
    
    -- Generate filename
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("%s/screenshot_%s.png", self.screenshotDir, timestamp)
    
    -- Save
    local thread = love.thread.newThread([[
        local imageData, filename = ...
        imageData:encode("png", filename)
    ]])
    
    thread:start(imageData, filename)
    
    local fullPath = love.filesystem.getSaveDirectory() .. "/" .. filename
    print("Screenshot saved: " .. fullPath)
    
    return fullPath
end

-- Simple capture method (most reliable)
function Screenshot:captureSimple()
    if not self.enabled then return end
    
    -- Capture screen to image data
    love.graphics.captureScreenshot(function(imageData)
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local filename = string.format("%s/screenshot_%s.png", self.screenshotDir, timestamp)
        
        imageData:encode("png", filename)
        
        local fullPath = love.filesystem.getSaveDirectory() .. "/" .. filename
        print("Screenshot saved: " .. fullPath)
        print("  " .. fullPath)
    end)
end

-- Keypressed handler (call from love.keypressed)
function Screenshot:keypressed(key)
    if key == "f12" then
        self:captureSimple()
        return true
    end
    return false
end

return Screenshot
