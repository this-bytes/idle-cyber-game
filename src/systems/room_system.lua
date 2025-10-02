-- Not Implemented Yet
-- Appart of a room system i was thinking of
-- Room System
-- Manages multiple room environments, transitions, and room-specific mechanics

local RoomSystem = {}
RoomSystem.__index = RoomSystem

-- Create new room system
function RoomSystem.new(eventBus)
    local self = setmetatable({}, RoomSystem)
    self.eventBus = eventBus
    
    -- Current room state
    self.currentRoom = "personal_office"
    self.previousRoom = nil
    self.transitionTime = 0
    self.isTransitioning = false
    
    -- Room definitions with cybersecurity consultancy theme
    self.rooms = {
        personal_office = {
            id = "personal_office",
            name = "📋 Personal Office",
            description = "Your private workspace for strategic planning",
            width = 640,
            height = 400,
            
            -- Visual styling
            bgColor = {0.08, 0.12, 0.16, 1},
            gridColor = {0.12, 0.18, 0.24, 0.4},
            wallColor = {0.15, 0.25, 0.35, 1},
            
            -- Interactive areas (departments/stations)
            areas = {
                { id = "desk", name = "Executive Desk", x = 320, y = 200, radius = 35, 
                  action = "strategic_planning", icon = "💼" },
                { id = "bookshelf", name = "Technical Library", x = 120, y = 120, radius = 30,
                  action = "research_boost", icon = "📚" },
                { id = "secure_phone", name = "Encrypted Communications", x = 520, y = 120, radius = 25,
                  action = "client_contact", icon = "📞" },
                { id = "monitor_wall", name = "Threat Intelligence Display", x = 320, y = 80, radius = 40,
                  action = "threat_analysis", icon = "🖥️" }
            },
            
            -- Room-specific bonuses and mechanics
            bonuses = {
                strategyPointsMultiplier = 1.5,
                researchEfficiency = 1.2,
                clientSatisfactionBonus = 0.1
            },
            
            -- Environmental effects
            atmosphere = "Focused and strategic environment for high-level decision making",
            unlocked = true,
            maxOccupancy = 1
        },
        
        main_office_floor = {
            id = "main_office_floor",
            name = "🏢 Main Office Floor",
            description = "Bustling workspace where your team collaborates",
            width = 800,
            height = 500,
            
            bgColor = {0.06, 0.10, 0.14, 1},
            gridColor = {0.10, 0.16, 0.20, 0.4},
            wallColor = {0.12, 0.20, 0.28, 1},
            
            areas = {
                { id = "workstation_1", name = "Security Analyst Station", x = 150, y = 150, radius = 30,
                  action = "security_analysis", icon = "🛡️" },
                { id = "workstation_2", name = "Incident Response Desk", x = 350, y = 150, radius = 30,
                  action = "incident_response", icon = "🚨" },
                { id = "workstation_3", name = "Penetration Testing Lab", x = 550, y = 150, radius = 30,
                  action = "pen_testing", icon = "🎯" },
                { id = "collaboration_area", name = "Team Collaboration Zone", x = 400, y = 300, radius = 50,
                  action = "team_synergy", icon = "👥" },
                { id = "printer_station", name = "Secure Document Center", x = 650, y = 350, radius = 25,
                  action = "document_security", icon = "🖨️" },
                { id = "coffee_corner", name = "Informal Meeting Corner", x = 100, y = 350, radius = 30,
                  action = "team_morale_boost", icon = "☕" }
            },
            
            bonuses = {
                teamProductivityMultiplier = 1.8,
                collaborationBonus = 1.5,
                incidentResponseSpeed = 1.3
            },
            
            atmosphere = "Dynamic collaborative environment with multiple specialist teams",
            unlocked = false,
            unlockRequirements = { reputation = 5, money = 2000 },
            maxOccupancy = 8
        },
        
        hr_office = {
            id = "hr_office",
            name = "👤 HR Department",
            description = "Human resources and team development center",
            width = 500,
            height = 350,
            
            bgColor = {0.10, 0.08, 0.12, 1},
            gridColor = {0.16, 0.12, 0.18, 0.4},
            wallColor = {0.20, 0.15, 0.25, 1},
            
            areas = {
                { id = "hr_desk", name = "HR Manager Desk", x = 250, y = 175, radius = 35,
                  action = "staff_management", icon = "👔" },
                { id = "interview_room", name = "Interview Room", x = 120, y = 120, radius = 40,
                  action = "recruit_specialist", icon = "🎤" },
                { id = "training_corner", name = "Professional Development", x = 380, y = 120, radius = 35,
                  action = "skill_training", icon = "📈" },
                { id = "personnel_files", name = "Secure Personnel Files", x = 380, y = 250, radius = 25,
                  action = "background_check", icon = "📁" }
            },
            
            bonuses = {
                recruitmentEfficiency = 2.0,
                trainingSpeedBonus = 1.6,
                teamLoyaltyBonus = 1.4,
                specialistRetention = 1.8
            },
            
            atmosphere = "Professional environment focused on human capital development",
            unlocked = false,
            unlockRequirements = { reputation = 10, specialists = 2 },
            maxOccupancy = 4
        },
        
        kitchen_break_room = {
            id = "kitchen_break_room",
            name = "🍽️ Kitchen & Break Room",
            description = "Relaxation space that boosts team morale and creativity",
            width = 450,
            height = 300,
            
            bgColor = {0.12, 0.10, 0.08, 1},
            gridColor = {0.18, 0.16, 0.12, 0.4},
            wallColor = {0.24, 0.20, 0.16, 1},
            
            areas = {
                { id = "kitchen_counter", name = "Kitchen Area", x = 120, y = 150, radius = 40,
                  action = "team_bonding", icon = "🥪" },
                { id = "coffee_machine", name = "Premium Coffee Station", x = 220, y = 100, radius = 25,
                  action = "energy_boost", icon = "☕" },
                { id = "lounge_area", name = "Comfortable Seating", x = 330, y = 180, radius = 45,
                  action = "creative_thinking", icon = "🛋️" },
                { id = "game_corner", name = "Recreation Area", x = 300, y = 80, radius = 30,
                  action = "stress_relief", icon = "🎮" }
            },
            
            bonuses = {
                teamMoraleMultiplier = 2.5,
                creativityBonus = 1.8,
                stressReduction = 0.3,
                informalNetworking = 1.6
            },
            
            atmosphere = "Relaxed social environment that fosters team chemistry and innovation",
            unlocked = false,
            unlockRequirements = { specialists = 3, money = 5000 },
            maxOccupancy = 10
        },
        
        server_room = {
            id = "server_room",
            name = "💾 Server Room",
            description = "High-security technical infrastructure center",
            width = 400,
            height = 400,
            
            bgColor = {0.02, 0.06, 0.10, 1},
            gridColor = {0.04, 0.12, 0.16, 0.6},
            wallColor = {0.08, 0.16, 0.24, 1},
            
            areas = {
                { id = "main_servers", name = "Primary Server Rack", x = 200, y = 150, radius = 50,
                  action = "infrastructure_upgrade", icon = "🖥️" },
                { id = "backup_systems", name = "Backup & Recovery Systems", x = 120, y = 280, radius = 35,
                  action = "data_protection", icon = "💿" },
                { id = "network_hub", name = "Network Operations Center", x = 280, y = 280, radius = 35,
                  action = "network_monitoring", icon = "🌐" },
                { id = "security_terminal", name = "Security Control Panel", x = 200, y = 50, radius = 30,
                  action = "security_hardening", icon = "🔒" }
            },
            
            bonuses = {
                processingPowerMultiplier = 3.0,
                dataSecurityBonus = 2.5,
                uptimeReliability = 1.9,
                incidentDetectionSpeed = 2.2
            },
            
            atmosphere = "High-tech secure environment with critical infrastructure systems",
            unlocked = false,
            unlockRequirements = { reputation = 25, facilities = 3 },
            maxOccupancy = 2
        },
        
        conference_room = {
            id = "conference_room",
            name = "🤝 Conference Room",
            description = "Professional meeting space for client presentations",
            width = 600,
            height = 350,
            
            bgColor = {0.08, 0.10, 0.12, 1},
            gridColor = {0.12, 0.16, 0.20, 0.3},
            wallColor = {0.16, 0.22, 0.28, 1},
            
            areas = {
                { id = "conference_table", name = "Executive Conference Table", x = 300, y = 175, radius = 60,
                  action = "client_meeting", icon = "🎯" },
                { id = "presentation_screen", name = "Smart Presentation Display", x = 300, y = 80, radius = 40,
                  action = "proposal_presentation", icon = "📊" },
                { id = "whiteboard", name = "Strategic Planning Board", x = 500, y = 175, radius = 30,
                  action = "strategy_session", icon = "📝" },
                { id = "secure_phone_booth", name = "Confidential Communications", x = 100, y = 280, radius = 25,
                  action = "classified_discussion", icon = "📱" }
            },
            
            bonuses = {
                clientImpressionBonus = 2.8,
                contractNegotiationBonus = 2.0,
                strategicPlanningBonus = 1.7,
                professionalReputationBonus = 1.5
            },
            
            atmosphere = "Professional and impressive environment designed to win client confidence",
            unlocked = false,
            unlockRequirements = { reputation = 40, completedContracts = 5 },
            maxOccupancy = 12
        },
        
        emergency_response_center = {
            id = "emergency_response_center",
            name = "🚨 Emergency Response Center",
            description = "24/7 Incident management and incident response headquarters",
            width = 700,
            height = 450,
            
            bgColor = {0.06, 0.02, 0.02, 1},
            gridColor = {0.12, 0.04, 0.04, 0.6},
            wallColor = {0.18, 0.06, 0.06, 1},
            
            areas = {
                { id = "command_center", name = "Incident Command Center", x = 350, y = 225, radius = 70,
                  action = "Incident_management", icon = "⚡" },
                { id = "threat_monitoring", name = "Threat Intelligence Station", x = 150, y = 150, radius = 40,
                  action = "threat_hunting", icon = "🎯" },
                { id = "communication_hub", name = "Emergency Communications", x = 550, y = 150, radius = 35,
                  action = "emergency_coordination", icon = "📡" },
                { id = "forensics_station", name = "Digital Forensics Lab", x = 150, y = 300, radius = 35,
                  action = "incident_analysis", icon = "🔍" },
                { id = "response_deployment", name = "Rapid Response Deployment", x = 550, y = 300, radius = 40,
                  action = "deploy_countermeasures", icon = "🛡️" }
            },
            
            bonuses = {
                IncidentResponseSpeed = 4.0,
                threatMitigationEfficiency = 3.5,
                emergencyCoordinationBonus = 2.8,
                reputationDamageReduction = 0.6
            },
            
            atmosphere = "High-intensity command center optimized for rapid Incident response",
            unlocked = false,
            unlockRequirements = { reputation = 60, threatLevel = "High", completedContracts = 15 },
            maxOccupancy = 6
        }
    }
    
    -- Subscribe to relevant events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to system events
