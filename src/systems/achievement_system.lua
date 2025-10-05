-- Achievement System - Tracks player progress and unlocks rewards
-- Manages achievement tracking, unlocking, and reward distribution

local AchievementSystem = {}
AchievementSystem.__index = AchievementSystem

-- System metadata for automatic registration
AchievementSystem.metadata = {
    priority = 70,
    dependencies = {
        "DataManager",
        "ResourceManager"
    },
    systemName = "AchievementSystem"
}

function AchievementSystem.new(eventBus, dataManager, resourceManager)
    local self = setmetatable({}, AchievementSystem)

    -- Dependencies
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.resourceManager = resourceManager

    -- Achievement state
    self.achievements = {}
    self.unlockedAchievements = {}
    self.progress = {}

    -- Load achievement definitions
    self:loadAchievements()

    -- Subscribe to relevant events
    self:subscribeToEvents()

    print("🏆 Achievement System initialized")
    return self
end

-- Load achievement definitions from data
function AchievementSystem:loadAchievements()
    if not self.dataManager then
        print("⚠️ AchievementSystem: No dataManager available")
        return
    end

    local achievementData = self.dataManager:getData("achievements")
    if not achievementData or not achievementData.achievements then
        print("⚠️ AchievementSystem: No achievement data found")
        return
    end

    self.achievements = achievementData.achievements

    -- Initialize progress tracking
    local count = 0
    for id, achievement in pairs(self.achievements) do
        self.progress[id] = {
            current = 0,
            unlocked = achievement.unlocked or false,
            unlockedAt = nil
        }
        count = count + 1
    end

    print("📚 Loaded " .. count .. " achievements")
end

-- Subscribe to events that trigger achievement checks
function AchievementSystem:subscribeToEvents()
    if not self.eventBus then return end

    -- Game events
    self.eventBus:subscribe("game_started", function() self:checkAchievement("first_contract") end)

    -- Resource events
    self.eventBus:subscribe("resource_changed", function(data)
        if data.resource == "money" then
            self:updateProgress("millionaire", data.newValue)
        elseif data.resource == "reputation" then
            self:updateProgress("reputation_master", data.newValue)
        end
    end)

    -- Contract events
    self.eventBus:subscribe("contract_accepted", function()
        self:updateProgress("first_contract", 1)
        self:updateProgress("contract_master", 1)
    end)

    self.eventBus:subscribe("contract_completed", function(data)
        self:updateProgress("contract_master", 1)
        if data.industry then
            self:updateProgress("contract_industry_completed", 1, {industry = data.industry})
        end
        if data.tier then
            self:updateProgress("contract_tier_completed", 1, {tier = data.tier})
        end
    end)

    -- Threat events
    self.eventBus:subscribe("threat_detected", function()
        self:updateProgress("first_threat_resolved", 1)
        self:updateProgress("threat_hunter", 1)
    end)

    self.eventBus:subscribe("threat_resolved", function(data)
        self:updateProgress("threat_hunter", 1)
        if data.category then
            self:updateProgress("threats_resolved_by_category", 1, {category = data.category})
        end
        if data.rarity then
            self:updateProgress("threats_resolved_by_rarity", 1, {rarity = data.rarity})
        end
        if data.id then
            self:updateProgress("threat_resolved_by_id", 1, {threat_id = data.id})
        end
        if data.perfect then
            self:updateProgress("perfect_resolutions", 1)
        end
    end)

    -- Specialist events
    self.eventBus:subscribe("specialist_hired", function()
        self:updateProgress("first_specialist", 1)
        self:updateProgress("team_builder", 1)
        self:updateProgress("specialist_collector", 1)
    end)

    -- Upgrade events
    self.eventBus:subscribe("upgrade_purchased", function()
        self:updateProgress("upgrade_enthusiast", 1)
        self:updateProgress("upgrade_master", 1)
    end)

    -- Time-based events
    self.eventBus:subscribe("play_time_milestone", function(data)
        if data.hours == 24 then
            self:updateProgress("time_waster", 24)
        elseif data.hours == 100 then
            self:updateProgress("dedicated_player", 100)
        end
    end)

    -- Offline earnings
    self.eventBus:subscribe("offline_earnings_calculated", function(data)
        self:updateProgress("idle_tycoon", data.netGain)
        self:updateProgress("offline_legend", data.netGain)
    end)
end

