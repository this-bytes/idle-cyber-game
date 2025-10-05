# SOC Simulation Implementation Plan
## Comprehensive Architecture and Roadmap for SLA-Driven Contract Management

**Created**: October 5, 2025  
**Status**: Design Phase - Ready for Implementation  
**Architecture Compliance**: ✅ Follows Golden Path (src/systems + EventBus + JSON)

---

## 🎯 Executive Summary

This document provides a complete implementation plan for enhancing the Idle Cyber game with a comprehensive SOC (Security Operations Center) simulation featuring:

- **SLA-Based Contract Management**: Contracts with Service Level Agreements requiring specific performance metrics
- **Contract Capacity Limits**: Maximum contracts based on specialist capability and company stats
- **Three-Stage Incident Lifecycle**: Detect → Respond → Resolve with timing and skill requirements
- **Admin Mode**: Manual specialist assignment for tactical control
- **Reward/Penalty System**: SLA compliance drives reputation, finances, and progression
- **Global Stats Tracking**: Company-wide performance metrics and progression

### Design Philosophy

✅ **Event-Driven Architecture**: All inter-system communication via EventBus  
✅ **Data-Driven Design**: All configurations in JSON files  
✅ **Modular Systems**: Self-contained modules in `src/systems/`  
✅ **Extensible**: Easy to add new features without breaking existing code  
✅ **Testable**: Logic decoupled from UI for unit testing  

---

## 📋 Current State Analysis

### ✅ Existing Systems (Working)

1. **ContractSystem** (`src/systems/contract_system.lua`)
   - Generates and manages contracts
   - Basic income generation
   - Auto-accept functionality
   - **MISSING**: SLA tracking, capacity limits, performance metrics

2. **SpecialistSystem** (`src/systems/specialist_system.lua`)
   - Specialist hiring and management
   - XP and leveling system
   - Skills and abilities
   - **MISSING**: Workload calculation, assignment optimization

3. **IncidentSpecialistSystem** (`src/systems/incident_specialist_system.lua`)
   - Incident generation from threats
   - Basic specialist assignment
   - **MISSING**: Three-stage lifecycle, SLA timing, manual assignment

4. **ResourceManager** (`src/systems/resource_manager.lua`)
   - Tracks money, reputation, and other resources
   - **READY**: Can be extended with new reward/penalty logic

5. **GameStateEngine** (`src/systems/game_state_engine.lua`)
   - Orchestrates all systems
   - Save/load state management
   - **READY**: New systems can be registered easily

### ❌ Missing Components (To Be Built)

1. **SLASystem** - Dedicated SLA tracking and compliance checking
2. **Enhanced Contract Schema** - SLA requirements in JSON
3. **Incident Lifecycle Stages** - Detect/Respond/Resolve tracking
4. **Contract Capacity Algorithm** - Specialist-based limits
5. **Admin Mode UI** - Manual specialist assignment interface
6. **Reward/Penalty Calculator** - SLA-based outcomes

---

## 🏗️ System Architecture Design

### 1. SLA Management System

**File**: `src/systems/sla_system.lua`

```lua
-- Core Responsibilities:
-- 1. Track SLA requirements for each active contract
-- 2. Monitor incident resolution times against SLAs
-- 3. Detect SLA breaches and trigger penalties
-- 4. Calculate SLA compliance scores
-- 5. Publish events for rewards/penalties
```

**Key Data Structures**:

```lua
SLATracker = {
    contractId = "contract_123",
    slaRequirements = {
        detectionTimeSLA = 30,      -- seconds
        responseTimeSLA = 120,       -- seconds
        resolutionTimeSLA = 300,     -- seconds
        requiredSkillLevels = {
            detection = 5,
            response = 7,
            resolution = 10
        },
        minimumSuccessRate = 0.90    -- 90% of incidents must be resolved
    },
    performance = {
        incidentsHandled = 15,
        incidentsPassed = 13,
        incidentsFailed = 2,
        averageDetectionTime = 28.5,
        averageResponseTime = 115.3,
        averageResolutionTime = 285.7,
        complianceScore = 0.87       -- 87% compliance
    },
    status = "COMPLIANT" | "AT_RISK" | "BREACHED"
}
```

