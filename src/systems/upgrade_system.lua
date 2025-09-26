-- Upgrade Management System
-- Handles all upgrades, their costs, effects, and progression

local UpgradeSystem = {}
UpgradeSystem.__index = UpgradeSystem

-- Create new upgrade system
function UpgradeSystem.new(eventBus)
    local self = setmetatable({}, UpgradeSystem)
    self.eventBus = eventBus
    
    -- Player's owned upgrades
    self.owned = {}
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    -- Upgrade definitions from instruction files
    self.upgrades = {
        -- Manual Clicking Upgrades (Phase 1)
        ergonomicMouse = {
            id = "ergonomicMouse",
            name = "🖱️ Ergonomic Mouse",
            description = "Reduces hand strain, increases clicking efficiency",
            category = "clicking",
            tier = 1,
            maxCount = 1,
            baseCost = {dataBits = 5},
            costGrowth = 1.0,
            effects = {
                clickPower = 1 -- +1 DB per click
            },
            unlockRequirements = {}
        },
        
        mechanicalKeyboard = {
            id = "mechanicalKeyboard", 
            name = "⌨️ Mechanical Keyboard",
            description = "Tactile feedback improves data entry speed",
            category = "clicking",
            tier = 1,
            maxCount = 1,
            baseCost = {dataBits = 25},
            costGrowth = 1.0,
            effects = {
                clickPower = 2 -- +2 DB per click
            },
            unlockRequirements = {
                upgrades = {"ergonomicMouse"}
            }
        },
        
        gamingSetup = {
            id = "gamingSetup",
            name = "🎮 Gaming Setup",
            description = "High-end peripherals enable combo clicking",
            category = "clicking",
            tier = 1,
            maxCount = 1,
            baseCost = {dataBits = 100},
            costGrowth = 1.0,
            effects = {
                clickPower = 5,
                comboBonus = 0.5 -- Improved combo building
            },
            unlockRequirements = {
                upgrades = {"mechanicalKeyboard"}
            }
        },
        
        -- Server Infrastructure (Phase 1)
        refurbishedDesktop = {
            id = "refurbishedDesktop",
            name = "💻 Refurbished Desktop",
            description = "Your first automated data generation",
            category = "servers",
            tier = 1,
            maxCount = 10,
            baseCost = {dataBits = 10},
            costGrowth = 1.15,
            effects = {
                dataBitsGeneration = 0.1 -- 0.1 DB/sec per unit
            },
            unlockRequirements = {}
        },
        
        basicServerRack = {
            id = "basicServerRack",
            name = "🖥️ Basic Server Rack",
            description = "Professional server hardware",
            category = "servers",
            tier = 1,
            maxCount = 25,
            baseCost = {dataBits = 100},
            costGrowth = 1.15,
            effects = {
                dataBitsGeneration = 1.0 -- 1 DB/sec per unit
            },
            unlockRequirements = {
                upgrades = {"refurbishedDesktop"},
                count = {refurbishedDesktop = 5}
            }
        },
        
        smallDataCenter = {
            id = "smallDataCenter",
            name = "🏢 Small Data Center",
            description = "Dedicated facility for serious operations",
            category = "servers",
            tier = 2,
            maxCount = 10,
            baseCost = {dataBits = 1000},
            costGrowth = 1.15,
            effects = {
                dataBitsGeneration = 10.0 -- 10 DB/sec per unit
            },
            unlockRequirements = {
                upgrades = {"basicServerRack"},
                count = {basicServerRack = 10},
                zones = {"basement"}
            }
        },
        
        -- Processing Power Infrastructure
        singleCoreProcessor = {
            id = "singleCoreProcessor",
            name = "⚡ Single-Core Processor",
            description = "Basic computational power",
            category = "processing",
            tier = 1,
            maxCount = 20,
            baseCost = {dataBits = 50},
            costGrowth = 1.2,
            effects = {
                processingPowerGeneration = 0.1,
                dataBitsMultiplier = 0.1 -- +10% DB generation per unit
            },
            unlockRequirements = {
                upgrades = {"basicServerRack"}
            }
        },
        
        multiCoreArray = {
            id = "multiCoreArray",
            name = "🔄 Multi-Core Array",
            description = "Parallel processing capabilities",
            category = "processing",
            tier = 2,
            maxCount = 15,
            baseCost = {dataBits = 500},
            costGrowth = 1.2,
            effects = {
                processingPowerGeneration = 1.0,
                dataBitsMultiplier = 0.2 -- +20% DB generation per unit
            },
            unlockRequirements = {
                upgrades = {"singleCoreProcessor"},
                count = {singleCoreProcessor = 5}
            }
        },
        
        -- Security Infrastructure  
        basicPacketFilter = {
            id = "basicPacketFilter",
            name = "🛡️ Basic Packet Filter",
            description = "Filters out common attack patterns",
            category = "security",
            tier = 1,
            maxCount = 10,
            baseCost = {dataBits = 200},
            costGrowth = 1.25,
            effects = {
                securityRating = 15,
                threatReduction = 0.15 -- 15% threat reduction per unit
            },
            unlockRequirements = {
                zones = {"apartment"}
            }
        },
        
        advancedFirewall = {
            id = "advancedFirewall",
            name = "🔥 Advanced Firewall",
            description = "Sophisticated intrusion prevention",
            category = "security",
            tier = 2,
            maxCount = 5,
            baseCost = {dataBits = 1000},
            costGrowth = 1.25,
            effects = {
                securityRating = 50,
                threatReduction = 0.25 -- 25% threat reduction per unit
            },
            unlockRequirements = {
                upgrades = {"basicPacketFilter"},
                count = {basicPacketFilter = 3}
            }
        },
        
        -- Specialized Security Defenses (for idle system)
        emailFilter = {
            id = "emailFilter",
            name = "📧 Email Security Filter",
            description = "Advanced phishing protection",
            category = "security",
            tier = 2,
            maxCount = 3,
            baseCost = {dataBits = 800},
            costGrowth = 1.3,
            effects = {
                securityRating = 40,
                threatReduction = 0.1
            },
            unlockRequirements = {
                upgrades = {"basicPacketFilter"}
            }
        },
        
        antivirus = {
            id = "antivirus",
            name = "🦠 Enterprise Antivirus",
            description = "Real-time malware protection",
            category = "security", 
            tier = 2,
            maxCount = 3,
            baseCost = {dataBits = 1200},
            costGrowth = 1.3,
            effects = {
                securityRating = 60,
                threatReduction = 0.15
            },
            unlockRequirements = {
                upgrades = {"basicPacketFilter"}
            }
        },
        
        accessControl = {
            id = "accessControl",
            name = "🔐 Access Control System",
            description = "Multi-factor authentication and access management",
            category = "security",
            tier = 3,
            maxCount = 2,
            baseCost = {dataBits = 2000},
            costGrowth = 1.4,
            effects = {
                securityRating = 100,
                threatReduction = 0.2
            },
            unlockRequirements = {
                upgrades = {"advancedFirewall"}
            }
        },
        
        trafficShaping = {
            id = "trafficShaping",
            name = "🌐 Traffic Analysis System",
            description = "DDoS protection and traffic management",
            category = "security",
            tier = 3,
            maxCount = 2,
            baseCost = {dataBits = 2500},
            costGrowth = 1.4,
            effects = {
                securityRating = 120,
                threatReduction = 0.25
            },
            unlockRequirements = {
                upgrades = {"advancedFirewall"}
            }
        },
        
        threatIntelligence = {
            id = "threatIntelligence",
            name = "🕵️ Threat Intelligence Platform",
            description = "Advanced persistent threat detection",
            category = "security",
            tier = 4,
            maxCount = 1,
            baseCost = {dataBits = 5000},
            costGrowth = 1.5,
            effects = {
                securityRating = 200,
                threatReduction = 0.3
            },
            unlockRequirements = {
                upgrades = {"accessControl", "trafficShaping"},
                resources = {xp = 1000}
            }
        },
        
        behavioralAnalysis = {
            id = "behavioralAnalysis",
            name = "🧠 Behavioral Analysis Engine",
            description = "AI-powered zero-day detection",
            category = "security",
            tier = 5,
            maxCount = 1,
            baseCost = {dataBits = 10000, money = 50000},
            costGrowth = 1.6,
            effects = {
                securityRating = 300,
                threatReduction = 0.35
            },
            unlockRequirements = {
                upgrades = {"threatIntelligence"},
                resources = {xp = 2000, reputation = 100}
            }
        }
        
        -- More upgrades would be added for later phases...
    }
    
    -- Initialize some basic upgrades as unlocked
    self:initializeUnlockedUpgrades()
    
    return self
