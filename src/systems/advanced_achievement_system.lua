-- Advanced Achievement System - Rich achievement tracking with hidden unlocks and progression
-- Provides meaningful goals and rewards to drive player engagement

local AdvancedAchievementSystem = {}
AdvancedAchievementSystem.__index = AdvancedAchievementSystem

function AdvancedAchievementSystem.new(eventBus)
    local self = setmetatable({}, AdvancedAchievementSystem)
    self.eventBus = eventBus
    
    -- Achievement state
    self.unlockedAchievements = {}
    self.achievementProgress = {}
    self.hiddenAchievements = {}
    self.recentUnlocks = {}
    self.categories = {}
    
    -- Statistics tracking
    self.stats = {
        -- Basic progression
        contractsCompleted = 0,
        totalEarnings = 0,
        reputationGained = 0,
        
        -- Combat/Crisis stats
        crisesResolved = 0,
        crisesFailed = 0,
        perfectCrises = 0,
        
        -- Business stats
        specialistsHired = 0,
        upgradesPurchased = 0,
        prestigeCount = 0,
        
        -- Time-based stats
        totalPlaytime = 0,
        longestSession = 0,
        sessionsPlayed = 0,
        
        -- Skill-based stats
        perfectContracts = 0,
        highValueContracts = 0,
        rapidContracts = 0,
        
        -- Discovery stats
        secretsFound = 0,
        easterEggsFound = 0,
        hiddenAreasVisited = 0,
        
        -- Social stats (future expansion)
        contractsShared = 0,
        achievementsShared = 0
    }
    
    -- Define achievement categories and their achievements
    self:initializeAchievements()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Initialize comprehensive achievement system
