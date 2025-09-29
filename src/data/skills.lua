-- Skill Definitions - Idle Sec Ops
-- Central data file for all skill trees and progression

local SkillData = {}

-- Skill definitions - fully expandable system
SkillData.skills = {
    -- === ANALYSIS SKILL TREE ===
    ["basic_analysis"] = {
        id = "basic_analysis",
        name = "Basic Analysis",
        description = "Fundamental security analysis techniques",
        category = "analysis",
        maxLevel = 10,
        baseXpCost = 100,
        xpGrowth = 1.2,
        prerequisites = {},
        effects = {
            efficiency = 0.05, -- +5% efficiency per level
            trace = 0.02       -- +2% trace ability per level
        },
        unlockRequirements = {} -- Always available
    },
    
    ["advanced_scanning"] = {
        id = "advanced_scanning",
        name = "Advanced Scanning",
        description = "Sophisticated network and system scanning",
        category = "analysis",
        maxLevel = 8,
        baseXpCost = 200,
        xpGrowth = 1.3,
        prerequisites = {"basic_analysis"},
        effects = {
            efficiency = 0.08,
            speed = 0.03,
            trace = 0.05
        },
        unlockRequirements = {
            skills = {basic_analysis = 3} -- Requires Basic Analysis level 3
        }
    },
    
    ["threat_hunting"] = {
        id = "threat_hunting",
        name = "Threat Hunting",
        description = "Proactive threat detection and analysis",
        category = "analysis",
        maxLevel = 12,
        baseXpCost = 500,
        xpGrowth = 1.4,
        prerequisites = {"advanced_scanning"},
        effects = {
            efficiency = 0.12,
            trace = 0.1,
            defense = 0.03
        },
        unlockRequirements = {
            skills = {advanced_scanning = 5},
            reputation = 50
        }
    },
    
    ["behavioral_analysis"] = {
        id = "behavioral_analysis",
        name = "Behavioral Analysis",
        description = "Understanding attacker patterns and motivations",
        category = "analysis",
        maxLevel = 10,
        baseXpCost = 600,
        xpGrowth = 1.35,
        prerequisites = {"threat_hunting"},
        effects = {
            trace = 0.15,
            efficiency = 0.08,
            crisisSuccessRate = 0.05 -- +5% crisis resolution success per level
        },
        unlockRequirements = {
            skills = {threat_hunting = 6},
            missionTokens = 3
        }
    },
    
    -- === NETWORK SECURITY SKILL TREE ===
    ["network_fundamentals"] = {
        id = "network_fundamentals",
        name = "Network Fundamentals",
        description = "Basic network security principles",
        category = "network",
        maxLevel = 10,
        baseXpCost = 120,
        xpGrowth = 1.15,
        prerequisites = {},
        effects = {
            speed = 0.04,
            defense = 0.06
        },
        unlockRequirements = {}
    },
    
    ["firewall_management"] = {
        id = "firewall_management",
        name = "Firewall Management",
        description = "Advanced firewall configuration and monitoring",
        category = "network",
        maxLevel = 8,
        baseXpCost = 250,
        xpGrowth = 1.25,
        prerequisites = {"network_fundamentals"},
        effects = {
            defense = 0.1,
            efficiency = 0.03
        },
        unlockRequirements = {
            skills = {network_fundamentals = 4}
        }
    },
    
    ["intrusion_detection"] = {
        id = "intrusion_detection",
        name = "Intrusion Detection",
        description = "Automated threat detection and alerting",
        category = "network",
        maxLevel = 10,
        baseXpCost = 400,
        xpGrowth = 1.3,
        prerequisites = {"firewall_management"},
        effects = {
            trace = 0.08,
            defense = 0.12,
            automaticThreatDetection = 0.1 -- +10% chance per level
        },
        unlockRequirements = {
            skills = {firewall_management = 5},
            reputation = 25
        }
    },
    
    ["network_forensics"] = {
        id = "network_forensics",
        name = "Network Forensics",
        description = "Deep packet analysis and traffic investigation",
        category = "network",
        maxLevel = 8,
        baseXpCost = 700,
        xpGrowth = 1.4,
        prerequisites = {"intrusion_detection"},
        effects = {
            trace = 0.2,
            efficiency = 0.1,
            evidenceQuality = 0.15 -- Better crisis resolution evidence
        },
        unlockRequirements = {
            skills = {intrusion_detection = 6},
            missionTokens = 2
        }
    },
    
    -- === INCIDENT RESPONSE SKILL TREE ===
    ["basic_response"] = {
        id = "basic_response",
        name = "Basic Incident Response",
        description = "Fundamental incident response procedures",
        category = "incident",
        maxLevel = 10,
        baseXpCost = 150,
        xpGrowth = 1.2,
        prerequisites = {},
        effects = {
            speed = 0.06,
            trace = 0.04
        },
        unlockRequirements = {}
    },
    
    ["containment_procedures"] = {
        id = "containment_procedures",
        name = "Containment Procedures",
        description = "Rapid threat isolation and damage limitation",
        category = "incident",
        maxLevel = 8,
        baseXpCost = 300,
        xpGrowth = 1.25,
        prerequisites = {"basic_response"},
        effects = {
            speed = 0.1,
            defense = 0.08,
            containmentSpeed = 0.2 -- Faster crisis containment
        },
        unlockRequirements = {
            skills = {basic_response = 4}
        }
    },
    
    ["crisis_management"] = {
        id = "crisis_management",
        name = "Crisis Management",
        description = "Advanced crisis handling and coordination",
        category = "incident",
        maxLevel = 8,
        baseXpCost = 400,
        xpGrowth = 1.35,
        prerequisites = {"containment_procedures"},
        effects = {
            efficiency = 0.1,
            speed = 0.08,
            defense = 0.05,
            crisisLeadershipBonus = 0.1 -- Boosts team performance during crisis
        },
        unlockRequirements = {
            skills = {containment_procedures = 6},
            missionTokens = 2
        }
    },
    
    ["disaster_recovery"] = {
        id = "disaster_recovery",
        name = "Disaster Recovery",
        description = "System restoration and business continuity",
        category = "incident",
        maxLevel = 10,
        baseXpCost = 600,
        xpGrowth = 1.3,
        prerequisites = {"crisis_management"},
        effects = {
            efficiency = 0.15,
            speed = 0.12,
            recoveryBonus = 0.2, -- Faster post-incident recovery
            reputationProtection = 0.05 -- Reduces reputation loss during crises
        },
        unlockRequirements = {
            skills = {crisis_management = 5},
            reputation = 75
        }
    },
    
    -- === LEADERSHIP SKILL TREE (CEO EXCLUSIVE) ===
    ["team_coordination"] = {
        id = "team_coordination",
        name = "Team Coordination",
        description = "Effective team management and coordination",
        category = "leadership",
        maxLevel = 15,
        baseXpCost = 200,
        xpGrowth = 1.1,
        prerequisites = {},
        effects = {
            teamEfficiencyBonus = 0.02, -- +2% team-wide efficiency per level
            contractCapacity = 0.1      -- +10% contract capacity per level
        },
        unlockRequirements = {
            specialistType = "ceo" -- Only CEO can learn this
        }
    },
    
    ["strategic_planning"] = {
        id = "strategic_planning",
        name = "Strategic Planning",
        description = "Long-term strategic business planning",
        category = "leadership",
        maxLevel = 10,
        baseXpCost = 500,
        xpGrowth = 1.2,
        prerequisites = {"team_coordination"},
        effects = {
            reputationMultiplier = 0.05, -- +5% reputation gain per level
            contractValueBonus = 0.03    -- +3% contract value per level
        },
        unlockRequirements = {
            specialistType = "ceo",
            skills = {team_coordination = 8},
            reputation = 100
        }
    },
    
    ["business_development"] = {
        id = "business_development",
        name = "Business Development",
        description = "Client acquisition and relationship management",
        category = "leadership",
        maxLevel = 12,
        baseXpCost = 800,
        xpGrowth = 1.25,
        prerequisites = {"strategic_planning"},
        effects = {
            contractGenerationRate = 0.1, -- +10% more contracts generated
            clientSatisfactionBonus = 0.08, -- Better client relationships
            higherTierUnlockRate = 0.05 -- Faster unlock of premium contracts
        },
        unlockRequirements = {
            specialistType = "ceo",
            skills = {strategic_planning = 6},
            reputation = 200
        }
    },
    
    -- === TECHNICAL SKILL TREE ===
    ["system_administration"] = {
        id = "system_administration",
        name = "System Administration",
        description = "Server and infrastructure management",
        category = "technical",
        maxLevel = 10,
        baseXpCost = 180,
        xpGrowth = 1.2,
        prerequisites = {},
        effects = {
            efficiency = 0.04,
            speed = 0.05,
            systemReliability = 0.1 -- Reduces system downtime
        },
        unlockRequirements = {}
    },
    
    ["cloud_security"] = {
        id = "cloud_security",
        name = "Cloud Security",
        description = "Cloud infrastructure protection and monitoring",
        category = "technical",
        maxLevel = 8,
        baseXpCost = 400,
        xpGrowth = 1.3,
        prerequisites = {"system_administration"},
        effects = {
            efficiency = 0.08,
            defense = 0.1,
            scalabilityBonus = 0.15 -- Better handling of large contracts
        },
        unlockRequirements = {
            skills = {system_administration = 5},
            reputation = 30
        }
    },
    
    -- === SPECIALIZED SKILL TREE ===
    ["malware_analysis"] = {
        id = "malware_analysis",
        name = "Malware Analysis",
        description = "Reverse engineering and malware dissection",
        category = "specialized",
        maxLevel = 10,
        baseXpCost = 600,
        xpGrowth = 1.35,
        prerequisites = {"advanced_scanning"},
        effects = {
            trace = 0.12,
            efficiency = 0.1,
            malwareSignatureCreation = 0.2 -- Creates better threat signatures
        },
        unlockRequirements = {
            skills = {advanced_scanning = 4},
            missionTokens = 1
        }
    },
    
    ["penetration_testing"] = {
        id = "penetration_testing",
        name = "Penetration Testing",
        description = "Ethical hacking and vulnerability assessment",
        category = "specialized",
        maxLevel = 8,
        baseXpCost = 500,
        xpGrowth = 1.4,
        prerequisites = {"network_fundamentals", "system_administration"},
        effects = {
            trace = 0.15,
            efficiency = 0.12,
            vulnerabilityDiscovery = 0.25 -- Better at finding client weaknesses
        },
        unlockRequirements = {
            skills = {
                network_fundamentals = 6,
                system_administration = 4
            },
            reputation = 40
        }
    }
}