-- Update progress for a specific achievement
function AchievementSystem:updateProgress(achievementId, value, context)
    if not self.achievements[achievementId] or not self.progress[achievementId] then
        return
    end

    local achievement = self.achievements[achievementId]
    local progress = self.progress[achievementId]

    -- Skip if already unlocked
    if progress.unlocked then
        return
    end

    -- Check requirement type
    local requirement = achievement.requirement
    local shouldUnlock = false

    if requirement.type == "clicks" or requirement.type == "total_money_earned" or
       requirement.type == "reputation_earned" or requirement.type == "threats_resolved" or
       requirement.type == "contracts_completed" or requirement.type == "specialists_hired" or
       requirement.type == "unique_specialists_hired" or requirement.type == "unique_upgrades_purchased" or
       requirement.type == "play_time_hours" or requirement.type == "offline_earnings" or
       requirement.type == "perfect_resolutions" then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "threats_resolved_by_category" and context and context.category == requirement.category then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "threats_resolved_by_rarity" and context and context.rarity == requirement.rarity then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "threat_resolved_by_id" and context and context.threat_id == requirement.threat_id then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "contract_industry_completed" and context and context.industry == requirement.industry then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "contract_tier_completed" and context and context.tier == requirement.tier then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "threat_resolved_perfect" and context and context.threat_id == requirement.threat_id then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "fastest_resolution_seconds" then
        if value <= requirement.value then
            shouldUnlock = true
        end

    elseif requirement.type == "simultaneous_resolutions" then
        if value >= requirement.value then
            shouldUnlock = true
        end

    elseif requirement.type == "survived_major_loss" then
        progress.current = progress.current + value
        shouldUnlock = progress.current >= requirement.value

    elseif requirement.type == "resolution_efficiency_percent" then
        if value >= requirement.value then
            shouldUnlock = true
        end
    end

    -- Unlock achievement if conditions met
    if shouldUnlock then
        self:unlockAchievement(achievementId)
    end
end

-- Unlock an achievement
function AchievementSystem:unlockAchievement(achievementId)
    if not self.achievements[achievementId] or self.progress[achievementId].unlocked then
        return
    end

    local achievement = self.achievements[achievementId]
    local progress = self.progress[achievementId]

    -- Mark as unlocked
    progress.unlocked = true
    progress.unlockedAt = os.time()

    -- Add to unlocked list
    table.insert(self.unlockedAchievements, achievementId)

    -- Grant rewards
    self:grantReward(achievement.reward)

    -- Publish event
    self.eventBus:publish("achievement_unlocked", {
        achievement = achievement,
        id = achievementId
    })

    print("🏆 Achievement Unlocked: " .. achievement.name)
end

-- Grant achievement reward
function AchievementSystem:grantReward(reward)
    if not reward or reward.type == "none" then
        return
    end

    if reward.type == "money" and self.resourceManager then
        self.resourceManager:addResource("money", reward.value)
        print("💰 Achievement reward: $" .. reward.value)

    elseif reward.type == "reputation" and self.resourceManager then
        self.resourceManager:addResource("reputation", reward.value)
        print("⭐ Achievement reward: " .. reward.value .. " reputation")
    end
end

-- Get achievement progress
function AchievementSystem:getProgress(achievementId)
    return self.progress[achievementId] or {current = 0, unlocked = false}
end

-- Get all achievements
function AchievementSystem:getAllAchievements()
    return self.achievements
end

-- Get unlocked achievements
function AchievementSystem:getUnlockedAchievements()
    return self.unlockedAchievements
end

-- Get achievement stats
function AchievementSystem:getStats()
    local total = 0
    local unlocked = 0

    for _, achievement in pairs(self.achievements) do
        total = total + 1
        if self.progress[achievement.id] and self.progress[achievement.id].unlocked then
            unlocked = unlocked + 1
        end
    end

    return {
        total = total,
        unlocked = unlocked,
        completionRate = total > 0 and (unlocked / total) or 0
    }
end

-- Check if achievement is unlocked
function AchievementSystem:isUnlocked(achievementId)
    return self.progress[achievementId] and self.progress[achievementId].unlocked
end

-- Update method (for time-based achievements)
function AchievementSystem:update(dt)
    -- Could implement time-based tracking here
end

-- Save achievement progress
function AchievementSystem:saveProgress()
    local saveData = {
        progress = self.progress,
        unlockedAchievements = self.unlockedAchievements
    }
    return saveData
end

-- Load achievement progress
function AchievementSystem:loadProgress(saveData)
    if saveData then
        self.progress = saveData.progress or self.progress
        self.unlockedAchievements = saveData.unlockedAchievements or self.unlockedAchievements
    end
end

return AchievementSystem