end

-- Initialize basic upgrades as unlocked
function UpgradeSystem:initializeUnlockedUpgrades()
    -- Unlock basic starting upgrades
    self.upgrades.ergonomicMouse.unlocked = true
    self.upgrades.refurbishedDesktop.unlocked = true
end

-- Subscribe to relevant events
function UpgradeSystem:subscribeToEvents()
    -- Nothing specific for now, but ready for expansion
end

-- Update upgrade system
function UpgradeSystem:update(dt)
    -- Check for newly unlocked upgrades
    self:checkUpgradeUnlocks()
end

-- Check which upgrades can be unlocked
function UpgradeSystem:checkUpgradeUnlocks()
    for upgradeId, upgrade in pairs(self.upgrades) do
        if not self:isUpgradeUnlocked(upgradeId) and self:canUnlockUpgrade(upgradeId) then
            self:unlockUpgrade(upgradeId)
        end
    end
end

-- Check if an upgrade can be unlocked based on requirements
function UpgradeSystem:canUnlockUpgrade(upgradeId)
    local upgrade = self.upgrades[upgradeId]
    if not upgrade then
        return false
    end
    
    local requirements = upgrade.unlockRequirements
    
    -- Check required upgrades
    if requirements.upgrades then
        for _, requiredUpgrade in ipairs(requirements.upgrades) do
            if not self:isUpgradeOwned(requiredUpgrade) then
                return false
            end
        end
    end
    
    -- Check required upgrade counts
    if requirements.count then
        for requiredUpgrade, requiredCount in pairs(requirements.count) do
            if self:getUpgradeCount(requiredUpgrade) < requiredCount then
                return false
            end
        end
    end
    
    -- Check resource requirements
    if requirements.resources then
        for resource, requiredAmount in pairs(requirements.resources) do
            local currentAmount = self.eventBus and self:getResourceAmount(resource) or 0
            if currentAmount < requiredAmount then
                return false
            end
        end
    end
    
    -- Other requirements would be checked via event bus
    -- (zones, achievements, etc.)
    
    return true
