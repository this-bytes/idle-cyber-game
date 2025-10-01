-- Admin Mode Scene - Active Incident Response
-- A focused, terminal-style interface for hands-on crisis management.

local CommandParser = require("src.utils.command_parser")
-- Lightweight UTF-8 backspace helper (avoid external utf8 dependency in tests)
local function utf8_backspace(s)
    if not s or s == "" then return "" end
    local i = #s
    -- Move backwards over continuation bytes (10xxxxxx)
    while i > 0 do
        local b = string.byte(s, i)
        if b >= 128 and b <= 191 then
            i = i - 1
        else
            break
        end
    end
    if i == 0 then return "" end
    return s:sub(1, i - 1)
end

local AdminMode = {}
AdminMode.__index = AdminMode

function AdminMode.new(eventBus)
    local self = setmetatable({}, AdminMode)
    self.eventBus = eventBus
    self.systems = {} -- Injected by SceneManager

    -- Terminal UI State
    self.logs = {}
    self.maxLogs = 300 -- cap to avoid runaway memory in long sessions
    self.availableCommands = {"help","status","specialists","clear","deploy","exit"}
    -- Use method to add initial log to ensure consistent formatting and capping
    -- (call below after object methods exist)
    self.inputBuffer = ""
    self.cursorChar = "▋"
    self.cursorBlinkTimer = 0
    self.showCursor = true
    -- Cached font (lazy-loaded)
    self._cachedFont = nil

    -- Gameplay State
    self.incident = nil
    self.commandHistory = {}
    self.historyIndex = 0

    -- Command suggestion state
    self.suggestionList = {}
    self.suggestionIndex = 0
    self.suggestionColorTimer = 0

    -- Log animation state
    self.animatedLogs = {} -- {text, severity, progress, done, glitch, glitchTimer}
    self.typewriterSpeed = 60 -- chars/sec
    self.glitchActive = false
    self.glitchTimer = 0
    self.glitchDuration = 0.25

    return self
end

-- Add a log entry with optional severity tag and enforce cap
function AdminMode:addLog(message, severity, opts)
    if not message then return end
    local entry = message
    if severity then
        entry = string.format("[%s] %s", severity:upper(), message)
    end
    -- If opts.instant, add directly (for log clear, etc)
    if opts and opts.instant then
        table.insert(self.logs, entry)
        while #self.logs > (self.maxLogs or 300) do table.remove(self.logs, 1) end
        return
    end
    -- Otherwise, animate in
    table.insert(self.animatedLogs, {
        text = entry,
        severity = severity,
        progress = 0,
        done = false,
        glitch = opts and opts.glitch or false,
        glitchTimer = 0
    })
end

