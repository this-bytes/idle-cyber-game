-- Progression System
-- Manages player progression, tiers, achievements, and currency generation

local ProgressionSystem = {}
ProgressionSystem.__index = ProgressionSystem

local json = require("dkjson")

-- Create new progression system
function ProgressionSystem.new(eventBus, resourceSystem)
    local self = setmetatable({}, ProgressionSystem)
    self.eventBus = eventBus
    self.resourceSystem = resourceSystem
    
    -- Progression state
    self.currentTier = "novice"
    self.achievements = {}
    self.statistics = {
        rooms_visited = {},
        buildings_unlocked = {},
        contracts_completed = 0,
        total_focus_time = 0,
        max_focus_streak = 0,
        current_focus_streak = 0
    }
    
    -- Currency data and progression config
    self.currencies = {}
    self.tiers = {}
    self.achievementDefinitions = {}
    self.generation = {}
    
    -- Load progression data
    self:loadProgressionData()
    
    -- Initialize currencies in resource system
    self:initializeCurrencies()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Load progression data from JSON
function ProgressionSystem:loadProgressionData()
    local dataPath = "src/data/currencies.json"
    local progressionData = nil
    
    -- Try to load from file system
    if love and love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo(dataPath) then
            local content = love.filesystem.read(dataPath)
            local ok, data = pcall(function() return json.decode(content) end)
            if ok and type(data) == "table" then
                progressionData = data
            end
        end
    else
        -- Fallback for non-LOVE environments
        local f = io.open(dataPath, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local ok, data = pcall(function() return json.decode(content) end)
            if ok and type(data) == "table" then
                progressionData = data
            end
        end
    end
    
    if progressionData then
        self.currencies = progressionData.currencies or {}
        self.tiers = progressionData.progression.tiers or {}
        self.achievementDefinitions = progressionData.progression.achievements or {}
        self.generation = progressionData.generation or {}
        print("💰 Loaded progression data: " .. self:getCurrencyCount() .. " currencies, " .. self:getTierCount() .. " tiers")
    else
        print("⚠️  Failed to load progression data, using defaults")
        self:createDefaultProgression()
    end
end

-- Initialize currencies in the resource system
function ProgressionSystem:initializeCurrencies()
    for currencyId, currencyData in pairs(self.currencies) do
        local startingAmount = currencyData.startingAmount or 0
        
        -- Set initial currency amount
        self.resourceSystem:setResource(currencyId, startingAmount)
        
        print("💰 Initialized " .. currencyData.name .. ": " .. startingAmount)
    end
end

-- Subscribe to game events for progression tracking
function ProgressionSystem:subscribeToEvents()
    -- Location events
    self.eventBus:subscribe("location_changed", function(data)
        self:onLocationChanged(data)
    end)
    
    self.eventBus:subscribe("building_unlocked", function(data)
        self:onBuildingUnlocked(data)
    end)
    
    -- Contract events
    self.eventBus:subscribe("contract_completed", function(data)
        self:onContractCompleted(data)
    end)
    
    -- Player state events
    self.eventBus:subscribe("focus_changed", function(data)
        self:onFocusChanged(data)
    end)
    
    -- Achievement events
    self.eventBus:subscribe("achievement_unlocked", function(data)
        self:onAchievementUnlocked(data)
    end)
end

-- Handle location change events
function ProgressionSystem:onLocationChanged(data)
    local locationKey = data.newBuilding .. "/" .. data.newFloor .. "/" .. data.newRoom
    
    -- Track room visits
    if not self.statistics.rooms_visited[locationKey] then
        self.statistics.rooms_visited[locationKey] = 0
        -- Check for first move achievement
        if self:getTotalRoomsVisited() == 1 then
            self:unlockAchievement("first_move")
        end
    end
    
    self.statistics.rooms_visited[locationKey] = (self.statistics.rooms_visited[locationKey] or 0) + 1
    
    -- Check for location master achievement
    self:checkLocationMasterAchievement(data.newBuilding)
    
    -- Apply location bonuses to currency generation
    -- This would be called with actual location bonuses from the location system
    -- For now, just store them for reference
end

-- Handle building unlock events
function ProgressionSystem:onBuildingUnlocked(data)
    self.statistics.buildings_unlocked[data.building] = true
    
    -- Award building owner achievement for first building unlock
    if self:getTotalBuildingsUnlocked() == 1 then
        self:unlockAchievement("building_owner")
    end
    
    -- Check for tier progression
    self:checkTierProgression()
end

-- Handle contract completion events
function ProgressionSystem:onContractCompleted(data)
    self.statistics.contracts_completed = self.statistics.contracts_completed + 1
    
    -- Award experience and reputation
    local baseExp = data.experience or 50
    local baseRep = data.reputation or 5
    
    -- Apply location bonuses
    local locationBonuses = self:getCurrentLocationBonuses()
    local expBonus = locationBonuses.xp_multiplier or 1.0
    local repBonus = locationBonuses.reputation or 1.0
    
    local finalExp = math.floor(baseExp * expBonus)
    local finalRep = math.floor(baseRep * repBonus)
    
    self.resourceSystem:addResource("experience", finalExp)
    self.resourceSystem:addResource("reputation", finalRep)
    
    print("🎯 Contract completed! +" .. finalExp .. " XP, +" .. finalRep .. " reputation")
    
    -- Check for tier progression
    self:checkTierProgression()
end

-- Handle achievement unlock events (for chaining achievements)
function ProgressionSystem:onAchievementUnlocked(data)
    -- This method can be used for achievement dependencies or effects
    print("🏆 Achievement effect processed: " .. data.id)
end

-- Handle focus change events
function ProgressionSystem:onFocusChanged(data)
    local focus = data.focus or 0
    
    if focus >= 200 then -- Maximum focus
        self.statistics.current_focus_streak = self.statistics.current_focus_streak + data.deltaTime
        self.statistics.total_focus_time = self.statistics.total_focus_time + data.deltaTime
        
        -- Check for efficiency expert achievement (5 minutes = 300 seconds)
        if self.statistics.current_focus_streak >= 300 and not self.achievements.efficiency_expert then
            self:unlockAchievement("efficiency_expert")
        end
        
        -- Track maximum streak
        self.statistics.max_focus_streak = math.max(self.statistics.max_focus_streak, self.statistics.current_focus_streak)
    else
        self.statistics.current_focus_streak = 0
    end
end

-- Update currency generation and progression
function ProgressionSystem:update(dt)
    -- Generate passive income
    self:updatePassiveIncome(dt)
    
    -- Update energy regeneration
    self:updateEnergyRegeneration(dt)
    
    -- Update focus decay
    self:updateFocusDecay(dt)
    
    -- Check for tier progression periodically
    if love.timer and love.timer.getTime() % 5 < dt then
        self:checkTierProgression()
    end
end

-- Update passive income generation
function ProgressionSystem:updatePassiveIncome(dt)
    local generation = self.generation.passive_income
    if not generation then return end
    
    local baseRate = generation.base_rate or 10
    local locationMultiplier = self:getLocationIncomeMultiplier()
    local tierMultiplier = self:getTierIncomeMultiplier()
    
    local totalRate = baseRate * locationMultiplier * tierMultiplier
    local income = totalRate * dt
    
    self.resourceSystem:addResource("money", income)
end

-- Update energy regeneration
function ProgressionSystem:updateEnergyRegeneration(dt)
    local energyCurrency = self.currencies.energy
    if not energyCurrency or not energyCurrency.regeneration then return end
    
    local baseRate = energyCurrency.regeneration.baseRate or 10
    local locationMultiplier = self:getLocationEnergyMultiplier()
    
    local totalRate = baseRate * locationMultiplier
    local regen = totalRate * dt
    
    local currentEnergy = self.resourceSystem:getResource("energy")
    local maxEnergy = energyCurrency.maxAmount or 100
    local newEnergy = math.min(maxEnergy, currentEnergy + regen)
    
    self.resourceSystem:setResource("energy", newEnergy)
end

-- Update focus decay
function ProgressionSystem:updateFocusDecay(dt)
    local focusCurrency = self.currencies.focus
    if not focusCurrency or not focusCurrency.decay then return end
    
    local baseRate = focusCurrency.decay.baseRate or 5
    local locationReduction = self:getLocationFocusDecayReduction()
    
    local totalRate = baseRate * (1 - locationReduction)
    local decay = totalRate * dt
    
    local currentFocus = self.resourceSystem:getResource("focus")
    local newFocus = math.max(0, currentFocus - decay)
    
    self.resourceSystem:setResource("focus", newFocus)
    
    -- Emit focus change event for streak tracking
    self.eventBus:publish("focus_changed", {
        focus = newFocus,
        deltaTime = dt
    })
end

-- Check if player can progress to next tier
function ProgressionSystem:checkTierProgression()
    local nextTierId = self:getNextTierId()
    if not nextTierId then return end
    
    local nextTier = self.tiers[nextTierId]
    if not nextTier or not nextTier.requirements then return end
    
    -- Check all requirements
    for resource, required in pairs(nextTier.requirements) do
        local current = 0
        
        if resource == "completed_contracts" then
            current = self.statistics.contracts_completed
        else
            current = self.resourceSystem:getResource(resource) or 0
        end
        
        if current < required then
            return -- Requirements not met
        end
    end
    
    -- All requirements met - promote to next tier!
    self:promoteToTier(nextTierId)
end

-- Promote player to next tier
function ProgressionSystem:promoteToTier(tierId)
    local tier = self.tiers[tierId]
    if not tier then return end
    
    local oldTier = self.currentTier
    self.currentTier = tierId
    
    -- Award tier rewards
    if tier.rewards then
        for resource, amount in pairs(tier.rewards) do
            self.resourceSystem:addResource(resource, amount)
        end
    end
    
    -- Emit tier change event
    self.eventBus:publish("tier_promoted", {
        oldTier = oldTier,
        newTier = tierId,
        tierData = tier
    })
    
    print("🎉 Promoted to " .. tier.name .. "!")
end

-- Unlock achievement
function ProgressionSystem:unlockAchievement(achievementId)
    if self.achievements[achievementId] then
        return -- Already unlocked
    end
    
    local achievement = self.achievementDefinitions[achievementId]
    if not achievement then return end
    
    self.achievements[achievementId] = {
        unlocked_at = love.timer and love.timer.getTime() or os.time(),
        id = achievementId
    }
    
    -- Award achievement rewards
    if achievement.rewards then
        for resource, amount in pairs(achievement.rewards) do
            self.resourceSystem:addResource(resource, amount)
        end
    end
    
    -- Emit achievement event
    self.eventBus:publish("achievement_unlocked", {
        id = achievementId,
        achievement = achievement
    })
    
    print("🏆 Achievement unlocked: " .. achievement.name)
end

-- Get current location bonuses from location system
function ProgressionSystem:getCurrentLocationBonuses()
    -- This would be provided by the location system
    -- For now, return empty table
    return {}
end

-- Helper methods for multipliers
function ProgressionSystem:getLocationIncomeMultiplier()
    local generation = self.generation.passive_income
    if not generation or not generation.location_multipliers then return 1.0 end
    
    -- This would use current location from location system
    return 1.0
end

function ProgressionSystem:getTierIncomeMultiplier()
    local generation = self.generation.passive_income
    if not generation or not generation.tier_multipliers then return 1.0 end
    
    return generation.tier_multipliers[self.currentTier] or 1.0
end

function ProgressionSystem:getLocationEnergyMultiplier()
    local energyCurrency = self.currencies.energy
    if not energyCurrency or not energyCurrency.regeneration or not energyCurrency.regeneration.locationMultipliers then 
        return 1.0 
    end
    
    -- This would use current room from location system
    return 1.0
end

function ProgressionSystem:getLocationFocusDecayReduction()
    local focusCurrency = self.currencies.focus
    if not focusCurrency or not focusCurrency.decay or not focusCurrency.decay.locationReduction then 
        return 0.0 
    end
    
    -- This would use current room from location system
    return 0.0
end

-- Achievement checking helpers
function ProgressionSystem:checkLocationMasterAchievement(buildingId)
    -- This would check if player has visited all rooms in the building
    -- Implementation would require location system integration
end

-- Utility methods
function ProgressionSystem:getCurrencyCount()
    local count = 0
    for _ in pairs(self.currencies) do count = count + 1 end
    return count
end

function ProgressionSystem:getTierCount()
    local count = 0
    for _ in pairs(self.tiers) do count = count + 1 end
    return count
end

function ProgressionSystem:getTotalRoomsVisited()
    local count = 0
    for _ in pairs(self.statistics.rooms_visited) do count = count + 1 end
    return count
end

function ProgressionSystem:getTotalBuildingsUnlocked()
    local count = 0
    for _ in pairs(self.statistics.buildings_unlocked) do count = count + 1 end
    return count
end

function ProgressionSystem:getNextTierId()
    local tierOrder = {"novice", "professional", "expert", "authority"}
    for i, tierId in ipairs(tierOrder) do
        if tierId == self.currentTier and i < #tierOrder then
            return tierOrder[i + 1]
        end
    end
    return nil
end

-- Get current tier information
function ProgressionSystem:getCurrentTier()
    return self.tiers[self.currentTier]
end

-- Get achievement progress
function ProgressionSystem:getAchievements()
    return self.achievements
end

-- Get statistics
function ProgressionSystem:getStatistics()
    return self.statistics
end

-- Get save state
function ProgressionSystem:getState()
    return {
        currentTier = self.currentTier,
        achievements = self.achievements,
        statistics = self.statistics
    }
end

-- Load state
function ProgressionSystem:setState(state)
    if state.currentTier then self.currentTier = state.currentTier end
    if state.achievements then self.achievements = state.achievements end
    if state.statistics then self.statistics = state.statistics end
end

-- Create default progression if JSON fails to load
function ProgressionSystem:createDefaultProgression()
    self.currencies = {
        money = { name = "Money", startingAmount = 1000 },
        reputation = { name = "Reputation", startingAmount = 10 },
        experience = { name = "Experience", startingAmount = 0 }
    }
    self.tiers = {
        novice = { name = "Novice Consultant", requirements = {} }
    }
end

return ProgressionSystem