-- Not implemented yet
-- File: src/systems/room_event_system.lua
-- Cool idea: room-specific dynamic events that can occur based on player actions, time spent, or random chance. Maybe it can be implemented
-- Room Event System
-- Handles dynamic events, encounters, and special situations that occur in different rooms

local RoomEventSystem = {}
RoomEventSystem.__index = RoomEventSystem

-- Create new room event system
function RoomEventSystem.new(eventBus, roomSystem)
    local self = setmetatable({}, RoomEventSystem)
    self.eventBus = eventBus
    self.roomSystem = roomSystem
    
    -- Event timing
    self.nextEventTime = 30 -- First event in 30 seconds
    self.eventCooldown = 0
    self.minEventInterval = 45 -- Minimum 45 seconds between events
    self.maxEventInterval = 180 -- Maximum 3 minutes between events
    
    -- Active events
    self.activeEvents = {}
    self.eventHistory = {}
    
    -- Room-specific event definitions
    self.roomEvents = {
        personal_office = {
            "urgent_email", "strategic_insight", "vendor_call", "market_analysis",
            "security_alert", "client_referral", "industry_news"
        },
        main_office_floor = {
            "team_collaboration", "skill_sharing", "equipment_failure", "productivity_surge",
            "mentorship_moment", "innovation_spark", "workflow_optimization"
        },
        hr_office = {
            "recruitment_lead", "team_conflict", "training_opportunity", "performance_review",
            "workplace_wellness", "policy_update", "team_building_idea"
        },
        kitchen_break_room = {
            "informal_networking", "creative_breakthrough", "team_bonding", "stress_relief",
            "celebration_moment", "casual_learning", "morale_boost"
        },
        server_room = {
            "hardware_upgrade", "system_optimization", "security_patch", "performance_spike",
            "backup_completion", "monitoring_alert", "efficiency_gain"
        },
        conference_room = {
            "client_presentation", "strategy_session", "partnership_opportunity", "contract_negotiation",
            "stakeholder_meeting", "board_review", "expansion_planning"
        },
        emergency_response_center = {
            "threat_detected", "incident_resolved", "security_drill", "threat_intelligence",
            "crisis_averted", "response_optimization", "forensic_discovery"
        }
    }
    
    -- Event definitions with outcomes
    self.eventDefinitions = {
        -- Personal Office Events
        urgent_email = {
            title = "📧 Urgent Client Email",
            description = "A high-priority client needs immediate attention.",
            choices = {
                { text = "Handle immediately", effect = { reputation = 3, stress = 5 } },
                { text = "Schedule for later", effect = { reputation = 1, efficiency = 2 } },
                { text = "Delegate to team", effect = { team_experience = 2, reputation = 2 } }
            },
            duration = 60
        },
        
        strategic_insight = {
            title = "💡 Strategic Insight",
            description = "While reviewing reports, you identify a new market opportunity.",
            choices = {
                { text = "Develop business plan", effect = { strategy_points = 10, money = -500 } },
                { text = "Research further", effect = { research_bonus = 1.5, time = 30 } },
                { text = "Share with team", effect = { team_morale = 5, collaboration = 2 } }
            },
            duration = 90
        },
        
        -- Main Office Floor Events
        team_collaboration = {
            title = "👥 Spontaneous Collaboration",
            description = "Your team naturally forms a problem-solving group around a complex issue.",
            choices = {
                { text = "Encourage the collaboration", effect = { productivity = 1.3, team_synergy = 5 } },
                { text = "Provide additional resources", effect = { money = -200, innovation = 3 } },
                { text = "Document the process", effect = { knowledge_base = 2, future_efficiency = 1.1 } }
            },
            duration = 45
        },
        
        equipment_failure = {
            title = "⚠️ Equipment Malfunction",
            description = "A critical workstation has failed during peak hours.",
            choices = {
                { text = "Emergency repair", effect = { money = -800, downtime = -30 } },
                { text = "Temporary workaround", effect = { productivity = 0.8, team_stress = 3 } },
                { text = "Upgrade opportunity", effect = { money = -1500, efficiency = 1.2, morale = 2 } }
            },
            duration = 20,
            urgent = true
        },
        
        -- HR Office Events
        recruitment_lead = {
            title = "🎯 Exceptional Candidate",
            description = "A highly skilled cybersecurity expert is interested in joining your team.",
            choices = {
                { text = "Fast-track interview", effect = { money = -1000, specialist_quality = 1.5 } },
                { text = "Standard process", effect = { reputation = 1, specialist_chance = 0.8 } },
                { text = "Negotiate terms", effect = { money = -500, specialist_loyalty = 1.3 } }
            },
            duration = 120
        },
        
        team_conflict = {
            title = "⚡ Team Tension",
            description = "Disagreements between team members are affecting productivity.",
            choices = {
                { text = "Mediate directly", effect = { team_harmony = 5, leadership_exp = 2 } },
                { text = "Team building activity", effect = { money = -300, morale = 8, productivity = 1.1 } },
                { text = "Individual meetings", effect = { time = -60, team_understanding = 3 } }
            },
            duration = 30,
            negative = true
        },
        
        -- Kitchen Events
        informal_networking = {
            title = "☕ Coffee Connection",
            description = "Casual conversations lead to valuable professional connections.",
            choices = {
                { text = "Join the conversation", effect = { network_strength = 3, morale = 2 } },
                { text = "Introduce new topics", effect = { team_knowledge = 2, creativity = 1.2 } },
                { text = "Plan regular sessions", effect = { money = -100, ongoing_networking = 1.15 } }
            },
            duration = 15
        },
        
        creative_breakthrough = {
            title = "🌟 Innovation Moment",
            description = "Relaxed atmosphere sparks a creative solution to a longstanding problem.",
            choices = {
                { text = "Develop immediately", effect = { innovation_points = 5, excitement = 3 } },
                { text = "Research feasibility", effect = { research_data = 3, risk_reduction = 0.1 } },
                { text = "Team brainstorm", effect = { team_creativity = 1.3, collective_intelligence = 2 } }
            },
            duration = 75
        },
        
        -- Server Room Events
        hardware_upgrade = {
            title = "🔧 Upgrade Opportunity",
            description = "New hardware becomes available that could significantly boost performance.",
            choices = {
                { text = "Purchase upgrade", effect = { money = -2000, processing_power = 1.4 } },
                { text = "Evaluate options", effect = { time = -30, better_deals = 1.2 } },
                { text = "Gradual upgrade", effect = { money = -800, steady_improvement = 1.15 } }
            },
            duration = 60
        },
        
        security_patch = {
            title = "🛡️ Critical Security Update",
            description = "A crucial security vulnerability needs immediate attention.",
            choices = {
                { text = "Immediate patch", effect = { security_rating = 5, reputation = 2 } },
                { text = "Test thoroughly first", effect = { time = -45, stability = 1.2, security_rating = 3 } },
                { text = "Schedule maintenance", effect = { planned_downtime = 30, security_rating = 4, efficiency = 1.1 } }
            },
            duration = 30,
            urgent = true
        },
        
        -- Conference Room Events
        client_presentation = {
            title = "🎯 High-Stakes Presentation",
            description = "A major client wants to see your capabilities in action.",
            choices = {
                { text = "Full demonstration", effect = { reputation = 5, contract_value = 1.3, pressure = 8 } },
                { text = "Conservative approach", effect = { reputation = 2, client_confidence = 1.1 } },
                { text = "Interactive session", effect = { client_engagement = 1.4, long_term_relationship = 1.2 } }
            },
            duration = 120
        },
        
        -- Emergency Response Center Events
        threat_detected = {
            title = "🚨 Active Threat Detected",
            description = "Your monitoring systems have identified a potential security breach.",
            choices = {
                { text = "Immediate response", effect = { threat_mitigation = 0.9, team_stress = 5, reputation = 3 } },
                { text = "Analyze first", effect = { time = -15, threat_understanding = 2, response_quality = 1.2 } },
                { text = "Coordinate response", effect = { team_coordination = 1.3, response_time = 1.1, leadership = 2 } }
            },
            duration = 45,
            urgent = true,
            critical = true
        },
        
        incident_resolved = {
            title = "✅ Crisis Successfully Managed",
            description = "Your team has successfully contained and resolved a major security incident.",
            choices = {
                { text = "Celebrate success", effect = { team_morale = 8, confidence = 1.2, reputation = 4 } },
                { text = "Document lessons", effect = { knowledge_base = 5, future_preparedness = 1.3 } },
                { text = "Client briefing", effect = { client_trust = 1.4, transparency_bonus = 2, reputation = 3 } }
            },
            duration = 30,
            positive = true
        }
    }
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to system events
function RoomEventSystem:subscribeToEvents()
    -- Listen for room changes to potentially trigger events
    self.eventBus:subscribe("room_changed", function(data)
        self:onRoomChanged(data.to, data.from)
    end)
    
    -- Listen for player interactions that might trigger events
    self.eventBus:subscribe("area_interaction", function(data)
        self:onAreaInteraction(data.areaId, data.roomId)
    end)
    
    -- Listen for resource changes that might affect event outcomes
    self.eventBus:subscribe("resource_updated", function(data)
        self:updateActiveEvents(data)
    end)