function AdminMode:draw()
    -- Retro terminal aesthetic
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    love.graphics.clear()
    -- Lazy-load and cache font; fall back to default if asset missing
    if not self._cachedFont then
        local ok, f = pcall(function() return love.graphics.newFont("assets/fonts/FiraCode-Retina.ttf", 14) end)
        if ok and f then
            self._cachedFont = f
        else
            self._cachedFont = love.graphics.newFont(14)
        end
    end
    love.graphics.setFont(self._cachedFont)

    -- Draw status bar (incident name, severity, category, mood meter)
    local barY = 0
    local barH = 22
    local barW = love.graphics.getWidth()
    local barColor = {0.12, 0.18, 0.22, 0.92}
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", 0, barY, barW, barH)

    -- Incident info
    local incident = self.incident or {name="Standby", severity=0, category="-"}
    local sev = tonumber(incident.severity) or 0
    local sevColor = {0.2, 1, 0.2}
    if sev >= 7 then
        sevColor = {1, 0.2, 0.2}
    elseif sev >= 5 then
        sevColor = {1, 0.7, 0.2}
    elseif sev > 0 then
        sevColor = {0.5, 1, 0.3}
    end
    love.graphics.setColor(1,1,1)
    local label = string.format("Incident: %s", incident.name or "-")
    love.graphics.print(label, 16, barY+3)
    love.graphics.setColor(sevColor)
    love.graphics.print(string.format("Severity: %s", tostring(incident.severity or "-")), 220, barY+3)
    love.graphics.setColor(0.5,0.8,1)
    love.graphics.print(string.format("Category: %s", incident.category or "-"), 370, barY+3)

    -- Mood/Stress Meter
    local moodText, moodColor, moodIcon = "Chill", {0.2, 1, 0.6}, "😎"
    if sev >= 8 then
        moodText, moodColor, moodIcon = "PANIC!", {1, 0.1, 0.1}, "🔥"
    elseif sev >= 6 then
        moodText, moodColor, moodIcon = "Stressed", {1, 0.6, 0.2}, "😰"
    elseif sev >= 3 then
        moodText, moodColor, moodIcon = "Alert", {1, 1, 0.2}, "⚡"
    end
    love.graphics.setColor(moodColor)
    love.graphics.print(string.format("SOC Mood: %s %s", moodText, moodIcon), barW-180, barY+3)
    love.graphics.setColor(1,1,1,1)

    -- Draw logs (including animated)
    local y = barY + barH + 4
    local allLogs = {}
    for _, l in ipairs(self.logs) do table.insert(allLogs, l) end
    for _, anim in ipairs(self.animatedLogs) do
        if anim.done then table.insert(allLogs, anim.text) end
    end
    -- Only show up to maxLogs
    while #allLogs > (self.maxLogs or 300) do table.remove(allLogs, 1) end
    -- Draw static logs
    for _, line in ipairs(allLogs) do
        local color = {0.2, 1, 0.2}
        if line:find("%[ALERT%]") then color = {1, 0.4, 0.2}
        elseif line:find("%[WARNING%]") then color = {1, 0.8, 0.2}
        elseif line:find("%[SYSTEM%]") then color = {0.5, 0.9, 1}
        elseif line:find("%[ERROR%]") then color = {1, 0.2, 0.2}
        elseif line:find("%[ACTION%]") then color = {0.7, 0.9, 1}
        end
        love.graphics.setColor(color)
        love.graphics.printf(line, 20, y, love.graphics.getWidth() - 40, "left")
        y = y + 20
    end
    -- Draw animated logs (not yet done)
    for _, anim in ipairs(self.animatedLogs) do
        if not anim.done then
            local shown = math.floor(anim.progress)
            local toDraw = anim.text:sub(1, shown)
            local color = {0.2, 1, 0.2}
            if anim.text:find("%[ALERT%]") then color = {1, 0.4, 0.2}
            elseif anim.text:find("%[WARNING%]") then color = {1, 0.8, 0.2}
            elseif anim.text:find("%[SYSTEM%]") then color = {0.5, 0.9, 1}
            elseif anim.text:find("%[ERROR%]") then color = {1, 0.2, 0.2}
            elseif anim.text:find("%[ACTION%]") then color = {0.7, 0.9, 1}
            end
            -- Glitch effect: shake or color jitter
            if anim.glitch and anim.glitchTimer > 0 then
                local shake = math.random(-2,2)
                love.graphics.setColor(1, 0.2 + math.random()*0.8, 0.2 + math.random()*0.8)
                love.graphics.printf(toDraw, 20+shake, y+shake, love.graphics.getWidth() - 40, "left")
            else
                love.graphics.setColor(color)
                love.graphics.printf(toDraw, 20, y, love.graphics.getWidth() - 40, "left")
            end
            y = y + 20
        end
    end
    love.graphics.setColor(0.2, 1, 0.2)

    -- Draw input line
    local inputPrompt = "> "
    love.graphics.print(inputPrompt .. self.inputBuffer, 20, y)

    -- Draw blinking cursor
    if self.showCursor then
        local textWidth = love.graphics.getFont():getWidth(inputPrompt .. self.inputBuffer)
        love.graphics.print(self.cursorChar, 20 + textWidth, y)
    end

    -- Draw animated command suggestions below input
    if #self.suggestionList > 0 then
        local baseY = y + 22
        for i, suggestion in ipairs(self.suggestionList) do
            if i > 3 then break end -- Show up to 3 suggestions
            -- Animated color cycling
            local t = (self.suggestionColorTimer or 0) + i * 0.15
            local r = 0.5 + 0.5 * math.sin(t)
            local g = 0.8 + 0.2 * math.cos(t)
            local b = 1.0
            if i == self.suggestionIndex then
                -- Highlight selected suggestion
                love.graphics.setColor(1, 1, 0.4, 1)
            else
                love.graphics.setColor(r, g, b, 0.85)
            end
            love.graphics.print(suggestion, 36, baseY + (i-1)*18)
        end
        love.graphics.setColor(1,1,1,1)
    end
