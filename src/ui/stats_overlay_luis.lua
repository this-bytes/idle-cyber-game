-- Stats Overlay - Player-Facing Game State Inspector (LUIS Version)
-- Can be overlaid on any scene to inspect game economy and systems in-depth
-- Toggle with F3 key
-- Migrated to LUIS (Love UI System) for consistency with new UI framework

--[[
    LUIS OVERLAY PATTERN
    ====================
    
    This overlay demonstrates how to use LUIS for modal overlays that can
    appear on top of any scene.
    
    KEY DIFFERENCES FROM SCENES:
    - Overlay layer is created once and toggled (enabled/disabled)
    - No load()/exit() methods - uses show()/hide() instead
    - Must explicitly enable/disable layer on visibility changes
    - Rebuilds UI on each show() to reflect current game state
--]]

local StatsOverlayLuis = {}
StatsOverlayLuis.__index = StatsOverlayLuis

function StatsOverlayLuis.new(eventBus, systems, luis)
    local self = setmetatable({}, StatsOverlayLuis)
    
    self.eventBus = eventBus
    self.systems = systems
    self.luis = luis  -- Direct LUIS instance
    self.layerName = "stats_overlay"
    self.visible = false
    self.updateTimer = 0
    self.updateInterval = 0.5 -- Update every 500ms
    
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
        achievements = {},
        events = {},
        rng = {}
    }

    -- Make this overlay modal by default: when visible it should block scene input
    self.modal = true

    -- Create the LUIS layer once (will be enabled/disabled on toggle)
    self.luis.newLayer(self.layerName)
    self.luis.disableLayer(self.layerName) -- Start hidden
    
    print("🔍 StatsOverlayLuis: Created with LUIS layer '" .. self.layerName .. "'")
    
    return self
end

function StatsOverlayLuis:toggle()
    self.visible = not self.visible
    print(string.format("🔍 Debug Overlay: %s", self.visible and "ENABLED" or "DISABLED"))
    
    if self.visible then
        self:show()
    else
        self:hide()
    end
end

function StatsOverlayLuis:show()
    self.visible = true
    
    -- Update data before showing
    self:updateCachedData()
    
    -- Rebuild UI with current data
    self:buildUI()
    
    -- Enable the LUIS layer
    self.luis.enableLayer(self.layerName)
end

function StatsOverlayLuis:hide()
    self.visible = false
    
    -- Disable the LUIS layer
    self.luis.disableLayer(self.layerName)
end

function StatsOverlayLuis:update(dt)
    if not self.visible then return end
    
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer >= self.updateInterval then
        self:updateCachedData()
        -- Rebuild UI with updated data
        self:buildUI()
        self.updateTimer = 0
    end
end

function StatsOverlayLuis:updateCachedData()
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
    
    -- Update achievement data
    if self.systems.achievementSystem then
        self.cachedData.achievements = self:getAchievementData()
    end
    
    -- Update event system data
    if self.systems.eventSystem then
        self.cachedData.events = self:getEventData()
    end
    
    -- Update RNG data
    self.cachedData.rng = self:getRNGData()
end

function StatsOverlayLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    -- Clear existing layer elements
    if luis.isLayerEnabled(self.layerName) then
        luis.disableLayer(self.layerName)
    end
    luis.removeLayer(self.layerName)
    luis.newLayer(self.layerName)
    luis.setCurrentLayer(self.layerName)
    
    -- Layout configuration (adapted to LUIS grid system)
    local panelWidth = 18  -- grid units
    local panelHeight = 10 -- grid units
    local margin = 1
    local spacing = 1
    
    -- Calculate starting positions
    local col1 = margin
    local col2 = col1 + panelWidth + spacing
    local col3 = col2 + panelWidth + spacing
    
    local row1 = margin + 3  -- Leave space for header
    local row2 = row1 + panelHeight + spacing
    local row3 = row2 + panelHeight + spacing
    local row4 = row3 + panelHeight + spacing
    
    -- Header background (dark overlay)
    -- Note: LUIS doesn't have a simple "full screen overlay" widget, so we'll
    -- use the theme system and labels to create the visual effect
    
    -- Create a semi-transparent background using a large label
    -- This simulates the dark overlay
    -- NOTE: Using an empty label as a background overlay is a workaround.
    -- Consider creating a dedicated background widget for better clarity and maintainability.
    local bgWidth = math.floor(screenWidth / gridSize)
    local bgHeight = math.floor(screenHeight / gridSize)
    local background = luis.newLabel("", bgWidth, bgHeight, 0, 0)
    -- Note: LUIS doesn't support custom colors easily per widget without theme customization
    -- We'll rely on the default theme for now
    luis.insertElement(self.layerName, background)
    
    -- Title label
    local title = luis.newLabel("🔍 DEBUG OVERLAY - GAME STATE INSPECTOR", 50, 2, 1, margin)
    luis.insertElement(self.layerName, title)
    
    -- Stats label (FPS)
    local fps = love.timer and love.timer.getFPS() or 0
    local statsText = string.format("FPS: %d | Press F3 to toggle | ESC to close", fps)
    local stats = luis.newLabel(statsText, 50, 1, 2, margin)
    luis.insertElement(self.layerName, stats)
    
    -- Column 1 - Core Economy
    self:createPanel(col1, row1, panelWidth, panelHeight, "💰 RESOURCES", self:getResourceContent())
    self:createPanel(col1, row2, panelWidth, panelHeight, "📋 CONTRACTS", self:getContractContent())
    self:createPanel(col1, row3, panelWidth, panelHeight, "🚨 THREATS", self:getThreatContent())
    self:createPanel(col1, row4, panelWidth, panelHeight, "🎲 EVENTS", self:getEventContent())
    
    -- Column 2 - Systems
    self:createPanel(col2, row1, panelWidth, panelHeight, "👥 SPECIALISTS", self:getSpecialistContent())
    self:createPanel(col2, row2, panelWidth, panelHeight, "⬆️ UPGRADES", self:getUpgradeContent())
    self:createPanel(col2, row3, panelWidth, panelHeight, "🎯 SKILLS", self:getSkillContent())
    self:createPanel(col2, row4, panelWidth, panelHeight, "🎰 RNG STATE", self:getRNGContent())
    
    -- Column 3 - Meta
    self:createPanel(col3, row1, panelWidth, panelHeight, "💤 IDLE SYSTEM", self:getIdleContent())
    self:createPanel(col3, row2, panelWidth, panelHeight, "📊 PROGRESSION", self:getProgressionContent())
    self:createPanel(col3, row3, panelWidth, panelHeight, "🏆 ACHIEVEMENTS", self:getAchievementContent())
    self:createPanel(col3, row4, panelWidth, panelHeight, "📈 SUMMARY", self:getSummaryContent())
    
    -- Enable the layer now that UI is built
    luis.enableLayer(self.layerName)
end

function StatsOverlayLuis:createPanel(col, row, width, height, title, content)
    local luis = self.luis
    
    -- Panel title
    local titleLabel = luis.newLabel(title, width, 1, row, col)
    luis.insertElement(self.layerName, titleLabel)
    
    -- Panel content (multiple lines)
    local contentRow = row + 1
    for i, line in ipairs(content) do
        if contentRow < row + height then
            local label = luis.newLabel(line, width, 1, contentRow, col)
            luis.insertElement(self.layerName, label)
            contentRow = contentRow + 1
        end
    end
end

-- Content generation methods (return array of text lines)
function StatsOverlayLuis:getResourceContent()
    local res = self.cachedData.resources or {}
    return {
        string.format("Money: $%.0f", res.money or 0),
        string.format("  Rate: $%.1f/s (x%.2f)", res.moneyRate or 0, res.moneyMultiplier or 1),
        string.format("Rep: %.1f (+%.2f/s)", res.reputation or 0, res.reputationRate or 0),
        string.format("XP: %.0f (+%.1f/s)", res.xp or 0, res.xpRate or 0),
        string.format("Tokens: %d", res.missionTokens or 0),
        string.format("Earned: $%.0f", res.totalMoneyEarned or 0),
        string.format("Spent: $%.0f", res.totalMoneySpent or 0)
    }
end

function StatsOverlayLuis:getContractContent()
    local con = self.cachedData.contracts or {}
    return {
        string.format("Available: %d", con.available or 0),
        string.format("Active: %d / %d", con.active or 0, con.maxActive or 0),
        string.format("Completed: %d", con.completed or 0),
        string.format("Auto: %s", (con.autoAcceptEnabled and "ON") or "OFF"),
        string.format("Next ID: %d", con.nextContractId or 0),
        string.format("Timer: %.1f / %.1f", con.generationTimer or 0, con.generationInterval or 0)
    }
end

