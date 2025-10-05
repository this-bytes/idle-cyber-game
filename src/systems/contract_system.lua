-- Contract Management System - Idle Sec Ops
-- Handles client contracts, the primary idle gameplay loop
-- AWESOME Backend Integration

local ContractSystem = {}
ContractSystem.__index = ContractSystem

-- Create new contract system
function ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, itemRegistry, effectProcessor, resourceManager)
    local self = setmetatable({}, ContractSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.upgradeSystem = upgradeSystem
    self.specialistSystem = specialistSystem -- Store reference to specialist system
    self.skillSystem = specialistSystem and specialistSystem.skillSystem or nil -- Get from specialist system
    
    -- AWESOME Backend systems
    self.itemRegistry = itemRegistry
    self.effectProcessor = effectProcessor
    self.resourceManager = resourceManager -- Add resource manager reference
    
    self.contracts = nil -- Will be loaded during initialize
    self.availableContracts = {}
    self.activeContracts = {}
    self.completedContracts = {}
    self.nextContractId = 1
    self.contractGenerationTimer = 0
    self.contractGenerationInterval = 10 -- seconds
    self.incomeTimer = 0
    self.incomeInterval = 0.1 -- Payout every 0.1 seconds
    
    -- Auto-accept settings for idle gameplay
    self.autoAcceptEnabled = true -- Enable auto-accept by default for better idle experience
    self.maxActiveContracts = 3 -- Limit concurrent contracts for balance
    
    return self
end

function ContractSystem:initialize()
    -- Load contract definitions from ItemRegistry if available
    if self.itemRegistry then
        self.contracts = self.itemRegistry:getItemsByType("contract")
        print("📜 Contract system initialized with " .. #self.contracts .. " contract types (AWESOME Backend).")
    else
        -- Fallback to old DataManager
        local contractData = self.dataManager:getData("contracts")
        -- The data from JSON is a direct array, not nested under a "contracts" key.
        if not contractData or type(contractData) ~= "table" then
            print("❌ ERROR: Contract data not found or malformed in DataManager. Contract system will not function.")
            self.contracts = {} -- Prevent crashes
        else
            self.contracts = contractData
        end
        print("📜 Contract system initialized with " .. #self.contracts .. " contract types.")
    end

    -- Start with one available contract to get the ball rolling
    if #self.availableContracts == 0 and #self.activeContracts == 0 then
        self:generateRandomContract()
        -- Don't auto-accept - let player choose which contracts to accept
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

    -- Auto-accept contracts if enabled and capacity available
    if self.autoAcceptEnabled and #self.activeContracts < self.maxActiveContracts then
        for id, contract in pairs(self.availableContracts) do
            if #self.activeContracts < self.maxActiveContracts then
                self:acceptContract(id)
                break -- Accept one at a time to avoid spam
            end
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
    
    -- Update resource generation rates
    self:updateIncomeRate()
end

function ContractSystem:generateIncome()
    local totalIncome = 0
    
    if #self.activeContracts == 0 then
        return
    end

    -- Get performance multiplier based on capacity
    local performanceMultiplier = self:getPerformanceMultiplier()

    -- Use AWESOME Backend if available
    if self.effectProcessor and self.itemRegistry then
        for id, contract in pairs(self.activeContracts) do
            -- Get contract item definition
            local contractItem = self.itemRegistry:getItem(contract.templateId or contract.id)
            
            if contractItem then
                -- Build context for effect calculation
                local context = {
                    type = "contract",
                    tags = contractItem.tags or {},
                    activeItems = self:getActiveEffectItems(),
                    soft_cap = 10.0 -- Prevent runaway growth
                }
                
                -- Calculate income with all active effects
                local baseIncome = contract.reward / contract.duration
                local effectiveIncome = self.effectProcessor:calculateValue(
                    baseIncome,
                    "income_multiplier",
                    context
                )
                
                totalIncome = totalIncome + effectiveIncome
            else
                -- Fallback to basic calculation
                local incomePerSecond = contract.reward / contract.duration
                totalIncome = totalIncome + incomePerSecond
            end
        end
    else
        -- Legacy calculation
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

        for id, contract in pairs(self.activeContracts) do
            local incomePerSecond = contract.reward / contract.duration
            totalIncome = totalIncome + incomePerSecond
        end

        totalIncome = totalIncome * incomeModifier
    end
    
    -- Apply performance multiplier based on capacity
    totalIncome = totalIncome * performanceMultiplier

    if totalIncome > 0 then
        self.eventBus:publish("resource_add", { money = totalIncome })
    end
end

function ContractSystem:updateIncomeRate()
    if not self.resourceManager then return end
    
    local totalIncomeRate = self:getTotalIncomeRate()
    self.resourceManager:setGenerationRate("money", totalIncomeRate)
end

function ContractSystem:getActiveEffectItems()
    local items = {}
    
    -- Include all purchased upgrades
    if self.upgradeSystem then
        local upgrades = self.upgradeSystem:getPurchasedUpgrades()
        for _, upgrade in ipairs(upgrades) do
            if self.itemRegistry then
                local item = self.itemRegistry:getItem(upgrade.id)
                if item then
                    table.insert(items, item)
                end
            else
                -- Fallback: treat upgrade as effect item directly
                table.insert(items, upgrade)
            end
        end
    end
    
    -- Include all active specialists
    if self.specialistSystem then
        local specialists = self.specialistSystem:getActiveSpecialists()
        if specialists then
            for _, specialist in ipairs(specialists) do
                if self.itemRegistry then
                    local item = self.itemRegistry:getItem(specialist.id)
                    if item then
                        table.insert(items, item)
                    end
                else
                    table.insert(items, specialist)
                end
            end
        end
    end
    
    return items
end

function ContractSystem:generateRandomContract()
    if not self.contracts or #self.contracts == 0 then
        print("❌ No contract templates available")
        return
    end
    
    -- Select random contract template
    local template = self.contracts[math.random(#self.contracts)]
    
    -- Create contract instance
    local newContract = {
        id = self.nextContractId,
        clientName = template.clientName or "Unknown Client",
        displayName = template.displayName or template.name or "Contract",
        description = template.description or "No description",
        baseBudget = template.baseBudget or 1000,
        baseDuration = template.baseDuration or 60,
        reputationReward = template.reputationReward or 1,
        riskLevel = template.riskLevel or "LOW",
        requiredResources = template.requiredResources or {},
        rarity = template.rarity or "common",
        tags = template.tags or {},
        tier = template.tier or 1,
        effects = template.effects or {},
        -- Copy SLA-related fields if present
        slaRequirements = template.slaRequirements,
        capacityRequirements = template.capacityRequirements,
        rewards = template.rewards,
        penalties = template.penalties
    }
    
    self.availableContracts[self.nextContractId] = newContract
    self.nextContractId = self.nextContractId + 1

    self.eventBus:publish("contract_available", { contract = newContract })
    print("Generated new contract: " .. newContract.clientName)
end

function ContractSystem:acceptContract(id)
    local contract = self.availableContracts[id]
    if contract then
        -- Ensure baseBudget and baseDuration are numbers before proceeding
        if type(contract.baseBudget) ~= "number" or type(contract.baseDuration) ~= "number" or contract.baseDuration <= 0 then
            print(string.format("Error: Invalid contract data for %s. Budget: %s, Duration: %s", 
                contract.clientName, tostring(contract.baseBudget), tostring(contract.baseDuration)))
            return
        end
        
        -- Check capacity before accepting
        local canAccept, message = self:canAcceptContract(contract)
        if not canAccept then
            print("❌ Cannot accept contract: " .. message)
            self.eventBus:publish("contract_rejected", { 
                contract = contract, 
                reason = message 
            })
            return false
        end
        
        self.availableContracts[id] = nil
        
        -- Assign specialists (auto-assign CEO for now)
        contract.assignedSpecialists = {0} -- ID 0 is the CEO
        contract.reward = contract.baseBudget -- Set reward for income calculation
        contract.duration = contract.baseDuration -- Set duration for income calculation
        contract.remainingTime = contract.baseDuration
        
        -- Copy SLA requirements if present
        if contract.slaRequirements then
            contract.slaRequirements = contract.slaRequirements
        end
        if contract.capacityRequirements then
            contract.capacityRequirements = contract.capacityRequirements
        end
        if contract.rewards then
            contract.rewards = contract.rewards
        end
        if contract.penalties then
            contract.penalties = contract.penalties
        end

        self.activeContracts[id] = contract
        self.eventBus:publish("contract_accepted", { contract = contract })
        
        -- Check if we're over capacity and publish event
        local capacity = self:calculateWorkloadCapacity()
        local activeCount = 0
        for _ in pairs(self.activeContracts) do
            activeCount = activeCount + 1
        end
        
        if activeCount > capacity then
            self.eventBus:publish("contract_overloaded", {
                capacity = capacity,
                activeCount = activeCount,
                overload = activeCount - capacity
            })
            print(string.format("⚠️ Contracts overloaded! Capacity: %d, Active: %d", capacity, activeCount))
        end
        
        self.eventBus:publish("contract_capacity_changed", {
            capacity = capacity,
            activeCount = activeCount
        })
        
        print("Accepted contract: " .. contract.clientName .. " (Assigned: CEO)")
        if message ~= "OK" then
            print("⚠️ " .. message)
        end
        
        -- Update income rate when contract is accepted
        self:updateIncomeRate()
        return true
    else
        print("Error: Tried to accept non-existent contract with id: " .. tostring(id))
        return false
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
        
        -- Update income rate when contract is completed
        self:updateIncomeRate()
    end
end

function ContractSystem:getAvailableContracts()
    return self.availableContracts
end

function ContractSystem:getActiveContracts()
    return self.activeContracts
end

function ContractSystem:getTotalIncomeRate()
    local totalIncome = 0
    
    if #self.activeContracts == 0 then
        return 0
    end

    -- Get performance multiplier based on capacity
    local performanceMultiplier = self:getPerformanceMultiplier()

    -- Use AWESOME Backend if available
    if self.effectProcessor and self.itemRegistry then
        for id, contract in pairs(self.activeContracts) do
            -- Get contract item definition
            local contractItem = self.itemRegistry:getItem(contract.templateId or contract.id)
            
            if contractItem then
                -- Build context for effect calculation
                local context = {
                    type = "contract",
                    tags = contractItem.tags or {},
                    activeItems = self:getActiveEffectItems(),
                    soft_cap = 10.0 -- Prevent runaway growth
                }
                
                -- Calculate income with all active effects
                local baseIncome = contract.reward / contract.duration
                local effectiveIncome = self.effectProcessor:calculateValue(
                    baseIncome,
                    "income_multiplier",
                    context
                )
                
                totalIncome = totalIncome + effectiveIncome
            else
                -- Fallback to basic calculation
                local incomePerSecond = contract.reward / contract.duration
                totalIncome = totalIncome + incomePerSecond
            end
        end
    else
        -- Legacy calculation
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

        for id, contract in pairs(self.activeContracts) do
            local incomePerSecond = contract.reward / contract.duration
            totalIncome = totalIncome + (incomePerSecond * incomeModifier)
        end
    end
    
    -- Apply performance multiplier based on capacity
    totalIncome = totalIncome * performanceMultiplier
    
    return totalIncome
end

function ContractSystem:getStats()
    local availableCount = 0
    for _ in pairs(self.availableContracts) do
        availableCount = availableCount + 1
    end
    
    local activeCount = 0
    for _ in pairs(self.activeContracts) do
        activeCount = activeCount + 1
    end
    
    local completedCount = #self.completedContracts
    
    return {
        availableContracts = availableCount,
        activeContracts = activeCount,
        completedContracts = completedCount,
        totalIncomeRate = self:getTotalIncomeRate()
    }
end

-- Calculate workload capacity based on specialists and upgrades
function ContractSystem:calculateWorkloadCapacity()
    -- Base capacity: 1 contract per 5 specialists
    local specialistCount = 0
    if self.specialistSystem and self.specialistSystem.specialists then
        specialistCount = #self.specialistSystem.specialists
    end
    
    local baseCapacity = math.floor(specialistCount / 5)
    
    -- Get average specialist efficiency
    local avgEfficiency = self:getAverageSpecialistEfficiency()
    
    -- Efficiency multiplier: 50% weight on efficiency above 1.0
    local efficiencyMultiplier = 1 + (avgEfficiency - 1) * 0.5
    
    -- Apply upgrade bonuses
    local upgradeBonus = 0
    if self.upgradeSystem then
        upgradeBonus = self.upgradeSystem:getEffectValue("contract_capacity_bonus") or 0
    end
    
    -- Total capacity
    local totalCapacity = math.max(1, math.floor(baseCapacity * efficiencyMultiplier + upgradeBonus))
    
    return totalCapacity
end

-- Get average specialist efficiency
function ContractSystem:getAverageSpecialistEfficiency()
    if not self.specialistSystem or not self.specialistSystem.specialists then
        return 1.0
    end
    
    local specialists = self.specialistSystem.specialists
    if #specialists == 0 then
        return 1.0
    end
    
    local totalEfficiency = 0
    for _, specialist in ipairs(specialists) do
        -- Efficiency based on level and skills
        local efficiency = 1.0
        if specialist.level then
            efficiency = 1.0 + (specialist.level - 1) * 0.1
        end
        totalEfficiency = totalEfficiency + efficiency
    end
    
    return totalEfficiency / #specialists
end

-- Check if we can accept a contract
function ContractSystem:canAcceptContract(contract)
    local capacity = self:calculateWorkloadCapacity()
    local activeCount = 0
    for _ in pairs(self.activeContracts) do
        activeCount = activeCount + 1
    end
    
    -- Allow accepting if under capacity
    if activeCount < capacity then
        return true, "OK"
    end
    
    -- Can still accept but with performance penalty warning
    if activeCount < capacity + 3 then
        return true, "WARNING: Over capacity - performance will degrade"
    end
    
    return false, "Maximum capacity reached"
end

-- Get performance multiplier based on workload
function ContractSystem:getPerformanceMultiplier()
    local capacity = self:calculateWorkloadCapacity()
    local activeCount = 0
    for _ in pairs(self.activeContracts) do
        activeCount = activeCount + 1
    end
    
    -- At or under capacity: 100% performance
    if activeCount <= capacity then
        return 1.0
    end
    
    -- Over capacity: degradation
    -- 1 over: 85%, 2 over: 70%, 3+ over: 50%
    local overload = activeCount - capacity
    local degradation = 0.15 * overload
    local multiplier = math.max(0.5, 1.0 - degradation)
    
    return multiplier
end

-- State management
function ContractSystem:getState()
    return {
        availableContracts = self.availableContracts,
        activeContracts = self.activeContracts,
        completedContracts = self.completedContracts,
        nextContractId = self.nextContractId,
        contractGenerationTimer = self.contractGenerationTimer,
        autoAcceptEnabled = self.autoAcceptEnabled,
        maxActiveContracts = self.maxActiveContracts
    }
end

function ContractSystem:loadState(state)
    if state.availableContracts then
        self.availableContracts = state.availableContracts
    end
    if state.activeContracts then
        self.activeContracts = state.activeContracts
    end
    if state.completedContracts then
        self.completedContracts = state.completedContracts
    end
    if state.nextContractId then
        self.nextContractId = state.nextContractId
    end
    if state.contractGenerationTimer then
        self.contractGenerationTimer = state.contractGenerationTimer
    end
    if state.autoAcceptEnabled ~= nil then
        self.autoAcceptEnabled = state.autoAcceptEnabled
    end
    if state.maxActiveContracts then
        self.maxActiveContracts = state.maxActiveContracts
    end
end

return ContractSystem