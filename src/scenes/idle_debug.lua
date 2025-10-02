-- Idle Debug Scene - Debug Interface for Idle Mechanics
-- Shows real-time idle system activity for development and testing

local IdleDebugScene = {}
IdleDebugScene.__index = IdleDebugScene

-- Create new idle debug scene
function IdleDebugScene.new(eventBus)
    local self = setmetatable({}, IdleDebugScene)

    -- Dependencies
    self.systems = {} -- Injected by SceneManager on enter
    self.eventBus = eventBus

    -- Debug state
    self.startTime = love.timer.getTime()
    self.frameCount = 0
    self.lastUpdate = 0
    self.updateInterval = 0.1 -- Update display every 100ms

    -- Debug data tracking
    self.debugData = {
        resources = {},
        contracts = {},
        threats = {},
        generators = {},
        specialists = {}
    }

    -- UI layout
    self.layout = {
        margin = 20,
        panelWidth = 300,
        panelHeight = 200,
        panelSpacing = 10
    }

    return self
end

-- Scene lifecycle methods
function IdleDebugScene:enter(systems)
    self.systems = systems
    print("🔧 Idle Debug Scene: Entered - Monitoring idle systems")

    -- Initialize debug tracking
    self:initializeDebugTracking()
end

function IdleDebugScene:exit()
    print("🔧 Idle Debug Scene: Exited")
end

function IdleDebugScene:update(dt)
    self.frameCount = self.frameCount + 1

    -- Update debug data periodically
    local currentTime = love.timer.getTime()
    if currentTime - self.lastUpdate >= self.updateInterval then
        self:updateDebugData()
        self.lastUpdate = currentTime
    end
end

function IdleDebugScene:draw()
    -- Clear screen
    love.graphics.clear(0.1, 0.1, 0.15)

    -- Draw header
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("🔧 IDLE DEBUG MONITOR", 0, 10, love.graphics.getWidth(), "center")

    -- Draw runtime info
    love.graphics.setFont(love.graphics.newFont(12))
    local runtime = love.timer.getTime() - self.startTime
    love.graphics.printf(string.format("Runtime: %.1fs | FPS: %.1f | Frame: %d",
        runtime, love.timer.getFPS(), self.frameCount), 10, 40, love.graphics.getWidth() - 20, "left")

    -- Draw debug panels
    self:drawResourcePanel()
    self:drawContractPanel()
    self:drawThreatPanel()
    self:drawGeneratorPanel()
    self:drawSpecialistPanel()

    -- Draw controls
    self:drawControls()
end

function IdleDebugScene:keypressed(key)
    if key == "escape" then
        -- Return to main menu
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
    elseif key == "r" then
        -- Reset debug data
        self:initializeDebugTracking()
        print("🔧 Debug data reset")
    elseif key == "space" then
        -- Toggle pause (if implemented)
        print("🔧 Pause toggle (not implemented)")
    end
end

-- Debug data management
function IdleDebugScene:initializeDebugTracking()
    self.debugData = {
        resources = {
            money = {current = 0, rate = 0, total = 0},
            reputation = {current = 0, rate = 0, total = 0},
            xp = {current = 0, rate = 0, total = 0}
        },
        contracts = {
            active = 0,
            available = 0,
            completed = 0
        },
        threats = {
            active = 0,
            total = 0,
            lastEvent = "None"
        },
        generators = {
            total = 0,
            active = 0,
            totalRate = 0
        },
        specialists = {
            total = 0,
            available = 0,
            busy = 0
        }
    }
    self.startTime = love.timer.getTime()
    
    return self
end

function IdleDebugScene:updateDebugData()
    if not self.systems then return end

    -- Update resource data
    if self.systems.resourceManager then
        local resources = self.systems.resourceManager.resources or {}
        self.debugData.resources.money.current = resources.money or 0
        self.debugData.resources.reputation.current = resources.reputation or 0
        self.debugData.resources.xp.current = resources.xp or 0

        local rates = self.systems.resourceManager.generationRates or {}
        self.debugData.resources.money.rate = rates.money or 0
        self.debugData.resources.reputation.rate = rates.reputation or 0
        self.debugData.resources.xp.rate = rates.xp or 0
    end

    -- Update contract data
    if self.systems.contractSystem then
        self.debugData.contracts.active = self:getTableSize(self.systems.contractSystem.activeContracts or {})
        self.debugData.contracts.available = self:getTableSize(self.systems.contractSystem.availableContracts or {})
        self.debugData.contracts.completed = self.systems.contractSystem.completedContracts and #self.systems.contractSystem.completedContracts or 0
    end

    -- Update threat data
    if self.systems.threatSystem then
        self.debugData.threats.active = self:getTableSize(self.systems.threatSystem.activeThreats or {})
        self.debugData.threats.total = self.systems.threatSystem.nextThreatId and (self.systems.threatSystem.nextThreatId - 1) or 0
    end

    -- Update generator data
    if self.systems.idleGenerators then
        self.debugData.generators.total = self.systems.idleGenerators:getTotalDefinitions() or 0
        self.debugData.generators.active = self:getTableSize(self.systems.idleGenerators.ownedGenerators or {})
        -- Calculate total generation rate (simplified)
        self.debugData.generators.totalRate = 0
        if self.systems.idleGenerators.ownedGenerators then
            for _, gen in pairs(self.systems.idleGenerators.ownedGenerators) do
                self.debugData.generators.totalRate = self.debugData.generators.totalRate + (gen.productionRate or 0)
            end
        end
    end

    -- Update specialist data
    if self.systems.specialistSystem then
        local allSpecs = self.systems.specialistSystem:getAllSpecialists() or {}
        self.debugData.specialists.total = self:getTableSize(allSpecs)
        self.debugData.specialists.available = 0
        self.debugData.specialists.busy = 0

        for _, spec in pairs(allSpecs) do
            if spec.status == "available" then
                self.debugData.specialists.available = self.debugData.specialists.available + 1
            elseif spec.status == "busy" then
                self.debugData.specialists.busy = self.debugData.specialists.busy + 1
            end
        end
    end