**Event Integration**:

```lua
-- Published Events:
-- sla_compliant: {contractId, score, bonusAmount}
-- sla_at_risk: {contractId, score, warningLevel}
-- sla_breached: {contractId, score, penaltyAmount}
-- sla_performance_updated: {contractId, performance}

-- Subscribed Events:
-- incident_stage_completed: Update timing metrics
-- incident_resolved: Update success rate
-- incident_failed: Update failure count
-- contract_activated: Initialize SLA tracking
-- contract_completed: Calculate final SLA score
```

---

### 2. Enhanced Contract Schema

**File**: `src/data/contracts.json` (additions)

```json
{
  "id": "enterprise_soc_contract",
  "type": "contract",
  "clientName": "Global Financial Services",
  "displayName": "24/7 SOC Operations",
  "description": "Provide round-the-clock security monitoring with strict SLA requirements.",
  "baseBudget": 50000,
  "baseDuration": 300,
  "reputationReward": 50,
  "riskLevel": "CRITICAL",
  
  "slaRequirements": {
    "detectionTimeSLA": 30,
    "responseTimeSLA": 120,
    "resolutionTimeSLA": 300,
    "requiredSkillLevels": {
      "detection": 8,
      "response": 10,
      "resolution": 12
    },
    "minimumSuccessRate": 0.95,
    "maxAllowedIncidents": 10
  },
  
  "capacityRequirements": {
    "minimumSpecialists": 3,
    "minimumTotalEfficiency": 25,
    "minimumTotalSpeed": 20,
    "requiredSkillCoverage": ["threat_hunting", "incident_response", "forensics"]
  },
  
  "rewards": {
    "slaComplianceBonus": 10000,
    "perfectPerformanceBonus": 5000,
    "reputationBonus": 25
  },
  
  "penalties": {
    "slaBreachFine": 15000,
    "contractTerminationPenalty": 30000,
    "reputationLoss": 50
  },
  
  "tier": 4,
  "rarity": "epic",
  "tags": ["enterprise", "24/7", "sla", "critical"]
}
```

**Contract Capacity Calculation**:

```lua
function ContractSystem:canAcceptContract(contract)
    local capacity = self:calculateContractCapacity()
    local required = contract.capacityRequirements
    
    -- Check specialist count
    if #self.specialistSystem.specialists < required.minimumSpecialists then
        return false, "Insufficient specialists"
    end
    
    -- Check total stats
    local totalStats = self:calculateTotalSpecialistStats()
    if totalStats.efficiency < required.minimumTotalEfficiency then
        return false, "Insufficient team efficiency"
    end
    
    -- Check skill coverage
    if not self:hasRequiredSkills(required.requiredSkillCoverage) then
        return false, "Missing required skills"
    end
    
    -- Check current workload
    local workloadCapacity = self:calculateWorkloadCapacity()
    if #self.activeContracts >= workloadCapacity then
        return false, "At maximum contract capacity"
    end
    
    return true, "Contract can be accepted"
end

function ContractSystem:calculateWorkloadCapacity()
    -- Base capacity: 1 contract per 5 specialists
    local baseCapacity = math.floor(#self.specialistSystem.specialists / 5)
    
    -- Efficiency multiplier: Higher avg efficiency = more capacity
    local avgEfficiency = self:getAverageSpecialistEfficiency()
    local efficiencyMultiplier = 1 + (avgEfficiency - 1) * 0.5
    
    -- Apply upgrades that increase contract capacity
    local upgradeBonus = self.upgradeSystem:getEffectValue("contract_capacity_bonus") or 0
    
    local totalCapacity = math.max(1, math.floor(baseCapacity * efficiencyMultiplier + upgradeBonus))
    
    return totalCapacity
end
```

---

### 3. Three-Stage Incident Lifecycle

**Enhanced Incident Structure**:

