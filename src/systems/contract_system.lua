-- Contract Management System - Idle Sec Ops
-- Handles client contracts, the primary idle gameplay loop

local ContractSystem = {}
ContractSystem.__index = ContractSystem
local ContractTemplates = require("src.data.contracts")

-- Create new contract system
function ContractSystem.new(eventBus)
    local self = setmetatable({}, ContractSystem)
    self.eventBus = eventBus
    
    -- Store reference to resource system for checking requirements
    self.resourceSystem = nil -- Will be set externally or retrieved via event bus
    
    -- Active contracts
    self.activeContracts = {}
    
    -- Available contracts (not yet taken)
    self.availableContracts = {}
    
    -- Contract generation parameters
    self.nextContractId = 1
    self.contractGenerationTimer = 0
    self.contractGenerationInterval = 15 -- Generate new contract every 15 seconds (reduced from 30 for better idle flow)
    
    -- Previously clientTypes lived here; now we use ContractTemplates registry
    
    -- Initialize with a basic contract (instantiate from templates)
    local initialContract = nil
    local firstTemplates = ContractTemplates.getTemplates()
    if #firstTemplates > 0 then
        -- instantiate first template as starter
        local tmpl = firstTemplates[1]
        initialContract = ContractTemplates.instantiate(tmpl.id, 1.0)
    end
    if initialContract then
        self.availableContracts[initialContract.id] = initialContract
    end
    
    return self
end

-- Set resource system reference for checking unlock requirements
function ContractSystem:setResourceSystem(resourceSystem)
    self.resourceSystem = resourceSystem
end

-- Update contract system
function ContractSystem:update(dt)
    -- Update active contracts
    for contractId, contract in pairs(self.activeContracts) do
        contract.remainingTime = contract.remainingTime - dt
        
        -- Contract completed
        if contract.remainingTime <= 0 then
            self:completeContract(contractId)
        else
            -- Generate income over time
            local incomeThisFrame = (contract.totalBudget / contract.originalDuration) * dt
            self.eventBus:publish("add_resource", {
                resource = "money",
                amount = incomeThisFrame
            })
        end
    end
    
    -- Generate new available contracts periodically
    self.contractGenerationTimer = self.contractGenerationTimer + dt
    if self.contractGenerationTimer >= self.contractGenerationInterval then
        self.contractGenerationTimer = 0
        self:generateRandomContract()
    end
end

-- Generate a contract of specific type
function ContractSystem:generateContract(templateId, scale)
    -- Use contract templates registry to instantiate contracts
    scale = scale or 1.0
    local contract = ContractTemplates.instantiate(templateId, scale)
    if contract then
        -- Ensure unique id if registry didn't provide one
        if not contract.id then
            contract.id = "c_" .. tostring(self.nextContractId)
            self.nextContractId = self.nextContractId + 1
        end
        -- Ensure status for available contracts
        contract.status = contract.status or "available"
    end
    return contract
end