function RoomSystem:subscribeToEvents()
    -- Listen for room change requests
    self.eventBus:subscribe("change_room", function(data)
        self:changeRoom(data.roomId, data.reason)
    end)
    
    -- Listen for area interactions
    self.eventBus:subscribe("interact_with_area", function(data)
        self:handleAreaInteraction(data.areaId, data.playerId)
    end)
    
    -- Listen for resource updates that might unlock rooms
    self.eventBus:subscribe("resource_updated", function(data)
        self:checkRoomUnlocks(data.resourceSystem)
    end)
    
    -- Listen for game state updates
    self.eventBus:subscribe("game_state_loaded", function(data)
        self:checkRoomUnlocks(data.resourceSystem)
    end)
end

-- Change to a different room
function RoomSystem:changeRoom(newRoomId, reason)
    if not self.rooms[newRoomId] then
        print("❌ Room not found: " .. tostring(newRoomId))
        return false
    end
    
    local newRoom = self.rooms[newRoomId]
    if not newRoom.unlocked then
        print("🔒 Room locked: " .. newRoom.name)
        self:displayUnlockRequirements(newRoom)
        return false
    end
    
    -- Start transition
    self.previousRoom = self.currentRoom
    self.currentRoom = newRoomId
    self.isTransitioning = true
    self.transitionTime = 0.5 -- Half second transition
    
    -- Track room usage for achievements
    if not newRoom.visitCount then
        newRoom.visitCount = 0
        newRoom.firstVisit = os.time()
    end
    newRoom.visitCount = newRoom.visitCount + 1
    newRoom.lastVisit = os.time()
    
    -- Emit room change event
    self.eventBus:publish("room_changed", {
        from = self.previousRoom,
        to = self.currentRoom,
        reason = reason or "player_action",
        visitCount = newRoom.visitCount
    })
    
    -- Achievement check
    if newRoom.visitCount == 1 then
        self.eventBus:publish("achievement_progress", { 
            id = "room_explorer", 
            progress = 1,
            data = { roomId = newRoomId, roomName = newRoom.name }
        })
    end
    
    print("🚪 Moved to " .. newRoom.name .. " - " .. newRoom.description)
    
    -- Give small XP bonus for exploring new rooms
    if newRoom.visitCount == 1 then
        self.eventBus:publish("add_resource", { resource = "xp", amount = 5 })
        print("✨ +5 XP for exploring a new room!")
    end
    
    return true
