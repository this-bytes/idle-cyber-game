-- Idle Mechanics System
-- Handles offline progress calculations including earnings and cybersecurity damage
-- Core focus: Realistic threat-based damage while player is away

local IdleSystem = {}
IdleSystem.__index = IdleSystem

-- Create new idle system
function IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    local self = setmetatable({}, IdleSystem)
    self.eventBus = eventBus
    self.resourceSystem = resourceSystem
    self.threatSystem = threatSystem
    self.upgradeSystem = upgradeSystem
    
    -- Idle progress tracking
    self.lastSaveTime = os.time()
    self.idleData = {
        totalEarnings = 0,
        totalDamage = 0,
        threatEvents = {},
        mitigationEvents = {}
    }
    
    -- Threat patterns for different attack types
    self.threatTypes = {
        -- Common threats - occur frequently, low damage
        phishing = {
            name = "Phishing Attack",
            baseFrequency = 300, -- Every 5 minutes on average
            baseDamage = 50,
            description = "Email-based social engineering attempt"
        },
        malware = {
            name = "Malware Detection",
            baseFrequency = 600, -- Every 10 minutes on average
            baseDamage = 100,
            description = "Malicious software infiltration attempt"
        },
        
        -- Medium threats - moderate frequency, medium damage
        bruteforce = {
            name = "Brute Force Attack",
            baseFrequency = 1800, -- Every 30 minutes on average
            baseDamage = 200,
            description = "Automated password cracking attempt"
        },
        ddos = {
            name = "DDoS Attack",
            baseFrequency = 3600, -- Every hour on average
            baseDamage = 300,
            description = "Distributed denial of service attack"
        },
        
        -- Severe threats - rare but high damage
        apt = {
            name = "Advanced Persistent Threat",
            baseFrequency = 7200, -- Every 2 hours on average
            baseDamage = 800,
            description = "Sophisticated long-term infiltration"
        },
        zeroday = {
            name = "Zero-Day Exploit",
            baseFrequency = 14400, -- Every 4 hours on average
            baseDamage = 1200,
            description = "Previously unknown vulnerability exploitation"
        }
    }
    
    return self
end

-- Calculate offline progress for given idle time
function IdleSystem:calculateOfflineProgress(idleTimeSeconds)
    if not idleTimeSeconds or idleTimeSeconds <= 0 then
        return {
            earnings = 0,
            damage = 0,
            netGain = 0,
            events = {}
        }
    end
    
    -- Get current player state (compatible with fortress ResourceManager)
    local resources = {}
    if self.resourceSystem.getResources then
        resources = self.resourceSystem:getResources()
    else
        -- Fortress ResourceManager compatibility
        resources = {
            money = self.resourceSystem:getResource("money") or 1000,
            reputation = self.resourceSystem:getResource("reputation") or 0
        }
    end
    
    local threatReduction = 0
    if self.threatSystem and self.threatSystem.threatReduction then
        threatReduction = self.threatSystem.threatReduction
    end
    
    local securityRating = self:calculateSecurityRating()
    
    -- Calculate base earnings (from existing resource generation)
    local baseEarningsPerSecond = 0
    if self.resourceSystem.generation and self.resourceSystem.generation.money then
        baseEarningsPerSecond = self.resourceSystem.generation.money
    else
        -- Use default idle earnings based on reputation
        baseEarningsPerSecond = (resources.reputation or 0) * 0.1
    end
    local totalEarnings = math.floor(baseEarningsPerSecond * idleTimeSeconds)
    
    -- Apply idle earnings bonus if resource generation is low (help early game)
    if baseEarningsPerSecond < 100 then
        local idleBonus = math.min(1000, 200 + securityRating * 500) -- 200-700 per second based on security
        totalEarnings = totalEarnings + math.floor(idleBonus * idleTimeSeconds)
    end
    
    -- Calculate threats and damage over idle period
    local damageEvents = self:simulateThreats(idleTimeSeconds, threatReduction, securityRating)
    local totalDamage = 0
    
    for _, event in ipairs(damageEvents) do
        totalDamage = totalDamage + event.damage
    end
    
    -- Apply damage caps to prevent complete resource loss
    local maxDamagePercent = math.max(0.1, 0.3 - securityRating * 0.2) -- 10%-30% based on security
    local maxDamage = math.floor(resources.money * maxDamagePercent)
    totalDamage = math.min(totalDamage, maxDamage)
    
    -- Calculate net progress
    local netGain = totalEarnings - totalDamage
    
    return {
        earnings = totalEarnings,
        damage = totalDamage,
        netGain = netGain,
        events = damageEvents,
        idleTime = idleTimeSeconds
    }
