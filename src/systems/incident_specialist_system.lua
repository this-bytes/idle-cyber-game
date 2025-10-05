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
    self.contractSystem = nil  -- Will be set externally
    
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

-- Set contract system reference for SLA integration
function IncidentSpecialistSystem:setContractSystem(contractSystem)
    self.contractSystem = contractSystem
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
    
    -- Subscribe to manual assignment events
    if self.eventBus then
        self.eventBus:subscribe("manual_assignment_requested", function(data)
            self:manualAssignSpecialist(data.specialistId, data.incidentId, data.stage)
        end)
    end
    
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
    
    -- Update all active incidents through their stages
    for _, incident in ipairs(self.GameState.IncidentsQueue) do
        if incident.stages then
            -- New format: three-stage lifecycle
            self:updateIncidentStage(incident, dt)
        else
            -- Legacy format: old resolution system
            -- This handles old save files gracefully
            self:Incident_Resolution_Update_Legacy(incident, dt)
        end
    end
    
    -- Update specialist cooldowns
    self:Specialist_Cooldown_Update(dt)
    
    -- Attempt auto-assignment for pending incidents (legacy only)
    -- New format auto-assigns in createIncidentFromTemplate
end

-- Legacy resolution update for backward compatibility
function IncidentSpecialistSystem:Incident_Resolution_Update_Legacy(incident, dt)
    if incident.status == "AutoAssigned" or incident.status == "ManualAssigned" then
        incident.resolutionTimeRemaining = incident.resolutionTimeRemaining - dt
        
        -- Check if resolution is complete
        if incident.resolutionTimeRemaining <= 0 then
            -- Find the assigned specialist
            local specialist = self:getSpecialistById(incident.assignedSpecialistId)
            
            if specialist then
                self:Incident_Resolve(incident, specialist)
                
                -- Remove from queue
                self:removeIncident(incident.id)
            end
        end
    end
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
            
            -- Get active contract if available (for SLA tracking)
            local contractId = nil
            if self.contractSystem then
                local activeContracts = self.contractSystem:getActiveContracts and self.contractSystem:getActiveContracts() or {}
                if activeContracts and #activeContracts > 0 then
                    -- Assign to first active contract
                    local contract = activeContracts[1]
                    contractId = contract.id
                end
            end
            
            -- Create incident entity with three-stage lifecycle
            local incident = self:createIncidentFromTemplate(template, contractId)
            
            print(string.format("🚨 [%s] Threat detected: %s (Severity: %d, Contract: %s)", 
                os.date("%H:%M:%S"), 
                incident.name, 
                incident.severity,
                contractId or "none"))
            
            -- Add to queue (new format doesn't use idle resolution check)
            table.insert(self.GameState.IncidentsQueue, incident)
        end
    end
end

-- Create an Incident Entity from a threat template
function IncidentSpecialistSystem:createIncidentFromTemplate(template, contractId)
    local severity = template.baseSeverity or 5
    
    local incident = {
        -- GDD-required fields
        id = "incident_" .. self.GameState.nextIncidentId,
        threatId = template.id,
        contractId = contractId,  -- CRITICAL: Link incidents to contracts
        severity = severity,
        trait_required = "Severity",  -- Generic trait for now (using defense stat)
        trait_value_needed = severity,
        time_to_resolve = template.baseTimeToResolve or 60,
        base_reward = {
            money = severity * 50,
            reputation = math.floor(severity / 2),
            xp = severity * 10,
            missionTokens = 1  -- Mission Tokens are primary reward
        },
        status = "Pending",
        
        -- Additional data from template
        templateId = template.id,
        name = template.name or template.displayName or "Unknown Threat",
        description = template.description or "",
        category = template.category or "unknown",
        
        -- NEW: Stage-based lifecycle
        stages = {
            detect = {
                status = "IN_PROGRESS",
                startTime = love.timer.getTime(),
                endTime = nil,
                duration = 0,
                slaLimit = self:getSLALimitForStage(contractId, "detect"),
                assignedSpecialists = {},
                success = nil
            },
            respond = {
                status = "PENDING",
                startTime = nil,
                endTime = nil,
                duration = 0,
                slaLimit = self:getSLALimitForStage(contractId, "respond"),
                assignedSpecialists = {},
                success = nil
            },
            resolve = {
                status = "PENDING",
                startTime = nil,
                endTime = nil,
                duration = 0,
                slaLimit = self:getSLALimitForStage(contractId, "resolve"),
                assignedSpecialists = {},
                success = nil
            }
        },
        
        currentStage = "detect",  -- Current active stage
        overallSuccess = nil,     -- Final outcome
        slaCompliant = nil,       -- Did we meet SLA?
        
        -- Tracking data (legacy, for backward compatibility)
        createdTime = os.time(),
        assignedSpecialistId = nil,
        resolutionTimeRemaining = template.baseTimeToResolve or 60
    }
    
    self.GameState.nextIncidentId = self.GameState.nextIncidentId + 1
    
    -- Auto-assign specialists to detect stage
    self:autoAssignSpecialistsToStage(incident, "detect")
    
    print(string.format("🔔 New incident created: %s (Contract: %s, Severity: %d)",
        incident.id, contractId or "none", severity))
    
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

-- Update resolution timers for assigned incidents (LEGACY - for old save format)
function IncidentSpecialistSystem:Incident_Resolution_Update(dt)
    for i = #self.GameState.IncidentsQueue, 1, -1 do
        local incident = self.GameState.IncidentsQueue[i]
        
        if not incident.stages then
            -- Only process old format incidents
            self:Incident_Resolution_Update_Legacy(incident, dt)
            
            -- Remove if complete
            if incident.status == "Resolved" then
                table.remove(self.GameState.IncidentsQueue, i)
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
-- PHASE 2: THREE-STAGE INCIDENT LIFECYCLE
-- ============================================================================

-- Get SLA time limits for a specific stage from contract or use defaults
function IncidentSpecialistSystem:getSLALimitForStage(contractId, stageName)
    -- Get SLA limits from contract if available
    if contractId and self.contractSystem then
        local contract = self.contractSystem:getContract(contractId)
        if contract and contract.slaRequirements then
            if stageName == "detect" then
                return contract.slaRequirements.detectionTimeSLA or 45
            elseif stageName == "respond" then
                return contract.slaRequirements.responseTimeSLA or 180
            elseif stageName == "resolve" then
                return contract.slaRequirements.resolutionTimeSLA or 600
            end
        end
    end
    
    -- Default fallbacks
    local defaults = {detect = 45, respond = 180, resolve = 600}
    return defaults[stageName] or 300
end

-- Get the required stat for a specific stage
function IncidentSpecialistSystem:getRequiredStatForStage(stageName)
    if stageName == "detect" then
        return "trace"     -- Detection requires trace stat
    elseif stageName == "respond" then
        return "speed"     -- Response requires speed stat
    elseif stageName == "resolve" then
        return "efficiency" -- Resolution requires efficiency stat
    end
    return "efficiency"  -- Default fallback
end

-- Get available specialists (not busy)
function IncidentSpecialistSystem:getAvailableSpecialists()
    local available = {}
    for _, spec in ipairs(self.GameState.Specialists) do
        if not spec.is_busy and spec.cooldown_timer <= 0 then
            table.insert(available, spec)
        end
    end
    return available
end

-- Get incident by ID
function IncidentSpecialistSystem:getIncident(incidentId)
    for _, incident in ipairs(self.GameState.IncidentsQueue) do
        if incident.id == incidentId then
            return incident
        end
    end
    return nil
end

-- Remove incident from queue and free specialists
function IncidentSpecialistSystem:removeIncident(incidentId)
    for i, incident in ipairs(self.GameState.IncidentsQueue) do
        if incident.id == incidentId then
            -- Free assigned specialists from all stages
            for stageName, stage in pairs(incident.stages or {}) do
                for _, specId in ipairs(stage.assignedSpecialists) do
                    local spec = self:getSpecialistById(specId)
                    if spec then
                        spec.is_busy = false
                        spec.cooldown_timer = 0
                    end
                end
            end
            
            table.remove(self.GameState.IncidentsQueue, i)
            return true
        end
    end
    return false
end

-- Get all incidents for a specific contract
function IncidentSpecialistSystem:getIncidentsByContract(contractId)
    local incidents = {}
    for _, incident in ipairs(self.GameState.IncidentsQueue) do
        if incident.contractId == contractId then
            table.insert(incidents, incident)
        end
    end
    return incidents
end

-- Auto-assign specialists to a stage based on required stat
function IncidentSpecialistSystem:autoAssignSpecialistsToStage(incident, stageName)
    if not incident.stages or not incident.stages[stageName] then
        return
    end
    
    local stage = incident.stages[stageName]
    local requiredStat = self:getRequiredStatForStage(stageName)
    
    -- Find best available specialists for this stat
    local availableSpecs = self:getAvailableSpecialists()
    
    -- Sort by relevant stat (highest first)
    table.sort(availableSpecs, function(a, b)
        return (a[requiredStat] or 0) > (b[requiredStat] or 0)
    end)
    
    -- Assign specialists based on severity
    -- Low severity (1-3): 1 specialist
    -- Medium severity (4-6): 2 specialists
    -- High severity (7-10): 3 specialists
    local numToAssign = math.min(math.ceil(incident.severity / 3), #availableSpecs)
    numToAssign = math.max(1, numToAssign)  -- At least 1
    
    for i = 1, numToAssign do
        local spec = availableSpecs[i]
        table.insert(stage.assignedSpecialists, spec.id)
        spec.is_busy = true
    end
    
    print(string.format("   Assigned %d specialists to %s stage (requires %s)",
        numToAssign, stageName, requiredStat))
end

-- Calculate progress for current stage based on specialist stats
function IncidentSpecialistSystem:calculateStageProgress(incident, stage)
    if #stage.assignedSpecialists == 0 then
        return 0  -- No progress without specialists
    end
    
    -- Get stage-specific stat requirements
    local statType = self:getRequiredStatForStage(incident.currentStage)
    
    local totalStat = 0
    for _, specId in ipairs(stage.assignedSpecialists) do
        local spec = self:getSpecialistById(specId)
        if spec then
            totalStat = totalStat + (spec[statType] or 1.0)
        end
    end
    
    -- Progress formula: (totalStat * timeDelta) / (severity * baseDifficulty)
    local baseDifficulty = 10
    local difficulty = incident.severity * baseDifficulty
    local progress = (totalStat * stage.duration) / difficulty
    
    return math.min(1.0, progress)
end

-- Update a specific incident stage
function IncidentSpecialistSystem:updateIncidentStage(incident, dt)
    if not incident.stages or not incident.currentStage then
        return  -- Old format incident, skip
    end
    
    local stage = incident.stages[incident.currentStage]
    
    if stage.status ~= "IN_PROGRESS" then
        return
    end
    
    -- Update duration
    stage.duration = stage.duration + dt
    
    -- Calculate progress based on assigned specialists
    local progress = self:calculateStageProgress(incident, stage)
    
    -- Check if stage is complete
    if progress >= 1.0 then
        stage.status = "COMPLETED"
        stage.endTime = love.timer.getTime()
        stage.success = stage.duration <= stage.slaLimit
        
        -- Publish stage completion event
        if self.eventBus then
            self.eventBus:publish("incident_stage_completed", {
                incidentId = incident.id,
                contractId = incident.contractId,
                stage = incident.currentStage,
                duration = stage.duration,
                slaLimit = stage.slaLimit,
                slaCompliant = stage.success,
                specialists = stage.assignedSpecialists
            })
        end
        
        print(string.format("✅ Incident %s: Stage '%s' completed in %.1fs (SLA: %ds, Compliant: %s)",
            incident.id, incident.currentStage, stage.duration, stage.slaLimit, tostring(stage.success)))
        
        -- Move to next stage
        self:advanceToNextStage(incident)
    end
end

-- Advance incident to next stage
function IncidentSpecialistSystem:advanceToNextStage(incident)
    if incident.currentStage == "detect" then
        incident.currentStage = "respond"
        local respondStage = incident.stages.respond
        respondStage.status = "IN_PROGRESS"
        respondStage.startTime = love.timer.getTime()
        
        -- Auto-assign specialists to respond stage
        self:autoAssignSpecialistsToStage(incident, "respond")
        
    elseif incident.currentStage == "respond" then
        incident.currentStage = "resolve"
        local resolveStage = incident.stages.resolve
        resolveStage.status = "IN_PROGRESS"
        resolveStage.startTime = love.timer.getTime()
        
        -- Auto-assign specialists to resolve stage
        self:autoAssignSpecialistsToStage(incident, "resolve")
        
    elseif incident.currentStage == "resolve" then
        -- Incident fully resolved
        self:finalizeIncident(incident)
    end
end

-- Finalize incident after all stages complete
function IncidentSpecialistSystem:finalizeIncident(incident)
    -- Calculate overall success
    local allStagesSuccess = incident.stages.detect.success and 
                            incident.stages.respond.success and 
                            incident.stages.resolve.success
    
    incident.overallSuccess = allStagesSuccess
    incident.slaCompliant = allStagesSuccess
    
    -- Calculate total time
    local totalDuration = incident.stages.detect.duration +
                         incident.stages.respond.duration +
                         incident.stages.resolve.duration
    
    -- Award rewards based on SLA compliance
    if incident.slaCompliant then
        -- Full rewards for SLA-compliant resolution
        if self.resourceManager then
            self.resourceManager:addResource("money", incident.base_reward.money)
            self.resourceManager:addResource("reputation", incident.base_reward.reputation)
            self.resourceManager:addResource("xp", incident.base_reward.xp)
            self.resourceManager:addResource("missionTokens", incident.base_reward.missionTokens)
        end
        
        print(string.format("   💰 Full rewards: $%.0f, %d Rep, %d XP, %d Mission Tokens", 
            incident.base_reward.money, 
            incident.base_reward.reputation, 
            incident.base_reward.xp,
            incident.base_reward.missionTokens))
    else
        -- Reduced rewards for SLA breach
        local reducedReward = {
            money = incident.base_reward.money * 0.6,
            reputation = incident.base_reward.reputation * 0.5,
            xp = incident.base_reward.xp * 0.7,
            missionTokens = 0  -- No mission tokens for SLA breach
        }
        
        if self.resourceManager then
            self.resourceManager:addResource("money", reducedReward.money)
            self.resourceManager:addResource("reputation", reducedReward.reputation)
            self.resourceManager:addResource("xp", reducedReward.xp)
        end
        
        print(string.format("   ⚠️  Reduced rewards (SLA breach): $%.0f, %.0f Rep, %.0f XP", 
            reducedReward.money, 
            reducedReward.reputation, 
            reducedReward.xp))
    end
    
    -- Award XP to all specialists involved
    for stageName, stage in pairs(incident.stages) do
        for _, specId in ipairs(stage.assignedSpecialists) do
            local spec = self:getSpecialistById(specId)
            if spec then
                local xpGain = incident.base_reward.xp / 3  -- Split XP across stages
                spec.XP = spec.XP + xpGain
            end
        end
    end
    
    -- Publish final resolution event
    if self.eventBus then
        self.eventBus:publish("incident_fully_resolved", {
            incidentId = incident.id,
            contractId = incident.contractId,
            totalDuration = totalDuration,
            stageCompliance = {
                detect = incident.stages.detect.success,
                respond = incident.stages.respond.success,
                resolve = incident.stages.resolve.success
            },
            overallSLACompliant = incident.slaCompliant
        })
    end
    
    print(string.format("🎯 Incident %s fully resolved: Total time %.1fs, SLA Compliant: %s",
        incident.id, totalDuration, tostring(incident.slaCompliant)))
    
    -- Remove from active incidents
    self:removeIncident(incident.id)
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

-- Get current state for save/inspection
function IncidentSpecialistSystem:getState()
    return {
        Specialists = self.GameState.Specialists,
        IncidentsQueue = self.GameState.IncidentsQueue,  -- Now has stages
        ThreatTemplates = self.GameState.ThreatTemplates,
        SpecialistTemplates = self.GameState.SpecialistTemplates,
        GlobalAutoResolveStat = self.GameState.GlobalAutoResolveStat,
        IncidentTimer = self.GameState.IncidentTimer,
        IncidentTimerMax = self.GameState.IncidentTimerMax,
        nextIncidentId = self.GameState.nextIncidentId,
        UnlockedSpecialists = self.GameState.UnlockedSpecialists
    }
end

-- Load state from save with migration support
function IncidentSpecialistSystem:loadState(state)
    if state then
        self.GameState.Specialists = state.Specialists or {}
        self.GameState.IncidentsQueue = state.IncidentsQueue or {}
        self.GameState.ThreatTemplates = state.ThreatTemplates or {}
        self.GameState.SpecialistTemplates = state.SpecialistTemplates or {}
        self.GameState.GlobalAutoResolveStat = state.GlobalAutoResolveStat or 100
        self.GameState.IncidentTimer = state.IncidentTimer or 0
        self.GameState.IncidentTimerMax = state.IncidentTimerMax or 10
        self.GameState.nextIncidentId = state.nextIncidentId or 1
        self.GameState.UnlockedSpecialists = state.UnlockedSpecialists or {}
        
        -- Migrate old incidents to new format if needed
        for _, incident in ipairs(self.GameState.IncidentsQueue) do
            if not incident.stages then
                self:migrateIncidentToStageFormat(incident)
            end
        end
        
        print("🎯 IncidentSpecialistSystem: State loaded with " .. #self.GameState.IncidentsQueue .. " active incidents")
    end
end

-- Migrate old incident format to new three-stage format
function IncidentSpecialistSystem:migrateIncidentToStageFormat(incident)
    print("🔄 Migrating incident " .. tostring(incident.id) .. " to stage format")
    
    -- If already has stages, skip
    if incident.stages then
        return
    end
    
    local severity = incident.trait_value_needed or incident.severity or 5
    incident.severity = severity
    
    -- Initialize stages based on current status
    incident.stages = {
        detect = {
            status = "COMPLETED",
            startTime = incident.createdTime or os.time(),
            endTime = incident.createdTime or os.time(),
            duration = 0,
            slaLimit = self:getSLALimitForStage(incident.contractId, "detect"),
            assignedSpecialists = {},
            success = true
        },
        respond = {
            status = "PENDING",
            startTime = nil,
            endTime = nil,
            duration = 0,
            slaLimit = self:getSLALimitForStage(incident.contractId, "respond"),
            assignedSpecialists = {},
            success = nil
        },
        resolve = {
            status = "PENDING",
            startTime = nil,
            endTime = nil,
            duration = 0,
            slaLimit = self:getSLALimitForStage(incident.contractId, "resolve"),
            assignedSpecialists = {},
            success = nil
        }
    }
    
    -- Set current stage based on old status
    if incident.status == "Pending" then
        incident.currentStage = "detect"
        incident.stages.detect.status = "IN_PROGRESS"
        incident.stages.detect.startTime = love.timer.getTime()
    elseif incident.status == "AutoAssigned" or incident.status == "ManualAssigned" then
        incident.currentStage = "respond"
        incident.stages.respond.status = "IN_PROGRESS"
        incident.stages.respond.startTime = love.timer.getTime()
        
        -- Assign the specialist to respond stage
        if incident.assignedSpecialistId then
            table.insert(incident.stages.respond.assignedSpecialists, incident.assignedSpecialistId)
        end
    else
        -- Default to detect
        incident.currentStage = "detect"
        incident.stages.detect.status = "IN_PROGRESS"
        incident.stages.detect.startTime = love.timer.getTime()
    end
    
    incident.overallSuccess = nil
    incident.slaCompliant = nil
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

-- Get all active incidents (for Admin UI)
function IncidentSpecialistSystem:getActiveIncidents()
    local active = {}
    for _, incident in pairs(self.incidents) do
        if incident.status == "ACTIVE" or incident.currentStage then
            table.insert(active, incident)
        end
    end
    return active
end

-- Get incident by ID
function IncidentSpecialistSystem:getIncidentById(incidentId)
    return self.incidents[incidentId]
end

-- Manually assign a specialist to an incident stage
function IncidentSpecialistSystem:manualAssignSpecialist(specialistId, incidentId, stageName)
    local incident = self:getIncidentById(incidentId)
    if not incident then
        print("❌ Manual Assignment Failed: Incident not found: " .. tostring(incidentId))
        return false
    end
    
    local stage = stageName or incident.currentStage
    if not incident.stages or not incident.stages[stage] then
        print("❌ Manual Assignment Failed: Invalid stage: " .. tostring(stage))
        return false
    end
    
    -- Verify specialist exists
    local specialistSystem = self.specialistSystem or (self.systems and self.systems.specialistSystem)
    if not specialistSystem or not specialistSystem:getSpecialist(specialistId) then
        print("❌ Manual Assignment Failed: Specialist not found: " .. tostring(specialistId))
        return false
    end
    
    -- Add to stage's assigned specialists
    local stageData = incident.stages[stage]
    if not stageData.assignedSpecialists then
        stageData.assignedSpecialists = {}
    end
    
    -- Check if already assigned
    for _, id in ipairs(stageData.assignedSpecialists) do
        if id == specialistId then
            print("⚠️  Specialist already assigned to this stage")
            return false
        end
    end
    
    -- Add assignment
    table.insert(stageData.assignedSpecialists, specialistId)
    stageData.manuallyAssigned = true
    
    -- Track manual assignment in global stats
    if self.globalStats then
        self.globalStats.manualAssignments = (self.globalStats.manualAssignments or 0) + 1
    end
    
    print(string.format("✅ Manual Assignment: Specialist %s → Incident %s (Stage: %s)", 
        specialistId, incidentId, stage))
    
    -- Publish event
    if self.eventBus then
        self.eventBus:publish("specialist_manually_assigned", {
            specialistId = specialistId,
            incidentId = incidentId,
            stage = stage,
            timestamp = love.timer.getTime()
        })
    end
    
    return true
end

-- Set specialist system reference for manual assignments
function IncidentSpecialistSystem:setSpecialistSystem(specialistSystem)
    self.specialistSystem = specialistSystem
end

return IncidentSpecialistSystem
