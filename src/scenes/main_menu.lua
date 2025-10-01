
local MainMenu = {}
MainMenu.__index = MainMenu

-- Quick Tips Carousel (modular, animated, accessible)
MainMenu.quickTips = {
    {text="Assign specialists to contracts for passive income.", type="onboarding", color={0.2,0.8,1,1}},
    {text="Upgrade your HQ to unlock more contract slots.", type="onboarding", color={0.4,1,0.4,1}},
    {text="Crisis Mode rewards rare Mission Tokens.", type="advanced", color={1,0.8,0.2,1}},
    {text="Idle, but never asleep. The cyber world never stops.", type="flavor", color={0.7,0.9,1,1}},
    {text="Bulk buy upgrades for efficiency.", type="advanced", color={1,0.8,0.2,1}},
    {text="Each contract has a unique risk/reward profile.", type="onboarding", color={0.2,0.8,1,1}},
    {text="Try different specialist combos for synergy bonuses!", type="advanced", color={0.4,1,0.4,1}},
    {text="SOC Mood reflects your team's stress and triumphs.", type="flavor", color={0.7,0.9,1,1}}
}

function MainMenu:initTipsState()
    self.tipIndex = 1
    self.tipTimer = 0
    self.tipDuration = 5.0
    self.tipAlpha = 1
    self.tipFadeDir = 1
    self.tipTransitioning = false
    self.tipTransitionTime = 0.4
    self.tipTransitionTimer = 0
    self.tipManual = false
end

