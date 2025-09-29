-- Cyber Empire Command - Pure ECS Architecture  
-- Main Entry Point for Entity-Component-System based Idle Cybersecurity Game
-- No legacy systems - pure ECS implementation

-- Import the pure ECS game controller
local ECSGame = require("src.ecs_game")

-- Global game instance
local game

-- LÖVE 2D callback functions
function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("🎯 Cyber Empire Command - Pure ECS Architecture")
    
    -- Set window size for optimal display
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    -- Set up clean monospace font for cybersecurity theme
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    
    -- Initialize the pure ECS game
    game = ECSGame.new()
    local success = game:initialize()
    
    if success then
        print("🎯 Pure ECS Cyber Empire Command loaded successfully!")
    else
        print("❌ Failed to initialize ECS game")
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
        love.graphics.print("ECS Game not initialized", 10, 10)
    end
end

function love.keypressed(key)
    if game then
        game:keypressed(key)
    end
    
    -- Global quit key
    if key == "escape" then
        love.event.quit()
    end
end

function love.quit()
    if game then
        game:shutdown()
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