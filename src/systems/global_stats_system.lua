-- Global Statistics Tracking System
-- Tracks company-wide performance metrics for SOC simulation
-- Provides analytics data for UI dashboard
-- Part of Phase 3: Global Stats System Implementation

local GlobalStatsSystem = {}
GlobalStatsSystem.__index = GlobalStatsSystem

function GlobalStatsSystem.new(eventBus, resourceManager)
    local self = setmetatable({}, GlobalStatsSystem)
    
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Company statistics
    self.stats = {
        company = {
            name = "Your SOC",
            tier = "STARTUP",  -- STARTUP | GROWING | ESTABLISHED | ENTERPRISE | CORPORATION
            foundedDate = os.time(),
            daysOperating = 0
        },
        
        contracts = {
            totalCompleted = 0,
            totalActive = 0,
            totalFailed = 0,
            totalRevenue = 0,
            averageSLACompliance = 0,
            highestTierCompleted = 0,
            currentStreak = 0,  -- Consecutive successful contracts
            bestStreak = 0
        },
        
        specialists = {
            totalHired = 0,
            totalActive = 0,
            totalRetired = 0,
            averageLevel = 0,
            averageEfficiency = 0,
            totalXPEarned = 0
        },
        
        incidents = {
            totalGenerated = 0,
            totalHandled = 0,
            totalResolved = 0,
            totalFailed = 0,
            totalAutoResolved = 0,
            averageResolutionTime = 0,
            totalResolutionTime = 0,
            fastestResolution = 999999,
            slowestResolution = 0
        },
        
        performance = {
            currentSLACompliance = 1.0,
            lifetimeSLACompliance = 1.0,
            reputationTrend = "STABLE",  -- RISING | STABLE | FALLING
            financialHealth = "GOOD",    -- EXCELLENT | GOOD | FAIR | POOR | CRITICAL
            workloadStatus = "OPTIMAL",  -- OPTIMAL | HIGH | CRITICAL | OVERLOADED
            efficiencyRating = 1.0       -- Overall company efficiency (0-1)
        },
        
        milestones = {
            firstContract = false,
            first10Contracts = false,
            first100Incidents = false,
            perfectContract = false,
            hire10Specialists = false,
            reach1MRevenue = false
        }
    }
    
    -- Performance tracking
    self.lastUpdateTime = nil
    self.lastReputation = nil
    
    print("📊 GlobalStatsSystem: Initialized")
    
    return self
end

function GlobalStatsSystem:initialize()
    -- Subscribe to contract events
    self.eventBus:subscribe("contract_completed", function(data)
        self:onContractCompleted(data)
    end)
    
    self.eventBus:subscribe("contract_failed", function(data)
        self:onContractFailed(data)
    end)
    
    self.eventBus:subscribe("contract_accepted", function(data)
        self:onContractActivated(data)
    end)
    
    -- Subscribe to incident events
    self.eventBus:subscribe("incident_fully_resolved", function(data)
        self:onIncidentResolved(data)
    end)
    
    self.eventBus:subscribe("incident_failed", function(data)
        self:onIncidentFailed(data)
    end)
    
    self.eventBus:subscribe("incident_auto_resolved", function(data)
        self:onIncidentAutoResolved(data)
    end)
    
    self.eventBus:subscribe("incident_escalated", function(data)
        self:onIncidentGenerated(data)
    end)
    
    -- Subscribe to specialist events
    self.eventBus:subscribe("specialist_hired", function(data)
        self:onSpecialistHired(data)
    end)
    
    self.eventBus:subscribe("specialist_unlocked", function(data)
        self:onSpecialistUnlocked(data)
    end)
    
    -- Subscribe to SLA events
    self.eventBus:subscribe("sla_finalized", function(data)
        self:onSLAFinalized(data)
    end)
    
    print("📊 GlobalStatsSystem: Event subscriptions registered")
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function GlobalStatsSystem:onContractCompleted(data)
    self.stats.contracts.totalCompleted = self.stats.contracts.totalCompleted + 1
    
    -- Update streak
    self.stats.contracts.currentStreak = self.stats.contracts.currentStreak + 1
    if self.stats.contracts.currentStreak > self.stats.contracts.bestStreak then
        self.stats.contracts.bestStreak = self.stats.contracts.currentStreak
    end
    
    -- Update tier tracking
    if data.tier and data.tier > self.stats.contracts.highestTierCompleted then
        self.stats.contracts.highestTierCompleted = data.tier
    end
    
    -- Update revenue
    if data.revenue then
        self.stats.contracts.totalRevenue = self.stats.contracts.totalRevenue + data.revenue
    end
    
    -- Check milestones
    self:checkMilestones()
    
    print(string.format("📊 Contract completed. Total: %d, Streak: %d",
        self.stats.contracts.totalCompleted,
        self.stats.contracts.currentStreak))
