-- Idle Sec Ops - Cybersecurity Idle Game
-- SOC-Focused Entry Point with Systematic Refactor Architecture
-- This is the single entry point for the idle SOC (Security Operations Center) game

-- Import the SOC game controller
local SOCGame = require("src.soc_game")

-- Global game instance
local game

-- LÖVE 2D callback functions
function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("🛡️ SOC Command Center - Cybersecurity Operations Simulator")
    
    -- Set window size for optimal SOC dashboard display
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    -- Set up clean monospace font for SOC terminal theme
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    
    -- Initialize the SOC game
    game = SOCGame.new()
    local success = game:initialize()
    
    if success then
        print("🚀 SOC Command Center loaded successfully!")
    else
        print("❌ Failed to initialize SOC operations")
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
        love.graphics.print("SOC Command Center not initialized", 10, 10)
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