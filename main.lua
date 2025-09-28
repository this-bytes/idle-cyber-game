-- Cyber Empire Command - Cybersecurity Consultancy Simulator
-- Main entry point with proper modular architecture

-- Import core game controller
-- Prefer fortress_main (modern fortress architecture). Fall back to legacy src.game if not present.
-- Prefer fortress core controller. Fall back to legacy src.game if not available.
local Game
local ok, FortressGame = pcall(require, "src.core.fortress_game")
if ok and FortressGame then
    -- Instantiate fortress controller and expose a Game-like API
    local fortressInstance
    Game = {}
    function Game.init()
        fortressInstance = FortressGame.new()
        fortressInstance:initialize()
    end
    function Game.update(dt)
        if fortressInstance then fortressInstance:update(dt) end
    end
    function Game.draw()
        if fortressInstance then fortressInstance:draw() end
    end
    function Game.keypressed(key)
        if fortressInstance then fortressInstance:keypressed(key) end
    end
    function Game.keyreleased(key)
        if fortressInstance and fortressInstance.keyreleased then fortressInstance:keyreleased(key) end
    end
    function Game.mousepressed(x, y, button)
        if fortressInstance then fortressInstance:mousepressed(x, y, button) end
    end
    function Game.resize(w, h)
        if fortressInstance then fortressInstance:resize(w, h) end
    end
    function Game.save()
        if fortressInstance then return fortressInstance:save() end
    end
    function Game.handleAutoSave(dt)
        if fortressInstance and fortressInstance.handleAutoSave then fortressInstance:handleAutoSave(dt) end
    end
else
    Game = require("src.game")
end

-- LÖVE 2D callback functions
function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Cyber Empire Command - Cybersecurity Consultancy Simulator")
    
    -- Set window size
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})

    -- Scale to window size
    -- TODO: Implement dynamic scaling based on window size
    
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

function love.keyreleased(key)
    if Game.keyreleased then Game.keyreleased(key) end
end

function love.mousepressed(x, y, button)
    Game.mousepressed(x, y, button)
end

function love.resize(w, h)
    Game.resize(w, h)
end

function love.quit()
    Game.save()
    print("Shutting down. Thanks for playing Cyber Empire Command!")
end