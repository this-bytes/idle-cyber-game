-- Input System - Unified Input Handling for Idle Sec Ops
-- Handles mouse, keyboard, and touch input with action mapping
-- Provides accessibility features and event-driven architecture

local InputSystem = {}
InputSystem.__index = InputSystem

function InputSystem.new(eventBus)
    local self = setmetatable({}, InputSystem)
    self.eventBus = eventBus

    -- Action mappings: action_name -> {keys, mouse_regions}
    self.actionMappings = {}

    -- Focus management for keyboard navigation
    self.focusStack = {}
    self.currentFocus = nil

    -- Debouncing system (prevents rapid-fire inputs)
    self.lastTriggerTime = {}
    self.debounceTime = 0.05 -- 50ms minimum between triggers

    -- Input state tracking
    self.keyStates = {}
    self.mouseStates = {}

    -- Load input configuration
    self:loadInputConfig()

    print("🎮 InputSystem: Initialized with " .. self:getActionCount() .. " action mappings")
    return self
end

-- Load input configuration from data file
function InputSystem:loadInputConfig()
    local success, config = pcall(require, "src.data.input_config")
    if success and config.actions then
        self.actionMappings = config.actions
        self.clickRegions = config.clickRegions or {}
    else
        print("⚠️  InputSystem: Could not load input_config.lua, using defaults")
        self:setDefaultMappings()
    end
end

-- Set default action mappings if config file is missing
function InputSystem:setDefaultMappings()
    self.actionMappings = {
        manual_income = {
            keys = {"space", "m"},
            mouseRegions = {"money_counter"}
        },
        navigate_next = {
            keys = {"tab", "right"},
            mouseRegions = {}
        },
        navigate_back = {
            keys = {"escape", "left"},
            mouseRegions = {}
        }
    }
    self.clickRegions = {
        money_counter = {x = 20, y = 80, width = 280, height = 40}
    }
end

-- Register a focusable UI element
function InputSystem:registerFocusable(element, priority)
    priority = priority or 0
    table.insert(self.focusStack, {
        element = element,
        priority = priority,
        id = element.id or tostring(element)
    })

    -- Sort by priority (highest first)
    table.sort(self.focusStack, function(a, b)
        return a.priority > b.priority
    end)

    -- Ensure focus is set to the highest priority element
    -- Use setFocus so focus gained/lost callbacks are invoked properly
    if #self.focusStack > 0 then
        self:setFocus(self.focusStack[1])
    end
end

-- Navigate focus (TAB navigation)
function InputSystem:navigateFocus(direction)
    if #self.focusStack == 0 then return end

    local currentIndex = 1
    for i, focus in ipairs(self.focusStack) do
        if focus == self.currentFocus then
            currentIndex = i
            break
        end
    end

    if direction == "next" then
        currentIndex = currentIndex % #self.focusStack + 1
    elseif direction == "prev" then
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = #self.focusStack
        end
    end

    self:setFocus(self.focusStack[currentIndex])
end

-- Set focus to specific element
function InputSystem:setFocus(focusItem)
    if self.currentFocus and self.currentFocus.element and self.currentFocus.element.onFocusLost then
        self.currentFocus.element:onFocusLost()
    end

    self.currentFocus = focusItem

    if self.currentFocus and self.currentFocus.element and self.currentFocus.element.onFocusGained then
        self.currentFocus.element:onFocusGained()
    end
end

-- Clear all focus
function InputSystem:clearFocus()
    if self.currentFocus and self.currentFocus.element and self.currentFocus.element.onFocusLost then
        self.currentFocus.element:onFocusLost()
    end
    self.currentFocus = nil
end

-- Check if an action should trigger (with debouncing)
function InputSystem:shouldTriggerAction(actionName)
    local now = love.timer.getTime()
    local lastTime = self.lastTriggerTime[actionName]

    -- If we've never triggered this action before, allow it immediately
    if not lastTime then
        self.lastTriggerTime[actionName] = now
        return true
    end

    if now - lastTime >= self.debounceTime then
        self.lastTriggerTime[actionName] = now
        return true
    end

    return false
end

-- Trigger an action (called by input handlers)
function InputSystem:triggerAction(actionName, source, data)
    if not self:shouldTriggerAction(actionName) then
        return false
    end

    -- Emit event for the action
    if self.eventBus then
        self.eventBus:publish("input_action_" .. actionName, {
            source = source,
            data = data or {},
            timestamp = love.timer.getTime()
        })
    end

    print("🎮 InputSystem: Triggered action '" .. actionName .. "' from " .. source)
    return true
end

-- Check if a key matches an action
function InputSystem:keyMatchesAction(key, actionName)
    local mapping = self.actionMappings[actionName]
    if not mapping or not mapping.keys then return false end

    for _, mappedKey in ipairs(mapping.keys) do
        if mappedKey == key then
            return true
        end
    end
    return false
end

-- Check if mouse position is in a region
function InputSystem:mouseInRegion(x, y, regionName)
    local region = self.clickRegions[regionName]
    if not region then return false end

    return x >= region.x and x <= region.x + region.width and
           y >= region.y and y <= region.y + region.height
end

-- Handle keyboard input
function InputSystem:keypressed(key, scancode, isrepeat)
    if isrepeat then return end -- Ignore key repeats

    self.keyStates[key] = true

    -- Check for action mappings
    for actionName, mapping in pairs(self.actionMappings) do
        if self:keyMatchesAction(key, actionName) then
            self:triggerAction(actionName, "keyboard", {key = key})
            return
        end
    end

    -- Handle focus navigation
    if key == "tab" then
        local direction = love.keyboard.isDown("lshift") and "prev" or "next"
        self:navigateFocus(direction)
    elseif key == "escape" then
        self:clearFocus()
    end
end

function InputSystem:keyreleased(key)
    self.keyStates[key] = false
end

-- Handle mouse input
function InputSystem:mousepressed(x, y, button, istouch, presses)
    if button ~= 1 then return end -- Only handle left clicks

    self.mouseStates[button] = {x = x, y = y}

    -- Check click regions
    for regionName, region in pairs(self.clickRegions) do
        if self:mouseInRegion(x, y, regionName) then
            -- Find action that uses this region
            for actionName, mapping in pairs(self.actionMappings) do
                if mapping.mouseRegions then
                    for _, mouseRegion in ipairs(mapping.mouseRegions) do
                        if mouseRegion == regionName then
                            self:triggerAction(actionName, "mouse", {x = x, y = y, region = regionName})
                            return
                        end
                    end
                end
            end
        end
    end
end

function InputSystem:mousereleased(x, y, button, istouch, presses)
    self.mouseStates[button] = nil
end

-- Update (for continuous input handling)
function InputSystem:update(dt)
    -- Handle continuous key presses if needed
    -- Currently debounced, but could add continuous actions here
end

-- Get formatted keybind hints for UI
function InputSystem:getKeybindHint(actionName)
    local mapping = self.actionMappings[actionName]
    if not mapping or not mapping.keys then return "" end

    local hints = {}
    for _, key in ipairs(mapping.keys) do
        table.insert(hints, string.upper(key))
    end

    return table.concat(hints, "/")
end

-- Get action count for debugging
function InputSystem:getActionCount()
    local count = 0
    for _ in pairs(self.actionMappings) do
        count = count + 1
    end
    return count
end

-- Debug: Show current focus
function InputSystem:getCurrentFocusInfo()
    if not self.currentFocus then return "No focus" end
    return "Focus: " .. (self.currentFocus.id or "unknown")
end

return InputSystem
