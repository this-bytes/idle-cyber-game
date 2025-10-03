-- Idle Debug Scene - Debug Interface for Idle Mechanics
-- Shows real-time idle system activity for development and testing
-- Uses SmartUIManager for modern component-based UI

local SmartUIManager = require("src.ui.smart_ui_manager")
local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Box = require("src.ui.components.box")
local Grid = require("src.ui.components.grid")

local IdleDebugScene = {}
IdleDebugScene.__index = IdleDebugScene

-- Create new idle debug scene
function IdleDebugScene.new(eventBus)
    local self = setmetatable({}, IdleDebugScene)

    -- Dependencies
    self.systems = {} -- Injected by SceneManager on enter
    self.eventBus = eventBus
    self.uiManager = nil

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

    return self
end

-- Scene lifecycle methods
function IdleDebugScene:enter(params)
    -- Note: self.systems is injected by SceneManager before enter() is called
    print("🔧 Idle Debug Scene: Entered - Monitoring idle systems")

    -- Initialize Smart UI Manager
    self.uiManager = SmartUIManager.new(self.eventBus, self.systems.resourceManager)
    self.uiManager:initialize()
    self.uiManager.currentState = "game" -- Use game state for debug UI
    self:buildDebugUI()

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
        self:updateDebugUI()
        self.lastUpdate = currentTime
    end
end

function IdleDebugScene:draw()
    if self.uiManager then
        self.uiManager:draw()
    end
end

function IdleDebugScene:keypressed(key)
    -- Pass input to UI manager first
    if self.uiManager then
        self.uiManager:keypressed(key)
    end

    -- Handle scene-specific keys
    if key == "escape" then
        -- Return to main menu
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
    elseif key == "r" then
        -- Reset debug data
        self:initializeDebugTracking()
        self:updateDebugUI()
        print("🔧 Debug data reset")
    elseif key == "space" then
        -- Toggle pause (if implemented)
        print("🔧 Pause toggle (not implemented)")
    end
end

-- Handle mouse input
function IdleDebugScene:mousepressed(x, y, button)
    if self.uiManager then
        self.uiManager:mousepressed(x, y, button)
    end
end

-- Handle mouse release (critical for onClick callbacks)
function IdleDebugScene:mousereleased(x, y, button)
    if self.uiManager then
        self.uiManager:mousereleased(x, y, button)
    end
end

-- Handle mouse movement
function IdleDebugScene:mousemoved(x, y, dx, dy)
    if self.uiManager then
        self.uiManager:mousemoved(x, y, dx, dy)
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

-- Build the debug UI using SmartUIManager components
function IdleDebugScene:buildDebugUI()
    if not self.uiManager then return end

    -- Clear existing UI
    self.uiManager.root:clearChildren()

    -- Main content container
    local content = Box.new({
        direction = "vertical",
        gap = 20,
        padding = {20, 20, 20, 20}
    })
    self.uiManager.root:addChild(content)

    -- Header section
    local header = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {0, 0, 20, 0}
    })
    content:addChild(header)

    -- Title
    header:addChild(Text.new({
        text = "🛠️ IDLE DEBUG MONITOR",
        fontSize = 24,
        color = {0, 1, 1, 1}, -- Cyan
        textAlign = "center"
    }))

    -- Runtime info
    self.runtimeText = Text.new({
        text = "Runtime: 0.0s | FPS: 60 | Frame: 0",
        fontSize = 12,
        color = {0.9, 0.9, 0.95, 1.0}
    })
    header:addChild(self.runtimeText)

    -- Create 3-column grid layout for panels
    local gridContainer = Grid.new({
        columns = 3,
        columnGap = 15,
        rowGap = 15,
        columnSizes = {"flex", "flex", "flex"}, -- Equal width columns
        padding = {0, 0, 20, 0}
    })
    content:addChild(gridContainer)

    -- Column 1: Resources & Contracts
    local col1 = Box.new({
        direction = "vertical",
        gap = 15
    })
    gridContainer:addChild(col1)
    self:createResourcePanel(col1)
    self:createContractPanel(col1)

    -- Column 2: Threats & Generators
    local col2 = Box.new({
        direction = "vertical",
        gap = 15
    })
    gridContainer:addChild(col2)
    self:createThreatPanel(col2)
    self:createGeneratorPanel(col2)

    -- Column 3: Specialists & Future panels
    local col3 = Box.new({
        direction = "vertical",
        gap = 15
    })
    gridContainer:addChild(col3)
    self:createSpecialistPanel(col3)

    -- Add placeholder for future panels (Events, Incidents, etc.)
    local placeholderPanel = Panel.new({
        title = "🚧 Future Panels",
        padding = {10, 10, 10, 10},
        backgroundColor = {0.2, 0.2, 0.25, 0.8},
        borderColor = {0.4, 0.4, 0.5, 1.0}
    })
    col3:addChild(placeholderPanel)
    placeholderPanel:addChild(Text.new({
        text = "Events, Incidents,\nSave/Load, Performance\nmonitoring coming soon...",
        fontSize = 10,
        color = {0.7, 0.7, 0.8, 1.0}
    }))

    -- Controls info at bottom
    content:addChild(Text.new({
        text = "Controls: ESC - Main Menu | R - Reset Data | SPACE - Pause (TODO)",
        fontSize = 10,
        color = {0.6, 0.6, 0.6, 1.0}
    }))
