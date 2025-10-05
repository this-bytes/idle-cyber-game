-- SLA System - Service Level Agreement Management
-- Tracks contract performance against SLA requirements
-- Part of Phase 1: Core SLA System Implementation

local SLASystem = {}
SLASystem.__index = SLASystem

-- Create new SLA system
function SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    local self = setmetatable({}, SLASystem)
    
    self.eventBus = eventBus
    self.contractSystem = contractSystem
    self.resourceManager = resourceManager
    self.dataManager = dataManager
    
    -- SLA tracking per contract
    self.contractSLAs = {}
    
    -- SLA configuration (loaded from JSON or defaults)
    self.config = {
        complianceThresholds = {
            excellent = 0.95,
            good = 0.85,
            acceptable = 0.75,
            poor = 0.60
        },
        penaltyMultipliers = {
            minor = 0.1,
            moderate = 0.25,
            severe = 0.5,
            critical = 1.0
        },
        rewardMultipliers = {
            excellent = 1.5,
            good = 1.2,
            acceptable = 1.0
        }
    }
    
    -- Overall SLA metrics
    self.metrics = {
        totalContracts = 0,
        compliantContracts = 0,
        breachedContracts = 0,
        totalRewards = 0,
        totalPenalties = 0,
        overallComplianceRate = 1.0
    }
    
    return self
end

-- Initialize SLA system
function SLASystem:initialize()
    print("📊 SLASystem: Initializing...")
    
    -- Load SLA configuration from data manager if available
    if self.dataManager then
        local slaConfig = self.dataManager:getData("sla_config")
        if slaConfig then
            -- Merge loaded config with defaults
            for key, value in pairs(slaConfig) do
                self.config[key] = value
            end
            print("📊 SLASystem: Loaded configuration from sla_config.json")
        end
    end
    
    -- Subscribe to contract events
    self.eventBus:subscribe("contract_accepted", function(data)
        self:onContractAccepted(data)
    end)
    
    self.eventBus:subscribe("contract_completed", function(data)
        self:onContractCompleted(data)
    end)
    
    self.eventBus:subscribe("contract_failed", function(data)
        self:onContractFailed(data)
    end)
    
    print("📊 SLASystem: Initialized")
end

-- Handle contract acceptance
function SLASystem:onContractAccepted(data)
    local contract = data.contract
    if not contract then return end
    
    -- Initialize SLA tracking for this contract
    self.contractSLAs[contract.id] = {
        contractId = contract.id,
        startTime = love.timer.getTime(),
        slaRequirements = contract.slaRequirements or {},
        incidentCount = 0,
        breachCount = 0,
        complianceScore = 1.0,
        active = true
    }
    
    print("📊 SLASystem: Tracking started for contract " .. contract.id)
end

-- Handle contract completion
function SLASystem:onContractCompleted(data)
    local contract = data.contract
    if not contract or not self.contractSLAs[contract.id] then return end
    
    local slaTracker = self.contractSLAs[contract.id]
    slaTracker.active = false
    slaTracker.endTime = love.timer.getTime()
    
    -- Calculate final compliance score
    local complianceScore = self:calculateComplianceScore(slaTracker)
    slaTracker.complianceScore = complianceScore
    
    -- Update metrics
    self.metrics.totalContracts = self.metrics.totalContracts + 1
    if complianceScore >= self.config.complianceThresholds.acceptable then
        self.metrics.compliantContracts = self.metrics.compliantContracts + 1
    else
        self.metrics.breachedContracts = self.metrics.breachedContracts + 1
    end
    
    -- Calculate and apply rewards/penalties
    local rewards, penalties = self:calculateRewardsAndPenalties(contract, slaTracker)
    
    if rewards > 0 then
        self.metrics.totalRewards = self.metrics.totalRewards + rewards
        self.eventBus:publish("sla_bonus_earned", {
            contractId = contract.id,
            amount = rewards,
            complianceScore = complianceScore
        })
    end
    
    if penalties > 0 then
        self.metrics.totalPenalties = self.metrics.totalPenalties + penalties
        self.eventBus:publish("sla_penalty_applied", {
            contractId = contract.id,
            amount = penalties,
            complianceScore = complianceScore
        })
    end
    
    -- Update overall compliance rate
    self:updateOverallCompliance()
    
    -- MEMORY LEAK FIX: Clean up old tracker after finalization
    -- Keep it briefly for history, then remove
    self.eventBus:publish("sla_finalized", {
        contractId = contract.id,
        complianceScore = complianceScore,
        rewards = rewards,
        penalties = penalties
    })
    
    -- Remove tracker after a delay (allow other systems to read it first)
    -- In a real implementation, you might move to a history table instead
    -- For now, we'll keep the last 100 completed trackers
    local completedTrackers = {}
    for id, tracker in pairs(self.contractSLAs) do
        if not tracker.active then
            table.insert(completedTrackers, {id = id, endTime = tracker.endTime or 0})
        end
    end
    
    -- Sort by end time and remove oldest if we have too many
    if #completedTrackers > 100 then
        table.sort(completedTrackers, function(a, b) return a.endTime < b.endTime end)
        for i = 1, #completedTrackers - 100 do
            self.contractSLAs[completedTrackers[i].id] = nil
        end
    end
    
    print(string.format("📊 SLASystem: Contract %s completed with %.1f%% compliance", 
        contract.id, complianceScore * 100))
end

