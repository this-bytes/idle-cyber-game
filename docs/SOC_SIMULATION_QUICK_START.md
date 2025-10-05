# SOC Simulation Quick Start Guide
## Developer Implementation Reference

**Related Document**: See `SOC_SIMULATION_IMPLEMENTATION_PLAN.md` for complete architectural details.

---

## 🚀 Quick Start: 5-Minute Overview

### What You're Building

A comprehensive SOC simulation with:
- **SLA-based contracts** requiring specific performance metrics
- **Three-stage incident handling** (Detect → Respond → Resolve)
- **Contract capacity limits** based on team capability
- **Manual admin mode** for tactical specialist assignment
- **Reward/penalty system** driven by SLA compliance

### Architecture Pattern

```
EventBus (Communication Hub)
    ↓
GameStateEngine (Orchestrator)
    ↓
Systems (src/systems/) ← YOU BUILD HERE
    ↓
JSON Data (src/data/) ← CONFIGURE HERE
    ↓
UI (src/scenes/) ← VISUALIZE HERE
```

---

## 📋 Implementation Checklist

### Phase 1: Core SLA System (Start Here)

- [ ] **Create `src/systems/sla_system.lua`**
  - Copy template from implementation plan section 1
  - Implement `SLATracker` data structure
  - Add breach detection logic
  - Register with GameStateEngine in `src/soc_game.lua`

- [ ] **Update `src/data/contracts.json`**
  - Add `slaRequirements` block to 5 contracts
  - Add `capacityRequirements` block
  - Add `rewards` and `penalties` blocks
  - See schema example in implementation plan section 2

- [ ] **Enhance `src/systems/contract_system.lua`**
  - Add `calculateWorkloadCapacity()` function
  - Add `canAcceptContract()` validation
  - Add `getPerformanceMultiplier()` function
  - See code examples in implementation plan section 2

- [ ] **Test Phase 1**
  - Run game and verify contract capacity limits work
  - Check that SLA tracking initializes
  - Verify events are published

### Phase 2: Incident Lifecycle

- [ ] **Enhance `src/systems/incident_specialist_system.lua`**
  - Update incident structure with `stages` object
  - Add `updateIncidentStage(dt)` function
  - Add `calculateStageProgress()` function
  - Add `advanceToNextStage()` function
  - See code examples in implementation plan section 3

- [ ] **Update `src/data/threats.json`**
  - Add stage-specific stat requirements
  - Add SLA time limits per stage

- [ ] **Connect to SLA System**
  - Subscribe to incident stage events in SLASystem
  - Update SLA tracking on stage completion
  - Calculate compliance scores

- [ ] **Test Phase 2**
  - Verify incidents progress through all stages
  - Check SLA timing is tracked correctly
  - Verify specialist stats affect progress

### Phase 3: Rewards & Penalties

- [ ] **Add Reward/Penalty Functions to SLASystem**
  - Implement `calculateContractRewards()`
  - Implement `calculateContractPenalties()`
  - Hook into contract completion event
  - See formulas in implementation plan section 6

- [ ] **Create `src/systems/global_stats_system.lua`**
  - Track company-wide metrics
  - Subscribe to all relevant events
  - Provide stats API for UI
  - See structure in implementation plan section 7

- [ ] **Test Phase 3**
  - Complete contracts and verify rewards applied
  - Breach SLAs and verify penalties applied
  - Check global stats update correctly

### Phase 4: Admin Mode

- [ ] **Enhance Admin Mode in IncidentSpecialistSystem**
  - Add `adminMode` state tracking
  - Implement `manualAssignSpecialist()` function
  - Track manual vs automatic performance
  - See code in implementation plan section 5

- [ ] **Create Admin UI Scene**
  - Create `src/scenes/admin_mode_enhanced_luis.lua`
  - Display active incidents with stages
  - Show available specialists
  - Add assignment controls

- [ ] **Test Phase 4**
  - Enable admin mode and manually assign specialists
  - Verify manual assignments work correctly
  - Check performance metrics tracked

---

## 💻 Code Templates

### Template: SLASystem Module