end

function AdminMode:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", { scene = "soc_view" })

    elseif key == "backspace" then
        if #self.inputBuffer > 0 then
            self:backspace()
        end

    elseif key == "return" or key == "kpenter" then
        self:handleCommand(self.inputBuffer)
        self.inputBuffer = ""

        -- Reset suggestions after command
        self.suggestionList = {}
        self.suggestionIndex = 0

    elseif key == "up" then
        if #self.commandHistory == 0 then return end
        if self.historyIndex == 0 then
            self.historyIndex = #self.commandHistory
        else
            self.historyIndex = math.max(1, self.historyIndex - 1)
        end
        self.inputBuffer = self.commandHistory[self.historyIndex]

    elseif key == "down" then
        if #self.commandHistory == 0 or self.historyIndex == 0 then
            self.inputBuffer = ""
            self.historyIndex = 0
            return
        end
        self.historyIndex = self.historyIndex + 1
        if self.historyIndex > #self.commandHistory then
            self.historyIndex = 0
            self.inputBuffer = ""
        else
            self.inputBuffer = self.commandHistory[self.historyIndex]
        end


    elseif key == "tab" or key == "right" then
        -- Cycle to next suggestion
        if #self.suggestionList > 0 then
            self.suggestionIndex = self.suggestionIndex + 1
            if self.suggestionIndex > #self.suggestionList then
                self.suggestionIndex = 1
            end
            -- Auto-complete inputBuffer with selected suggestion
            self.inputBuffer = self.suggestionList[self.suggestionIndex] .. " "
        end
        return

    elseif key == "left" then
        -- Cycle to previous suggestion
        if #self.suggestionList > 0 then
            self.suggestionIndex = self.suggestionIndex - 1
            if self.suggestionIndex < 1 then
                self.suggestionIndex = #self.suggestionList
            end
            self.inputBuffer = self.suggestionList[self.suggestionIndex] .. " "
        end
        return

    elseif key == "v" and love and love.keyboard and love.keyboard.isDown and love.keyboard.isDown("lctrl") then
        if love and love.system and love.system.getClipboard then
            local clip = love.system.getClipboard() or ""
            self.inputBuffer = self.inputBuffer .. clip
        end
        return

    elseif #key == 1 then
        self.inputBuffer = self.inputBuffer .. key
        -- Update suggestions on every keypress
        self:updateSuggestions()
        return
    end

    self.cursorBlinkTimer = 0
end

