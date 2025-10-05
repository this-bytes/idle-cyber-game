-- Skill System - Idle Sec Ops
-- Handles expandable skill trees, progression, and effects

local SkillSystem = {}
SkillSystem.__index = SkillSystem

-- System metadata for automatic registration
SkillSystem.metadata = {
    priority = 10,  -- Early priority - many systems use skills
    dependencies = {
        "DataManager"
    },
    systemName = "SkillSystem"
}

-- No longer need to import this, it's not a real Lua module
-- local SkillData = require("src.data.skills")

-- Create new skill system
function SkillSystem.new(eventBus, dataManager)
    local self = setmetatable({}, SkillSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    
    -- Player and specialist skill progress
    -- Format: [entityId][skillId] = {level, xp, unlocked}
    self.skillProgress = {}
    
    -- Load skill definitions from data file
    self.skills = self.dataManager:getData("skills").skills or {}
    self.categories = self.dataManager:getData("skills").categories or {}
    
    local skillCount = 0
    if self.skills then
        for _ in pairs(self.skills) do skillCount = skillCount + 1 end
    end
    
    -- TODO: Add validation for the loaded JSON skill data
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    print("🛠️ SkillSystem: Initialized and loaded " .. skillCount .. " skills.")
    return self
end

-- Subscribe to relevant events
function SkillSystem:subscribeToEvents()
    -- Award XP when contracts complete
    self.eventBus:subscribe("contract_completed", function(data)
        local xpGain = data.xpAwarded or 25
        
        -- Award XP to assigned specialists
        if data.assignedSpecialists then
            for _, specialistId in ipairs(data.assignedSpecialists) do
                -- For now, award to a default skill. This can be expanded later.
                local awarded = self:awardXp(specialistId, "basic_analysis", xpGain)
                if awarded then
                    -- We don't have a direct reference to SpecialistSystem to get the name,
                    -- but we can log the ID. The UI can resolve the name later.
                    print(string.format("Awarded %d XP to Specialist ID %s for completing contract.", xpGain, tostring(specialistId)))
                end
            end
        end
    end)
    
    -- Award XP for Incident mode activities
    self.eventBus:subscribe("Incident_resolved", function(data)
        local xpGain = data.difficulty * 50 -- Base XP based on Incident difficulty
        if data.specialistId then
            self:awardXp(data.specialistId, "basic_response", xpGain)
        end
    end)

    -- Award XP for resolving threats
    self.eventBus:subscribe("threat_resolved", function(data)
        if data.status == "success" and data.threat and data.threat.assignedSpecialist and data.rewards and data.rewards.experience then
            local specialistId = data.threat.assignedSpecialist
            local xpGain = data.rewards.experience
            
            -- Determine which skill to award XP to based on threat category
            local skillToLevel = "basic_analysis" -- Default
            local category = data.threat.category
            if category == "network_attack" or category == "malware" then
                skillToLevel = "network_fundamentals"
            end

            -- Check if the specialist has the skill unlocked
            if self:isSkillUnlocked(specialistId, skillToLevel) then
                local awarded = self:awardXp(specialistId, skillToLevel, xpGain)
                if awarded then
                    print(string.format("Awarded %d XP to Specialist ID %s in '%s' for resolving threat.", xpGain, tostring(specialistId), self.skills[skillToLevel].name))
                end
            else
                -- If the primary skill isn't unlocked, award to the basic one as a fallback
                local awarded = self:awardXp(specialistId, "basic_analysis", xpGain)
                 if awarded then
                    print(string.format("Awarded %d XP to Specialist ID %s in 'Basic Analysis' (fallback) for resolving threat.", xpGain, tostring(specialistId)))
                end
            end
        end
    end)
end

-- Initialize skills for a new entity (specialist or player)
function SkillSystem:initializeEntity(entityId, entityType)
    if not self.skillProgress[entityId] then
        self.skillProgress[entityId] = {}
    end
    
    -- Automatically unlock basic skills for now
    self:unlockSkill(entityId, "basic_analysis")
    self:unlockSkill(entityId, "network_fundamentals")
end

function SkillSystem:getSkillDefinition(skillId)
    return self.skills and self.skills[skillId]
end

-- Unlock a skill for an entity
function SkillSystem:unlockSkill(entityId, skillId)
    if not self.skillProgress[entityId] then
        self.skillProgress[entityId] = {}
    end
    
    if not self.skillProgress[entityId][skillId] then
        self.skillProgress[entityId][skillId] = {
            level = 0,
            xp = 0,
            unlocked = true
        }
        
        self.eventBus:publish("skill_unlocked", {
            entityId = entityId,
            skillId = skillId,
            skill = self.skills[skillId]
        })
    end
end

-- Award XP to a specific skill
function SkillSystem:awardXp(entityId, skillId, amount)
    if not self.skillProgress[entityId] or not self.skillProgress[entityId][skillId] then
        return false
    end
    
    local skillProgress = self.skillProgress[entityId][skillId]
    local skill = self.skills[skillId]
    
    if not skill or skillProgress.level >= skill.maxLevel then
        return false
    end
    
    skillProgress.xp = skillProgress.xp + amount
    
    -- Check for level up
    local requiredXp = self:getXpRequiredForLevel(skillId, skillProgress.level + 1)
    if skillProgress.xp >= requiredXp then
        self:levelUpSkill(entityId, skillId)
    end
    
    self.eventBus:publish("xp_gained", {
        entityId = entityId,
        skillId = skillId,
        amount = amount,
        currentXp = skillProgress.xp,
        currentLevel = skillProgress.level
    })
    
    return true
end

-- Level up a skill
function SkillSystem:levelUpSkill(entityId, skillId)
    if not self.skillProgress[entityId] or not self.skillProgress[entityId][skillId] then
        return false
    end
    
    local skillProgress = self.skillProgress[entityId][skillId]
    local skill = self.skills[skillId]
    
    if not skill or skillProgress.level >= skill.maxLevel then
        return false
    end
    
    local newLevel = skillProgress.level + 1
    local requiredXp = self:getXpRequiredForLevel(skillId, newLevel)
    
    if skillProgress.xp >= requiredXp then
        skillProgress.level = newLevel
        skillProgress.xp = skillProgress.xp - requiredXp -- Carry over excess XP
        
        self.eventBus:publish("skill_level_up", {
            entityId = entityId,
            skillId = skillId,
            newLevel = newLevel,
            skill = skill
        })
        
        -- Check if this unlocks new skills
        self:checkSkillUnlocks(entityId)
        
        -- Continue leveling up if there's enough XP for the next level
        if skillProgress.level < skill.maxLevel then
            self:levelUpSkill(entityId, skillId)
        end
        
        return true
    end
    
    return false
end

-- Get skill by ID
function SkillSystem:getSkill(skillId)
    return self.skills[skillId]
end

-- Get all skill progress for a specific entity
function SkillSystem:getSkillProgress(entityId)
    return self.skillProgress[entityId]
end

-- Get XP required to advance from current level to next level
function SkillSystem:getXpRequiredForLevel(skillId, targetLevel)
    local skill = self.skills[skillId]
    if not skill or targetLevel <= 1 then
        return targetLevel == 1 and skill and skill.baseXpCost or 0
    end
    
    -- XP required to go from level (targetLevel-1) to targetLevel
    return math.floor(skill.baseXpCost * (skill.xpGrowth ^ (targetLevel - 2)))
end

-- Check if new skills can be unlocked for an entity
function SkillSystem:checkSkillUnlocks(entityId)
    for skillId, skill in pairs(self.skills) do
        if self:canUnlockSkill(entityId, skillId) and not self:isSkillUnlocked(entityId, skillId) then
            self:unlockSkill(entityId, skillId)
        end
    end
end

-- Check if a skill can be unlocked
function SkillSystem:canUnlockSkill(entityId, skillId)
    local skill = self.skills[skillId]
    if not skill or not skill.requirements then return true end -- No requirements means it's unlockable
    
    for reqSkillId, reqLevel in pairs(skill.requirements) do
        if not self.skillProgress[entityId] or not self.skillProgress[entityId][reqSkillId] or self.skillProgress[entityId][reqSkillId].level < reqLevel then
            return false
        end
    end
    
    return true
end

-- Get total effects from all leveled skills for an entity
function SkillSystem:getSkillEffects(entityId)
    local totalEffects = {}
    
    if not self.skillProgress[entityId] then
        return totalEffects
    end
    
    for skillId, progress in pairs(self.skillProgress[entityId]) do
        if progress.level > 0 then
            local skill = self.skills[skillId]
            if skill and skill.effects then
                for _, effect in ipairs(skill.effects) do
                    local currentEffectValue = totalEffects[effect.stat] or 0
                    -- Assuming additive bonus for now.
                    -- Example: { stat = "efficiency", bonus = 0.05 }
                    totalEffects[effect.stat] = currentEffectValue + (progress.level * effect.bonus)
                end
            end
        end
    end
    
    return totalEffects
end

-- Check if a skill is unlocked for an entity
function SkillSystem:isSkillUnlocked(entityId, skillId)
    if not self.skillProgress[entityId] or not self.skillProgress[entityId][skillId] then
        return false
    end
    return self.skillProgress[entityId][skillId].unlocked
end

-- Get all skills for an entity
function SkillSystem:getEntitySkills(entityId)
    return self.skillProgress[entityId] or {}
end

-- Get skill effects for an entity (used by other systems)
function SkillSystem:getSkillEffects(entityId)
    local effects = {
        -- Core stats
        efficiency = 0,
        speed = 0,
        trace = 0,
        defense = 0,
        
        -- Leadership effects
        teamEfficiencyBonus = 0,
        contractCapacity = 0,
        reputationMultiplier = 0,
        contractValueBonus = 0,
        
        -- Advanced effects
        IncidentSuccessRate = 0,
        automaticThreatDetection = 0,
        evidenceQuality = 0,
        containmentSpeed = 0,
        IncidentLeadershipBonus = 0,
        recoveryBonus = 0,
        reputationProtection = 0,
        contractGenerationRate = 0,
        clientSatisfactionBonus = 0,
        higherTierUnlockRate = 0,
        systemReliability = 0,
        scalabilityBonus = 0,
        malwareSignatureCreation = 0,
        vulnerabilityDiscovery = 0
    }
    
    if not self.skillProgress[entityId] then
        return effects
    end
    
    for skillId, progress in pairs(self.skillProgress[entityId]) do
        if progress.unlocked and progress.level > 0 then
            local skill = self.skills[skillId]
            if skill and skill.effects then
                for effectType, effectValue in pairs(skill.effects) do
                    if effects[effectType] ~= nil then
                        effects[effectType] = effects[effectType] + (effectValue * progress.level)
                    end
                end
            end
        end
    end
    
    return effects
end

-- Get available skills (for UI)
function SkillSystem:getAvailableSkills()
    return self.skills
end

-- Get all skills
function SkillSystem:getAllSkills()
    return self.skills
end

-- Get skills by category (for UI organization)
function SkillSystem:getSkillsByCategory(category)
    local categorizedSkills = {}
    for id, skill in pairs(self.skills) do
        if skill.category == category then
            table.insert(categorizedSkills, skill)
        end
    end
    return categorizedSkills
end

-- Get all skill categories
function SkillSystem:getSkillCategories()
    return self.categories
end

-- Get prerequisite chain for a skill
function SkillSystem:getPrerequisiteChain(skillId)
    local chain = {}
    local currentSkillId = skillId
    while currentSkillId do
        local skill = self.skills[currentSkillId]
        if not skill then break end
        table.insert(chain, 1, skill)
        -- Assuming single prerequisite for simplicity
        currentSkillId = skill.prerequisites and skill.prerequisites[1]
    end
    return chain
end

-- Get state for saving
function SkillSystem:getState()
    return {
        skillProgress = self.skillProgress
    }
end

-- Load state from save
function SkillSystem:loadState(state)
    if state.skillProgress then
        self.skillProgress = state.skillProgress
    end
end

-- Update skill system
function SkillSystem:update(dt)
    -- Could be used for passive skill XP gain or other time-based effects
    -- For now, skills are only advanced through explicit events
end

return SkillSystem