end

-- Simulate cyber threats during idle period
function IdleSystem:simulateThreats(idleTimeSeconds, threatReduction, securityRating)
    local events = {}
    local currentTime = 0
    
    -- Simulate each threat type
    for threatId, threat in pairs(self.threatTypes) do
        -- Calculate adjusted frequency based on security
        local adjustedFrequency = threat.baseFrequency * (1 + securityRating * 0.5)
        
        -- Simulate threat occurrences using Poisson distribution approximation
        local expectedEvents = idleTimeSeconds / adjustedFrequency
        local actualEvents = self:poissonSample(expectedEvents)
        
        for i = 1, actualEvents do
            -- Calculate damage with advanced threat mitigation
            local baseDamage = threat.baseDamage
            local mitigation = self:calculateThreatMitigation(threatId, securityRating, threatReduction)
            local reducedDamage = baseDamage * (1 - mitigation)
            
            -- Add some randomness to damage
            local variance = 0.3 -- ±30% variance
            local damageMultiplier = 1 + (math.random() - 0.5) * variance * 2
            local finalDamage = math.floor(reducedDamage * damageMultiplier)
            
            -- Create event record
            table.insert(events, {
                type = threatId,
                name = threat.name,
                description = threat.description,
                damage = math.max(0, finalDamage),
                timestamp = currentTime + (i * adjustedFrequency / actualEvents),
                mitigated = mitigation > 0.1, -- Consider mitigated if >10% reduction
                mitigationLevel = mitigation
            })
        end
    end
    
    -- Sort events by timestamp
    table.sort(events, function(a, b) return a.timestamp < b.timestamp end)
    
    return events
end

-- Simple Poisson distribution sampling for threat frequency
function IdleSystem:poissonSample(lambda)
    if lambda <= 0 then return 0 end
    
    -- Use simple approximation for small lambda values
    if lambda < 10 then
        local L = math.exp(-lambda)
        local k = 0
        local p = 1
        
        repeat
            k = k + 1
            p = p * math.random()
        until p <= L
        
        return k - 1
    else
        -- For larger lambda, use normal approximation
        local mean = lambda
        local stddev = math.sqrt(lambda)
        local normal = self:normalRandom(mean, stddev)
        return math.max(0, math.floor(normal + 0.5))
    end
end

-- Generate normal random number using Box-Muller transform
function IdleSystem:normalRandom(mean, stddev)
    if not self._hasSpare then
        self._hasSpare = true
        local u = math.random()
        local v = math.random()
        local mag = stddev * math.sqrt(-2 * math.log(u))
        self._spare = mean + mag * math.cos(2 * math.pi * v)
        return mean + mag * math.sin(2 * math.pi * v)
    else
        self._hasSpare = false
        return self._spare
    end
end

