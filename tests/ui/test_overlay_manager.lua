-- Tests for OverlayManager
local OverlayManager = require("src.ui.overlay_manager")

TestRunner.test("OverlayManager - push/pop/top/isEmpty", function()
    local m = OverlayManager.new()
    TestRunner.assert(m:isEmpty(), "Should be empty initially")

    local o1 = { entered = false, enter = function(self) self.entered = true end }
    m:push(o1)
    TestRunner.assert(not m:isEmpty(), "Should not be empty after push")
    TestRunner.assert(m:top() == o1, "Top should be the pushed overlay")

    local p = m:pop()
    TestRunner.assert(p == o1, "Popped overlay should be the same")
    TestRunner.assert(m:isEmpty(), "Should be empty after pop")
end)

TestRunner.test("OverlayManager - mousepressed routing top consumes", function()
    local m = OverlayManager.new()
    local calls = {}
    local top = { mousepressed = function(self, x,y,b) table.insert(calls, 'top'); return true end }
    local bottom = { mousepressed = function(self) table.insert(calls, 'bottom'); return true end }
    m:push(bottom)
    m:push(top)

    local consumed = m:mousepressed(10, 20, 1)
    TestRunner.assert(consumed, "Should return true when top consumed")
    TestRunner.assert(#calls == 1 and calls[1] == 'top', "Top should be called and consume")
end)

TestRunner.test("OverlayManager - mousepressed routing falls through to bottom", function()
    local m = OverlayManager.new()
    local calls = {}
    local top = { mousepressed = function(self) table.insert(calls, 'top'); return false end }
    local bottom = { mousepressed = function(self) table.insert(calls, 'bottom'); return true end }
    m:push(bottom)
    m:push(top)

    local consumed = m:mousepressed(1, 2, 1)
    TestRunner.assert(consumed, "Should be consumed by bottom")
    TestRunner.assert(#calls == 2 and calls[1] == 'top' and calls[2] == 'bottom', "Both overlays should be called in order")
end)

TestRunner.test("OverlayManager - keypressed routing", function()
    local m = OverlayManager.new()
    local calls = {}
    local top = { keypressed = function(self, k) table.insert(calls, 'top:'..k); return false end }
    local bottom = { keypressed = function(self, k) table.insert(calls, 'bottom:'..k); return true end }
    m:push(bottom)
    m:push(top)

    local consumed = m:keypressed('escape')
    TestRunner.assert(consumed, "Key should be consumed by bottom")
    TestRunner.assert(#calls == 2 and calls[1] == 'top:escape' and calls[2] == 'bottom:escape', "Key events routed top->bottom")
end)
