-- Progression System - Comprehensive player advancement and currency management
-- Handles multiple currencies, progression tiers, prestige system, and milestones

local json = require("dkjson")
local ProgressionSystem = {}
ProgressionSystem.__index = ProgressionSystem

-- Create new progression system
function ProgressionSystem.new(eventBus)
    local self = setmetatable({}, ProgressionSystem)
    self.eventBus = eventBus
    
    -- Load configuration from JSON files
    self.config = self:loadConfig()
    
    -- Currency management
    self.currencies = {}
    
    -- Progression state
    self.currentTier = "startup"
    self.prestigeLevel = 0
    self.completedMilestones = {}
    -- Achievement state (compatibility)
    self.achievements = {}
    -- Statistics tracking (more detailed for tests)
    self.statistics = {
        rooms_visited = {}
    }
    
    -- Statistics tracking
    self.totalStats = {
        totalEarnings = 0,
        totalSpent = 0,
        contractsCompleted = 0,
        specialistsHired = 0,
        crisisMissionsCompleted = 0
    }
    
    -- Daily conversion tracking
    self.dailyConversions = {}
    
    -- Initialize currencies from config
    self:initializeCurrencies()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Load configuration from JSON file
function ProgressionSystem:loadConfig()
    local config = {}
    local success, data = pcall(function()
        local json = require("src.utils.json")
        local file = io.open("src/data/progression_config.json", "r")
        if file then
            local content = file:read("*all")
            file:close()
            return json.decode(content)
        end
        return nil
    end)
    
    if success and data then
        config = data
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
                maxStorage = currencyConfig.maxStorage,
                totalEarned = 0,
                totalSpent = 0,
                canSpend = currencyConfig.canSpend ~= false,  -- Default to true
                category = categoryName
            }
        end
    end
    
    -- Ensure essential currencies exist even if not in config
    if not self.currencies.money then
        self.currencies.money = {amount = 1000, totalEarned = 0, totalSpent = 0, canSpend = true, category = "basic"}
    end
    if not self.currencies.reputation then
        self.currencies.reputation = {amount = 0, totalEarned = 0, totalSpent = 0, canSpend = false, category = "basic"}
    end
    if not self.currencies.xp then
        self.currencies.xp = {amount = 0, totalEarned = 0, totalSpent = 0, canSpend = true, category = "basic"}
    end
    if not self.currencies.prestigePoints then
        self.currencies.prestigePoints = {amount = 0, totalEarned = 0, totalSpent = 0, canSpend = true, category = "advanced"}
    end
end

-- Subscribe to events
function ProgressionSystem:subscribeToEvents()
    -- Listen for currency events
    if self.eventBus then
        self.eventBus:subscribe("contract_completed", function(data)
            if data.rewards then
                for currency, amount in pairs(data.rewards) do
                    self:awardCurrency(currency, amount)
                end
            end
        end)
        
        self.eventBus:subscribe("specialist_hired", function(data)
            self.totalStats.specialistsHired = self.totalStats.specialistsHired + 1
        end)
        
        self.eventBus:subscribe("crisis_completed", function(data)
            self.totalStats.crisisMissionsCompleted = self.totalStats.crisisMissionsCompleted + 1
        end)
        -- Track location changes for statistics
        self.eventBus:subscribe("location_changed", function(data)
            if data and data.newBuilding and data.newFloor and data.newRoom then
                local key = data.newBuilding .. "/" .. data.newFloor .. "/" .. data.newRoom
                self.statistics.rooms_visited[key] = (self.statistics.rooms_visited[key] or 0) + 1
            end
        end)
    end
end

-- Get currency amount
function ProgressionSystem:getCurrency(currencyId)
    if self.currencies[currencyId] then
        return self.currencies[currencyId].amount
    end
    return 0
end

