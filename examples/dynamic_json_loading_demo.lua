#!/usr/bin/env lua5.3
-- Dynamic JSON Loading with ECS Demo
-- Demonstrates how the ECS architecture supports dynamic loading of new entities from JSON

print("🎯 Dynamic JSON Loading with ECS Demo")
print("=" .. string.rep("=", 60))

-- Load required components
local World = require("src.ecs.world")
local System = require("src.ecs.system")
local EventBus = require("src.utils.event_bus")
local Contracts = require("src.data.contracts")
local CostCalculator = require("src.rules.cost_calculator")
local EligibilityChecker = require("src.rules.eligibility_checker")

-- Create ECS world and event bus
local eventBus = EventBus.new()
local world = World.new(eventBus)
world:initialize()

-- Register component types for contracts
world:registerComponent("contract", {
    id = "string",
    clientName = "string", 
    description = "string",
    budget = "number",
    duration = "number",
    reputationReward = "number"
})
world:registerComponent("active", {started = "boolean", timeRemaining = "number"})
world:registerComponent("rewards", {money = "number", reputation = "number"})

print("✅ ECS World initialized with contract components")

-- Create a contract management system using ECS
local ContractECSSystem = {}
ContractECSSystem.__index = ContractECSSystem
setmetatable(ContractECSSystem, {__index = System})

function ContractECSSystem.new(world, eventBus)
    local self = System.new("ContractECSSystem", world, eventBus)
    setmetatable(self, ContractECSSystem)
    
    self:setRequiredComponents({"contract", "active"})
    return self
end

function ContractECSSystem:processEntity(entityId, dt)
    local contract = self:getComponent(entityId, "contract")
    local active = self:getComponent(entityId, "active")
    
    if contract and active and active.started then
        active.timeRemaining = active.timeRemaining - dt
        
        if active.timeRemaining <= 0 then
            -- Contract completed
            local rewards = self:getComponent(entityId, "rewards")
            if rewards then
                print("📋 Contract completed: " .. contract.clientName .. 
                      " - Earned $" .. rewards.money .. " and " .. rewards.reputation .. " reputation")
            end
            
            -- Remove the completed contract
            self.world:destroyEntity(entityId)
        end
    end
end

-- Register the contract system
world:registerSystem(ContractECSSystem.new(world, eventBus), 1)

print("✅ ContractECSSystem registered")

-- Demonstrate loading existing contracts from JSON
print("\n📋 Loading Existing Contracts from JSON:")
print("=" .. string.rep("=", 60))