```lua
Incident = {
    id = "incident_456",
    threatId = "ransomware_attack",
    contractId = "contract_123",
    severity = 8,
    
    -- Lifecycle stages
    stages = {
        detect = {
            status = "COMPLETED" | "IN_PROGRESS" | "PENDING",
            startTime = 1696501234.5,
            endTime = 1696501256.3,
            duration = 21.8,
            slaLimit = 30,
            assignedSpecialists = {"spec_1"},
            success = true
        },
        respond = {
            status = "IN_PROGRESS",
            startTime = 1696501256.3,
            endTime = nil,
            duration = 0,
            slaLimit = 120,
            assignedSpecialists = {"spec_1", "spec_3"},
            success = nil
        },
        resolve = {
            status = "PENDING",
            startTime = nil,
            endTime = nil,
            duration = 0,
            slaLimit = 300,
            assignedSpecialists = {},
            success = nil
        }
    },
    
    currentStage = "respond",
    overallSuccess = nil,
    slaCompliant = nil
}
```

**Stage Progression Logic**:

```lua
function IncidentSpecialistSystem:updateIncidentStage(incident, dt)
    local stage = incident.stages[incident.currentStage]
    
    if stage.status == "IN_PROGRESS" then
        stage.duration = stage.duration + dt
        
        -- Calculate progress based on assigned specialists
        local progress = self:calculateStageProgress(incident, stage)
        
        -- Check if stage is complete
        if progress >= 1.0 then
            stage.status = "COMPLETED"
            stage.endTime = love.timer.getTime()
            stage.success = stage.duration <= stage.slaLimit
            
            -- Publish stage completion event
            self.eventBus:publish("incident_stage_completed", {
                incidentId = incident.id,
                contractId = incident.contractId,
                stage = incident.currentStage,
                duration = stage.duration,
                slaLimit = stage.slaLimit,
                slaCompliant = stage.success,
                specialists = stage.assignedSpecialists
            })
            
            -- Move to next stage
            self:advanceToNextStage(incident)
        end
    end
end

function IncidentSpecialistSystem:calculateStageProgress(incident, stage)
    local specialists = stage.assignedSpecialists
    if #specialists == 0 then return 0 end
    
    -- Get stage-specific stat requirements
    local statType = self:getRequiredStatForStage(incident.currentStage)
    -- detect -> "trace", respond -> "speed", resolve -> "efficiency"
    
    local totalStat = 0
    for _, specId in ipairs(specialists) do
        local spec = self:getSpecialist(specId)
        if spec then
            totalStat = totalStat + (spec[statType] or 1.0)
        end
    end
    
    -- Progress = (totalStat * timeDelta) / baseDifficulty
    local difficulty = incident.severity * 10
    local progress = (totalStat * stage.duration) / difficulty
    
    return math.min(1.0, progress)
end
```

---

### 4. Contract Capacity System

**Capacity Formula**:

```lua
MaxContracts = floor(
    (SpecialistCount / 5) * 
    EfficiencyMultiplier * 
    (1 + UpgradeBonuses)
)

EfficiencyMultiplier = 1 + (AvgSpecialistEfficiency - 1) * 0.5

Performance Degradation when Overloaded:
- At capacity: 100% performance
- 1 over capacity: 85% performance
- 2 over capacity: 70% performance
- 3+ over capacity: 50% performance
```

**Implementation**:

```lua
function ContractSystem:getPerformanceMultiplier()
    local capacity = self:calculateWorkloadCapacity()
    local activeCount = #self.activeContracts
    
    if activeCount <= capacity then
        return 1.0  -- Full performance
    end
    
    local overload = activeCount - capacity
    local degradation = 0.15 * overload  -- 15% penalty per contract over capacity
    
    return math.max(0.5, 1.0 - degradation)  -- Minimum 50% performance
end

-- Apply performance multiplier to all contract-related activities
function ContractSystem:generateIncome()
    local baseIncome = self:calculateBaseIncome()
    local performanceMultiplier = self:getPerformanceMultiplier()
    
    local actualIncome = baseIncome * performanceMultiplier
    
    -- Publish event
    self.eventBus:publish("contract_income_generated", {
        baseIncome = baseIncome,
        performanceMultiplier = performanceMultiplier,
        actualIncome = actualIncome
    })
    
    self.resourceManager:addResource("money", actualIncome)
end
```

---

### 5. Admin Mode Enhancement

**Admin Mode Features**:

