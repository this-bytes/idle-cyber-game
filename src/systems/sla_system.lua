-- SLA (Service Level Agreement) Management System
-- Tracks contract SLA requirements, monitors performance, detects breaches
-- Part of SOC Simulation implementation
-- See: docs/SOC_SIMULATION_IMPLEMENTATION_PLAN.md

local SLASystem = {}
SLASystem.__index = SLASystem

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    local self = setmetatable({}, SLASystem)
    
    self.eventBus = eventBus
    self.contractSystem = contractSystem
    self.resourceManager = resourceManager
    self.dataManager = dataManager
    
    -- SLA Trackers: contractId -> SLATracker
    self.slaTrackers = {}
    
    -- Configuration loaded from JSON
    self.config = nil
    
    print("📊 SLASystem: Initialized")
    
    return self
end

function SLASystem:initialize()
    -- Load SLA configuration
    self:loadConfiguration()
    
    -- Subscribe to contract lifecycle events
    self.eventBus:subscribe("contract_activated", function(data)
        self:initializeSLATracking(data.contractId)
    end)
    
    self.eventBus:subscribe("contract_completed", function(data)
        self:finalizeContractSLA(data.contractId)
    end)
    
    self.eventBus:subscribe("contract_cancelled", function(data)
        self:cleanupSLATracking(data.contractId)
    end)
    
    -- Subscribe to incident lifecycle events
    self.eventBus:subscribe("incident_stage_completed", function(data)
        self:updateSLAPerformance(data)
    end)
    
    self.eventBus:subscribe("incident_fully_resolved", function(data)
        self:recordIncidentSuccess(data)
    end)
    
    self.eventBus:subscribe("incident_failed", function(data)
        self:recordIncidentFailure(data)
    end)
    
    print("📊 SLASystem: Event subscriptions registered")
end

function SLASystem:loadConfiguration()
    -- Try to load from sla_config.json
    local configData = self.dataManager and self.dataManager:getData("sla_config")
    
    if configData then
        self.config = configData
        print("📊 SLASystem: Loaded configuration from sla_config.json")
    else
        -- Use default configuration
        self.config = self:getDefaultConfiguration()
        print("📊 SLASystem: Using default configuration")
    end
end

function SLASystem:getDefaultConfiguration()
    return {
        defaultSLA = {
            detectionTimeSLA = 45,
            responseTimeSLA = 180,
            resolutionTimeSLA = 600,
            minimumSuccessRate = 0.85
        },
        tierMultipliers = {
            [1] = 1.5,  -- Tier 1: 50% more time allowed
            [2] = 1.2,  -- Tier 2: 20% more time
            [3] = 1.0,  -- Tier 3: Standard
            [4] = 0.8,  -- Tier 4: 20% less time
            [5] = 0.6   -- Tier 5: 40% less time
        },
        performanceBands = {
            excellent = {threshold = 0.95, bonusMultiplier = 1.5},
            good = {threshold = 0.85, bonusMultiplier = 1.0},
            acceptable = {threshold = 0.75, bonusMultiplier = 0.5},
            poor = {threshold = 0.0, penaltyMultiplier = 1.5}
        }
    }
end

-- ============================================================================
-- SLA TRACKING
-- ============================================================================

function SLASystem:initializeSLATracking(contractId)
    local contract = self.contractSystem:getContract(contractId)
    if not contract then
        print("⚠️  SLASystem: Contract not found:", contractId)
        return
    end
    
    -- Get SLA requirements from contract or use defaults
    local slaRequirements = contract.slaRequirements or self.config.defaultSLA
    
    -- Create SLA tracker
    self.slaTrackers[contractId] = {
        contractId = contractId,
        slaRequirements = slaRequirements,
        performance = {
            incidentsHandled = 0,
            incidentsPassed = 0,
            incidentsFailed = 0,
            totalDetectionTime = 0,
            totalResponseTime = 0,
            totalResolutionTime = 0,
            averageDetectionTime = 0,
            averageResponseTime = 0,
            averageResolutionTime = 0,
            complianceScore = 1.0
        },
        status = "COMPLIANT",  -- COMPLIANT | AT_RISK | BREACHED
        warningsSent = 0,
        lastUpdateTime = love.timer.getTime()
    }
    
    print(string.format("📊 SLASystem: Initialized tracking for contract %s", contractId))
    
    -- Publish initialization event
    self.eventBus:publish("sla_tracking_initialized", {
        contractId = contractId,
        slaRequirements = slaRequirements
    })
