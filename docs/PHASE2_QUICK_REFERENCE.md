# Three-Stage Incident Lifecycle - Quick Reference

## 🚀 Quick Start

### Basic Usage

```lua
-- Initialize system
local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
system:initialize()
system:setContractSystem(contractSystem)

-- Create incident with three stages
local incident = system:createIncidentFromTemplate(threatTemplate, contractId)

-- Update in game loop
system:update(dt)
```

## 📊 Incident Structure

```lua
incident = {
    id = "incident_123",
    threatId = "malware_detection",
    contractId = "contract_456",
    severity = 5,
    currentStage = "detect",
    
    stages = {
        detect = {
            status = "IN_PROGRESS" | "COMPLETED" | "PENDING",
            duration = 0,
            slaLimit = 45,
            assignedSpecialists = {1, 2},
            success = nil
        },
        respond = { ... },
        resolve = { ... }
    }
}
```

## 🎯 Stage Requirements

| Stage   | Required Stat | Default SLA | Purpose                    |
|---------|---------------|-------------|----------------------------|
| Detect  | `trace`       | 45s         | Identify and analyze threat|
| Respond | `speed`       | 180s        | Contain and neutralize     |
| Resolve | `efficiency`  | 600s        | Full remediation           |

## 🔧 Key Functions

### Creating Incidents
```lua
-- Creates incident with all stages initialized
local incident = system:createIncidentFromTemplate(template, contractId)
```

### Stage Progression
```lua
-- Called automatically in update loop
system:updateIncidentStage(incident, dt)

-- Manual stage advancement (for testing)
system:advanceToNextStage(incident)
```

### Helper Functions
```lua
-- Get incident by ID
local incident = system:getIncident("incident_123")

-- Get all incidents for a contract
local incidents = system:getIncidentsByContract("contract_456")

-- Get available specialists
local available = system:getAvailableSpecialists()

-- Remove incident and free specialists
system:removeIncident("incident_123")
```

## 📡 Events

### Stage Completion
```lua
eventBus:subscribe("incident_stage_completed", function(data)
    -- data.incidentId
    -- data.contractId
    -- data.stage ("detect", "respond", "resolve")
    -- data.duration
    -- data.slaLimit
    -- data.slaCompliant
    -- data.specialists
end)
```

### Incident Resolution
```lua
eventBus:subscribe("incident_fully_resolved", function(data)
    -- data.incidentId
    -- data.contractId
    -- data.totalDuration
    -- data.stageCompliance {detect, respond, resolve}
    -- data.overallSLACompliant
end)
```

## 💡 Progress Formula

```lua
-- Progress calculation
progress = (totalStat * duration) / (severity * baseDifficulty)

-- Where:
-- totalStat = Sum of relevant stat from assigned specialists
-- duration = Time in current stage (seconds)
-- severity = Incident severity (1-10)
-- baseDifficulty = 10 (constant)
```

## 👥 Specialist Assignment

### Auto-Assignment Rules
- **Low Severity (1-3)**: 1 specialist
- **Medium Severity (4-6)**: 2 specialists
- **High Severity (7-10)**: 3 specialists

### Selection Criteria
1. Specialists must be available (not busy)
2. Sorted by relevant stat (highest first)
3. Assigned to current stage

## 🎮 Rewards

### SLA Compliant (All Stages Pass)
- 100% of base rewards
- Mission tokens awarded
- Reputation bonus

### SLA Breach (Any Stage Fails)
- 60% money reward
- 50% reputation reward
- 70% XP reward
- NO mission tokens

## 🔄 Migration

### Old Format Detection
```lua
if not incident.stages then
    -- Old format incident
    system:migrateIncidentToStageFormat(incident)
end
```

### Manual Migration
```lua
-- Converts old incident to new format
system:migrateIncidentToStageFormat(oldIncident)
```

## 🎯 Contract Integration

### Getting SLA Limits
```lua
-- From contract (preferred)
local limit = system:getSLALimitForStage(contractId, "detect")

-- Falls back to defaults if contract not found
-- detect: 45s, respond: 180s, resolve: 600s
```

### Contract System Setup
```lua
-- Add getContract method to ContractSystem
function ContractSystem:getContract(contractId)
    return self.activeContracts[contractId] or 
           self.availableContracts[contractId]
end
```

## 📈 Debugging

### Console Output
```
🔔 New incident created: incident_1 (Contract: contract_123, Severity: 5)
   Assigned 2 specialists to detect stage (requires trace)
✅ Incident incident_1: Stage 'detect' completed in 42.3s (SLA: 45s, Compliant: true)
   Assigned 2 specialists to respond stage (requires speed)
🎯 Incident incident_1 fully resolved: Total time 425.7s, SLA Compliant: true
   💰 Full rewards: $250, 2 Rep, 50 XP, 1 Mission Tokens
```

### Common Issues

**Specialists Not Assigned**
- Check specialist availability (`is_busy = false`)
- Check cooldown timer (`cooldown_timer <= 0`)
- Verify specialists have required stat

**SLA Always Failing**
- Check severity vs specialist stats
- Verify SLA limits from contract
- Increase specialist count or stats

**Incidents Stuck**
- Check if `update()` is being called
- Verify specialists are assigned to current stage
- Check progress calculation output

## 🧪 Testing

### Unit Test Example
```lua
TestRunner.test("Stage Progression", function()
    local system = IncidentSpecialistSystem.new(eventBus, resourceManager)
    system:initialize()
    
    local incident = system:createIncidentFromTemplate(template, "contract_1")
    
    -- Verify initial state
    TestRunner.assertEqual("detect", incident.currentStage)
    TestRunner.assertEqual("IN_PROGRESS", incident.stages.detect.status)
    
    -- Force completion and advance
    incident.stages.detect.status = "COMPLETED"
    system:advanceToNextStage(incident)
    
    -- Verify advancement
    TestRunner.assertEqual("respond", incident.currentStage)
end)
```

## 📚 Related Files

- **Core**: `src/systems/incident_specialist_system.lua`
- **Integration**: `src/soc_game.lua`
- **Data**: `src/data/threats.json`
- **Tests**: `tests/systems/test_incident_specialist_system.lua`
- **Docs**: `docs/PHASE2_INCIDENT_LIFECYCLE.md`

## 🎓 Best Practices

1. **Always Link to Contract**: Pass contractId to `createIncidentFromTemplate()`
2. **Check Progress**: Monitor stage progress for balancing
3. **Subscribe to Events**: Use events for UI updates and SLA tracking
4. **Test Migration**: Verify old saves load correctly
5. **Log Everything**: Use print statements for debugging stage transitions

---

**Quick Reference Version**: 1.0
**Phase**: 2 of 5
**Last Updated**: 2024