1. **Manual Specialist Assignment**
   - View all active incidents with current status
   - Select specialist(s) to assign to specific incident stage
   - Override automatic assignment
   - See specialist workload and availability

2. **Performance Tracking**
   - Compare manual vs automatic assignment outcomes
   - Track SLA compliance for manually assigned incidents
   - Specialist efficiency ratings

3. **Tactical Control**
   - Ability to reassign specialists mid-incident
   - Priority flagging for critical incidents
   - Resource allocation optimization

**Admin Mode State**:

```lua
AdminMode = {
    enabled = false,
    currentIncidents = {},
    specialistAssignments = {},
    manualOverrides = {},
    performanceMetrics = {
        manualAssignments = 45,
        manualSuccessRate = 0.92,
        automaticAssignments = 120,
        automaticSuccessRate = 0.88
    }
}
```

**Admin Assignment Logic**:

```lua
function IncidentSpecialistSystem:manualAssignSpecialist(incidentId, specialistId, stage)
    -- Verify admin mode is enabled
    if not self.adminMode.enabled then
        return false, "Admin mode not enabled"
    end
    
    -- Verify specialist is available
    local specialist = self:getSpecialist(specialistId)
    if not specialist or specialist.status ~= "available" then
        return false, "Specialist not available"
    end
    
    -- Verify incident exists and stage is valid
    local incident = self:getIncident(incidentId)
    if not incident then
        return false, "Incident not found"
    end
    
    -- Assign specialist to stage
    local stageData = incident.stages[stage]
    table.insert(stageData.assignedSpecialists, specialistId)
    
    -- Mark as manual override
    self.adminMode.manualOverrides[incidentId] = self.adminMode.manualOverrides[incidentId] or {}
    table.insert(self.adminMode.manualOverrides[incidentId], {
        stage = stage,
        specialistId = specialistId,
        timestamp = love.timer.getTime()
    })
    
    -- Update specialist status
    specialist.status = "busy"
    specialist.assignedTo = incidentId
    
    -- Publish event
    self.eventBus:publish("specialist_manually_assigned", {
        incidentId = incidentId,
        specialistId = specialistId,
        stage = stage
    })
    
    return true, "Specialist assigned successfully"
end
```

---

### 6. Reward and Penalty System

**Reward Calculation**:

```lua
function SLASystem:calculateContractRewards(contractId)
    local contract = self.contractSystem:getContract(contractId)
    local performance = self.slaTrackers[contractId].performance
    
    local rewards = {
        money = 0,
        reputation = 0,
        bonuses = {}
    }
    
    -- Base contract payment
    rewards.money = contract.baseBudget
    rewards.reputation = contract.reputationReward
    
    -- SLA Compliance Bonus
    if performance.complianceScore >= contract.slaRequirements.minimumSuccessRate then
        rewards.money = rewards.money + contract.rewards.slaComplianceBonus
        rewards.reputation = rewards.reputation + contract.rewards.reputationBonus
        table.insert(rewards.bonuses, "SLA Compliant")
    end
    
    -- Perfect Performance Bonus
    if performance.complianceScore >= 1.0 then
        rewards.money = rewards.money + contract.rewards.perfectPerformanceBonus
        rewards.reputation = rewards.reputation + math.floor(contract.rewards.reputationBonus * 0.5)
        table.insert(rewards.bonuses, "Perfect Performance")
    end
    
    -- Early Completion Bonus
    if contract.remainingTime > contract.baseDuration * 0.2 then
        local earlyBonus = math.floor(contract.baseBudget * 0.15)
        rewards.money = rewards.money + earlyBonus
        table.insert(rewards.bonuses, "Early Completion")
    end
    
    return rewards
end
```

**Penalty Calculation**:

