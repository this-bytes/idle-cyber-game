-- ECS Contract System - Cybersecurity empire dealflow orchestrator
-- Manages contracts using Entity-Component-System architecture
-- Replaces legacy ContractSystem with pure ECS approach

local System = require("src.ecs.system")
local Contracts = require("src.data.contracts")

local ECSContractSystem = setmetatable({}, { __index = System })
ECSContractSystem.__index = ECSContractSystem

local function randomRange(min, max)
    return min + math.random() * (max - min)
end

local function clamp(value, min, max)
    if min and value < min then
        return min
    end
    if max and value > max then
        return max
    end
    return value
end

-- Create new ECS contract system
function ECSContractSystem.new(world, eventBus)
    local self = System.new("ECSContractSystem", world, eventBus)
    setmetatable(self, ECSContractSystem)

    -- Set required components
    self:setRequiredComponents({ "contract", "activeWork" })

    self.contractTemplates = Contracts.getTemplates()
    self.contractDifficultyScale = 1.0
    self.maxAvailableContracts = 4
    self.refreshInterval = 18
    self.refreshTimer = 0
    self.autoAssignSpecialists = true

    self.availableContracts = {}
    self.activeContracts = {}
    self.completedContracts = {}
    self.contractHistory = {}

    self.resourceSystem = nil
    self.specialistSystem = nil
    self.upgradeSystem = nil

    return self
end

function ECSContractSystem:setResourceSystem(system)
    self.resourceSystem = system
end

function ECSContractSystem:setSpecialistSystem(system)
    self.specialistSystem = system
end

function ECSContractSystem:setUpgradeSystem(system)
    self.upgradeSystem = system
end

-- Initialize the system
function ECSContractSystem:initialize()
    System.initialize(self)

    if self.eventBus then
        self.eventBus:subscribe("contract_accept", function(data)
            if data and data.entityId then
                self:startContract(data.entityId, data.assignments)
            end
        end)

        self.eventBus:subscribe("contract_cancel", function(data)
            if data and data.entityId then
                self:cancelContract(data.entityId, data.reason)
            end
        end)

        self.eventBus:subscribe("contract_generate", function()
            self:refreshAvailableContracts(true)
        end)
    end

    self:refreshAvailableContracts(true)
end

-- Process contract entities
function ECSContractSystem:processEntity(entityId, dt)
    local contract = self:getComponent(entityId, "contract")
    local work = self:getComponent(entityId, "activeWork")

    if not contract or not work or contract.status == "completed" then
        return
    end

    if work.status == "active" then
        local speed = work.speedMultiplier or 1.0
        work.timeRemaining = clamp(work.timeRemaining - (dt * speed), 0, contract.duration)
        work.progress = clamp(1.0 - (work.timeRemaining / contract.duration), 0, 1)

        local efficiency = work.efficiencyMultiplier or 1.0
        local duration = math.max(contract.duration, 1)
        local resourceGain = {
            money = ((contract.rewards.money or 0) / duration) * dt * efficiency,
            xp = ((contract.rewards.xp or 0) / duration) * dt,
            reputation = ((contract.rewards.reputation or 0) / duration) * dt,
        }

        if self.resourceSystem then
            local primary = self.resourceSystem:getPrimaryResourceEntity()
            if primary then
                self.resourceSystem:addResources(primary, resourceGain, {
                    source = "contract_tick",
                    contractId = contract.id,
                })
            end
        end

        if work.timeRemaining <= 0 then
            self:completeContract(entityId)
        end
    elseif work.status == "available" then
        work.progress = 0
    end
end

function ECSContractSystem:update(dt)
    self.refreshTimer = self.refreshTimer + dt
    if self.refreshTimer >= self.refreshInterval then
        self.refreshTimer = 0
        self:refreshAvailableContracts()
    end

    System.update(self, dt)
end

function ECSContractSystem:refreshAvailableContracts(force)
    if #self.contractTemplates == 0 then
        self.contractTemplates = Contracts.getTemplates()
    end

    local current = self:getAvailableContracts()
    if not force and #current >= self.maxAvailableContracts then
        return
    end

    local toGenerate = self.maxAvailableContracts - #current
    for _ = 1, toGenerate do
        local template = self:pickTemplateForPlayer()
        if template then
            self:createContractEntity(template)
        end
    end
end

