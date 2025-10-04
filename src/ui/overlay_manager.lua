-- Overlay Manager - Manages a stack of UI overlays/modals
local OverlayManager = {}
OverlayManager.__index = OverlayManager

function OverlayManager.new()
    local self = setmetatable({}, OverlayManager)
    -- Stack of overlays (0 = none, top is last element)
    self.stack = {}
    return self
end

-- Push an overlay onto the stack. Overlay should be a table with optional
-- methods: enter(params), exit(), update(dt), draw(), mousepressed(x,y,btn),
-- mousereleased, mousemoved, keypressed, keyreleased. Returns the overlay.
function OverlayManager:push(overlay, params)
    if not overlay then return nil end
    table.insert(self.stack, overlay)
    if overlay.enter then
        overlay:enter(params)
    end
    return overlay
end

-- Pop the top overlay and call its exit handler.
function OverlayManager:pop()
    local top = self:top()
    if not top then return nil end
    if top.exit then top:exit() end
    table.remove(self.stack)
    return top
end

function OverlayManager:top()
    return self.stack[#self.stack]
end

function OverlayManager:isEmpty()
    return #self.stack == 0
end

function OverlayManager:update(dt)
    -- Update all overlays (or only top if you prefer). We'll update all so
    -- non-modal overlays can animate even when behind a modal.
    for _, overlay in ipairs(self.stack) do
        if overlay.update then overlay:update(dt) end
    end
end

function OverlayManager:draw()
    -- Draw overlays in order (bottom to top) so top overlay is drawn last.
    for _, overlay in ipairs(self.stack) do
        if overlay.draw then overlay:draw() end
    end
end

-- Input routing: try top -> bottom, stop when an overlay returns true
function OverlayManager:mousepressed(x, y, button)
    for i = #self.stack, 1, -1 do
        local o = self.stack[i]
        if o then
            -- If overlay provides handler, call it
            if o.mousepressed then
                local consumed = o:mousepressed(x, y, button)
                if consumed then
                    print(string.format("[UI DEBUG] OverlayManager:mousepressed consumed by overlay at index=%d", i))
                    return true
                end
            else
                -- If overlay explicitly wants to capture input, honor that first
                if o.shouldCaptureInput and o:shouldCaptureInput() then
                    return true
                end
                -- Only treat modal overlays as capturing when they're visible
                if o.modal and (o.visible == nil or o.visible) then
                    print(string.format("[UI DEBUG] OverlayManager:mousepressed captured by modal overlay at index=%d", i))
                    return true
                end
            end
        end
    end
    return false
end

function OverlayManager:mousereleased(x, y, button)
    for i = #self.stack, 1, -1 do
        local o = self.stack[i]
        if o then
            if o.mousereleased then
                local consumed = o:mousereleased(x, y, button)
                if consumed then
                    print(string.format("[UI DEBUG] OverlayManager:mousereleased consumed by overlay at index=%d", i))
                    return true
                end
            else
                if o.shouldCaptureInput and o:shouldCaptureInput() then
                    print(string.format("[UI DEBUG] OverlayManager:mousereleased captured by overlay.shouldCaptureInput at index=%d", i))
                    return true
                end
                if o.modal and (o.visible == nil or o.visible) then
                    print(string.format("[UI DEBUG] OverlayManager:mousereleased captured by modal overlay at index=%d", i))
                    return true
                end
            end
        end
    end
    return false
end

function OverlayManager:mousemoved(x, y, dx, dy)
    for i = #self.stack, 1, -1 do
        local o = self.stack[i]
        if o then
            if o.mousemoved then
                local consumed = o:mousemoved(x, y, dx, dy)
                if consumed then
                    print(string.format("[UI DEBUG] OverlayManager:mousemoved consumed by overlay at index=%d", i))
                    return true
                end
            else
                if o.shouldCaptureInput and o:shouldCaptureInput() then
                    print(string.format("[UI DEBUG] OverlayManager:mousemoved captured by overlay.shouldCaptureInput at index=%d", i))
                    return true
                end
                if o.modal and (o.visible == nil or o.visible) then
                    print(string.format("[UI DEBUG] OverlayManager:mousemoved captured by modal overlay at index=%d", i))
                    return true
                end
            end
        end
    end
    return false
end

function OverlayManager:wheelmoved(x, y)
    for i = #self.stack, 1, -1 do
        local o = self.stack[i]
        if o then
            if o.wheelmoved then
                local consumed = o:wheelmoved(x, y)
                if consumed then
                    print(string.format("[UI DEBUG] OverlayManager:wheelmoved consumed by overlay at index=%d", i))
                    return true
                end
            else
                if o.shouldCaptureInput and o:shouldCaptureInput() then
                    print(string.format("[UI DEBUG] OverlayManager:wheelmoved captured by overlay.shouldCaptureInput at index=%d", i))
                    return true
                end
                if o.modal and (o.visible == nil or o.visible) then
                    print(string.format("[UI DEBUG] OverlayManager:wheelmoved captured by modal overlay at index=%d", i))
                    return true
                end
            end
        end
    end
    return false
end

-- Clear input state on overlays (if overlays expose a clearInputState method)
function OverlayManager:clearInputState()
    for _, o in ipairs(self.stack) do
        if o and o.clearInputState then
            o:clearInputState()
            print("[UI DEBUG] OverlayManager: cleared input state on overlay")
        end
    end
end

function OverlayManager:keypressed(key)
    for i = #self.stack, 1, -1 do
        local o = self.stack[i]
        if o then
            if o.keypressed then
                local consumed = o:keypressed(key)
                if consumed then
                    print(string.format("[UI DEBUG] OverlayManager:keypressed consumed by overlay at index=%d key=%s", i, tostring(key)))
                    return true
                end
            else
                if o.shouldCaptureInput and o:shouldCaptureInput() then
                    print(string.format("[UI DEBUG] OverlayManager:keypressed captured by overlay.shouldCaptureInput at index=%d key=%s", i, tostring(key)))
                    return true
                end
                if o.modal and (o.visible == nil or o.visible) then
                    print(string.format("[UI DEBUG] OverlayManager:keypressed captured by modal overlay at index=%d key=%s", i, tostring(key)))
                    return true
                end
            end
        end
    end
    return false
end

function OverlayManager:keyreleased(key)
    for i = #self.stack, 1, -1 do
        local o = self.stack[i]
        if o then
            if o.keyreleased then
                local consumed = o:keyreleased(key)
                if consumed then
                    print(string.format("[UI DEBUG] OverlayManager:keyreleased consumed by overlay at index=%d key=%s", i, tostring(key)))
                    return true
                end
            else
                if o.shouldCaptureInput and o:shouldCaptureInput() then
                    print(string.format("[UI DEBUG] OverlayManager:keyreleased captured by overlay.shouldCaptureInput at index=%d key=%s", i, tostring(key)))
                    return true
                end
                if o.modal and (o.visible == nil or o.visible) then
                    print(string.format("[UI DEBUG] OverlayManager:keyreleased captured by modal overlay at index=%d key=%s", i, tostring(key)))
                    return true
                end
            end
        end
    end
    return false
end

return OverlayManager
