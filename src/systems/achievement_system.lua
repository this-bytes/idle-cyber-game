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
        totalContractsCompleted = 0,
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
            name = "🔥 Action Specialist",
            description = "Execute 5 consecutive successful actions",
            requirement = {type = "maxCombo", value = 5.0},
            reward = {type = "money", value = 500},
            unlocked = false
        },
        firstUpgrade = {
            id = "firstUpgrade",
            name = "🛒 First Purchase",
            description = "Buy your first upgrade",
            requirement = {type = "upgrades", value = 1},
            reward = {type = "money", value = 250},
            unlocked = false
        },
        businessBuilder = {
            id = "businessBuilder",
            name = "💼 Business Builder",
            description = "Complete 10 contracts successfully",
            requirement = {type = "contractsCompleted", value = 10},
            reward = {type = "reputation", value = 10},
            unlocked = false
        }
    }
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to relevant events
function AchievementSystem:subscribeToEvents()
    -- Track contract completions
    self.eventBus:subscribe("contract_completed", function(data)
        self.progress.totalContractsCompleted = self.progress.totalContractsCompleted + 1
        self:checkAchievements()
    end)
    
    -- Track upgrade purchases
    self.eventBus:subscribe("upgrade_purchased", function(data)
        self.progress.totalUpgradesPurchased = self.progress.totalUpgradesPurchased + 1
        self:checkAchievements()
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
    elseif reqType == "contractsCompleted" then
        return self.progress.totalContractsCompleted >= reqValue
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
    if reward.type == "money" then
        self.eventBus:publish("add_resource", {
            resource = "money",
            amount = reward.value
        })
    elseif reward.type == "reputation" then  
        self.eventBus:publish("add_resource", {
            resource = "reputation",
            amount = reward.value
        })
    end
end

function AchievementSystem:initializeProgress()
    -- Initialize progress tracking
    self.progress = {
        totalClicks = 0,
        totalContractsCompleted = 0,
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