-- ECS Contract System - Pure ECS Implementation
-- Manages contracts using Entity-Component-System architecture
-- Replaces legacy ContractSystem with pure ECS approach

local System = require("src.ecs.system")
local ECSContractSystem = setmetatable({}, {__index = System})
ECSContractSystem.__index = ECSContractSystem

-- Create new ECS contract system
function ECSContractSystem.new(world, eventBus)
    local self = System.new("ECSContractSystem", world, eventBus)
    setmetatable(self, ECSContractSystem)
    
    -- Set required components
    self:setRequiredComponents({"contract", "activeWork"})
    
    -- Contract completion rewards
    self.completionRewards = {}
    
    return self
end

-- Initialize the system
function ECSContractSystem:initialize()
    System.initialize(self)
    
    -- Subscribe to contract events
    if self.eventBus then
        self.eventBus:subscribe("start_contract", function(data)
            self:startContract(data.entityId)
        end)
        
        self.eventBus:subscribe("complete_contract", function(data)
            self:completeContract(data.entityId)
        end)
    end
end

-- Process contract entities
function ECSContractSystem:processEntity(entityId, dt)
    local contract = self:getComponent(entityId, "contract")
    local work = self:getComponent(entityId, "activeWork")
    
    if not contract or not work then
        return
    end
    
    -- Update active contracts
    if work.started and not contract.completed then
        work.timeRemaining = work.timeRemaining - dt
        work.progress = 1.0 - (work.timeRemaining / contract.duration)
        
        -- Check for completion
        if work.timeRemaining <= 0 then
            self:completeContract(entityId)
        end
    end
end

-- Start a contract
function ECSContractSystem:startContract(entityId)
    local work = self:getComponent(entityId, "activeWork")
    local contract = self:getComponent(entityId, "contract")
    
    if work and contract and not work.started then
        work.started = true
        work.progress = 0
        
        print("🚀 Started contract: " .. contract.clientName)
        
        if self.eventBus then
            self.eventBus:publish("contract_started", {
                entityId = entityId,
                contract = contract
            })
        end
    end
end

-- Complete a contract
function ECSContractSystem:completeContract(entityId)
    local contract = self:getComponent(entityId, "contract")
    local work = self:getComponent(entityId, "activeWork")
    
    if not contract or not work then
        return
    end
    
    contract.completed = true
    work.started = false
    work.progress = 1.0
    
    -- Store rewards for application by resource system
    self.completionRewards[entityId] = {
        money = contract.budget,
        reputation = contract.reputationReward,
        experience = math.floor(contract.budget * 0.1)
    }
    
    print("📋 Completed contract: " .. contract.clientName .. 
          " - Earned $" .. contract.budget .. " and " .. contract.reputationReward .. " reputation")
    
    if self.eventBus then
        self.eventBus:publish("contract_completed", {
            entityId = entityId,
            contract = contract,
            rewards = self.completionRewards[entityId]
        })
    end
end

-- Get available contracts
function ECSContractSystem:getAvailableContracts()
    local available = {}
    local entities = self:getMatchingEntities()
    
    for _, entityId in ipairs(entities) do
        local contract = self:getComponent(entityId, "contract")
        local work = self:getComponent(entityId, "activeWork")
        
        if contract and work and not work.started and not contract.completed then
            table.insert(available, {
                entityId = entityId,
                contract = contract,
                work = work
            })
        end
    end
    
    return available
end

-- Get active (in progress) contracts
function ECSContractSystem:getActiveContracts()
    local active = {}
    local entities = self:getMatchingEntities()
    
    for _, entityId in ipairs(entities) do
        local contract = self:getComponent(entityId, "contract")
        local work = self:getComponent(entityId, "activeWork")
        
        if contract and work and work.started and not contract.completed then
            table.insert(active, {
                entityId = entityId,
                contract = contract,
                work = work
            })
        end
    end
    
    return active
end

-- Get completed contracts
function ECSContractSystem:getCompletedContracts()
    local completed = {}
    local entities = self:getMatchingEntities()
    
    for _, entityId in ipairs(entities) do
        local contract = self:getComponent(entityId, "contract")
        
        if contract and contract.completed then
            table.insert(completed, {
                entityId = entityId,
                contract = contract
            })
        end
    end
    
    return completed
end

-- Get pending rewards for resource system
function ECSContractSystem:getPendingRewards()
    local rewards = self.completionRewards
    self.completionRewards = {} -- Clear after returning
    return rewards
end

-- Get system statistics
function ECSContractSystem:getStats()
    local available = #self:getAvailableContracts()
    local active = #self:getActiveContracts() 
    local completed = #self:getCompletedContracts()
    
    return {
        availableCount = available,
        activeCount = active,
        completedCount = completed,
        totalContracts = available + active + completed
    }
end

return ECSContractSystem