end

function SLASystem:updateSLAPerformance(data)
    local tracker = self.slaTrackers[data.contractId]
    if not tracker then
        print("⚠️  SLASystem: No tracker found for contract:", data.contractId)
        return
    end
    
    -- Update timing statistics based on stage
    if data.stage == "detect" then
        tracker.performance.totalDetectionTime = tracker.performance.totalDetectionTime + data.duration
    elseif data.stage == "respond" then
        tracker.performance.totalResponseTime = tracker.performance.totalResponseTime + data.duration
    elseif data.stage == "resolve" then
        tracker.performance.totalResolutionTime = tracker.performance.totalResolutionTime + data.duration
    end
    
    -- Update compliance tracking
    if data.slaCompliant then
        tracker.performance.incidentsPassed = tracker.performance.incidentsPassed + 1
    else
        tracker.performance.incidentsFailed = tracker.performance.incidentsFailed + 1
    end
    
    tracker.performance.incidentsHandled = tracker.performance.incidentsPassed + tracker.performance.incidentsFailed
    
    -- Calculate averages
    if tracker.performance.incidentsHandled > 0 then
        tracker.performance.averageDetectionTime = tracker.performance.totalDetectionTime / tracker.performance.incidentsHandled
        tracker.performance.averageResponseTime = tracker.performance.totalResponseTime / tracker.performance.incidentsHandled
        tracker.performance.averageResolutionTime = tracker.performance.totalResolutionTime / tracker.performance.incidentsHandled
    end
    
    -- Update compliance score
    self:updateComplianceScore(tracker)
    
    -- Check and update status
    self:checkSLAStatus(tracker)
    
    -- Publish performance update event
    self.eventBus:publish("sla_performance_updated", {
        contractId = data.contractId,
        performance = tracker.performance,
        status = tracker.status
    })
end

function SLASystem:recordIncidentSuccess(data)
    local tracker = self.slaTrackers[data.contractId]
    if not tracker then return end
    
    -- Already tracked by stage completion events
    -- This is for logging/analytics
    print(string.format("✅ SLASystem: Incident %s resolved successfully for contract %s", 
        data.incidentId, data.contractId))
end

function SLASystem:recordIncidentFailure(data)
    local tracker = self.slaTrackers[data.contractId]
    if not tracker then return end
    
    -- Mark failure (may have already been counted in stage updates)
    tracker.performance.incidentsFailed = tracker.performance.incidentsFailed + 1
    tracker.performance.incidentsHandled = tracker.performance.incidentsPassed + tracker.performance.incidentsFailed
    
    self:updateComplianceScore(tracker)
    self:checkSLAStatus(tracker)
    
    print(string.format("❌ SLASystem: Incident %s failed for contract %s (Reason: %s)", 
        data.incidentId, data.contractId, data.reason or "unknown"))
end

-- ============================================================================
-- COMPLIANCE CALCULATIONS
-- ============================================================================

function SLASystem:updateComplianceScore(tracker)
    if tracker.performance.incidentsHandled == 0 then
        tracker.performance.complianceScore = 1.0
        return
    end
    
    -- Calculate success rate
    local successRate = tracker.performance.incidentsPassed / tracker.performance.incidentsHandled
    
    -- Factor in average timing compliance
    local timingCompliance = self:calculateTimingCompliance(tracker)
    
    -- Overall compliance is weighted average of success rate (70%) and timing (30%)
    tracker.performance.complianceScore = (successRate * 0.7) + (timingCompliance * 0.3)
end

function SLASystem:calculateTimingCompliance(tracker)
    local req = tracker.slaRequirements
    local perf = tracker.performance
    
    local detectionCompliance = 1.0
    local responseCompliance = 1.0
    local resolutionCompliance = 1.0
    
    if req.detectionTimeSLA and perf.averageDetectionTime > 0 then
        detectionCompliance = math.min(1.0, req.detectionTimeSLA / perf.averageDetectionTime)
    end
    
    if req.responseTimeSLA and perf.averageResponseTime > 0 then
        responseCompliance = math.min(1.0, req.responseTimeSLA / perf.averageResponseTime)
    end
    
    if req.resolutionTimeSLA and perf.averageResolutionTime > 0 then
        resolutionCompliance = math.min(1.0, req.resolutionTimeSLA / perf.averageResolutionTime)
    end
    
    -- Average of all three stages
    return (detectionCompliance + responseCompliance + resolutionCompliance) / 3