end

-- Helper function to get current resource amounts
function UpgradeSystem:getResourceAmount(resourceName)
    -- This would need to be connected to the resource system
    -- For now, return 0 as placeholder
    if self.eventBus then
        local amount = 0
        self.eventBus:publish("get_resource_amount", {
            resource = resourceName,
            callback = function(value) amount = value end
        })
        return amount
    end
    return 0
end

-- Unlock an upgrade
function UpgradeSystem:unlockUpgrade(upgradeId)
    local upgrade = self.upgrades[upgradeId]
    if not upgrade then
        return false
    end
    
    upgrade.unlocked = true
    
    -- Publish unlock event
    self.eventBus:publish("upgrade_unlocked", {
        upgradeId = upgradeId,
        upgrade = upgrade
    })
    
    print("✨ Upgrade unlocked: " .. upgrade.name)
    return true
end

-- Check if upgrade is unlocked
function UpgradeSystem:isUpgradeUnlocked(upgradeId)
    local upgrade = self.upgrades[upgradeId]
    return upgrade and upgrade.unlocked
end

-- Purchase an upgrade
function UpgradeSystem:purchaseUpgrade(upgradeId)
    local upgrade = self.upgrades[upgradeId]
    if not upgrade or not upgrade.unlocked then
        return false
    end
    
    -- Check if at max count
    local currentCount = self:getUpgradeCount(upgradeId)
    if currentCount >= upgrade.maxCount then
        return false
    end
    
    -- Calculate current cost
    local cost = self:getUpgradeCost(upgradeId)
    
    -- Check if player can afford it (synchronous for now)
    local canAfford = false
    self.eventBus:publish("check_can_afford", {
        cost = cost,
        callback = function(result)
            canAfford = result
        end
    })
    
    if not canAfford then
        return false
    end
    
    -- Spend resources
    self.eventBus:publish("spend_resources", {cost = cost})
    
    -- Add upgrade to owned
    if not self.owned[upgradeId] then
        self.owned[upgradeId] = 0
    end
    self.owned[upgradeId] = self.owned[upgradeId] + 1
    
    -- Apply upgrade effects
    self:applyUpgradeEffects(upgradeId, upgrade.effects)
    
    -- Check for newly unlocked upgrades
    self:checkUpgradeUnlocks()
    
    -- Publish purchase event
    self.eventBus:publish("upgrade_purchased", {
        upgradeId = upgradeId,
        upgrade = upgrade,
        count = self.owned[upgradeId],
        cost = cost
    })
    
    print("🛒 Purchased: " .. upgrade.name .. " (x" .. self.owned[upgradeId] .. ")")
    return true
