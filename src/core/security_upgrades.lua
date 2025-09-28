-- SecurityUpgrades - Cybersecurity-Themed Upgrade Management System
-- Fortress Refactor: Specialized upgrade system for cybersecurity business progression
-- Handles defensive infrastructure, security tools, and threat mitigation upgrades

local SecurityUpgrades = {}
SecurityUpgrades.__index = SecurityUpgrades

-- Upgrade categories aligned with cybersecurity business
local UPGRADE_CATEGORIES = {
    INFRASTRUCTURE = "infrastructure", -- Firewalls, servers, network security
    TOOLS = "tools",                  -- Software, analysis tools, automation
    PERSONNEL = "personnel",          -- Training, specialists, expertise
    RESEARCH = "research",            -- New techniques, threat intelligence
    FACILITIES = "facilities"         -- Office, equipment, capacity
}

-- Create new security upgrades system
function SecurityUpgrades.new(eventBus, resourceManager)
    local self = setmetatable({}, SecurityUpgrades)
    
    -- Core dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- Upgrade tracking
    self.owned = {}
    self.upgradeDefinitions = {}
    
    -- Initialize upgrade catalog
    self:initializeUpgrades()
    
    return self
end

-- Initialize the cybersecurity upgrade catalog
function SecurityUpgrades:initializeUpgrades()
    -- Infrastructure Upgrades - Core Security Systems
    self:defineUpgrade("basicFirewall", {
        name = "🔥 Basic Firewall",
        description = "Network perimeter defense against common threats",
        category = UPGRADE_CATEGORIES.INFRASTRUCTURE,
        tier = 1,
        maxCount = 1,
        baseCost = {money = 500},
        effects = {
            threatReduction = 0.1,
            moneyGeneration = 2 -- Clients pay more for better security
        },
        unlockRequirements = {}
    })
    
    self:defineUpgrade("enterpriseFirewall", {
        name = "🔥 Enterprise Firewall",
        description = "Advanced firewall with deep packet inspection",
        category = UPGRADE_CATEGORIES.INFRASTRUCTURE,
        tier = 2,
        maxCount = 1,
        baseCost = {money = 2500, reputation = 10},
        effects = {
            threatReduction = 0.25,
            moneyGeneration = 5
        },
        unlockRequirements = {
            upgrades = {"basicFirewall"}
        }
    })
    
    self:defineUpgrade("intrusionDetection", {
        name = "👁️ Intrusion Detection System",
        description = "Real-time monitoring and threat detection",
        category = UPGRADE_CATEGORIES.INFRASTRUCTURE,
        tier = 2,
        maxCount = 1,
        baseCost = {money = 1500, xp = 50},
        effects = {
            threatReduction = 0.15,
            reputationGeneration = 1
        },
        unlockRequirements = {
            upgrades = {"basicFirewall"}
        }
    })
    
    -- Tools Upgrades - Security Software and Analysis
    self:defineUpgrade("vulnerabilityScanner", {
        name = "🔍 Vulnerability Scanner",
        description = "Automated security assessment tools",
        category = UPGRADE_CATEGORIES.TOOLS,
        tier = 1,
        maxCount = 1,
        baseCost = {money = 800},
        effects = {
            contractEfficiency = 0.2,
            xpGeneration = 1
        },
        unlockRequirements = {}
    })
    
    self:defineUpgrade("siem", {
        name = "📊 Security Information & Event Management",
        description = "Centralized log analysis and correlation",
        category = UPGRADE_CATEGORIES.TOOLS,
        tier = 3,
        maxCount = 1,
        baseCost = {money = 5000, reputation = 25, xp = 100},
        effects = {
            threatReduction = 0.3,
            contractEfficiency = 0.4,
            moneyGeneration = 8
        },
        unlockRequirements = {
            upgrades = {"vulnerabilityScanner", "intrusionDetection"}
        }
    })
    
    self:defineUpgrade("aiThreatDetection", {
        name = "🤖 AI Threat Detection",
        description = "Machine learning-powered threat analysis",
        category = UPGRADE_CATEGORIES.TOOLS,
        tier = 4,
        maxCount = 1,
        baseCost = {money = 15000, reputation = 50, xp = 200, missionTokens = 5},
        effects = {
            threatReduction = 0.5,
            contractEfficiency = 0.6,
            moneyGeneration = 15
        },
        unlockRequirements = {
            upgrades = {"siem"}
        }
    })
    
    -- Personnel Upgrades - Team and Training
    self:defineUpgrade("securityTraining", {
        name = "🎓 Security Awareness Training",
        description = "Improve team security knowledge and response",
        category = UPGRADE_CATEGORIES.PERSONNEL,
        tier = 1,
        maxCount = 5,
        baseCost = {money = 200, xp = 10},
        costGrowth = 1.5,
        effects = {
            threatReduction = 0.05,
            xpGeneration = 0.5
        },
        unlockRequirements = {}
    })
    
    self:defineUpgrade("seniorAnalyst", {
        name = "👨‍💻 Senior Security Analyst",
        description = "Experienced cybersecurity professional",
        category = UPGRADE_CATEGORIES.PERSONNEL,
        tier = 2,
        maxCount = 3,
        baseCost = {money = 3000, reputation = 15},
        costGrowth = 2.0,
        effects = {
            contractEfficiency = 0.3,
            moneyGeneration = 4,
            threatReduction = 0.1
        },
        unlockRequirements = {
            upgrades = {"securityTraining"}
        }
    })
    
    -- Research Upgrades - Advanced Capabilities
    self:defineUpgrade("threatIntelligence", {
        name = "🕵️ Threat Intelligence Platform",
        description = "Advanced threat research and intelligence sharing",
        category = UPGRADE_CATEGORIES.RESEARCH,
        tier = 3,
        maxCount = 1,
        baseCost = {money = 8000, reputation = 30, xp = 150},
        effects = {
            threatReduction = 0.35,
            reputationGeneration = 2,
            contractEfficiency = 0.25
        },
        unlockRequirements = {
            upgrades = {"seniorAnalyst"}
        }
    })
    
    -- Facilities Upgrades - Infrastructure and Capacity
    self:defineUpgrade("secureDataCenter", {
        name = "🏢 Secure Data Center",
        description = "Dedicated secure facility for sensitive operations",
        category = UPGRADE_CATEGORIES.FACILITIES,
        tier = 3,
        maxCount = 1,
        baseCost = {money = 10000, reputation = 40},
        effects = {
            storageIncrease = {
                contracts = 10,
                specialists = 5
            },
            moneyGeneration = 10,
            threatReduction = 0.2
        },
        unlockRequirements = {
            upgrades = {"threatIntelligence"}
        }
    })
    
    print("🛡️ SecurityUpgrades: Initialized cybersecurity upgrade catalog")