end

function SLASystem:checkSLAStatus(tracker)
    local previousStatus = tracker.status
    local score = tracker.performance.complianceScore
    local minRate = tracker.slaRequirements.minimumSuccessRate or 0.85
    
    -- Determine status
    if score < 0.70 then
        tracker.status = "BREACHED"
    elseif score < minRate then
        tracker.status = "AT_RISK"
    else
        tracker.status = "COMPLIANT"
    end
    
    -- Publish status change events
    if tracker.status ~= previousStatus then
        if tracker.status == "BREACHED" then
            self.eventBus:publish("sla_breached", {
                contractId = tracker.contractId,
                complianceScore = score,
                previousStatus = previousStatus
            })
            print(string.format("🚨 SLASystem: SLA BREACHED for contract %s (Score: %.2f)", 
                tracker.contractId, score))
        elseif tracker.status == "AT_RISK" then
            self.eventBus:publish("sla_at_risk", {
                contractId = tracker.contractId,
                complianceScore = score,
                warningLevel = self:getWarningLevel(score, minRate)
            })
            print(string.format("⚠️  SLASystem: SLA AT RISK for contract %s (Score: %.2f)", 
                tracker.contractId, score))
        elseif tracker.status == "COMPLIANT" and previousStatus ~= "COMPLIANT" then
            self.eventBus:publish("sla_recovered", {
                contractId = tracker.contractId,
                complianceScore = score,
                previousStatus = previousStatus
            })
            print(string.format("✅ SLASystem: SLA RECOVERED for contract %s (Score: %.2f)", 
                tracker.contractId, score))
        end
    end
end

function SLASystem:getWarningLevel(score, minRate)
    local shortfall = minRate - score
    if shortfall > 0.15 then
        return "SEVERE"
    elseif shortfall > 0.05 then
        return "MODERATE"
    else
        return "MINOR"
    end
end

-- ============================================================================
-- REWARDS AND PENALTIES
-- ============================================================================

function SLASystem:finalizeContractSLA(contractId)
    local tracker = self.slaTrackers[contractId]
    if not tracker then return end
    
    local contract = self.contractSystem:getContract(contractId)
    if not contract then return end
    
    print(string.format("📊 SLASystem: Finalizing SLA for contract %s", contractId))
    print(string.format("   Compliance Score: %.2f", tracker.performance.complianceScore))
    print(string.format("   Incidents Handled: %d", tracker.performance.incidentsHandled))
    print(string.format("   Success Rate: %.2f%%", 
        (tracker.performance.incidentsPassed / math.max(1, tracker.performance.incidentsHandled)) * 100))
    
    -- Calculate rewards or penalties
    if tracker.status == "COMPLIANT" then
        self:applyRewards(tracker, contract)
    elseif tracker.status == "BREACHED" then
        self:applyPenalties(tracker, contract)
    end
    
    -- Publish finalization event
    self.eventBus:publish("sla_finalized", {
        contractId = contractId,
        status = tracker.status,
        complianceScore = tracker.performance.complianceScore,
        performance = tracker.performance
    })
end

function SLASystem:applyRewards(tracker, contract)
    if not contract.rewards then return end
    
    local rewards = {
        money = 0,
        reputation = 0,
        bonuses = {}
    }
    
    local score = tracker.performance.complianceScore
    local minRate = tracker.slaRequirements.minimumSuccessRate or 0.85
    
    -- SLA Compliance Bonus
    if score >= minRate and contract.rewards.slaComplianceBonus then
        rewards.money = rewards.money + contract.rewards.slaComplianceBonus
        rewards.reputation = rewards.reputation + (contract.rewards.reputationBonus or 0)
        table.insert(rewards.bonuses, "SLA Compliance Bonus")
    end
    
    -- Perfect Performance Bonus
    if score >= 0.99 and contract.rewards.perfectPerformanceBonus then
        rewards.money = rewards.money + contract.rewards.perfectPerformanceBonus
        rewards.reputation = rewards.reputation + math.floor((contract.rewards.reputationBonus or 0) * 0.5)
        table.insert(rewards.bonuses, "Perfect Performance")
    end
    
    -- Excellence Bonus (95%+)
    if score >= 0.95 and score < 0.99 then
        local excellenceBonus = math.floor((contract.rewards.slaComplianceBonus or 0) * 0.5)
        rewards.money = rewards.money + excellenceBonus
        table.insert(rewards.bonuses, "Excellence Bonus")
    end
    
    -- Apply rewards
    if rewards.money > 0 then
        self.resourceManager:addResource("money", rewards.money)
    end
    if rewards.reputation > 0 then
        self.resourceManager:addResource("reputation", rewards.reputation)
    end
    
    -- Publish rewards event
    self.eventBus:publish("sla_rewards_applied", {
        contractId = tracker.contractId,
        rewards = rewards
    })
    
    print(string.format("💰 SLASystem: Applied rewards for contract %s", tracker.contractId))
    print(string.format("   Money: +$%d", rewards.money))
    print(string.format("   Reputation: +%d", rewards.reputation))
    if #rewards.bonuses > 0 then
        print(string.format("   Bonuses: %s", table.concat(rewards.bonuses, ", ")))
    end
