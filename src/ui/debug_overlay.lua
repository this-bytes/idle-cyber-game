-- Debug Overlay - Comprehensive Game State Inspector
-- Can be overlaid on any scene to inspect game economy and systems in-depth
-- Toggle with F3 key

local DebugOverlay = {}
DebugOverlay.__index = DebugOverlay

function DebugOverlay.new(eventBus, systems)
    local self = setmetatable({}, DebugOverlay)
    
    self.eventBus = eventBus
    self.systems = systems
    self.visible = false
    self.updateTimer = 0
    self.updateInterval = 0.1 -- Update every 100ms
    
    -- Layout configuration
    self.layout = {
        margin = 10,
        panelWidth = 380,
        panelHeight = 160,
        columnSpacing = 10,
        rowSpacing = 10,
        fontSize = 10,
        titleFontSize = 12,
        headerHeight = 35
    }
    
    -- Cached data for display
    self.cachedData = {
        resources = {},
        contracts = {},
        specialists = {},
        threats = {},
        upgrades = {},
        skills = {},
        idle = {},
        progression = {},
        rng = {}
    }
    
    return self
end

function DebugOverlay:toggle()
    self.visible = not self.visible
    print(string.format("🔍 Debug Overlay: %s", self.visible and "ENABLED" or "DISABLED"))
end

function DebugOverlay:show()
    self.visible = true
end

function DebugOverlay:hide()
    self.visible = false
end

function DebugOverlay:update(dt)
    if not self.visible then return end
    
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer >= self.updateInterval then
        self:updateCachedData()
        self.updateTimer = 0
    end
end

function DebugOverlay:updateCachedData()
    if not self.systems then return end
    
    -- Update resource data
    if self.systems.resourceManager then
        self.cachedData.resources = self:getResourceData()
    end
    
    -- Update contract data
    if self.systems.contractSystem then
        self.cachedData.contracts = self:getContractData()
    end
    
    -- Update specialist data
    if self.systems.specialistSystem then
        self.cachedData.specialists = self:getSpecialistData()
    end
    
    -- Update threat data
    if self.systems.threatSystem then
        self.cachedData.threats = self:getThreatData()
    end
    
    -- Update upgrade data
    if self.systems.upgradeSystem then
        self.cachedData.upgrades = self:getUpgradeData()
    end
    
    -- Update skill data
    if self.systems.skillSystem then
        self.cachedData.skills = self:getSkillData()
    end
    
    -- Update idle system data
    if self.systems.idleSystem then
        self.cachedData.idle = self:getIdleData()
    end
    
    -- Update progression data
    if self.systems.progressionSystem then
        self.cachedData.progression = self:getProgressionData()
    end
    
    -- Update RNG data
    self.cachedData.rng = self:getRNGData()
end

function DebugOverlay:getResourceData()
    local rm = self.systems.resourceManager
    local data = {
        money = rm.resources.money or 0,
        moneyRate = rm.generationRates and rm.generationRates.money or 0,
        moneyMultiplier = rm.multipliers and rm.multipliers.money or 1.0,
        reputation = rm.resources.reputation or 0,
        reputationRate = rm.generationRates and rm.generationRates.reputation or 0,
        reputationMultiplier = rm.multipliers and rm.multipliers.reputation or 1.0,
        xp = rm.resources.xp or 0,
        xpRate = rm.generationRates and rm.generationRates.xp or 0,
        xpMultiplier = rm.multipliers and rm.multipliers.xp or 1.0,
        missionTokens = rm.resources.missionTokens or 0,
        totalMoneyEarned = rm.resources.totalMoneyEarned or 0,
        totalMoneySpent = rm.resources.totalMoneySpent or 0,
        totalReputationEarned = rm.resources.totalReputationEarned or 0
    }
    return data
end

function DebugOverlay:getContractData()
    local cs = self.systems.contractSystem
    local data = {
        available = self:countTable(cs.availableContracts),
        active = self:countTable(cs.activeContracts),
        completed = #(cs.completedContracts or {}),
        autoAcceptEnabled = cs.autoAcceptEnabled or false,
        maxActive = cs.maxActiveContracts or 0,
        nextContractId = cs.nextContractId or 0,
        generationTimer = cs.contractGenerationTimer or 0,
        generationInterval = cs.contractGenerationInterval or 0
    }
    return data
