-- SOC Idle Operations - Automated SOC Management
-- Handles SOC operations when player is not actively managing
-- Implements realistic SOC automation and passive security improvements

local SOCIdleOperations = {}
SOCIdleOperations.__index = SOCIdleOperations

-- Create new SOC idle operations system
function SOCIdleOperations.new(eventBus, resourceManager, threatSimulation, securityUpgrades)
    local self = setmetatable({}, SOCIdleOperations)
    
    -- Core dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.threatSimulation = threatSimulation
    self.securityUpgrades = securityUpgrades
    
    -- Idle tracking
    self.lastUpdateTime = love.timer.getTime()
    self.passiveOperations = {
        threatMonitoring = {
            enabled = false,
            interval = 10.0, -- Check every 10 seconds
            lastCheck = 0,
            effectivenessRate = 0.1 -- Base 10% automation
        },
        incidentResponse = {
            enabled = false,
            interval = 15.0, -- Respond every 15 seconds
            lastResponse = 0,
            successRate = 0.05 -- Base 5% auto-resolve
        },
        resourceGeneration = {
            enabled = true,
            baseRate = 1.0, -- $1 per second base
            reputationRate = 0.1, -- 0.1 reputation per 10 successful operations
            lastGeneration = 0
        },
        skillImprovement = {
            enabled = false,
            interval = 60.0, -- Skill improvement every minute
            lastImprovement = 0,
            xpRate = 1.0 -- 1 XP per minute base
        }
    }
    
    -- SOC automation levels
    self.automationLevels = {
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
    
    self.currentAutomationLevel = "MANUAL"
    
    return self
end

-- Initialize SOC idle operations
function SOCIdleOperations:initialize()
    self.lastUpdateTime = love.timer.getTime()
    
    -- Subscribe to relevant events
    self.eventBus:subscribe("soc_level_upgraded", function(data)
        self:updateAutomationLevel(data.level)
    end)
    
    self.eventBus:subscribe("security_upgrade_purchased", function(data)
        self:updateAutomationCapabilities()
    end)
    
    print("⚙️ SOCIdleOperations: Initialized SOC automation systems")
end

-- Update SOC idle operations
function SOCIdleOperations:update(dt)
    local currentTime = love.timer.getTime()
    
    -- Update all passive systems
    self:updateThreatMonitoring(dt)
    self:updateIncidentResponse(dt)
    self:updateResourceGeneration(dt)
    self:updateSkillImprovement(dt)
    
    self.lastUpdateTime = currentTime
end

-- Update threat monitoring automation
function SOCIdleOperations:updateThreatMonitoring(dt)
    local monitoring = self.passiveOperations.threatMonitoring
    
    if not monitoring.enabled then
        return
    end
    
    monitoring.lastCheck = monitoring.lastCheck + dt
    
    if monitoring.lastCheck >= monitoring.interval then
        monitoring.lastCheck = 0
        
        -- Automated threat detection based on automation level
        local automationLevel = self.automationLevels[self.currentAutomationLevel]
        local detectionChance = automationLevel.threatMonitoring
        
        if math.random() < detectionChance then
            -- Generate and automatically handle a threat
            local threat = self:generateAutomatedThreat()
            if threat then
                self.eventBus:publish("threat_detected_auto", threat)
                
                -- Award XP for automated detection
                self.resourceManager:addResource("xp", 2)
                
                print("🤖 SOC Automation: Detected and catalogued " .. threat.name)
            end
        end
    end
end

-- Update incident response automation
function SOCIdleOperations:updateIncidentResponse(dt)
    local response = self.passiveOperations.incidentResponse
    
    if not response.enabled then
        return
    end
    
    response.lastResponse = response.lastResponse + dt
    
    if response.lastResponse >= response.interval then
        response.lastResponse = 0
        
        -- Automated incident resolution
        local automationLevel = self.automationLevels[self.currentAutomationLevel]
        local responseChance = automationLevel.incidentResponse
        
        if math.random() < responseChance then
            -- Simulate resolving a background incident
            local incident = self:generateBackgroundIncident()
            if incident then
                self:autoResolveIncident(incident)
            end
        end
    end
end

-- Update resource generation from SOC operations
function SOCIdleOperations:updateResourceGeneration(dt)
    local generation = self.passiveOperations.resourceGeneration
    
    generation.lastGeneration = generation.lastGeneration + dt
    
    -- Generate resources every second
    if generation.lastGeneration >= 1.0 then
        generation.lastGeneration = 0
        
        local automationLevel = self.automationLevels[self.currentAutomationLevel]
        local multiplier = automationLevel.resourceMultiplier
        
        -- Base passive income from SOC operations
        local baseIncome = generation.baseRate * multiplier
        
        -- Bonus from reputation (clients trust automated SOC)
        local reputation = self.resourceManager:getResource("reputation") or 0
        local reputationBonus = reputation * 0.1 * multiplier
        
        -- Bonus from security upgrades (better tools = more efficient operations)
        local upgradeBonus = self:calculateUpgradeBonus() * multiplier
        
        local totalIncome = baseIncome + reputationBonus + upgradeBonus
        
        if totalIncome > 0 then
            self.resourceManager:addResource("money", math.floor(totalIncome))
            
            -- Occasional reputation gain from successful operations
            if math.random() < 0.1 then -- 10% chance each second
                self.resourceManager:addResource("reputation", math.floor(0.1 * multiplier))
            end
        end
    end
end

-- Update skill improvement from automated operations
function SOCIdleOperations:updateSkillImprovement(dt)
    local skill = self.passiveOperations.skillImprovement
    
    if not skill.enabled then
        return
    end
    
    skill.lastImprovement = skill.lastImprovement + dt
    
    if skill.lastImprovement >= skill.interval then
        skill.lastImprovement = 0
        
        -- Gain XP from automated learning
        local automationLevel = self.automationLevels[self.currentAutomationLevel]
        local xpGain = skill.xpRate * automationLevel.resourceMultiplier
        
        self.resourceManager:addResource("xp", math.floor(xpGain))
        
        print("📚 SOC Learning: Gained " .. math.floor(xpGain) .. " XP from automated operations")
    end
end

-- Update automation level based on SOC progression
function SOCIdleOperations:updateAutomationLevel(level)
    local newAutomationLevel = "MANUAL"
    
    if level == "STARTING" then
        newAutomationLevel = "MANUAL"
    elseif level == "BASIC" then
        newAutomationLevel = "BASIC"
    elseif level == "ADVANCED" then
        newAutomationLevel = "INTERMEDIATE"
    elseif level == "ENTERPRISE" then
        newAutomationLevel = "ADVANCED"
    end
    
    if newAutomationLevel ~= self.currentAutomationLevel then
        self.currentAutomationLevel = newAutomationLevel
        self:enableAutomationFeatures(newAutomationLevel)
        
        local automationInfo = self.automationLevels[newAutomationLevel]
        print("🤖 SOC Automation upgraded to: " .. automationInfo.name)
        print("   " .. automationInfo.description)
    end
end

-- Enable automation features based on level
function SOCIdleOperations:enableAutomationFeatures(level)
    local automationLevel = self.automationLevels[level]
    
    -- Enable/disable systems based on capabilities
    self.passiveOperations.threatMonitoring.enabled = automationLevel.threatMonitoring > 0
    self.passiveOperations.incidentResponse.enabled = automationLevel.incidentResponse > 0
    self.passiveOperations.skillImprovement.enabled = automationLevel.resourceMultiplier > 1.0
    
    -- Update effectiveness rates
    self.passiveOperations.threatMonitoring.effectivenessRate = automationLevel.threatMonitoring
    self.passiveOperations.incidentResponse.successRate = automationLevel.incidentResponse
end

-- Update automation capabilities based on security upgrades
function SOCIdleOperations:updateAutomationCapabilities()
    -- Check if automation-enhancing upgrades are present
    if self.securityUpgrades then
        local ownedUpgrades = self.securityUpgrades:getOwnedUpgrades() or {}
        
        local automationBonus = 0
        for _, upgrade in ipairs(ownedUpgrades) do
            if upgrade.category == "tools" then
                automationBonus = automationBonus + 0.1 -- Tools improve automation
            elseif upgrade.category == "research" then
                automationBonus = automationBonus + 0.05 -- Research improves efficiency
            end
        end
        
        -- Apply automation bonuses to intervals (faster operations)
        if automationBonus > 0 then
            self.passiveOperations.threatMonitoring.interval = math.max(5.0, 10.0 - automationBonus)
            self.passiveOperations.incidentResponse.interval = math.max(8.0, 15.0 - automationBonus)
        end
    end
end

-- Calculate upgrade bonus for resource generation
function SOCIdleOperations:calculateUpgradeBonus()
    if not self.securityUpgrades then
        return 0
    end
    
    local ownedUpgrades = self.securityUpgrades:getOwnedUpgrades() or {}
    local bonus = 0
    
    for _, upgrade in ipairs(ownedUpgrades) do
        if upgrade.category == "infrastructure" then
            bonus = bonus + 0.5 -- Infrastructure provides steady income
        elseif upgrade.category == "personnel" then
            bonus = bonus + 0.3 -- Personnel improves efficiency
        elseif upgrade.category == "tools" then
            bonus = bonus + 0.2 -- Tools reduce operational costs
        end
    end
    
    return bonus
end

-- Generate automated threat for background processing
function SOCIdleOperations:generateAutomatedThreat()
    local automatedThreats = {
        {name = "Automated Malware Scan", severity = "low", impact = "Background threat catalogued"},
        {name = "Port Scan Detection", severity = "low", impact = "Reconnaissance attempt logged"},
        {name = "Suspicious Traffic Analysis", severity = "medium", impact = "Traffic pattern analyzed"},
        {name = "Endpoint Anomaly", severity = "medium", impact = "Endpoint behavior monitored"}
    }
    
    local threat = automatedThreats[math.random(#automatedThreats)]
    threat.id = "auto_threat_" .. os.time() .. "_" .. math.random(1000)
    threat.automated = true
    
    return threat
end

-- Generate background incident for automation practice
function SOCIdleOperations:generateBackgroundIncident()
    local backgroundIncidents = {
        {name = "Log Analysis Completed", severity = "maintenance", impact = "System optimization"},
        {name = "Signature Update", severity = "maintenance", impact = "Security database updated"},
        {name = "Health Check Performed", severity = "maintenance", impact = "System status verified"},
        {name = "Backup Verification", severity = "maintenance", impact = "Data integrity confirmed"}
    }
    
    local incident = backgroundIncidents[math.random(#backgroundIncidents)]
    incident.id = "auto_incident_" .. os.time() .. "_" .. math.random(1000)
    incident.automated = true
    
    return incident
end

-- Auto-resolve incident through automation
function SOCIdleOperations:autoResolveIncident(incident)
    print("✅ SOC Automation: Auto-resolved " .. incident.name)
    
    -- Award resources for successful automation
    self.resourceManager:addResource("xp", 3)
    if math.random() < 0.2 then -- 20% chance for reputation gain
        self.resourceManager:addResource("reputation", 1)
    end
    
    self.eventBus:publish("incident_resolved_auto", incident)
end

-- Get automation status for UI display
function SOCIdleOperations:getAutomationStatus()
    local automationLevel = self.automationLevels[self.currentAutomationLevel]
    
    return {
        level = self.currentAutomationLevel,
        name = automationLevel.name,
        description = automationLevel.description,
        threatMonitoring = automationLevel.threatMonitoring * 100,
        incidentResponse = automationLevel.incidentResponse * 100,
        resourceMultiplier = automationLevel.resourceMultiplier,
        operations = {
            threatMonitoring = self.passiveOperations.threatMonitoring,
            incidentResponse = self.passiveOperations.incidentResponse,
            resourceGeneration = self.passiveOperations.resourceGeneration,
            skillImprovement = self.passiveOperations.skillImprovement
        }
    }
end

-- Calculate offline progress when player returns
function SOCIdleOperations:calculateOfflineProgress(offlineTimeSeconds)
    if offlineTimeSeconds <= 0 then
        return {
            income = 0,
            threatsHandled = 0,
            incidentsResolved = 0,
            xpGained = 0,
            reputationGained = 0,
            summary = "No offline time detected"
        }
    end
    
    local automationLevel = self.automationLevels[self.currentAutomationLevel]
    
    -- Calculate offline income
    local baseIncomePerSecond = self.passiveOperations.resourceGeneration.baseRate * automationLevel.resourceMultiplier
    local reputation = self.resourceManager:getResource("reputation") or 0
    local reputationBonus = reputation * 0.1 * automationLevel.resourceMultiplier
    local upgradeBonus = self:calculateUpgradeBonus() * automationLevel.resourceMultiplier
    
    local totalIncomePerSecond = baseIncomePerSecond + reputationBonus + upgradeBonus
    local totalIncome = math.floor(totalIncomePerSecond * offlineTimeSeconds)
    
    -- Calculate offline threat handling
    local threatInterval = self.passiveOperations.threatMonitoring.interval
    local possibleThreats = math.floor(offlineTimeSeconds / threatInterval)
    local threatsHandled = math.floor(possibleThreats * automationLevel.threatMonitoring)
    
    -- Calculate offline incident resolution
    local incidentInterval = self.passiveOperations.incidentResponse.interval
    local possibleIncidents = math.floor(offlineTimeSeconds / incidentInterval)
    local incidentsResolved = math.floor(possibleIncidents * automationLevel.incidentResponse)
    
    -- Calculate offline XP and reputation
    local xpPerMinute = self.passiveOperations.skillImprovement.xpRate * automationLevel.resourceMultiplier
    local xpGained = math.floor((offlineTimeSeconds / 60) * xpPerMinute)
    
    local reputationGained = math.floor((threatsHandled + incidentsResolved) * 0.1)
    
    -- Generate summary
    local hours = math.floor(offlineTimeSeconds / 3600)
    local minutes = math.floor((offlineTimeSeconds % 3600) / 60)
    local timeString = hours > 0 and (hours .. "h " .. minutes .. "m") or (minutes .. "m")
    
    local summary = string.format(
        "SOC operated autonomously for %s\n" ..
        "Automation Level: %s\n" ..
        "Income: $%d | Threats: %d | Incidents: %d\n" ..
        "XP: %d | Reputation: %d",
        timeString, automationLevel.name, totalIncome, threatsHandled, incidentsResolved, xpGained, reputationGained
    )
    
    return {
        income = totalIncome,
        threatsHandled = threatsHandled,
        incidentsResolved = incidentsResolved,
        xpGained = xpGained,
        reputationGained = reputationGained,
        summary = summary,
        offlineTime = offlineTimeSeconds
    }
end

-- Get state for saving
function SOCIdleOperations:getState()
    return {
        currentAutomationLevel = self.currentAutomationLevel,
        passiveOperations = self.passiveOperations,
        lastUpdateTime = self.lastUpdateTime
    }
end

-- Load state from save
function SOCIdleOperations:loadState(state)
    if state then
        self.currentAutomationLevel = state.currentAutomationLevel or "MANUAL"
        self.passiveOperations = state.passiveOperations or self.passiveOperations
        self.lastUpdateTime = state.lastUpdateTime or love.timer.getTime()
        
        -- Re-enable automation features
        self:enableAutomationFeatures(self.currentAutomationLevel)
        
        print("⚙️ SOCIdleOperations: State loaded - Automation Level: " .. self.currentAutomationLevel)
    end
end

return SOCIdleOperations