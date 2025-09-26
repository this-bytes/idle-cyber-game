-- Progression System - Comprehensive player advancement and currency management
-- Handles multiple currencies, progression tiers, prestige system, and milestones

local json = require("dkjson")
local ProgressionSystem = {}
ProgressionSystem.__index = ProgressionSystem

-- Create new progression system
function ProgressionSystem.new(eventBus)
    local self = setmetatable({}, ProgressionSystem)
    self.eventBus = eventBus
    
    -- Load progression configuration from JSON
    self.config = self:loadProgressionConfig()
    
    -- Player progression state
    self.currencies = {}
    self.currentTier = "startup"
    self.prestigeLevel = 0
    self.prestigePoints = 0
    self.completedMilestones = {}
    self.dailyConversions = {}
    
    -- Initialize currencies from config
    self:initializeCurrencies()
    
    -- Progression tracking
    self.totalStats = {
        totalEarnings = 0,
        totalSpent = 0,
        contractsCompleted = 0,
        specialistsHired = 0,
        crisisMissionsCompleted = 0
    }
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Load progression configuration from JSON file
function ProgressionSystem:loadProgressionConfig()
    local dataPath = "src/data/progression.json"
    local config = nil
    
    -- Try to load from file system
    if love and love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo(dataPath) then
            local content = love.filesystem.read(dataPath)
            local success, decoded = pcall(json.decode, content)
            if success and decoded then
                config = decoded
            end
        end
    else
        -- Fallback for non-LOVE environment
        local file = io.open(dataPath, "r")
        if file then
            local content = file:read("*all")
            file:close()
            local success, decoded = pcall(json.decode, content)
            if success and decoded then
                config = decoded
            end
        end
    end
    
    -- Return config or empty structure if loading failed
    return config or {
        currencies = {},
        progressionTiers = {},
        prestigeSystem = {enabled = false},
        milestones = {},
        currencyConversions = {}
    }
end

-- Initialize currencies from configuration
function ProgressionSystem:initializeCurrencies()
    for categoryName, category in pairs(self.config.currencies or {}) do
        for currencyId, currencyConfig in pairs(category) do
            self.currencies[currencyId] = {
                amount = currencyConfig.startingAmount or 0,
                totalEarned = 0,
                totalSpent = 0,
                config = currencyConfig
            }
        end
    end
end

-- Subscribe to relevant events
function ProgressionSystem:subscribeToEvents()
    -- Resource changes
    self.eventBus:subscribe("resource_earned", function(data)
        self:onResourceEarned(data.resource, data.amount)
    end)
    
    self.eventBus:subscribe("resource_spent", function(data)
        self:onResourceSpent(data.resource, data.amount)
    end)
    
    -- Contract completion
    self.eventBus:subscribe("contract_completed", function(data)
        self.totalStats.contractsCompleted = self.totalStats.contractsCompleted + 1
        self:checkMilestones()
        self:checkTierProgression()
    end)
    
    -- Specialist hired
    self.eventBus:subscribe("specialist_hired", function(data)
        self.totalStats.specialistsHired = self.totalStats.specialistsHired + 1
        self:checkMilestones()
    end)
    
    -- Crisis mission completed
    self.eventBus:subscribe("crisis_mission_completed", function(data)
        self.totalStats.crisisMissionsCompleted = self.totalStats.crisisMissionsCompleted + 1
        self:awardCurrency("missionTokens", data.tokens or 1)
        self:checkMilestones()
    end)
    
    -- Check progression tier access
    self.eventBus:subscribe("check_progression_tier", function(data)
        local hasAccess = false
        local requiredTier = self.config.progressionTiers[data.requiredTier]
        local currentTier = self.config.progressionTiers[self.currentTier]
        
        if requiredTier and currentTier then
            hasAccess = currentTier.level >= requiredTier.level
        end
        
        if data.callback then
            data.callback(hasAccess)
        end
    end)
    
    -- Get currency amount for achievements
    self.eventBus:subscribe("get_currency_amount", function(data)
        local amount = self:getCurrency(data.currency)
        if data.callback then
            data.callback(amount)
        end
    end)
    
    -- Award currency from achievements
    self.eventBus:subscribe("award_currency", function(data)
        self:awardCurrency(data.currency, data.amount)
    end)