function StatsOverlayLuis:getSpecialistContent()
    local spec = self.cachedData.specialists or {}
    return {
        string.format("Total: %d", spec.total or 0),
        string.format("Available: %d", spec.available or 0),
        string.format("Busy: %d", spec.busy or 0),
        string.format("Next ID: %d", spec.nextId or 0)
    }
end

function StatsOverlayLuis:getThreatContent()
    local thr = self.cachedData.threats or {}
    return {
        string.format("Active: %d", thr.active or 0),
        string.format("Templates: %d", thr.templates or 0),
        string.format("Next ID: %d", thr.nextId or 0),
        string.format("Timer: %.1f / %.1f", thr.generationTimer or 0, thr.generationInterval or 0),
        string.format("System: %s", (thr.enabled and "ON") or "OFF")
    }
end

function StatsOverlayLuis:getUpgradeContent()
    local upg = self.cachedData.upgrades or {}
    return {
        string.format("Total: %d", upg.total or 0),
        string.format("Purchased: %d", upg.purchased or 0),
        string.format("Trees: %d", upg.trees or 0)
    }
end

function StatsOverlayLuis:getSkillContent()
    local skill = self.cachedData.skills or {}
    return {
        string.format("Definitions: %d", skill.definitions or 0),
        string.format("Unlocked: %d", skill.unlockedCount or 0)
    }
end

function StatsOverlayLuis:getIdleContent()
    local idle = self.cachedData.idle or {}
    local timeSince = (os.time() - (idle.lastSaveTime or os.time()))
    return {
        string.format("Last Save: %ds ago", timeSince),
        string.format("Earnings: $%.0f", idle.totalEarnings or 0),
        string.format("Damage: $%.0f", idle.totalDamage or 0),
        string.format("Threats: %d", idle.threatTypes or 0)
    }
end

function StatsOverlayLuis:getProgressionContent()
    local prog = self.cachedData.progression or {}
    if prog.level then
        local percent = (prog.xpToNextLevel or 0) > 0 and ((prog.xp or 0) / prog.xpToNextLevel * 100) or 0
        return {
            string.format("Level: %d", prog.level or 1),
            string.format("XP: %.0f / %.0f", prog.xp or 0, prog.xpToNextLevel or 0),
            string.format("Progress: %.1f%%", percent),
            string.format("Features: %d", prog.unlockedFeatures or 0)
        }
    else
        return {"No progression system"}
    end
end

function StatsOverlayLuis:getAchievementContent()
    local ach = self.cachedData.achievements or {}
    local percent = (ach.total or 0) > 0 and ((ach.unlocked or 0) / ach.total * 100) or 0
    return {
        string.format("Total: %d", ach.total or 0),
        string.format("Unlocked: %d", ach.unlocked or 0),
        string.format("Progress: %d", ach.progress or 0),
        string.format("Complete: %.1f%%", percent)
    }
end

function StatsOverlayLuis:getEventContent()
    local evt = self.cachedData.events or {}
    return {
        string.format("Total: %d", evt.total or 0),
        string.format("Active: %d", evt.active or 0),
        string.format("Timer: %.1fs / %.1fs", evt.timer or 0, evt.baseInterval or 0),
        string.format("Weight: %.2f", evt.totalWeight or 0)
    }
end

function StatsOverlayLuis:getRNGContent()
    local rng = self.cachedData.rng or {}
    return {
        string.format("S1: %.6f", rng.sample1 or 0),
        string.format("S2: %.6f", rng.sample2 or 0),
        string.format("S3: %.6f", rng.sample3 or 0),
        string.format("Time: %.2fs", rng.timestamp or 0)
    }
end

function StatsOverlayLuis:getSummaryContent()
    local res = self.cachedData.resources or {}
    local con = self.cachedData.contracts or {}
    local spec = self.cachedData.specialists or {}
    local thr = self.cachedData.threats or {}
    
    local netIncome = res.moneyRate or 0
    local systemsActive = ((con.active or 0) > 0 and 1 or 0) + (thr.enabled and 1 or 0) + ((spec.total or 0) > 0 and 1 or 0)
    
    return {
        string.format("Income: $%.1f/s", netIncome),
        string.format("Systems: %d", systemsActive),
        string.format("Health: %s", netIncome > 0 and "GOOD" or "POOR"),
        string.format("Uptime: %.0fs", love.timer and love.timer.getTime() or 0)
    }
end

