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

-- Mock UI Components for testing
local function createMockUIComponents()
    -- Mock Component base class
    local MockComponent = {
        new = function(props)
            return {
                visible = true,
                children = {},
                addChild = function(self, child) table.insert(self.children, child) end,
                clearChildren = function(self) self.children = {} end,
                setText = function(self, text) self.text = text end
            }
        end
    }
    
    -- Mock specific components
    local MockPanel = setmetatable({}, {__index = MockComponent})
    MockPanel.new = function(props) 
        local self = MockComponent.new(props)
        setmetatable(self, {__index = MockPanel})
        return self
    end
    
    local MockText = setmetatable({}, {__index = MockComponent})
    MockText.new = function(props) 
        local self = MockComponent.new(props)
        setmetatable(self, {__index = MockText})
        return self
    end
    
    local MockBox = setmetatable({}, {__index = MockComponent})
    MockBox.new = function(props) 
        local self = MockComponent.new(props)
        setmetatable(self, {__index = MockBox})
        return self
    end
    
    local MockGrid = setmetatable({}, {__index = MockComponent})
    MockGrid.new = function(props) 
        local self = MockComponent.new(props)
        setmetatable(self, {__index = MockGrid})
        return self
    end
    
    return {
        Component = MockComponent,
        Panel = MockPanel,
        Text = MockText,
        Box = MockBox,
        Grid = MockGrid
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

-- Create mock UI components
local mockUI = createMockUIComponents()

-- Make components globally available for require() calls
package.preload["src.ui.components.component"] = function() return mockUI.Component end
package.preload["src.ui.components.panel"] = function() return mockUI.Panel end
package.preload["src.ui.components.text"] = function() return mockUI.Text end
package.preload["src.ui.components.box"] = function() return mockUI.Box end
package.preload["src.ui.components.grid"] = function() return mockUI.Grid end

return {
    filesystem = love.filesystem,
    timer = love.timer,
    graphics = love.graphics,
    ui = mockUI
}