end

-- Define a new upgrade
function SecurityUpgrades:defineUpgrade(id, config)
    if not id or not config then
        error("SecurityUpgrades:defineUpgrade requires id and config")
    end
    
    -- Store upgrade definition
    config.id = id
    self.upgradeDefinitions[id] = config
    
    -- Initialize ownership tracking
    self.owned[id] = 0
    
    -- Notify listeners
    self.eventBus:publish("upgrade_defined", {
        id = id,
        config = config
    })
end

-- Check if upgrade can be purchased
function SecurityUpgrades:canPurchaseUpgrade(upgradeId)
    local upgrade = self.upgradeDefinitions[upgradeId]
    if not upgrade then
        return false, "Upgrade not found"
    end
    
    -- Check ownership limits
    if upgrade.maxCount and self.owned[upgradeId] >= upgrade.maxCount then
        return false, "Maximum count reached"
    end
    
    -- Check unlock requirements
    if upgrade.unlockRequirements and upgrade.unlockRequirements.upgrades then
        for _, requiredId in ipairs(upgrade.unlockRequirements.upgrades) do
            if self.owned[requiredId] == 0 then
                return false, "Missing required upgrade: " .. requiredId
            end
        end
    end
    
    -- Check resource requirements
    local cost = self:calculateUpgradeCost(upgradeId)
    if not self.resourceManager:canAfford(cost) then
        return false, "Insufficient resources"
    end
    
    return true
end

-- Calculate current cost of upgrade (considering growth)
function SecurityUpgrades:calculateUpgradeCost(upgradeId)
    local upgrade = self.upgradeDefinitions[upgradeId]
    if not upgrade then
        return {}
    end
    
    local currentCount = self.owned[upgradeId]
    local growthFactor = upgrade.costGrowth or 1.0
    local cost = {}
    
    for resource, baseCost in pairs(upgrade.baseCost) do
        cost[resource] = math.floor(baseCost * math.pow(growthFactor, currentCount))
    end
    
    return cost
end