end

-- Calculate current cost of an upgrade
function UpgradeSystem:getUpgradeCost(upgradeId)
    local upgrade = self.upgrades[upgradeId]
    if not upgrade then
        return {}
    end
    
    local count = self:getUpgradeCount(upgradeId)
    local cost = {}
    
    for resource, baseCost in pairs(upgrade.baseCost) do
        cost[resource] = math.floor(baseCost * math.pow(upgrade.costGrowth, count))
    end
    
    return cost
end

-- Apply effects of an upgrade
function UpgradeSystem:applyUpgradeEffects(upgradeId, effects)
    for effectType, value in pairs(effects) do
        self.eventBus:publish("apply_upgrade_effect", {
            upgradeId = upgradeId,
            effectType = effectType,
            value = value
        })
    end
end

-- Get number of owned upgrades
function UpgradeSystem:getUpgradeCount(upgradeId)
    return self.owned[upgradeId] or 0
end

-- Check if player owns an upgrade
function UpgradeSystem:isUpgradeOwned(upgradeId)
    return self:getUpgradeCount(upgradeId) > 0
end

-- Get upgrade by ID
function UpgradeSystem:getUpgrade(upgradeId)
    return self.upgrades[upgradeId]
end

-- Get all upgrades
function UpgradeSystem:getAllUpgrades()
    return self.upgrades
end

-- Get upgrades by category
function UpgradeSystem:getUpgradesByCategory(category)
    local categoryUpgrades = {}
    for upgradeId, upgrade in pairs(self.upgrades) do
        if upgrade.category == category then
            categoryUpgrades[upgradeId] = upgrade
        end
    end
    return categoryUpgrades
end

-- Get unlocked upgrades
function UpgradeSystem:getUnlockedUpgrades()
    local unlocked = {}
    for upgradeId, upgrade in pairs(self.upgrades) do
        if upgrade.unlocked then
            unlocked[upgradeId] = upgrade
        end
    end
    return unlocked
end

-- Get owned upgrades
function UpgradeSystem:getOwnedUpgrades()
    return self.owned
end

-- Get state for saving
function UpgradeSystem:getState()
    return {
        owned = self.owned,
        unlocked = {}  -- Track which upgrades are unlocked
    }
end

-- Load state from save
function UpgradeSystem:loadState(state)
    if state.owned then
        self.owned = state.owned
    end
    
    if state.unlocked then
        for upgradeId, unlocked in pairs(state.unlocked) do
            if self.upgrades[upgradeId] then
                self.upgrades[upgradeId].unlocked = unlocked
            end
        end
    end
    
    -- Re-apply all upgrade effects
    for upgradeId, count in pairs(self.owned) do
        local upgrade = self.upgrades[upgradeId]
        if upgrade then
            for i = 1, count do
                self:applyUpgradeEffects(upgradeId, upgrade.effects)
            end
        end
    end
end

return UpgradeSystem