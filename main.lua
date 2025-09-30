-- Idle Sec Ops - Cybersecurity Idle Game
-- This is the single entry point for the game.

-- Global game instance
local game

function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("🛡️ SOC Command Center - Cybersecurity Operations Simulator")
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)

    -- Create and initialize the main game object
    local EventBus = require("src.utils.event_bus"):new()
    local SOCGame = require("src.soc_game")
    game = SOCGame.new(EventBus)
    
    local success, err = pcall(function() game:initialize() end)
    
    if success then
        print("🚀 Game loaded successfully!")
    else
        print("❌❌❌ FATAL ERROR DURING INITIALIZATION ❌❌❌")
        print(err)
        -- In a real build, you might switch to an error scene here.
    end
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    else
        love.graphics.printf("Error during initialization. Check console.", 0, 10, love.graphics.getWidth(), "center")
    end
end

function love.keypressed(key)
    if game then
        game:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if game then
        game:mousepressed(x, y, button)
    end
end

function love.resize(w, h)
    if game then
        game:resize(w, h)
    end
end

function love.quit()
    if game then
        game:shutdown()
    end
    print("🛡️ Thanks for operating the SOC Command Center!")
end