-- Award currency
function ProgressionSystem:awardCurrency(currencyId, amount)
    if not self.currencies[currencyId] then
        return false
    end
    
    local currency = self.currencies[currencyId]
    local actualAmount = amount
    
    -- Apply storage limits
    if currency.maxStorage then
        local newTotal = currency.amount + amount
        if newTotal > currency.maxStorage then
            actualAmount = currency.maxStorage - currency.amount
        end
    end
    
    if actualAmount > 0 then
        currency.amount = currency.amount + actualAmount
        currency.totalEarned = currency.totalEarned + actualAmount
        
        -- Update total stats
        if currencyId == "money" then
            self.totalStats.totalEarnings = self.totalStats.totalEarnings + actualAmount
        end
        
        -- Emit event
        if self.eventBus then
            self.eventBus:publish("currency_awarded", {
                currency = currencyId,
                amount = actualAmount,
                newTotal = currency.amount
            })
        end
        
        return true
    end
    
    return false
end

-- Spend currency
function ProgressionSystem:spendCurrency(currencyId, amount)
    if not self.currencies[currencyId] or not self.currencies[currencyId].canSpend then
        return false
    end
    
    local currency = self.currencies[currencyId]
    if currency.amount >= amount then
        currency.amount = currency.amount - amount
        currency.totalSpent = currency.totalSpent + amount
        
        -- Update total stats
        if currencyId == "money" then
            self.totalStats.totalSpent = self.totalStats.totalSpent + amount
        end
        
        -- Emit event
        if self.eventBus then
            self.eventBus:publish("currency_spent", {
                currency = currencyId,
                amount = amount,
                newTotal = currency.amount
            })
        end
        
        return true
    end
    
    return false
end

-- Check if can afford multiple currencies
function ProgressionSystem:canAfford(costs)
    for currencyId, amount in pairs(costs) do
        if self:getCurrency(currencyId) < amount then
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
        if not self:spendCurrency(currencyId, amount) then
            -- This shouldn't happen if canAfford worked correctly
            return false
        end
    end
    
    return true
end

-- Check milestones
function ProgressionSystem:checkMilestones()
    for milestoneId, milestone in pairs(self.config.milestones or {}) do
        if not self.completedMilestones[milestoneId] then
            local completed = true
            
            -- Check milestone conditions
            for condition, value in pairs(milestone.conditions or {}) do
                if condition == "totalEarnings" then
                    if self.totalStats.totalEarnings < value then
                        completed = false
                        break
                    end
                elseif condition == "contractsCompleted" then
                    if self.totalStats.contractsCompleted < value then
                        completed = false
                        break
                    end
                -- Add more condition types as needed
                end
            end
            
            if completed then
                self.completedMilestones[milestoneId] = true
                
                -- Award rewards
                if milestone.rewards then
                    for currency, amount in pairs(milestone.rewards) do
                        self:awardCurrency(currency, amount)
                    end
                end
                
                -- Emit event
                if self.eventBus then
                    self.eventBus:publish("milestone_completed", {
                        milestoneId = milestoneId,
                        milestone = milestone
                    })
                end
            end
        end
    end
end

-- Check tier progression
function ProgressionSystem:checkTierProgression()
    local tiers = self.config.progressionTiers or {}
    local currentTierData = tiers[self.currentTier]
    
    if currentTierData and currentTierData.nextTier then
        local requirements = currentTierData.requirements or {}
        local canAdvance = true
        
        -- Check all requirements
        for requirement, value in pairs(requirements) do
            if requirement == "money" then
                if self:getCurrency("money") < value then
                    canAdvance = false
                    break
                end
            elseif requirement == "reputation" then
                if self:getCurrency("reputation") < value then
                    canAdvance = false
                    break
                end
            elseif requirement == "contractsCompleted" then
                if self.totalStats.contractsCompleted < value then
                    canAdvance = false
                    break
                end
            end
        end
        
        if canAdvance then
            local oldTier = self.currentTier
            self.currentTier = currentTierData.nextTier
            
            -- Award tier progression rewards
            if currentTierData.rewards then
                for currency, amount in pairs(currentTierData.rewards) do
                    self:awardCurrency(currency, amount)
                end
            end
            
            -- Emit tier change event
            if self.eventBus then
                self.eventBus:publish("tier_promoted", {
                    oldTier = oldTier,
                    newTier = self.currentTier
                })
            end
        end
    end
end

-- Compatibility methods expected by tests
function ProgressionSystem:getCurrentTier()
    return self.currentTier