function AdvancedAchievementSystem:initializeAchievements()
    self.categories = {
        -- ===============================
        -- FIRST STEPS - Tutorial/Beginner achievements
        -- ===============================
        first_steps = {
            title = "First Steps",
            description = "Getting started in the cybersecurity world",
            icon = "🚀",
            achievements = {
                first_contract = {
                    title = "First Client",
                    description = "Complete your first security contract",
                    icon = "📋",
                    condition = function(stats) return stats.contractsCompleted >= 1 end,
                    rewards = {money = 500, reputation = 1},
                    rarity = "common"
                },
                first_dollar = {
                    title = "First Dollar Earned",
                    description = "Earn your first dollar in the cybersecurity business",
                    icon = "💰",
                    condition = function(stats) return stats.totalEarnings >= 1 end,
                    rewards = {money = 100},
                    rarity = "common"
                },
                first_hire = {
                    title = "Growing the Team",
                    description = "Hire your first cybersecurity specialist",
                    icon = "👥",
                    condition = function(stats) return stats.specialistsHired >= 1 end,
                    rewards = {reputation = 2, missionTokens = 1},
                    rarity = "common"
                }
            }
        },
        
        -- ===============================
        -- BUSINESS BUILDER - Enterprise growth achievements
        -- ===============================
        business_builder = {
            title = "Business Builder",
            description = "Growing your cybersecurity empire",
            icon = "🏢",
            achievements = {
                money_maker = {
                    title = "Money Maker",
                    description = "Earn $50,000 in total revenue",
                    icon = "💰",
                    condition = function(stats) return stats.totalEarnings >= 50000 end,
                    rewards = {money = 2500, reputation = 5},
                    rarity = "uncommon"
                },
                reputation_builder = {
                    title = "Reputation Builder", 
                    description = "Gain 100 reputation points",
                    icon = "⭐",
                    condition = function(stats) return stats.reputationGained >= 100 end,
                    rewards = {money = 5000, prestigePoints = 1},
                    rarity = "uncommon"
                },
                team_leader = {
                    title = "Team Leader",
                    description = "Build a team of 10 specialists",
                    icon = "👑",
                    condition = function(stats) return stats.specialistsHired >= 10 end,
                    rewards = {reputation = 10, missionTokens = 5},
                    rarity = "rare"
                },
                empire_builder = {
                    title = "Cyber Empire",
                    description = "Reach $1,000,000 in total earnings",
                    icon = "🏰",
                    condition = function(stats) return stats.totalEarnings >= 1000000 end,
                    rewards = {money = 50000, prestigePoints = 5, specialBadge = "Empire Crown"},
                    rarity = "legendary"
                }
            }
        },
        
        -- ===============================
        -- CRISIS MASTER - Combat/Crisis achievements
        -- ===============================
        crisis_master = {
            title = "Crisis Master",
            description = "Mastering the art of incident response",
            icon = "🚨",
            achievements = {
                first_responder = {
                    title = "First Responder",
                    description = "Successfully resolve your first security crisis",
                    icon = "🚑",
                    condition = function(stats) return stats.crisesResolved >= 1 end,
                    rewards = {reputation = 3, missionTokens = 2},
                    rarity = "common"
                },
                crisis_veteran = {
                    title = "Crisis Veteran",
                    description = "Resolve 25 security crises",
                    icon = "🎖️",
                    condition = function(stats) return stats.crisesResolved >= 25 end,
                    rewards = {money = 10000, reputation = 15, missionTokens = 10},
                    rarity = "rare"
                },
                perfectionist = {
                    title = "Perfect Response",
                    description = "Achieve perfect scores on 5 crisis responses",
                    icon = "💎",
                    condition = function(stats) return stats.perfectCrises >= 5 end,
                    rewards = {reputation = 20, prestigePoints = 3, specialSkill = "Crisis Mastery"},
                    rarity = "epic"
                },
                unbreakable = {
                    title = "Unbreakable Defense",
                    description = "Resolve 10 crises in a row without failure",
                    icon = "🛡️",
                    condition = function(stats) return stats.perfectCrises >= 10 and stats.crisesFailed == 0 end,
                    rewards = {money = 25000, reputation = 30, prestigePoints = 5},
                    rarity = "legendary",
                    hidden = true
                }
            }
        },
        
        -- ===============================
        -- SPEED DEMON - Time-based achievements
        -- ===============================
        speed_demon = {
            title = "Speed Demon",
            description = "For those who work fast and efficiently",
            icon = "⚡",
            achievements = {
                rapid_responder = {
                    title = "Rapid Responder",
                    description = "Complete 5 contracts in record time",
                    icon = "🏃",
                    condition = function(stats) return stats.rapidContracts >= 5 end,
                    rewards = {money = 3000, reputation = 5},
                    rarity = "uncommon"
                },
                speed_demon = {
                    title = "Speed Demon",
                    description = "Complete 20 contracts in under 60 seconds each",
                    icon = "💨",
                    condition = function(stats) return stats.rapidContracts >= 20 end,
                    rewards = {money = 15000, reputation = 15, specialBonus = "Speed Multiplier"},
                    rarity = "epic"
                },
                lightning_fast = {
                    title = "Lightning Fast",
                    description = "Complete a high-value contract in under 30 seconds",
                    icon = "⚡",
                    condition = function(stats) return stats.rapidContracts >= 1 and stats.highValueContracts >= 1 end,
                    rewards = {money = 10000, prestigePoints = 2},
                    rarity = "rare",
                    hidden = true
                }
            }
        },
        
        -- ===============================
        -- EXPLORER - Discovery achievements
        -- ===============================
        explorer = {
            title = "Explorer",
            description = "For those who discover hidden secrets",
            icon = "🔍",
            achievements = {
                secret_seeker = {
                    title = "Secret Seeker",
                    description = "Find your first hidden secret",
                    icon = "🕵️",
                    condition = function(stats) return stats.secretsFound >= 1 end,
                    rewards = {reputation = 5, missionTokens = 3},
                    rarity = "uncommon",
                    hidden = true
                },
                easter_egg_hunter = {
                    title = "Easter Egg Hunter",
                    description = "Discover 5 hidden easter eggs",
                    icon = "🥚",
                    condition = function(stats) return stats.easterEggsFound >= 5 end,
                    rewards = {money = 7500, prestigePoints = 2, specialBadge = "Golden Egg"},
                    rarity = "rare",
                    hidden = true
                },
                master_explorer = {
                    title = "Master Explorer",
                    description = "Visit all hidden areas and find all secrets",
                    icon = "🗺️",
                    condition = function(stats) return stats.hiddenAreasVisited >= 10 and stats.secretsFound >= 20 end,
                    rewards = {money = 50000, prestigePoints = 10, specialTitle = "Master Explorer"},
                    rarity = "legendary",
                    hidden = true
                }
            }
        },
        
        -- ===============================
        -- PERFECTIONIST - Quality achievements
        -- ===============================
        perfectionist = {
            title = "Perfectionist",
            description = "For those who demand excellence",
            icon = "✨",
            achievements = {
                quality_first = {
                    title = "Quality First",
                    description = "Complete 10 contracts with perfect ratings",
                    icon = "⭐",
                    condition = function(stats) return stats.perfectContracts >= 10 end,
                    rewards = {reputation = 10, money = 5000},
                    rarity = "uncommon"
                },
                excellence_standard = {
                    title = "Excellence Standard",
                    description = "Maintain 100% perfect rating across 25 contracts",
                    icon = "🏆",
                    condition = function(stats) return stats.perfectContracts >= 25 end,
                    rewards = {money = 20000, reputation = 25, specialSkill = "Quality Assurance"},
                    rarity = "epic"
                },
                legendary_perfectionist = {
                    title = "Legendary Perfectionist",
                    description = "Achieve perfect ratings on 100 contracts without a single failure",
                    icon = "👑",
                    condition = function(stats) return stats.perfectContracts >= 100 and stats.crisesFailed == 0 end,
                    rewards = {money = 100000, prestigePoints = 15, specialTitle = "Perfection Master"},
                    rarity = "legendary",
                    hidden = true
                }
            }
        },
        
        -- ===============================
        -- SOCIAL CONNECTOR - Community achievements (future expansion)
        -- ===============================
        social_connector = {
            title = "Social Connector",
            description = "Building connections in the cybersecurity community",
            icon = "🤝",
            achievements = {
                networker = {
                    title = "Networker",
                    description = "Share 10 contract successes with the community",
                    icon = "📢",
                    condition = function(stats) return stats.contractsShared >= 10 end,
                    rewards = {reputation = 15, missionTokens = 5},
                    rarity = "uncommon",
                    hidden = true
                },
                achievement_collector = {
                    title = "Achievement Collector",
                    description = "Share 25 achievements with others",
                    icon = "🏅",
                    condition = function(stats) return stats.achievementsShared >= 25 end,
                    rewards = {prestigePoints = 5, specialBadge = "Community Champion"},
                    rarity = "rare",
                    hidden = true
                }
            }
        }
    }
