-- Unsure if relevant, but here is the full file content you asked for:
-- If in use core to the active game, ensure to merge any necessary changes.
-- Incident System - Dynamic Incident Generation and Management
-- Handles Incident lifecycle, specialist deployment, and outcomes

local IncidentSystem = {}
IncidentSystem.__index = IncidentSystem

-- Create new Incident system
function IncidentSystem.new(eventBus, dataManager)
    local self = setmetatable({}, IncidentSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    
    -- Incident definitions loaded from data
    self.IncidentDefinitions = {}
    
    -- Active Incident state
    self.activeIncident = nil
    self.currentStageIndex = 1
    self.IncidentProgress = 0
    self.deployedSpecialists = {}
    self.IncidentStartTime = 0
    self.elapsedTime = 0
    
    return self
end

function IncidentSystem:initialize()
    -- Load Incident definitions from JSON
    local IncidentData = self.dataManager:getData("crises")
    if IncidentData and IncidentData.crises then
        self.IncidentDefinitions = IncidentData.crises
        print("✅ Incident System: Loaded " .. self:countCrises() .. " Incident definitions")
    else
        print("⚠️  Incident System: No Incident definitions found")
    end
end

function IncidentSystem:countCrises()
    local count = 0
    for _ in pairs(self.IncidentDefinitions) do
        count = count + 1
    end
    return count
end

-- Generate a Incident from a threat type
function IncidentSystem:generateIncident(threatType, difficultyModifier)
    difficultyModifier = difficultyModifier or 1.0
    
    -- Find Incident definition matching threat type
    local IncidentId = nil
    for id, Incident in pairs(self.IncidentDefinitions) do
        if Incident.threatType == threatType then
            IncidentId = id
            break
        end
    end
    
    if not IncidentId then
        print("⚠️  No Incident definition found for threat type: " .. threatType)
        return nil
    end
    
    return IncidentId
end

-- Start a Incident by ID
function IncidentSystem:startIncident(IncidentId)
    if self.activeIncident then
        print("⚠️  Incident already active: " .. self.activeIncident.id)
        return false
    end
    
    local IncidentDef = self.IncidentDefinitions[IncidentId]
    if not IncidentDef then
        print("❌ Incident definition not found: " .. IncidentId)
        return false
    end
    
    -- Create active Incident instance from definition
    self.activeIncident = {
        id = IncidentDef.id,
        name = IncidentDef.name,
        description = IncidentDef.description,
        threatType = IncidentDef.threatType,
        severity = IncidentDef.severity,
        timeLimit = IncidentDef.timeLimit,
        xpReward = IncidentDef.xpReward,
        moneyReward = IncidentDef.moneyReward,
        reputationImpact = IncidentDef.reputationImpact,
        stages = self:deepCopyStages(IncidentDef.stages)
    }
    
    self.currentStageIndex = 1
    self.IncidentProgress = 0
    self.deployedSpecialists = {}
    self.IncidentStartTime = love and love.timer and love.timer.getTime() or os.clock()
    self.elapsedTime = 0
    
    -- Auto-complete first stage if marked
    if self.activeIncident.stages[1] and self.activeIncident.stages[1].autoComplete then
        self.activeIncident.stages[1].completed = true
        self.currentStageIndex = 2
    end
    
    -- Fire event
    if self.eventBus then
        self.eventBus:publish("Incident_started", {
            IncidentId = IncidentId,
            threatType = IncidentDef.threatType,
            severity = IncidentDef.severity,
            name = IncidentDef.name
        })
    end
    
    print("🚨 Incident started: " .. IncidentDef.name)
    return true
end

-- Helper function for deep copying tables
local function deepCopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopyTable(orig_key)] = deepCopyTable(orig_value)
        end
        setmetatable(copy, getmetatable(orig))
    else
        copy = orig
    end
    return copy
end

-- Deep copy stages array
function IncidentSystem:deepCopyStages(stages)
    local copy = deepCopyTable(stages)
    -- Ensure each stage has completed = false
    for i, stage in ipairs(copy) do
        stage.completed = false
    end
    return copy
end

