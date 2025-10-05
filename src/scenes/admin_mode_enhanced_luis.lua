-- Enhanced Admin Mode Scene - Manual Assignment & Performance Dashboard (LUIS Version)
-- Provides advanced incident management with manual specialist assignment
-- Part of Phase 4: Enhanced Admin Mode with Manual Assignment UI

local AdminModeEnhanced = {}
AdminModeEnhanced.__index = AdminModeEnhanced

function AdminModeEnhanced.new(eventBus, luis, systems)
    local self = setmetatable({}, AdminModeEnhanced)
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "admin_mode_enhanced"
    
    -- UI State
    self.selectedIncident = nil
    self.selectedSpecialist = nil
    self.activeIncidents = {}
    self.availableSpecialists = {}
    self.dashboardData = {}
    self.scrollOffset = 0
    self.maxScrollOffset = 0
    
    -- Cyberpunk theme
    local cyberpunkTheme = {
        textColor = {0, 1, 180/255, 1},
        bgColor = {10/255, 25/255, 20/255, 0.8},
        borderColor = {0, 1, 180/255, 0.4},
        borderWidth = 1,
        hoverTextColor = {20/255, 30/255, 25/255, 1},
        hoverBgColor = {0, 1, 180/255, 1},
        hoverBorderColor = {0, 1, 180/255, 1},
        activeTextColor = {20/255, 30/255, 25/255, 1},
        activeBgColor = {0.8, 1, 1, 1},
        activeBorderColor = {0.8, 1, 1, 1},
        Label = { textColor = {0, 1, 180/255, 0.9} },
    }
    if self.luis.setTheme then
        self.luis.setTheme(cyberpunkTheme)
    end
    
    return self
end

function AdminModeEnhanced:load(data)
    print("🔧 Enhanced Admin Mode: Entering")
    
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    self:buildUI()
    self:refreshData()
    
    -- Subscribe to real-time updates
    self.eventBus:subscribe("incident_generated", function() self:refreshData() end)
    self.eventBus:subscribe("incident_stage_completed", function() self:refreshData() end)
    self.eventBus:subscribe("specialist_assigned", function() self:refreshData() end)
    self.eventBus:subscribe("stats_updated", function() self:refreshData() end)
end

function AdminModeEnhanced:exit()
    print("🔧 Enhanced Admin Mode: Exiting")
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function AdminModeEnhanced:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    -- Calculate grid dimensions
    local numCols = math.floor(screenWidth / gridSize)
    local numRows = math.floor(screenHeight / gridSize)
    
    -- Title
    local title = luis.newLabel("🔧 ENHANCED ADMIN MODE", 40, 2, 2, math.floor(numCols/2) - 20)
    luis.insertElement(self.layerName, title)
    
    -- Performance metrics will be drawn manually in draw() for dynamic updates
    
    -- Back button
    local backBtn = luis.newButton(
        "← BACK TO SOC",
        20, 3,
        function()
            self.eventBus:publish("request_scene_change", {scene = "soc_view"})
        end,
        nil,
        numRows - 4,
        2
    )
    luis.insertElement(self.layerName, backBtn)
    
    print("🔧 AdminModeEnhanced: UI built (grid-based)")
end

function AdminModeEnhanced:refreshData()
    -- Get dashboard data from GlobalStatsSystem
    if self.systems.globalStatsSystem then
        self.dashboardData = self.systems.globalStatsSystem:getDashboardData()
    end
    
    -- Get active incidents
    if self.systems.Incident then
        self.activeIncidents = {}
        local allIncidents = self.systems.Incident:getActiveIncidents() or {}
        for _, incident in ipairs(allIncidents) do
            table.insert(self.activeIncidents, incident)
        end
    end
    
    -- Get available specialists
    if self.systems.specialistSystem then
        self.availableSpecialists = self.systems.specialistSystem:getAllSpecialists() or {}
    end
end

function AdminModeEnhanced:update(dt)
    -- Auto-refresh data periodically
    if not self.refreshTimer then
        self.refreshTimer = 0
    end
    self.refreshTimer = self.refreshTimer + dt
    if self.refreshTimer > 2.0 then
        self:refreshData()
        self.refreshTimer = 0
    end
end

function AdminModeEnhanced:draw()
    -- Draw performance dashboard
    self:drawPerformanceDashboard()
    
    -- Draw active incidents list
    self:drawIncidentsList()
    
    -- Draw specialists panel
    self:drawSpecialistsPanel()
end