end

function GlobalStatsSystem:onContractFailed(data)
    self.stats.contracts.totalFailed = self.stats.contracts.totalFailed + 1
    self.stats.contracts.currentStreak = 0  -- Break streak
    
    print(string.format("📊 Contract failed. Total failures: %d",
        self.stats.contracts.totalFailed))
end

function GlobalStatsSystem:onContractActivated(data)
    self.stats.contracts.totalActive = self.stats.contracts.totalActive + 1
end

function GlobalStatsSystem:onIncidentResolved(data)
    self.stats.incidents.totalHandled = self.stats.incidents.totalHandled + 1
    self.stats.incidents.totalResolved = self.stats.incidents.totalResolved + 1
    
    -- Update resolution time statistics
    if data.totalDuration then
        self.stats.incidents.totalResolutionTime = 
            self.stats.incidents.totalResolutionTime + data.totalDuration
        
        if data.totalDuration < self.stats.incidents.fastestResolution then
            self.stats.incidents.fastestResolution = data.totalDuration
        end
        
        if data.totalDuration > self.stats.incidents.slowestResolution then
            self.stats.incidents.slowestResolution = data.totalDuration
        end
        
        -- Calculate average
        self.stats.incidents.averageResolutionTime = 
            self.stats.incidents.totalResolutionTime / self.stats.incidents.totalResolved
    end
    
    -- Check milestones
    self:checkMilestones()
end

function GlobalStatsSystem:onIncidentFailed(data)
    self.stats.incidents.totalHandled = self.stats.incidents.totalHandled + 1
    self.stats.incidents.totalFailed = self.stats.incidents.totalFailed + 1
end

function GlobalStatsSystem:onIncidentAutoResolved(data)
    self.stats.incidents.totalAutoResolved = self.stats.incidents.totalAutoResolved + 1
end

function GlobalStatsSystem:onIncidentGenerated(data)
    self.stats.incidents.totalGenerated = self.stats.incidents.totalGenerated + 1
end

function GlobalStatsSystem:onSpecialistHired(data)
    self.stats.specialists.totalHired = self.stats.specialists.totalHired + 1
    self.stats.specialists.totalActive = self.stats.specialists.totalActive + 1
    
    -- Check milestones
    self:checkMilestones()
end

function GlobalStatsSystem:onSpecialistUnlocked(data)
    -- Also counts as hired
    self:onSpecialistHired(data)
end

function GlobalStatsSystem:onSLAFinalized(data)
    if data.complianceScore then
        -- Update current SLA compliance (weighted average)
        local totalContracts = self.stats.contracts.totalCompleted + self.stats.contracts.totalFailed
        if totalContracts > 0 then
            local weight = 1.0 / totalContracts
            self.stats.performance.currentSLACompliance = 
                (self.stats.performance.lifetimeSLACompliance * (totalContracts - 1) + data.complianceScore) / totalContracts
            self.stats.performance.lifetimeSLACompliance = self.stats.performance.currentSLACompliance
        end
    end
end

-- ============================================================================
-- PERFORMANCE ANALYSIS
-- ============================================================================

function GlobalStatsSystem:update(dt)
    -- Periodic performance analysis (every 5 seconds)
    if not self.lastUpdateTime then
        self.lastUpdateTime = love.timer.getTime()
    end
    
    local currentTime = love.timer.getTime()
    if currentTime - self.lastUpdateTime >= 5.0 then
        self.lastUpdateTime = currentTime
        self:updatePerformanceMetrics()
    end