-- Data extraction methods (same as original)
function StatsOverlayLuis:getResourceData()
    local rm = self.systems.resourceManager
    return {
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
end

function StatsOverlayLuis:getContractData()
    local cs = self.systems.contractSystem
    return {
        available = self:countTable(cs.availableContracts),
        active = self:countTable(cs.activeContracts),
        completed = #(cs.completedContracts or {}),
        autoAcceptEnabled = cs.autoAcceptEnabled or false,
        maxActive = cs.maxActiveContracts or 0,
        nextContractId = cs.nextContractId or 0,
        generationTimer = cs.contractGenerationTimer or 0,
        generationInterval = cs.contractGenerationInterval or 0
    }
end

function StatsOverlayLuis:getSpecialistData()
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
    
    return {
        total = total,
        available = available,
        busy = busy,
        nextId = ss.nextSpecialistId or 0
    }
end

function StatsOverlayLuis:getThreatData()
    local ts = self.systems.threatSystem
    return {
        active = self:countTable(ts.activeThreats or {}),
        templates = #(ts.threatTemplates or {}),
        nextId = ts.nextThreatId or 0,
        generationTimer = ts.threatGenerationTimer or 0,
        generationInterval = ts.threatGenerationInterval or 0,
        enabled = ts.enabled or false
    }
end

function StatsOverlayLuis:getUpgradeData()
    local us = self.systems.upgradeSystem
    return {
        total = #(us.allUpgrades or {}),
        purchased = self:countTable(us.purchasedUpgrades or {}),
        trees = self:countTable(us.upgradeTrees or {})
    }
end

function StatsOverlayLuis:getSkillData()
    local ss = self.systems.skillSystem
    return {
        definitions = ss.skillDefinitions and self:countTable(ss.skillDefinitions) or 0,
        unlockedCount = ss.unlockedSkills and self:countTable(ss.unlockedSkills) or 0
    }
end

function StatsOverlayLuis:getIdleData()
    local is = self.systems.idleSystem
    return {
        lastSaveTime = is.lastSaveTime or 0,
        totalEarnings = is.idleData and is.idleData.totalEarnings or 0,
        totalDamage = is.idleData and is.idleData.totalDamage or 0,
        threatTypes = self:countTable(is.threatTypes or {})
    }
end

function StatsOverlayLuis:getProgressionData()
    local ps = self.systems.progressionSystem
    if not ps then return {} end
    
    return {
        level = ps.level or 1,
        xp = ps.xp or 0,
        xpToNextLevel = ps.xpToNextLevel or 100,
        unlockedFeatures = ps.unlockedFeatures and #ps.unlockedFeatures or 0
    }
end

function StatsOverlayLuis:getAchievementData()
    local as = self.systems.achievementSystem
    return {
        total = self:countTable(as.achievements or {}),
        unlocked = self:countTable(as.unlockedAchievements or {}),
        progress = self:countTable(as.progress or {})
    }
end

function StatsOverlayLuis:getEventData()
    local es = self.systems.eventSystem
    return {
        total = #(es.events or {}),
        active = self:countTable(es.activeEvents or {}),
        timer = es.eventTimer or 0,
        baseInterval = es.baseInterval or 0,
        totalWeight = es.totalWeight or 0
    }
end

function StatsOverlayLuis:getRNGData()
    return {
        sample1 = math.random(),
        sample2 = math.random(),
        sample3 = math.random(),
        timestamp = love.timer and love.timer.getTime() or 0
    }
end

-- Input handlers (modal overlay behavior)
function StatsOverlayLuis:mousepressed(x, y, button)
    if not self.visible then return false end
    return true  -- Consume all mouse input when visible
end

function StatsOverlayLuis:mousereleased(x, y, button)
    if not self.visible then return false end
    return true
end

function StatsOverlayLuis:keypressed(key)
    if not self.visible then return false end
    
    -- ESC closes the overlay
    if key == 'escape' then
        self:hide()
        return true
    end
    
    return true  -- Consume other keys while overlay visible
end

function StatsOverlayLuis:keyreleased(key)
    if not self.visible then return false end
    return true
end

-- Helper to count table entries
function StatsOverlayLuis:countTable(tbl)
    if type(tbl) ~= "table" then return 0 end
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Helper for overlay manager (check if should capture input)
function StatsOverlayLuis:shouldCaptureInput()
    return self.visible and self.modal
end

return StatsOverlayLuis