function MainMenu:updateTips(dt)
    if not self.tipIndex then self:initTipsState() end
    self.tipTimer = self.tipTimer + dt
    if not self.tipManual and self.tipTimer > self.tipDuration then
        self.tipTimer = 0
        self.tipTransitioning = true
        self.tipFadeDir = -1
        self.tipTransitionTimer = 0
    end
    if self.tipTransitioning then
        self.tipTransitionTimer = self.tipTransitionTimer + dt
        if self.tipFadeDir == -1 then
            self.tipAlpha = math.max(0, 1 - self.tipTransitionTimer / self.tipTransitionTime)
            if self.tipAlpha <= 0 then
                self.tipIndex = (self.tipIndex % #MainMenu.quickTips) + 1
                self.tipFadeDir = 1
                self.tipTransitionTimer = 0
            end
        elseif self.tipFadeDir == 1 then
            self.tipAlpha = math.min(1, self.tipTransitionTimer / self.tipTransitionTime)
            if self.tipAlpha >= 1 then
                self.tipTransitioning = false
                self.tipManual = false
            end
        end
    else
        self.tipAlpha = 1
    end
end

function MainMenu:drawTipsCarousel()
    if not self.tipIndex then self:initTipsState() end
    local tip = MainMenu.quickTips[self.tipIndex]
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local barW, barH = 520, 44
    local x, y = (w-barW)/2, h-68
    local alpha = self.tipAlpha * 0.97
    local scale = self.accessibility.fontScale
    local color = tip.color or {0.7,0.9,1,1}
    love.graphics.setColor(color[1], color[2], color[3], 0.85*alpha)
    love.graphics.rectangle('fill', x, y, barW, barH, 12)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.printf(tip.text, x+48, y+10, barW-96, 'left', 0, scale, scale)
    -- Navigation arrows
    love.graphics.setColor(0.2,0.8,1,0.7*alpha)
    love.graphics.polygon('fill', x+12, y+barH/2, x+32, y+barH/2-12, x+32, y+barH/2+12)
    love.graphics.polygon('fill', x+barW-12, y+barH/2, x+barW-32, y+barH/2-12, x+barW-32, y+barH/2+12)
    love.graphics.setColor(1,1,1,1)
end
-- SOC Mood Indicator (modular, animated, accessible)
local socMoods = {
    {name="Chill", icon="😎", color={0.2,0.8,1,1}, blurb="All systems nominal."},
    {name="Alert", icon="⚠️", color={1,0.8,0.2,1}, blurb="Suspicious activity detected."},
    {name="Stressed", icon="😰", color={1,0.3,0.3,1}, blurb="Multiple threats active!"},
    {name="Triumphant", icon="🏆", color={0.4,1,0.4,1}, blurb="SOC at peak performance!"}
}

function MainMenu:initMoodState()
    self.socMoodIndex = 1
    self.socMoodTimer = 0
    self.socMoodDuration = 5.5
    self.socMoodAlpha = 1
    self.socMoodScale = 1
    self.socMoodBobbing = 0
    self.socMoodTransitioning = false
    self.socMoodTransitionTime = 0.5
    self.socMoodTransitionTimer = 0
end

function MainMenu:updateMood(dt)
    if not self.socMoodIndex then self:initMoodState() end
    self.socMoodTimer = self.socMoodTimer + dt
    if not self.socMoodTransitioning and self.socMoodTimer > self.socMoodDuration then
        self.socMoodTransitioning = true
        self.socMoodTransitionTimer = 0
    end
    if self.socMoodTransitioning then
        self.socMoodTransitionTimer = self.socMoodTransitionTimer + dt
        self.socMoodAlpha = math.max(0, 1 - self.socMoodTransitionTimer / self.socMoodTransitionTime)
        self.socMoodScale = 1 - 0.1 * (self.socMoodTransitionTimer / self.socMoodTransitionTime)
        if self.socMoodAlpha <= 0 then
            self.socMoodIndex = (self.socMoodIndex % #socMoods) + 1
            self.socMoodAlpha = 0
            self.socMoodTransitioning = false
            self.socMoodTimer = 0
        end
    else
        self.socMoodAlpha = math.min(1, self.socMoodAlpha + dt * 2)
        self.socMoodScale = 1 + 0.05 * math.sin(love.timer.getTime() * 2)
    end
    self.socMoodBobbing = self.accessibility.reducedMotion and 0 or math.sin(love.timer.getTime() * 2.2) * 6
end

function MainMenu:drawMoodIndicator()
    if not self.socMoodIndex then self:initMoodState() end
    local mood = socMoods[self.socMoodIndex]
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local x, y = w-180, 32 + self.socMoodBobbing
    local scale = self.socMoodScale * self.accessibility.fontScale
    local alpha = self.socMoodAlpha
    love.graphics.setColor(mood.color[1], mood.color[2], mood.color[3], 0.85*alpha)
    love.graphics.rectangle('fill', x, y, 148, 56, 14)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.printf(mood.icon, x+8, y+8, 32, 'center', 0, scale, scale)
    love.graphics.setColor(mood.color[1], mood.color[2], mood.color[3], 0.7*alpha)
    love.graphics.printf(mood.name, x+44, y+8, 96, 'left', 0, scale, scale)
    love.graphics.setColor(0.9,0.9,1,0.7*alpha)
    love.graphics.printf(mood.blurb, x+44, y+28, 96, 'left', 0, scale, scale)
    love.graphics.setColor(1,1,1,1)
end
-- Main Menu Scene - SOC Game Entry Point
-- Provides initial navigation for the SOC cybersecurity simulation
-- Clean, professional interface matching SOC environment theme


local json = require("dkjson")
local MainMenu = {}
MainMenu.__index = MainMenu

-- Create new main menu scene

function MainMenu.new(eventBus)
    local self = setmetatable({}, MainMenu)
    -- Scene state
    self.eventBus = eventBus
    self.menuItems = {
        {text = "Start SOC Operations", action = "start_game"},
        {text = "Load Previous SOC", action = "load_game"},
        {text = "SOC Settings", action = "settings"},
        {text = "Quit", action = "quit"}
    }
    self.selectedItem = 1
    -- Visual elements
    self.titleText = "🛡️ SOC Command Center"
    self.subtitleText = "Cybersecurity Operations Management"

    -- Contract/Faction Preview Data
    local function load_json(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        local obj, _, err = json.decode(content)
        if err then return nil end
        return obj
    end
    self.contracts = load_json("src/data/contracts.json") or {}
    local locs = load_json("src/data/locations.json")
    self.factions = {}
    if locs and locs.buildings then
        for _, b in pairs(locs.buildings) do
            table.insert(self.factions, b)
        end
    end
    -- Preview state
    self.previewIndex = 1
    self.previewType = "contract" -- alternate contract/faction
    self.previewTimer = 0
    self.previewDuration = 4.5
    self.previewAlpha = 1
    self.previewFadeDir = 1
    self.previewManual = false
    self.previewTransitioning = false
    self.previewTransitionTime = 0.4
    self.previewTransitionTimer = 0
    -- Accessibility (shared)
    self.accessibility = {
        highContrast = false,
        reducedMotion = false,
        fontScale = 1.0
    }
    print("🏠 MainMenu: Initialized SOC main menu")
    return self
end

-- Enter the main menu scene
function MainMenu:enter(data)
    print("🏠 MainMenu: Entered main menu")
end

-- Exit the main menu scene
function MainMenu:exit()
    print("🏠 MainMenu: Exited main menu")
end

-- Update main menu

function MainMenu:update(dt)
    -- Menu animations or state updates can go here
    -- Contract/Faction Preview cycling
    self.previewTimer = self.previewTimer + dt
    if not self.previewManual and self.previewTimer > self.previewDuration then
        self.previewTimer = 0
        self.previewTransitioning = true
        self.previewFadeDir = -1
        self.previewTransitionTimer = 0
    end
    if self.previewTransitioning then
        self.previewTransitionTimer = self.previewTransitionTimer + dt
        if self.previewFadeDir == -1 then
            self.previewAlpha = math.max(0, 1 - self.previewTransitionTimer / self.previewTransitionTime)
            if self.previewAlpha <= 0 then
                -- Switch preview
                if self.previewType == "contract" then
                    self.previewType = "faction"
                    self.previewIndex = (self.previewIndex % #self.factions) + 1
                else
                    self.previewType = "contract"
                    self.previewIndex = (self.previewIndex % #self.contracts) + 1
                end
                self.previewFadeDir = 1
                self.previewTransitionTimer = 0
            end
        elseif self.previewFadeDir == 1 then
            self.previewAlpha = math.min(1, self.previewTransitionTimer / self.previewTransitionTime)
            if self.previewAlpha >= 1 then
                self.previewTransitioning = false
                self.previewManual = false
            end
        end
    else
        self.previewAlpha = 1
    end
    -- SOC Mood update
    self:updateMood(dt)
    -- Quick Tips update
    self:updateTips(dt)
end

-- Draw main menu
function MainMenu:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.05, 0.1, 0.15, 1) -- Dark blue SOC theme
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Title (nil-safe)
    love.graphics.setColor(0.2, 0.8, 1, 1) -- Bright cyan
    local titleFont = love.graphics.getFont()
    local titleText = tostring(self.titleText or "")
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, (screenWidth - titleWidth) / 2, screenHeight * 0.2)
    
    -- Subtitle (nil-safe)
    love.graphics.setColor(0.7, 0.9, 1, 1) -- Light cyan
    local subtitleText = tostring(self.subtitleText or "")
    local subtitleWidth = titleFont:getWidth(subtitleText)
    love.graphics.print(subtitleText, (screenWidth - subtitleWidth) / 2, screenHeight * 0.25)
    
    -- Menu items
    local startY = screenHeight * 0.4
    local itemHeight = 40
    
    local menuItems = self.menuItems or {}
    
    for i, item in ipairs(menuItems) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == self.selectedItem)
        
        -- Highlight selected item
        if isSelected then
            love.graphics.setColor(0.1, 0.3, 0.5, 0.8)
            love.graphics.rectangle("fill", screenWidth * 0.3, y - 5, screenWidth * 0.4, itemHeight - 10)
        end
        
    -- Menu item text (nil-safe)
    local textColor = isSelected and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 1}
    love.graphics.setColor(textColor)
        
    local itemText = tostring(item.text or "")
    local itemWidth = titleFont:getWidth(itemText)
    love.graphics.print(itemText, (screenWidth - itemWidth) / 2, y)
    end
    
    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    local instructionText = "Use ↑↓ to navigate, ENTER to select, ESC to quit"
    local instrWidth = titleFont:getWidth(instructionText)
    love.graphics.print(instructionText, (screenWidth - instrWidth) / 2, screenHeight * 0.8)
    

    -- Contract/Faction Preview Panel
    local function drawPreviewPanel()
        local panelW, panelH = 420, 140
        local x = (screenWidth - panelW) / 2
        local y = screenHeight * 0.62
        local alpha = self.previewAlpha * 0.97
        love.graphics.setColor(0.08, 0.18, 0.22, 0.92 * alpha)
        love.graphics.rectangle("fill", x, y, panelW, panelH, 16)
        love.graphics.setColor(0.2, 0.8, 1, 0.7 * alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, panelW, panelH, 16)
        love.graphics.setLineWidth(1)
        local font = love.graphics.getFont()
        local scale = self.accessibility.fontScale
        if self.previewType == "contract" and #self.contracts > 0 then
            local c = self.contracts[self.previewIndex]
            if c then
                love.graphics.setColor(0.9, 1, 0.9, 0.95 * alpha)
                love.graphics.printf("Contract Preview", x, y+8, panelW, "center", 0, scale, scale)
                love.graphics.setColor(1,1,1,alpha)
                love.graphics.printf(c.displayName or c.clientName or "(Unknown)", x+16, y+36, panelW-32, "left", 0, scale, scale)
                love.graphics.setColor(0.7,0.9,1,alpha)
                love.graphics.printf(c.description or "", x+16, y+60, panelW-32, "left", 0, scale, scale)
                -- Risk/Reward
                local risk = c.riskLevel or "?"
                local rep = c.reputationReward or 0
                local budget = c.baseBudget or 0
                love.graphics.setColor(0.9,0.7,0.2,alpha)
                love.graphics.print("Risk: "..risk, x+16, y+100, 0, scale, scale)
                love.graphics.setColor(0.2,0.9,0.4,alpha)
                love.graphics.print("Reward: $"..budget.." | REP: "..rep, x+120, y+100, 0, scale, scale)
            end
        elseif self.previewType == "faction" and #self.factions > 0 then
            local f = self.factions[self.previewIndex]
            if f then
                love.graphics.setColor(0.9, 1, 0.9, 0.95 * alpha)
                love.graphics.printf("Faction Preview", x, y+8, panelW, "center", 0, scale, scale)
                love.graphics.setColor(1,1,1,alpha)
                love.graphics.printf(f.name or f.id or "(Unknown)", x+16, y+36, panelW-32, "left", 0, scale, scale)
                love.graphics.setColor(0.7,0.9,1,alpha)
                love.graphics.printf(f.description or "", x+16, y+60, panelW-32, "left", 0, scale, scale)
                -- Tier/Contracts
                local tier = f.tier or "?"
                local maxC = f.maxContracts or "?"
                love.graphics.setColor(0.8,0.7,0.9,alpha)
                love.graphics.print("Tier: "..tier, x+16, y+100, 0, scale, scale)
                love.graphics.setColor(0.2,0.8,1,alpha)
                love.graphics.print("Max Contracts: "..maxC, x+120, y+100, 0, scale, scale)
            end
        end
        -- Navigation arrows (manual)
        local arrowY = y + panelH/2 - 16
        love.graphics.setColor(0.2,0.8,1,0.7*alpha)
        love.graphics.polygon("fill", x+8, arrowY+16, x+28, arrowY, x+28, arrowY+32)
        love.graphics.polygon("fill", x+panelW-8, arrowY+16, x+panelW-28, arrowY, x+panelW-28, arrowY+32)
        love.graphics.setColor(1,1,1,1)
    end


    drawPreviewPanel()
    -- SOC Mood Indicator
    self:drawMoodIndicator()
    -- Quick Tips Carousel
    self:drawTipsCarousel()

    -- SOC status indicator (moved up)
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.print("SOC Status: READY", 20, screenHeight - 40)
-- Manual navigation for preview panel
function MainMenu:mousepressed(x, y, button)
    if button == 1 then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local panelW, panelH = 420, 140
        local px = (screenWidth - panelW) / 2
        local py = screenHeight * 0.62
        local arrowY = py + panelH/2 - 16
        -- Left arrow
        if x >= px+8 and x <= px+28 and y >= arrowY and y <= arrowY+32 then
            self.previewManual = true
            self.previewTransitioning = true
            self.previewFadeDir = -1
            self.previewTransitionTimer = 0
            self.previewType = (self.previewType == "contract") and "faction" or "contract"
            self.previewIndex = 1
            return
        end
        -- Right arrow
        if x >= px+panelW-28 and x <= px+panelW-8 and y >= arrowY and y <= arrowY+32 then
            self.previewManual = true
            self.previewTransitioning = true
            self.previewFadeDir = -1
            self.previewTransitionTimer = 0
            if self.previewType == "contract" then
                self.previewIndex = (self.previewIndex % #self.contracts) + 1
            else
                self.previewIndex = (self.previewIndex % #self.factions) + 1
            end
            return
        end
        return
    end
    -- Quick Tips navigation
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local barW, barH = 520, 44
    local tx, ty = (w-barW)/2, h-68
    -- Left arrow
    if x >= tx+12 and x <= tx+32 and y >= ty+barH/2-12 and y <= ty+barH/2+12 then
        self.tipManual = true
        self.tipTransitioning = true
        self.tipFadeDir = -1
        self.tipTransitionTimer = 0
        self.tipIndex = (self.tipIndex-2) % #quickTips + 1
        return
    end
    -- Right arrow
    if x >= tx+barW-32 and x <= tx+barW-12 and y >= ty+barH/2-12 and y <= ty+barH/2+12 then
        self.tipManual = true
        self.tipTransitioning = true
        self.tipFadeDir = -1
        self.tipTransitionTimer = 0
        self.tipIndex = (self.tipIndex % #quickTips) + 1
        return
    end
    -- Existing menu item click logic
    if button == 1 then -- Left click
        local screenHeight = love.graphics.getHeight()
        local startY = screenHeight * 0.4
        local itemHeight = 40
        local menuItems = self.menuItems or {}
        for i, item in ipairs(menuItems) do
            local itemY = startY + (i - 1) * itemHeight
            if y >= itemY and y <= itemY + itemHeight then
                self.selectedItem = i
                self:activateMenuItem()
                break
            end
        end
    end
end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
        -- Juicy Main Menu Enhancements
        neonPulseTimer = neonPulseTimer + dt
        applyStartEffects(dt)
        drawDynamicBackground(dt)
    
        -- Data-driven flavor text (from narrative instructions)
        local flavorSnippets = {
            "Welcome to your garage SOC. Time to make a name for yourself.",
            "Clients are quirky. Factions are quirkier. Stay sharp.",
            "Every contract is a story. Every breach, a lesson.",
            "Upgrade your HQ. Train your team. Outsmart the threats.",
            "Can you build the world's top SOC? Let's find out.",
            "Idle, but never asleep. The cyber world never stops."
        }
        local flavorTimer, flavorIndex, flavorAlpha, flavorFadeDir = 0, 1, 1, -1
        local flavorDuration, flavorFadeSpeed = 4.5, 0.6
    
        -- Modular notification/event panel (recent achievements, upgrades, events)
        local notifications = {}
        local notificationTimer, notificationDuration = 0, 3.5
    
        -- Accessibility state
        local accessibility = {
            highContrast = false,
            reducedMotion = false,
            fontScale = 1.0
        }
    
        -- Accessibility toggle button
        local function drawAccessibilityToggle(x, y, w, h)
            love.graphics.setColor(0.2, 0.8, 1, 0.7)
            love.graphics.rectangle('fill', x, y, w, h, 6)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("Accessibility", x, y + h/2 - 8, w, 'center')
        end
    
        local function handleAccessibilityToggle(mx, my, x, y, w, h)
            if mx >= x and mx <= x+w and my >= y and my <= y+h then
                accessibility.highContrast = not accessibility.highContrast
                accessibility.reducedMotion = not accessibility.reducedMotion
                accessibility.fontScale = accessibility.fontScale == 1.0 and 1.25 or 1.0
                return true
            end
            return false
        end
    
        -- Draw animated flavor text
        local function drawFlavorText(dt, screenWidth, screenHeight)
            flavorTimer = flavorTimer + dt
            if flavorTimer > flavorDuration then
                flavorTimer = 0
                flavorIndex = flavorIndex % #flavorSnippets + 1
                flavorAlpha = 0
                flavorFadeDir = 1
            end
            -- Fade in/out
            if flavorFadeDir == 1 then
                flavorAlpha = math.min(1, flavorAlpha + dt * flavorFadeSpeed)
                if flavorAlpha >= 1 then flavorFadeDir = -1 end
            else
                if flavorTimer > flavorDuration - 1.2 then
                    flavorAlpha = math.max(0, flavorAlpha - dt * flavorFadeSpeed)
                end
            end
            local text = flavorSnippets[flavorIndex]
            love.graphics.setColor(0.7, 1, 0.9, 0.7 * flavorAlpha)
            local font = love.graphics.getFont()
            local scale = accessibility.fontScale
            love.graphics.printf(text, 0, screenHeight * 0.32, screenWidth, 'center', 0, scale, scale)
            love.graphics.setColor(1,1,1,1)
        end
    
        -- Draw notification/event panel
        local function drawNotificationPanel(dt, screenWidth, screenHeight)
            notificationTimer = notificationTimer + dt
            if #notifications > 0 and notificationTimer > notificationDuration then
                table.remove(notifications, 1)
                notificationTimer = 0
            end
            if #notifications > 0 then
                local notif = notifications[1]
                love.graphics.setColor(0.2,0.2,0.2,0.85)
                love.graphics.rectangle('fill', screenWidth-340, 30, 320, 44, 8)
                love.graphics.setColor(0.7,1,0.7,1)
                love.graphics.printf(notif, screenWidth-330, 44, 300, 'left')
                love.graphics.setColor(1,1,1,1)
            end
        end
    
        -- Add notification (call from game events)
        local function addNotification(msg)
            table.insert(notifications, msg)
        end
    
        -- Patch main menu draw
        local old_draw = love.draw
        function love.draw()
            local dt = love.timer.getDelta and love.timer.getDelta() or 0.016
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            -- High contrast mode
            if accessibility.highContrast then
                love.graphics.clear(0,0,0)
            end
            -- Dynamic background (reuse previous logic, respect reduced motion)
            if not accessibility.reducedMotion then
                if drawDynamicBackground then drawDynamicBackground(dt) end
            end
            -- ...existing code...
            -- Draw main menu UI
            -- ...existing code...
            -- Draw flavor text
            drawFlavorText(dt, w, h)
            -- Draw notification panel
            drawNotificationPanel(dt, w, h)
            -- Draw accessibility toggle
            drawAccessibilityToggle(w-160, h-56, 140, 36)
            if old_draw then old_draw() end
        end
    
        -- Patch mousepressed for accessibility toggle
        local old_mousepressed = love.mousepressed
        function love.mousepressed(x, y, button)
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            if handleAccessibilityToggle(x, y, w-160, h-56, 140, 36) then return end
            if old_mousepressed then old_mousepressed(x, y, button) end
        end
    
        -- Example: add a notification on load (remove in production)
        addNotification("Achievement Unlocked: First Login!")
    
        -- Draw menu buttons with neon pulse
        for i, btn in ipairs(menuItems) do
            local y = startY + (i - 1) * itemHeight
            local selected = (i == self.selectedItem)
            drawMenuButton(btn.text, (screenWidth - 240) / 2, y, 240, itemHeight, selected, neonPulseTimer + i)
        end
end

-- Handle key input
function MainMenu:keypressed(key)
    if not self.menuItems or #self.menuItems == 0 then return end

    if key == "up" then
        self.selectedItem = math.max(1, self.selectedItem - 1)
    elseif key == "down" then
        self.selectedItem = math.min(#self.menuItems, self.selectedItem + 1)
    elseif key == "return" or key == "enter" then
        self:activateMenuItem()
    elseif key == "escape" then
        self:activateMenuItem(4) -- Quit
    end
end

-- Handle mouse input
function MainMenu:mousepressed(x, y, button)
    if button == 1 then -- Left click
        local screenHeight = love.graphics.getHeight()
        local startY = screenHeight * 0.4
        local itemHeight = 40
        local menuItems = self.menuItems or {}

        for i, item in ipairs(menuItems) do
            local itemY = startY + (i - 1) * itemHeight
            if y >= itemY and y <= itemY + itemHeight then
                self.selectedItem = i
                self:activateMenuItem()
                break
            end
        end
    end
end

-- Activate the selected menu item
function MainMenu:activateMenuItem(itemIndex)
    local index = itemIndex or self.selectedItem
    local item = self.menuItems[index]
    
    if not item then return end
    
    if item.action == "start_game" then
        if self.eventBus then
            self.eventBus:publish("scene_request", {scene = "soc_view"})
        else
            print("scene_request: soc_view (eventBus missing)")
        end
    elseif item.action == "load_game" then
        if self.eventBus then
            self.eventBus:publish("load_game_request", {})
            self.eventBus:publish("scene_request", {scene = "soc_view"})
        else
            print("load_game_request + scene_request: eventBus missing")
        end
    elseif item.action == "settings" then
        -- TODO: Implement settings scene
        print("⚙️ Settings menu not yet implemented")
    elseif item.action == "quit" then
        love.event.quit()
    end
end

return MainMenu