end

-- Award currency to player
function ProgressionSystem:awardCurrency(currencyId, amount)
    if not self.currencies[currencyId] then
        print("Warning: Unknown currency " .. currencyId)
        return false
    end
    
    local currency = self.currencies[currencyId]
    local config = currency.config
    
    -- Check storage limits
    if config.maxStorage and config.maxStorage > 0 then
        local maxAmount = config.maxStorage - currency.amount
        amount = math.min(amount, maxAmount)
    end
    
    if amount > 0 then
        currency.amount = currency.amount + amount
        currency.totalEarned = currency.totalEarned + amount
        
        -- Emit event for UI updates
        self.eventBus:publish("currency_awarded", {
            currency = currencyId,
            amount = amount,
            total = currency.amount
        })
        
        return true
    end
    
    return false
end

-- Spend currency
function ProgressionSystem:spendCurrency(currencyId, amount)
    if not self.currencies[currencyId] then
        return false
    end
    
    local currency = self.currencies[currencyId]
    
    if currency.amount >= amount and currency.config.canSpend then
        currency.amount = currency.amount - amount
        currency.totalSpent = currency.totalSpent + amount
        
        -- Emit event for UI updates
        self.eventBus:publish("currency_spent", {
            currency = currencyId,
            amount = amount,
            remaining = currency.amount
        })
        
        return true
    end
    
    return false
end

-- Check if player can afford a cost
function ProgressionSystem:canAfford(costs)
    for currencyId, amount in pairs(costs) do
        if not self.currencies[currencyId] or self.currencies[currencyId].amount < amount then
            return false
        end
    end
    return true
end

-- Spend multiple currencies
function ProgressionSystem:spendMultiple(costs)
    if not self:canAfford(costs) then
        return false
    end
    
    for currencyId, amount in pairs(costs) do
        self:spendCurrency(currencyId, amount)
    end
    
    return true
end

-- Get currency amount
function ProgressionSystem:getCurrency(currencyId)
    return self.currencies[currencyId] and self.currencies[currencyId].amount or 0
end

-- Get all currencies for display
function ProgressionSystem:getAllCurrencies()
    local result = {}
    
    -- Sort currencies by display order
    local sortedCurrencies = {}
    for currencyId, data in pairs(self.currencies) do
        table.insert(sortedCurrencies, {id = currencyId, data = data})
    end
    
    table.sort(sortedCurrencies, function(a, b)
        local orderA = a.data.config.displayOrder or 999
        local orderB = b.data.config.displayOrder or 999
        return orderA < orderB
    end)
    
    for _, entry in ipairs(sortedCurrencies) do
        result[entry.id] = entry.data
    end
    
    return result
end

-- Handle resource earned events
function ProgressionSystem:onResourceEarned(resource, amount)
    if resource == "money" then
        self.totalStats.totalEarnings = self.totalStats.totalEarnings + amount
    end
    
    self:awardCurrency(resource, amount)
end

-- Handle resource spent events
function ProgressionSystem:onResourceSpent(resource, amount)
    if resource == "money" then
        self.totalStats.totalSpent = self.totalStats.totalSpent + amount
    end
end

-- Check milestone completion
function ProgressionSystem:checkMilestones()
    for milestoneId, milestone in pairs(self.config.milestones or {}) do
        if not self.completedMilestones[milestoneId] then
            if self:isMilestoneComplete(milestone) then
                self:completeMilestone(milestoneId, milestone)
            end
        end
    end
end

-- Check if milestone requirements are met
function ProgressionSystem:isMilestoneComplete(milestone)
    for requirement, value in pairs(milestone.requirements) do
        local currentValue = 0
        
        if requirement == "totalEarnings" then
            currentValue = self.totalStats.totalEarnings
        elseif requirement == "contractsCompleted" then
            currentValue = self.totalStats.contractsCompleted
        elseif requirement == "specialistsHired" then
            currentValue = self.totalStats.specialistsHired
        elseif self.currencies[requirement] then
            currentValue = self.currencies[requirement].amount
        end
        
        if currentValue < value then
            return false
        end
    end
    
    return true
