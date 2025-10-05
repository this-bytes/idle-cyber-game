local StatsOverlay = require("src.ui.stats_overlay")

TestRunner.test("StatsOverlay - modal blocks input when visible", function()
    local overlay = StatsOverlay.new(nil, nil)
    -- verify overlay initialized
    TestRunner.assert(overlay ~= nil, "StatsOverlay should be initialized (not nil)")
    -- overlay should be modal by default
    TestRunner.assert(overlay.modal, "StatsOverlay should be modal by default")
    overlay:show()
    -- shouldCaptureInput should return true when visible
    TestRunner.assert(overlay:shouldCaptureInput(), "shouldCaptureInput must return true when visible and modal")
end)
