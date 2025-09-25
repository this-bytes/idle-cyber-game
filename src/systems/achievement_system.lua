-- Achievement System
-- Tracks player progress and unlocks rewards

local AchievementSystem = {}
AchievementSystem.__index = AchievementSystem

-- Create new achievement system
function AchievementSystem.new(eventBus)
    local self = setmetatable({}, AchievementSystem)
    self.eventBus = eventBus
    
    -- Achievement progress tracking
    self.progress = {
        totalClicks = 0,
        totalDataBitsEarned = 0,
        totalUpgradesPurchased = 0,
        maxClickCombo = 1.0,
        criticalHits = 0
    }
    
    -- Unlocked achievements
    self.unlocked = {}
    
    -- Achievement definitions
    self.achievements = {
        firstClick = {
            id = "firstClick",
            name = "🖱️ First Click",
            description = "Click to earn your first Data Bit",
            requirement = {type = "clicks", value = 1},
            reward = {type = "none"},
            unlocked = false
        },
        clickMaster = {
            id = "clickMaster",
            name = "🎯 Click Master",
            description = "Perform 100 clicks",
            requirement = {type = "clicks", value = 100},
            reward = {type = "clickPower", value = 2},
            unlocked = false
        },
        comboKing = {
            id = "comboKing",
            name = "🔥 Combo King",
            description = "Achieve a 5x click combo",
            requirement = {type = "maxCombo", value = 5.0},
            reward = {type = "dataBits", value = 100},
            unlocked = false
        },
        firstUpgrade = {
            id = "firstUpgrade",
            name = "🛒 First Purchase",
            description = "Buy your first upgrade",
            requirement = {type = "upgrades", value = 1},
            reward = {type = "dataBits", value = 50},
            unlocked = false
        },
        dataCollector = {
            id = "dataCollector",
            name = "💎 Data Collector",
            description = "Earn 1,000 Data Bits",
            requirement = {type = "totalEarned", value = 1000},
            reward = {type = "clickPower", value = 5},
            unlocked = false
        }
    }
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to relevant events
function AchievementSystem:subscribeToEvents()
    -- Track clicking achievements
    self.eventBus:subscribe("resource_clicked", function(data)
        if data.resource == "dataBits" then
            self.progress.totalClicks = self.progress.totalClicks + 1
            self.progress.totalDataBitsEarned = self.progress.totalDataBitsEarned + data.amount
            
            if data.combo > self.progress.maxClickCombo then
                self.progress.maxClickCombo = data.combo
            end
            
            if data.critical then
                self.progress.criticalHits = self.progress.criticalHits + 1
            end
        end
    end)
    
    -- Track upgrade purchases
    self.eventBus:subscribe("upgrade_purchased", function(data)
        self.progress.totalUpgradesPurchased = self.progress.totalUpgradesPurchased + 1
    end)
end

function AchievementSystem:update(dt)
    -- Check for newly unlocked achievements
    self:checkAchievements()
end

-- Check if any achievements can be unlocked
function AchievementSystem:checkAchievements()
    for achievementId, achievement in pairs(self.achievements) do
        if not achievement.unlocked and self:checkRequirement(achievement.requirement) then
            self:unlockAchievement(achievementId)
        end
    end
end

-- Check if requirement is met
function AchievementSystem:checkRequirement(requirement)
    local reqType = requirement.type
    local reqValue = requirement.value
    
    if reqType == "clicks" then
        return self.progress.totalClicks >= reqValue
    elseif reqType == "maxCombo" then
        return self.progress.maxClickCombo >= reqValue
    elseif reqType == "upgrades" then
        return self.progress.totalUpgradesPurchased >= reqValue
    elseif reqType == "totalEarned" then
        return self.progress.totalDataBitsEarned >= reqValue
    end
    
    return false
end

-- Unlock an achievement
function AchievementSystem:unlockAchievement(achievementId)
    local achievement = self.achievements[achievementId]
    if not achievement or achievement.unlocked then
        return false
    end
    
    achievement.unlocked = true
    self.unlocked[achievementId] = true
    
    -- Apply reward
    self:applyReward(achievement.reward)
    
    -- Publish achievement event
    self.eventBus:publish("achievement_unlocked", {
        achievementId = achievementId,
        achievement = achievement
    })
    
    print("🏆 Achievement Unlocked: " .. achievement.name)
    print("   " .. achievement.description)
    
    return true
end

-- Apply achievement reward
function AchievementSystem:applyReward(reward)
    if reward.type == "dataBits" then
        self.eventBus:publish("add_resource", {
            resource = "dataBits",
            amount = reward.value
        })
    elseif reward.type == "clickPower" then
        self.eventBus:publish("apply_upgrade_effect", {
            upgradeId = "achievement_reward",
            effectType = "clickPower",
            value = reward.value
        })
    end
end

function AchievementSystem:initializeProgress()
    -- Initialize progress tracking
    self.progress = {
        totalClicks = 0,
        totalDataBitsEarned = 0,
        totalUpgradesPurchased = 0,
        maxClickCombo = 1.0,
        criticalHits = 0
    }
end

-- Get all achievements
function AchievementSystem:getAllAchievements()
    return self.achievements
end

-- Get unlocked achievements
function AchievementSystem:getUnlockedAchievements()
    local unlocked = {}
    for achievementId, achievement in pairs(self.achievements) do
        if achievement.unlocked then
            unlocked[achievementId] = achievement
        end
    end
    return unlocked
end

-- Get progress
function AchievementSystem:getProgress()
    return self.progress
end

function AchievementSystem:getState()
    return {
        unlocked = self.unlocked,
        progress = self.progress,
        achievements = self.achievements
    }
end

function AchievementSystem:loadState(state)
    if state.unlocked then
        self.unlocked = state.unlocked
    end
    
    if state.progress then
        self.progress = state.progress
    end
    
    if state.achievements then
        for achievementId, achievementData in pairs(state.achievements) do
            if self.achievements[achievementId] then
                self.achievements[achievementId].unlocked = achievementData.unlocked
            end
        end
    end
end

return AchievementSystem