```lua
function SLASystem:calculateContractPenalties(contractId)
    local contract = self.contractSystem:getContract(contractId)
    local performance = self.slaTrackers[contractId].performance
    
    local penalties = {
        money = 0,
        reputation = 0,
        consequences = {}
    }
    
    -- SLA Breach Fine
    if performance.complianceScore < contract.slaRequirements.minimumSuccessRate then
        local shortfall = contract.slaRequirements.minimumSuccessRate - performance.complianceScore
        penalties.money = math.floor(contract.penalties.slaBreachFine * shortfall)
        penalties.reputation = math.floor(contract.penalties.reputationLoss * shortfall)
        table.insert(penalties.consequences, "SLA Breach")
    end
    
    -- Critical Failure (< 70% compliance)
    if performance.complianceScore < 0.70 then
        penalties.money = penalties.money + contract.penalties.contractTerminationPenalty
        penalties.reputation = penalties.reputation + math.floor(contract.penalties.reputationLoss * 0.5)
        table.insert(penalties.consequences, "Contract Terminated")
    end
    
    -- Excessive Incidents Failed
    if performance.incidentsFailed > contract.slaRequirements.maxAllowedIncidents then
        local excessFailed = performance.incidentsFailed - contract.slaRequirements.maxAllowedIncidents
        penalties.money = penalties.money + (excessFailed * 1000)
        table.insert(penalties.consequences, "Excessive Failures")
    end
    
    return penalties
end
```

---

### 7. Global Stats Tracking

**Global Stats Structure**:

```lua
GlobalStats = {
    company = {
        name = "Cyber Defense Corp",
        tier = "STARTUP" | "GROWING" | "ESTABLISHED" | "ENTERPRISE" | "CORPORATION",
        reputation = 150,
        totalFunds = 45000
    },
    contracts = {
        totalCompleted = 23,
        totalActive = 3,
        totalFailed = 2,
        averageSLACompliance = 0.88,
        highestTierCompleted = 3
    },
    specialists = {
        totalHired = 8,
        totalActive = 6,
        averageLevel = 4.2,
        averageEfficiency = 6.5
    },
    incidents = {
        totalHandled = 156,
        totalResolved = 142,
        totalFailed = 14,
        averageResolutionTime = 245.8
    },
    performance = {
        currentSLACompliance = 0.91,
        reputationTrend = "RISING",
        financialHealth = "GOOD",
        workloadStatus = "OPTIMAL" | "HIGH" | "CRITICAL"
    }
}
```

**Stats Update Events**:

```lua
-- Subscribe to all relevant events to update stats
eventBus:subscribe("contract_completed", updateContractStats)
eventBus:subscribe("specialist_hired", updateSpecialistStats)
eventBus:subscribe("incident_resolved", updateIncidentStats)
eventBus:subscribe("sla_performance_updated", updatePerformanceStats)
```

---

## 🗺️ Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
**Goal**: Establish core SLA and capacity systems

#### Tasks:

1. **Create SLASystem Module** ✅
   - File: `src/systems/sla_system.lua`
   - Implement SLA tracking data structures
   - Implement basic breach detection
   - Register with GameStateEngine
   - **Estimated**: 8 hours

2. **Enhance Contract JSON Schema** ✅
   - Update `src/data/contracts.json`
   - Add SLA requirements to 5 sample contracts
   - Add capacity requirements
   - Add rewards/penalties
   - **Estimated**: 4 hours

3. **Implement Contract Capacity Algorithm** ✅
   - Update `src/systems/contract_system.lua`
   - Add `calculateWorkloadCapacity()`
   - Add `canAcceptContract()` validation
   - Add `getPerformanceMultiplier()`
   - **Estimated**: 6 hours

4. **Event Bus Integration** ✅
   - Define all new event types
   - Implement event subscriptions in SLASystem
   - Test event flow
   - **Estimated**: 4 hours

**Deliverable**: Working SLA tracking with contract capacity limits

---

### Phase 2: Incident Lifecycle (Week 3-4)
**Goal**: Implement three-stage incident progression

#### Tasks:

1. **Enhance Incident Data Structure** ✅
   - Update `src/systems/incident_specialist_system.lua`
   - Add stage tracking (detect/respond/resolve)
   - Add timing and SLA tracking per stage
   - **Estimated**: 6 hours

2. **Implement Stage Progression Logic** ✅
   - Add `updateIncidentStage()`
   - Add `calculateStageProgress()`
   - Add `advanceToNextStage()`
   - Integrate specialist stats impact
   - **Estimated**: 8 hours