end

-- Update the debug UI with current data
function IdleDebugScene:updateDebugUI()
    if not self.uiManager or not self.runtimeText then return end

    -- Update runtime info
    local runtime = love.timer.getTime() - self.startTime
    self.runtimeText:setText(string.format("Runtime: %.1fs | FPS: %.1f | Frame: %d",
        runtime, love.timer.getFPS(), self.frameCount))

    -- Update panel contents
    self:updateResourcePanel()
    self:updateContractPanel()
    self:updateThreatPanel()
    self:updateGeneratorPanel()
    self:updateSpecialistPanel()
end

-- Create resource panel
function IdleDebugScene:createResourcePanel(container)
    self.resourcePanel = Panel.new({
        title = "� RESOURCES",
        width = 300,
        height = 120
    })
    container:addChild(self.resourcePanel)

    self.resourceText = Text.new({
        text = "Loading...",
        fontSize = 10,
        color = {1, 1, 1, 1}
    })
    self.resourcePanel:addChild(self.resourceText)
end

-- Create contract panel
function IdleDebugScene:createContractPanel(container)
    self.contractPanel = Panel.new({
        title = "📋 CONTRACTS",
        width = 300,
        height = 120
    })
    container:addChild(self.contractPanel)

    self.contractText = Text.new({
        text = "Loading...",
        fontSize = 10,
        color = {1, 1, 1, 1}
    })
    self.contractPanel:addChild(self.contractText)
end

-- Create threat panel
function IdleDebugScene:createThreatPanel(container)
    self.threatPanel = Panel.new({
        title = "🚨 THREATS",
        width = 300,
        height = 120
    })
    container:addChild(self.threatPanel)

    self.threatText = Text.new({
        text = "Loading...",
        fontSize = 10,
        color = {1, 1, 1, 1}
    })
    self.threatPanel:addChild(self.threatText)
end

-- Create generator panel
function IdleDebugScene:createGeneratorPanel(container)
    self.generatorPanel = Panel.new({
        title = "⚙️ GENERATORS",
        width = 300,
        height = 120
    })
    container:addChild(self.generatorPanel)

    self.generatorText = Text.new({
        text = "Loading...",
        fontSize = 10,
        color = {1, 1, 1, 1}
    })
    self.generatorPanel:addChild(self.generatorText)
end

-- Create specialist panel
function IdleDebugScene:createSpecialistPanel(container)
    self.specialistPanel = Panel.new({
        title = "👥 SPECIALISTS",
        width = 300,
        height = 120
    })
    container:addChild(self.specialistPanel)

    self.specialistText = Text.new({
        text = "Loading...",
        fontSize = 10,
        color = {1, 1, 1, 1}
    })
    self.specialistPanel:addChild(self.specialistText)
end

-- Update panel contents
function IdleDebugScene:updateResourcePanel()
    if not self.resourceText then return end
    local res = self.debugData.resources
    self.resourceText:setText(string.format(
        "Money: $%.0f (+$%.1f/sec)\nReputation: %.1f (+%.3f/sec)\nXP: %.0f (+%.1f/sec)",
        res.money.current, res.money.rate,
        res.reputation.current, res.reputation.rate,
        res.xp.current, res.xp.rate
    ))
end

function IdleDebugScene:updateContractPanel()
    if not self.contractText then return end
    local con = self.debugData.contracts
    self.contractText:setText(string.format(
        "Active: %d\nAvailable: %d\nCompleted: %d",
        con.active, con.available, con.completed
    ))
end

function IdleDebugScene:updateThreatPanel()
    if not self.threatText then return end
    local thr = self.debugData.threats
    self.threatText:setText(string.format(
        "Active: %d\nTotal Generated: %d\nLast Event: %s",
        thr.active, thr.total, thr.lastEvent
    ))
end

function IdleDebugScene:updateGeneratorPanel()
    if not self.generatorText then return end
    local gen = self.debugData.generators
    self.generatorText:setText(string.format(
        "Total Types: %d\nOwned: %d\nTotal Rate: %.1f/sec",
        gen.total, gen.active, gen.totalRate
    ))
end

function IdleDebugScene:updateSpecialistPanel()
    if not self.specialistText then return end
    local spec = self.debugData.specialists
    self.specialistText:setText(string.format(
        "Total: %d\nAvailable: %d\nBusy: %d",
        spec.total, spec.available, spec.busy
    ))
end

-- Drawing methods (legacy - replaced by SmartUIManager)
function IdleDebugScene:drawResourcePanel()
    -- Legacy method - no longer used
end

function IdleDebugScene:drawContractPanel()
    -- Legacy method - no longer used
end

function IdleDebugScene:drawThreatPanel()
    -- Legacy method - no longer used
end

function IdleDebugScene:drawGeneratorPanel()
    -- Legacy method - no longer used
end

function IdleDebugScene:drawSpecialistPanel()
    -- Legacy method - no longer used
end

function IdleDebugScene:drawPanel(title, x, y, width, height)
    -- Legacy method - no longer used
end

function IdleDebugScene:drawControls()
    -- Legacy method - no longer used
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