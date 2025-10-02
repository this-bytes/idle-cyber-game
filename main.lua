-- Idle Sec Ops - Cybersecurity Idle Game
-- This is the single entry point for the game.

-- Global game instance
local game
---@param DEBUG_UI boolean If true, show debug overlay for UI elements
DEBUG_UI = false
--Arguments to run parts directly passed in via command line expand as we develop
-- Useful for running specific test suites without a full IDE setup or driving particular
-- game modes directly from command line.
-- Usage:
-- e.g. love . --test=contracts
-- or love . --test=progression
local args = {...}
if args then
    for i, v in ipairs(args) do
        if v:find("--test=") == 1 then
            local testName = v:sub(8)
            if testName == "contracts" then
                print("Running contract system tests...")
                local ContractTests = require("tests.systems.test_contract_system")
                local passed, failed = ContractTests.run_contract_tests()
                print(string.format("Contract tests completed: %d passed, %d failed", passed, failed))
                love.event.quit()
            elseif testName == "progression" then
                print("Running progression system tests...")
                local ProgressionTests = require("tests.systems.test_progression_system")
                local passed, failed = ProgressionTests.run_progression_tests()
                print(string.format("Progression tests completed: %d passed, %d failed", passed, failed))
                love.event.quit()
            elseif testName == "specialists" then
                print("Running specialist system tests...")
                local SpecialistTests = require("tests.systems.test_specialist_system")
                local passed, failed = SpecialistTests.run_specialist_tests()
                print(string.format("Specialist tests completed: %d passed, %d failed", passed, failed))
                love.event.quit()
            elseif testName == "input" then
                print("Running input system tests...")
                local InputTests = require("tests.systems.test_input_system")
                local passed, failed = InputTests.run_input_tests()
                print(string.format("Input tests completed: %d passed, %d failed", passed, failed))
                love.event.quit()
            else
                print("Unknown test: " .. testName)
                love.event.quit()
            end
        end
    end
end

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

    -- Enable UI debug overlay when environment variable IDLE_DEBUG_UI is set
    local dbg = os.getenv("IDLE_DEBUG_UI")
    if dbg == "1" or dbg == "true" then
        DEBUG_UI = true
        print("[UI DEBUG] DEBUG_UI overlay enabled")
    else
        DEBUG_UI = false
    end

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
    -- Log raw coordinates at the engine entry point for diagnostics
    print(string.format("[UI RAW] love.mousepressed raw x=%.1f y=%.1f button=%s", x, y, tostring(button)))
    if game then
        game:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if game and game.mousereleased then
        game:mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if game and game.mousemoved then
        game:mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(x, y)
    if game and game.wheelmoved then
        game:wheelmoved(x, y)
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