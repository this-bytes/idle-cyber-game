-- Skill System - Cyber Empire Command
-- Handles expandable skill trees, progression, and effects

local SkillSystem = {}
SkillSystem.__index = SkillSystem

-- Create new skill system
function SkillSystem.new(eventBus)
    local self = setmetatable({}, SkillSystem)
    self.eventBus = eventBus
    
    -- Player and specialist skill progress
    -- Format: [entityId][skillId] = {level, xp, unlocked}
    self.skillProgress = {}
    
    -- Skill definitions - expandable system
    self.skills = {
        -- Core Security Skills
        ["basic_analysis"] = {
            id = "basic_analysis",
            name = "Basic Analysis",
            description = "Fundamental security analysis techniques",
            category = "analysis",
            maxLevel = 10,
            baseXpCost = 100,
            xpGrowth = 1.2,
            prerequisites = {},
            effects = {
                -- Effects per level
                efficiency = 0.05, -- +5% efficiency per level
                trace = 0.02       -- +2% trace ability per level
            },
            unlockRequirements = {} -- Always available
        },
        
        ["advanced_scanning"] = {
            id = "advanced_scanning",
            name = "Advanced Scanning",
            description = "Sophisticated network and system scanning",
            category = "analysis",
            maxLevel = 8,
            baseXpCost = 200,
            xpGrowth = 1.3,
            prerequisites = {"basic_analysis"},
            effects = {
                efficiency = 0.08,
                speed = 0.03,
                trace = 0.05
            },
            unlockRequirements = {
                skills = {basic_analysis = 3} -- Requires Basic Analysis level 3
            }
        },
        
        ["threat_hunting"] = {
            id = "threat_hunting",
            name = "Threat Hunting",
            description = "Proactive threat detection and analysis",
            category = "analysis",
            maxLevel = 12,
            baseXpCost = 500,
            xpGrowth = 1.4,
            prerequisites = {"advanced_scanning"},
            effects = {
                efficiency = 0.12,
                trace = 0.1,
                defense = 0.03
            },
            unlockRequirements = {
                skills = {advanced_scanning = 5},
                reputation = 50
            }
        },
        
        -- Network Security Skills
        ["network_fundamentals"] = {
            id = "network_fundamentals",
            name = "Network Fundamentals",
            description = "Basic network security principles",
            category = "network",
            maxLevel = 10,
            baseXpCost = 120,
            xpGrowth = 1.15,
            prerequisites = {},
            effects = {
                speed = 0.04,
                defense = 0.06
            },
            unlockRequirements = {}
        },
        
        ["firewall_management"] = {
            id = "firewall_management",
            name = "Firewall Management",
            description = "Advanced firewall configuration and monitoring",
            category = "network",
            maxLevel = 8,
            baseXpCost = 250,
            xpGrowth = 1.25,
            prerequisites = {"network_fundamentals"},
            effects = {
                defense = 0.1,
                efficiency = 0.03
            },
            unlockRequirements = {
                skills = {network_fundamentals = 4}
            }
        },
        
        -- Incident Response Skills
        ["basic_response"] = {
            id = "basic_response",
            name = "Basic Incident Response",
            description = "Fundamental incident response procedures",
            category = "incident",
            maxLevel = 10,
            baseXpCost = 150,
            xpGrowth = 1.2,
            prerequisites = {},
            effects = {
                speed = 0.06,
                trace = 0.04
            },
            unlockRequirements = {}
        },
        
        ["crisis_management"] = {
            id = "crisis_management",
            name = "Crisis Management",
            description = "Advanced crisis handling and coordination",
            category = "incident",
            maxLevel = 8,
            baseXpCost = 400,
            xpGrowth = 1.35,
            prerequisites = {"basic_response"},
            effects = {
                efficiency = 0.1,
                speed = 0.08,
                defense = 0.05
            },
            unlockRequirements = {
                skills = {basic_response = 6},
                missionTokens = 2
            }
        },
        
        -- Leadership Skills (CEO specific)
        ["team_coordination"] = {
            id = "team_coordination",
            name = "Team Coordination",
            description = "Effective team management and coordination",
            category = "leadership",
            maxLevel = 15,
            baseXpCost = 200,
            xpGrowth = 1.1,
            prerequisites = {},
            effects = {
                teamEfficiencyBonus = 0.02, -- +2% team-wide efficiency per level
                contractCapacity = 0.1      -- +10% contract capacity per level
            },
            unlockRequirements = {
                specialistType = "ceo" -- Only CEO can learn this
            }
        },
        
        ["strategic_planning"] = {
            id = "strategic_planning",
            name = "Strategic Planning",
            description = "Long-term strategic business planning",
            category = "leadership",
            maxLevel = 10,
            baseXpCost = 500,
            xpGrowth = 1.2,
            prerequisites = {"team_coordination"},
            effects = {
                reputationMultiplier = 0.05, -- +5% reputation gain per level
                contractValueBonus = 0.03    -- +3% contract value per level
            },
            unlockRequirements = {
                specialistType = "ceo",
                skills = {team_coordination = 8},
                reputation = 100
            }
        }
    }
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to relevant events
function SkillSystem:subscribeToEvents()
    -- Award XP when contracts complete
    self.eventBus:subscribe("contract_completed", function(data)
        local xpGain = data.contract.budget * 0.01 -- 1% of contract budget as XP
        self:awardXp(0, "basic_analysis", xpGain)  -- Award to CEO
        
        -- Award XP to assigned specialists
        if data.assignedSpecialists then
            for _, specialistId in ipairs(data.assignedSpecialists) do
                self:awardXp(specialistId, "basic_analysis", xpGain * 0.8)
            end
        end
    end)
    
    -- Award XP for crisis mode activities
    self.eventBus:subscribe("crisis_resolved", function(data)
        local xpGain = data.difficulty * 50 -- Base XP based on crisis difficulty
        if data.specialistId then
            self:awardXp(data.specialistId, "basic_response", xpGain)
        end
    end)
