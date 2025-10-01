-- SMART UI FRAMEWORK - STANDALONE DEMO
-- Run with: love demo_ui.lua

local UIDemo = require("src.ui.ui_demo")
local Screenshot = require("src.utils.screenshot")

local demo
local windowWidth, windowHeight
local screenshot

function love.load()
    -- Configure window
    love.window.setTitle("Smart UI Framework Demo - Idle Sec Ops")
    love.window.setMode(1024, 768, {
        resizable = true,  -- Allow resizing
        vsync = true,
        minwidth = 800,
        minheight = 600
    })
    
    -- Set up graphics
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1, 1)
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Get initial window size
    windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Create screenshot utility
    screenshot = Screenshot.new()
    
    -- Create demo
    demo = UIDemo.new()
    demo:init(windowWidth, windowHeight)
    
    print("=== Smart UI Framework Demo ===")
    print("Hover over buttons to see hover effects")
    print("Click buttons to trigger callbacks (check console)")
    print("Scroll with mouse wheel if content overflows")
    print("Press F12 to capture screenshot")
    print("All layouts are automatically calculated!")
end

function love.resize(w, h)
    windowWidth, windowHeight = w, h
    if demo then
        demo:resize(w, h)
    end
end

function love.update(dt)
    if demo then
        demo:update(dt)
    end
end

function love.draw()
    if demo then
        demo:render()
    end
    
    -- Draw info overlay
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.print("Smart UI Framework v1.0 | FPS: " .. love.timer.getFPS(), 10, 10)
    
    local mouseX, mouseY = love.mouse.getPosition()
    love.graphics.print(string.format("Mouse: (%d, %d)", mouseX, mouseY), 10, 30)
end

function love.mousemoved(x, y, dx, dy, istouch)
    if demo then
        demo:mouseMoved(x, y)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if demo then
        demo:mousePressed(x, y, button)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if demo then
        demo:mouseReleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if demo then
        demo:mouseWheel(x, y)
    end
end

function love.keypressed(key)
    -- Screenshot capture
    if screenshot and screenshot:keypressed(key) then
        return
    end
    
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        -- Reload demo
        love.load()
    end
end