-- Calculate current security rating from upgrades
function IdleSystem:calculateSecurityRating()
    local totalRating = 0
    
    -- Compatibility with fortress SecurityUpgrades system
    if self.upgradeSystem and self.upgradeSystem.owned then
        -- Legacy upgrade system
        for upgradeId, count in pairs(self.upgradeSystem.owned) do
            local upgrade = self.upgradeSystem.upgrades and self.upgradeSystem.upgrades[upgradeId]
            if upgrade and upgrade.effects then
                if upgrade.effects.securityRating then
                    totalRating = totalRating + (upgrade.effects.securityRating * count)
                end
                -- Also consider threat reduction upgrades
                if upgrade.effects.threatReduction then
                    -- Convert threat reduction to security rating equivalent
                    totalRating = totalRating + (upgrade.effects.threatReduction * 100 * count)
                end
            end
        end
    elseif self.upgradeSystem and self.upgradeSystem.getOwnedUpgrades then
        -- Fortress SecurityUpgrades system
        local ownedUpgrades = self.upgradeSystem:getOwnedUpgrades()
        for _, upgrade in ipairs(ownedUpgrades) do
            if upgrade.threatReduction then
                totalRating = totalRating + (upgrade.threatReduction * 10) -- Convert to rating scale
            end
            if upgrade.detectionImprovement then
                totalRating = totalRating + (upgrade.detectionImprovement * 5)
            end
        end
    end
    
    -- Add base security from experience (cyber skills progression)
    local xp = 0
    if self.resourceSystem.getResources then
        local resources = self.resourceSystem:getResources()
        xp = resources.xp or 0
    elseif self.resourceSystem.getResource then
        xp = self.resourceSystem:getResource("xp") or 0
    end
    
    local xpSecurityBonus = math.floor(xp / 100) * 10 -- +10 security per 100 XP
    totalRating = totalRating + xpSecurityBonus
    
    -- Convert to normalized rating (0.0 to 1.0)
    -- Assume max practical security rating of 1000 for balanced gameplay
    return math.min(totalRating / 1000, 1.0)
end

-- Advanced threat mitigation based on player's security infrastructure
function IdleSystem:calculateThreatMitigation(threatType, securityRating, threatReduction)
    local mitigation = threatReduction -- Base from threat system
    
    -- Different security infrastructures are better against different threats
    local specializedDefenses = {
        phishing = self:getUpgradeCount("emailFilter") * 0.1,
        malware = self:getUpgradeCount("antivirus") * 0.15,
        bruteforce = self:getUpgradeCount("accessControl") * 0.2,
        ddos = self:getUpgradeCount("trafficShaping") * 0.25,
        apt = self:getUpgradeCount("threatIntelligence") * 0.3,
        zeroday = self:getUpgradeCount("behavioralAnalysis") * 0.35
    }
    
    -- Add specialized defense bonus
    local specialized = specializedDefenses[threatType] or 0
    mitigation = mitigation + specialized
    
    -- Add general security rating bonus (diminishing returns)
    local generalBonus = securityRating * 0.5 * (1 - mitigation) -- Less effective if already high mitigation
    mitigation = mitigation + generalBonus
    
    -- Cap at 95% mitigation (never 100% secure)
    return math.min(mitigation, 0.95)
end

-- Helper function to get upgrade counts (with fallback for non-existent upgrades)
function IdleSystem:getUpgradeCount(upgradeId)
    return self.upgradeSystem.owned[upgradeId] or 0
end

-- Apply offline progress to game state
function IdleSystem:applyOfflineProgress(progress)
    if not progress or progress.netGain == 0 then
        return
    end
    
    -- Apply net resource change
    if progress.netGain > 0 then
        self.resourceSystem:addResource("money", progress.netGain)
        print("💰 Net offline gain: $" .. progress.netGain)
    elseif progress.netGain < 0 then
        self.resourceSystem:spendResources({money = -progress.netGain})
        print("⚠️ Net offline loss: $" .. (-progress.netGain))
    end
    
    -- Award experience for surviving threats
    local xpGained = math.floor(#progress.events * 10)
    if xpGained > 0 then
        self.resourceSystem:addResource("xp", xpGained)
        print("🎓 Experience gained from threat handling: " .. xpGained)
    end
    
    -- Store event data for UI display
    self.idleData = progress
    
    -- Publish event for UI to show offline summary
    self.eventBus:publish("offline_progress_calculated", progress)
end

-- Get idle progress data for UI display
function IdleSystem:getIdleData()
    return self.idleData
end

-- Update save timestamp
function IdleSystem:updateSaveTime()
    self.lastSaveTime = os.time()
end

-- Get state for saving
function IdleSystem:getState()
    return {
        lastSaveTime = self.lastSaveTime,
        idleData = self.idleData
    }
end

-- Load state from save
function IdleSystem:loadState(state)
    if state.lastSaveTime then
        self.lastSaveTime = state.lastSaveTime
    end
    if state.idleData then
        self.idleData = state.idleData
    end
end

return IdleSystem