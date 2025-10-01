-- Data-driven configuration for SOC Idle Operations
-- Expose passiveOperations defaults and automationLevels to make content additions trivial

local soc_operations = {}

soc_operations.passiveOperations = {
    threatMonitoring = {
        enabled = false,
        interval = 10.0,
        lastCheck = 0,
        effectivenessRate = 0.1
    },
    incidentResponse = {
        enabled = false,
        interval = 15.0,
        lastResponse = 0,
        successRate = 0.05
    },
    resourceGeneration = {
        enabled = true,
        baseRate = 1.0,
        reputationRate = 0.1,
        lastGeneration = 0
    },
    skillImprovement = {
        enabled = false,
        interval = 60.0,
        lastImprovement = 0,
        xpRate = 1.0
    }
}

soc_operations.automationLevels = {
    MANUAL = {
        name = "Manual Operations",
        threatMonitoring = 0,
        incidentResponse = 0,
        resourceMultiplier = 1.0,
        description = "All operations require manual intervention"
    },
    BASIC = {
        name = "Basic Automation",
        threatMonitoring = 0.2,
        incidentResponse = 0.1,
        resourceMultiplier = 1.2,
        description = "Simple alerts and basic response automation"
    },
    INTERMEDIATE = {
        name = "Intermediate SOC",
        threatMonitoring = 0.5,
        incidentResponse = 0.3,
        resourceMultiplier = 1.5,
        description = "Advanced monitoring with partial incident automation"
    },
    ADVANCED = {
        name = "Advanced SOC",
        threatMonitoring = 0.8,
        incidentResponse = 0.6,
        resourceMultiplier = 2.0,
        description = "Comprehensive automation with AI-assisted response"
    },
    ENTERPRISE = {
        name = "Enterprise SOC",
        threatMonitoring = 0.95,
        incidentResponse = 0.85,
        resourceMultiplier = 3.0,
        description = "Fully automated SOC with predictive capabilities"
    }
}

-- Registration helpers (simple API for content authors)
function soc_operations.registerAutomationLevel(key, definition)
    soc_operations.automationLevels[key] = definition
end

function soc_operations.registerPassiveOperation(name, definition)
    soc_operations.passiveOperations[name] = definition
end

return soc_operations