-- Skill categories for organization
SkillData.categories = {
    analysis = {
        name = "Analysis & Intelligence",
        description = "Skills focused on threat detection and analysis",
        color = "#4CAF50"
    },
    network = {
        name = "Network Security",
        description = "Network infrastructure protection and monitoring",
        color = "#2196F3"
    },
    incident = {
        name = "Incident Response",
        description = "Crisis management and recovery procedures",
        color = "#FF5722"
    },
    leadership = {
        name = "Leadership & Business",
        description = "Team management and business development",
        color = "#9C27B0"
    },
    technical = {
        name = "Technical Operations",
        description = "System administration and infrastructure",
        color = "#607D8B"
    },
    specialized = {
        name = "Specialized Skills",
        description = "Advanced and niche cybersecurity disciplines",
        color = "#FF9800"
    }
}

-- Get all skills
function SkillData.getAllSkills()
    return SkillData.skills
end

-- Get skills by category
function SkillData.getSkillsByCategory(category)
    local categorySkills = {}
    for skillId, skill in pairs(SkillData.skills) do
        if skill.category == category then
            categorySkills[skillId] = skill
        end
    end
    return categorySkills
end

-- Get skill by ID
function SkillData.getSkill(skillId)
    return SkillData.skills[skillId]
end

-- Get all categories
function SkillData.getCategories()
    return SkillData.categories
