-- Achievement System
-- Tracks player progress and unlocks rewards

local achievements = {}
local resources = require("resources")
local format = require("format")

-- Achievement state
local achievementState = {
    unlocked = {},  -- Track which achievements are unlocked
    progress = {},  -- Track progress toward achievements
    notifications = {},  -- Recent achievement notifications
    
    totalDataBitsEarned = 0,
    totalClicks = 0,
    totalUpgradesPurchased = 0,
    totalThreatsDefeated = 0,
    maxCombo = 1,
    criticalHits = 0,
    
    -- Zone progression
    currentZone = "garage",
    zonesUnlocked = {"garage"},
}

-- Achievement definitions
local achievementDefinitions = {
    -- Clicking achievements
    {
        id = "first_click",
        name = "🖱️ First Click",
        description = "Click to earn your first Data Bit",
        requirement = {type = "clicks", value = 1},
        reward = {type = "none"},
        category = "clicking"
    },
    {
        id = "click_master",
        name = "🎯 Click Master", 
        description = "Perform 100 clicks",
        requirement = {type = "clicks", value = 100},
        reward = {type = "clickPower", value = 2},
        category = "clicking"
    },
    {
        id = "combo_king",
        name = "🔥 Combo King",
        description = "Achieve a 5x click combo",
        requirement = {type = "maxCombo", value = 5},
        reward = {type = "dataBits", value = 100},
        category = "clicking"
    },
    {
        id = "critical_striker",
        name = "💥 Critical Striker",
        description = "Land 10 critical hits",
        requirement = {type = "criticalHits", value = 10},
        reward = {type = "dataBits", value = 250},
        category = "clicking"
    },
    
    -- Earning achievements
    {
        id = "data_collector",
        name = "💎 Data Collector",
        description = "Earn 1,000 total Data Bits",
        requirement = {type = "totalDataBitsEarned", value = 1000},
        reward = {type = "dataBits", value = 100},
        category = "earning"
    },
    {
        id = "data_magnate",
        name = "💰 Data Magnate",
        description = "Earn 100,000 total Data Bits",
        requirement = {type = "totalDataBitsEarned", value = 100000},
        reward = {type = "dataBits", value = 5000},
        category = "earning"
    },
    {
        id = "millionaire",
        name = "🏆 Millionaire",
        description = "Earn 1,000,000 total Data Bits",
        requirement = {type = "totalDataBitsEarned", value = 1000000},
        reward = {type = "zone", value = "office"},
        category = "earning"
    },
    
    -- Upgrade achievements
    {
        id = "first_upgrade",
        name = "🔧 First Upgrade",
        description = "Purchase your first upgrade",
        requirement = {type = "totalUpgradesPurchased", value = 1},
        reward = {type = "dataBits", value = 50},
        category = "upgrades"
    },
    {
        id = "upgrade_enthusiast",
        name = "⚙️ Upgrade Enthusiast",
        description = "Purchase 25 upgrades",
        requirement = {type = "totalUpgradesPurchased", value = 25},
        reward = {type = "dataBits", value = 1000},
        category = "upgrades"
    },
    {
        id = "infrastructure_baron",
        name = "🏭 Infrastructure Baron",
        description = "Own 10 server racks",
        requirement = {type = "upgradeCount", upgrade = "basicServerRack", value = 10},
        reward = {type = "zone", value = "startup"},
        category = "upgrades"
    },
    
    -- Security achievements
    {
        id = "first_defense",
        name = "🛡️ First Defense",
        description = "Purchase your first security upgrade",
        requirement = {type = "securityUpgrade", value = 1},
        reward = {type = "dataBits", value = 100},
        category = "security"
    },
    {
        id = "cyber_guardian",
        name = "🔒 Cyber Guardian",
        description = "Survive 50 cyber attacks",
        requirement = {type = "totalThreatsDefeated", value = 50},
        reward = {type = "dataBits", value = 2000},
        category = "security"
    },
    
    -- Zone progression achievements
    {
        id = "leaving_garage",
        name = "🚪 Leaving the Garage",
        description = "Unlock the Startup Office zone",
        requirement = {type = "zone", value = "startup"},
        reward = {type = "dataBits", value = 1000},
        category = "progression"
    },
    {
        id = "corporate_climber",
        name = "🏢 Corporate Climber", 
        description = "Reach the Corporate Office zone",
        requirement = {type = "zone", value = "office"},
        reward = {type = "dataBits", value = 10000},
        category = "progression"
    },
    
    -- Special achievements
    {
        id = "admin_initiate",
        name = "👨‍💼 Admin Initiate",
        description = "Enter The Admin's Watch mode",
        requirement = {type = "adminMode", value = 1},
        reward = {type = "dataBits", value = 500},
        category = "special"
    },
    {
        id = "crisis_manager",
        name = "🚨 Crisis Manager",
        description = "Successfully handle 10 incidents in Admin mode",
        requirement = {type = "incidentsHandled", value = 10},
        reward = {type = "dataBits", value = 2500},
        category = "special"
    }
}

