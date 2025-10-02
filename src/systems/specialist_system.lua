-- Core Specialist System
-- Manages specialists, their stats, XP, leveling, and abilities
-- Integral to gameplay and progression

local SpecialistSystem = {}
SpecialistSystem.__index = SpecialistSystem

-- Create new specialist system
function SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local self = setmetatable({}, SpecialistSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.skillSystem = skillSystem
    
    -- Hired specialists
    self.specialists = {}
    
    -- Available specialists for hire
    self.availableSpecialists = {}
    
    -- Specialist roles and their base stats
    self.specialistTypes = {}
    
    -- XP thresholds for leveling up
    self.levelUpThresholds = {
        [2] = 100,   -- XP needed to reach level 2
        [3] = 250,   -- XP needed to reach level 3
        [4] = 500,   -- XP needed to reach level 4
        [5] = 1000,  -- XP needed to reach level 5
        [6] = 2000,  -- XP needed to reach level 6
        [7] = 4000,  -- XP needed to reach level 7
        [8] = 8000,  -- XP needed to reach level 8
        [9] = 16000, -- XP needed to reach level 9
        [10] = 32000, -- XP needed to reach level 10
        [11] = 50000  -- XP needed to reach level 11
    }
    
    self.nextSpecialistId = 1
    
    return self
end

function SpecialistSystem:initialize()
    local specialistTypesData = self.dataManager:getData("specialists")
    if specialistTypesData and specialistTypesData.specialists then
        for _, specialistType in ipairs(specialistTypesData.specialists) do
            self.specialistTypes[specialistType.id] = specialistType
        end
    end

    -- Initialize with player as the first specialist
    self:addSpecialist("ceo", {
        id = 0,
        type = "ceo",
        name = "You (CEO)",
        level = 1,
        xp = 0,
        efficiency = 1.0,
        speed = 1.0, 
        trace = 1.0,
        defense = 1.0,
        status = "available", -- available, busy, cooldown
        abilities = {"leadership", "basic_analysis"},
        busyUntil = 0
    })
    
    -- Generate some initial available specialists
    self:generateAvailableSpecialist("junior_analyst")
    self:generateAvailableSpecialist("network_admin")
    
    -- Subscribe to contract completion events for XP awards
    if self.eventBus then
        self.eventBus:subscribe("contract_completed", function(data)
            self:awardXpToAllSpecialists(data.xpAwarded or 25)
        end)
        
        -- Subscribe to Incident completion events for XP awards
        self.eventBus:subscribe("Incident_completed", function(data)
            -- Award XP to deployed specialists
            if data.specialistsDeployed then
                for _, deployment in ipairs(data.specialistsDeployed) do
                    local specialistId = deployment.specialistId
                    local baseXp = data.xpAwarded or 50
                    
                    -- Bonus XP for using abilities
                    local abilityBonus = deployment.abilityId and 10 or 0
                    
                    self:awardXp(specialistId, baseXp + abilityBonus)
                end
            end
        end)
        
        -- Subscribe to admin commands
        self.eventBus:subscribe("admin_command_deploy_specialist", function(data)
            self:handleAdminDeploy(data)
        end)
    end
end

function SpecialistSystem:handleAdminDeploy(data)
    local specialist = self:getSpecialistByName(data.specialistName)
    local abilityName = data.abilityName

    if not specialist then
        self.eventBus:publish("admin_log", { message = string.format("[ERROR] Specialist '%s' not found.", data.specialistName) })
        return
    end

    if specialist.status ~= "available" then
        self.eventBus:publish("admin_log", { message = string.format("[ERROR] Specialist '%s' is currently %s.", specialist.name, specialist.status) })
        return
    end

    local hasAbility = false
    if specialist.abilities then
        for _, abilityId in ipairs(specialist.abilities) do
            -- This assumes abilityId matches the abilityName from the command.
            -- We might need to look up an ability by its ID from skill data later.
            if abilityId == abilityName then
                hasAbility = true
                break
            end
        end
    end

    if not hasAbility then
        self.eventBus:publish("admin_log", { message = string.format("[ERROR] Specialist '%s' does not have the ability '%s'.", specialist.name, abilityName) })
        return
    end

    -- TODO: Define ability effects, costs, and cooldowns.
    local cooldown = 30 -- Placeholder cooldown in seconds
    specialist.status = "busy"
    specialist.busyUntil = love.timer.getTime() + cooldown

    self.eventBus:publish("admin_log", { message = string.format("[SUCCESS] %s is now executing '%s'. Cooldown: %d seconds.", specialist.name, abilityName, cooldown) })
    
    -- We can also publish a more specific event for other systems to react to
    self.eventBus:publish("specialist_ability_used", {
        specialistId = specialist.id,
        abilityName = abilityName,
        incidentId = data.incidentId
    })
end

function SpecialistSystem:update(dt)
    local currentTime = love.timer.getTime()
    for _, specialist in pairs(self.specialists) do
        if specialist.status == "busy" and specialist.busyUntil and currentTime >= specialist.busyUntil then
            specialist.status = "available"
            specialist.busyUntil = 0
            self.eventBus:publish("admin_log", { message = string.format("[INFO] Specialist %s is now available.", specialist.name) })
        end
    end
end

function SpecialistSystem:getSpecialists()
    return self.specialists
end

-- Set skill system reference
-- function SpecialistSystem:setSkillSystem(skillSystem)
--     self.skillSystem = skillSystem
-- end

-- Add a specialist to the team
function SpecialistSystem:addSpecialist(specialistType, specialistData)
    local specialist = specialistData or {}
    
    if not specialist.id then
        specialist.id = self.nextSpecialistId
        self.nextSpecialistId = self.nextSpecialistId + 1
    end
    
    if not specialist.type then
        specialist.type = specialistType
    end
    
    if not specialist.name then
        local typeData = self.specialistTypes[specialistType]
        specialist.name = typeData and typeData.name or "Unknown Specialist"
    end
    
    -- Set defaults if not provided
    specialist.level = specialist.level or 1
    specialist.xp = specialist.xp or 0
    specialist.status = specialist.status or "available"
    specialist.busyUntil = specialist.busyUntil or 0
    
    -- Copy base stats from type
    local typeData = self.specialistTypes[specialistType]
    if typeData then
        specialist.efficiency = specialist.efficiency or typeData.efficiency
        specialist.speed = specialist.speed or typeData.speed
        specialist.trace = specialist.trace or typeData.trace
        specialist.defense = specialist.defense or typeData.defense
        specialist.abilities = specialist.abilities or typeData.abilities
    end
    
    self.specialists[specialist.id] = specialist
    
    -- Initialize skills if skill system is available
    if self.skillSystem then
        self.skillSystem:initializeEntity(specialist.id, specialist.type)
    end
    
    if self.eventBus then
        self.eventBus:publish("specialist_hired", {
            specialist = specialist
        })
    end
    
    return specialist
end

function SpecialistSystem:getAllSpecialists()
    return self.specialists
end

-- Generate an available specialist for hire
function SpecialistSystem:generateAvailableSpecialist(specialistType)
    local typeData = self.specialistTypes[specialistType]
    if not typeData then return nil end
    
    local specialist = {
        type = specialistType,
        name = typeData.name,
        cost = typeData.cost,
        efficiency = typeData.efficiency,
        speed = typeData.speed,
        trace = typeData.trace,
        defense = typeData.defense,
        description = typeData.description,
        abilities = typeData.abilities
    }
    
    table.insert(self.availableSpecialists, specialist)
    return specialist
end

-- Hire a specialist
function SpecialistSystem:hireSpecialist(index)
    if not self.availableSpecialists or not self.availableSpecialists[index] then
        print("Error: Invalid specialist index " .. tostring(index))
        return false
    end

    local specialistToHire = self.availableSpecialists[index]
    if not specialistToHire or not specialistToHire.cost then
        print("Error: Specialist data is corrupt or missing cost.")
        return false
    end
    
    -- The ResourceManager will listen for this and handle the transaction.
    -- It needs to know if the purchase was successful to proceed.
    self.eventBus:publish("resource_spend_request", {
        cost = specialistToHire.cost,
        onSuccess = function()
            -- This callback will be executed by the ResourceManager on success
            print("Purchase successful for: " .. specialistToHire.name)
            self:addSpecialist(specialistToHire.type, specialistToHire)
            table.remove(self.availableSpecialists, index)
            self.eventBus:publish("ui_notification", {
                message = "Hired: " .. specialistToHire.name,
                type = "success"
            })
        end,
        onFailure = function()
            -- This callback will be executed by the ResourceManager on failure
            print("Purchase failed for: " .. specialistToHire.name .. ". Not enough resources.")
            self.eventBus:publish("ui_notification", {
                message = "Not enough resources to hire " .. specialistToHire.name,
                type = "error"
            })
        end
    })

    print("Attempting to hire: " .. specialistToHire.name)
    -- The function now returns immediately, and the outcome is handled asynchronously.
    return true
end

-- Get a specialist's effective stats including skill bonuses
function SpecialistSystem:getSpecialistEffectiveStats(specialistId)
    local specialist = self.specialists[specialistId]
    if not specialist then return nil end

    -- Start with base stats
    local effectiveStats = {
        efficiency = specialist.efficiency,
        speed = specialist.speed,
        trace = specialist.trace,
        defense = specialist.defense,
    }

    -- Apply skill effects
    if self.skillSystem then
        local skillEffects = self.skillSystem:getSkillEffects(specialistId)
        for stat, bonus in pairs(skillEffects) do
            if effectiveStats[stat] then
                effectiveStats[stat] = effectiveStats[stat] + bonus
            end
        end
    end

    return effectiveStats
end

function SpecialistSystem:getTeamBonuses()
    local totalEfficiency = 0
    local specialistCount = 0
    local averageEfficiency = 1.0

    for id, _ in pairs(self.specialists) do
        local stats = self:getSpecialistEffectiveStats(id)
        if stats and stats.efficiency then
            totalEfficiency = totalEfficiency + stats.efficiency
            specialistCount = specialistCount + 1
        end
    end

    if specialistCount > 0 then
        averageEfficiency = totalEfficiency / specialistCount
    end

    return {
        efficiency = averageEfficiency
    }
end

-- Update specialist system
function SpecialistSystem:update(dt)
    local currentTime = (love and love.timer and love.timer.getTime()) or os.clock()
    
    -- Update specialist status
    for id, specialist in pairs(self.specialists) do
        if specialist.status == "busy" and currentTime >= specialist.busyUntil then
            specialist.status = "available"
            
            self.eventBus:publish("specialist_available", {
                specialist = specialist
            })
        end
    end
end

-- Get all specialists on the team
function SpecialistSystem:getTeam()
    return self.specialists
end

-- Get available specialists for contracts/activities
function SpecialistSystem:getAvailableSpecialists()
    local available = {}
    for id, specialist in pairs(self.specialists) do
        if specialist.status == "available" then
            available[id] = specialist
        end
    end
    return available
end

-- Get specialist by ID
function SpecialistSystem:getSpecialist(id)
    return self.specialists[id]
end

-- Get all specialists
function SpecialistSystem:getAllSpecialists()
    return self.specialists
end

-- Get available specialists for hire
function SpecialistSystem:getAvailableForHire()
    return self.availableSpecialists
end

-- Assign specialist to activity (makes them busy)
function SpecialistSystem:assignSpecialist(specialistId, duration)
    local specialist = self.specialists[specialistId]
    if not specialist or specialist.status ~= "available" then
        return false
    end
    
    specialist.status = "busy"
    specialist.busyUntil = ((love and love.timer and love.timer.getTime()) or os.clock()) + duration
    
    self.eventBus:publish("specialist_assigned", {
        specialist = specialist,
        duration = duration
    })
    
    return true
end

-- Calculate team bonuses for contracts
function SpecialistSystem:getTeamBonuses()
    local efficiency = 1.0
    local speed = 1.0
    local defense = 1.0
    local availableCount = 0
    
    for id, specialist in pairs(self.specialists) do
        if specialist.status == "available" then
            local specEfficiency = specialist.efficiency
            local specSpeed = specialist.speed
            local specDefense = specialist.defense
            
            -- Apply skill bonuses if skill system is available
            if self.skillSystem then
                local skillEffects = self.skillSystem:getSkillEffects(specialist.id)
                specEfficiency = specEfficiency * (1 + skillEffects.efficiency)
                specSpeed = specSpeed * (1 + skillEffects.speed)
                specDefense = specDefense * (1 + skillEffects.defense)
                
                -- Apply team-wide bonuses (typically from CEO leadership skills)
                if skillEffects.teamEfficiencyBonus and skillEffects.teamEfficiencyBonus > 0 then
                    efficiency = efficiency * (1 + skillEffects.teamEfficiencyBonus)
                end
            end
            
            efficiency = efficiency * specEfficiency
            speed = speed * specSpeed
            defense = defense * specDefense
            availableCount = availableCount + 1
        end
    end
    
    return {
        efficiency = efficiency,
        speed = speed,
        defense = defense,
        availableSpecialists = availableCount
    }
end

-- Get stats for display
function SpecialistSystem:getStats()
    local totalSpecialists = 0
    local availableSpecialists = 0
    local busySpecialists = 0
    
    for id, specialist in pairs(self.specialists) do
        totalSpecialists = totalSpecialists + 1
        if specialist.status == "available" then
            availableSpecialists = availableSpecialists + 1
        elseif specialist.status == "busy" then
            busySpecialists = busySpecialists + 1
        end
    end
    
    return {
        total = totalSpecialists,
        available = availableSpecialists,
        busy = busySpecialists,
        forHire = #self.availableSpecialists
    }
end

-- Get specialist skills (for UI display)
function SpecialistSystem:getSpecialistSkills(specialistId)
    if not self.skillSystem then
        return {}
    end
    return self.skillSystem:getEntitySkills(specialistId)
end

-- Get specialist skill effects (for detailed stats)
function SpecialistSystem:getSpecialistSkillEffects(specialistId)
    if not self.skillSystem then
        return {}
    end
    return self.skillSystem:getSkillEffects(specialistId)
end

-- Award XP to all specialists
function SpecialistSystem:awardXpToAllSpecialists(amount)
    local specialistCount = 0
    for specialistId, specialist in pairs(self.specialists) do
        if self:awardXp(specialistId, amount) then
            specialistCount = specialistCount + 1
        end
    end
    
    if specialistCount > 0 then
        print("Awarded " .. amount .. " XP to " .. specialistCount .. " specialists")
    end
    
    return specialistCount
end

function SpecialistSystem:awardXp(specialistId, amount)
    local specialist = self.specialists[specialistId]
    if not specialist then
        return false
    end
    
    -- Award XP
    specialist.xp = (specialist.xp or 0) + amount
    
    -- Check for level up
    local currentLevel = specialist.level or 1
    local requiredXp = self.levelUpThresholds[currentLevel + 1]
    
    if requiredXp and specialist.xp >= requiredXp then
        self:levelUp(specialistId)
    end
    
    -- Publish XP gained event
    self.eventBus:publish("specialist_xp_gained", {
        specialistId = specialistId,
        specialist = specialist,
        amount = amount,
        currentXp = specialist.xp,
        currentLevel = specialist.level
    })
    
    return true
end

-- Level up a specialist
function SpecialistSystem:levelUp(specialistId)
    local specialist = self.specialists[specialistId]
    if not specialist then
        return false
    end
    
    local oldLevel = specialist.level or 1
    local newLevel = oldLevel + 1
    
    -- Check if we have a threshold for this level
    if not self.levelUpThresholds[newLevel] then
        return false -- Max level reached
    end
    
    -- Level up the specialist
    specialist.level = newLevel
    
    -- Apply stat boost (10% increase per level to all stats)
    local statMultiplier = 1.1
    specialist.efficiency = (specialist.efficiency or 1.0) * statMultiplier
    specialist.speed = (specialist.speed or 1.0) * statMultiplier
    specialist.trace = (specialist.trace or 1.0) * statMultiplier
    specialist.defense = (specialist.defense or 1.0) * statMultiplier
    
    print(string.format("⭐ %s leveled up to Level %d! Stats increased by 10%%", specialist.name, newLevel))
    
    -- Publish level up event
    self.eventBus:publish("specialist_leveled_up", {
        specialistId = specialistId,
        specialist = specialist,
        oldLevel = oldLevel,
        newLevel = newLevel
    })
    
    return true
end

-- Get XP required for next level
function SpecialistSystem:getXpForNextLevel(currentLevel)
    return self.levelUpThresholds[currentLevel + 1]
end

-- Learn a new skill
function SpecialistSystem:learnSkill(specialistId, skillId)
    local specialist = self.specialists[specialistId]
    if not specialist then
        return false, "Specialist not found"
    end
    
    -- Check if skill system is available
    if not self.skillSystem then
        return false, "Skill system not available"
    end
    
    -- Check if already has the skill
    if specialist.abilities then
        for _, abilityId in ipairs(specialist.abilities) do
            if abilityId == skillId then
                return false, "Already knows this skill"
            end
        end
    end
    
    -- Validate skill requirements
    local canLearn, reason = self:canLearnSkill(specialist, skillId)
    if not canLearn then
        return false, reason
    end
    
    -- Get skill data to check XP cost
    local skills = self.skillSystem:getAllSkills()
    local skill = skills[skillId]
    if not skill then
        return false, "Skill not found"
    end
    
    local xpCost = skill.baseXpCost or 0
    if specialist.xp < xpCost then
        return false, string.format("Not enough XP (need %d, have %d)", xpCost, specialist.xp)
    end
    
    -- Deduct XP
    specialist.xp = specialist.xp - xpCost
    
    -- Add skill to abilities
    if not specialist.abilities then
        specialist.abilities = {}
    end
    table.insert(specialist.abilities, skillId)
    
    -- Fire event
    if self.eventBus then
        self.eventBus:publish("specialist_learned_skill", {
            specialistId = specialistId,
            skillId = skillId,
            specialistName = specialist.name
        })
    end
    
    print(string.format("✨ %s learned new skill: %s", specialist.name, skill.name))
    
    return true
end

-- Check if specialist can learn a skill
function SpecialistSystem:canLearnSkill(specialist, skillId)
    if not self.skillSystem then
        return false, "Skill system not available"
    end
    
    -- Get skill data
    local skills = self.skillSystem:getAllSkills()
    local skill = skills[skillId]
    if not skill then
        return false, "Skill not found"
    end
    
    -- Check level requirement (if any)
    if skill.levelRequirement and (specialist.level or 1) < skill.levelRequirement then
        return false, string.format("Requires level %d", skill.levelRequirement)
    end
    
    -- Check prerequisite skills
    if skill.requirements then
        for reqSkillId, reqLevel in pairs(skill.requirements) do
            local hasSkill = false
            if specialist.abilities then
                for _, abilityId in ipairs(specialist.abilities) do
                    if abilityId == reqSkillId then
                        hasSkill = true
                        break
                    end
                end
            end
            
            if not hasSkill then
                return false, string.format("Requires skill: %s", reqSkillId)
            end
        end
    end
    
    -- Check XP cost
    local xpCost = skill.baseXpCost or 0
    if specialist.xp < xpCost then
        return false, string.format("Not enough XP (need %d, have %d)", xpCost, specialist.xp)
    end
    
    return true
end

-- Award XP to a specialist (skill system integration)
function SpecialistSystem:awardSpecialistXp(specialistId, skillId, amount)
    if not self.skillSystem then
        return false
    end
    return self.skillSystem:awardXp(specialistId, skillId, amount)
end

-- Get state for saving
function SpecialistSystem:getState()
    return {
        specialists = self.specialists,
        availableSpecialists = self.availableSpecialists,
        nextSpecialistId = self.nextSpecialistId
    }
end

-- Load state from save
function SpecialistSystem:loadState(state)
    if state.specialists then
        self.specialists = state.specialists
    end
    
    if state.availableSpecialists then
        self.availableSpecialists = state.availableSpecialists
    end
    
    if state.nextSpecialistId then
        self.nextSpecialistId = state.nextSpecialistId
    end
end

function SpecialistSystem:getTeamBonuses()
    local bonuses = {
        efficiency = 1.0,
        speed = 1.0,
        defense = 1.0,
        availableSpecialists = 0
    }
    
    -- Count available specialists
    for _, specialist in pairs(self.specialists) do
        if specialist.status == "available" then
            bonuses.availableSpecialists = bonuses.availableSpecialists + 1
        end
    end
    
    -- Calculate bonuses from specialist stats
    for _, specialist in pairs(self.specialists) do
        if specialist.efficiency then
            bonuses.efficiency = bonuses.efficiency * specialist.efficiency
        end
        if specialist.speed then
            bonuses.speed = bonuses.speed * specialist.speed
        end
        if specialist.defense then
            bonuses.defense = bonuses.defense * specialist.defense
        end
    end
    
    return bonuses
end

return SpecialistSystem