-- Purchase an upgrade
function SecurityUpgrades:purchaseUpgrade(upgradeId)
    local canPurchase, reason = self:canPurchaseUpgrade(upgradeId)
    if not canPurchase then
        return false, reason
    end
    
    local upgrade = self.upgradeDefinitions[upgradeId]
    local cost = self:calculateUpgradeCost(upgradeId)
    
    -- Spend resources
    if not self.resourceManager:spendResources(cost) then
        return false, "Failed to spend resources"
    end
    
    -- Update ownership
    self.owned[upgradeId] = self.owned[upgradeId] + 1
    
    -- Apply upgrade effects
    self:applyUpgradeEffects(upgradeId, upgrade.effects)
    
    -- Publish events
    self.eventBus:publish("upgrade_purchased", {
        upgradeId = upgradeId,
        count = self.owned[upgradeId],
        cost = cost,
        effects = upgrade.effects
    })
    
    print("🛡️ SecurityUpgrades: Purchased " .. upgrade.name)
    return true
end

-- Apply upgrade effects
function SecurityUpgrades:applyUpgradeEffects(upgradeId, effects)
    for effectType, value in pairs(effects) do
        if effectType == "moneyGeneration" then
            self.resourceManager:addGeneration("money", value)
        elseif effectType == "reputationGeneration" then
            self.resourceManager:addGeneration("reputation", value)
        elseif effectType == "xpGeneration" then
            self.resourceManager:addGeneration("xp", value)
        elseif effectType == "threatReduction" then
            self.eventBus:publish("threat_reduction_increased", {
                amount = value,
                source = upgradeId
            })
        elseif effectType == "contractEfficiency" then
            self.eventBus:publish("contract_efficiency_increased", {
                amount = value,
                source = upgradeId
            })
        elseif effectType == "storageIncrease" then
            for resource, amount in pairs(value) do
                -- Apply storage increases through resource manager
                self.eventBus:publish("apply_upgrade_effect", {
                    upgradeId = upgradeId,
                    effectType = "storage",
                    value = {[resource] = amount}
                })
            end
        end
    end
end

-- Get available upgrades (can be purchased)
function SecurityUpgrades:getAvailableUpgrades()
    local available = {}
    
    for upgradeId, upgrade in pairs(self.upgradeDefinitions) do
        local canPurchase, reason = self:canPurchaseUpgrade(upgradeId)
        if canPurchase then
            available[upgradeId] = {
                upgrade = upgrade,
                cost = self:calculateUpgradeCost(upgradeId),
                owned = self.owned[upgradeId]
            }
        end
    end
    
    return available
end

-- Get upgrades by category
function SecurityUpgrades:getUpgradesByCategory(category)
    local categoryUpgrades = {}
    
    for upgradeId, upgrade in pairs(self.upgradeDefinitions) do
        if upgrade.category == category then
            categoryUpgrades[upgradeId] = {
                upgrade = upgrade,
                cost = self:calculateUpgradeCost(upgradeId),
                owned = self.owned[upgradeId],
                canPurchase = self:canPurchaseUpgrade(upgradeId)
            }
        end
    end
    
    return categoryUpgrades
end

-- Get upgrade count
function SecurityUpgrades:getUpgradeCount(upgradeId)
    return self.owned[upgradeId] or 0
end

-- Calculate total threat reduction from all upgrades
function SecurityUpgrades:getTotalThreatReduction()
    local totalReduction = 0
    
    for upgradeId, count in pairs(self.owned) do
        if count > 0 then
            local upgrade = self.upgradeDefinitions[upgradeId]
            if upgrade and upgrade.effects and upgrade.effects.threatReduction then
                totalReduction = totalReduction + (upgrade.effects.threatReduction * count)
            end
        end
    end
    
    -- Cap at 95% (never 100% secure)
    return math.min(totalReduction, 0.95)
end

-- Get comprehensive state
function SecurityUpgrades:getState()
    return {
        owned = self.owned
    }
end

-- Load state
function SecurityUpgrades:loadState(state)
    if not state then return end
    
    if state.owned then
        self.owned = state.owned
        
        -- Re-apply all upgrade effects
        for upgradeId, count in pairs(self.owned) do
            if count > 0 then
                local upgrade = self.upgradeDefinitions[upgradeId]
                if upgrade and upgrade.effects then
                    for i = 1, count do
                        self:applyUpgradeEffects(upgradeId, upgrade.effects)
                    end
                end
            end
        end
    end
    
    print("🛡️ SecurityUpgrades: State loaded successfully")
end

-- Initialize method for GameLoop integration
function SecurityUpgrades:initialize()
    print("🛡️ SecurityUpgrades: Fortress architecture integration complete")
end

-- Update method for GameLoop integration
function SecurityUpgrades:update(dt)
    -- Security upgrades don't need regular updates
    -- All effects are applied immediately when purchased
end

-- Shutdown method for GameLoop integration
function SecurityUpgrades:shutdown()
    print("🛡️ SecurityUpgrades: Shutdown complete")
end

return SecurityUpgrades
