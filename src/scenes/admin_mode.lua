-- Admin Mode Scene - Active Incident Response
-- A focused, terminal-style interface for hands-on crisis management.

local CommandParser = require("src.utils.command_parser")

local AdminMode = {}
AdminMode.__index = AdminMode

function AdminMode.new(eventBus)
    local self = setmetatable({}, AdminMode)
    self.eventBus = eventBus
    self.systems = {} -- Injected by SceneManager

    -- Terminal UI State
    self.logs = {"[SYSTEM] Secure channel established. Awaiting incident data..."}
    self.inputBuffer = ""
    self.cursorChar = "▋"
    self.cursorBlinkTimer = 0
    self.showCursor = true

    -- Gameplay State
    self.incident = nil
    self.commandHistory = {}
    self.historyIndex = 0

    return self
end

function AdminMode:enter(data)
    print("🚨 Admin Mode Activated: Engaging active incident response.")
    self.logs = {"[SYSTEM] Secure channel established. Awaiting incident data..."} -- Reset logs
    self.incident = data and data.incident or nil

    if self.incident then
        table.insert(self.logs, string.format("[ALERT] Threat Level %s incident detected: %s", self.incident.severity, self.incident.name))
        table.insert(self.logs, self.incident.description)
        table.insert(self.logs, "Awaiting your command...")
    else
        table.insert(self.logs, "[WARNING] No incident data received. Operating in standby mode.")
        self.incident = { id = "STANDBY", name = "Standby", description = "No active incident."} -- Create a dummy incident
    end

    -- Listen for logs from other systems
    self.eventBus:subscribe("admin_log", function(logData)
        if logData and logData.message then
            table.insert(self.logs, logData.message)
        end
    end, self) -- Use self as key to allow unsubscribing
end

function AdminMode:exit()
    print("🚨 Admin Mode Deactivated.")
    self.eventBus:unsubscribe("admin_log", self) -- Clean up listener
end

function AdminMode:update(dt)
    -- Handle cursor blinking
    self.cursorBlinkTimer = self.cursorBlinkTimer + dt
    if self.cursorBlinkTimer > 0.5 then
        self.showCursor = not self.showCursor
        self.cursorBlinkTimer = 0
    end
end

function AdminMode:draw()
    -- Retro terminal aesthetic
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    love.graphics.clear()
    love.graphics.setColor(0.2, 1, 0.2) -- Green text
    love.graphics.setFont(love.graphics.newFont("assets/fonts/FiraCode-Retina.ttf", 14))

    local y = 20
    -- Draw logs
    for _, line in ipairs(self.logs) do
        love.graphics.printf(line, 20, y, love.graphics.getWidth() - 40, "left")
        y = y + 20
    end

    -- Draw input line
    local inputPrompt = "> "
    love.graphics.print(inputPrompt .. self.inputBuffer, 20, y)

    -- Draw blinking cursor
    if self.showCursor then
        local textWidth = love.graphics.getFont():getWidth(inputPrompt .. self.inputBuffer)
        love.graphics.print(self.cursorChar, 20 + textWidth, y)
    end
end

function AdminMode:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", { scene = "soc_view" })
    elseif key == "backspace" then
        self.inputBuffer = self.inputBuffer:sub(1, -2)
    elseif key == "return" or key == "kpenter" then
        self:handleCommand(self.inputBuffer)
        self.inputBuffer = ""
    elseif key == "up" then
        if self.historyIndex > 0 then
            self.inputBuffer = self.commandHistory[self.historyIndex]
            self.historyIndex = self.historyIndex - 1
        end
    elseif key == "down" then
        if self.historyIndex < #self.commandHistory then
            self.historyIndex = self.historyIndex + 1
            self.inputBuffer = self.commandHistory[self.historyIndex]
        else
            self.inputBuffer = ""
        end
    elseif #key == 1 then
        self.inputBuffer = self.inputBuffer .. key
    end
end

