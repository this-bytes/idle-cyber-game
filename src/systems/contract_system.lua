-- Contract Management System - Idle Sec Ops
-- Handles client contracts, the primary idle gameplay loop

local ContractSystem = {}
ContractSystem.__index = ContractSystem

-- Create new contract system
function ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem)
    local self = setmetatable({}, ContractSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.upgradeSystem = upgradeSystem
    self.specialistSystem = specialistSystem -- Store reference to specialist system
    self.skillSystem = specialistSystem.skillSystem -- Get from specialist system
    self.contracts = nil -- Will be loaded during initialize
    self.availableContracts = {}
    self.activeContracts = {}
    self.completedContracts = {}
    self.nextContractId = 1
    self.contractGenerationTimer = 0
    self.contractGenerationInterval = 10 -- seconds
    self.incomeTimer = 0
    self.incomeInterval = 1 -- Payout every second
    return self
end

function ContractSystem:initialize()
    -- Load contract definitions from the DataManager
    local contractData = self.dataManager:getData("contracts")
    -- The data from JSON is a direct array, not nested under a "contracts" key.
    if not contractData or type(contractData) ~= "table" then
        print("❌ ERROR: Contract data not found or malformed in DataManager. Contract system will not function.")
        self.contracts = {} -- Prevent crashes
    else
        self.contracts = contractData
    end
    
    print("📜 Contract system initialized with " .. #self.contracts .. " contract types.")

    -- Start with one active contract to get the ball rolling
    if #self.availableContracts == 0 and #self.activeContracts == 0 then
        self:generateRandomContract()
        if #self.availableContracts > 0 then
            local firstAvailableId = next(self.availableContracts)
            self:acceptContract(firstAvailableId)
        end
    end
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

    -- Update income generation
    self.incomeTimer = self.incomeTimer + dt
    if self.incomeTimer >= self.incomeInterval then
        self.incomeTimer = self.incomeTimer - self.incomeInterval
        self:generateIncome()
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

function ContractSystem:generateIncome()
    local totalIncome = 0
    local incomeModifier = 1.0

    -- Check for income-boosting upgrades
    if self.upgradeSystem then
        local purchasedUpgrades = self.upgradeSystem:getPurchasedUpgrades()
        for _, upgrade in ipairs(purchasedUpgrades) do
            if upgrade.effects and upgrade.effects.income_multiplier then
                incomeModifier = incomeModifier + (upgrade.effects.income_multiplier - 1)
            end
        end
    end

    -- Check for specialist efficiency bonuses
    if self.specialistSystem then
        local teamBonuses = self.specialistSystem:getTeamBonuses()
        if teamBonuses and teamBonuses.efficiency then
            incomeModifier = incomeModifier * teamBonuses.efficiency
        end
    end

    if #self.activeContracts == 0 then
        -- print("DEBUG: No active contracts to generate income from.")
        return
    end

    for id, contract in pairs(self.activeContracts) do
        -- DEBUG LOG: Check contract values
        -- print(string.format("DEBUG: Calculating income for contract %s. Reward: %s, Duration: %s", id, tostring(contract.reward), tostring(contract.duration)))
        
        -- Income per second is the total reward divided by the duration
        local incomePerSecond = contract.reward / contract.duration
        totalIncome = totalIncome + incomePerSecond
    end

    -- Apply the modifier
    totalIncome = totalIncome * incomeModifier

    -- DEBUG LOG: Check final income value
    -- print(string.format("DEBUG: Total income this tick: %f", totalIncome))

    if totalIncome > 0 then
        self.eventBus:publish("resource_add", { money = totalIncome })
    end
end

function ContractSystem:generateRandomContract()
    if not self.contracts or #self.contracts == 0 then return end

    local contractTemplate = self.contracts[math.random(#self.contracts)]
    local newContract = {
        id = self.nextContractId,
        clientName = contractTemplate.clientName,
        description = contractTemplate.description,
        reward = contractTemplate.baseBudget, -- Use baseBudget for reward
        risk = contractTemplate.riskLevel, -- Use riskLevel for risk
        duration = contractTemplate.baseDuration, -- Use baseDuration for duration
        remainingTime = contractTemplate.baseDuration
    }
    -- DEBUG LOG: Check created contract
    -- print(string.format("DEBUG: Generated contract with Reward: %s, Duration: %s", tostring(newContract.reward), tostring(newContract.duration)))

    self.availableContracts[self.nextContractId] = newContract
    self.nextContractId = self.nextContractId + 1

    self.eventBus:publish("contract_available", { contract = newContract })
    print("Generated new contract: " .. newContract.clientName)
end

function ContractSystem:acceptContract(id)
    local contract = self.availableContracts[id]
    if contract then
        -- Ensure reward and duration are numbers before proceeding
        if type(contract.reward) ~= "number" or type(contract.duration) ~= "number" or contract.duration <= 0 then
            print(string.format("Error: Invalid contract data for %s. Reward: %s, Duration: %s", 
                contract.clientName, tostring(contract.reward), tostring(contract.duration)))
            return
        end
        self.availableContracts[id] = nil
        
        -- Assign specialists (auto-assign CEO for now)
        contract.assignedSpecialists = {0} -- ID 0 is the CEO

        self.activeContracts[id] = contract
        self.eventBus:publish("contract_accepted", { contract = contract })
        print("Accepted contract: " .. contract.clientName .. " (Assigned: CEO)")
    else
        print("Error: Tried to accept non-existent contract with id: " .. tostring(id))
    end
end

function ContractSystem:completeContract(id)
    local contract = self.activeContracts[id]
    if contract then
        self.activeContracts[id] = nil
        self.completedContracts[id] = contract
        
        -- Calculate XP award based on contract value
        local xpAmount = math.floor((contract.reward or 0) * 0.1) -- 10% of contract reward as XP
        if xpAmount < 25 then
            xpAmount = 25 -- Minimum XP award
        end
        
        -- Publish completion event with reward info and XP
        self.eventBus:publish("contract_completed", { 
            contract = contract,
            xpAwarded = xpAmount,
            assignedSpecialists = contract.assignedSpecialists
        })
        self.eventBus:publish("resource_change", { money = contract.reward }) -- Assuming direct resource change
        
        print("Completed contract: " .. contract.clientName .. ". Reward: " .. contract.reward .. ", XP: " .. xpAmount)
    end
end

function ContractSystem:getAvailableContracts()
    return self.availableContracts
end

function ContractSystem:getActiveContracts()
    return self.activeContracts
end

return ContractSystem