end

-- Get prerequisite chain for a skill
function SkillData.getPrerequisiteChain(skillId)
    local chain = {}
    local skill = SkillData.skills[skillId]
    
    if not skill then
        return chain
    end
    
    for _, prereqId in ipairs(skill.prerequisites) do
        table.insert(chain, prereqId)
        -- Recursively get prerequisites of prerequisites
        local subChain = SkillData.getPrerequisiteChain(prereqId)
        for _, subSkillId in ipairs(subChain) do
            -- Avoid duplicates
            local found = false
            for _, existingId in ipairs(chain) do
                if existingId == subSkillId then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(chain, subSkillId)
            end
        end
    end
    
    return chain
end

-- Validate skill system integrity
function SkillData.validateSkills()
    local errors = {}
    
    for skillId, skill in pairs(SkillData.skills) do
        -- Check prerequisites exist
        for _, prereqId in ipairs(skill.prerequisites) do
            if not SkillData.skills[prereqId] then
                table.insert(errors, "Skill '" .. skillId .. "' has invalid prerequisite: " .. prereqId)
            end
        end
        
        -- Check for circular dependencies (basic check)
        local chain = SkillData.getPrerequisiteChain(skillId)
        for _, chainSkillId in ipairs(chain) do
            if chainSkillId == skillId then
                table.insert(errors, "Circular dependency detected for skill: " .. skillId)
                break
            end
        end
        
        -- Check category exists
        if not SkillData.categories[skill.category] then
            table.insert(errors, "Skill '" .. skillId .. "' has invalid category: " .. skill.category)
        end
    end
    
    return errors
end

return SkillData