3. **Connect to SLA System** ✅
   - Publish stage completion events
   - Update SLA tracking on stage complete
   - Calculate SLA compliance per incident
   - **Estimated**: 4 hours

4. **Update Threat JSON** ✅
   - Add stage-specific requirements to `src/data/threats.json`
   - Define detection/response/resolution stats needed
   - **Estimated**: 3 hours

**Deliverable**: Full incident lifecycle with SLA tracking

---

### Phase 3: Reward & Penalty System (Week 5)
**Goal**: Implement outcome calculations

#### Tasks:

1. **Implement Reward Calculator** ✅
   - Add `calculateContractRewards()` to SLASystem
   - Implement bonus calculations
   - Integrate with ResourceManager
   - **Estimated**: 5 hours

2. **Implement Penalty Calculator** ✅
   - Add `calculateContractPenalties()` to SLASystem
   - Implement fine calculations
   - Handle contract termination
   - **Estimated**: 5 hours

3. **Global Stats Tracking** ✅
   - Create `GlobalStatsSystem` module
   - Track company-wide metrics
   - Implement performance trends
   - **Estimated**: 6 hours

4. **Testing & Balancing** ✅
   - Test reward/penalty calculations
   - Balance SLA thresholds
   - Adjust capacity formulas
   - **Estimated**: 8 hours

**Deliverable**: Complete reward/penalty system with stat tracking

---

### Phase 4: Admin Mode (Week 6-7)
**Goal**: Enable manual specialist assignment

#### Tasks:

1. **Admin Mode System** ✅
   - Add admin mode toggle to IncidentSpecialistSystem
   - Implement `manualAssignSpecialist()`
   - Track manual vs automatic performance
   - **Estimated**: 6 hours

2. **Admin Mode UI Scene** ✅
   - Create `src/scenes/admin_mode_enhanced_luis.lua`
   - Design incident list view
   - Design specialist selection interface
   - Add assignment controls
   - **Estimated**: 12 hours

3. **UI Integration** ✅
   - Add admin mode toggle button
   - Add performance metrics display
   - Add specialist workload indicators
   - **Estimated**: 8 hours

4. **Testing & Polish** ✅
   - Test manual assignments
   - Test UI responsiveness
   - Polish visual feedback
   - **Estimated**: 6 hours

**Deliverable**: Fully functional admin mode with UI

---

### Phase 5: Integration & Testing (Week 8)
**Goal**: Final integration and comprehensive testing

#### Tasks:

1. **System Integration Testing** ✅
   - Test all systems working together
   - Test save/load state
   - Test edge cases
   - **Estimated**: 8 hours

2. **Balance Pass** ✅
   - Adjust contract SLA requirements
   - Balance capacity limits
   - Tune reward/penalty amounts
   - **Estimated**: 6 hours

3. **Documentation** ✅
   - Update ARCHITECTURE.md
   - Create gameplay documentation
   - Document JSON schemas
   - **Estimated**: 4 hours

4. **Bug Fixes & Polish** ✅
   - Fix discovered issues
   - Polish UI feedback
   - Optimize performance
   - **Estimated**: 10 hours

**Deliverable**: Production-ready SOC simulation system

---

## 📁 File Structure

```
src/
├── systems/
│   ├── sla_system.lua                    [NEW] - SLA tracking and compliance
│   ├── global_stats_system.lua           [NEW] - Company-wide statistics
│   ├── contract_system.lua               [ENHANCED] - Add capacity limits
│   ├── incident_specialist_system.lua    [ENHANCED] - Add lifecycle stages
│   └── specialist_system.lua             [ENHANCED] - Add workload tracking
│
├── data/
│   ├── contracts.json                    [ENHANCED] - Add SLA requirements
│   ├── threats.json                      [ENHANCED] - Add stage requirements
│   └── sla_config.json                   [NEW] - SLA configuration
│
├── scenes/
│   ├── admin_mode_enhanced_luis.lua      [NEW] - Enhanced admin UI
│   └── sla_dashboard_luis.lua            [NEW] - SLA monitoring UI
│
└── ui/
    └── components/
        ├── sla_meter.lua                 [NEW] - SLA compliance visualization
        └── workload_indicator.lua        [NEW] - Specialist workload display
```

