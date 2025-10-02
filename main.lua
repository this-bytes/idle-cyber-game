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
local args = arg
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
        elseif v:find("--screenshot") == 1 then
            -- Enable screenshot mode (automated mode that quits after capture)
            SCREENSHOT_MODE = true
            SCREENSHOT_READY = false
            SCREENSHOT_AGENT = false
            print("📸 Screenshot mode enabled from command line")
        elseif v:find("--screenshot-agent") == 1 then
            -- Agent-triggered screenshots: enable capturing but do NOT quit the
            -- game afterwards. Useful for coding agents that want to inspect
            -- UI without terminating the process.
            SCREENSHOT_MODE = true
            SCREENSHOT_READY = false
            SCREENSHOT_AGENT = true
            print("📸 Screenshot agent mode enabled from command line")
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

    -- Debug: print command line arguments
    print("📋 Command line args:", table.concat(arg, ", "))

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
        -- If in screenshot mode, schedule captures after first draw to ensure
        -- the window has been rendered. We'll capture main_menu first, then
        -- navigate to soc_view and capture that. Agent mode controls whether
        -- we quit after capturing.
        if SCREENSHOT_MODE then
            SCREENSHOT_CAPTURE_FLOW = true
            SCREENSHOT_CAPTURED_MAIN = false
            SCREENSHOT_CAPTURED_SOC = false
            print("📸 Screenshot mode scheduled: will capture main_menu then soc_view")
        end
        -- Start the game normally; captures will be triggered from love.draw
        if SCREENSHOT_MODE and not SCREENSHOT_AGENT then
            -- For automated screenshot mode (non-agent) we still start the game
            -- so the SOC view can be reached automatically.
            game:startGame()
            game.sceneManager:requestScene("soc_view")
        end
    else
        print("❌❌❌ FATAL ERROR DURING INITIALIZATION ❌❌❌")
        print(err)
        -- In a real build, you might switch to an error scene here.
    end
end

function love.update(dt)
    if game then
        game:update(dt)
        
        -- Mark screenshot as ready after first update cycle
        if SCREENSHOT_MODE and not SCREENSHOT_READY then
            SCREENSHOT_READY = true
            print("📸 Screenshot mode: Ready to capture after first update cycle")
        end
        -- If we're waiting for async screenshot file to be written, poll for it
        if SCREENSHOT_WAITING and SCREENSHOT_PENDING_PATH then
            if SCREENSHOT_WAIT_FRAMES and SCREENSHOT_WAIT_FRAMES > 0 then
                SCREENSHOT_WAIT_FRAMES = SCREENSHOT_WAIT_FRAMES - 1
            end
            local exists = io.open(SCREENSHOT_PENDING_PATH, 'rb') ~= nil
            if exists or (SCREENSHOT_WAIT_FRAMES and SCREENSHOT_WAIT_FRAMES <= 0) then
                print('📸 Screenshot file presence check: ' .. tostring(exists))
                SCREENSHOT_WAITING = false
                SCREENSHOT_PENDING_PATH = nil
                -- Quit now that the file exists (or we've given up waiting)
                love.event.quit()
            end
        end
    end
end

function love.draw()
    if game then
        game:draw()
    else
        love.graphics.printf("Error during initialization. Check console.", 0, 10, love.graphics.getWidth(), "center")
    end

    -- Take screenshot if in screenshot mode and ready
    if SCREENSHOT_MODE and SCREENSHOT_READY and game and SCREENSHOT_CAPTURE_FLOW then
        local ScreenshotTool = require("tools.screenshot_tool")
        local currentScene = game.sceneManager and game.sceneManager.currentSceneName or "unknown"

        if not SCREENSHOT_CAPTURED_MAIN and currentScene == "main_menu" then
            print("📸 Capturing main menu scene:", currentScene)
            ScreenshotTool.takeScreenshotWithPrefix("dashboard_main_menu")
            SCREENSHOT_CAPTURED_MAIN = true
            -- After capturing main menu, ensure SOC view will be shown to capture
            if not SCREENSHOT_AGENT then
                -- For automated mode, request SOC view immediately.
                game.sceneManager:requestScene("soc_view")
            end
            return
        end

        if SCREENSHOT_CAPTURED_MAIN and not SCREENSHOT_CAPTURED_SOC and currentScene == "soc_view" then
            print("📸 Capturing SOC view scene:", currentScene)
            local path = ScreenshotTool.takeScreenshotWithPrefix("dashboard_soc_view")
            SCREENSHOT_CAPTURED_SOC = true
            if not SCREENSHOT_AGENT then
                -- Start waiting for the file to exist before quitting
                SCREENSHOT_WAITING = true
                SCREENSHOT_PENDING_PATH = path
                SCREENSHOT_WAIT_FRAMES = 5 -- poll a few frames to allow async encode
            end
            return
        end
        -- If agent mode, we leave screenshots for inspection and do not quit.
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