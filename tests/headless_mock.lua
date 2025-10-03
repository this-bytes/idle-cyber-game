#!/usr/bin/env lua
-- Headless Mock Environment for Testing
-- Provides mock LÖVE functions for headless test execution

-- Mock love.filesystem
local function createMockFilesystem()
    return {
        getInfo = function(path)
            -- Check if file exists using standard Lua io
            local file = io.open(path, "r")
            if file then
                file:close()
                return {type = "file"}
            end
            return nil
        end,
        
        read = function(path)
            local file = io.open(path, "r")
            if file then
                local content = file:read("*a")
                file:close()
                return content
            end
            return nil
        end,
        
        write = function(path, content)
            local file = io.open(path, "w")
            if file then
                file:write(content)
                file:close()
                return true
            end
            return false
        end,
        
        getDirectoryItems = function(dir)
            -- Use ls command to list directory
            local handle = io.popen("ls " .. dir .. " 2>/dev/null")
            if not handle then
                return nil, "Failed to list directory"
            end
            
            local result = handle:read("*a")
            handle:close()
            
            local items = {}
            for item in result:gmatch("[^\n]+") do
                table.insert(items, item)
            end
            
            return items
        end
    }
end

-- Mock love.timer
local function createMockTimer()
    local startTime = os.clock()
    return {
        getTime = function()
            return os.clock() - startTime
        end,
        
        getFPS = function()
            return 60
        end
    }
end

-- Mock love.graphics (minimal, for tests that don't actually render)
local function createMockGraphics()
    return {
        newFont = function(size)
            return {getWidth = function(text) return #text * 8 end}
        end,
        
        setFont = function() end,
        setColor = function() end,
        print = function() end,
        printf = function() end,
        rectangle = function() end,
        clear = function() end,
        getWidth = function() return 1024 end,
        getHeight = function() return 768 end
    }
end

-- Initialize global love table for headless mode
if not love then
    love = {
        filesystem = createMockFilesystem(),
        timer = createMockTimer(),
        graphics = createMockGraphics()
    }
end

return {
    filesystem = love.filesystem,
    timer = love.timer,
    graphics = love.graphics
}