end

function GlobalStatsSystem:updatePerformanceMetrics()
    -- Update reputation trend
    if self.resourceManager then
        local reputation = self.resourceManager:getResource("reputation") or 0
        if not self.lastReputation then
            self.lastReputation = reputation
        end
        
        local repChange = reputation - self.lastReputation
        if repChange > 5 then
            self.stats.performance.reputationTrend = "RISING"
        elseif repChange < -5 then
            self.stats.performance.reputationTrend = "FALLING"
        else
            self.stats.performance.reputationTrend = "STABLE"
        end
        
        self.lastReputation = reputation
        
        -- Update financial health
        local money = self.resourceManager:getResource("money") or 0
        if money > 100000 then
            self.stats.performance.financialHealth = "EXCELLENT"
        elseif money > 50000 then
            self.stats.performance.financialHealth = "GOOD"
        elseif money > 10000 then
            self.stats.performance.financialHealth = "FAIR"
        elseif money > 1000 then
            self.stats.performance.financialHealth = "POOR"
        else
            self.stats.performance.financialHealth = "CRITICAL"
        end
    end
    
    -- Update efficiency rating
    self.stats.performance.efficiencyRating = self:calculateEfficiencyRating()
    
    -- Update workload status
    self:updateWorkloadStatus()
    
    -- Update company tier based on metrics
    self:updateCompanyTier()
end

function GlobalStatsSystem:calculateEfficiencyRating()
    -- Efficiency = (Incidents Resolved / Total Incidents) * SLA Compliance
    local total = self.stats.incidents.totalHandled
    if total == 0 then return 1.0 end
    
    local successRate = self.stats.incidents.totalResolved / total
    local efficiency = successRate * self.stats.performance.currentSLACompliance
    
    return math.min(1.0, math.max(0.0, efficiency))
end

function GlobalStatsSystem:updateWorkloadStatus()
    -- Determine workload status based on active contracts and specialists
    local contracts = self.stats.contracts.totalActive
    local specialists = self.stats.specialists.totalActive
    
    if specialists == 0 then
        self.stats.performance.workloadStatus = "CRITICAL"
        return
    end
    
    local ratio = contracts / specialists
    
    if ratio <= 0.5 then
        self.stats.performance.workloadStatus = "OPTIMAL"
    elseif ratio <= 1.0 then
        self.stats.performance.workloadStatus = "HIGH"
    elseif ratio <= 1.5 then
        self.stats.performance.workloadStatus = "CRITICAL"
    else
        self.stats.performance.workloadStatus = "OVERLOADED"
    end
end

function GlobalStatsSystem:updateCompanyTier()
    local completed = self.stats.contracts.totalCompleted
    local specialists = self.stats.specialists.totalActive
    
    if completed >= 100 and specialists >= 20 then
        self.stats.company.tier = "CORPORATION"
    elseif completed >= 50 and specialists >= 10 then
        self.stats.company.tier = "ENTERPRISE"
    elseif completed >= 25 and specialists >= 7 then
        self.stats.company.tier = "ESTABLISHED"
    elseif completed >= 10 and specialists >= 4 then
        self.stats.company.tier = "GROWING"
    else
        self.stats.company.tier = "STARTUP"
    end
end

function GlobalStatsSystem:checkMilestones()
    -- Check and unlock milestones
    if self.stats.contracts.totalCompleted >= 1 and not self.stats.milestones.firstContract then
        self.stats.milestones.firstContract = true
        self:unlockMilestone("firstContract", "First Contract Completed!")
    end
    
    if self.stats.contracts.totalCompleted >= 10 and not self.stats.milestones.first10Contracts then
        self.stats.milestones.first10Contracts = true
        self:unlockMilestone("first10Contracts", "10 Contracts Completed!")
    end
    
    if self.stats.incidents.totalResolved >= 100 and not self.stats.milestones.first100Incidents then
        self.stats.milestones.first100Incidents = true
        self:unlockMilestone("first100Incidents", "100 Incidents Resolved!")
    end
    
    if self.stats.specialists.totalHired >= 10 and not self.stats.milestones.hire10Specialists then
        self.stats.milestones.hire10Specialists = true
        self:unlockMilestone("hire10Specialists", "Hired 10 Specialists!")
    end
    
    if self.stats.contracts.totalRevenue >= 1000000 and not self.stats.milestones.reach1MRevenue then
        self.stats.milestones.reach1MRevenue = true
        self:unlockMilestone("reach1MRevenue", "Reached $1M Revenue!")
    end
