-- Test for SceneManager initialization and default scene
local SceneManager = require("src.scenes.scene_manager")
local EventBus = require("src.utils.event_bus")

local function run()
    print("🧪 Testing SceneManager initialization...")
    local eventBus = EventBus.new()
    local manager = SceneManager.new(eventBus)
    manager:initialize()

    local current = manager:getCurrentScene()
    assert(current == "main_menu", "SceneManager should initialize to main_menu, got: " .. tostring(current))
    print("✅ SceneManager: initialized to main_menu")
end

run()
return true
