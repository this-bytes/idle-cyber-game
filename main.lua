-- Idle Sec Ops - Cybersecurity Idle Game
-- This is the single entry point for the game.

-- LUIS Integration: Override require to translate "luis.*" to "lib/luis/*"
do
    local originalRequire = require
    _G.require = function(moduleName)
        if moduleName:match("^luis%.") then
            -- Translate "luis.core" -> "lib.luis.core", "luis.3rdparty.flux" -> "lib.luis.3rdparty.flux"
            local translatedPath = moduleName:gsub("^luis%.", "lib.luis.")
            local success, result = pcall(originalRequire, translatedPath)
            if success then
                return result
            end
            -- If that didn't work, fall through to original require
        end
        return originalRequire(moduleName)
    end
end

local game
local ScreenshotTool = require("tools.screenshot_tool")

-- @param DEBUG_UI boolean If true, show debug overlay for UI elements
DEBUG_UI = false

-- --- NEW ARGUMENT PARSING HELPER ---
local function parse_args(args)
    local options = {}
    if not args then return options end

    for _, v in ipairs(args) do
        -- Find argument and its value (e.g., test=contracts)
        if v:find("^%-%-test=") then
            options.test = v:sub(v:find("=")[1] + 1)
        -- Handle simple flags
        elseif v == "--screenshot" then
            options.screenshot_mode = true
        elseif v == "--screenshot-agent" then
            options.screenshot_mode = true
            options.screenshot_agent = true
        elseif v == "--take-screenshot" then
            options.take_screenshot_on_load = true
        end
    end
    return options
end
-- --- END NEW ARGUMENT PARSING HELPER ---

-- --- NEW TEST REGISTRY ---
local TestRegistry = {
    contracts = function()
        local ContractTests = require("tests.systems.test_contract_system")
        local p, f = ContractTests.run_contract_tests()
        return p, f, "Contract"
    end,
    progression = function()
        local ProgressionTests = require("tests.systems.test_progression_system")
        local p, f = ProgressionTests.run_progression_tests()
        return p, f, "Progression"
    end,
    specialists = function()
        local SpecialistTests = require("tests.systems.test_specialist_system")
        local p, f = SpecialistTests.run_specialist_tests()
        return p, f, "Specialist"
    end,
    input = function()
        local InputTests = require("tests.systems.test_input_system")
        local p, f = InputTests.run_input_tests()
        return p, f, "Input"
    end,
}
-- --- END NEW TEST REGISTRY ---


-- Process command line arguments
local options = parse_args(arg)

-- EXECUTE LOGIC BASED ON PARSED OPTIONS
if options.test then
    local runTest = TestRegistry[options.test]
    if runTest then
        local passed, failed, name = runTest()
        print(string.format("%s tests completed: %d passed, %d failed", name, passed, failed))
    else
        print("Unknown test: " .. options.test)
    end
    -- Quit after test execution regardless of success/failure
    love.event.quit()
end

-- Set global flags based on parsed options
SCREENSHOT_MODE = options.screenshot_mode or false
SCREENSHOT_READY = false
SCREENSHOT_AGENT = options.screenshot_agent or false
TAKE_SCREENSHOT_ON_LOAD = options.take_screenshot_on_load or false

if SCREENSHOT_MODE or TAKE_SCREENSHOT_ON_LOAD then
    local mode_name = SCREENSHOT_AGENT and "Agent" or "Automated"
    print(string.format("📸 Screenshot mode enabled: %s", mode_name))
end

function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("🛡️ SOC Command Center - Cybersecurity Operations Simulator")
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    -- TODO: Add emoji support through graphics.printf()

    love.graphics.printf("🛡️ SOC Command Center - Cybersecurity Operations Simulator", 0, 50, love.graphics.getWidth(), "center")

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
        --[[ REMOVED to allow main_menu to render first for screenshot
        if SCREENSHOT_MODE and not SCREENSHOT_AGENT then
            -- For automated screenshot mode (non-agent) we still start the game
            -- so the SOC view can be reached automatically.
            game:startGame()
            game.sceneManager:requestScene("soc_view")
        end
        ]]
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
        if (SCREENSHOT_MODE or TAKE_SCREENSHOT_ON_LOAD) and not SCREENSHOT_READY then
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

    if TAKE_SCREENSHOT_ON_LOAD and SCREENSHOT_READY then
        local path = ScreenshotTool.takeScreenshot()
        TAKE_SCREENSHOT_ON_LOAD = false -- only once
        if not SCREENSHOT_MODE then -- if not in full screenshot mode, quit after taking one
            SCREENSHOT_WAITING = true
            SCREENSHOT_PENDING_PATH = path
            SCREENSHOT_WAIT_FRAMES = 5 -- poll a few frames to allow async encode
        end
    end

    -- Take screenshot if in screenshot mode and ready
    if SCREENSHOT_MODE and SCREENSHOT_READY and game and SCREENSHOT_CAPTURE_FLOW then
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
    ScreenshotTool.keypressed(key)
end

function love.mousepressed(x, y, button)
    -- Log raw coordinates at the engine entry point for diagnostics
    print(string.format("[UI RAW] love.mousepressed raw x=%.1f y=%.1f button=%s", x, y, tostring(button)))
    if game then
        game:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    -- Log raw coordinates at the engine entry point for diagnostics
    print(string.format("[UI RAW] love.mousereleased raw x=%.1f y=%.1f button=%s", x, y, tostring(button)))
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
