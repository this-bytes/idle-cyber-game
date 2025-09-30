-- src/systems/specialist_system.lua

local SpecialistSystem = {}
SpecialistSystem.__index = SpecialistSystem

-- Create new specialist system
function SpecialistSystem.new(eventBus, dataManager)
    local self = setmetatable({}, SpecialistSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    
    -- Reference to skill system (will be set externally)
    self.skillSystem = nil
    
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
    end
end

-- Set skill system reference
function SpecialistSystem:setSkillSystem(skillSystem)
    self.skillSystem = skillSystem
end

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

-- Award XP to a specialist
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
    
    -- Apply stat boost (10% increase to efficiency)
    specialist.efficiency = (specialist.efficiency or 1.0) * 1.1
    
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

return SpecialistSystem