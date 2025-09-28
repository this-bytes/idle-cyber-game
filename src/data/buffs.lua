-- Buff Definitions - Cyber Empire Command
-- Central data file for all buff types and their configurations

local BuffData = {}

-- Buff category constants
BuffData.BUFF_TYPES = {
    TEMPORARY = "temporary",
    PERMANENT = "permanent", 
    STACKABLE = "stackable",
    UNIQUE = "unique"
}

BuffData.EFFECT_CATEGORIES = {
    RESOURCE = "resource",
    COMBAT = "combat",
    SPECIAL = "special",
    PRODUCTIVITY = "productivity"
}

-- Core buff definitions
BuffData.buffs = {
    -- === PRODUCTIVITY BUFFS ===
    ["contract_efficiency_boost"] = {
        name = "📈 Contract Efficiency Boost",
        description = "Increased efficiency from successful contract completion",
        type = "temporary",
        category = "productivity",
        duration = 300, -- 5 minutes
        maxStacks = 5,
        effects = {
            resourceMultiplier = {money = 1.2},
            efficiency = 0.15
        },
        icon = "📈",
        stackable = true,
        triggerEvents = {"contract_completed"},
        rarity = "common"
    },
    
    ["focus_enhancement"] = {
        name = "🧠 Enhanced Focus",
        description = "Improved concentration and productivity from training",
        type = "stackable",
        category = "productivity", 
        duration = 240, -- 4 minutes
        maxStacks = 10,
        effects = {
            efficiency = 0.1,
            speed = 0.05,
            xpMultiplier = 1.1
        },
        icon = "🧠",
        stackable = true,
        triggerEvents = {"skill_training", "player_interact"},
        rarity = "common"
    },
    
    ["research_acceleration"] = {
        name = "⚡ Research Boost",
        description = "Accelerated skill and upgrade progression from breakthrough",
        type = "unique",
        category = "special",
        duration = 180, -- 3 minutes
        maxStacks = 1,
        effects = {
            xpMultiplier = 2.0,
            upgradeSpeedBonus = 0.5,
            researchEfficiency = 0.8
        },
        icon = "⚡",
        stackable = false,
        triggerEvents = {"major_contract_completed", "crisis_resolved"},
        rarity = "rare"
    },
    
    -- === DEFENSIVE BUFFS ===
    ["threat_resistance"] = {
        name = "🛡️ Enhanced Security",
        description = "Improved defenses against cyber threats from recent crisis experience",
        type = "temporary",
        category = "combat",
        duration = 600, -- 10 minutes
        maxStacks = 3,
        effects = {
            threatReduction = 0.25,
            defense = 10,
            crisisSuccessRate = 0.15
        },
        icon = "🛡️",
        stackable = true,
        triggerEvents = {"crisis_resolved", "threat_detected"},
        rarity = "uncommon"
    },
    
    ["firewall_fortification"] = {
        name = "🔥 Firewall Fortified",
        description = "Temporary boost to network defenses after successful threat mitigation",
        type = "temporary",
        category = "combat",
        duration = 450, -- 7.5 minutes
        maxStacks = 2,
        effects = {
            threatReduction = 0.35,
            networkSecurity = 15,
            automaticThreatDetection = 0.2
        },
        icon = "🔥",
        stackable = true,
        triggerEvents = {"threat_blocked", "intrusion_prevented"},
        rarity = "uncommon"
    },
    
    -- === RESOURCE BUFFS ===
    ["client_satisfaction"] = {
        name = "😊 Client Satisfaction",
        description = "Increased reputation and income from excellent service delivery",
        type = "temporary",
        category = "resource",
        duration = 900, -- 15 minutes
        maxStacks = 3,
        effects = {
            resourceMultiplier = {money = 1.3, reputation = 1.5},
            contractValueBonus = 0.2
        },
        icon = "😊",
        stackable = true,
        triggerEvents = {"contract_completed_excellently", "client_feedback_positive"},
        rarity = "uncommon"
    },
    
    ["market_recognition"] = {
        name = "🏆 Market Recognition",
        description = "Industry recognition boosting company reputation and contract availability",
        type = "temporary",
        category = "resource",
        duration = 1800, -- 30 minutes
        maxStacks = 1,
        effects = {
            resourceGeneration = {reputation = 3, money = 8},
            contractGenerationRate = 0.4,
            prestigePointsMultiplier = 1.5
        },
        icon = "🏆",
        stackable = false,
        triggerEvents = {"achievement_unlocked", "milestone_reached"},
        rarity = "rare"
    },
    
    -- === PERMANENT BUFFS ===
    ["advanced_infrastructure"] = {
        name = "🏢 Advanced Infrastructure",
        description = "Permanent benefits from upgraded facilities and equipment",
        type = "permanent",
        category = "resource",
        effects = {
            resourceGeneration = {money = 5, reputation = 1},
            storageCapacity = 1.5,
            facilityEfficiency = 0.25
        },
        icon = "🏢",
        triggerEvents = {"facility_upgraded", "infrastructure_investment"},
        rarity = "epic"
    },
    
    ["elite_training"] = {
        name = "🎖️ Elite Training Program",
        description = "Advanced specialist training providing permanent productivity gains",
        type = "permanent", 
        category = "productivity",
        effects = {
            efficiency = 0.3,
            specialistCapacity = 2,
            teamEfficiencyBonus = 0.15
        },
        icon = "🎖️",
        triggerEvents = {"training_program_completed", "specialist_mastery"},
        rarity = "epic"
    },
    
    ["threat_intelligence_network"] = {
        name = "🕸️ Threat Intelligence Network",
        description = "Permanent access to advanced threat intelligence and early warning systems",
        type = "permanent",
        category = "combat",
        effects = {
            threatReduction = 0.2,
            automaticThreatDetection = 0.3,
            threatIntelligence = 1.0,
            earlyWarningSystem = true
        },
        icon = "🕸️",
        triggerEvents = {"intelligence_network_established", "government_partnership"},
        rarity = "legendary"
    },
    
    -- === SPECIAL EVENT BUFFS ===
    ["crisis_veteran"] = {
        name = "⚔️ Crisis Veteran",
        description = "Battle-tested experience from surviving multiple major incidents",
        type = "stackable",
        category = "special",
        duration = 3600, -- 1 hour
        maxStacks = 20,
        effects = {
            crisisSuccessRate = 0.1,
            stressResistance = 0.05,
            leadershipBonus = 0.03
        },
        icon = "⚔️",
        stackable = true,
        triggerEvents = {"major_crisis_resolved", "disaster_survived"},
        rarity = "rare"
    },
    
    ["innovation_streak"] = {
        name = "💡 Innovation Streak",
        description = "Creative momentum from consecutive breakthroughs and discoveries",
        type = "stackable",
        category = "special",
        duration = 600, -- 10 minutes
        maxStacks = 8,
        effects = {
            researchEfficiency = 0.2,
            innovationChance = 0.1,
            breakthroughMultiplier = 1.15
        },
        icon = "💡",
        stackable = true,
        triggerEvents = {"research_breakthrough", "innovation_discovered"},
        rarity = "rare"
    },
    
    ["adrenaline_rush"] = {
        name = "⚡ Adrenaline Rush", 
        description = "Heightened performance during high-stakes crisis situations",
        type = "temporary",
        category = "special",
        duration = 120, -- 2 minutes
        maxStacks = 1,
        effects = {
            speed = 0.5,
            efficiency = 0.4,
            crisisResponseTime = 0.6,
            staminaBonus = 25
        },
        icon = "⚡",
        stackable = false,
        triggerEvents = {"crisis_detected", "emergency_response"},
        rarity = "uncommon"
    }
}

