-- Launcher for API test mode
-- This replaces main.lua when running API tests

-- Check if we're in test mode
local args = arg
if args and args[1] == "--test-api" then
    -- Load the API test instead of main game
    require("test_love_api")
else
    -- Load normal game
    require("main")
end