end

function GlobalStatsSystem:unlockMilestone(id, name)
    print(string.format("🏆 MILESTONE UNLOCKED: %s", name))
    
    if self.eventBus then
        self.eventBus:publish("milestone_unlocked", {
            id = id,
            name = name
        })
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function GlobalStatsSystem:getStats()
    return self.stats
end

function GlobalStatsSystem:getCompanyInfo()
    return self.stats.company
end

function GlobalStatsSystem:getContractStats()
    return self.stats.contracts
end

function GlobalStatsSystem:getSpecialistStats()
    return self.stats.specialists
end

function GlobalStatsSystem:getIncidentStats()
    return self.stats.incidents
end

function GlobalStatsSystem:getPerformanceMetrics()
    return self.stats.performance
end

function GlobalStatsSystem:getMilestones()
    return self.stats.milestones
end

-- Calculate success rate percentage
function GlobalStatsSystem:getSuccessRate()
    local total = self.stats.incidents.totalResolved + self.stats.incidents.totalFailed
    if total == 0 then return 100 end
    return (self.stats.incidents.totalResolved / total) * 100
end

-- Calculate contract success rate
function GlobalStatsSystem:getContractSuccessRate()
    local total = self.stats.contracts.totalCompleted + self.stats.contracts.totalFailed
    if total == 0 then return 100 end
    return (self.stats.contracts.totalCompleted / total) * 100
end

-- Get formatted dashboard data for UI
function GlobalStatsSystem:getDashboardData()
    return {
        overview = {
            companyName = self.stats.company.name,
            tier = self.stats.company.tier,
            daysOperating = self.stats.company.daysOperating
        },
        
        keyMetrics = {
            {
                label = "Active Contracts",
                value = self.stats.contracts.totalActive,
                trend = self.stats.contracts.currentStreak > 0 and "up" or "neutral"
            },
            {
                label = "SLA Compliance",
                value = string.format("%.1f%%", self.stats.performance.currentSLACompliance * 100),
                trend = self.stats.performance.currentSLACompliance > 0.85 and "up" or "down"
            },
            {
                label = "Success Rate",
                value = string.format("%.1f%%", self:getSuccessRate()),
                trend = "neutral"
            },
            {
                label = "Total Revenue",
                value = "$" .. self:formatNumber(self.stats.contracts.totalRevenue),
                trend = "up"
            }
        },
        
        recentActivity = {
            contractsCompleted = self.stats.contracts.totalCompleted,
            incidentsResolved = self.stats.incidents.totalResolved,
            currentStreak = self.stats.contracts.currentStreak
        },
        
        performance = {
            slaCompliance = self.stats.performance.currentSLACompliance,
            reputationTrend = self.stats.performance.reputationTrend,
            financialHealth = self.stats.performance.financialHealth,
            workloadStatus = self.stats.performance.workloadStatus
        }
    }
end

function GlobalStatsSystem:formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

function GlobalStatsSystem:getState()
    return {
        stats = self.stats,
        lastReputation = self.lastReputation,
        lastUpdateTime = self.lastUpdateTime
    }
end

function GlobalStatsSystem:loadState(state)
    if state and state.stats then
        self.stats = state.stats
        self.lastReputation = state.lastReputation
        self.lastUpdateTime = state.lastUpdateTime
        
        print(string.format("📊 GlobalStatsSystem: Loaded state - %d contracts completed, %d incidents resolved",
            self.stats.contracts.totalCompleted,
            self.stats.incidents.totalResolved))
    end
end

return GlobalStatsSystem