end

-- Subscribe to game events for achievement tracking
function AdvancedAchievementSystem:subscribeToEvents()
    if not self.eventBus then return end
    
    -- Contract events
    self.eventBus:subscribe("contract_completed", function(data)
        self.stats.contractsCompleted = self.stats.contractsCompleted + 1
        
        -- Track contract quality
        if data.perfectRating then
            self.stats.perfectContracts = self.stats.perfectContracts + 1
        end
        
        -- Track high-value contracts
        if data.contract and data.contract.totalBudget and data.contract.totalBudget > 10000 then
            self.stats.highValueContracts = self.stats.highValueContracts + 1
        end
        
        -- Track rapid completion
        if data.completionTime and data.completionTime < 60 then
            self.stats.rapidContracts = self.stats.rapidContracts + 1
        end
        
        self:checkAchievements()
    end)
    
    -- Currency events
    self.eventBus:subscribe("currency_awarded", function(data)
        if data.currency == "money" then
            self.stats.totalEarnings = self.stats.totalEarnings + data.amount
        elseif data.currency == "reputation" then
            self.stats.reputationGained = self.stats.reputationGained + data.amount
        end
        
        self:checkAchievements()
    end)
    
    -- Crisis events
    self.eventBus:subscribe("crisis_resolved", function(data)
        self.stats.crisesResolved = self.stats.crisesResolved + 1
        
        if data.perfectScore then
            self.stats.perfectCrises = self.stats.perfectCrises + 1
        end
        
        self:checkAchievements()
    end)
    
    self.eventBus:subscribe("crisis_failed", function(data)
        self.stats.crisesFailed = self.stats.crisesFailed + 1
        self:checkAchievements()
    end)
    
    -- Specialist events
    self.eventBus:subscribe("specialist_hired", function(data)
        self.stats.specialistsHired = self.stats.specialistsHired + 1
        self:checkAchievements()
    end)
    
    -- Upgrade events
    self.eventBus:subscribe("upgrade_purchased", function(data)
        self.stats.upgradesPurchased = self.stats.upgradesPurchased + 1
        self:checkAchievements()
    end)
    
    -- Prestige events
    self.eventBus:subscribe("prestige_performed", function(data)
        self.stats.prestigeCount = self.stats.prestigeCount + 1
        self:checkAchievements()
    end)
    
    -- Discovery events
    self.eventBus:subscribe("secret_found", function(data)
        self.stats.secretsFound = self.stats.secretsFound + 1
        self:checkAchievements()
    end)
    
    self.eventBus:subscribe("easter_egg_found", function(data)
        self.stats.easterEggsFound = self.stats.easterEggsFound + 1
        self:checkAchievements()
    end)
    
    self.eventBus:subscribe("hidden_area_visited", function(data)
        self.stats.hiddenAreasVisited = self.stats.hiddenAreasVisited + 1
        self:checkAchievements()
    end)