end

function SLASystem:applyPenalties(tracker, contract)
    if not contract.penalties then return end
    
    local penalties = {
        money = 0,
        reputation = 0,
        consequences = {}
    }
    
    local score = tracker.performance.complianceScore
    local minRate = tracker.slaRequirements.minimumSuccessRate or 0.85
    local shortfall = minRate - score
    
    -- SLA Breach Fine
    if contract.penalties.slaBreachFine then
        penalties.money = math.floor(contract.penalties.slaBreachFine * math.max(shortfall, 0.3))
        penalties.reputation = math.floor((contract.penalties.reputationLoss or 0) * math.max(shortfall, 0.3))
        table.insert(penalties.consequences, "SLA Breach Fine")
    end
    
    -- Critical Failure (< 70%)
    if score < 0.70 and contract.penalties.contractTerminationPenalty then
        penalties.money = penalties.money + contract.penalties.contractTerminationPenalty
        penalties.reputation = penalties.reputation + math.floor((contract.penalties.reputationLoss or 0) * 0.5)
        table.insert(penalties.consequences, "Contract Terminated Early")
    end
    
    -- Apply penalties
    if penalties.money > 0 then
        self.resourceManager:removeResource("money", penalties.money)
    end
    if penalties.reputation > 0 then
        self.resourceManager:removeResource("reputation", penalties.reputation)
    end
    
    -- Publish penalties event
    self.eventBus:publish("sla_penalties_applied", {
        contractId = tracker.contractId,
        penalties = penalties
    })
    
    print(string.format("⚠️  SLASystem: Applied penalties for contract %s", tracker.contractId))
    print(string.format("   Money: -$%d", penalties.money))
    print(string.format("   Reputation: -%d", penalties.reputation))
    if #penalties.consequences > 0 then
        print(string.format("   Consequences: %s", table.concat(penalties.consequences, ", ")))
    end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function SLASystem:cleanupSLATracking(contractId)
    if self.slaTrackers[contractId] then
        print(string.format("📊 SLASystem: Cleaning up tracking for contract %s", contractId))
        self.slaTrackers[contractId] = nil
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SLASystem:getSLAStatus(contractId)
    local tracker = self.slaTrackers[contractId]
    if not tracker then return nil end
    
    return {
        status = tracker.status,
        complianceScore = tracker.performance.complianceScore,
        incidentsHandled = tracker.performance.incidentsHandled,
        incidentsPassed = tracker.performance.incidentsPassed,
        incidentsFailed = tracker.performance.incidentsFailed
    }
end

function SLASystem:getAllSLAStatuses()
    local statuses = {}
    for contractId, tracker in pairs(self.slaTrackers) do
        statuses[contractId] = self:getSLAStatus(contractId)
    end
    return statuses
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

function SLASystem:getState()
    return {
        slaTrackers = self.slaTrackers,
        config = self.config
    }
end

function SLASystem:loadState(state)
    if state then
        self.slaTrackers = state.slaTrackers or {}
        self.config = state.config or self:getDefaultConfiguration()
        print(string.format("📊 SLASystem: Loaded state with %d active trackers", 
            self:tableLength(self.slaTrackers)))
    end
end

function SLASystem:tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function SLASystem:update(dt)
    -- Periodic status checks (every 5 seconds)
    for contractId, tracker in pairs(self.slaTrackers) do
        local currentTime = love.timer.getTime()
        if currentTime - tracker.lastUpdateTime > 5.0 then
            tracker.lastUpdateTime = currentTime
            self:checkSLAStatus(tracker)
        end
    end
end

return SLASystem
