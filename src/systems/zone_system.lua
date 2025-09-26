-- Zone Management System
-- Handles zone progression, unlocking, and zone-specific bonuses

local ZoneSystem = {}
ZoneSystem.__index = ZoneSystem

-- Create new zone system
function ZoneSystem.new(eventBus)
    local self = setmetatable({}, ZoneSystem)
    self.eventBus = eventBus
    
    -- Zone definitions from instruction files
    self.zones = {
        -- Tier 1: Personal Network
        garage = {
            id = "garage",
            name = "🏠 Home Office",
            description = "Starting your cybersecurity consultancy from home",
            unlocked = true,
            tier = 1,
            
            -- Business capabilities
            maxContracts = 2,
            contractTypes = {"startup"},
            reputationBonus = 1.0,
            
            -- Unlock requirements
            unlockRequirements = {},
            
            -- Business context
            riskLevel = "Low",
            atmosphere = "Cozy but limited workspace with basic equipment"
        },
        
        coworking = {
            id = "coworking",
            name = "🏢 Co-working Space",
            description = "Professional shared workspace environment",
            unlocked = false,
            tier = 2,
            
            maxContracts = 4,
            contractTypes = {"startup", "smallBusiness"},
            reputationBonus = 1.2,
            
            unlockRequirements = {
                money = 5000,
                reputation = 25
            },
            
            riskLevel = "Low-Medium",
            atmosphere = "Professional environment with better networking"
        },
        
        smallOffice = {
            id = "smallOffice",
            name = "🏢 Small Office",
            description = "Your own dedicated office space",
            unlocked = false,
            tier = 3,
            
            maxContracts = 6,
            contractTypes = {"startup", "smallBusiness", "enterprise"},
            reputationBonus = 1.5,
            
            unlockRequirements = {
                money = 25000,
                reputation = 75
            },
            
            riskLevel = "Medium",
            atmosphere = "Professional office with proper security setup"
        },
        
        -- Tier 2: Small Operations
        smallOffice = {
            id = "smallOffice",
            name = "🏢 Small Office",
            description = "Your first real business location",
            unlocked = false,
            tier = 2,
            difficulty = 2.0,
            
            bonuses = {
                dataBitsMultiplier = 1.5,
                processingPowerMultiplier = 1.3,
                securityRatingMultiplier = 1.2,
                reputationPointsMultiplier = 1.1
            },
            
            unlockRequirements = {
                dataBits = 50000,
                reputationPoints = 10,
                zones = {"apartment"}
            },
            
            threatLevel = "Medium",
            atmosphere = "Professional environment attracting attention"
        },
        
        warehouse = {
            id = "warehouse",
            name = "🏭 Warehouse Datacenter",
            description = "Industrial-scale server operations",
            unlocked = false,
            tier = 2,
            difficulty = 2.5,
            
            bonuses = {
                dataBitsMultiplier = 2.0,
                processingPowerMultiplier = 1.8,
                securityRatingMultiplier = 1.0,
                reputationPointsMultiplier = 1.2
            },
            
            unlockRequirements = {
                dataBits = 250000,
                processingPower = 100,
                zones = {"smallOffice"}
            },
            
            threatLevel = "Medium-High",
            atmosphere = "Noisy cooling systems and rows of server racks"
        },
        
        -- Tier 3: Corporate Operations
        corporateHQ = {
            id = "corporateHQ",
            name = "🏬 Corporate Headquarters",
            description = "Legitimate business operations",
            unlocked = false,
            tier = 3,
            difficulty = 3.0,
            
            bonuses = {
                dataBitsMultiplier = 2.5,
                processingPowerMultiplier = 2.0,
                securityRatingMultiplier = 1.5,
                reputationPointsMultiplier = 1.5,
                researchDataMultiplier = 1.2
            },
            
            unlockRequirements = {
                dataBits = 1000000,
                reputationPoints = 50,
                factionReputation = {corporate = 25}
            },
            
            threatLevel = "High",
            atmosphere = "Glass towers and corporate espionage"
        },
        
        -- Tier 4: Underground Operations
        underground = {
            id = "underground",
            name = "🕳️ Underground Bunker",
            description = "Hidden operations below the city",
            unlocked = false,
            tier = 4,
            difficulty = 4.0,
            
            bonuses = {
                dataBitsMultiplier = 3.0,
                processingPowerMultiplier = 2.5,
                securityRatingMultiplier = 2.0,
                reputationPointsMultiplier = 2.0,
                researchDataMultiplier = 1.5
            },
            
            unlockRequirements = {
                dataBits = 5000000,
                reputationPoints = 100,
                factionReputation = {underground = 50}
            },
            
            threatLevel = "Extreme",
            atmosphere = "Concrete tunnels and hidden data centers"
        },
        
        -- Tier 5: Digital Dimensions
        cyberspace = {
            id = "cyberspace",
            name = "🌐 Pure Cyberspace",
            description = "Operating within the digital realm itself",
            unlocked = false,
            tier = 5,
            difficulty = 5.0,
            
            bonuses = {
                dataBitsMultiplier = 5.0,
                processingPowerMultiplier = 4.0,
                securityRatingMultiplier = 3.0,
                reputationPointsMultiplier = 3.0,
                researchDataMultiplier = 2.0,
                neuralNetworkFragmentsMultiplier = 1.5
            },
            
            unlockRequirements = {
                dataBits = 50000000,
                neuralNetworkFragments = 10,
                achievements = {"digital_ascension"}
            },
            
            threatLevel = "Legendary",
            atmosphere = "Data streams and algorithmic entities"
        }
    }
    
    -- Current zone
    self.currentZone = "garage"
    self.unlockedZones = {"garage"}
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to relevant events
function ZoneSystem:subscribeToEvents()
    -- Handle zone unlock checks
    self.eventBus:subscribe("check_zones_unlocked", function(data)
        local allUnlocked = true
        for _, zoneId in ipairs(data.zones) do
            if not self:isZoneUnlocked(zoneId) then
                allUnlocked = false
                break
            end
        end
        if data.callback then
            data.callback(allUnlocked)
        end
    end)