end

-- Handle interaction with room areas
function RoomSystem:handleAreaInteraction(areaId, playerId)
    local currentRoom = self.rooms[self.currentRoom]
    if not currentRoom then return end
    
    -- Find the area
    local area = nil
    for _, a in ipairs(currentRoom.areas) do
        if a.id == areaId then
            area = a
            break
        end
    end
    
    if not area then
        print("❌ Area not found: " .. tostring(areaId))
        return
    end
    
    -- Execute area-specific action
    self:executeAreaAction(area, currentRoom)
end

-- Execute specific area actions
function RoomSystem:executeAreaAction(area, room)
    local action = area.action
    local bonusMultiplier = self:calculateRoomBonuses(room)
    
    -- Area-specific actions with room bonuses
    if action == "strategic_planning" then
        local strategyPoints = math.floor(10 * (room.bonuses.strategyPointsMultiplier or 1))
        self.eventBus:publish("add_resource", { resource = "strategyPoints", amount = strategyPoints })
        print("💼 Strategic planning session: +" .. strategyPoints .. " Strategy Points")
        
    elseif action == "research_boost" then
        local researchBonus = math.floor(15 * (room.bonuses.researchEfficiency or 1))
        self.eventBus:publish("research_accelerated", { bonus = researchBonus })
        print("📚 Research acceleration: +" .. researchBonus .. "% research speed for 5 minutes")
        
    elseif action == "client_contact" then
        self.eventBus:publish("generate_contract_opportunity", { quality = "high" })
        print("📞 Client outreach successful: New high-quality contract opportunity generated")
        
    elseif action == "threat_analysis" then
        local threatReduction = 0.1 * (room.bonuses.strategicPlanningBonus or 1)
        self.eventBus:publish("threat_analysis_completed", { reduction = threatReduction })
        print("🖥️ Threat analysis: Reduced threat level and improved defenses")
        
    elseif action == "security_analysis" then
        local securityBonus = math.floor(20 * (room.bonuses.teamProductivityMultiplier or 1))
        self.eventBus:publish("add_resource", { resource = "securityRating", amount = securityBonus })
        print("🛡️ Security analysis complete: +" .. securityBonus .. " Security Rating")
        
    elseif action == "incident_response" then
        local responseBonus = room.bonuses.incidentResponseSpeed or 1
        self.eventBus:publish("incident_response_drill", { efficiency = responseBonus })
        print("🚨 Incident response drill: Improved response time by " .. math.floor((responseBonus - 1) * 100) .. "%")
        
    elseif action == "team_synergy" then
        local synergyBonus = room.bonuses.collaborationBonus or 1
        self.eventBus:publish("team_synergy_activated", { multiplier = synergyBonus })
        print("👥 Team collaboration: All activities boosted by " .. math.floor((synergyBonus - 1) * 100) .. "% for 10 minutes")
        
    elseif action == "recruit_specialist" then
        local recruitmentBonus = room.bonuses.recruitmentEfficiency or 1
        self.eventBus:publish("recruitment_opportunity", { efficiency = recruitmentBonus })
        print("👔 Recruitment drive: Discovered " .. math.floor(recruitmentBonus * 2) .. " potential specialist candidates")
        
    elseif action == "team_bonding" then
        local moraleBonus = room.bonuses.teamMoraleMultiplier or 1
        self.eventBus:publish("team_morale_boost", { multiplier = moraleBonus })
        print("🥪 Team bonding: Morale boosted, productivity increased by " .. math.floor((moraleBonus - 1) * 100) .. "%")
        
    elseif action == "infrastructure_upgrade" then
        local processingBonus = room.bonuses.processingPowerMultiplier or 1
        self.eventBus:publish("infrastructure_enhanced", { multiplier = processingBonus })
        print("💾 Infrastructure upgrade: Processing power increased by " .. math.floor((processingBonus - 1) * 100) .. "%")
        
    elseif action == "client_meeting" then
        local impressionBonus = room.bonuses.clientImpressionBonus or 1
        self.eventBus:publish("client_meeting_success", { impression = impressionBonus })
        print("🤝 Client meeting: Exceptional impression, contract value increased by " .. math.floor((impressionBonus - 1) * 100) .. "%")
        
    elseif action == "Incident_management" then
        local IncidentBonus = room.bonuses.IncidentResponseSpeed or 1
        self.eventBus:publish("Incident_management_drill", { speed = IncidentBonus })
        print("⚡ Incident management: Response protocols optimized, speed increased by " .. math.floor((IncidentBonus - 1) * 100) .. "%")
        
    else
        -- Generic action
        print("✨ " .. area.name .. ": Completed " .. action)
    end
    
    -- Add base interaction rewards
    self.eventBus:publish("add_resource", { resource = "xp", amount = 5 })
    self.eventBus:publish("add_resource", { resource = "reputation", amount = 1 })
