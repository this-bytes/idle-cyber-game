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

return GameConfig