end

function ProgressionSystem:unlockAchievement(id)
    if not id then return false end
    self.achievements[id] = true
    if self.eventBus then
        self.eventBus:publish("achievement_unlocked", { id = id })
    end
    return true
end

function ProgressionSystem:getAchievements()
    return self.achievements
end

function ProgressionSystem:getStatistics()
    -- Merge basic totalStats and extended statistics for backward compatibility
    local merged = {
        rooms_visited = self.statistics.rooms_visited or {},
        totalEarnings = self.totalStats.totalEarnings or 0,
        contractsCompleted = self.totalStats.contractsCompleted or 0
    }
    return merged
end

-- Backwards-compatible state setter
function ProgressionSystem:setState(state)
    -- Accept the same structure as loadState/getState
    if not state then return end
    self:loadState(state)
    -- Restore achievements and statistics if present
    if state.achievements then
        self.achievements = state.achievements
    end
    if state.statistics then
        self.statistics = state.statistics
    end
end

-- Get current tier level (for display)
function ProgressionSystem:getCurrentTierLevel()
    local tiers = self.config.progressionTiers or {}
    local tierData = tiers[self.currentTier]
    return tierData and tierData.level or 1
end

-- Check if can prestige
function ProgressionSystem:canPrestige()
    local prestigeConfig = self.config.prestigeSystem or {}
    if not prestigeConfig.enabled then
        return false
    end
    
    local requirements = prestigeConfig.requirements or {}
    
    -- Check tier requirement
    if requirements.minTier and self.currentTier ~= requirements.minTier then
        return false
    end
    
    -- Check currency requirements
    for currency, amount in pairs(requirements.currencies or {}) do
        if self:getCurrency(currency) < amount then
            return false
        end
    end
    
    return true
end

-- Perform prestige
function ProgressionSystem:performPrestige()
    if not self:canPrestige() then
        return false
    end
    
    local prestigeConfig = self.config.prestigeSystem or {}
    
    -- Award prestige points
    local prestigePointsGained = prestigeConfig.basePrestigePoints or 1
    self:awardCurrency("prestigePoints", prestigePointsGained)
    
    -- Reset currencies (except prestige points)
    for currencyId, currency in pairs(self.currencies) do
        if currencyId ~= "prestigePoints" and currency.category ~= "permanent" then
            currency.amount = 0
            currency.totalEarned = 0
            currency.totalSpent = 0
        end
    end
    
    -- Reset progression state
    self.currentTier = "startup"
    self.prestigeLevel = self.prestigeLevel + 1
    self.completedMilestones = {}
    
    -- Reset stats
    self.totalStats = {
        totalEarnings = 0,
        totalSpent = 0,
        contractsCompleted = 0,
        specialistsHired = 0,
        crisisMissionsCompleted = 0
    }
    
    -- Re-initialize starting currencies
    self:initializeCurrencies()
    
    -- Emit event
    if self.eventBus then
        self.eventBus:publish("prestige_performed", {
            prestigeLevel = self.prestigeLevel,
            prestigePointsGained = prestigePointsGained
        })
    end
    
    return true
end

-- Update method (called regularly)
function ProgressionSystem:update(dt)
    -- Check for milestone completions
    self:checkMilestones()
    
    -- Check for tier progression
    self:checkTierProgression()
end

-- Get save state
function ProgressionSystem:getState()
    local state = {
        currencies = {},
        currentTier = self.currentTier,
        prestigeLevel = self.prestigeLevel,
        completedMilestones = self.completedMilestones,
        totalStats = self.totalStats,
        dailyConversions = self.dailyConversions
    }

    -- Include achievements and statistics for compatibility
    state.achievements = self.achievements or {}
    state.statistics = self.statistics or { rooms_visited = {} }
    
    -- Save currency data
    for currencyId, currency in pairs(self.currencies) do
        state.currencies[currencyId] = {
            amount = currency.amount,
            totalEarned = currency.totalEarned,
            totalSpent = currency.totalSpent
        }
    end
    
    return state
end

-- Load save state
function ProgressionSystem:loadState(state)
    if not state then return end
    
    -- Load currencies
    if state.currencies then
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