-- Generate a random contract based on reputation level  
function ContractSystem:generateRandomContract()
    -- Get current reputation from resource system (simplified approach)
    local currentReputation = 0
    local currentMissionTokens = 0
    
    -- If resource system is available, get actual values
    if self.resourceSystem then
        currentReputation = self.resourceSystem:getResource("reputation") or 0
        currentMissionTokens = self.resourceSystem:getResource("missionTokens") or 0
    end
    
    -- Use templates registry to pick a random template and instantiate
    local allTemplates = ContractTemplates.getTemplates()
    if #allTemplates == 0 then return end

    local tmpl = allTemplates[math.random(#allTemplates)]
    local scale = 0.8 + math.random() * 1.4 -- random scale between 0.8 and 2.2
    local contract = self:generateContract(tmpl.id, scale)
    if contract then
        self.availableContracts[contract.id] = contract
        self.eventBus:publish("contract_available", { contract = contract })
    end
end

-- Accept a contract
function ContractSystem:acceptContract(contractId)
    local contract = self.availableContracts[contractId]
    if not contract then return false end
    
    -- Move to active contracts
    contract.status = "active"
    contract.acceptedTime = (love and love.timer and love.timer.getTime()) or os.clock()
    
    -- Critical fix: Properly initialize duration and remaining time
    -- If the template already provided originalDuration/remainingTime, keep them.
    -- Otherwise fall back to 'duration' or remainingTime fields.
    local dur = contract.originalDuration or contract.duration or contract.remainingTime
    if not dur then
        -- As a last resort, set a sensible default (30s)
        dur = 30
    end
    contract.originalDuration = contract.originalDuration or dur
    contract.remainingTime = contract.remainingTime or dur
    
    self.activeContracts[contractId] = contract
    self.availableContracts[contractId] = nil
    
    self.eventBus:publish("contract_accepted", {
        contract = contract
    })
    
    -- Show UI notification for contract acceptance
    self.eventBus:publish("ui.toast", {
        text = "Contract accepted: " .. contract.clientName,
        type = "info",
        duration = 2.5
    })
    
    self.eventBus:publish("ui.log", {
        text = "Contract accepted: " .. contract.clientName .. " - Budget: $" .. contract.totalBudget .. ", Duration: " .. math.floor(dur) .. "s",
        severity = "info"
    })
    
    return true
end

-- Complete a contract
function ContractSystem:completeContract(contractId)
    local contract = self.activeContracts[contractId]
    if not contract then return false end
    
    contract.status = "completed"
    
    -- Award reputation
    self.eventBus:publish("add_resource", {
        resource = "reputation",
        amount = contract.reputationReward
    })
    
    -- Award XP
    local xpReward = math.floor(contract.totalBudget * 0.1)
    self.eventBus:publish("add_resource", {
        resource = "xp",
        amount = xpReward
    })
    
    -- Remove from active contracts
    self.activeContracts[contractId] = nil
    
    self.eventBus:publish("contract_completed", {
        contract = contract
    })
    
    -- Show UI notification for contract completion
    self.eventBus:publish("ui.toast", {
        text = "Contract completed: " .. contract.clientName,
        type = "success",
        duration = 3.0
    })
    
    self.eventBus:publish("ui.log", {
        text = "Contract completed: " .. contract.clientName .. " - Earned $" .. contract.totalBudget .. " and " .. contract.reputationReward .. " reputation",
        severity = "success"
    })
    
    print("📋 Contract completed: " .. contract.clientName .. " - Earned " .. contract.reputationReward .. " reputation")
    
    return true
end

-- Get available contracts
function ContractSystem:getAvailableContracts()
    return self.availableContracts
end

-- Get active contracts
function ContractSystem:getActiveContracts()
    return self.activeContracts
end

-- Get contract by ID
function ContractSystem:getContract(contractId)
    return self.activeContracts[contractId] or self.availableContracts[contractId]
end

-- Get total income per second from all active contracts
function ContractSystem:getTotalIncomeRate()
    local totalRate = 0
    for _, contract in pairs(self.activeContracts) do
        totalRate = totalRate + (contract.totalBudget / contract.originalDuration)
    end
    return totalRate
end

-- Get contract statistics
function ContractSystem:getStats()
    local activeCount = 0
    local availableCount = 0
    local totalIncome = 0
    
    for _ in pairs(self.activeContracts) do
        activeCount = activeCount + 1
    end
    
    for _ in pairs(self.availableContracts) do
        availableCount = availableCount + 1
    end
    
    totalIncome = self:getTotalIncomeRate()
    
    return {
        activeContracts = activeCount,
        availableContracts = availableCount,
        totalIncomeRate = totalIncome
    }
end

-- Get state for saving
function ContractSystem:getState()
    return {
        activeContracts = self.activeContracts,
        availableContracts = self.availableContracts,
        nextContractId = self.nextContractId,
        contractGenerationTimer = self.contractGenerationTimer
    }
end

-- Load state from save
function ContractSystem:loadState(state)
    if state.activeContracts then
        self.activeContracts = state.activeContracts
    end
    
    if state.availableContracts then
        self.availableContracts = state.availableContracts
    end
    
    if state.nextContractId then
        self.nextContractId = state.nextContractId
    end
    
    if state.contractGenerationTimer then
        self.contractGenerationTimer = state.contractGenerationTimer
    end
end

return ContractSystem