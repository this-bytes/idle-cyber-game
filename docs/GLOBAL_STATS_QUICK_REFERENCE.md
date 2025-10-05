# GlobalStatsSystem Quick Reference

## Overview
The GlobalStatsSystem tracks company-wide performance metrics for the SOC simulation. It provides comprehensive statistics, milestone tracking, and dashboard data for UI integration.

## Accessing the System

```lua
-- In any scene or system with access to systems table:
local statsSystem = systems.globalStatsSystem
```

## Getting Statistics

### Get All Stats
```lua
local stats = statsSystem:getStats()
-- Returns complete stats object with all categories
```

### Get Specific Categories
```lua
-- Company information
local company = statsSystem:getCompanyInfo()
-- Returns: { name, tier, foundedDate, daysOperating }

-- Contract statistics
local contracts = statsSystem:getContractStats()
-- Returns: { totalCompleted, totalActive, totalFailed, totalRevenue, 
--           averageSLACompliance, highestTierCompleted, currentStreak, bestStreak }

-- Specialist statistics
local specialists = statsSystem:getSpecialistStats()
-- Returns: { totalHired, totalActive, totalRetired, averageLevel, 
--           averageEfficiency, totalXPEarned }

-- Incident statistics
local incidents = statsSystem:getIncidentStats()
-- Returns: { totalGenerated, totalHandled, totalResolved, totalFailed,
--           totalAutoResolved, averageResolutionTime, totalResolutionTime,
--           fastestResolution, slowestResolution }

-- Performance metrics
local performance = statsSystem:getPerformanceMetrics()
-- Returns: { currentSLACompliance, lifetimeSLACompliance, reputationTrend,
--           financialHealth, workloadStatus, efficiencyRating }

-- Milestone status
local milestones = statsSystem:getMilestones()
-- Returns: { firstContract, first10Contracts, first100Incidents,
--           perfectContract, hire10Specialists, reach1MRevenue }
```

## Calculated Metrics

### Success Rates
```lua
-- Incident success rate (%)
local incidentSuccessRate = statsSystem:getSuccessRate()
-- Returns: 0-100 (percentage)

-- Contract success rate (%)
local contractSuccessRate = statsSystem:getContractSuccessRate()
-- Returns: 0-100 (percentage)
```

## Dashboard Data

### Get Formatted Dashboard Data
```lua
local dashboard = statsSystem:getDashboardData()
-- Returns structured data for UI:
-- {
--   overview = { companyName, tier, daysOperating },
--   keyMetrics = [
--     { label, value, trend },
--     ...
--   ],
--   recentActivity = { contractsCompleted, incidentsResolved, currentStreak },
--   performance = { slaCompliance, reputationTrend, financialHealth, workloadStatus }
-- }
```

### Example: Display Key Metrics
```lua
local dashboard = statsSystem:getDashboardData()

for _, metric in ipairs(dashboard.keyMetrics) do
    print(metric.label .. ": " .. metric.value)
    -- Active Contracts: 5
    -- SLA Compliance: 95.0%
    -- Success Rate: 87.5%
    -- Total Revenue: $125.5K
end
```

## Event Subscriptions

The GlobalStatsSystem automatically tracks these events:

### Contract Events
- `contract_completed` - Increments completions, revenue, streak
- `contract_failed` - Increments failures, resets streak
- `contract_accepted` - Increments active contracts

### Incident Events
- `incident_fully_resolved` - Tracks resolution with timing data
- `incident_failed` - Tracks failed incidents
- `incident_auto_resolved` - Tracks auto-resolved incidents
- `incident_escalated` - Tracks generated incidents

### Specialist Events
- `specialist_hired` - Increments specialist count
- `specialist_unlocked` - Also counts as hired

### SLA Events
- `sla_finalized` - Updates SLA compliance score

## Published Events

### Milestone Unlocked
```lua
-- Subscribe to milestone events
eventBus:subscribe("milestone_unlocked", function(data)
    print("Milestone: " .. data.name)
    -- Display notification to player
end)
```

## Milestones

| Milestone | Trigger | Event ID |
|-----------|---------|----------|
| First Contract | Complete 1 contract | `firstContract` |
| 10 Contracts | Complete 10 contracts | `first10Contracts` |
| 100 Incidents | Resolve 100 incidents | `first100Incidents` |
| 10 Specialists | Hire 10 specialists | `hire10Specialists` |
| $1M Revenue | Earn $1,000,000 total | `reach1MRevenue` |

## Company Tiers

Tiers are automatically updated based on completed contracts and specialists:

| Tier | Contracts | Specialists |
|------|-----------|-------------|
| STARTUP | 0-9 | 0-3 |
| GROWING | 10-24 | 4-6 |
| ESTABLISHED | 25-49 | 7-9 |
| ENTERPRISE | 50-99 | 10-19 |
| CORPORATION | 100+ | 20+ |

## Performance Indicators

### Reputation Trend
- **RISING**: Reputation increased by 5+ recently
- **STABLE**: Reputation change between -5 and +5
- **FALLING**: Reputation decreased by 5+ recently

### Financial Health
- **EXCELLENT**: Money > $100,000
- **GOOD**: Money > $50,000
- **FAIR**: Money > $10,000
- **POOR**: Money > $1,000
- **CRITICAL**: Money ≤ $1,000

### Workload Status
- **OPTIMAL**: ≤ 0.5 contracts per specialist
- **HIGH**: 0.5-1.0 contracts per specialist
- **CRITICAL**: 1.0-1.5 contracts per specialist
- **OVERLOADED**: > 1.5 contracts per specialist