end

function DebugOverlay:getSpecialistData()
    local ss = self.systems.specialistSystem
    local all = ss:getAllSpecialists() or {}
    
    local available = 0
    local busy = 0
    local total = self:countTable(all)
    
    for _, spec in pairs(all) do
        if spec.status == "available" then
            available = available + 1
        elseif spec.status == "busy" then
            busy = busy + 1
        end
    end
    
    local data = {
        total = total,
        available = available,
        busy = busy,
        nextId = ss.nextSpecialistId or 0
    }
    return data
end

function DebugOverlay:getThreatData()
    local ts = self.systems.threatSystem
    local data = {
        active = self:countTable(ts.activeThreats or {}),
        templates = #(ts.threatTemplates or {}),
        nextId = ts.nextThreatId or 0,
        generationTimer = ts.threatGenerationTimer or 0,
        generationInterval = ts.threatGenerationInterval or 0,
        enabled = ts.enabled or false
    }
    return data
end

function DebugOverlay:getUpgradeData()
    local us = self.systems.upgradeSystem
    local data = {
        total = #(us.allUpgrades or {}),
        purchased = self:countTable(us.purchasedUpgrades or {}),
        trees = self:countTable(us.upgradeTrees or {})
    }
    return data
end

function DebugOverlay:getSkillData()
    local ss = self.systems.skillSystem
    local data = {
        definitions = ss.skillDefinitions and self:countTable(ss.skillDefinitions) or 0,
        unlockedCount = 0
    }
    
    if ss.unlockedSkills then
        data.unlockedCount = self:countTable(ss.unlockedSkills)
    end
    
    return data
end

function DebugOverlay:getIdleData()
    local is = self.systems.idleSystem
    local data = {
        lastSaveTime = is.lastSaveTime or 0,
        totalEarnings = is.idleData and is.idleData.totalEarnings or 0,
        totalDamage = is.idleData and is.idleData.totalDamage or 0,
        threatTypes = self:countTable(is.threatTypes or {})
    }
    return data
end

function DebugOverlay:getProgressionData()
    local ps = self.systems.progressionSystem
    if not ps then return {} end
    
    local data = {
        level = ps.level or 1,
        xp = ps.xp or 0,
        xpToNextLevel = ps.xpToNextLevel or 100,
        unlockedFeatures = ps.unlockedFeatures and #ps.unlockedFeatures or 0
    }
    return data
end

function DebugOverlay:getRNGData()
    -- Track RNG state - Lua uses a global random seed
    local data = {
        -- Sample random values to show distribution
        sample1 = math.random(),
        sample2 = math.random(),
        sample3 = math.random(),
        timestamp = love.timer and love.timer.getTime() or 0
    }
    return data
end

function DebugOverlay:draw()
    if not self.visible then return end
    
    -- Semi-transparent dark background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw header
    self:drawHeader()
    
    -- Draw panels in a grid layout
    local startY = self.layout.headerHeight
    local col1X = self.layout.margin
    local col2X = col1X + self.layout.panelWidth + self.layout.columnSpacing
    
    local row1Y = startY + self.layout.margin
    local row2Y = row1Y + self.layout.panelHeight + self.layout.rowSpacing
    local row3Y = row2Y + self.layout.panelHeight + self.layout.rowSpacing
    local row4Y = row3Y + self.layout.panelHeight + self.layout.rowSpacing
    
    -- Left column
    self:drawResourcePanel(col1X, row1Y)
    self:drawContractPanel(col1X, row2Y)
    self:drawThreatPanel(col1X, row3Y)
    self:drawIdlePanel(col1X, row4Y)
    
    -- Right column
    self:drawSpecialistPanel(col2X, row1Y)
    self:drawUpgradePanel(col2X, row2Y)
    self:drawSkillPanel(col2X, row3Y)
    self:drawProgressionPanel(col2X, row4Y)
    
    -- Draw controls footer
    self:drawFooter()