end

-- Check all achievements for completion
function AdvancedAchievementSystem:checkAchievements()
    for categoryId, category in pairs(self.categories) do
        for achievementId, achievement in pairs(category.achievements) do
            local fullId = categoryId .. "." .. achievementId
            
            -- Skip if already unlocked
            if not self.unlockedAchievements[fullId] then
                -- Check if condition is met
                if achievement.condition(self.stats) then
                    self:unlockAchievement(fullId, categoryId, achievementId, achievement)
                end
            end
        end
    end
end

-- Unlock an achievement
function AdvancedAchievementSystem:unlockAchievement(fullId, categoryId, achievementId, achievement)
    -- Mark as unlocked
    self.unlockedAchievements[fullId] = {
        unlockedAt = love.timer and love.timer.getTime() or 0,
        category = categoryId,
        achievement = achievementId
    }
    
    -- Add to recent unlocks
    table.insert(self.recentUnlocks, {
        id = fullId,
        achievement = achievement,
        category = self.categories[categoryId],
        timestamp = love.timer and love.timer.getTime() or 0
    })
    
    -- Keep only recent 10 unlocks
    while #self.recentUnlocks > 10 do
        table.remove(self.recentUnlocks, 1)
    end
    
    -- Award rewards
    if achievement.rewards then
        for currency, amount in pairs(achievement.rewards) do
            if currency == "specialBadge" or currency == "specialTitle" or currency == "specialSkill" or currency == "specialBonus" then
                -- Handle special rewards
                self:awardSpecialReward(currency, amount)
            else
                -- Award currency
                if self.eventBus then
                    self.eventBus:publish("add_resource", {
                        resource = currency,
                        amount = amount
                    })
                end
            end
        end
    end
    
    -- Emit achievement unlocked event
    if self.eventBus then
        self.eventBus:publish("achievement_unlocked", {
            id = fullId,
            achievement = achievement,
            category = self.categories[categoryId]
        })
    end
    
    print("🏆 Achievement Unlocked: " .. achievement.title .. " - " .. achievement.description)
    
    -- Check for meta-achievements (achievements for getting achievements)
    self:checkMetaAchievements()
end

-- Award special rewards
function AdvancedAchievementSystem:awardSpecialReward(type, reward)
    -- TODO: Implement special reward system
    print("🎁 Special reward earned: " .. type .. " - " .. reward)
end

-- Check for meta-achievements (achievements about achievements)
function AdvancedAchievementSystem:checkMetaAchievements()
    local totalUnlocked = self:getTotalUnlockedCount()
    
    -- Achievement collector milestones
    local milestones = {5, 10, 25, 50, 100}
    for _, milestone in ipairs(milestones) do
        local metaId = "meta.collector_" .. milestone
        if totalUnlocked >= milestone and not self.unlockedAchievements[metaId] then
            local metaAchievement = {
                title = "Achievement Collector (" .. milestone .. ")",
                description = "Unlock " .. milestone .. " achievements",
                icon = "🏆",
                rewards = {prestigePoints = math.floor(milestone / 5), reputation = milestone * 2},
                rarity = milestone >= 50 and "legendary" or milestone >= 25 and "epic" or "rare"
            }
            
            self.unlockedAchievements[metaId] = {
                unlockedAt = love.timer and love.timer.getTime() or 0,
                category = "meta",
                achievement = "collector_" .. milestone
            }
            
            -- Award rewards and emit event
            if metaAchievement.rewards then
                for currency, amount in pairs(metaAchievement.rewards) do
                    if self.eventBus then
                        self.eventBus:publish("add_resource", {
                            resource = currency,
                            amount = amount
                        })
                    end
                end
            end
            
            if self.eventBus then
                self.eventBus:publish("achievement_unlocked", {
                    id = metaId,
                    achievement = metaAchievement,
                    category = {title = "Meta Achievements", icon = "🎯"}
                })
            end
            
            print("🌟 Meta Achievement Unlocked: " .. metaAchievement.title)
        end
    end