function AdminMode:handleCommand(input)
    table.insert(self.logs, "> " .. input)
    table.insert(self.commandHistory, input)
    self.historyIndex = #self.commandHistory

    local parsed = CommandParser.parse(input)
    if not parsed then return end

    local command = parsed.command
    local args = parsed.args

    if command == "help" then
        self:showHelp()
    elseif command == "status" then
        self:showStatus()
    elseif command == "specialists" then
        self:showSpecialists()
    elseif command == "clear" then
        self:clearLogs()
    elseif command == "deploy" then
        self:handleDeploy(args)
    else
        table.insert(self.logs, string.format("Unknown command: '%s'. Type 'help' for a list of commands.", self.inputBuffer))
    end
end

function AdminMode:handleDeploy(args)
    if #args < 2 then
        table.insert(self.logs, "[ERROR] Usage: deploy <specialist_name> <ability_name>")
        return
    end

    local specialistName = args[1]
    local abilityName = args[2]

    -- Publish an event for the SpecialistSystem to handle.
    -- This decouples the UI from the game logic.
    self.eventBus:publish("admin_command_deploy_specialist", {
        specialistName = specialistName,
        abilityName = abilityName,
        incidentId = self.incident.id -- Pass incident context
    })

    table.insert(self.logs, string.format("[ACTION] Issuing deploy order for %s to execute %s...", specialistName, abilityName))
end

function AdminMode:showHelp()
    table.insert(self.logs, "Available commands:")
    table.insert(self.logs, "  help                   - Show this help message")
    table.insert(self.logs, "  status                 - Display incident status and team overview")
    table.insert(self.logs, "  specialists            - List available specialists and their status")
    table.insert(self.logs, "  deploy <spec> <ability>  - Deploy a specialist with a specific ability")
    table.insert(self.logs, "  clear                  - Clear the command log")
    table.insert(self.logs, "  exit                   - Return to the SOC view (or use ESC)")
end

function AdminMode:showStatus()
    table.insert(self.logs, "--- Incident Status ---")
    if self.incident and self.incident.name ~= "Standby" then
        table.insert(self.logs, string.format("  Incident: %s (ID: %s)", self.incident.name, self.incident.id))
        table.insert(self.logs, string.format("  Severity: %d", self.incident.severity))
        table.insert(self.logs, string.format("  Category: %s", self.incident.category))
        
        -- Display HP if the threat system has been updated
        if self.incident.hp and self.incident.baseHp then
            table.insert(self.logs, string.format("  Integrity: %d/%d HP", self.incident.hp, self.incident.baseHp))
        end
    else
        table.insert(self.logs, "  No active incident.")
    end
    table.insert(self.logs, "-----------------------")
end

function AdminMode:showSpecialists()
    table.insert(self.logs, "--- Specialist Roster ---")
    local specialists = self.systems.specialistSystem:getSpecialists()
    
    if not specialists or next(specialists) == nil then
        table.insert(self.logs, "No specialists have been hired.")
        return
    end

    for id, spec in pairs(specialists) do
        local statusLine = string.format("  %s (ID: %d) - Status: %s", spec.name, id, spec.status)
        if spec.status == "busy" then
            local remaining = math.ceil(spec.busyUntil - love.timer.getTime())
            statusLine = statusLine .. string.format(" (%ds remaining)", remaining > 0 and remaining or 0)
        end
        table.insert(self.logs, statusLine)

        local abilities = "    Abilities: "
        if spec.abilities and #spec.abilities > 0 then
            abilities = abilities .. table.concat(spec.abilities, ", ")
        else
            abilities = abilities .. "None"
        end
        table.insert(self.logs, abilities)
    end
end

function AdminMode:clearLogs()
    self.logs = {}
    table.insert(self.logs, "[SYSTEM] Logs cleared. Awaiting new incident data...")
end

-- Future expansion placeholders
-- function AdminMode:updateIncidentProgress()
--     -- This will update the incident state based on player actions
-- end

return AdminMode