-- Update command suggestions based on inputBuffer
function AdminMode:updateSuggestions()
    local prefix = self.inputBuffer:match("^%s*(%S*)") or ""
    local matches = {}
    if #prefix > 0 then
        for _, cmd in ipairs(self.availableCommands) do
            if cmd:sub(1, #prefix) == prefix then
                table.insert(matches, cmd)
            end
        end
    end
    self.suggestionList = matches
    self.suggestionIndex = (#matches > 0) and 1 or 0
end

-- UTF-8-aware backspace helper
function AdminMode:backspace()
    if #self.inputBuffer == 0 then return end
    self.inputBuffer = utf8_backspace(self.inputBuffer)
end

function AdminMode:handleCommand(input)
    self:addLog("> " .. input, "cmd")
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
        -- Glitch animation for invalid command
        self:addLog(string.format("Unknown command: '%s'. Type 'help' for a list of commands.", self.inputBuffer), "warning", {glitch=true})
    end
end

function AdminMode:handleDeploy(args)
    if #args < 2 then
        self:addLog("Usage: deploy <specialist_name> <ability_name>", "error")
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

    self:addLog(string.format("Issuing deploy order for %s to execute %s...", specialistName, abilityName), "action")
end

function AdminMode:showHelp()
    self:addLog("Available commands:", "info")
    self:addLog("  help                   - Show this help message", "info")
    self:addLog("  status                 - Display incident status and team overview", "info")
    self:addLog("  specialists            - List available specialists and their status", "info")
    self:addLog("  deploy <spec> <ability>  - Deploy a specialist with a specific ability", "info")
    self:addLog("  clear                  - Clear the command log", "info")
    self:addLog("  exit                   - Return to the SOC view (or use ESC)", "info")
end

function AdminMode:showStatus()
    self:addLog("--- Incident Status ---", "info")
    if self.incident and self.incident.name ~= "Standby" then
        self:addLog(string.format("  Incident: %s (ID: %s)", self.incident.name, self.incident.id), "info")
        self:addLog(string.format("  Severity: %d", self.incident.severity), "info")
        self:addLog(string.format("  Category: %s", self.incident.category), "info")
        
        -- Display HP if the threat system has been updated
        if self.incident.hp and self.incident.baseHp then
            self:addLog(string.format("  Integrity: %d/%d HP", self.incident.hp, self.incident.baseHp), "info")
        end
    else
        self:addLog("  No active incident.", "info")
    end
    self:addLog("-----------------------", "info")
end

function AdminMode:showSpecialists()
    self:addLog("--- Specialist Roster ---", "info")
    local specialistSys = self.systems and self.systems.specialistSystem
    if not specialistSys or type(specialistSys.getSpecialists) ~= "function" then
        self:addLog("No specialists system available.", "warning")
        return
    end

    local specialists = specialistSys:getSpecialists()

    if not specialists or next(specialists) == nil then
        self:addLog("No specialists have been hired.", "info")
        return
    end

    for id, spec in pairs(specialists) do
        local statusLine = string.format("  %s (ID: %d) - Status: %s", spec.name, id, spec.status)
        if spec.status == "busy" then
            local now = (love and love.timer and type(love.timer.getTime) == "function") and love.timer.getTime() or os.time()
            local remaining = math.ceil(spec.busyUntil - now)
            statusLine = statusLine .. string.format(" (%ds remaining)", remaining > 0 and remaining or 0)
        end
    self:addLog(statusLine, "info")

        local abilities = "    Abilities: "
        if spec.abilities and #spec.abilities > 0 then
            abilities = abilities .. table.concat(spec.abilities, ", ")
        else
            abilities = abilities .. "None"
        end
        self:addLog(abilities, "info")
    end
end

function AdminMode:clearLogs()
    self.logs = {}
    self.animatedLogs = {}
    self:addLog("Logs cleared. Awaiting new incident data...", "system", {instant=true})
end

-- Future expansion placeholders
-- function AdminMode:updateIncidentProgress()
--     -- This will update the incident state based on player actions
-- end


-- Animate suggestion color cycling
function AdminMode:update(dt)
    self.suggestionColorTimer = (self.suggestionColorTimer or 0) + (dt or 0)
    -- Animate typewriter logs
    local finished = {}
    for i, anim in ipairs(self.animatedLogs) do
        if not anim.done then
            anim.progress = anim.progress + (self.typewriterSpeed * (dt or 0))
            if anim.progress >= #anim.text then
                anim.progress = #anim.text
                anim.done = true
                -- If glitch, start timer
                if anim.glitch then anim.glitchTimer = self.glitchDuration end
            end
        elseif anim.glitch and anim.glitchTimer > 0 then
            anim.glitchTimer = anim.glitchTimer - (dt or 0)
            if anim.glitchTimer <= 0 then anim.glitchTimer = 0 end
        end
        if anim.done and (not anim.glitch or anim.glitchTimer == 0) then
            table.insert(finished, i)
        end
    end
    -- Move finished animated logs to main logs
    for j = #finished, 1, -1 do
        local idx = finished[j]
        local anim = table.remove(self.animatedLogs, idx)
        if anim then
            table.insert(self.logs, anim.text)
            while #self.logs > (self.maxLogs or 300) do table.remove(self.logs, 1) end
        end
    end
end

return AdminMode