---

## 🔗 Event Bus Specification

### New Events

#### SLA System Events

```lua
-- SLA Compliance
{
    event = "sla_compliant",
    data = {
        contractId = string,
        complianceScore = number (0-1),
        bonusAmount = number
    }
}

-- SLA At Risk
{
    event = "sla_at_risk",
    data = {
        contractId = string,
        complianceScore = number (0-1),
        warningLevel = "MINOR" | "MODERATE" | "SEVERE"
    }
}

-- SLA Breached
{
    event = "sla_breached",
    data = {
        contractId = string,
        complianceScore = number (0-1),
        penaltyAmount = number,
        consequences = array of strings
    }
}

-- SLA Performance Updated
{
    event = "sla_performance_updated",
    data = {
        contractId = string,
        performance = {
            incidentsHandled = number,
            incidentsPassed = number,
            incidentsFailed = number,
            complianceScore = number
        }
    }
}
```

#### Incident Lifecycle Events

```lua
-- Incident Stage Completed
{
    event = "incident_stage_completed",
    data = {
        incidentId = string,
        contractId = string,
        stage = "detect" | "respond" | "resolve",
        duration = number,
        slaLimit = number,
        slaCompliant = boolean,
        specialists = array of specialist IDs
    }
}

-- Incident Fully Resolved
{
    event = "incident_fully_resolved",
    data = {
        incidentId = string,
        contractId = string,
        totalDuration = number,
        stageCompliance = {
            detect = boolean,
            respond = boolean,
            resolve = boolean
        },
        overallSLACompliant = boolean
    }
}

-- Incident Failed
{
    event = "incident_failed",
    data = {
        incidentId = string,
        contractId = string,
        failureStage = string,
        reason = string
    }
}
```

#### Contract Capacity Events

```lua
-- Contract Capacity Changed
{
    event = "contract_capacity_changed",
    data = {
        oldCapacity = number,
        newCapacity = number,
        reason = string
    }
}

-- Contract Overloaded
{
    event = "contract_overloaded",
    data = {
        currentContracts = number,
        capacity = number,
        performanceMultiplier = number
    }
}
```

#### Admin Mode Events