end

-- Complete a milestone
function ProgressionSystem:completeMilestone(milestoneId, milestone)
    self.completedMilestones[milestoneId] = true
    
    -- Award rewards
    if milestone.rewards then
        for rewardType, amount in pairs(milestone.rewards) do
            self:awardCurrency(rewardType, amount)
        end
    end
    
    -- Emit event for notifications
    self.eventBus:publish("milestone_completed", {
        id = milestoneId,
        milestone = milestone
    })
    
    print("🏆 Milestone completed: " .. milestone.name)
end

-- Check tier progression
function ProgressionSystem:checkTierProgression()
    for tierId, tier in pairs(self.config.progressionTiers or {}) do
        if tier.level > self:getCurrentTierLevel() and self:canAdvanceToTier(tier) then
            self:advanceToTier(tierId, tier)
            break
        end
    end
end

-- Get current tier level
function ProgressionSystem:getCurrentTierLevel()
    local currentTierData = self.config.progressionTiers[self.currentTier]
    return currentTierData and currentTierData.level or 1
end

-- Check if player can advance to tier
function ProgressionSystem:canAdvanceToTier(tier)
    for requirement, value in pairs(tier.requirements) do
        local currentValue = 0
        
        if requirement == "contracts" then
            currentValue = self.totalStats.contractsCompleted
        elseif requirement == "specialists" then
            currentValue = self.totalStats.specialistsHired
        elseif self.currencies[requirement] then
            currentValue = self.currencies[requirement].amount
        end
        
        if currentValue < value then
            return false
        end
    end
    
    return true
end

-- Advance to new tier
function ProgressionSystem:advanceToTier(tierId, tier)
    self.currentTier = tierId
    
    -- Emit tier advancement event
    self.eventBus:publish("tier_advanced", {
        newTier = tierId,
        tierData = tier
    })
    
    print("🚀 Advanced to " .. tier.name .. "!")
end

-- Convert currencies
function ProgressionSystem:convertCurrency(conversionId)
    local conversion = self.config.currencyConversions[conversionId]
    if not conversion or not conversion.enabled then
        return false
    end
    
    -- Check daily limits
    local today = os.date("%Y-%m-%d")
    if not self.dailyConversions[today] then
        self.dailyConversions[today] = {}
    end
    
    local dailyUsed = self.dailyConversions[today][conversionId] or 0
    if conversion.maxPerDay and dailyUsed >= conversion.maxPerDay then
        return false
    end
    
    -- Perform conversion (simplified - would need proper parsing for complex conversions)
    -- This is a basic implementation for XP to Skill Points
    if conversionId == "xpToSkillPoints" then
        if self:spendCurrency("xp", conversion.ratio) then
            self:awardCurrency("skillPoints", 1)
            self.dailyConversions[today][conversionId] = dailyUsed + 1
            return true
        end
    end
    
    return false
end

-- Perform prestige (company rebirth)
function ProgressionSystem:performPrestige()
    local prestigeConfig = self.config.prestigeSystem
    if not prestigeConfig.enabled then
        return false
    end
    
    -- Check requirements
    if not self:canPrestige() then
        return false
    end
    
    -- Calculate prestige points earned
    local earnedPoints = self:calculatePrestigePoints()
    
    -- Reset specified resources
    for _, resource in ipairs(prestigeConfig.resetResources) do
        if self.currencies[resource] then
            local config = self.currencies[resource].config
            self.currencies[resource].amount = config.startingAmount or 0
        end
    end
    
    -- Award prestige points
    self.prestigeLevel = self.prestigeLevel + 1
    self.prestigePoints = self.prestigePoints + earnedPoints
    self:awardCurrency("prestigePoints", earnedPoints)
    
    -- Reset progression tier
    self.currentTier = "startup"
    
    -- Reset stats
    self.totalStats.contractsCompleted = 0
    self.totalStats.specialistsHired = 0
    
    -- Emit prestige event
    self.eventBus:publish("prestige_performed", {
        level = self.prestigeLevel,
        pointsEarned = earnedPoints,
        totalPoints = self.prestigePoints
    })
    
    print("🌟 Prestige complete! Level: " .. self.prestigeLevel .. ", Points earned: " .. earnedPoints)
    return true
