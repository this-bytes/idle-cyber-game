# Phase 4 Quick Reference Guide

## Quick Start

### Accessing Enhanced Admin Mode
1. Start game → SOC View
2. Click "🔧 Enhanced Admin" button
3. Enhanced Admin Mode opens

### Manual Assignment
1. Click incident in left panel (highlights it)
2. Click "ASSIGN TO [INCIDENT]" button on specialist card
3. Assignment complete! (auto-refresh)

### Navigation
- **ESC key** or **← BACK TO SOC** button → Return to SOC View

---

## API Reference

### IncidentSpecialistSystem Methods

#### `getActiveIncidents()`
Returns array of all active incidents.
```lua
local activeIncidents = incidentSystem:getActiveIncidents()
-- Returns: { {id, threatType, currentStage, stages, ...}, ... }
```

#### `getIncidentById(incidentId)`
Retrieves specific incident by ID.
```lua
local incident = incidentSystem:getIncidentById("incident-123")
-- Returns: incident object or nil
```

#### `manualAssignSpecialist(specialistId, incidentId, stageName)`
Assigns specialist to incident stage.
```lua
local success = incidentSystem:manualAssignSpecialist(
    "specialist-1",
    "incident-123",
    "detect"  -- optional, defaults to currentStage
)
-- Returns: true on success, false on failure
```

#### `setSpecialistSystem(specialistSystem)`
Connects to specialist system for validation.
```lua
incidentSystem:setSpecialistSystem(specialistSystem)
```

---

### GlobalStatsSystem Methods

#### `trackManualAssignment(data)`
Records manual assignment event.
```lua
statsSystem:trackManualAssignment({
    specialistId = "specialist-1",
    incidentId = "incident-123",
    stage = "detect",
    timestamp = os.clock()
})
```

#### `getDashboardData()`
Returns enhanced dashboard data.
```lua
local data = statsSystem:getDashboardData()
-- Returns: {
--   workloadPercentage = 0.5,
--   slaComplianceRate = 0.95,
--   activeContracts = 3,
--   totalSpecialists = 5,
--   avgSpecialistLevel = 2.4,
--   avgResponseTime = 45.2,
--   ...
-- }
```

#### `calculateWorkloadPercentage()`
Calculates current workload as 0-1 ratio.
```lua
local workload = statsSystem:calculateWorkloadPercentage()
-- Returns: 0.0 (empty) to 1.0 (overloaded)
```

---

## Event Reference

### Published Events

#### `manual_assignment_requested`
Published when user requests manual assignment.
```lua
eventBus:publish("manual_assignment_requested", {
    specialistId = "specialist-1",
    incidentId = "incident-123",
    stage = "detect",  -- optional
    timestamp = os.clock()
})
```

#### `specialist_manually_assigned`
Published after successful manual assignment.
```lua
eventBus:publish("specialist_manually_assigned", {
    specialistId = "specialist-1",
    incidentId = "incident-123",
    stage = "detect",
    timestamp = os.clock()
})
```

### Subscribed Events
The Enhanced Admin Mode subscribes to:
- `incident_generated` → Refreshes incident list
- `incident_stage_completed` → Updates progress
- `specialist_assigned` → Updates assignments
- `stats_updated` → Refreshes dashboard

---

## Data Structures

### Manual Assignment Stats
```lua
stats.manualAssignmentStats = {
    totalManualAssignments = 0,          -- Counter
    manualAssignmentSuccessRate = 0,     -- 0-1 ratio
    averageManualAssignmentTime = 0,     -- Seconds
    lastManualAssignment = {
        specialistId = "specialist-1",
        incidentId = "incident-123",
        stage = "detect",
        timestamp = 123456.789
    }
}
```

### Enhanced Dashboard Data
```lua
dashboardData = {
    workloadPercentage = 0.5,       -- 0-1 (0=empty, 1=overloaded)
    slaComplianceRate = 0.95,       -- 0-1 (0=failing, 1=perfect)
    activeContracts = 3,            -- Integer count
    totalSpecialists = 5,           -- Integer count
    avgSpecialistLevel = 2.4,       -- Float average
    avgResponseTime = 45.2,         -- Seconds
    workloadStatus = "OPTIMAL"      -- OPTIMAL|HIGH|CRITICAL|OVERLOADED
}
```

---

## UI Layout

