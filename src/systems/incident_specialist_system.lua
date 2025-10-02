-- Incident and Specialist Management System
-- Implements the core architectural mechanics for Incident and Specialist Management
-- Strictly adheres to the GDD (03-core-mechanics.instructions.md) and technical architecture (11-technical-architecture.instructions.md)

local IncidentSpecialistSystem = {}
IncidentSpecialistSystem.__index = IncidentSpecialistSystem

-- ============================================================================
-- PHASE 1: DATA LOADING AND SYSTEM INITIALIZATION
-- ============================================================================

-- Create new incident specialist system
function IncidentSpecialistSystem.new(eventBus, resourceManager)
    local self = setmetatable({}, IncidentSpecialistSystem)
    
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Global GameState table to hold runtime state
    self.GameState = {
        Specialists = {},           -- Array of active, instantiated specialist objects
        IncidentsQueue = {},        -- Array of active Pending Incident objects (Alerts Queue)
        ThreatTemplates = {},       -- Loaded data from threats.json
        SpecialistTemplates = {},   -- Loaded data from specialists.json
        GlobalAutoResolveStat = 100, -- Placeholder value for idle resolution
        IncidentTimer = 0,          -- Current timer value
        IncidentTimerMax = 10,      -- Base time for threat check (randomized)
        nextIncidentId = 1,         -- ID counter for incidents
        UnlockedSpecialists = {}    -- Track which specialists are unlocked
    }
    
    return self
end