-- Zone definitions
local zoneDefinitions = {
    garage = {
        name = "🏠 Garage Startup",
        description = "Your humble beginnings in the family garage",
        unlockRequirement = {type = "none"},
        bonuses = {dataBitsMultiplier = 1.0},
        background = "garage"
    },
    startup = {
        name = "🚀 Startup Office",
        description = "A small office space with big dreams",
        unlockRequirement = {type = "upgradeCount", upgrade = "basicServerRack", value = 10},
        bonuses = {dataBitsMultiplier = 1.2},
        background = "startup"
    },
    office = {
        name = "🏢 Corporate Office",
        description = "Professional workspace with enterprise equipment",
        unlockRequirement = {type = "totalDataBitsEarned", value = 1000000},
        bonuses = {dataBitsMultiplier = 1.5},
        background = "office"
    },
    datacenter = {
        name = "🏭 Data Center",
        description = "Industrial-scale computing facility",
        unlockRequirement = {type = "totalDataBitsEarned", value = 10000000},
        bonuses = {dataBitsMultiplier = 2.0},
        background = "datacenter"
    },
    enterprise = {
        name = "🌐 Enterprise Campus",
        description = "Massive corporate technology campus",
        unlockRequirement = {type = "totalDataBitsEarned", value = 100000000},
        bonuses = {dataBitsMultiplier = 3.0},
        background = "enterprise"
    }
}

