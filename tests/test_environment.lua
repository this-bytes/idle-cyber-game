-- Test environment setup with mock LÖVE 2D functions
-- Provides compatibility layer for testing fortress architecture

local testEnv = {}

-- Mock love.timer functions
local mockTimer = {
    currentTime = 0
}

function mockTimer.getTime()
    return mockTimer.currentTime
end

function mockTimer.step(dt) 
    mockTimer.currentTime = mockTimer.currentTime + dt
end

-- Mock love.graphics functions
local mockGraphics = {
    width = 1024,
    height = 768
}

function mockGraphics.getWidth()
    return mockGraphics.width
end

function mockGraphics.getHeight() 
    return mockGraphics.height
end

function mockGraphics.getDimensions()
    return mockGraphics.width, mockGraphics.height
end

function mockGraphics.setColor() end
function mockGraphics.rectangle() end
function mockGraphics.print() end
function mockGraphics.getFont()
    return {
        getWidth = function(text) return #text * 8 end,
        getHeight = function() return 12 end
    }
end

-- Set up global love table for testing
function testEnv.setup()
    if not love then
        _G.love = {
            timer = mockTimer,
            graphics = mockGraphics
        }
    end
end

-- Clean up test environment
function testEnv.cleanup()
    -- Leave love table for other tests
end

-- Advance mock time
function testEnv.advanceTime(dt)
    mockTimer.step(dt)
end

return testEnv