function AdminModeEnhanced:drawPerformanceDashboard()
    local x = 20
    local y = 80
    local width = love.graphics.getWidth() - 40
    local height = 100
    
    -- Background panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0, 1, 180/255, 0.4)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(0.3, 0.8, 1.0, 1.0)
    love.graphics.print("📊 PERFORMANCE METRICS", x + 10, y + 10)
    
    -- Metrics
    local data = self.dashboardData
    local metricX = x + 10
    local metricY = y + 40
    local metricSpacing = 360
    
    -- Workload
    local workloadColor = data.workloadStatus == "OVERLOADED" and {1.0, 0.3, 0.3} or {0.3, 1.0, 0.5}
    love.graphics.setColor(workloadColor)
    love.graphics.print(string.format("Workload: %s (%.0f%%)", 
        data.workloadStatus or "N/A", (data.workloadPercentage or 0) * 100), metricX, metricY)
    
    -- SLA Compliance
    local slaColor = (data.slaComplianceRate or 0) >= 0.8 and {0.3, 1.0, 0.5} or {1.0, 0.8, 0.3}
    love.graphics.setColor(slaColor)
    love.graphics.print(string.format("SLA: %.1f%%", (data.slaComplianceRate or 0) * 100), 
        metricX + metricSpacing, metricY)
    
    -- Active Contracts
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.format("Contracts: %d", data.activeContracts or 0), 
        metricX + metricSpacing * 2, metricY)
    
    -- Specialists
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.format("Specialists: %d (Lvl: %.1f)", 
        data.totalSpecialists or 0, data.avgSpecialistLevel or 1), 
        metricX + metricSpacing * 3, metricY)
    
    -- Response Time
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.format("Avg Response: %.0fs", data.avgResponseTime or 0), 
        metricX, metricY + 25)
end

function AdminModeEnhanced:drawIncidentsList()
    local x = 20
    local y = 200
    local width = 900
    local height = love.graphics.getHeight() - 280
    
    -- Background panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(1.0, 0.3, 0.3, 0.6)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(1.0, 0.3, 0.3, 1.0)
    love.graphics.print("🚨 ACTIVE INCIDENTS", x + 10, y + 10)
    
    -- Incidents
    local incidentY = y + 40
    local incidentHeight = 140
    local incidentSpacing = 10
    
    if #self.activeIncidents == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No active incidents", x + 10, incidentY)
    else
        for i, incident in ipairs(self.activeIncidents) do
            if incidentY + incidentHeight < y + height then
                self:drawIncidentCard(incident, x + 10, incidentY, width - 20)
                incidentY = incidentY + incidentHeight + incidentSpacing
            end
        end
    end
end

function AdminModeEnhanced:drawIncidentCard(incident, x, y, width)
    local cardHeight = 130
    
    -- Card background
    local isSelected = self.selectedIncident and self.selectedIncident.id == incident.id
    if isSelected then
        love.graphics.setColor(0.2, 0.3, 0.4, 0.95)
    else
        love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
    end
    love.graphics.rectangle("fill", x, y, width, cardHeight)
    love.graphics.setColor(1.0, 0.6, 0.3, 0.8)
    love.graphics.rectangle("line", x, y, width, cardHeight)
    
    -- Incident info
    love.graphics.setColor(1.0, 0.6, 0.3, 1.0)
    love.graphics.print(string.format("🚨 %s [Stage: %s]", 
        incident.threatType or "Unknown", 
        incident.currentStage or "detect"), x + 10, y + 10)
    
    -- Stage progress
    local stage = incident.stages and incident.stages[incident.currentStage or "detect"]
    if stage then
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(string.format("Progress: %.0f%% | SLA: %.0fs / %.0fs", 
            (stage.progress or 0) * 100,
            stage.duration or 0,
            stage.slaLimit or 0), x + 10, y + 35)
        
        -- Assigned specialists
        local assignedText = "Assigned: "
        if stage.assignedSpecialists and #stage.assignedSpecialists > 0 then
            local names = {}
            for _, specId in ipairs(stage.assignedSpecialists) do
                local spec = self.systems.specialistSystem:getSpecialist(specId)
                if spec then
                    table.insert(names, spec.name)
                end
            end
            assignedText = assignedText .. table.concat(names, ", ")
        else
            assignedText = assignedText .. "None (Auto-assign)"
        end
        
        love.graphics.setColor(0.6, 0.8, 1.0)
        love.graphics.print(assignedText, x + 10, y + 55)
    end
    
    -- Manual assignment button (clickable area)
    love.graphics.setColor(0.3, 0.6, 0.9, 0.8)
    love.graphics.rectangle("fill", x + 10, y + 85, width - 20, 35)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("📋 MANUALLY ASSIGN SPECIALIST (Click)", x + 20, y + 95)
end