### Efficiency Rating
```
Efficiency = (Incidents Resolved / Total Incidents) × SLA Compliance
```
Returns value from 0.0 to 1.0

## Utility Functions

### Format Large Numbers
```lua
local formatted = statsSystem:formatNumber(1500)    -- "1.5K"
local formatted = statsSystem:formatNumber(1500000) -- "1.5M"
local formatted = statsSystem:formatNumber(500)     -- "500"
```

## State Management

The system automatically saves/loads state through GameStateEngine. No manual intervention needed.

```lua
-- State is automatically persisted
-- All statistics, streaks, and milestones are preserved across sessions
```

## Example Usage

### Display Company Overview
```lua
local company = statsSystem:getCompanyInfo()
local contracts = statsSystem:getContractStats()

print("Company: " .. company.name)
print("Tier: " .. company.tier)
print("Contracts Completed: " .. contracts.totalCompleted)
print("Current Streak: " .. contracts.currentStreak)
print("Total Revenue: $" .. statsSystem:formatNumber(contracts.totalRevenue))
```

### Display Performance Summary
```lua
local performance = statsSystem:getPerformanceMetrics()
local incidentSuccessRate = statsSystem:getSuccessRate()
local contractSuccessRate = statsSystem:getContractSuccessRate()

print("Performance Summary")
print("==================")
print("SLA Compliance: " .. string.format("%.1f%%", performance.currentSLACompliance * 100))
print("Incident Success: " .. string.format("%.1f%%", incidentSuccessRate))
print("Contract Success: " .. string.format("%.1f%%", contractSuccessRate))
print("Financial Health: " .. performance.financialHealth)
print("Workload: " .. performance.workloadStatus)
print("Efficiency: " .. string.format("%.1f%%", performance.efficiencyRating * 100))
```

### Check Milestone Progress
```lua
local milestones = statsSystem:getMilestones()

print("Milestones:")
print("  First Contract: " .. (milestones.firstContract and "✓" or "✗"))
print("  10 Contracts: " .. (milestones.first10Contracts and "✓" or "✗"))
print("  100 Incidents: " .. (milestones.first100Incidents and "✓" or "✗"))
print("  10 Specialists: " .. (milestones.hire10Specialists and "✓" or "✗"))
print("  $1M Revenue: " .. (milestones.reach1MRevenue and "✓" or "✗"))
```

### Display Incident Statistics
```lua
local incidents = statsSystem:getIncidentStats()

print("Incident Statistics")
print("==================")
print("Total Generated: " .. incidents.totalGenerated)
print("Resolved: " .. incidents.totalResolved)
print("Failed: " .. incidents.totalFailed)
print("Auto-Resolved: " .. incidents.totalAutoResolved)

if incidents.totalResolved > 0 then
    print("Average Time: " .. string.format("%.1fs", incidents.averageResolutionTime))
    print("Fastest: " .. string.format("%.1fs", incidents.fastestResolution))
    print("Slowest: " .. string.format("%.1fs", incidents.slowestResolution))
end
```

## Best Practices

1. **Use Getters**: Always use getter methods instead of accessing `stats` directly
2. **Check for Nil**: Some values may be 0 or nil on first access
3. **Subscribe to Events**: Listen to `milestone_unlocked` for real-time notifications
4. **Dashboard Data**: Use `getDashboardData()` for UI display (already formatted)
5. **Number Formatting**: Use `formatNumber()` for displaying large values

## Performance Notes

- Stats update in real-time via event subscriptions
- Performance metrics recalculated every 5 seconds (not every frame)
- Minimal overhead - no polling or heavy calculations
- All state is preserved through GameStateEngine

## Integration Example

### Creating a Stats Display Scene
```lua
function StatsScene:draw()
    local dashboard = systems.globalStatsSystem:getDashboardData()
    
    -- Draw company overview
    local y = 50
    love.graphics.print(dashboard.overview.companyName, 50, y)
    love.graphics.print("Tier: " .. dashboard.overview.tier, 50, y + 30)
    
    -- Draw key metrics
    y = y + 80
    for _, metric in ipairs(dashboard.keyMetrics) do
        love.graphics.print(metric.label .. ": " .. metric.value, 50, y)
        y = y + 25
    end
    
    -- Draw performance indicators
    y = y + 30
    love.graphics.print("Performance:", 50, y)
    y = y + 25
    love.graphics.print("Reputation: " .. dashboard.performance.reputationTrend, 50, y)
    love.graphics.print("Financial: " .. dashboard.performance.financialHealth, 250, y)
    y = y + 25
    love.graphics.print("Workload: " .. dashboard.performance.workloadStatus, 50, y)
end
```

## Troubleshooting

### Stats Not Updating
- Verify system is initialized: `systems.globalStatsSystem:initialize()`
- Check event subscriptions are active
- Ensure events include required data (tier, revenue, etc.)

### Milestones Not Unlocking
- Check that `checkMilestones()` is being called
- Verify milestone thresholds are correct
- Subscribe to `milestone_unlocked` to see when they trigger

### Performance Metrics Incorrect
- Performance updates every 5 seconds
- Ensure ResourceManager is accessible
- Check that enough time has passed (> 5 seconds)

## See Also

- `docs/PHASE3_IMPLEMENTATION_SUMMARY.md` - Complete implementation details
- `tests/systems/test_global_stats_system.lua` - Usage examples
- `tests/integration/test_global_stats_integration.lua` - Integration test
