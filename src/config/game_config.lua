-- Core Game Configuration - Cyber Empire Command
-- Data-driven configuration following technical architecture instructions

local GameConfig = {}

-- Game Identity and Version
GameConfig.GAME_TITLE = "Cyber Empire Command"
GameConfig.GAME_SUBTITLE = "Cybersecurity Consultancy Simulator"
GameConfig.VERSION = "0.1.0-bootstrap"

-- Core Resource Configuration
GameConfig.RESOURCES = {
    -- Primary Resources (as per core mechanics instructions)
    money = {
        name = "Money",
        symbol = "$",
        startingAmount = 1000,
        description = "Currency for hiring staff and buying equipment"
    },
    reputation = {
        name = "Reputation", 
        symbol = "★",
        startingAmount = 0,
        description = "Unlocks higher-tier contracts and factions"
    },
    xp = {
        name = "Experience",
        symbol = "XP", 
        startingAmount = 0,
        description = "Company growth and specialist leveling"
    },
    missionTokens = {
        name = "Mission Tokens",
        symbol = "◊",
        startingAmount = 0,
        description = "Rare resource from Crisis Mode for elite upgrades"
    }
}

-- Client Tier Configuration (as per contract system)
GameConfig.CLIENT_TIERS = {
    startup = {
        name = "Tech Startup",
        budgetRange = {500, 2000},
        durationRange = {60, 180}, -- seconds 
        reputationReward = {1, 5},
        riskLevel = "low",
        threatTypes = {"script_kiddies", "basic_malware"},
        description = "Small tech company needing basic security",
        unlockRequirement = nil
    },
    smallBusiness = {
        name = "Small Business", 
        budgetRange = {1500, 5000},
        durationRange = {120, 300},
        reputationReward = {3, 10},
        riskLevel = "medium", 
        threatTypes = {"phishing", "ransomware"},
        description = "Growing business with moderate security needs",
        unlockRequirement = {reputation = 10}
    },
    enterprise = {
        name = "Enterprise Corp",
        budgetRange = {10000, 50000},
        durationRange = {300, 600},
        reputationReward = {15, 50},
        riskLevel = "high",
        threatTypes = {"apt", "supply_chain", "zero_day"},
        description = "Large corporation requiring comprehensive security", 
        unlockRequirement = {reputation = 50}
    },
    government = {
        name = "Government Agency",
        budgetRange = {25000, 100000},
        durationRange = {600, 1200},
        reputationReward = {30, 100},
        riskLevel = "critical",
        threatTypes = {"nation_state", "advanced_persistent", "zero_day"},
        description = "High-security government contract",
        unlockRequirement = {reputation = 200, missionTokens = 5}
    }
}

-- Specialist Roles Configuration
GameConfig.SPECIALIST_ROLES = {
    analyst = {
        name = "Security Analyst",
        baseStats = {efficiency = 70, speed = 60, trace = 80, defense = 50},
        abilities = {"threat_analysis", "log_review"},
        hireCost = 5000,
        description = "Specializes in threat detection and analysis"
    },
    engineer = {
        name = "Security Engineer", 
        baseStats = {efficiency = 80, speed = 70, trace = 60, defense = 90},
        abilities = {"system_hardening", "patch_deployment"},
        hireCost = 7500,
        description = "Builds and maintains security infrastructure"
    },
    responder = {
        name = "Incident Responder",
        baseStats = {efficiency = 90, speed = 95, trace = 85, defense = 70},
        abilities = {"crisis_management", "forensics"},
        hireCost = 10000,
        description = "Elite crisis response specialist"
    }
}

-- Crisis Mode Configuration
GameConfig.CRISIS_SCENARIOS = {
    phishing_campaign = {
        id = "phishing_campaign_001",
        title = "PHISHING CAMPAIGN DETECTED",
        description = "Targeted phishing emails detected across client network",
        severity = "HIGH",
        timeLimit = 300, -- 5 minutes
        rewardTokens = 1,
        stages = {
            {
                name = "Initial Detection",
                description = "Unusual email traffic patterns detected",
                options = {
                    {key = "1", action = "Deploy Email Scanner", cost = "processing_time"},
                    {key = "2", action = "Manual Investigation", cost = "specialist_time"},
                    {key = "3", action = "Automated Response", cost = "reputation_risk"}
                }
            },
            {
                name = "Containment",
                description = "Block malicious emails and quarantine affected systems", 
                options = {
                    {key = "1", action = "Full Network Isolation", cost = "client_downtime"},
                    {key = "2", action = "Selective Quarantine", cost = "precision_required"}, 
                    {key = "3", action = "Monitor and Log", cost = "ongoing_risk"}
                }
            }
        }
    }
}

-- UI Theme Configuration (cyberpunk terminal aesthetic)
GameConfig.UI_THEME = {
    colors = {
        primary = {0, 1, 0},        -- Bright green (terminal)
        secondary = {0, 0.8, 0},    -- Dimmer green
        accent = {1, 1, 0},         -- Yellow (warnings)
        danger = {1, 0, 0},         -- Red (alerts)
        background = {0, 0, 0},     -- Black
        text = {0.9, 0.9, 0.9}      -- Light gray
    },
    fonts = {
        monospace = true,
        pixelated = true
    }
}

-- Game Balance Configuration
GameConfig.BALANCE = {
    contractGenerationInterval = 30, -- seconds
    autoSaveInterval = 60,           -- seconds
    crisisFrequency = 0.1,          -- 10% chance per contract completion
    reputationDecayRate = 0,         -- no decay in base game
    maxActiveContracts = 5,          -- can be upgraded
    maxSpecialists = 10              -- can be upgraded
}

return GameConfig
