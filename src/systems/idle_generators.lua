-- Idle Generators System
-- Handles dynamic creation and management of idle resource generators from JSON
-- Supports equipment, automation, infrastructure, and training systems

local IdleGenerators = {}
IdleGenerators.__index = IdleGenerators

local json = require("dkjson")

-- Create new idle generators system
function IdleGenerators.new(eventBus, resourceManager)
    local self = setmetatable({}, IdleGenerators)
    
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Generator definitions loaded from JSON
    self.generatorDefinitions = {}
    self.categoryDefinitions = {}
    
    -- Player owned generators
    self.ownedGenerators = {}
    
    -- Generation tracking
    self.lastUpdateTime = 0
    
    return self
end

-- Initialize the system by loading generators from JSON
function IdleGenerators:initialize()
    print("⚙️ Initializing idle generators system...")
    
    -- Load generator definitions from JSON
    self:loadGeneratorDefinitions()
    
    -- Initialize owned generators tracking
    self:initializeOwnedGenerators()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    print("⚙️ Idle generators system initialized with " .. self:getTotalDefinitions() .. " generator types")
    return true
end

-- Load generator definitions from JSON file
function IdleGenerators:loadGeneratorDefinitions()
    local dataPath = "src/data/idle_generators.json"
    
    if love and love.filesystem and love.filesystem.getInfo then
        -- Running in LÖVE environment
        if love.filesystem.getInfo(dataPath) then
            local content = love.filesystem.read(dataPath)
            local data, pos, err = json.decode(content)
            if data then
                self.generatorDefinitions = data.generators or {}
                self.categoryDefinitions = data.categories or {}
                print("   ✅ Loaded idle generators from JSON")
            else
                print("   ❌ Failed to parse idle generators JSON: " .. tostring(err))
                self:setDefaultGenerators()
            end
        else
            print("   ⚠️ Idle generators JSON not found, using defaults")
            self:setDefaultGenerators()
        end
    else
        -- Running in standard Lua environment
        local f = io.open(dataPath, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local data, pos, err = json.decode(content)
            if data then
                self.generatorDefinitions = data.generators or {}
                self.categoryDefinitions = data.categories or {}
                print("   ✅ Loaded idle generators from JSON")
            else
                print("   ❌ Failed to parse idle generators JSON: " .. tostring(err))
                self:setDefaultGenerators()
            end
        else
            print("   ⚠️ Idle generators JSON not found, using defaults")
            self:setDefaultGenerators()
        end
    end
end

-- Set default generators if JSON loading fails
function IdleGenerators:setDefaultGenerators()
    self.generatorDefinitions = {
        equipment = {
            {
                id = "basic_workstation",
                name = "Basic Workstation",
                description = "A standard computer setup for basic security tasks",
                category = "equipment",
                cost = { money = 1000 },
                unlockRequirements = {},
                generation = { money = 2, xp = 0.1 },
                maxOwned = 10,
                costMultiplier = 1.15,
                tier = 1,
                icon = "💻"
            }
        }
    }
    
    self.categoryDefinitions = {
        equipment = {
            name = "Equipment",
            description = "Hardware and software tools for security operations",
            icon = "🔧",
            color = {0.3, 0.7, 0.9, 1}
        }
    }
end

-- Initialize owned generators tracking
function IdleGenerators:initializeOwnedGenerators()
    for category, generators in pairs(self.generatorDefinitions) do
        if not self.ownedGenerators[category] then
            self.ownedGenerators[category] = {}
        end
        
        for _, generator in ipairs(generators) do
            if not self.ownedGenerators[category][generator.id] then
                self.ownedGenerators[category][generator.id] = 0
            end
        end
    end
end

-- Subscribe to events
function IdleGenerators:subscribeToEvents()
    -- Handle purchase requests
    self.eventBus:subscribe("purchase_generator", function(data)
        self:purchaseGenerator(data.category, data.id, data.quantity or 1)
    end)
    
    -- Handle sell requests
    self.eventBus:subscribe("sell_generator", function(data)
        self:sellGenerator(data.category, data.id, data.quantity or 1)
    end)
end

-- Update generator resource generation
function IdleGenerators:update(dt)
    local currentTime = love.timer and love.timer.getTime() or os.clock()
    
    if self.lastUpdateTime == 0 then
        self.lastUpdateTime = currentTime
        return
    end
    
    local deltaTime = dt or (currentTime - self.lastUpdateTime)
    self.lastUpdateTime = currentTime
    
    -- Calculate generation from all owned generators
    local totalGeneration = {}
    
    for category, generators in pairs(self.ownedGenerators) do
        for generatorId, quantity in pairs(generators) do
            if quantity > 0 then
                local definition = self:getGeneratorDefinition(category, generatorId)
                if definition and definition.generation then
                    for resource, rate in pairs(definition.generation) do
                        totalGeneration[resource] = (totalGeneration[resource] or 0) + (rate * quantity)
                    end
                end
            end
        end
    end
    
    -- Apply generation to resource manager
    for resource, rate in pairs(totalGeneration) do
        if rate > 0 then
            local generated = rate * deltaTime
            self.resourceManager:addResource(resource, generated)
        end
    end
end

-- Purchase a generator
function IdleGenerators:purchaseGenerator(category, id, quantity)
    quantity = quantity or 1
    
    local definition = self:getGeneratorDefinition(category, id)
    if not definition then
        return false, "Generator not found"
    end
    
    -- Check unlock requirements
    if not self:isUnlocked(definition) then
        return false, "Generator not unlocked"
    end
    
    -- Check current quantity vs max owned
    local currentOwned = self:getOwnedQuantity(category, id)
    if currentOwned + quantity > (definition.maxOwned or math.huge) then
        return false, "Maximum owned limit reached"
    end
    
    -- Calculate total cost with scaling
    local totalCost = self:calculateCost(definition, currentOwned, quantity)
    
    -- Check if player can afford
    if not self.resourceManager:canAfford(totalCost) then
        return false, "Cannot afford generator"
    end
    
    -- Purchase generator
    if self.resourceManager:spendResources(totalCost) then
        self.ownedGenerators[category][id] = currentOwned + quantity
        
        -- Publish purchase event
        self.eventBus:publish("generator_purchased", {
            category = category,
            id = id,
            quantity = quantity,
            totalCost = totalCost,
            newQuantity = self.ownedGenerators[category][id]
        })
        
        print("💰 Purchased " .. quantity .. "x " .. definition.name)
        return true, "Purchase successful"
    end
    
    return false, "Purchase failed"
end

-- Sell a generator (if enabled)
function IdleGenerators:sellGenerator(category, id, quantity)
    quantity = quantity or 1
    
    local currentOwned = self:getOwnedQuantity(category, id)
    if currentOwned < quantity then
        return false, "Not enough generators to sell"
    end
    
    local definition = self:getGeneratorDefinition(category, id)
    if not definition then
        return false, "Generator not found"
    end
    
    -- Calculate sell value (50% of purchase cost)
    local sellValue = {}
    if definition.cost then
        for resource, cost in pairs(definition.cost) do
            sellValue[resource] = math.floor(cost * 0.5 * quantity)
        end
    end
    
    -- Sell generator
    self.ownedGenerators[category][id] = currentOwned - quantity
    
    -- Give resources back
    for resource, amount in pairs(sellValue) do
        self.resourceManager:addResource(resource, amount)
    end
    
    -- Publish sell event
    self.eventBus:publish("generator_sold", {
        category = category,
        id = id,
        quantity = quantity,
        sellValue = sellValue,
        newQuantity = self.ownedGenerators[category][id]
    })
    
    print("💸 Sold " .. quantity .. "x " .. definition.name)
    return true, "Sale successful"
end

-- Check if a generator is unlocked
function IdleGenerators:isUnlocked(definition)
    if not definition.unlockRequirements then
        return true
    end
    
    for resource, required in pairs(definition.unlockRequirements) do
        local current = self.resourceManager:getResource(resource)
        if current < required then
            return false
        end
    end
    
    return true
end

-- Calculate cost for purchasing generators with scaling
function IdleGenerators:calculateCost(definition, currentOwned, quantity)
    local cost = {}
    local multiplier = definition.costMultiplier or 1.0
    
    if definition.cost then
        for resource, baseCost in pairs(definition.cost) do
            local totalCost = 0
            
            -- Calculate cost for each individual generator with scaling
            for i = 1, quantity do
                local scaledCost = baseCost * math.pow(multiplier, currentOwned + i - 1)
                totalCost = totalCost + scaledCost
            end
            
            cost[resource] = math.floor(totalCost)
        end
    end
    
    return cost
end

-- Get generator definition
function IdleGenerators:getGeneratorDefinition(category, id)
    if not self.generatorDefinitions[category] then
        return nil
    end
    
    for _, generator in ipairs(self.generatorDefinitions[category]) do
        if generator.id == id then
            return generator
        end
    end
    
    return nil
end

-- Get owned quantity of a generator
function IdleGenerators:getOwnedQuantity(category, id)
    if not self.ownedGenerators[category] then
        return 0
    end
    return self.ownedGenerators[category][id] or 0
end

-- Get all generators by category
function IdleGenerators:getGeneratorsByCategory(category)
    return self.generatorDefinitions[category] or {}
end

-- Get all categories
function IdleGenerators:getCategories()
    return self.categoryDefinitions
end

-- Get total number of generator definitions
function IdleGenerators:getTotalDefinitions()
    local total = 0
    for category, generators in pairs(self.generatorDefinitions) do
        total = total + #generators
    end
    return total
end

-- Get current generation rates
function IdleGenerators:getCurrentGeneration()
    local generation = {}
    
    for category, generators in pairs(self.ownedGenerators) do
        for generatorId, quantity in pairs(generators) do
            if quantity > 0 then
                local definition = self:getGeneratorDefinition(category, generatorId)
                if definition and definition.generation then
                    for resource, rate in pairs(definition.generation) do
                        generation[resource] = (generation[resource] or 0) + (rate * quantity)
                    end
                end
            end
        end
    end
    
    return generation
end

-- Get state for save/load
function IdleGenerators:getState()
    return {
        ownedGenerators = self.ownedGenerators,
        lastUpdateTime = self.lastUpdateTime
    }
end

-- Load state from save
function IdleGenerators:loadState(state)
    if state.ownedGenerators then
        self.ownedGenerators = state.ownedGenerators
        -- Ensure all current generators are tracked
        self:initializeOwnedGenerators()
    end
    
    if state.lastUpdateTime then
        self.lastUpdateTime = state.lastUpdateTime
    end
end

return IdleGenerators