end

function DebugOverlay:drawHeader()
    love.graphics.setColor(0.2, 0.4, 0.8, 0.95)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.layout.headerHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("🔍 DEBUG OVERLAY - GAME STATE INSPECTOR", self.layout.margin, 8)
    
    -- Show FPS and update stats
    love.graphics.setNewFont(self.layout.fontSize)
    local fps = love.timer and love.timer.getFPS() or 0
    local statsText = string.format("FPS: %d | Press F3 to toggle", fps)
    love.graphics.printf(statsText, 0, 12, love.graphics.getWidth() - self.layout.margin, "right")
end

function DebugOverlay:drawFooter()
    local y = love.graphics.getHeight() - 25
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 25)
    
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.setNewFont(self.layout.fontSize)
    love.graphics.print("Controls: F3 - Toggle Debug | ESC - Close", self.layout.margin, y + 7)
end

function DebugOverlay:drawPanel(title, icon, x, y, content)
    local w = self.layout.panelWidth
    local h = self.layout.panelHeight
    
    -- Panel background
    love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    
    -- Panel border
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 5, 5)
    love.graphics.setLineWidth(1)
    
    -- Title bar
    love.graphics.setColor(0.25, 0.25, 0.35, 1)
    love.graphics.rectangle("fill", x, y, w, 22, 5, 5)
    
    -- Title text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setNewFont(self.layout.titleFontSize)
    love.graphics.print(icon .. " " .. title, x + 8, y + 5)
    
    -- Content
    love.graphics.setNewFont(self.layout.fontSize)
    local contentY = y + 28
    for _, line in ipairs(content) do
        love.graphics.setColor(line.color or {1, 1, 1, 1})
        love.graphics.print(line.text, x + 8, contentY)
        contentY = contentY + 15
    end
end

function DebugOverlay:drawResourcePanel(x, y)
    local res = self.cachedData.resources
    local content = {
        {text = string.format("Money: $%.0f", res.money), color = {0.2, 1, 0.2, 1}},
        {text = string.format("  Rate: $%.1f/sec (x%.2f)", res.moneyRate, res.moneyMultiplier), color = {0.7, 0.7, 0.7, 1}},
        {text = string.format("Reputation: %.1f (+%.2f/sec)", res.reputation, res.reputationRate), color = {1, 0.8, 0.2, 1}},
        {text = string.format("XP: %.0f (+%.1f/sec)", res.xp, res.xpRate), color = {0.5, 0.8, 1, 1}},
        {text = string.format("Mission Tokens: %d", res.missionTokens), color = {1, 0.5, 1, 1}},
        {text = string.format("Total Earned: $%.0f", res.totalMoneyEarned), color = {0.6, 0.6, 0.6, 1}},
        {text = string.format("Total Spent: $%.0f", res.totalMoneySpent), color = {0.6, 0.6, 0.6, 1}}
    }
    self:drawPanel("RESOURCES", "💰", x, y, content)
end

function DebugOverlay:drawContractPanel(x, y)
    local con = self.cachedData.contracts
    local content = {
        {text = string.format("Available: %d", con.available), color = {0.8, 0.8, 1, 1}},
        {text = string.format("Active: %d / %d", con.active, con.maxActive), color = {0.2, 1, 0.2, 1}},
        {text = string.format("Completed: %d", con.completed), color = {0.5, 1, 0.5, 1}},
        {text = string.format("Auto-Accept: %s", con.autoAcceptEnabled and "ON" or "OFF"), color = {1, 1, 0.2, 1}},
        {text = string.format("Next ID: %d", con.nextContractId), color = {0.7, 0.7, 0.7, 1}},
        {text = string.format("Gen Timer: %.1f / %.1f", con.generationTimer, con.generationInterval), color = {0.7, 0.7, 0.7, 1}}
    }
    self:drawPanel("CONTRACTS", "📋", x, y, content)
end