-- Deploy a specialist to the active Incident
function IncidentSystem:deploySpecialist(specialistId, IncidentId, abilityId)
    if not self.activeIncident or self.activeIncident.id ~= IncidentId then
        print("❌ No active Incident or Incident mismatch")
        return false
    end
    
    -- Record deployment
    table.insert(self.deployedSpecialists, {
        specialistId = specialistId,
        abilityId = abilityId,
        deploymentTime = self.elapsedTime
    })
    
    -- Fire event
    if self.eventBus then
        self.eventBus:publish("specialist_deployed_to_Incident", {
            IncidentId = IncidentId,
            specialistId = specialistId,
            abilityId = abilityId
        })
    end
    
    return true
end

-- Use an ability on a Incident stage
function IncidentSystem:useAbility(specialistId, abilityId, stageId, specialistAbilities)
    if not self.activeIncident then
        return false, "No active Incident"
    end
    
    -- Find the stage
    local stage = self:findStage(stageId)
    if not stage then
        return false, "Stage not found"
    end
    
    if stage.completed then
        return false, "Stage already completed"
    end
    
    -- Calculate effectiveness
    local effectiveness = self:calculateEffectiveness(specialistAbilities, stage.requiredAbilities or {})
    
    -- Apply ability effect
    local progressGain = 0.3 * effectiveness -- Base progress gain
    self.IncidentProgress = math.min(1.0, self.IncidentProgress + progressGain)
    
    -- Check if stage requirements are met
    local requiredProgress = stage.requiredProgress or 0
    if self.IncidentProgress >= requiredProgress then
        stage.completed = true
        self:advanceStage()
        
        -- Fire event
        if self.eventBus then
            self.eventBus:publish("Incident_stage_completed", {
                IncidentId = self.activeIncident.id,
                stageId = stageId,
                effectiveness = effectiveness
            })
        end
    end
    
    -- Fire ability used event
    if self.eventBus then
        self.eventBus:publish("specialist_ability_used", {
            specialistId = specialistId,
            abilityId = abilityId,
            IncidentId = self.activeIncident.id,
            effectiveness = effectiveness
        })
    end
    
    return true, effectiveness
end

-- Find stage by ID
function IncidentSystem:findStage(stageId)
    if not self.activeIncident then return nil end
    
    for _, stage in ipairs(self.activeIncident.stages) do
        if stage.id == stageId then
            return stage
        end
    end
    return nil
end

-- Advance to next stage
function IncidentSystem:advanceStage()
    if not self.activeIncident then return false end
    
    -- Check if all stages completed
    local allCompleted = true
    for _, stage in ipairs(self.activeIncident.stages) do
        if not stage.completed then
            allCompleted = false
            break
        end
    end
    
    if allCompleted then
        self:resolveIncident("success")
        return true
    end
    
    -- Move to next incomplete stage
    for i = self.currentStageIndex + 1, #self.activeIncident.stages do
        if not self.activeIncident.stages[i].completed then
            self.currentStageIndex = i
            
            -- Auto-complete if marked
            if self.activeIncident.stages[i].autoComplete then
                self.activeIncident.stages[i].completed = true
                return self:advanceStage()
            end
            
            return true
        end
    end
    
    return false
end

-- Calculate effectiveness based on specialist abilities vs required abilities
function IncidentSystem:calculateEffectiveness(specialistAbilities, requiredAbilities)
    if not requiredAbilities or #requiredAbilities == 0 then
        return 1.0 -- No specific requirements, full effectiveness
    end
    
    local matchCount = 0
    for _, required in ipairs(requiredAbilities) do
        for _, has in ipairs(specialistAbilities) do
            if has == required then
                matchCount = matchCount + 1
                break
            end
        end
    end
    
    -- Base effectiveness 0.5, +0.25 per matching ability
    local effectiveness = 0.5 + (matchCount * 0.25)
    return math.min(1.0, effectiveness)
end