end

-- Update zone system
function ZoneSystem:update(dt)
    -- Check for zone unlock conditions
    self:checkZoneUnlocks()
end

-- Check if any zones can be unlocked
function ZoneSystem:checkZoneUnlocks()
    for zoneId, zone in pairs(self.zones) do
        if not zone.unlocked and self:canUnlockZone(zoneId) then
            self:unlockZone(zoneId)
        end
    end
end

-- Check if a zone can be unlocked
function ZoneSystem:canUnlockZone(zoneId)
    local zone = self.zones[zoneId]
    if not zone or zone.unlocked then
        return false
    end
    
    -- Check requirements through event bus
    local requirementsMet = true
    
    -- This would be expanded to check actual resources/achievements/etc
    -- For now, just return false for locked zones
    return false
end

-- Unlock a zone
function ZoneSystem:unlockZone(zoneId)
    local zone = self.zones[zoneId]
    if not zone or zone.unlocked then
        return false
    end
    
    zone.unlocked = true
    table.insert(self.unlockedZones, zoneId)
    
    -- Publish zone unlock event
    self.eventBus:publish("zone_unlocked", {
        zoneId = zoneId,
        zoneName = zone.name,
        zone = zone
    })
    
    print("🌟 Zone unlocked: " .. zone.name)
    return true
end

-- Set current zone
function ZoneSystem:setCurrentZone(zoneId)
    local zone = self.zones[zoneId]
    if not zone or not zone.unlocked then
        return false
    end
    
    local oldZone = self.currentZone
    self.currentZone = zoneId
    
    -- Apply zone bonuses through event bus
    self.eventBus:publish("zone_changed", {
        oldZone = oldZone,
        newZone = zoneId,
        bonuses = zone.bonuses,
        zone = zone
    })
    
    print("📍 Moved to zone: " .. zone.name)
    return true
end

-- Get current zone
function ZoneSystem:getCurrentZone()
    return self.zones[self.currentZone]
end

-- Get current zone ID
function ZoneSystem:getCurrentZoneId()
    return self.currentZone
end

-- Get zone by ID
function ZoneSystem:getZone(zoneId)
    return self.zones[zoneId]
end

-- Get all zones
function ZoneSystem:getAllZones()
    return self.zones
end

-- Get unlocked zones
function ZoneSystem:getUnlockedZones()
    local unlocked = {}
    for _, zoneId in ipairs(self.unlockedZones) do
        unlocked[zoneId] = self.zones[zoneId]
    end
    return unlocked
end

-- Check if zone is unlocked
function ZoneSystem:isZoneUnlocked(zoneId)
    local zone = self.zones[zoneId]
    return zone and zone.unlocked
end

-- Get zone bonuses for current zone
function ZoneSystem:getCurrentZoneBonuses()
    local currentZone = self:getCurrentZone()
    return currentZone and currentZone.bonuses or {}
end

-- Get zone difficulty multiplier
function ZoneSystem:getCurrentDifficulty()
    local currentZone = self:getCurrentZone()
    return currentZone and currentZone.difficulty or 1.0
end

-- Get zone threat level
function ZoneSystem:getCurrentThreatLevel()
    local currentZone = self:getCurrentZone()
    return currentZone and currentZone.threatLevel or "Unknown"
end

-- Get zones by tier
function ZoneSystem:getZonesByTier(tier)
    local zonesByTier = {}
    for zoneId, zone in pairs(self.zones) do
        if zone.tier == tier then
            zonesByTier[zoneId] = zone
        end
    end
    return zonesByTier
end

-- Get state for saving
function ZoneSystem:getState()
    return {
        currentZone = self.currentZone,
        unlockedZones = self.unlockedZones,
        zones = self.zones
    }
end

-- Load state from save
function ZoneSystem:loadState(state)
    if state.currentZone then
        self.currentZone = state.currentZone
    end
    
    if state.unlockedZones then
        self.unlockedZones = state.unlockedZones
    end
    
    if state.zones then
        -- Update zone unlock status
        for zoneId, zoneData in pairs(state.zones) do
            if self.zones[zoneId] then
                self.zones[zoneId].unlocked = zoneData.unlocked
            end
        end
    end
end

return ZoneSystem