```lua
-- Specialist Manually Assigned
{
    event = "specialist_manually_assigned",
    data = {
        incidentId = string,
        specialistId = string,
        stage = string
    }
}

-- Admin Mode Toggled
{
    event = "admin_mode_toggled",
    data = {
        enabled = boolean
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests

**File**: `tests/systems/test_sla_system.lua`

```lua
-- Test SLA tracking initialization
-- Test SLA breach detection
-- Test compliance score calculation
-- Test reward/penalty calculations
```

**File**: `tests/systems/test_contract_capacity.lua`

```lua
-- Test capacity calculation
-- Test workload limits
-- Test performance degradation
-- Test specialist stat impact
```

**File**: `tests/systems/test_incident_lifecycle.lua`

```lua
-- Test stage progression
-- Test stage timing
-- Test specialist assignment impact
-- Test SLA compliance per stage
```

### Integration Tests

**File**: `tests/integration/test_soc_simulation.lua`

```lua
-- Test full contract lifecycle with SLA tracking
-- Test incident handling across all stages
-- Test reward/penalty application
-- Test admin mode manual assignments
-- Test save/load state with new systems
```

### Performance Tests

```lua
-- Test with 100+ active incidents
-- Test with 50+ specialists
-- Test with 20+ active contracts
-- Verify < 16ms frame time
```

---

## 📊 Success Metrics

### Functionality
- ✅ SLA tracking works for all active contracts
- ✅ Contract capacity limits enforced
- ✅ Incident lifecycle progresses through all stages
- ✅ Admin mode allows manual assignments
- ✅ Rewards/penalties calculated correctly
- ✅ Global stats updated in real-time

### Performance
- ✅ Frame rate stays at 60 FPS with 50+ incidents
- ✅ Save/load completes in < 2 seconds
- ✅ UI remains responsive during heavy load

### Balance
- ✅ SLA requirements are challenging but achievable
- ✅ Contract capacity feels meaningful
- ✅ Rewards incentivize good performance
- ✅ Penalties provide real consequences

### User Experience
- ✅ Clear feedback on SLA status
- ✅ Easy to understand contract requirements
- ✅ Admin mode is intuitive to use
- ✅ Visual feedback for all actions

---

## 🚨 Risk Mitigation

### Technical Risks

**Risk**: Performance degradation with many active incidents  
**Mitigation**: 
- Implement object pooling for incidents
- Batch SLA calculations
- Use spatial partitioning for specialist assignment

**Risk**: Save file corruption with new data structures  
**Mitigation**:
- Implement schema versioning
- Add migration logic for old saves
- Create backup before save

**Risk**: Event bus becoming bottleneck  
**Mitigation**:
- Profile event processing
- Implement event batching if needed
- Use priority queues for critical events

### Design Risks

**Risk**: SLA requirements too difficult/easy  
**Mitigation**:
- Start with generous SLAs
- Implement difficulty scaling
- Add configuration file for easy tuning

**Risk**: Contract capacity formula imbalanced  
**Mitigation**:
- Test with various specialist configurations
- Add debug visualization for capacity
- Make formula data-driven for easy adjustment

---

## 📝 Configuration Files

### SLA Configuration

**File**: `src/data/sla_config.json`

```json
{
  "defaultSLA": {
    "detectionTimeSLA": 45,
    "responseTimeSLA": 180,
    "resolutionTimeSLA": 600,
    "minimumSuccessRate": 0.85
  },
  "tierMultipliers": {
    "tier1": 1.5,
    "tier2": 1.2,
    "tier3": 1.0,
    "tier4": 0.8,
    "tier5": 0.6
  },
  "performanceBands": {
    "excellent": {
      "threshold": 0.95,
      "bonusMultiplier": 1.5
    },
    "good": {
      "threshold": 0.85,
      "bonusMultiplier": 1.0
    },
    "acceptable": {
      "threshold": 0.75,
      "bonusMultiplier": 0.5
    },
    "poor": {
      "threshold": 0.0,
      "penaltyMultiplier": 1.5
    }
  }
}
```

---

## 🎓 Migration Guide

### For Existing Saves

```lua
-- Add migration logic to GameStateEngine
function GameStateEngine:migrateFromVersion1ToVersion2(state)
    -- Add SLA tracking for existing contracts
    if state.contractSystem and state.contractSystem.activeContracts then
        for _, contract in ipairs(state.contractSystem.activeContracts) do
            -- Initialize SLA tracking
            contract.slaTracker = {
                incidentsHandled = 0,
                incidentsPassed = 0,
                incidentsFailed = 0,
                complianceScore = 1.0
            }
        end
    end
    
    -- Add stage data to existing incidents
    if state.incidentSystem and state.incidentSystem.activeIncidents then
        for _, incident in ipairs(state.incidentSystem.activeIncidents) do
            -- Convert to new stage-based structure
            incident.stages = {
                detect = {status = "COMPLETED", success = true},
                respond = {status = "IN_PROGRESS", success = nil},
                resolve = {status = "PENDING", success = nil}
            }
            incident.currentStage = "respond"
        end
    end
    
    return state
end
```

---

## 🎯 Next Steps

1. **Review this plan** with the development team
2. **Create feature branch**: `feature/soc-sla-simulation`
3. **Begin Phase 1**: Start with SLASystem module
4. **Set up testing environment**: Create test contracts and scenarios
5. **Iterate rapidly**: Test each phase before moving to next
6. **Document as you go**: Update ARCHITECTURE.md with each addition

---

## 📚 Additional Resources

- **Architecture**: `/ARCHITECTURE.md`
- **Testing Guide**: `/TESTING.md`
- **Event Bus**: `/src/utils/event_bus.lua`
- **Existing Systems**: `/src/systems/`
- **Data Files**: `/src/data/`

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Estimated Total Time**: 8 weeks (200 hours)  
**Complexity**: High  
**Risk Level**: Medium  
**ROI**: Very High - Core gameplay feature

---

*This implementation plan follows the project's "Golden Path" architecture and adheres to all established patterns and best practices.*