function ECSContractSystem:pickTemplateForPlayer()
    if #self.contractTemplates == 0 then
        return nil
    end

    local reputation = 0
    if self.resourceSystem then
        local primary = self.resourceSystem:getPrimaryResourceEntity()
        if primary then
            reputation = self.resourceSystem:getResources(primary).reputation or 0
        end
    end

    local filtered = {}
    for _, template in ipairs(self.contractTemplates) do
        local requirement = template.requirement or {}
        local repRequirement = requirement.reputation or 0
        if reputation >= repRequirement then
            table.insert(filtered, template)
        end
    end

    if #filtered == 0 then
        filtered = self.contractTemplates
    end

    return filtered[math.random(#filtered)]
end

function ECSContractSystem:createContractEntity(template)
    local scale = self:calculateContractScale(template)
    local contractData = Contracts.instantiate(template.id, scale)
    if not contractData then
        return nil
    end

    contractData.clientName = contractData.clientName or template.clientName
    contractData.description = contractData.description or template.description
    contractData.budget = contractData.totalBudget or math.floor(template.baseBudget * scale)
    contractData.duration = contractData.originalDuration or math.max(20, math.floor(template.baseDuration * scale))
    contractData.reputationReward = contractData.reputationReward or template.reputationReward
    contractData.riskLevel = contractData.riskLevel or template.riskLevel or "MEDIUM"
    contractData.tier = template.tier or 1

    local rewards = {
        money = contractData.budget,
        reputation = contractData.reputationReward,
        xp = math.floor(contractData.budget * 0.15),
        missionTokens = (contractData.riskLevel == "HIGH" or contractData.riskLevel == "CRITICAL") and 1 or 0,
    }

    local entityId = self.world:createEntity()
    self.world:addComponent(entityId, "contract", {
        id = contractData.id,
        templateId = template.id,
        clientName = contractData.clientName,
        description = contractData.description,
        budget = contractData.budget,
        duration = contractData.duration,
        reputationReward = contractData.reputationReward,
        riskLevel = contractData.riskLevel,
        tier = contractData.tier,
        rewards = rewards,
        requirement = template.requiredResources or contractData.requirement or {},
        status = "available",
    })

    self.world:addComponent(entityId, "activeWork", {
        status = "available",
        timeRemaining = contractData.duration,
        progress = 0,
        efficiencyMultiplier = 1.0,
        speedMultiplier = 1.0,
        assignedSpecialists = {},
    })

    table.insert(self.availableContracts, entityId)

    if self.eventBus then
        self.eventBus:publish("contract_available", {
            entityId = entityId,
            contract = self:getComponent(entityId, "contract"),
        })
    end

    return entityId
end

function ECSContractSystem:calculateContractScale(template)
    local baseScale = self.contractDifficultyScale
    local reputation = 0

    if self.resourceSystem then
        local primary = self.resourceSystem:getPrimaryResourceEntity()
        if primary then
            reputation = self.resourceSystem:getResources(primary).reputation or 0
        end
    end

    local repModifier = 1 + (reputation / 1000)
    local upgradeModifier = 1

    if self.upgradeSystem then
        upgradeModifier = upgradeModifier + (self.upgradeSystem:getContractModifiers().payout or 0)
    end

    return baseScale * repModifier * upgradeModifier * randomRange(0.85, 1.3)
end

-- Start a contract
function ECSContractSystem:startContract(entityId, specialistAssignments)
    local contract = self:getComponent(entityId, "contract")
    local work = self:getComponent(entityId, "activeWork")

    if not contract or not work or work.status ~= "available" then
        return false
    end

    if not self:meetsContractRequirements(contract.requirement) then
        if self.eventBus then
            self.eventBus:publish("contract_declined", {
                entityId = entityId,
                reason = "requirements",
            })
        end
        return false
    end

    local bonuses = self:autoAssignSpecialists(entityId, specialistAssignments)
    local upgradeBoost = self.upgradeSystem and self.upgradeSystem:getContractModifiers() or {}

    work.status = "active"
    work.startedAt = (love and love.timer and love.timer.getTime()) or os.clock()
    work.timeRemaining = contract.duration
    work.efficiencyMultiplier = bonuses.efficiency * (1 + (upgradeBoost.efficiency or 0))
    work.speedMultiplier = bonuses.speed * (1 + (upgradeBoost.speed or 0))
    work.progress = 0

    contract.status = "active"
    self.activeContracts[entityId] = { entityId = entityId, startedAt = work.startedAt }

    for i = #self.availableContracts, 1, -1 do
        if self.availableContracts[i] == entityId then
            table.remove(self.availableContracts, i)
            break
        end
    end

    if self.eventBus then
        self.eventBus:publish("contract_started", {
            entityId = entityId,
            contract = contract,
            work = work,
        })
    end

    return true
end

function ECSContractSystem:autoAssignSpecialists(entityId, specialistAssignments)
    if not self.specialistSystem then
        return { efficiency = 1.0, speed = 1.0 }
    end

    local bonuses, assigned = self.specialistSystem:generateContractBonuses(specialistAssignments)
    local work = self:getComponent(entityId, "activeWork")
    if work then
        work.assignedSpecialists = assigned or {}
    end

    return bonuses or { efficiency = 1.0, speed = 1.0 }
end

-- Complete a contract
function ECSContractSystem:completeContract(entityId)
    local contract = self:getComponent(entityId, "contract")
    local work = self:getComponent(entityId, "activeWork")

    if not contract or not work or contract.status == "completed" then
        return false
    end

    contract.status = "completed"
    work.status = "complete"
    work.progress = 1
    work.timeRemaining = 0

    self.completedContracts[entityId] = { entityId = entityId, contract = contract }
    self.activeContracts[entityId] = nil

    table.insert(self.contractHistory, {
        id = contract.id,
        clientName = contract.clientName,
        rewards = contract.rewards,
        completedAt = (love and love.timer and love.timer.getTime()) or os.clock(),
    })

    if self.resourceSystem then
        local primary = self.resourceSystem:getPrimaryResourceEntity()
        if primary then
            self.resourceSystem:addResources(primary, {
                missionTokens = contract.rewards.missionTokens or 0,
            }, {
                source = "contract_completion",
                contractId = contract.id,
            })
        end
    end

    if self.specialistSystem then
        self.specialistSystem:releaseSpecialists(work.assignedSpecialists or {}, contract)
    end

    if self.eventBus then
        self.eventBus:publish("contract_completed", {
            entityId = entityId,
            contract = contract,
            rewards = contract.rewards,
        })
    end

    return true
end

-- Cancel a contract
function ECSContractSystem:cancelContract(entityId, reason)
    local contract = self:getComponent(entityId, "contract")
    local work = self:getComponent(entityId, "activeWork")

    if not contract or not work then
        return
    end

    if work.status == "active" and self.specialistSystem then
        self.specialistSystem:releaseSpecialists(work.assignedSpecialists or {}, contract, true)
    end

    contract.status = "cancelled"
    work.status = "cancelled"

    self.activeContracts[entityId] = nil

    if self.eventBus then
        self.eventBus:publish("contract_cancelled", {
            entityId = entityId,
            contract = contract,
            reason = reason or "cancelled",
        })
    end

    self.world:destroyEntity(entityId)
    self:refreshAvailableContracts(true)
end

function ECSContractSystem:meetsContractRequirements(requirements)
    if not requirements or next(requirements) == nil then
        return true
    end

    if not self.resourceSystem then
        return true
    end

    local primary = self.resourceSystem:getPrimaryResourceEntity()
    if not primary then
        return false
    end

    local resources = self.resourceSystem:getResources(primary)
    for resource, amount in pairs(requirements) do
        if (resources[resource] or 0) < amount then
            return false
        end
    end

    return true
end

function ECSContractSystem:getAvailableContracts()
    local list = {}
    for _, entityId in ipairs(self.availableContracts) do
        local contract = self:getComponent(entityId, "contract")
        local work = self:getComponent(entityId, "activeWork")
        if contract and work and work.status == "available" then
            table.insert(list, { entityId = entityId, contract = contract, work = work })
        end
    end
    return list
end

function ECSContractSystem:getActiveContracts()
    local list = {}
    for entityId in pairs(self.activeContracts) do
        local contract = self:getComponent(entityId, "contract")
        local work = self:getComponent(entityId, "activeWork")
        if contract and work and work.status == "active" then
            table.insert(list, { entityId = entityId, contract = contract, work = work })
        end
    end
    return list
end

function ECSContractSystem:getCompletedContracts()
    local list = {}
    for _, data in pairs(self.completedContracts) do
        table.insert(list, data)
    end
    return list
end

function ECSContractSystem:getStats()
    return {
        availableCount = #self:getAvailableContracts(),
        activeCount = #self:getActiveContracts(),
        completedCount = #self:getCompletedContracts(),
        historyCount = #self.contractHistory,
    }
end

return ECSContractSystem