```lua
-- src/systems/sla_system.lua
local SLASystem = {}
SLASystem.__index = SLASystem

function SLASystem.new(eventBus, contractSystem, resourceManager)
    local self = setmetatable({}, SLASystem)
    self.eventBus = eventBus
    self.contractSystem = contractSystem
    self.resourceManager = resourceManager
    self.slaTrackers = {} -- contractId -> SLATracker
    
    -- Subscribe to events
    self.eventBus:subscribe("contract_activated", function(data)
        self:initializeSLATracking(data.contractId)
    end)
    
    self.eventBus:subscribe("incident_stage_completed", function(data)
        self:updateSLAPerformance(data)
    end)
    
    return self
end

function SLASystem:initializeSLATracking(contractId)
    local contract = self.contractSystem:getContract(contractId)
    
    self.slaTrackers[contractId] = {
        contractId = contractId,
        slaRequirements = contract.slaRequirements,
        performance = {
            incidentsHandled = 0,
            incidentsPassed = 0,
            incidentsFailed = 0,
            complianceScore = 1.0
        },
        status = "COMPLIANT"
    }
end

function SLASystem:updateSLAPerformance(data)
    local tracker = self.slaTrackers[data.contractId]
    if not tracker then return end
    
    tracker.performance.incidentsHandled = tracker.performance.incidentsHandled + 1
    
    if data.slaCompliant then
        tracker.performance.incidentsPassed = tracker.performance.incidentsPassed + 1
    else
        tracker.performance.incidentsFailed = tracker.performance.incidentsFailed + 1
    end
    
    -- Calculate compliance score
    tracker.performance.complianceScore = 
        tracker.performance.incidentsPassed / tracker.performance.incidentsHandled
    
    -- Check status
    if tracker.performance.complianceScore < 0.70 then
        tracker.status = "BREACHED"
        self.eventBus:publish("sla_breached", {contractId = data.contractId})
    elseif tracker.performance.complianceScore < tracker.slaRequirements.minimumSuccessRate then
        tracker.status = "AT_RISK"
        self.eventBus:publish("sla_at_risk", {contractId = data.contractId})
    end
end

function SLASystem:getState()
    return {
        slaTrackers = self.slaTrackers
    }
end

function SLASystem:loadState(state)
    if state and state.slaTrackers then
        self.slaTrackers = state.slaTrackers
    end
end

return SLASystem
```

### Template: Enhanced Contract JSON

```json
{
  "id": "startup_security",
  "type": "contract",
  "clientName": "Tech Startup Inc",
  "displayName": "Startup Security Package",
  "description": "Basic security monitoring for a growing tech company.",
  "baseBudget": 5000,
  "baseDuration": 120,
  "reputationReward": 10,
  "riskLevel": "MEDIUM",
  
  "slaRequirements": {
    "detectionTimeSLA": 45,
    "responseTimeSLA": 180,
    "resolutionTimeSLA": 600,
    "requiredSkillLevels": {
      "detection": 5,
      "response": 7,
      "resolution": 10
    },
    "minimumSuccessRate": 0.85,
    "maxAllowedIncidents": 20
  },
  
  "capacityRequirements": {
    "minimumSpecialists": 2,
    "minimumTotalEfficiency": 10,
    "minimumTotalSpeed": 8,
    "requiredSkillCoverage": ["basic_analysis", "network_monitoring"]
  },
  
  "rewards": {
    "slaComplianceBonus": 2000,
    "perfectPerformanceBonus": 1000,
    "reputationBonus": 5
  },
  
  "penalties": {
    "slaBreachFine": 3000,
    "contractTerminationPenalty": 5000,
    "reputationLoss": 15
  },
  
  "tier": 2,
  "rarity": "common",
  "tags": ["startup", "tech", "basic"]
}
```

### Template: Incident Stage Structure

```lua
-- Enhanced incident object
incident = {
    id = "incident_123",
    threatId = "malware_detection",
    contractId = "contract_456",
    severity = 5,
    
    -- NEW: Stage-based lifecycle
    stages = {
        detect = {
            status = "COMPLETED",
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
            duration = 45.2,
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

---

## 🔗 Event Bus Quick Reference

### Events to Publish

```lua
-- When SLA status changes
eventBus:publish("sla_compliant", {
    contractId = "contract_123",
    complianceScore = 0.92
})

eventBus:publish("sla_breached", {
    contractId = "contract_123",
    complianceScore = 0.68,
    penaltyAmount = 5000
})

-- When incident stage completes
eventBus:publish("incident_stage_completed", {
    incidentId = "incident_456",
    contractId = "contract_123",
    stage = "respond",
    duration = 98.5,
    slaLimit = 120,
    slaCompliant = true
})

-- When specialist manually assigned
eventBus:publish("specialist_manually_assigned", {
    incidentId = "incident_456",
    specialistId = "spec_5",
    stage = "resolve"
})
```

### Events to Subscribe To

```lua
-- In SLASystem
eventBus:subscribe("contract_activated", function(data)
    -- Initialize SLA tracking
end)

eventBus:subscribe("incident_stage_completed", function(data)
    -- Update SLA metrics
end)

-- In ContractSystem
eventBus:subscribe("sla_breached", function(data)
    -- Apply penalties
end)

-- In IncidentSpecialistSystem
eventBus:subscribe("specialist_manually_assigned", function(data)
    -- Handle manual assignment
end)
```

---

## 🧪 Testing Checklist

### Unit Tests to Write

```lua
-- tests/systems/test_sla_system.lua
function test_sla_tracking_initialization()
    -- Test that SLA trackers are created correctly
end

function test_compliance_score_calculation()
    -- Test score calculation with various pass/fail ratios
end

function test_breach_detection()
    -- Test that breaches are detected at correct thresholds
end

-- tests/systems/test_contract_capacity.lua
function test_capacity_calculation()
    -- Test capacity formula with various specialist counts
end