end

-- Initialize skills for a new entity (specialist or player)
function SkillSystem:initializeEntity(entityId, entityType)
    if not self.skillProgress[entityId] then
        self.skillProgress[entityId] = {}
    end
    
    -- Unlock basic skills based on entity type
    if entityType == "ceo" then
        self:unlockSkill(entityId, "basic_analysis")
        self:unlockSkill(entityId, "team_coordination")
    elseif entityType then
        -- For specialists, unlock basic skills in their domain
        self:unlockSkill(entityId, "basic_analysis")
        if entityType:find("network") then
            self:unlockSkill(entityId, "network_fundamentals")
        end
        if entityType:find("incident") or entityType:find("response") then
            self:unlockSkill(entityId, "basic_response")
        end
    end
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
    if not skill then
        return false
    end
    
    -- Check unlock requirements
    if skill.unlockRequirements then
        -- Check skill prerequisites
        if skill.unlockRequirements.skills then
            for reqSkillId, reqLevel in pairs(skill.unlockRequirements.skills) do
                local currentLevel = self:getSkillLevel(entityId, reqSkillId)
                if currentLevel < reqLevel then
                    return false
                end
            end
        end
        
        -- Check if this skill is restricted to certain specialist types
        if skill.unlockRequirements.specialistType then
            -- This would need integration with specialist system
            -- For now, assume it's checkable via event bus
            local canLearn = false
            self.eventBus:publish("check_specialist_type", {
                entityId = entityId,
                requiredType = skill.unlockRequirements.specialistType,
                callback = function(result) canLearn = result end
            })
            if not canLearn then
                return false
            end
        end
        
        -- Other requirements (reputation, resources) would be checked via event bus
    end
    
    return true
end

-- Get skill level for an entity
function SkillSystem:getSkillLevel(entityId, skillId)
    if not self.skillProgress[entityId] or not self.skillProgress[entityId][skillId] then
        return 0
    end
    return self.skillProgress[entityId][skillId].level
end

-- Check if skill is unlocked
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
        efficiency = 0,
        speed = 0,
        trace = 0,
        defense = 0,
        teamEfficiencyBonus = 0,
        contractCapacity = 0,
        reputationMultiplier = 0,
        contractValueBonus = 0
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