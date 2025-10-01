-- Integration Demo Main Entry Point
-- Run with: love integration_demo_dir

local IntegrationDemo = require("integration_demo")
local demo

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    
    demo = IntegrationDemo.new()
    print("🎨 Smart UI Integration Demo loaded!")
end

function love.update(dt)
    if demo then
        demo:update(dt)
    end
end

function love.draw()
    if demo then
        demo:draw()
    end
end

function love.mousepressed(x, y, button)
    if demo then
        demo:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if demo and demo.mousereleased then
        demo:mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if demo and demo.mousemoved then
        demo:mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(x, y)
    if demo and demo.wheelmoved then
        demo:wheelmoved(x, y)
    end
end

function love.keypressed(key)
    if demo then
        demo:keypressed(key)
    end
end

function love.quit()
    print("👋 Thanks for viewing the Smart UI Demo!")
end