end

-- Check if prestige is available
function ProgressionSystem:canPrestige()
    local prestigeConfig = self.config.prestigeSystem
    if not prestigeConfig.enabled then
        return false
    end
    
    local requirements = prestigeConfig.unlockRequirements
    
    -- Check tier requirement
    if requirements.progressionTier then
        local requiredTier = self.config.progressionTiers[requirements.progressionTier]
        if not requiredTier or self:getCurrentTierLevel() < requiredTier.level then
            return false
        end
    end
    
    -- Check currency requirements
    for currency, amount in pairs(requirements) do
        if currency ~= "progressionTier" and self:getCurrency(currency) < amount then
            return false
        end
    end
    
    return true
end

-- Calculate prestige points to be earned
function ProgressionSystem:calculatePrestigePoints()
    local formula = self.config.prestigeSystem.prestigeFormula
    local base = formula.base or 1
    
    local moneyPoints = math.floor(self:getCurrency("money") / (formula.moneyDivisor or 50000))
    local reputationPoints = math.floor(self:getCurrency("reputation") / (formula.reputationDivisor or 100))
    
    return base + moneyPoints + reputationPoints
end

-- Get prestige bonuses
function ProgressionSystem:getPrestigeBonuses()
    local bonuses = {}
    local prestigeBonuses = self.config.prestigeSystem.prestigeBonuses or {}
    
    for bonusType, bonusConfig in pairs(prestigeBonuses) do
        -- Simplified bonus calculation (would need proper formula parser)
        if bonusType == "moneyGeneration" then
            bonuses[bonusType] = 1 + (self.prestigePoints * 0.1)
        elseif bonusType == "xpGeneration" then
            bonuses[bonusType] = 1 + (self.prestigePoints * 0.05)
        elseif bonusType == "contractCapacity" then
            bonuses[bonusType] = math.floor(self.prestigePoints * 0.5)
        elseif bonusType == "startingMoney" then
            bonuses[bonusType] = 1000 + (self.prestigePoints * 500)
        end
    end
    
    return bonuses
end

-- Get current progression tier info
function ProgressionSystem:getCurrentTier()
    return self.config.progressionTiers[self.currentTier] or {}
end

-- Update system
function ProgressionSystem:update(dt)
    -- Check for milestone and tier progression periodically
    self:checkMilestones()
    self:checkTierProgression()
end

-- Get state for saving
function ProgressionSystem:getState()
    return {
        currencies = self.currencies,
        currentTier = self.currentTier,
        prestigeLevel = self.prestigeLevel,
        prestigePoints = self.prestigePoints,
        completedMilestones = self.completedMilestones,
        totalStats = self.totalStats,
        dailyConversions = self.dailyConversions
    }
end

-- Load state from save
function ProgressionSystem:loadState(state)
    if state.currencies then
        -- Merge saved currencies with config, keeping saved amounts
        for currencyId, savedData in pairs(state.currencies) do
            if self.currencies[currencyId] then
                self.currencies[currencyId].amount = savedData.amount or 0
                self.currencies[currencyId].totalEarned = savedData.totalEarned or 0
                self.currencies[currencyId].totalSpent = savedData.totalSpent or 0
            end
        end
    end
    
    self.currentTier = state.currentTier or "startup"
    self.prestigeLevel = state.prestigeLevel or 0
    self.prestigePoints = state.prestigePoints or 0
    self.completedMilestones = state.completedMilestones or {}
    self.totalStats = state.totalStats or {
        totalEarnings = 0,
        totalSpent = 0,
        contractsCompleted = 0,
        specialistsHired = 0,
        crisisMissionsCompleted = 0
    }
    self.dailyConversions = state.dailyConversions or {}
end

return ProgressionSystem