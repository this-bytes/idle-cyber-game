-- Resource Management System - Cyber Empire Command
-- Handles resources for cybersecurity consultancy business
-- Now config-driven following bootstrap architecture

local ResourceSystem = {}
ResourceSystem.__index = ResourceSystem

-- Import configuration
local GameConfig = require("src.config.game_config")

-- Create new resource system
function ResourceSystem.new(eventBus)
    local self = setmetatable({}, ResourceSystem)
    self.eventBus = eventBus
    
    -- Initialize resources from config
    self.resources = {}
    for resourceName, resourceConfig in pairs(GameConfig.RESOURCES) do
        self.resources[resourceName] = resourceConfig.startingAmount
    end
    
    -- Legacy resources (TODO: Remove after full refactor)
    self.resources.dataBits = 10
    self.resources.processingPower = 0
    self.resources.securityRating = 100
    
    -- Generation rates (per second) - mainly from active contracts
    self.generation = {}
    for resourceName in pairs(self.resources) do
        self.generation[resourceName] = 0
    end
    
    -- Resource multipliers from facilities and upgrades
    self.multipliers = {}
    for resourceName in pairs(self.resources) do
        self.multipliers[resourceName] = 1.0
    end
    
    -- Click mechanics for active gameplay
    self.clickPower = 1
    self.clickCombo = 1.0
    self.lastClickTime = 0
    self.comboDecayTime = 2.0
    
    -- Storage limitations (expandable through upgrades)
    self.storage = {}
    for resourceName in pairs(self.resources) do
        self.storage[resourceName] = math.huge -- No limits initially
    end
        dataBits = math.huge,           -- No limit initially
        processingPower = math.huge,
        securityRating = 1000,          -- Security has a cap
        reputationPoints = 100,         -- Limited reputation storage initially
        researchData = 50,              -- Limited research storage
        neuralNetworkFragments = 10,    -- Very limited storage
        quantumEntanglementTokens = 1   -- Extremely limited
    }
    
    self.lastUpdateTime = (love and love.timer and love.timer.getTime()) or os.clock()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to relevant events
function ResourceSystem:subscribeToEvents()
    -- Handle upgrade effects
    self.eventBus:subscribe("apply_upgrade_effect", function(data)
        self:applyUpgradeEffect(data.upgradeId, data.effectType, data.value)
    end)
    
    -- Handle resource spend requests
    self.eventBus:subscribe("check_can_afford", function(data)
        local canAfford = self:canAfford(data.cost)
        if data.callback then
            data.callback(canAfford)
        end
    end)
    
    self.eventBus:subscribe("spend_resources", function(data)
        self:spendResources(data.cost)
    end)
    
    -- Handle zone bonuses
    self.eventBus:subscribe("zone_changed", function(data)
        self:applyZoneBonuses(data.bonuses)
    end)
    
    -- Handle achievement rewards
    self.eventBus:subscribe("add_resource", function(data)
        self:addResource(data.resource, data.amount)
    end)
end

-- Apply upgrade effect
function ResourceSystem:applyUpgradeEffect(upgradeId, effectType, value)
    if effectType == "clickPower" then
        self.clickPower = self.clickPower + value
    elseif effectType == "dataBitsGeneration" then
        self:addGeneration("dataBits", value)
    elseif effectType == "processingPowerGeneration" then
        self:addGeneration("processingPower", value)
    elseif effectType == "dataBitsMultiplier" then
        local currentMultiplier = self:getMultiplier("dataBits")
        self:setMultiplier("dataBits", currentMultiplier + value)
    elseif effectType == "securityRating" then
        self:addResource("securityRating", value)
    end
end

-- Apply zone bonuses to multipliers
function ResourceSystem:applyZoneBonuses(bonuses)
    for resource, multiplier in pairs(bonuses) do
        if resource:find("Multiplier") then
            local resourceName = resource:gsub("Multiplier", "")
            if self.multipliers[resourceName] then
                -- Zone bonuses are multiplicative with base multiplier
                local baseMultiplier = self.multipliers[resourceName]
                self.multipliers[resourceName] = baseMultiplier * multiplier
            end
        end
    end
end

-- Update resource generation
function ResourceSystem:update(dt)
    -- Use provided dt directly for deterministic testing
    local deltaTime = dt
    
    -- Generate resources based on rates
    for resourceName, rate in pairs(self.generation) do
        if rate > 0 then
            local generated = rate * deltaTime * self.multipliers[resourceName]
            self:addResource(resourceName, generated)
        end
    end
    
    -- Update click combo decay
    local timeSinceLastClick = (love and love.timer and love.timer.getTime() or os.clock()) - self.lastClickTime
    if timeSinceLastClick > self.comboDecayTime then
        self.clickCombo = math.max(1.0, self.clickCombo - (dt * 2.0))
    end
    
    -- Update last update time if in Love2D environment
    if love and love.timer then
        self.lastUpdateTime = love.timer.getTime()
    end
    
    -- Publish resource update event
    self.eventBus:publish("resources_updated", {
        resources = self.resources,
        generation = self.generation
    })
end

