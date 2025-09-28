-- Cyber Empire Command - Cybersecurity Idle Game
-- Unified Main Entry Point with Dynamic Data-Driven Architecture
-- This is the single entry point for the idle cybersecurity game

-- Import the unified game controller
local IdleGame = require("src.idle_game")

-- Global game instance
local game

-- LÖVE 2D callback functions
function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("🏰 Cyber Empire Command - Idle Cybersecurity Tycoon")
    
    -- Set window size for optimal dashboard display
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    -- Set up clean monospace font for cybersecurity theme
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    
    -- Initialize the unified idle game
    game = IdleGame.new()
    local success = game:initialize()
    
    if success then
        print("🚀 Cyber Empire Command loaded successfully!")
    else
        print("❌ Failed to initialize game")
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
        love.graphics.print("Game not initialized", 10, 10)
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
    print("🏰 Thanks for playing Cyber Empire Command!")
end