-- Handle contract failure
function SLASystem:onContractFailed(data)
    local contract = data.contract
    if not contract or not self.contractSLAs[contract.id] then return end
    
    local slaTracker = self.contractSLAs[contract.id]
    slaTracker.active = false
    slaTracker.complianceScore = 0.0
    
    -- Update metrics
    self.metrics.totalContracts = self.metrics.totalContracts + 1
    self.metrics.breachedContracts = self.metrics.breachedContracts + 1
    
    -- Apply failure penalties if defined
    if contract.penalties and contract.penalties.contractTerminationPenalty then
        self.metrics.totalPenalties = self.metrics.totalPenalties + contract.penalties.contractTerminationPenalty
    end
    
    self:updateOverallCompliance()
    
    -- MEMORY LEAK FIX: Finalize and allow cleanup
    self.eventBus:publish("sla_finalized", {
        contractId = contract.id,
        complianceScore = 0.0,
        rewards = 0,
        penalties = contract.penalties and contract.penalties.contractTerminationPenalty or 0
    })
    
    print("📊 SLASystem: Contract " .. contract.id .. " failed - severe SLA breach")
end

-- Calculate compliance score for a contract
function SLASystem:calculateComplianceScore(slaTracker)
    if not slaTracker or not slaTracker.slaRequirements then
        return 1.0 -- No SLA requirements means perfect compliance
    end
    
    local requirements = slaTracker.slaRequirements
    local score = 1.0
    
    -- Check incident count against max allowed
    if requirements.maxAllowedIncidents then
        if slaTracker.incidentCount > requirements.maxAllowedIncidents then
            local overageRatio = (slaTracker.incidentCount - requirements.maxAllowedIncidents) / requirements.maxAllowedIncidents
            score = score * math.max(0.5, 1.0 - overageRatio * 0.3)
        end
    end
    
    -- Factor in breach count
    if slaTracker.breachCount > 0 then
        score = score * math.max(0.3, 1.0 - slaTracker.breachCount * 0.15)
    end
    
    return math.max(0.0, math.min(1.0, score))
end

-- Calculate rewards and penalties based on SLA performance
function SLASystem:calculateRewardsAndPenalties(contract, slaTracker)
    local rewards = 0
    local penalties = 0
    
    if not contract.rewards and not contract.penalties then
        return rewards, penalties
    end
    
    local complianceScore = slaTracker.complianceScore
    
    -- Calculate rewards for good performance
    if complianceScore >= self.config.complianceThresholds.excellent then
        if contract.rewards and contract.rewards.perfectPerformanceBonus then
            rewards = rewards + contract.rewards.perfectPerformanceBonus
        end
        if contract.rewards and contract.rewards.slaComplianceBonus then
            rewards = rewards + contract.rewards.slaComplianceBonus
        end
    elseif complianceScore >= self.config.complianceThresholds.good then
        if contract.rewards and contract.rewards.slaComplianceBonus then
            rewards = rewards + contract.rewards.slaComplianceBonus * 0.7
        end
    end
    
    -- Calculate penalties for poor performance
    if complianceScore < self.config.complianceThresholds.acceptable then
        if contract.penalties and contract.penalties.slaBreachFine then
            local penaltyMultiplier = 1.0 - complianceScore
            penalties = penalties + contract.penalties.slaBreachFine * penaltyMultiplier
        end
    end
    
    return rewards, penalties
end

-- Update overall compliance rate
function SLASystem:updateOverallCompliance()
    if self.metrics.totalContracts > 0 then
        self.metrics.overallComplianceRate = self.metrics.compliantContracts / self.metrics.totalContracts
    end
end

-- Record an incident for a contract
function SLASystem:recordIncident(contractId, incidentType)
    local slaTracker = self.contractSLAs[contractId]
    if not slaTracker or not slaTracker.active then return end
    
    slaTracker.incidentCount = slaTracker.incidentCount + 1
    
    -- Check if this exceeds SLA limits
    if slaTracker.slaRequirements.maxAllowedIncidents then
        if slaTracker.incidentCount > slaTracker.slaRequirements.maxAllowedIncidents then
            slaTracker.breachCount = slaTracker.breachCount + 1
            self.eventBus:publish("sla_breach", {
                contractId = contractId,
                reason = "Exceeded maximum allowed incidents",
                incidentCount = slaTracker.incidentCount
            })
        end
    end
end

-- Get SLA status for a contract
function SLASystem:getContractSLA(contractId)
    return self.contractSLAs[contractId]
end

-- Get overall metrics
function SLASystem:getMetrics()
    return self.metrics
end

-- Get compliance rating
function SLASystem:getComplianceRating(score)
    if score >= self.config.complianceThresholds.excellent then
        return "EXCELLENT"
    elseif score >= self.config.complianceThresholds.good then
        return "GOOD"
    elseif score >= self.config.complianceThresholds.acceptable then
        return "ACCEPTABLE"
    elseif score >= self.config.complianceThresholds.poor then
        return "POOR"
    else
        return "CRITICAL"
    end
end

-- State management for save/load
function SLASystem:getState()
    return {
        contractSLAs = self.contractSLAs,
        metrics = self.metrics,
        config = self.config
    }
end

function SLASystem:loadState(state)
    if state.contractSLAs then
        self.contractSLAs = state.contractSLAs
    end
    if state.metrics then
        self.metrics = state.metrics
    end
    if state.config then
        self.config = state.config
    end
end

return SLASystem