function test_performance_degradation()
    -- Test performance drops when overloaded
end

-- tests/systems/test_incident_lifecycle.lua
function test_stage_progression()
    -- Test incidents move through stages correctly
end

function test_sla_timing_per_stage()
    -- Test SLA compliance per stage
end
```

### Manual Testing Scenarios

1. **Happy Path**: Accept contract → Handle incidents → Complete with good SLA → Get rewards
2. **SLA Breach**: Accept contract → Fail some incidents → SLA breached → Get penalties
3. **Overload**: Accept too many contracts → Performance degrades → Harder to meet SLAs
4. **Admin Mode**: Enable admin → Manually assign specialists → Compare performance
5. **Save/Load**: Play for a bit → Save → Load → Verify state restored correctly

---

## 📊 Debug Commands

Add these to help with testing:

```lua
-- In your debug console or scene
function debugSLAStatus(contractId)
    local tracker = slaSystem.slaTrackers[contractId]
    print("Contract:", contractId)
    print("Status:", tracker.status)
    print("Compliance Score:", tracker.performance.complianceScore)
    print("Incidents Handled:", tracker.performance.incidentsHandled)
    print("Incidents Passed:", tracker.performance.incidentsPassed)
    print("Incidents Failed:", tracker.performance.incidentsFailed)
end

function debugContractCapacity()
    local capacity = contractSystem:calculateWorkloadCapacity()
    local active = #contractSystem.activeContracts
    local multiplier = contractSystem:getPerformanceMultiplier()
    print("Contract Capacity:", capacity)
    print("Active Contracts:", active)
    print("Performance Multiplier:", multiplier)
end

function debugIncidentStage(incidentId)
    local incident = incidentSystem:getIncident(incidentId)
    print("Incident:", incidentId)
    print("Current Stage:", incident.currentStage)
    for stage, data in pairs(incident.stages) do
        print(stage, "Status:", data.status, "Duration:", data.duration, "SLA:", data.slaLimit)
    end
end
```

---

## 🎯 Common Pitfalls to Avoid

### ❌ Don't Do This

1. **Hardcoding SLA values** in Lua code
   - ✅ Use JSON configuration instead

2. **Directly accessing other systems' internal state**
   - ✅ Use EventBus for communication

3. **Forgetting to register new systems with GameStateEngine**
   - ✅ Always add to `soc_game.lua` initialization

4. **Not implementing `getState()` and `loadState()`**
   - ✅ Required for save/load to work

5. **Publishing events synchronously in update loop without checks**
   - ✅ Batch events or throttle to avoid spam

### ✅ Best Practices

1. **Always validate data from JSON files**
2. **Use meaningful event names** (e.g., `sla_breached` not `sla_bad`)
3. **Log important state changes** for debugging
4. **Test with extreme values** (0 specialists, 100 contracts, etc.)
5. **Document your formulas** in code comments

---

## 📚 Key Files Reference

### Core Systems
- `src/systems/game_state_engine.lua` - Orchestrator
- `src/systems/contract_system.lua` - Contract management
- `src/systems/specialist_system.lua` - Specialist management
- `src/systems/incident_specialist_system.lua` - Incident handling
- `src/systems/resource_manager.lua` - Money, reputation, etc.

### Utilities
- `src/utils/event_bus.lua` - Event system
- `src/utils/dkjson.lua` - JSON parsing

### Data Files
- `src/data/contracts.json` - Contract definitions
- `src/data/specialists.json` - Specialist types
- `src/data/threats.json` - Threat definitions

### Entry Point
- `src/soc_game.lua` - System initialization and registration

---

## 🚦 When to Ask for Help

**Ask for help if**:
- You're modifying files outside `src/systems/` or `src/data/`
- You're adding new UI libraries
- You're changing the EventBus core functionality
- You're unsure how to integrate with GameStateEngine
- You need to modify existing save file format

**You're on the right track if**:
- Creating new files in `src/systems/`
- Adding fields to JSON in `src/data/`
- Using EventBus for communication
- Following existing system patterns
- Writing unit tests for your code

---

## ⏱️ Time Estimates

- **Phase 1 (Core SLA)**: 2-3 days
- **Phase 2 (Lifecycle)**: 2-3 days  
- **Phase 3 (Rewards)**: 1-2 days
- **Phase 4 (Admin Mode)**: 3-4 days
- **Testing & Polish**: 2-3 days

**Total**: ~2 weeks for experienced developer

---

## 🎓 Learning Resources

- Read `ARCHITECTURE.md` - Understand the golden path
- Study `src/systems/contract_system.lua` - See existing patterns
- Review `src/systems/game_state_engine.lua` - Understand orchestration
- Check `tests/systems/` - See testing examples
- Look at `src/scenes/*_luis.lua` - UI patterns

---

**Ready to start?** Begin with Phase 1, Section 1: Create `src/systems/sla_system.lua`

**Questions?** Check the full implementation plan: `SOC_SIMULATION_IMPLEMENTATION_PLAN.md`

---

*Last Updated: October 5, 2025*
