-- Dynamic Event System - Manages random events and their effects
-- Handles event triggering, effects application, and duration management

local EventSystem = {}
EventSystem.__index = EventSystem

function EventSystem.new(eventBus, dataManager, resourceManager)
    local self = setmetatable({}, EventSystem)

    -- Dependencies
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.resourceManager = resourceManager

    -- Event data
    self.events = {}
    self.activeEvents = {} -- Events with ongoing effects
    self.eventTimer = 0
    self.baseInterval = 120 -- Base time in seconds between event checks (2 minutes)
    self.intervalVariance = 30 -- Random variance (±30 seconds)

    -- Event probabilities and weights
    self.eventWeights = {}
    self.totalWeight = 0

    -- Cooldown tracking to prevent event spam
    self.eventCooldowns = {}
    self.globalCooldown = 0

    print("🎉 Event System initialized")
    return self
end

-- Initialize the event system
function EventSystem:initialize()
    if not self.dataManager then
        print("⚠️ EventSystem: No dataManager available")
        return false
    end

    local eventData = self.dataManager:getData("events")
    if not eventData or type(eventData) ~= "table" then
        print("⚠️ EventSystem: No event data found")
        return false
    end

    self.events = eventData

    -- Calculate event weights for weighted random selection
    self:calculateEventWeights()

    print("📚 Loaded " .. #self.events .. " dynamic events")
    print("⚖️ Total event weight: " .. self.totalWeight)

    return true
end

-- Calculate weights for weighted random event selection
function EventSystem:calculateEventWeights()
    self.eventWeights = {}
    self.totalWeight = 0

    for i, event in ipairs(self.events) do
        local weight = self:calculateEventWeight(event)
        self.eventWeights[i] = weight
        self.totalWeight = self.totalWeight + weight
    end
end

-- Calculate weight for a single event based on rarity and frequency
function EventSystem:calculateEventWeight(event)
    local baseWeight = event.frequency or 0.1

    -- Adjust weight based on rarity
    local rarityMultiplier = 1.0
    if event.rarity == "common" then
        rarityMultiplier = 1.0
    elseif event.rarity == "uncommon" then
        rarityMultiplier = 0.7
    elseif event.rarity == "rare" then
        rarityMultiplier = 0.4
    elseif event.rarity == "epic" then
        rarityMultiplier = 0.2
    elseif event.rarity == "legendary" then
        rarityMultiplier = 0.1
    end

    return baseWeight * rarityMultiplier * 1000 -- Scale up for integer weights
end

-- Update the event system
function EventSystem:update(dt)
    -- Update active event timers
    self:updateActiveEvents(dt)

    -- Update global cooldown
    if self.globalCooldown > 0 then
        self.globalCooldown = self.globalCooldown - dt
    end

    -- Check for new event triggers
    self.eventTimer = self.eventTimer + dt
    local currentInterval = self.baseInterval + math.random(-self.intervalVariance, self.intervalVariance)

    if self.eventTimer >= currentInterval and self.globalCooldown <= 0 then
        self.eventTimer = 0
        self:attemptTriggerEvent()
    end
end

-- Attempt to trigger a random event
function EventSystem:attemptTriggerEvent()
    if #self.events == 0 or self.totalWeight <= 0 then
        return
    end

    -- Weighted random selection
    local randomValue = math.random(0, self.totalWeight)
    local cumulativeWeight = 0

    for i, weight in ipairs(self.eventWeights) do
        cumulativeWeight = cumulativeWeight + weight
        if randomValue <= cumulativeWeight then
            local event = self.events[i]

            -- Check if event is on cooldown
            if not self:isEventOnCooldown(event.id) then
                self:triggerEvent(event)
                return
            end
        end
    end
end

-- Trigger a specific event
function EventSystem:triggerEvent(event)
    print("🎲 Event Triggered: " .. event.name)
    print("   " .. event.description)

    -- Set global cooldown to prevent event spam
    self.globalCooldown = 10 -- 10 second minimum between events

    -- Set event-specific cooldown
    self.eventCooldowns[event.id] = os.time() + (event.cooldown or 300) -- Default 5 minutes

    -- Handle different event types
    if event.type == "choice" then
        self:handleChoiceEvent(event)
    else
        self:handleAutomaticEvent(event)
    end

    -- Publish event for UI and other systems
    self.eventBus:publish("dynamic_event_triggered", {
        event = event,
        timestamp = os.time()
    })
end

-- Handle automatic events (positive, negative, neutral)
function EventSystem:handleAutomaticEvent(event)
    -- Apply immediate effects
    self:applyEventEffects(event)

    -- Handle duration-based effects
    if event.duration and event.duration > 0 then
        self:startEventDuration(event)
    end
end

-- Handle choice events (player must make a decision)
function EventSystem:handleChoiceEvent(event)
    -- For choice events, we publish the choices and wait for player decision
    -- The UI system will handle presenting the choices to the player

    self.eventBus:publish("event_choice_required", {
        event = event,
        choices = event.choices or {},
        timestamp = os.time()
    })
end

-- Apply event effects to game systems
function EventSystem:applyEventEffects(event)
    if not event.effects then return end

    local effects = event.effects

    -- Money effects
    if effects.money and self.resourceManager then
        self.resourceManager:addResource("money", effects.money)
        if effects.money > 0 then
            print("💰 +" .. effects.money .. " credits")
        else
            print("💸 " .. effects.money .. " credits")
        end
    end

    -- Reputation effects
    if effects.reputation and self.resourceManager then
        self.resourceManager:addResource("reputation", effects.reputation)
        if effects.reputation > 0 then
            print("⭐ +" .. effects.reputation .. " reputation")
        else
            print("📉 " .. effects.reputation .. " reputation")
        end
    end

    -- Publish effects for other systems to handle
    self.eventBus:publish("event_effects_applied", {
        eventId = event.id,
        effects = effects
    })
end

-- Start duration-based event effects
function EventSystem:startEventDuration(event)
    local activeEvent = {
        event = event,
        startTime = os.time(),
        endTime = os.time() + event.duration,
        effects = event.effects
    }

    table.insert(self.activeEvents, activeEvent)

    print("⏰ Event active for " .. self:formatDuration(event.duration))
end

-- Update active events and remove expired ones
function EventSystem:updateActiveEvents(dt)
    local currentTime = os.time()
    local expiredEvents = {}

    for i, activeEvent in ipairs(self.activeEvents) do
        if currentTime >= activeEvent.endTime then
            table.insert(expiredEvents, i)
            self:endEventDuration(activeEvent)
        end
    end

    -- Remove expired events (in reverse order to maintain indices)
    for i = #expiredEvents, 1, -1 do
        table.remove(self.activeEvents, expiredEvents[i])
    end
end

-- End duration-based event effects
function EventSystem:endEventDuration(activeEvent)
    print("⏰ Event ended: " .. activeEvent.event.name)

    -- Publish event end for other systems to handle cleanup
    self.eventBus:publish("event_duration_ended", {
        eventId = activeEvent.event.id,
        effects = activeEvent.effects
    })
end

-- Handle player choice for choice events
function EventSystem:makeEventChoice(eventId, choiceIndex)
    -- Find the event
    for _, activeEvent in ipairs(self.activeEvents) do
        if activeEvent.event.id == eventId and activeEvent.event.type == "choice" then
            local choice = activeEvent.event.choices[choiceIndex]
            if choice then
                print("🎯 Chose: " .. choice.name)
                self:applyEventEffects(choice)
                -- Remove the choice event
                for i, ae in ipairs(self.activeEvents) do
                    if ae.event.id == eventId then
                        table.remove(self.activeEvents, i)
                        break
                    end
                end
                return true
            end
        end
    end
    return false
end

-- Check if an event is on cooldown
function EventSystem:isEventOnCooldown(eventId)
    local cooldownEnd = self.eventCooldowns[eventId]
    return cooldownEnd and os.time() < cooldownEnd
end

-- Get active events
function EventSystem:getActiveEvents()
    return self.activeEvents
end

-- Get all available events
function EventSystem:getAllEvents()
    return self.events
end

-- Format duration for display
function EventSystem:formatDuration(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm", math.floor(seconds / 60))
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- Get event statistics
function EventSystem:getStats()
    return {
        totalEvents = #self.events,
        activeEvents = #self.activeEvents,
        totalWeight = self.totalWeight,
        nextEventIn = math.max(0, (self.baseInterval - self.eventTimer))
    }
end

-- Force trigger a specific event (for testing/debugging)
function EventSystem:forceTriggerEvent(eventId)
    for _, event in ipairs(self.events) do
        if event.id == eventId then
            self:triggerEvent(event)
            return true
        end
    end
    return false
end

return EventSystem