end

-- Calculate combined room bonuses
function RoomSystem:calculateRoomBonuses(room)
    local total = 1.0
    for _, bonus in pairs(room.bonuses or {}) do
        if type(bonus) == "number" and bonus > 1 then
            total = total * bonus
        end
    end
    return total
end

-- Check if any rooms should be unlocked
function RoomSystem:checkRoomUnlocks(resourceSystem)
    if not resourceSystem then return end
    
    local unlockedAny = false
    for roomId, room in pairs(self.rooms) do
        if not room.unlocked and room.unlockRequirements then
            if self:evaluateUnlockRequirements(room, resourceSystem) then
                room.unlocked = true
                unlockedAny = true
                self.eventBus:publish("room_unlocked", { roomId = roomId, room = room })
                print("🔓 Room unlocked: " .. room.name .. " - " .. room.description)
            end
        end
    end
    
    return unlockedAny
end

-- Evaluate if room unlock requirements are met
function RoomSystem:evaluateUnlockRequirements(room, resourceSystem)
    if not room.unlockRequirements then return true end
    
    for requirement, value in pairs(room.unlockRequirements) do
        if requirement == "money" then
            if resourceSystem:getResource("money") < value then
                return false
            end
        elseif requirement == "reputation" then
            if resourceSystem:getResource("reputation") < value then
                return false
            end
        elseif requirement == "specialists" then
            if resourceSystem:getResource("specialists") < value then
                return false
            end
        elseif requirement == "xp" then
            if resourceSystem:getResource("xp") < value then
                return false
            end
        elseif requirement == "facilities" then
            if resourceSystem:getResource("facilities") < value then
                return false
            end
        elseif requirement == "completedContracts" then
            -- This would need to be tracked by contract system
            -- For now, assume it's satisfied if reputation is high enough
            if resourceSystem:getResource("reputation") < value * 5 then
                return false
            end
        elseif requirement == "securityRating" then
            -- This would need to be tracked by a security system
            -- For now, assume it's satisfied if facilities are upgraded
            if resourceSystem:getResource("facilities") < value / 10 then
                return false
            end
        elseif requirement == "threatLevel" then
            -- This is a special case - requires high threat level
            -- We'll assume this is unlocked through story progression
            -- For now, unlock if reputation is very high
            if resourceSystem:getResource("reputation") < 150 then
                return false
            end
        end
    end
    
    return true
