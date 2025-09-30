-- Contract Management System - Idle Sec Ops
-- Handles client contracts, the primary idle gameplay loop

local ContractSystem = {}
ContractSystem.__index = ContractSystem

-- Create new contract system
function ContractSystem.new(eventBus, dataManager)
    local self = setmetatable({}, ContractSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.contracts = nil -- Will be loaded during initialize
    self.availableContracts = {}
    self.activeContracts = {}
    self.completedContracts = {}
    self.nextContractId = 1
    self.contractGenerationTimer = 0
    self.contractGenerationInterval = 10 -- seconds
    return self
end

function ContractSystem:initialize()
    -- Load contract definitions from the DataManager
    self.contracts = self.dataManager:getData("contracts")
    if not self.contracts then
        print("❌ ERROR: Contract data not found in DataManager. Contract system will not function.")
        self.contracts = {} -- Prevent crashes
    end
    print("📜 Contract system initialized.")
end

function ContractSystem:update(dt)
    -- Generate new contracts periodically
    self.contractGenerationTimer = self.contractGenerationTimer + dt
    if self.contractGenerationTimer >= self.contractGenerationInterval then
        self.contractGenerationTimer = 0
        if #self.availableContracts < 5 then -- Limit available contracts
            self:generateRandomContract()
        end
    end

    -- Update active contracts
    local completed = {}
    for id, contract in pairs(self.activeContracts) do
        contract.remainingTime = contract.remainingTime - dt
        if contract.remainingTime <= 0 then
            table.insert(completed, id)
        end
    end

    -- Process completed contracts
    for _, id in ipairs(completed) do
        self:completeContract(id)
    end
end

function ContractSystem:generateRandomContract()
    if not self.contracts or #self.contracts == 0 then return end

    local contractTemplate = self.contracts[math.random(#self.contracts)]
    local newContract = {
        id = self.nextContractId,
        clientName = contractTemplate.clientName,
        description = contractTemplate.description,
        reward = contractTemplate.reward,
        risk = contractTemplate.risk,
        duration = contractTemplate.duration,
        remainingTime = contractTemplate.duration
    }
    self.availableContracts[self.nextContractId] = newContract
    self.nextContractId = self.nextContractId + 1

    self.eventBus:publish("contract_available", { contract = newContract })
    print("Generated new contract: " .. newContract.clientName)
end

function ContractSystem:acceptContract(id)
    local contract = self.availableContracts[id]
    if contract then
        self.availableContracts[id] = nil
        self.activeContracts[id] = contract
        self.eventBus:publish("contract_accepted", { contract = contract })
        print("Accepted contract: " .. contract.clientName)
    else
        print("Error: Tried to accept non-existent contract with id: " .. id)
    end
end

function ContractSystem:completeContract(id)
    local contract = self.activeContracts[id]
    if contract then
        self.activeContracts[id] = nil
        self.completedContracts[id] = contract
        
        -- Publish completion event with reward info
        self.eventBus:publish("contract_completed", { contract = contract })
        self.eventBus:publish("resource_change", { money = contract.reward }) -- Assuming direct resource change
        
        print("Completed contract: " .. contract.clientName .. ". Reward: " .. contract.reward)
    end
end

function ContractSystem:getAvailableContracts()
    return self.availableContracts
end

function ContractSystem:getActiveContracts()
    return self.activeContracts
end

return ContractSystem