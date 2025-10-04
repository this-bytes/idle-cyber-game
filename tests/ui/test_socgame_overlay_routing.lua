-- Ensure SOCGame routes input to overlays first and scenes only when not consumed
local SOCGame = require("src.soc_game")

TestRunner.test("SOCGame - overlay consumes input before scene", function()
    local EventBus = require("src.utils.event_bus")
    local eb = EventBus:new()
    local game = SOCGame.new(eb)
    -- Minimal initializeCore to create resource manager
    game:initializeCore()

    -- Create a mock scene with mousepressed and keypressed trackers
    local called = { scene_mouse = 0, scene_key = 0 }
    local mockScene = {
        enter = function() end,
        exit = function() end,
        mousepressed = function(self, x, y, b) called.scene_mouse = called.scene_mouse + 1 end,
        keypressed = function(self, k) called.scene_key = called.scene_key + 1 end
    }

    -- Create scene manager and register mock scene
    game.sceneManager = require("src.scenes.scene_manager").new(nil, game.systems)
    game.sceneManager:registerScene("mock", mockScene)
    game.sceneManager:requestScene("mock")

    -- Create overlay manager and push a modal overlay that consumes input
    game.overlayManager = require("src.ui.overlay_manager").new()
    local overlay = { modal = true } -- no handlers but modal should block
    game.overlayManager:push(overlay)

    -- Simulate input; overlay is modal so scene should not be called
    game:mousepressed(10, 10, 1)
    game:keypressed('a')
    TestRunner.assert(called.scene_mouse == 0, "Scene mouse should not be called when modal overlay present")
    TestRunner.assert(called.scene_key == 0, "Scene key should not be called when modal overlay present")

    -- Pop overlay and test again
    game.overlayManager:pop()
    game:mousepressed(10, 10, 1)
    game:keypressed('a')
    TestRunner.assert(called.scene_mouse == 1, "Scene mouse should be called after removing overlay")
    TestRunner.assert(called.scene_key == 1, "Scene key should be called after removing overlay")
end)
