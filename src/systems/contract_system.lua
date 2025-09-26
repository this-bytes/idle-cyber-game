-- Contract Management System - Cyber Empire Command
-- Handles client contracts, the primary idle gameplay loop

local ContractSystem = {}
ContractSystem.__index = ContractSystem

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
    
    -- Client types and their properties
    self.clientTypes = {
        startup = {
            name = "Tech Startup",
            budgetRange = {500, 2000},
            durationRange = {60, 180}, -- seconds
            reputationReward = {1, 5},
            riskLevel = "low",
            threatTypes = {"script_kiddies", "basic_malware"},
            description = "Small tech company needing basic security"
        },
        
        smallBusiness = {
            name = "Small Business",
            budgetRange = {1500, 5000},
            durationRange = {120, 300},
            reputationReward = {3, 10},
            riskLevel = "medium",
            threatTypes = {"phishing", "ransomware"},
            description = "Growing business with moderate security needs"
        },
        
        enterprise = {
            name = "Enterprise Corp",
            budgetRange = {10000, 50000},
            durationRange = {300, 600},
            reputationReward = {15, 50},
            riskLevel = "high",
            threatTypes = {"apt", "supply_chain", "zero_day"},
            description = "Large corporation requiring comprehensive security",
            unlockRequirement = {reputation = 50}
        },
        
        government = {
            name = "Government Agency",
            budgetRange = {25000, 100000},
            durationRange = {600, 1200},
            reputationReward = {30, 100},
            riskLevel = "critical",
            threatTypes = {"nation_state", "advanced_persistent", "zero_day"},
            description = "High-security government contract",
            unlockRequirement = {reputation = 200, missionTokens = 5}
        }
    }
    
    -- Initialize with a basic contract
    local initialContract = self:generateContract("startup")
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
function ContractSystem:generateContract(clientType)
    local clientData = self.clientTypes[clientType]
    if not clientData then return nil end
    
    local contract = {
        id = self.nextContractId,
        clientType = clientType,
        clientName = clientData.name .. " #" .. self.nextContractId,
        description = clientData.description,
        
        -- Financial details
        totalBudget = math.random(clientData.budgetRange[1], clientData.budgetRange[2]),
        duration = math.random(clientData.durationRange[1], clientData.durationRange[2]),
        originalDuration = 0, -- Will be set when contract is accepted
        remainingTime = 0, -- Will be set when contract is accepted
        
        -- Rewards
        reputationReward = math.random(clientData.reputationReward[1], clientData.reputationReward[2]),
        
        -- Risk profile
        riskLevel = clientData.riskLevel,
        threatTypes = clientData.threatTypes,
        
        -- Status
        status = "available", -- available, active, completed, failed
        acceptedTime = 0
    }
    
    self.nextContractId = self.nextContractId + 1
    
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
    
    local availableTypes = {}
    for clientType, data in pairs(self.clientTypes) do
        local canUnlock = true
        if data.unlockRequirement then
            -- Check unlock requirements against actual resources
            if data.unlockRequirement.reputation and currentReputation < data.unlockRequirement.reputation then
                canUnlock = false
            end
            if data.unlockRequirement.missionTokens and currentMissionTokens < data.unlockRequirement.missionTokens then
                canUnlock = false
            end
        end
        
        if canUnlock then
            table.insert(availableTypes, clientType)
        end
    end
    
    if #availableTypes > 0 then
        local randomType = availableTypes[math.random(#availableTypes)]
        local contract = self:generateContract(randomType)
        
        if contract then
            self.availableContracts[contract.id] = contract
            
            self.eventBus:publish("contract_available", {
                contract = contract
            })
        end
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
    contract.originalDuration = contract.duration
    contract.remainingTime = contract.duration
    
    self.activeContracts[contractId] = contract
    self.availableContracts[contractId] = nil
    
    self.eventBus:publish("contract_accepted", {
        contract = contract
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