```
┌────────────────────────────────────────────────────────────┐
│  🔧 ENHANCED ADMIN MODE                                    │
├────────────────────────────────────────────────────────────┤
│  📊 PERFORMANCE METRICS                                    │
│  Workload: OPTIMAL (50%) | SLA: 95% | Contracts: 3        │
│  Specialists: 5 (Lvl: 2.4) | Avg Response: 45s            │
├──────────────────────────────┬─────────────────────────────┤
│ 🚨 ACTIVE INCIDENTS          │ 👥 SPECIALISTS & WORKLOAD   │
│ ┌──────────────────────────┐ │ ┌─────────────────────────┐ │
│ │ 🚨 Phishing [detect]     │ │ │ 👤 Alice (Level 3)      │ │
│ │ Progress: 45% | SLA: 30s │ │ │ Trace: 5 | Speed: 7     │ │
│ │ Assigned: Bob            │ │ │ Workload: 2 incidents   │ │
│ │ [MANUALLY ASSIGN...]     │ │ │ [ASSIGN TO Phishing]    │ │
│ └──────────────────────────┘ │ └─────────────────────────┘ │
│ ┌──────────────────────────┐ │ ┌─────────────────────────┐ │
│ │ 🚨 Ransomware [respond]  │ │ │ 👤 Bob (Level 2)        │ │
│ │ Progress: 78% | SLA: 60s │ │ │ Trace: 3 | Speed: 4     │ │
│ │ Assigned: Alice          │ │ │ Workload: 1 incident    │ │
│ │ [MANUALLY ASSIGN...]     │ │ │                         │ │
│ └──────────────────────────┘ │ └─────────────────────────┘ │
│                              │                             │
├──────────────────────────────┴─────────────────────────────┤
│ [← BACK TO SOC]                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Color Coding

### Workload Status
- 🟢 **OPTIMAL** (Green): 0-50% capacity
- 🟡 **HIGH** (Yellow): 50-66% capacity
- 🟠 **CRITICAL** (Orange): 66-100% capacity
- 🔴 **OVERLOADED** (Red): >100% capacity

### SLA Compliance
- 🟢 **Green**: ≥80% compliance
- 🟡 **Yellow**: <80% compliance

### Specialist Workload
- 🟢 **Green**: 0 incidents (available)
- 🟡 **Yellow**: 1-2 incidents (busy)
- 🔴 **Red**: 3+ incidents (overloaded)

---

## Troubleshooting

### Scene doesn't load
- Check console for error messages
- Verify scene is registered in soc_game.lua
- Ensure LUIS is initialized

### No incidents showing
- Check if any contracts are active
- Verify incident system is generating incidents
- Check console for "No active incidents" message

### No specialists showing
- Check if any specialists are hired
- Verify specialist system is initialized
- Check `getAllSpecialists()` return value

### Assignment doesn't work
- Ensure incident is selected first (click incident)
- Verify specialist exists and is valid
- Check event flow in console logs
- Look for validation error messages

### UI doesn't refresh
- Check event subscriptions are active
- Verify systems are publishing events
- Check refresh timer (2 second interval)

---

## Performance Tips

### Optimize for Many Incidents
- Keep incident list to visible items only
- Consider pagination for 20+ incidents
- Use scroll offset to limit rendering

### Optimize for Many Specialists
- Limit visible specialists to screen space
- Consider filtering by workload or level
- Use scroll offset for large teams

### Reduce Event Overhead
- Increase refresh timer interval if needed
- Batch multiple assignments together
- Debounce frequent updates

---

## Testing Commands

### Run Integration Tests
```bash
lua tests/integration/test_phase4_admin_enhanced.lua
```

### Expected Output
```
🧪 Testing Phase 4: Enhanced Admin Mode Integration
============================================================
✅ IncidentSpecialistSystem loaded successfully
✅ getActiveIncidents() method exists
✅ getIncidentById() method exists
✅ manualAssignSpecialist() method exists
✅ setSpecialistSystem() method exists
✅ GlobalStatsSystem loaded successfully
✅ manualAssignmentStats structure exists
✅ trackManualAssignment() method exists
✅ Manual assignment counter incremented
✅ Enhanced dashboard data verified
✅ AdminModeEnhanced scene loaded
✅ All Phase 4 Integration Tests PASSED!
```

---

## Code Examples

### Example: Manual Assignment Flow
```lua
-- In AdminModeEnhanced scene
function AdminModeEnhanced:manuallyAssignSpecialist(specialistId, incidentId)
    -- 1. Publish event
    self.eventBus:publish("manual_assignment_requested", {
        specialistId = specialistId,
        incidentId = incidentId,
        timestamp = love.timer.getTime()
    })
    
    -- 2. Clear selection
    self.selectedIncident = nil
    
    -- 3. Refresh UI
    self:refreshData()
end
```

### Example: Subscribe to Assignment Events
```lua
-- In any system
eventBus:subscribe("specialist_manually_assigned", function(data)
    print(string.format("Specialist %s assigned to incident %s", 
        data.specialistId, data.incidentId))
    
    -- Update your system state here
end)
```

### Example: Get Enhanced Dashboard Data
```lua
-- In any scene
local data = self.systems.globalStatsSystem:getDashboardData()

print("Workload: " .. data.workloadStatus)
print("SLA: " .. (data.slaComplianceRate * 100) .. "%")
print("Active Contracts: " .. data.activeContracts)
print("Specialists: " .. data.totalSpecialists)
```

---

## Future Roadmap

### Planned Enhancements
1. Scrolling support for 20+ items
2. Drag-and-drop assignment
3. Assignment history panel
4. Performance graphs
5. Filtering and sorting
6. Keyboard navigation
7. Assignment templates
8. Bulk assignment
9. Undo/redo support
10. Assignment confirmation dialog

---

## Support

For issues or questions:
1. Check `PHASE4_IMPLEMENTATION.md` for detailed docs
2. Review integration tests in `tests/integration/test_phase4_admin_enhanced.lua`
3. Check console logs for error messages
4. Verify event flow with debug prints

---

## Version Info

- **Phase**: 4
- **Feature**: Enhanced Admin Mode with Manual Assignment
- **Status**: Complete
- **Lines of Code**: 857
- **Functions Added**: 20
- **Tests**: 11 integration tests