end

-- Handle room change events
function RoomEventSystem:onRoomChanged(newRoomId, oldRoomId)
    -- Chance for room-specific event when entering
    if math.random() < 0.15 then -- 15% chance
        self:scheduleRoomEvent(newRoomId, 5) -- Schedule event in 5 seconds
    end
end

-- Handle area interactions that might trigger events
function RoomEventSystem:onAreaInteraction(areaId, roomId)
    -- Some interactions have a chance to trigger events
    if math.random() < 0.1 then -- 10% chance
        self:scheduleRoomEvent(roomId, 2) -- Quick event
    end
end

-- Update system
function RoomEventSystem:update(dt)
    -- Update event cooldown
    if self.eventCooldown > 0 then
        self.eventCooldown = self.eventCooldown - dt
    end
    
    -- Check for scheduled events
    self.nextEventTime = self.nextEventTime - dt
    if self.nextEventTime <= 0 and self.eventCooldown <= 0 then
        self:triggerRandomEvent()
    end
    
    -- Update active events
    for eventId, event in pairs(self.activeEvents) do
        if event.duration then
            event.duration = event.duration - dt
            if event.duration <= 0 then
                self:resolveEvent(eventId)
            end
        end
    end
end

-- Trigger a random event based on current room
function RoomEventSystem:triggerRandomEvent()
    if not self.roomSystem then return end
    
    local currentRoom = self.roomSystem:getCurrentRoom()
    if not currentRoom then return end
    
    local roomEvents = self.roomEvents[currentRoom.id]
    if not roomEvents or #roomEvents == 0 then return end
    
    -- Select random event
    local eventType = roomEvents[math.random(#roomEvents)]
    self:triggerEvent(eventType, currentRoom.id)
    
    -- Schedule next event
    self:scheduleNextEvent()
end

-- Schedule a specific room event
function RoomEventSystem:scheduleRoomEvent(roomId, delay)
    if not self.roomEvents[roomId] then return end
    
    local roomEvents = self.roomEvents[roomId]
    local eventType = roomEvents[math.random(#roomEvents)]
    
    -- Schedule the event
    self.nextEventTime = delay or math.random(10, 30)
end

-- Trigger a specific event
function RoomEventSystem:triggerEvent(eventType, roomId)
    local eventDef = self.eventDefinitions[eventType]
    if not eventDef then return end
    
    local eventId = "event_" .. os.time() .. "_" .. math.random(1000)
    
    -- Create event instance
    local event = {
        id = eventId,
        type = eventType,
        roomId = roomId,
        definition = eventDef,
        startTime = os.time(),
        duration = eventDef.duration,
        active = true
    }
    
    self.activeEvents[eventId] = event
    
    -- Emit event for UI systems
    self.eventBus:publish("room_event_triggered", {
        event = event,
        roomId = roomId
    })
    
    -- Print event notification
    local urgentPrefix = eventDef.urgent and "⚡ URGENT: " or eventDef.critical and "🔥 CRITICAL: " or ""
    print(urgentPrefix .. eventDef.title)
    print("📍 " .. (roomId:gsub("_", " "):gsub("^%l", string.upper)) .. " - " .. eventDef.description)
    
    if eventDef.choices then
        print("💭 Options:")
        for i, choice in ipairs(eventDef.choices) do
            print("   " .. i .. ". " .. choice.text)
        end
        print("Choose option (1-" .. #eventDef.choices .. ") or wait for auto-resolve...")
    end
    
    -- Set cooldown
    self.eventCooldown = 10 -- Minimum 10 seconds between events
end

-- Resolve an event (automatically or by choice)
function RoomEventSystem:resolveEvent(eventId, choiceIndex)
    local event = self.activeEvents[eventId]
    if not event then return end
    
    local choice = nil
    if choiceIndex and event.definition.choices then
        choice = event.definition.choices[choiceIndex]
    elseif event.definition.choices then
        -- Auto-resolve with random choice
        choice = event.definition.choices[math.random(#event.definition.choices)]
    end
    
    -- Apply effects
    if choice and choice.effect then
        self:applyEventEffects(choice.effect, event)
        print("✅ Event resolved: " .. choice.text)
    else
        print("⏰ Event timed out: " .. event.definition.title)
    end
    
    -- Record in history
    table.insert(self.eventHistory, {
        type = event.type,
        roomId = event.roomId,
        resolvedAt = os.time(),
        choice = choice,
        duration = event.definition.duration - (event.duration or 0)
    })
    
    -- Remove from active events
    self.activeEvents[eventId] = nil
    
    -- Emit resolution event
    self.eventBus:publish("room_event_resolved", {
        eventId = eventId,
        event = event,
        choice = choice
    })
end

-- Apply event effects to game systems
function RoomEventSystem:applyEventEffects(effects, event)
    for effectType, value in pairs(effects) do
        if effectType == "money" then
            self.eventBus:publish("add_resource", { resource = "money", amount = value })
        elseif effectType == "reputation" then
            self.eventBus:publish("add_resource", { resource = "reputation", amount = value })
        elseif effectType == "xp" then
            self.eventBus:publish("add_resource", { resource = "xp", amount = value })
        elseif effectType == "team_morale" then
            self.eventBus:publish("team_morale_change", { amount = value, source = "room_event" })
        elseif effectType == "productivity" then
            self.eventBus:publish("productivity_bonus", { multiplier = value, duration = 300, source = "room_event" })
        elseif effectType == "security_rating" then
            self.eventBus:publish("security_boost", { amount = value, source = "room_event" })
        else
            -- Generic effect - just log it
            print("   📊 " .. effectType .. ": " .. tostring(value))
        end
    end
end

-- Schedule next random event
function RoomEventSystem:scheduleNextEvent()
    self.nextEventTime = math.random(self.minEventInterval, self.maxEventInterval)
end

-- Player choice handling
function RoomEventSystem:makeEventChoice(eventId, choiceIndex)
    local event = self.activeEvents[eventId]
    if not event or not event.definition.choices then
        return false
    end
    
    if choiceIndex < 1 or choiceIndex > #event.definition.choices then
        return false
    end
    
    self:resolveEvent(eventId, choiceIndex)
    return true
end

-- Get active events for UI display
function RoomEventSystem:getActiveEvents()
    local events = {}
    for eventId, event in pairs(self.activeEvents) do
        table.insert(events, {
            id = eventId,
            title = event.definition.title,
            description = event.definition.description,
            choices = event.definition.choices,
            duration = event.duration,
            urgent = event.definition.urgent,
            critical = event.definition.critical,
            roomId = event.roomId
        })
    end
    return events
end

-- Get event history for statistics
function RoomEventSystem:getEventHistory(limit)
    limit = limit or 10
    local history = {}
    for i = math.max(1, #self.eventHistory - limit + 1), #self.eventHistory do
        table.insert(history, self.eventHistory[i])
    end
    return history
end

-- Get current state for saving
function RoomEventSystem:getState()
    return {
        activeEvents = self.activeEvents,
        eventHistory = self.eventHistory,
        nextEventTime = self.nextEventTime,
        eventCounter = self.eventCounter,
        minEventInterval = self.minEventInterval,
        maxEventInterval = self.maxEventInterval
    }
end

-- Load state from save data
function RoomEventSystem:loadState(state)
    if not state then return end
    
    self.activeEvents = state.activeEvents or {}
    self.eventHistory = state.eventHistory or {}
    self.nextEventTime = state.nextEventTime or math.random(self.minEventInterval, self.maxEventInterval)
    self.eventCounter = state.eventCounter or 0
    self.minEventInterval = state.minEventInterval or self.minEventInterval
    self.maxEventInterval = state.maxEventInterval or self.maxEventInterval
end

return RoomEventSystem