-- Initialize achievement system
function achievements.init()
    -- Initialize progress tracking
    for _, achievement in ipairs(achievementDefinitions) do
        achievementState.progress[achievement.id] = 0
        achievementState.unlocked[achievement.id] = false
    end
    
    print("🏆 Achievement system initialized")
    print("   " .. #achievementDefinitions .. " achievements available")
    print("   Current zone: " .. (zoneDefinitions[achievementState.currentZone].name or "Unknown"))
end

-- Update achievement progress
function achievements.update(dt)
    -- Check zone progression
    achievements.checkZoneProgression()
    
    -- Check all achievements
    for _, achievement in ipairs(achievementDefinitions) do
        if not achievementState.unlocked[achievement.id] then
            achievements.checkAchievement(achievement)
        end
    end
    
    -- Update notifications
    for i = #achievementState.notifications, 1, -1 do
        local notification = achievementState.notifications[i]
        notification.timeRemaining = notification.timeRemaining - dt
        
        if notification.timeRemaining <= 0 then
            table.remove(achievementState.notifications, i)
        end
    end
end

-- Track various events
function achievements.trackClick(reward, combo, critical)
    achievementState.totalClicks = achievementState.totalClicks + 1
    achievementState.totalDataBitsEarned = achievementState.totalDataBitsEarned + reward
    achievementState.maxCombo = math.max(achievementState.maxCombo, combo)
    
    if critical then
        achievementState.criticalHits = achievementState.criticalHits + 1
    end
end

function achievements.trackUpgradePurchase(upgradeName, cost)
    achievementState.totalUpgradesPurchased = achievementState.totalUpgradesPurchased + 1
    achievementState.totalDataBitsEarned = achievementState.totalDataBitsEarned + cost  -- Cost represents earned bits spent
end

function achievements.trackThreatDefeated()
    achievementState.totalThreatsDefeated = achievementState.totalThreatsDefeated + 1
end

function achievements.trackDataEarned(amount)
    achievementState.totalDataBitsEarned = achievementState.totalDataBitsEarned + amount
end

function achievements.trackAdminModeEntry()
    -- Track first entry to Admin's Watch mode
    achievements.updateProgress("admin_initiate", 1)
end

function achievements.trackIncidentHandled()
    achievements.updateProgress("crisis_manager", 1)
end

-- Update specific progress
function achievements.updateProgress(achievementId, amount)
    if achievementState.progress[achievementId] then
        achievementState.progress[achievementId] = achievementState.progress[achievementId] + amount
    end
end

-- Check if an achievement should be unlocked
function achievements.checkAchievement(achievement)
    local req = achievement.requirement
    local currentValue = 0
    
    if req.type == "clicks" then
        currentValue = achievementState.totalClicks or 0
    elseif req.type == "totalDataBitsEarned" then
        currentValue = achievementState.totalDataBitsEarned or 0
    elseif req.type == "totalUpgradesPurchased" then
        currentValue = achievementState.totalUpgradesPurchased or 0
    elseif req.type == "totalThreatsDefeated" then
        currentValue = achievementState.totalThreatsDefeated or 0
    elseif req.type == "maxCombo" then
        currentValue = achievementState.maxCombo or 1
    elseif req.type == "criticalHits" then
        currentValue = achievementState.criticalHits or 0
    elseif req.type == "upgradeCount" then
        local upgrades = resources.getUpgrades()
        currentValue = upgrades[req.upgrade] or 0
    elseif req.type == "securityUpgrade" then
        local upgrades = resources.getUpgrades()
        currentValue = (upgrades.basicPacketFilter or 0) + 
                      (upgrades.advancedFirewall or 0) + 
                      (upgrades.intrusionDetectionSystem or 0)
    elseif req.type == "zone" then
        -- Check if specific zone is unlocked
        currentValue = 0
        for _, zone in ipairs(achievementState.zonesUnlocked) do
            if zone == req.value then
                currentValue = 1
                break
            end
        end
    elseif req.type == "adminMode" or req.type == "incidentsHandled" then
        currentValue = achievementState.progress[achievement.id] or 0
    end
    
    -- Ensure both values are numbers before comparison
    local reqValue = tonumber(req.value) or 0
    local curValue = tonumber(currentValue) or 0
    
    if curValue >= reqValue then
        achievements.unlockAchievement(achievement)
    end
end

-- Unlock an achievement
function achievements.unlockAchievement(achievement)
    achievementState.unlocked[achievement.id] = true
    
    -- Apply reward
    achievements.applyReward(achievement.reward)
    
    -- Add notification
    table.insert(achievementState.notifications, {
        achievement = achievement,
        timeRemaining = 5.0  -- Show for 5 seconds
    })
    
    -- Console notification
    print("🏆 ACHIEVEMENT UNLOCKED!")
    print("   " .. achievement.name)
    print("   " .. achievement.description)
    
    if achievement.reward.type ~= "none" then
        print("   Reward: " .. achievements.formatReward(achievement.reward))
    end
end

-- Apply achievement reward
function achievements.applyReward(reward)
    if reward.type == "dataBits" then
        local currentResources = resources.save()
        currentResources.resources.dataBits = currentResources.resources.dataBits + reward.value
        resources.load(currentResources)
    elseif reward.type == "clickPower" then
        -- This would require expanding the resource system
        print("   Click power increased by " .. reward.value)
    elseif reward.type == "zone" then
        achievements.unlockZone(reward.value)
    end
end

-- Format reward for display
function achievements.formatReward(reward)
    if reward.type == "dataBits" then
        return "+" .. format.currency(reward.value) .. " Data Bits"
    elseif reward.type == "clickPower" then
        return "+" .. reward.value .. " click power"
    elseif reward.type == "zone" then
        return "Unlock " .. (zoneDefinitions[reward.value].name or reward.value)
    else
        return "Special reward"
    end
end

-- Check zone progression
function achievements.checkZoneProgression()
    for zoneName, zone in pairs(zoneDefinitions) do
        if not achievements.isZoneUnlocked(zoneName) then
            if achievements.meetsZoneRequirement(zone.unlockRequirement) then
                achievements.unlockZone(zoneName)
            end
        end
    end
end

-- Check if zone requirement is met
function achievements.meetsZoneRequirement(requirement)
    if requirement.type == "none" then
        return true
    elseif requirement.type == "totalDataBitsEarned" then
        return achievementState.totalDataBitsEarned >= requirement.value
    elseif requirement.type == "upgradeCount" then
        local upgrades = resources.getUpgrades()
        return (upgrades[requirement.upgrade] or 0) >= requirement.value
    end
    
    return false
end

-- Unlock a new zone
function achievements.unlockZone(zoneName)
    if not achievements.isZoneUnlocked(zoneName) then
        table.insert(achievementState.zonesUnlocked, zoneName)
        
        print("🌟 NEW ZONE UNLOCKED!")
        print("   " .. (zoneDefinitions[zoneName].name or zoneName))
        print("   " .. (zoneDefinitions[zoneName].description or ""))
        
        -- Auto-switch to new zone if it's better
        if zoneDefinitions[zoneName].bonuses.dataBitsMultiplier > 
           zoneDefinitions[achievementState.currentZone].bonuses.dataBitsMultiplier then
            achievements.switchZone(zoneName)
        end
    end
end

-- Switch to a different zone
function achievements.switchZone(zoneName)
    if achievements.isZoneUnlocked(zoneName) then
        achievementState.currentZone = zoneName
        print("📍 Moved to " .. (zoneDefinitions[zoneName].name or zoneName))
        
        -- Recalculate resources with new bonuses
        resources.recalculateGeneration()
    end
end

-- Check if zone is unlocked
function achievements.isZoneUnlocked(zoneName)
    for _, zone in ipairs(achievementState.zonesUnlocked) do
        if zone == zoneName then
            return true
        end
    end
    return false
end

-- Get current zone bonus
function achievements.getCurrentZoneBonus()
    local zone = zoneDefinitions[achievementState.currentZone]
    return zone and zone.bonuses or {dataBitsMultiplier = 1.0}
end

-- Get achievement statistics for UI
function achievements.getStats()
    local unlockedCount = 0
    for _, unlocked in pairs(achievementState.unlocked) do
        if unlocked then
            unlockedCount = unlockedCount + 1
        end
    end
    
    return {
        totalAchievements = #achievementDefinitions,
        unlockedAchievements = unlockedCount,
        currentZone = achievementState.currentZone,
        zonesUnlocked = #achievementState.zonesUnlocked,
        totalZones = 5,
        notifications = achievementState.notifications,
        
        -- Progress stats
        totalClicks = achievementState.totalClicks,
        totalDataBitsEarned = achievementState.totalDataBitsEarned,
        totalUpgradesPurchased = achievementState.totalUpgradesPurchased,
        maxCombo = achievementState.maxCombo,
        criticalHits = achievementState.criticalHits,
    }
end

-- Get all achievement definitions for UI
function achievements.getAchievements()
    local result = {}
    for _, achievement in ipairs(achievementDefinitions) do
        table.insert(result, {
            id = achievement.id,
            name = achievement.name,
            description = achievement.description,
            category = achievement.category,
            unlocked = achievementState.unlocked[achievement.id],
            progress = achievements.getAchievementProgress(achievement),
            reward = achievement.reward
        })
    end
    return result
end

-- Get progress toward specific achievement
function achievements.getAchievementProgress(achievement)
    local req = achievement.requirement
    local currentValue = 0
    
    if req.type == "clicks" then
        currentValue = achievementState.totalClicks
    elseif req.type == "totalDataBitsEarned" then
        currentValue = achievementState.totalDataBitsEarned
    elseif req.type == "totalUpgradesPurchased" then
        currentValue = achievementState.totalUpgradesPurchased
    elseif req.type == "maxCombo" then
        currentValue = achievementState.maxCombo
    elseif req.type == "criticalHits" then
        currentValue = achievementState.criticalHits
    elseif req.type == "upgradeCount" then
        local upgrades = resources.getUpgrades()
        currentValue = upgrades[req.upgrade] or 0
    elseif req.type == "securityUpgrade" then
        local upgrades = resources.getUpgrades()
        currentValue = (upgrades.basicPacketFilter or 0) + 
                      (upgrades.advancedFirewall or 0) + 
                      (upgrades.intrusionDetectionSystem or 0)
    else
        currentValue = achievementState.progress[achievement.id] or 0
    end
    
    return {
        current = currentValue,
        required = req.value,
        percentage = math.min(100, (tonumber(currentValue) / tonumber(req.value)) * 100)
    }
end

-- Get available zones for UI
function achievements.getZones()
    local result = {}
    for zoneName, zone in pairs(zoneDefinitions) do
        table.insert(result, {
            id = zoneName,
            name = zone.name,
            description = zone.description,
            unlocked = achievements.isZoneUnlocked(zoneName),
            current = achievementState.currentZone == zoneName,
            bonuses = zone.bonuses
        })
    end
    return result
end

-- Save/Load support
function achievements.save()
    return achievementState
end

function achievements.load(savedState)
    if savedState then
        achievementState = savedState
    end
end

-- Show achievement status (console output for now)
function achievements.showAchievements()
    local stats = achievements.getStats()
    
    print("\n🏆 ACHIEVEMENT PROGRESS")
    print("═══════════════════════")
    print(string.format("Progress: %d/%d achievements unlocked", 
                       stats.unlockedAchievements, stats.totalAchievements))
    print(string.format("Zone: %s (%d/%d zones)", 
                       zoneDefinitions[stats.currentZone].name, 
                       stats.zonesUnlocked, stats.totalZones))
    print("")
    
    -- Show statistics
    print("📊 STATISTICS:")
    print("   💎 Total Data Bits Earned: " .. format.currency(stats.totalDataBitsEarned))
    print("   🖱️  Total Clicks: " .. stats.totalClicks)
    print("   🛒 Upgrades Purchased: " .. stats.totalUpgradesPurchased)
    print("   🔥 Max Combo: " .. string.format("%.1fx", stats.maxCombo))
    print("   💥 Critical Hits: " .. stats.criticalHits)
    print("")
    
    -- Show unlocked achievements
    local unlockedCount = 0
    for id, unlocked in pairs(achievementState.unlocked) do
        if unlocked then
            unlockedCount = unlockedCount + 1
        end
    end
    
    if unlockedCount > 0 then
        print("✅ RECENT ACHIEVEMENTS:")
        for _, achievement in ipairs(achievementDefinitions) do
            if achievementState.unlocked[achievement.id] then
                print("   " .. achievement.name .. " - " .. achievement.description)
                if unlockedCount <= 3 then -- Only show first few to avoid spam
                    unlockedCount = unlockedCount - 1
                    if unlockedCount <= 0 then break end
                end
            end
        end
        print("")
    end
    
    print("🎯 Press 'H' to view achievements")
end

return achievements