end

-- Drawing methods
function IdleDebugScene:drawResourcePanel()
    local x, y = self.layout.margin, 70
    self:drawPanel("💰 RESOURCES", x, y, self.layout.panelWidth, self.layout.panelHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))

    local res = self.debugData.resources
    love.graphics.printf(string.format("Money: $%.0f (+$%.1f/sec)", res.money.current, res.money.rate), x + 10, y + 25, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Reputation: %.1f (+%.3f/sec)", res.reputation.current, res.reputation.rate), x + 10, y + 40, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("XP: %.0f (+%.1f/sec)", res.xp.current, res.xp.rate), x + 10, y + 55, self.layout.panelWidth - 20)
end

function IdleDebugScene:drawContractPanel()
    local x, y = self.layout.margin + self.layout.panelWidth + self.layout.panelSpacing, 70
    self:drawPanel("📋 CONTRACTS", x, y, self.layout.panelWidth, self.layout.panelHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))

    local con = self.debugData.contracts
    love.graphics.printf(string.format("Active: %d", con.active), x + 10, y + 25, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Available: %d", con.available), x + 10, y + 40, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Completed: %d", con.completed), x + 10, y + 55, self.layout.panelWidth - 20)
end

function IdleDebugScene:drawThreatPanel()
    local x, y = self.layout.margin, 70 + self.layout.panelHeight + self.layout.panelSpacing
    self:drawPanel("🚨 THREATS", x, y, self.layout.panelWidth, self.layout.panelHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))

    local thr = self.debugData.threats
    love.graphics.printf(string.format("Active: %d", thr.active), x + 10, y + 25, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Total Generated: %d", thr.total), x + 10, y + 40, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Last Event: %s", thr.lastEvent), x + 10, y + 55, self.layout.panelWidth - 20)
end

function IdleDebugScene:drawGeneratorPanel()
    local x, y = self.layout.margin + self.layout.panelWidth + self.layout.panelSpacing, 70 + self.layout.panelHeight + self.layout.panelSpacing
    self:drawPanel("⚙️ GENERATORS", x, y, self.layout.panelWidth, self.layout.panelHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))

    local gen = self.debugData.generators
    love.graphics.printf(string.format("Total Types: %d", gen.total), x + 10, y + 25, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Owned: %d", gen.active), x + 10, y + 40, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Total Rate: %.1f/sec", gen.totalRate), x + 10, y + 55, self.layout.panelWidth - 20)
end

function IdleDebugScene:drawSpecialistPanel()
    local x, y = self.layout.margin, 70 + (self.layout.panelHeight + self.layout.panelSpacing) * 2
    self:drawPanel("👥 SPECIALISTS", x, y, self.layout.panelWidth, self.layout.panelHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))

    local spec = self.debugData.specialists
    love.graphics.printf(string.format("Total: %d", spec.total), x + 10, y + 25, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Available: %d", spec.available), x + 10, y + 40, self.layout.panelWidth - 20)
    love.graphics.printf(string.format("Busy: %d", spec.busy), x + 10, y + 55, self.layout.panelWidth - 20)
end

function IdleDebugScene:drawPanel(title, x, y, width, height)
    -- Panel background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Panel border
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.rectangle("line", x, y, width, height)

    -- Panel title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf(title, x + 5, y + 5, width - 10)
end

function IdleDebugScene:drawControls()
    local y = love.graphics.getHeight() - 60
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.printf("Controls: ESC - Main Menu | R - Reset Data | SPACE - Pause (TODO)", 10, y, love.graphics.getWidth() - 20)
end

-- Utility methods
function IdleDebugScene:getTableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

return IdleDebugScene