-- Buff rarity system for visual distinction and acquisition rates
BuffData.rarities = {
    common = {
        color = {0.8, 0.8, 0.8}, -- Light gray
        acquisitionRate = 0.8,
        description = "Frequently obtained through normal gameplay"
    },
    uncommon = {
        color = {0.2, 0.8, 0.2}, -- Green
        acquisitionRate = 0.4,
        description = "Obtained through skilled play and good performance"
    },
    rare = {
        color = {0.2, 0.4, 1.0}, -- Blue
        acquisitionRate = 0.15,
        description = "Rare rewards for exceptional achievements"
    },
    epic = {
        color = {0.8, 0.2, 0.8}, -- Purple
        acquisitionRate = 0.05,
        description = "Epic upgrades from major milestones"
    },
    legendary = {
        color = {1.0, 0.6, 0.0}, -- Orange
        acquisitionRate = 0.01,
        description = "Legendary bonuses from extraordinary accomplishments"
    }
}

-- Get all buff definitions
function BuffData.getAllBuffs()
    return BuffData.buffs
end

-- Get buff definition by ID
function BuffData.getBuff(buffId)
    return BuffData.buffs[buffId]
end

-- Get buffs by category
function BuffData.getBuffsByCategory(category)
    local categoryBuffs = {}
    for buffId, buff in pairs(BuffData.buffs) do
        if buff.category == category then
            categoryBuffs[buffId] = buff
        end
    end
    return categoryBuffs
end

-- Get buffs by type
function BuffData.getBuffsByType(buffType)
    local typeBuffs = {}
    for buffId, buff in pairs(BuffData.buffs) do
        if buff.type == buffType then
            typeBuffs[buffId] = buff
        end
    end
    return typeBuffs
end

-- Get buffs by rarity
function BuffData.getBuffsByRarity(rarity)
    local rarityBuffs = {}
    for buffId, buff in pairs(BuffData.buffs) do
        if buff.rarity == rarity then
            rarityBuffs[buffId] = buff
        end
    end
    return rarityBuffs
end

-- Validate buff system integrity
function BuffData.validateBuffs()
    local errors = {}
    
    for buffId, buff in pairs(BuffData.buffs) do
        -- Check required fields
        if not buff.name then
            table.insert(errors, "Buff '" .. buffId .. "' missing name")
        end
        if not buff.description then
            table.insert(errors, "Buff '" .. buffId .. "' missing description")
        end
        if not buff.type then
            table.insert(errors, "Buff '" .. buffId .. "' missing type")
        end
        if not buff.category then
            table.insert(errors, "Buff '" .. buffId .. "' missing category")
        end
        if not buff.effects then
            table.insert(errors, "Buff '" .. buffId .. "' missing effects")
        end
        
        -- Validate stackable settings
        if buff.stackable and not buff.maxStacks then
            table.insert(errors, "Stackable buff '" .. buffId .. "' missing maxStacks")
        end
        
        -- Validate temporary buff duration
        if buff.type == "temporary" and not buff.duration then
            table.insert(errors, "Temporary buff '" .. buffId .. "' missing duration")
        end
        
        -- Validate rarity
        if buff.rarity and not BuffData.rarities[buff.rarity] then
            table.insert(errors, "Buff '" .. buffId .. "' has invalid rarity: " .. buff.rarity)
        end
    end
    
    return errors
end

return BuffData