end

-- Update method for time-based tracking
function AdvancedAchievementSystem:update(dt)
    self.stats.totalPlaytime = self.stats.totalPlaytime + dt
    
    -- Clean up old recent unlocks (older than 5 minutes)
    local currentTime = love.timer and love.timer.getTime() or 0
    for i = #self.recentUnlocks, 1, -1 do
        local unlock = self.recentUnlocks[i]
        if currentTime - unlock.timestamp > 300 then -- 5 minutes
            table.remove(self.recentUnlocks, i)
        end
    end
end

-- Get achievement statistics
function AdvancedAchievementSystem:getStats()
    local totalAchievements = 0
    local unlockedCount = 0
    local hiddenCount = 0
    local hiddenUnlocked = 0
    
    for categoryId, category in pairs(self.categories) do
        for achievementId, achievement in pairs(category.achievements) do
            totalAchievements = totalAchievements + 1
            
            local fullId = categoryId .. "." .. achievementId
            if self.unlockedAchievements[fullId] then
                unlockedCount = unlockedCount + 1
                if achievement.hidden then
                    hiddenUnlocked = hiddenUnlocked + 1
                end
            end
            
            if achievement.hidden then
                hiddenCount = hiddenCount + 1
            end
        end
    end
    
    return {
        total = totalAchievements,
        unlocked = unlockedCount,
        percentage = (unlockedCount / totalAchievements) * 100,
        hidden = hiddenCount,
        hiddenUnlocked = hiddenUnlocked,
        recent = #self.recentUnlocks
    }
end

-- Get achievements by category
function AdvancedAchievementSystem:getAchievementsByCategory(categoryId)
    local category = self.categories[categoryId]
    if not category then return {} end
    
    local achievements = {}
    for achievementId, achievement in pairs(category.achievements) do
        local fullId = categoryId .. "." .. achievementId
        local unlocked = self.unlockedAchievements[fullId]
        
        -- Only show hidden achievements if unlocked
        if not achievement.hidden or unlocked then
            achievements[achievementId] = {
                data = achievement,
                unlocked = unlocked,
                progress = self:getAchievementProgress(fullId, achievement)
            }
        end
    end
    
    return achievements
end

-- Get progress towards an achievement
function AdvancedAchievementSystem:getAchievementProgress(fullId, achievement)
    if self.unlockedAchievements[fullId] then
        return 1.0 -- 100% complete
    end
    
    -- TODO: Implement progress tracking for incremental achievements
    -- For now, just return 0 or estimated progress based on stats
    return 0.0
end

-- Get recent unlocks
function AdvancedAchievementSystem:getRecentUnlocks()
    return self.recentUnlocks
end

-- Get total unlocked count
function AdvancedAchievementSystem:getTotalUnlockedCount()
    local count = 0
    for _ in pairs(self.unlockedAchievements) do
        count = count + 1
    end
    return count
end

-- Save state
function AdvancedAchievementSystem:getState()
    return {
        unlockedAchievements = self.unlockedAchievements,
        stats = self.stats,
        achievementProgress = self.achievementProgress
    }
end

-- Load state
function AdvancedAchievementSystem:loadState(state)
    if not state then return end
    
    self.unlockedAchievements = state.unlockedAchievements or {}
    self.stats = state.stats or self.stats
    self.achievementProgress = state.achievementProgress or {}
    
    -- Rebuild recent unlocks from saved data (last 5 unlocks)
    self.recentUnlocks = {}
    local recentUnlocks = {}
    
    for fullId, unlockData in pairs(self.unlockedAchievements) do
        if unlockData.unlockedAt then
            table.insert(recentUnlocks, {
                id = fullId,
                time = unlockData.unlockedAt,
                category = unlockData.category,
                achievement = unlockData.achievement
            })
        end
    end
    
    -- Sort by unlock time and keep recent ones
    table.sort(recentUnlocks, function(a, b) return a.time > b.time end)
    
    for i = 1, math.min(5, #recentUnlocks) do
        local recent = recentUnlocks[i]
        local category = self.categories[recent.category]
        local achievement = category and category.achievements[recent.achievement]
        
        if achievement then
            table.insert(self.recentUnlocks, {
                id = recent.id,
                achievement = achievement,
                category = category,
                timestamp = recent.time
            })
        end
    end
end

return AdvancedAchievementSystem