local existingContracts = Contracts.getTemplates()
print("Found " .. #existingContracts .. " contract templates in JSON:")

for i, template in ipairs(existingContracts) do
    print(string.format("  %d. %s (%s) - Budget: $%d, Duration: %ds", 
                        i, template.clientName, template.id, template.baseBudget, template.baseDuration))
end

-- Demonstrate dynamic contract addition via registerTemplate
print("\n🆕 Adding New Contracts Dynamically:")
print("=" .. string.rep("=", 60))

-- Add a new contract template at runtime
local newContract1 = {
    id = "crypto_exchange",
    clientName = "CryptoEx Trading",
    description = "Secure cryptocurrency exchange platform with advanced threat monitoring.",
    baseBudget = 2500,
    baseDuration = 120,
    reputationReward = 8,
    riskLevel = "HIGH",
    requiredResources = {}
}

local newContract2 = {
    id = "healthcare_clinic", 
    clientName = "MedSecure Clinic",
    description = "HIPAA compliance audit and patient data protection implementation.",
    baseBudget = 1200,
    baseDuration = 90,
    reputationReward = 5,
    riskLevel = "MEDIUM",
    requiredResources = {}
}

-- Register new contracts
Contracts.registerTemplate(newContract1)
Contracts.registerTemplate(newContract2)

print("✅ Added 2 new contract types dynamically")
print("Updated contract count: " .. #Contracts.getTemplates())

-- Demonstrate creating ECS entities from JSON-loaded contracts
print("\n🏭 Creating ECS Entities from JSON Templates:")
print("=" .. string.rep("=", 60))

-- Create entities for all available contracts
local contractEntities = {}
local allTemplates = Contracts.getTemplates()

for i, template in ipairs(allTemplates) do
    -- Instantiate contract from template
    local contractInstance = Contracts.instantiate(template.id, 1.0 + (i * 0.2)) -- Scale each one differently
    
    if contractInstance then
        -- Create ECS entity for this contract
        local entityId = world:createEntity()
        
        -- Add contract component
        world:addComponent(entityId, "contract", {
            id = contractInstance.id,
            clientName = contractInstance.clientName,
            description = contractInstance.description,
            budget = contractInstance.totalBudget,
            duration = contractInstance.originalDuration,
            reputationReward = contractInstance.reputationReward
        })
        
        -- Add active tracking component
        world:addComponent(entityId, "active", {
            started = false,
            timeRemaining = contractInstance.remainingTime
        })
        
        -- Add rewards component
        world:addComponent(entityId, "rewards", {
            money = contractInstance.totalBudget,
            reputation = contractInstance.reputationReward
        })
        
        table.insert(contractEntities, entityId)
        
        print(string.format("✅ Created entity %d for %s (Budget: $%d)", 
                          entityId, contractInstance.clientName, contractInstance.totalBudget))
    end
end

-- Demonstrate rules engine integration with JSON loading
print("\n⚙️ Demonstrating Rules Engine with JSON Configuration:")
print("=" .. string.rep("=", 60))

local costCalculator = CostCalculator.new()
local eligibilityChecker = EligibilityChecker.new()

-- Example JSON configuration for rules engine
local rulesConfig = {
    costs = {
        contract = {
            crypto_exchange = 100,
            healthcare_clinic = 75,
            basic_small_business = 25
        }
    },
    requirements = {
        contract = {
            crypto_exchange = {reputation = 10, money = 500},
            healthcare_clinic = {reputation = 5, money = 200}
        }
    }
}

-- Load configuration into rules engine
costCalculator:loadFromConfig({
    baseCosts = rulesConfig.costs,
    scalingFactors = {contract = {crypto_exchange = 1.8, healthcare_clinic = 1.5}},
    modifiers = {}
})

eligibilityChecker:loadFromConfig({
    requirements = rulesConfig.requirements,
    restrictions = {},
    conditions = {}
})

print("✅ Rules engine configured from JSON-like data")

-- Test cost calculation for dynamically loaded contracts
local playerState = {money = 1000, reputation = 12}

for _, template in ipairs({newContract1, newContract2}) do
    local cost = costCalculator:calculateTotalCost("contract", template.id, {currentLevel = 0})
    local eligible, reason = eligibilityChecker:checkEligibility("contract", template.id, playerState)
    
    print(string.format("  %s: Cost $%d, Eligible: %s%s", 
                       template.clientName, cost, tostring(eligible),
                       not eligible and (" - " .. reason) or ""))
end

-- Simulate contract execution
print("\n🎮 Simulating Contract Execution:")
print("=" .. string.rep("=", 60))

-- Start a few contracts
for i = 1, math.min(3, #contractEntities) do
    local entityId = contractEntities[i]
    local active = world:getComponent(entityId, "active")
    local contract = world:getComponent(entityId, "contract")
    
    if active and contract then
        active.started = true
        print("🚀 Started contract: " .. contract.clientName)
    end
end

-- Run simulation for 10 iterations
for frame = 1, 10 do
    world:update(10) -- 10 seconds per frame for faster demo
    
    local activeContracts = world:query({"contract", "active"})
    local runningCount = 0
    
    for _, entityId in ipairs(activeContracts) do
        local active = world:getComponent(entityId, "active")
        if active and active.started then
            runningCount = runningCount + 1
        end
    end
    
    if runningCount == 0 then
        print("📋 All contracts completed!")
        break
    else
        print(string.format("Frame %d: %d contracts still running", frame, runningCount))
    end
end

-- Demonstrate JSON file modification simulation
print("\n💾 Demonstrating JSON File Update Simulation:")
print("=" .. string.rep("=", 60))

-- Add one more contract and save to JSON (simulation)
local urgentContract = {
    id = "emergency_response",
    clientName = "Emergency Services",
    description = "Critical incident response for government emergency services.",
    baseBudget = 5000,
    baseDuration = 24,
    reputationReward = 15,
    riskLevel = "CRITICAL",
    requiredResources = {}
}

Contracts.registerTemplate(urgentContract)

-- In a real scenario, this would write to the actual JSON file
print("✅ Added emergency contract template")
print("Final contract count: " .. #Contracts.getTemplates())

-- Show final statistics
local stats = world:getStats()
print("\n📊 Final ECS World Statistics:")
print("=" .. string.rep("=", 60))
print("Entities remaining: " .. stats.entityCount)
print("Systems running: " .. stats.systemCount)

-- Cleanup
world:teardown()
print("✅ ECS World cleaned up")

print("\n🎯 Dynamic JSON Loading Demo Complete!")
print("=" .. string.rep("=", 60))
print("Key Capabilities Demonstrated:")
print("  ✅ Loading existing entities from JSON files")
print("  ✅ Adding new entity templates at runtime")  
print("  ✅ Creating ECS entities from JSON templates")
print("  ✅ Rules engine configuration from JSON-like data")
print("  ✅ Dynamic system processing of JSON-loaded entities")
print("  ✅ Runtime contract template registration")
print("")
print("📝 To add new contracts in your game:")
print("  1. Add new contract object to src/data/contracts.json")
print("  2. Call Contracts.reloadFromJSON() to refresh templates")
print("  3. Use ECS world to create entities from new templates")
print("  4. Systems will automatically process the new entities")