-- Resolve Incident with outcome
function IncidentSystem:resolveIncident(outcome)
    if not self.activeIncident then
        return false
    end
    
    local Incident = self.activeIncident
    local xpAwarded = 0
    local moneyAwarded = 0
    local reputationChange = 0
    
    -- Calculate rewards based on outcome
    if outcome == "success" then
        xpAwarded = Incident.xpReward
        moneyAwarded = Incident.moneyReward
        reputationChange = Incident.reputationImpact.success
        
        -- Bonus for perfect Incident (all stages completed quickly)
        if self.elapsedTime < Incident.timeLimit * 0.5 then
            xpAwarded = math.floor(xpAwarded * 1.5)
            print("⭐ Perfect Incident resolution! +50% XP bonus")
        end
    elseif outcome == "partial" then
        -- Partial completion
        local completionRate = self:getCompletionRate()
        xpAwarded = math.floor(Incident.xpReward * completionRate)
        moneyAwarded = math.floor(Incident.moneyReward * completionRate)
        reputationChange = Incident.reputationImpact.partial
    elseif outcome == "failure" or outcome == "timeout" then
        xpAwarded = math.floor(Incident.xpReward * 0.1) -- Small consolation XP
        moneyAwarded = 0
        reputationChange = Incident.reputationImpact.failure
    end
    
    -- Award resources
    if self.eventBus then
        if moneyAwarded > 0 then
            self.eventBus:publish("add_resource", {
                resource = "money",
                amount = moneyAwarded
            })
        end
        
        if reputationChange ~= 0 then
            self.eventBus:publish("add_resource", {
                resource = "reputation",
                amount = reputationChange
            })
        end
        
        -- Fire Incident completed event (SpecialistSystem will handle XP distribution)
        self.eventBus:publish("Incident_completed", {
            IncidentId = Incident.id,
            outcome = outcome,
            xpAwarded = xpAwarded,
            moneyAwarded = moneyAwarded,
            reputationChange = reputationChange,
            specialistsDeployed = self.deployedSpecialists
        })
    end
    
    print(string.format("✅ Incident resolved: %s | Outcome: %s | XP: %d | Money: $%d | Reputation: %+d",
        Incident.name, outcome, xpAwarded, moneyAwarded, reputationChange))
    
    -- Clear active Incident
    self.activeIncident = nil
    self.currentStageIndex = 1
    self.IncidentProgress = 0
    self.deployedSpecialists = {}
    
    return true
end

-- Get completion rate (0.0 to 1.0)
function IncidentSystem:getCompletionRate()
    if not self.activeIncident then return 0 end
    
    local completed = 0
    for _, stage in ipairs(self.activeIncident.stages) do
        if stage.completed then
            completed = completed + 1
        end
    end
    
    return completed / #self.activeIncident.stages
end

-- Update Incident timer
function IncidentSystem:update(dt)
    if not self.activeIncident then return end
    
    self.elapsedTime = self.elapsedTime + dt
    
    -- Check for timeout
    if self.elapsedTime >= self.activeIncident.timeLimit then
        print("⏰ Incident timeout!")
        self:resolveIncident("timeout")
    end
end

-- Get active Incident
function IncidentSystem:getActiveIncident()
    return self.activeIncident
end

-- Get current stage
function IncidentSystem:getCurrentStage()
    if not self.activeIncident then return nil end
    return self.activeIncident.stages[self.currentStageIndex]
end

-- Get time remaining
function IncidentSystem:getTimeRemaining()
    if not self.activeIncident then return 0 end
    return math.max(0, self.activeIncident.timeLimit - self.elapsedTime)
end

-- Get all Incident definitions
function IncidentSystem:getAllIncidentDefinitions()
    return self.IncidentDefinitions
end

-- Get state for saving
function IncidentSystem:getState()
    return {
        activeIncident = self.activeIncident,
        currentStageIndex = self.currentStageIndex,
        IncidentProgress = self.IncidentProgress,
        deployedSpecialists = self.deployedSpecialists,
        elapsedTime = self.elapsedTime
    }
end

-- Load state from save
function IncidentSystem:loadState(state)
    if state then
        self.activeIncident = state.activeIncident
        self.currentStageIndex = state.currentStageIndex or 1
        self.IncidentProgress = state.IncidentProgress or 0
        self.deployedSpecialists = state.deployedSpecialists or {}
        self.elapsedTime = state.elapsedTime or 0
    end
end

return IncidentSystem