function AdminModeEnhanced:drawSpecialistsPanel()
    local x = 940
    local y = 200
    local width = love.graphics.getWidth() - 960
    local height = love.graphics.getHeight() - 280
    
    -- Background panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.3, 1.0, 0.5, 0.6)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(0.3, 1.0, 0.5, 1.0)
    love.graphics.print("👥 SPECIALISTS & WORKLOAD", x + 10, y + 10)
    
    -- Specialists
    local specY = y + 40
    local specHeight = 120
    local specSpacing = 10
    
    if not self.availableSpecialists or type(self.availableSpecialists) ~= "table" then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No specialists available", x + 10, specY)
        return
    end
    
    -- Convert specialists to array if it's a dictionary
    local specialistArray = self:buildSpecialistArray()
    
    if #specialistArray == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No specialists available", x + 10, specY)
    else
        for i, specialist in ipairs(specialistArray) do
            if specY + specHeight < y + height then
                self:drawSpecialistCard(specialist, x + 10, specY, width - 20)
                specY = specY + specHeight + specSpacing
            end
        end
    end
end

function AdminModeEnhanced:drawSpecialistCard(specialist, x, y, width)
    local cardHeight = 110
    
    -- Card background
    love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
    love.graphics.rectangle("fill", x, y, width, cardHeight)
    love.graphics.setColor(0.3, 1.0, 0.5, 0.8)
    love.graphics.rectangle("line", x, y, width, cardHeight)
    
    -- Specialist info
    love.graphics.setColor(0.3, 1.0, 0.5, 1.0)
    love.graphics.print(string.format("👤 %s (Level %d)", 
        specialist.name or "Unknown", 
        specialist.level or 1), x + 10, y + 10)
    
    -- Stats
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.format("Trace: %d | Speed: %d | Efficiency: %d", 
        specialist.trace or 0, 
        specialist.speed or 0, 
        specialist.efficiency or 0), x + 10, y + 35)
    
    -- Workload
    local workload = specialist.assignedIncidents or 0
    local workloadColor = workload == 0 and {0.3, 1.0, 0.5} or 
                          workload <= 2 and {1.0, 0.8, 0.3} or 
                          {1.0, 0.3, 0.3}
    love.graphics.setColor(workloadColor)
    love.graphics.print(string.format("Workload: %d incidents", workload), x + 10, y + 55)
    
    -- Assign button (if incident selected)
    if self.selectedIncident then
        love.graphics.setColor(0.3, 0.9, 0.6, 0.8)
        love.graphics.rectangle("fill", x + 10, y + 75, width - 20, 25)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("ASSIGN TO %s", 
            self.selectedIncident.threatType or "INCIDENT"), x + 20, y + 82)
    end
end

function AdminModeEnhanced:mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    -- Check incident selection
    local incidentX = 30
    local incidentY = 240
    local incidentWidth = 880
    local incidentHeight = 140
    local incidentSpacing = 10
    
    for i, incident in ipairs(self.activeIncidents) do
        local cardY = incidentY + (i-1) * (incidentHeight + incidentSpacing)
        if x >= incidentX and x <= incidentX + incidentWidth and
           y >= cardY and y <= cardY + incidentHeight then
            -- Check if clicked on assign button
            if y >= cardY + 85 and y <= cardY + 120 then
                self.selectedIncident = incident
                print(string.format("🎯 Selected incident: %s", incident.id))
                return true
            end
        end
    end
    
    -- Check specialist selection (for assignment)
    if self.selectedIncident then
        local specX = 950
        local specY = 240
        local specWidth = love.graphics.getWidth() - 970
        local specHeight = 120
        local specSpacing = 10
        
        -- Get specialist array
        local specialistArray = {}
        for id, spec in pairs(self.availableSpecialists) do
            if type(spec) == "table" then
                spec.id = spec.id or id
                table.insert(specialistArray, spec)
            end
        end
        
        for i, specialist in ipairs(specialistArray) do
            local cardY = specY + (i-1) * (specHeight + specSpacing)
            if x >= specX and x <= specX + specWidth and
               y >= cardY + 75 and y <= cardY + 100 then
                -- Assign specialist to incident
                self:manuallyAssignSpecialist(specialist.id, self.selectedIncident.id)
                return true
            end
        end
    end
    
    return false
end

function AdminModeEnhanced:manuallyAssignSpecialist(specialistId, incidentId)
    print(string.format("🎯 Manual Assignment: Specialist %s → Incident %s", specialistId, incidentId))
    
    -- Publish manual assignment event
    self.eventBus:publish("manual_assignment_requested", {
        specialistId = specialistId,
        incidentId = incidentId,
        timestamp = love.timer.getTime()
    })
    
    -- Clear selection and refresh
    self.selectedIncident = nil
    self:refreshData()
    
    -- Show confirmation message
    print("✅ Specialist manually assigned!")
end

function AdminModeEnhanced:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
        return true
    end
    return false
end

return AdminModeEnhanced
