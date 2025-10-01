-- Crisis System - Dynamic Crisis Generation and Management
-- Handles crisis lifecycle, specialist deployment, and outcomes

local CrisisSystem = {}
CrisisSystem.__index = CrisisSystem

-- Create new crisis system
function CrisisSystem.new(eventBus, dataManager)
    local self = setmetatable({}, CrisisSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    
    -- Crisis definitions loaded from data
    self.crisisDefinitions = {}
    
    -- Active crisis state
    self.activeCrisis = nil
    self.currentStageIndex = 1
    self.crisisProgress = 0
    self.deployedSpecialists = {}
    self.crisisStartTime = 0
    self.elapsedTime = 0
    
    return self
end

function CrisisSystem:initialize()
    -- Load crisis definitions from JSON
    local crisisData = self.dataManager:getData("crises")
    if crisisData and crisisData.crises then
        self.crisisDefinitions = crisisData.crises
        print("✅ Crisis System: Loaded " .. self:countCrises() .. " crisis definitions")
    else
        print("⚠️  Crisis System: No crisis definitions found")
    end
end

function CrisisSystem:countCrises()
    local count = 0
    for _ in pairs(self.crisisDefinitions) do
        count = count + 1
    end
    return count
end

-- Generate a crisis from a threat type
function CrisisSystem:generateCrisis(threatType, difficultyModifier)
    difficultyModifier = difficultyModifier or 1.0
    
    -- Find crisis definition matching threat type
    local crisisId = nil
    for id, crisis in pairs(self.crisisDefinitions) do
        if crisis.threatType == threatType then
            crisisId = id
            break
        end
    end
    
    if not crisisId then
        print("⚠️  No crisis definition found for threat type: " .. threatType)
        return nil
    end
    
    return crisisId
end

-- Start a crisis by ID
function CrisisSystem:startCrisis(crisisId)
    if self.activeCrisis then
        print("⚠️  Crisis already active: " .. self.activeCrisis.id)
        return false
    end
    
    local crisisDef = self.crisisDefinitions[crisisId]
    if not crisisDef then
        print("❌ Crisis definition not found: " .. crisisId)
        return false
    end
    
    -- Create active crisis instance from definition
    self.activeCrisis = {
        id = crisisDef.id,
        name = crisisDef.name,
        description = crisisDef.description,
        threatType = crisisDef.threatType,
        severity = crisisDef.severity,
        timeLimit = crisisDef.timeLimit,
        xpReward = crisisDef.xpReward,
        moneyReward = crisisDef.moneyReward,
        reputationImpact = crisisDef.reputationImpact,
        stages = self:deepCopyStages(crisisDef.stages)
    }
    
    self.currentStageIndex = 1
    self.crisisProgress = 0
    self.deployedSpecialists = {}
    self.crisisStartTime = love and love.timer and love.timer.getTime() or os.clock()
    self.elapsedTime = 0
    
    -- Auto-complete first stage if marked
    if self.activeCrisis.stages[1] and self.activeCrisis.stages[1].autoComplete then
        self.activeCrisis.stages[1].completed = true
        self.currentStageIndex = 2
    end
    
    -- Fire event
    if self.eventBus then
        self.eventBus:publish("crisis_started", {
            crisisId = crisisId,
            threatType = crisisDef.threatType,
            severity = crisisDef.severity,
            name = crisisDef.name
        })
    end
    
    print("🚨 Crisis started: " .. crisisDef.name)
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
function CrisisSystem:deepCopyStages(stages)
    local copy = deepCopyTable(stages)
    -- Ensure each stage has completed = false
    for i, stage in ipairs(copy) do
        stage.completed = false
    end
    return copy
end

-- Deploy a specialist to the active crisis
function CrisisSystem:deploySpecialist(specialistId, crisisId, abilityId)
    if not self.activeCrisis or self.activeCrisis.id ~= crisisId then
        print("❌ No active crisis or crisis mismatch")
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
        self.eventBus:publish("specialist_deployed_to_crisis", {
            crisisId = crisisId,
            specialistId = specialistId,
            abilityId = abilityId
        })
    end
    
    return true
end

-- Use an ability on a crisis stage
function CrisisSystem:useAbility(specialistId, abilityId, stageId, specialistAbilities)
    if not self.activeCrisis then
        return false, "No active crisis"
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
    self.crisisProgress = math.min(1.0, self.crisisProgress + progressGain)
    
    -- Check if stage requirements are met
    local requiredProgress = stage.requiredProgress or 0
    if self.crisisProgress >= requiredProgress then
        stage.completed = true
        self:advanceStage()
        
        -- Fire event
        if self.eventBus then
            self.eventBus:publish("crisis_stage_completed", {
                crisisId = self.activeCrisis.id,
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
            crisisId = self.activeCrisis.id,
            effectiveness = effectiveness
        })
    end
    
    return true, effectiveness
end

-- Find stage by ID
function CrisisSystem:findStage(stageId)
    if not self.activeCrisis then return nil end
    
    for _, stage in ipairs(self.activeCrisis.stages) do
        if stage.id == stageId then
            return stage
        end
    end
    return nil
end

-- Advance to next stage
function CrisisSystem:advanceStage()
    if not self.activeCrisis then return false end
    
    -- Check if all stages completed
    local allCompleted = true
    for _, stage in ipairs(self.activeCrisis.stages) do
        if not stage.completed then
            allCompleted = false
            break
        end
    end
    
    if allCompleted then
        self:resolveCrisis("success")
        return true
    end
    
    -- Move to next incomplete stage
    for i = self.currentStageIndex + 1, #self.activeCrisis.stages do
        if not self.activeCrisis.stages[i].completed then
            self.currentStageIndex = i
            
            -- Auto-complete if marked
            if self.activeCrisis.stages[i].autoComplete then
                self.activeCrisis.stages[i].completed = true
                return self:advanceStage()
            end
            
            return true
        end
    end
    
    return false
end

-- Calculate effectiveness based on specialist abilities vs required abilities
function CrisisSystem:calculateEffectiveness(specialistAbilities, requiredAbilities)
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

-- Resolve crisis with outcome
function CrisisSystem:resolveCrisis(outcome)
    if not self.activeCrisis then
        return false
    end
    
    local crisis = self.activeCrisis
    local xpAwarded = 0
    local moneyAwarded = 0
    local reputationChange = 0
    
    -- Calculate rewards based on outcome
    if outcome == "success" then
        xpAwarded = crisis.xpReward
        moneyAwarded = crisis.moneyReward
        reputationChange = crisis.reputationImpact.success
        
        -- Bonus for perfect crisis (all stages completed quickly)
        if self.elapsedTime < crisis.timeLimit * 0.5 then
            xpAwarded = math.floor(xpAwarded * 1.5)
            print("⭐ Perfect crisis resolution! +50% XP bonus")
        end
    elseif outcome == "partial" then
        -- Partial completion
        local completionRate = self:getCompletionRate()
        xpAwarded = math.floor(crisis.xpReward * completionRate)
        moneyAwarded = math.floor(crisis.moneyReward * completionRate)
        reputationChange = crisis.reputationImpact.partial
    elseif outcome == "failure" or outcome == "timeout" then
        xpAwarded = math.floor(crisis.xpReward * 0.1) -- Small consolation XP
        moneyAwarded = 0
        reputationChange = crisis.reputationImpact.failure
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
        
        -- Fire crisis completed event (SpecialistSystem will handle XP distribution)
        self.eventBus:publish("crisis_completed", {
            crisisId = crisis.id,
            outcome = outcome,
            xpAwarded = xpAwarded,
            moneyAwarded = moneyAwarded,
            reputationChange = reputationChange,
            specialistsDeployed = self.deployedSpecialists
        })
    end
    
    print(string.format("✅ Crisis resolved: %s | Outcome: %s | XP: %d | Money: $%d | Reputation: %+d",
        crisis.name, outcome, xpAwarded, moneyAwarded, reputationChange))
    
    -- Clear active crisis
    self.activeCrisis = nil
    self.currentStageIndex = 1
    self.crisisProgress = 0
    self.deployedSpecialists = {}
    
    return true
end

-- Get completion rate (0.0 to 1.0)
function CrisisSystem:getCompletionRate()
    if not self.activeCrisis then return 0 end
    
    local completed = 0
    for _, stage in ipairs(self.activeCrisis.stages) do
        if stage.completed then
            completed = completed + 1
        end
    end
    
    return completed / #self.activeCrisis.stages
end

-- Update crisis timer
function CrisisSystem:update(dt)
    if not self.activeCrisis then return end
    
    self.elapsedTime = self.elapsedTime + dt
    
    -- Check for timeout
    if self.elapsedTime >= self.activeCrisis.timeLimit then
        print("⏰ Crisis timeout!")
        self:resolveCrisis("timeout")
    end
end

-- Get active crisis
function CrisisSystem:getActiveCrisis()
    return self.activeCrisis
end

-- Get current stage
function CrisisSystem:getCurrentStage()
    if not self.activeCrisis then return nil end
    return self.activeCrisis.stages[self.currentStageIndex]
end

-- Get time remaining
function CrisisSystem:getTimeRemaining()
    if not self.activeCrisis then return 0 end
    return math.max(0, self.activeCrisis.timeLimit - self.elapsedTime)
end

-- Get all crisis definitions
function CrisisSystem:getAllCrisisDefinitions()
    return self.crisisDefinitions
end

-- Get state for saving
function CrisisSystem:getState()
    return {
        activeCrisis = self.activeCrisis,
        currentStageIndex = self.currentStageIndex,
        crisisProgress = self.crisisProgress,
        deployedSpecialists = self.deployedSpecialists,
        elapsedTime = self.elapsedTime
    }
end

-- Load state from save
function CrisisSystem:loadState(state)
    if state then
        self.activeCrisis = state.activeCrisis
        self.currentStageIndex = state.currentStageIndex or 1
        self.crisisProgress = state.crisisProgress or 0
        self.deployedSpecialists = state.deployedSpecialists or {}
        self.elapsedTime = state.elapsedTime or 0
    end
end

return CrisisSystem