end

-- Display unlock requirements for a room
function RoomSystem:displayUnlockRequirements(room)
    print("🔓 To unlock " .. room.name .. ":")
    if room.unlockRequirements then
        for req, value in pairs(room.unlockRequirements) do
            print("   • " .. req .. ": " .. tostring(value))
        end
    end
end

-- Update room system
function RoomSystem:update(dt)
    -- Handle room transitions
    if self.isTransitioning then
        self.transitionTime = self.transitionTime - dt
        if self.transitionTime <= 0 then
            self.isTransitioning = false
        end
    end
end

-- Connect to resource system for unlocking
function RoomSystem:connectResourceSystem(resourceSystem)
    self.resourceSystem = resourceSystem
    self:checkRoomUnlocks(resourceSystem)
end

-- Get current room data
function RoomSystem:getCurrentRoom()
    return self.rooms[self.currentRoom]
end

-- Get all available rooms
function RoomSystem:getAvailableRooms()
    local available = {}
    for roomId, room in pairs(self.rooms) do
        if room.unlocked then
            table.insert(available, {
                id = roomId,
                name = room.name,
                description = room.description,
                current = roomId == self.currentRoom
            })
        end
    end
    return available
end

-- Unlock a room (for external systems)
function RoomSystem:unlockRoom(roomId)
    if self.rooms[roomId] then
        self.rooms[roomId].unlocked = true
        self.eventBus:publish("room_unlocked", { roomId = roomId, room = self.rooms[roomId] })
        print("🔓 Unlocked: " .. self.rooms[roomId].name)
        return true
    end
    return false
end

-- Get current state for saving
function RoomSystem:getState()
    -- Collect room unlock status
    local roomUnlocks = {}
    for roomId, room in pairs(self.rooms) do
        if room.unlocked then
            roomUnlocks[roomId] = true
        end
    end
    
    return {
        currentRoom = self.currentRoom,
        previousRoom = self.previousRoom,
        transitionTime = self.transitionTime,
        isTransitioning = self.isTransitioning,
        -- Save unlock status for each room
        roomUnlocks = roomUnlocks
    }
end

-- Load state from save data
function RoomSystem:loadState(state)
    if not state then return end
    
    self.currentRoom = state.currentRoom or "personal_office"
    self.previousRoom = state.previousRoom
    self.transitionTime = state.transitionTime or 0
    self.isTransitioning = state.isTransitioning or false
    
    -- Restore room unlock status
    if state.roomUnlocks then
        for roomId, unlocked in pairs(state.roomUnlocks) do
            if self.rooms[roomId] and unlocked then
                self.rooms[roomId].unlocked = true
            end
        end
    end
end

return RoomSystem