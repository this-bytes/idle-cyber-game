-- Cyber Empire Command - Cybersecurity Consultancy Simulator
-- Main entry point with proper modular architecture

-- Import core game controller
local Game = require("src.game")

-- LÖVE 2D callback functions
function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Cyber Empire Command - Cybersecurity Consultancy Simulator")
    
    -- Set window size
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    -- Set up monospace font for terminal aesthetic (if available)
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    
    -- Initialize the game
    Game.init()
end

function love.update(dt)
    Game.update(dt)
    Game.handleAutoSave(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    Game.keypressed(key)
end

function love.mousepressed(x, y, button)
    Game.mousepressed(x, y, button)
end

function love.resize(w, h)
    Game.resize(w, h)
end

function love.quit()
    Game.save()
end