function DebugOverlay:drawSpecialistPanel(x, y)
    local spec = self.cachedData.specialists
    local content = {
        {text = string.format("Total: %d", spec.total), color = {1, 1, 1, 1}},
        {text = string.format("Available: %d", spec.available), color = {0.2, 1, 0.2, 1}},
        {text = string.format("Busy: %d", spec.busy), color = {1, 0.5, 0.2, 1}},
        {text = string.format("Next ID: %d", spec.nextId), color = {0.7, 0.7, 0.7, 1}}
    }
    self:drawPanel("SPECIALISTS", "👥", x, y, content)
end

function DebugOverlay:drawThreatPanel(x, y)
    local thr = self.cachedData.threats
    local content = {
        {text = string.format("Active Threats: %d", thr.active), color = {1, 0.3, 0.3, 1}},
        {text = string.format("Templates: %d", thr.templates), color = {0.8, 0.8, 0.8, 1}},
        {text = string.format("Next ID: %d", thr.nextId), color = {0.7, 0.7, 0.7, 1}},
        {text = string.format("Gen Timer: %.1f / %.1f", thr.generationTimer, thr.generationInterval), color = {0.7, 0.7, 0.7, 1}},
        {text = string.format("System: %s", thr.enabled and "ENABLED" or "DISABLED"), color = thr.enabled and {0.2, 1, 0.2, 1} or {1, 0.3, 0.3, 1}}
    }
    self:drawPanel("THREATS", "🚨", x, y, content)
end

function DebugOverlay:drawUpgradePanel(x, y)
    local upg = self.cachedData.upgrades
    local content = {
        {text = string.format("Total Upgrades: %d", upg.total), color = {1, 1, 1, 1}},
        {text = string.format("Purchased: %d", upg.purchased), color = {0.2, 1, 0.2, 1}},
        {text = string.format("Trees: %d", upg.trees), color = {0.8, 0.8, 1, 1}}
    }
    self:drawPanel("UPGRADES", "⬆️", x, y, content)
end

function DebugOverlay:drawSkillPanel(x, y)
    local skill = self.cachedData.skills
    local content = {
        {text = string.format("Skill Definitions: %d", skill.definitions), color = {1, 1, 1, 1}},
        {text = string.format("Unlocked: %d", skill.unlockedCount), color = {0.2, 1, 0.2, 1}}
    }
    self:drawPanel("SKILLS", "🎯", x, y, content)
end

function DebugOverlay:drawIdlePanel(x, y)
    local idle = self.cachedData.idle
    local timeSinceLastSave = (os.time() - idle.lastSaveTime)
    local content = {
        {text = string.format("Last Save: %ds ago", timeSinceLastSave), color = {0.8, 0.8, 1, 1}},
        {text = string.format("Total Earnings: $%.0f", idle.totalEarnings), color = {0.2, 1, 0.2, 1}},
        {text = string.format("Total Damage: $%.0f", idle.totalDamage), color = {1, 0.3, 0.3, 1}},
        {text = string.format("Threat Types: %d", idle.threatTypes), color = {0.8, 0.8, 0.8, 1}}
    }
    self:drawPanel("IDLE SYSTEM", "💤", x, y, content)
end

function DebugOverlay:drawProgressionPanel(x, y)
    local prog = self.cachedData.progression
    local content = {}
    
    if prog.level then
        content = {
            {text = string.format("Level: %d", prog.level), color = {1, 0.8, 0.2, 1}},
            {text = string.format("XP: %.0f / %.0f", prog.xp, prog.xpToNextLevel), color = {0.5, 0.8, 1, 1}},
            {text = string.format("Progress: %.1f%%", (prog.xp / prog.xpToNextLevel * 100)), color = {0.7, 0.7, 0.7, 1}},
            {text = string.format("Unlocked: %d features", prog.unlockedFeatures), color = {0.2, 1, 0.2, 1}}
        }
    else
        content = {
            {text = "No progression system", color = {0.5, 0.5, 0.5, 1}}
        }
    end
    
    self:drawPanel("PROGRESSION", "📊", x, y, content)
end

function DebugOverlay:countTable(tbl)
    if type(tbl) ~= "table" then return 0 end
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

return DebugOverlay