-- Manual click for resources (primarily Data Bits)
function ResourceSystem:click()
    local currentTime = love.timer.getTime()
    local timeSinceLastClick = currentTime - self.lastClickTime
    
    -- Update click combo
    if timeSinceLastClick <= self.comboDecayTime then
        self.clickCombo = math.min(self.clickCombo + 0.2, 5.0)
    else
        self.clickCombo = 1.0
    end
    
    self.lastClickTime = currentTime
    
    -- Calculate click reward
    local baseReward = self.clickPower
    local comboMultiplier = self.clickCombo
    
    -- Critical hit chance (5% base + processing power bonus)
    local critChance = 0.05 + (self.resources.processingPower * 0.0005)
    local isCritical = math.random() < critChance
    local criticalMultiplier = isCritical and 10 or 1
    
    local totalReward = baseReward * comboMultiplier * criticalMultiplier
    
    self:addResource("dataBits", totalReward)
    
    -- Publish click event
    self.eventBus:publish("resource_clicked", {
        resource = "dataBits",
        amount = totalReward,
        combo = comboMultiplier,
        critical = isCritical
    })
    
    return {
        reward = totalReward,
        combo = comboMultiplier,
        critical = isCritical
    }
end

-- Add resource with storage limits
function ResourceSystem:addResource(resourceName, amount)
    if not self.resources[resourceName] then
        return false
    end
    
    local currentAmount = self.resources[resourceName]
    local maxStorage = self.storage[resourceName] or math.huge
    local newAmount = math.min(currentAmount + amount, maxStorage)
    
    self.resources[resourceName] = newAmount
    
    -- Publish resource changed event
    self.eventBus:publish("resource_changed", {
        resource = resourceName,
        oldAmount = currentAmount,
        newAmount = newAmount,
        addedAmount = newAmount - currentAmount
    })
    
    return true
end

-- Spend resource
function ResourceSystem:spendResource(resourceName, amount)
    if not self.resources[resourceName] then
        return false
    end
    
    if self.resources[resourceName] >= amount then
        local oldAmount = self.resources[resourceName]
        self.resources[resourceName] = self.resources[resourceName] - amount
        
        -- Publish resource spent event
        self.eventBus:publish("resource_spent", {
            resource = resourceName,
            amount = amount,
            remaining = self.resources[resourceName]
        })
        
        return true
    end
    
    return false
end

-- Check if player can afford cost
function ResourceSystem:canAfford(costs)
    for resourceName, amount in pairs(costs) do
        if not self.resources[resourceName] or self.resources[resourceName] < amount then
            return false
        end
    end
    return true
end

-- Spend multiple resources at once
function ResourceSystem:spendResources(costs)
    if not self:canAfford(costs) then
        return false
    end
    
    for resourceName, amount in pairs(costs) do
        self:spendResource(resourceName, amount)
    end
    
    return true
end

-- Set resource amount (for initialization/loading)
function ResourceSystem:setResource(resourceName, amount)
    if self.resources[resourceName] ~= nil then
        self.resources[resourceName] = amount
    end
end

-- Get resource amount
function ResourceSystem:getResource(resourceName)
    return self.resources[resourceName] or 0
end

-- Get all resources
function ResourceSystem:getAllResources()
    return self.resources
end

-- Set generation rate
function ResourceSystem:setGeneration(resourceName, rate)
    if self.generation[resourceName] ~= nil then
        self.generation[resourceName] = rate
    end
end

-- Add to generation rate
function ResourceSystem:addGeneration(resourceName, rate)
    if self.generation[resourceName] ~= nil then
        self.generation[resourceName] = self.generation[resourceName] + rate
    end
end

-- Get generation rate
function ResourceSystem:getGeneration(resourceName)
    return self.generation[resourceName] or 0
end

-- Get all generation rates
function ResourceSystem:getAllGeneration()
    return self.generation
end

-- Set resource multiplier
function ResourceSystem:setMultiplier(resourceName, multiplier)
    if self.multipliers[resourceName] ~= nil then
        self.multipliers[resourceName] = multiplier
    end
end

-- Get resource multiplier
function ResourceSystem:getMultiplier(resourceName)
    return self.multipliers[resourceName] or 1.0
end

-- Set storage limit
function ResourceSystem:setStorageLimit(resourceName, limit)
    if self.storage[resourceName] ~= nil then
        self.storage[resourceName] = limit
    end
end

-- Get storage limit
function ResourceSystem:getStorageLimit(resourceName)
    return self.storage[resourceName] or math.huge
end

-- Get click information
function ResourceSystem:getClickInfo()
    return {
        power = self.clickPower,
        combo = self.clickCombo,
        maxCombo = 5.0
    }
end

-- Set click power
function ResourceSystem:setClickPower(power)
    self.clickPower = power
end

-- Get state for saving
function ResourceSystem:getState()
    return {
        resources = self.resources,
        generation = self.generation,
        multipliers = self.multipliers,
        clickPower = self.clickPower,
        storage = self.storage
    }
end

-- Load state from save
function ResourceSystem:loadState(state)
    if state.resources then
        for name, value in pairs(state.resources) do
            self.resources[name] = value or 0
        end
    end
    
    if state.generation then
        for name, value in pairs(state.generation) do
            self.generation[name] = value or 0
        end
    end
    
    if state.multipliers then
        for name, value in pairs(state.multipliers) do
            self.multipliers[name] = value or 1.0
        end
    end
    
    if state.clickPower then
        self.clickPower = state.clickPower
    end
    
    if state.storage then
        for name, value in pairs(state.storage) do
            self.storage[name] = value
        end
    end
end

return ResourceSystem