-- Initialize the system
function IncidentSpecialistSystem:initialize()
    print("🎯 IncidentSpecialistSystem: Initializing...")
    
    -- Load data from JSON files
    self:loadSpecialistsData()
    self:loadThreatsData()
    
    -- Initialize starting specialists
    self:initializeStartingSpecialists()
    
    -- Reset incident timer with randomization
    self:resetIncidentTimer()
    
    print("🎯 IncidentSpecialistSystem: Initialization complete!")
    print(string.format("   - Loaded %d threat templates", #self.GameState.ThreatTemplates))
    print(string.format("   - Loaded %d specialist templates", self:countSpecialistTemplates()))
    print(string.format("   - Initialized %d active specialists", #self.GameState.Specialists))
end

-- Load specialists from specialists.json
function IncidentSpecialistSystem:loadSpecialistsData()
    local json = require("src.utils.dkjson")
    
    -- Try to load from LÖVE filesystem
    if love and love.filesystem and love.filesystem.getInfo("src/data/specialists.json") then
        local content = love.filesystem.read("src/data/specialists.json")
        local data, pos, err = json.decode(content)
        
        if data and data.specialists then
            self.GameState.SpecialistTemplates = data.specialists
            print("   ✅ Loaded specialists from specialists.json")
        else
            print("   ❌ Failed to parse specialists.json: " .. tostring(err))
            self:loadFallbackSpecialists()
        end
    else
        -- Fallback for non-LÖVE environments
        local file = io.open("src/data/specialists.json", "r")
        if file then
            local content = file:read("*a")
            file:close()
            local data, pos, err = json.decode(content)
            
            if data and data.specialists then
                self.GameState.SpecialistTemplates = data.specialists
                print("   ✅ Loaded specialists from specialists.json")
            else
                print("   ❌ Failed to parse specialists.json: " .. tostring(err))
                self:loadFallbackSpecialists()
            end
        else
            print("   ⚠️  Could not find specialists.json, using fallback")
            self:loadFallbackSpecialists()
        end
    end
end

-- Fallback specialist data if JSON load fails
function IncidentSpecialistSystem:loadFallbackSpecialists()
    self.GameState.SpecialistTemplates = {
        intern = {
            id = "intern",
            name = "Security Intern",
            efficiency = 1.3,
            speed = 1.05,
            trace = 0.8,
            defense = 1.0
        },
        junior_analyst = {
            id = "junior_analyst",
            name = "Junior Security Analyst",
            efficiency = 2.0,
            speed = 1.1,
            trace = 1.0,
            defense = 1.1
        }
    }
end

-- Load threats from threats.json
function IncidentSpecialistSystem:loadThreatsData()
    local json = require("src.utils.dkjson")
    
    -- Try to load from LÖVE filesystem
    if love and love.filesystem and love.filesystem.getInfo("src/data/threats.json") then
        local content = love.filesystem.read("src/data/threats.json")
        local data, pos, err = json.decode(content)
        
        if data and type(data) == "table" then
            -- threats.json is an array
            self.GameState.ThreatTemplates = data
            print("   ✅ Loaded threats from threats.json")
        else
            print("   ❌ Failed to parse threats.json: " .. tostring(err))
            self:loadFallbackThreats()
        end
    else
        -- Fallback for non-LÖVE environments
        local file = io.open("src/data/threats.json", "r")
        if file then
            local content = file:read("*a")
            file:close()
            local data, pos, err = json.decode(content)
            
            if data and type(data) == "table" then
                self.GameState.ThreatTemplates = data
                print("   ✅ Loaded threats from threats.json")
            else
                print("   ❌ Failed to parse threats.json: " .. tostring(err))
                self:loadFallbackThreats()
            end
        else
            print("   ⚠️  Could not find threats.json, using fallback")
            self:loadFallbackThreats()
        end
    end
end

-- Fallback threat data if JSON load fails
function IncidentSpecialistSystem:loadFallbackThreats()
    self.GameState.ThreatTemplates = {
        {
            id = "phishing_attempt",
            name = "Phishing Email Campaign",
            baseSeverity = 3,
            baseTimeToResolve = 45
        },
        {
            id = "ddos_attack",
            name = "DDoS Attack",
            baseSeverity = 5,
            baseTimeToResolve = 30
        }
    }
end

-- Initialize 3-5 starting specialists from loaded data
function IncidentSpecialistSystem:initializeStartingSpecialists()
    -- Select specific specialists to start with
    local startingSpecialistIds = {"intern", "junior_analyst", "network_specialist"}
    
    for _, specialistId in ipairs(startingSpecialistIds) do
        local template = self.GameState.SpecialistTemplates[specialistId]
        if template then
            self:instantiateSpecialist(template)
        end
    end
end

-- Instantiate a specialist entity from a template
function IncidentSpecialistSystem:instantiateSpecialist(template)
    local specialist = {
        id = #self.GameState.Specialists + 1,
        templateId = template.id,
        name = template.name or template.displayName or "Unknown Specialist",
        
        -- GDD-required fields
        Level = 1,
        XP = 0,
        is_busy = false,
        cooldown_timer = 0,
        
        -- Stats from template (these serve as "Traits")
        efficiency = template.efficiency or 1.0,
        speed = template.speed or 1.0,
        trace = template.trace or 1.0,
        defense = template.defense or 1.0,
        
        -- Additional data
        abilities = template.abilities or {},
        description = template.description or ""
    }
    
    table.insert(self.GameState.Specialists, specialist)
    self.GameState.UnlockedSpecialists[template.id] = true
    
    print(string.format("   👤 Instantiated specialist: %s (ID: %d)", specialist.name, specialist.id))
    
    return specialist
end

-- Unlock and instantiate a new specialist
function IncidentSpecialistSystem:unlockSpecialist(templateId)
    if self.GameState.UnlockedSpecialists[templateId] then
        print(string.format("   ⚠️  Specialist %s is already unlocked", templateId))
        return false
    end
    
    local template = self.GameState.SpecialistTemplates[templateId]
    if not template then
        print(string.format("   ❌ Specialist template %s not found", templateId))
        return false
    end
    
    self:instantiateSpecialist(template)
    
    -- Publish event for UI notification
    if self.eventBus then
        self.eventBus:publish("specialist_unlocked", {
            templateId = templateId,
            name = template.name or template.displayName
        })
    end
    
    return true
end

-- Count specialist templates
function IncidentSpecialistSystem:countSpecialistTemplates()
    local count = 0
    for _ in pairs(self.GameState.SpecialistTemplates) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- PHASE 2: CORE LOOP AND SYSTEM LOGIC
-- ============================================================================

-- Main update function to be called from game loop
function IncidentSpecialistSystem:update(dt)
    -- Update incident generation timer
    self:Incident_Generate_and_Check(dt)
    
    -- Update resolution timers for assigned incidents
    self:Incident_Resolution_Update(dt)
    
    -- Update specialist cooldowns
    self:Specialist_Cooldown_Update(dt)
    
    -- Attempt auto-assignment for pending incidents
    self:Specialist_AutoAssign()
end

-- Reset incident timer with randomization for unpredictability
function IncidentSpecialistSystem:resetIncidentTimer()
    -- Randomize between 70% and 130% of base timer
    local randomFactor = 0.7 + (math.random() * 0.6)
    self.GameState.IncidentTimer = self.GameState.IncidentTimerMax * randomFactor
end

-- Incident generation and threat check
function IncidentSpecialistSystem:Incident_Generate_and_Check(dt)
    self.GameState.IncidentTimer = self.GameState.IncidentTimer - dt
    
    if self.GameState.IncidentTimer <= 0 then
        -- Reset timer
        self:resetIncidentTimer()
        
        -- Check if we should generate a threat (not every tick)
        if #self.GameState.ThreatTemplates > 0 then
            -- Select random threat template
            local randomIndex = math.random(1, #self.GameState.ThreatTemplates)
            local template = self.GameState.ThreatTemplates[randomIndex]
            
            -- Create incident entity
            local incident = self:createIncidentFromTemplate(template)
            
            print(string.format("🚨 [%s] Threat detected: %s (Severity: %d)", 
                os.date("%H:%M:%S"), 
                incident.name, 
                incident.trait_value_needed))
            
            -- Run idle resolution check
            self:Incident_CheckIdleResolve(incident)
        end
    end
end

-- Create an Incident Entity from a threat template
function IncidentSpecialistSystem:createIncidentFromTemplate(template)
    local incident = {
        -- GDD-required fields
        id = self.GameState.nextIncidentId,
        trait_required = "Severity",  -- Generic trait for now (using defense stat)
        trait_value_needed = template.baseSeverity or 5,
        time_to_resolve = template.baseTimeToResolve or 60,
        base_reward = {
            money = (template.baseSeverity or 5) * 50,
            reputation = math.floor((template.baseSeverity or 5) / 2),
            xp = (template.baseSeverity or 5) * 10,
            missionTokens = 1  -- Mission Tokens are primary reward
        },
        status = "Pending",
        
        -- Additional data from template
        templateId = template.id,
        name = template.name or template.displayName or "Unknown Threat",
        description = template.description or "",
        category = template.category or "unknown",
        
        -- Tracking data
        createdTime = os.time(),
        assignedSpecialistId = nil,
        resolutionTimeRemaining = template.baseTimeToResolve or 60
    }
    
    self.GameState.nextIncidentId = self.GameState.nextIncidentId + 1
    
    return incident
end

-- Idle Resolution Check - compares incident requirement to auto-resolve stat
function IncidentSpecialistSystem:Incident_CheckIdleResolve(incident)
    if incident.trait_value_needed <= self.GameState.GlobalAutoResolveStat then
        -- SUCCESS: Auto-resolve with reduced reward
        print(string.format("   ✅ [AUTO-RESOLVE] %s handled automatically!", incident.name))
        
        -- Calculate reduced reward (50% of base)
        local reducedReward = {
            money = incident.base_reward.money * 0.5,
            reputation = incident.base_reward.reputation * 0.5,
            xp = incident.base_reward.xp * 0.5,
            missionTokens = 0  -- No mission tokens for auto-resolve
        }
        
        print(string.format("   💰 Reduced rewards: $%.0f, %.0f Rep, %.0f XP", 
            reducedReward.money, 
            reducedReward.reputation, 
            reducedReward.xp))
        
        -- Award resources via ResourceManager
        if self.resourceManager then
            self.resourceManager:addResource("money", reducedReward.money)
            self.resourceManager:addResource("reputation", reducedReward.reputation)
            self.resourceManager:addResource("xp", reducedReward.xp)
        end
        
        -- Log to event bus
        if self.eventBus then
            self.eventBus:publish("incident_auto_resolved", {
                incident = incident,
                reward = reducedReward
            })
        end
    else
        -- FAILURE: Escalate to Incident Queue
        print(string.format("   ⚠️  [ESCALATION] %s added to alerts queue!", incident.name))
        table.insert(self.GameState.IncidentsQueue, incident)
        
        -- Log to event bus
        if self.eventBus then
            self.eventBus:publish("incident_escalated", {
                incident = incident
            })
        end
    end
end

-- Specialist Auto-Assignment logic
function IncidentSpecialistSystem:Specialist_AutoAssign()
    -- Iterate through pending incidents
    for i = #self.GameState.IncidentsQueue, 1, -1 do
        local incident = self.GameState.IncidentsQueue[i]
        
        if incident.status == "Pending" then
            -- Find best available specialist
            local bestSpecialist = self:findBestSpecialistForIncident(incident)
            
            if bestSpecialist then
                -- Assign specialist to incident
                incident.status = "AutoAssigned"
                incident.assignedSpecialistId = bestSpecialist.id
                bestSpecialist.is_busy = true
                
                print(string.format("   🤝 [AUTO-ASSIGN] %s assigned to %s", 
                    bestSpecialist.name, 
                    incident.name))
                
                -- Log to event bus
                if self.eventBus then
                    self.eventBus:publish("incident_auto_assigned", {
                        incident = incident,
                        specialist = bestSpecialist
                    })
                end
            end
        end
    end
end

-- Find the best available specialist for an incident
function IncidentSpecialistSystem:findBestSpecialistForIncident(incident)
    local bestSpecialist = nil
    local bestScore = 0
    
    for _, specialist in ipairs(self.GameState.Specialists) do
        if not specialist.is_busy and specialist.cooldown_timer <= 0 then
            -- Use defense stat as the "Trait" for severity comparison
            local relevantTrait = specialist.defense
            
            -- Specialist must meet the requirement
            if relevantTrait >= incident.trait_value_needed then
                -- Score based on how much better they are (prefer exact match)
                local score = relevantTrait
                
                if score > bestScore then
                    bestScore = score
                    bestSpecialist = specialist
                end
            end
        end
    end
    
    return bestSpecialist
end

-- Update resolution timers for assigned incidents
function IncidentSpecialistSystem:Incident_Resolution_Update(dt)
    for i = #self.GameState.IncidentsQueue, 1, -1 do
        local incident = self.GameState.IncidentsQueue[i]
        
        if incident.status == "AutoAssigned" or incident.status == "ManualAssigned" then
            incident.resolutionTimeRemaining = incident.resolutionTimeRemaining - dt
            
            -- Check if resolution is complete
            if incident.resolutionTimeRemaining <= 0 then
                -- Find the assigned specialist
                local specialist = self:getSpecialistById(incident.assignedSpecialistId)
                
                if specialist then
                    self:Incident_Resolve(incident, specialist)
                    
                    -- Remove from queue
                    table.remove(self.GameState.IncidentsQueue, i)
                end
            end
        end
    end
end

-- Resolve an incident and award rewards
function IncidentSpecialistSystem:Incident_Resolve(incident, specialist)
    print(string.format("   ✅ [RESOLVED] %s resolved %s!", 
        specialist.name, 
        incident.name))
    
    -- Award full rewards
    print(string.format("   💰 Full rewards: $%.0f, %d Rep, %d XP, %d Mission Tokens", 
        incident.base_reward.money, 
        incident.base_reward.reputation, 
        incident.base_reward.xp,
        incident.base_reward.missionTokens))
    
    -- Award resources via ResourceManager
    if self.resourceManager then
        self.resourceManager:addResource("money", incident.base_reward.money)
        self.resourceManager:addResource("reputation", incident.base_reward.reputation)
        self.resourceManager:addResource("xp", incident.base_reward.xp)
        self.resourceManager:addResource("missionTokens", incident.base_reward.missionTokens)
    end
    
    -- Award XP to specialist
    specialist.XP = specialist.XP + incident.base_reward.xp
    print(string.format("   📈 %s gained %d XP (Total: %d)", 
        specialist.name, 
        incident.base_reward.xp, 
        specialist.XP))
    
    -- Update incident status
    incident.status = "Resolved"
    
    -- Set specialist cooldown (5 seconds base)
    specialist.cooldown_timer = 5.0
    
    -- Log to event bus
    if self.eventBus then
        self.eventBus:publish("incident_resolved", {
            incident = incident,
            specialist = specialist,
            reward = incident.base_reward
        })
    end
end

-- Update specialist cooldowns
function IncidentSpecialistSystem:Specialist_Cooldown_Update(dt)
    for _, specialist in ipairs(self.GameState.Specialists) do
        if specialist.cooldown_timer > 0 then
            specialist.cooldown_timer = specialist.cooldown_timer - dt
            
            -- Cooldown complete
            if specialist.cooldown_timer <= 0 then
                specialist.cooldown_timer = 0
                specialist.is_busy = false
                
                print(string.format("   ⏰ %s is now available", specialist.name))
                
                -- Log to event bus
                if self.eventBus then
                    self.eventBus:publish("specialist_available", {
                        specialist = specialist
                    })
                end
            end
        end
    end
end

-- Get specialist by ID
function IncidentSpecialistSystem:getSpecialistById(id)
    for _, specialist in ipairs(self.GameState.Specialists) do
        if specialist.id == id then
            return specialist
        end
    end
    return nil
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

-- Get current state for inspection
function IncidentSpecialistSystem:getState()
    return self.GameState
end

-- Get statistics for display
function IncidentSpecialistSystem:getStatistics()
    local stats = {
        activeSpecialists = #self.GameState.Specialists,
        pendingIncidents = 0,
        assignedIncidents = 0,
        resolvedIncidents = 0,
        availableSpecialists = 0,
        busySpecialists = 0
    }
    
    for _, incident in ipairs(self.GameState.IncidentsQueue) do
        if incident.status == "Pending" then
            stats.pendingIncidents = stats.pendingIncidents + 1
        elseif incident.status == "AutoAssigned" or incident.status == "ManualAssigned" then
            stats.assignedIncidents = stats.assignedIncidents + 1
        elseif incident.status == "Resolved" then
            stats.resolvedIncidents = stats.resolvedIncidents + 1
        end
    end
    
    for _, specialist in ipairs(self.GameState.Specialists) do
        if specialist.is_busy or specialist.cooldown_timer > 0 then
            stats.busySpecialists = stats.busySpecialists + 1
        else
            stats.availableSpecialists = stats.availableSpecialists + 1
        end
    end
    
    return stats
end

return IncidentSpecialistSystem
