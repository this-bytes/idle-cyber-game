-- Contract Detail Modal - Rich interactive contract management interface
-- Provides detailed contract information, client background, and decision options

local ContractModal = {}
ContractModal.__index = ContractModal

local TerminalTheme = require("src.ui.terminal_theme")
local format = require("src.utils.format")

function ContractModal.new(eventBus)
    local self = setmetatable({}, ContractModal)
    self.eventBus = eventBus
    self.theme = TerminalTheme.new()
    
    -- Modal state
    self.visible = false
    self.contract = nil
    self.clientInfo = nil
    self.animationTime = 0
    self.selectedAction = "accept" -- "accept" or "decline"
    
    -- Animation properties
    self.slideProgress = 0
    self.fadeAlpha = 0
    self.pulseTime = 0
    
    -- Client background generator
    self.clientTemplates = {
        {
            type = "startup",
            backgrounds = {
                "A fast-growing fintech startup specializing in mobile payments",
                "An innovative healthtech company developing telemedicine solutions", 
                "A sustainable energy startup building smart grid technology",
                "A promising edtech platform focused on remote learning"
            },
            concerns = {
                "Recent rapid growth has outpaced security infrastructure",
                "Regulatory compliance requirements are increasing",
                "Customer data protection is critical for trust",
                "Limited internal security expertise"
            }
        },
        {
            type = "enterprise",
            backgrounds = {
                "A Fortune 500 manufacturing company with global operations",
                "A major healthcare provider serving millions of patients",
                "A multinational retail corporation with extensive e-commerce",
                "A leading financial services firm managing institutional assets"
            },
            concerns = {
                "Complex legacy systems create security vulnerabilities",
                "Sophisticated threat actors are targeting the industry",
                "Compliance with multiple international regulations",
                "Need for enterprise-grade security architecture"
            }
        },
        {
            type = "government",
            backgrounds = {
                "A municipal government managing critical city infrastructure",
                "A federal agency handling sensitive citizen data",
                "A public utility company serving essential services",
                "A university system with extensive research programs"
            },
            concerns = {
                "Nation-state actors pose significant threats",
                "Public trust depends on robust security measures",
                "Budget constraints limit security investments",
                "Need for transparent security practices"
            }
        }
    }
    
    return self
end

-- Show contract modal with detailed information
function ContractModal:show(contract)
    if not contract then return end
    
    self.contract = contract
    self.clientInfo = self:generateClientBackground(contract)
    self.visible = true
    self.animationTime = 0
    self.slideProgress = 0
    self.fadeAlpha = 0
    self.selectedAction = "accept"
    
    -- Emit sound event
    if self.eventBus then
        self.eventBus:publish("ui.notification", {})
    end
    
    print("📋 Contract modal opened: " .. contract.clientName)
end

-- Hide the modal
function ContractModal:hide()
    self.visible = false
    self.contract = nil
    self.clientInfo = nil
    
    -- Emit sound event
    if self.eventBus then
        self.eventBus:publish("ui.click", {})
    end
end

-- Generate rich client background information
function ContractModal:generateClientBackground(contract)
    local clientType = self:inferClientType(contract)
    local template = self.clientTemplates[math.random(#self.clientTemplates)]
    
    -- Find matching template or use random
    for _, t in ipairs(self.clientTemplates) do
        if t.type == clientType then
            template = t
            break
        end
    end
    
    local background = template.backgrounds[math.random(#template.backgrounds)]
    local concern = template.concerns[math.random(#template.concerns)]
    
    -- Generate additional details
    local timeline = self:generateTimeline(contract)
    local riskLevel = self:calculateRiskLevel(contract)
    local specialRequirements = self:generateSpecialRequirements(contract)
    
    return {
        type = clientType,
        background = background,
        primaryConcern = concern,
        timeline = timeline,
        riskLevel = riskLevel,
        specialRequirements = specialRequirements,
        contactPerson = self:generateContactPerson(contract.clientName),
        industryContext = self:generateIndustryContext(clientType)
    }
end

-- Infer client type from contract details
function ContractModal:inferClientType(contract)
    local budget = contract.totalBudget or 0
    local duration = contract.duration or 0
    
    if budget < 5000 then
        return "startup"
    elseif budget > 25000 then
        return "enterprise"
    elseif string.find(contract.clientName or "", "City") or 
           string.find(contract.clientName or "", "Gov") or
           string.find(contract.description or "", "compliance") then
        return "government"
    else
        return "enterprise"
    end
end

-- Generate project timeline
function ContractModal:generateTimeline(contract)
    local phases = {}
    local duration = contract.duration or 300
    
    if duration < 200 then
        phases = {"Assessment & Planning", "Implementation", "Validation"}
    elseif duration < 500 then
        phases = {"Discovery & Analysis", "Architecture Design", "Implementation", "Testing & Validation"}
    else
        phases = {"Comprehensive Assessment", "Risk Analysis", "Solution Design", "Phased Implementation", "Ongoing Monitoring", "Final Review"}
    end
    
    return phases
end

-- Calculate risk level based on contract parameters
function ContractModal:calculateRiskLevel(contract)
    local risk = 1
    local budget = contract.totalBudget or 0
    local reputation = contract.reputationReward or 0
    
    if budget > 20000 then risk = risk + 1 end
    if reputation > 5 then risk = risk + 1 end
    if contract.duration and contract.duration > 600 then risk = risk + 1 end
    
    local levels = {"Low", "Moderate", "High", "Critical"}
    return levels[math.min(risk, #levels)]
end

-- Generate special requirements
function ContractModal:generateSpecialRequirements(contract)
    local requirements = {}
    local pool = {
        "Security clearance verification required",
        "On-site presence needed for sensitive phases",
        "24/7 support during implementation",
        "Compliance with industry-specific regulations",
        "Integration with existing security tools",
        "Staff training and knowledge transfer",
        "Detailed documentation and reporting",
        "Post-implementation monitoring period"
    }
    
    local numRequirements = math.random(2, 4)
    local selected = {}
    
    for i = 1, numRequirements do
        local req = pool[math.random(#pool)]
        if not selected[req] then
            table.insert(requirements, req)
            selected[req] = true
        end
    end
    
    return requirements
end

-- Generate contact person details
function ContractModal:generateContactPerson(clientName)
    local firstNames = {"Sarah", "Michael", "Jennifer", "David", "Lisa", "Robert", "Maria", "James", "Emily", "Daniel"}
    local lastNames = {"Johnson", "Williams", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas"}
    local titles = {"CISO", "IT Director", "Security Manager", "CTO", "VP Technology", "Risk Manager"}
    
    local first = firstNames[math.random(#firstNames)]
    local last = lastNames[math.random(#lastNames)]
    local title = titles[math.random(#titles)]
    
    return {
        name = first .. " " .. last,
        title = title,
        email = string.lower(first .. "." .. last .. "@" .. string.lower(clientName:gsub(" ", "") .. ".com"))
    }
end

-- Generate industry context
function ContractModal:generateIndustryContext(clientType)
    local contexts = {
        startup = "Fast-paced environment with evolving security needs and resource constraints",
        enterprise = "Complex security landscape with established processes and compliance requirements",
        government = "High-security environment with strict protocols and public accountability"
    }
    
    return contexts[clientType] or contexts.enterprise
end

-- Update animation
function ContractModal:update(dt)
    if not self.visible then return end
    
    self.animationTime = self.animationTime + dt
    self.pulseTime = self.pulseTime + dt * 3
    
    -- Slide in animation
    local targetSlide = self.visible and 1 or 0
    self.slideProgress = self.slideProgress + (targetSlide - self.slideProgress) * dt * 6
    
    -- Fade in animation
    local targetAlpha = self.visible and 1 or 0
    self.fadeAlpha = self.fadeAlpha + (targetAlpha - self.fadeAlpha) * dt * 8
end

-- Handle input
function ContractModal:keypressed(key)
    if not self.visible then return false end
    
    if key == "escape" or key == "q" then
        self:hide()
        return true
    elseif key == "enter" or key == "space" then
        self:executeAction()
        return true
    elseif key == "tab" or key == "left" or key == "right" then
        self.selectedAction = (self.selectedAction == "accept") and "decline" or "accept"
        if self.eventBus then
            self.eventBus:publish("ui.hover", {playSound = true})
        end
        return true
    end
    
    return false
end

function ContractModal:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    
    local w, h = love.graphics.getDimensions()
    local modalW, modalH = w * 0.8, h * 0.85
    local modalX, modalY = (w - modalW) / 2, (h - modalH) / 2
    
    -- Check if click is inside modal
    if x >= modalX and x <= modalX + modalW and y >= modalY and y <= modalY + modalH then
        -- Check button areas
        local buttonY = modalY + modalH - 80
        local acceptX, declineX = modalX + 50, modalX + modalW - 200
        local buttonW, buttonH = 140, 35
        
        if y >= buttonY and y <= buttonY + buttonH then
            if x >= acceptX and x <= acceptX + buttonW then
                self.selectedAction = "accept"
                self:executeAction()
                return true
            elseif x >= declineX and x <= declineX + buttonW then
                self.selectedAction = "decline"
                self:executeAction()
                return true
            end
        end
        
        return true -- Consume click inside modal
    else
        -- Click outside modal - close it
        self:hide()
        return true
    end
end

-- Execute the selected action
function ContractModal:executeAction()
    if not self.contract then return end
    
    if self.selectedAction == "accept" then
        -- Emit contract acceptance event
        if self.eventBus then
            self.eventBus:publish("contract_accepted", {
                contract = self.contract,
                clientInfo = self.clientInfo
            })
            self.eventBus:publish("ui.success", {})
        end
        print("✅ Contract accepted: " .. self.contract.clientName)
    else
        -- Emit contract decline event
        if self.eventBus then
            self.eventBus:publish("contract_declined", {
                contract = self.contract,
                reason = "Player choice"
            })
            self.eventBus:publish("ui.click", {})
        end
        print("❌ Contract declined: " .. self.contract.clientName)
    end
    
    self:hide()
end

-- Draw the modal
function ContractModal:draw()
    if not self.visible or not self.contract then return end
    
    local w, h = love.graphics.getDimensions()
    
    -- Background overlay with fade
    love.graphics.setColor(0, 0, 0, 0.7 * self.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Modal dimensions with slide animation
    local modalW, modalH = w * 0.8, h * 0.85
    local modalX = (w - modalW) / 2 + (1 - self.slideProgress) * modalW * 0.3
    local modalY = (h - modalH) / 2
    
    -- Modal background
    love.graphics.setColor(0.02, 0.02, 0.03, 0.98 * self.fadeAlpha)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 8, 8)
    
    -- Modal border with glow effect
    local glowIntensity = 0.5 + 0.3 * math.sin(self.pulseTime)
    love.graphics.setColor(0.1, 0.9, 0.9, glowIntensity * self.fadeAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 8, 8)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Content area
    local contentX, contentY = modalX + 30, modalY + 30
    local contentW = modalW - 60
    local lineHeight = 25
    local currentY = contentY
    
    -- Title
    love.graphics.setColor(0.1, 0.9, 0.9, self.fadeAlpha)
    love.graphics.printf("CONTRACT PROPOSAL", contentX, currentY, contentW, "center")
    currentY = currentY + lineHeight * 1.5
    
    -- Client name (emphasized)
    love.graphics.setColor(1, 1, 1, self.fadeAlpha)
    love.graphics.printf(self.contract.clientName or "Unknown Client", contentX, currentY, contentW, "center")
    currentY = currentY + lineHeight * 1.2
    
    -- Separator line
    love.graphics.setColor(0.1, 0.9, 0.9, 0.5 * self.fadeAlpha)
    love.graphics.rectangle("fill", contentX, currentY, contentW, 2)
    currentY = currentY + lineHeight
    
    -- Contract details in two columns
    local col1X, col2X = contentX, contentX + contentW / 2
    local col1Y, col2Y = currentY, currentY
    
    -- Left column - Financial details
    love.graphics.setColor(0.9, 0.9, 0.1, self.fadeAlpha)
    love.graphics.print("FINANCIAL TERMS", col1X, col1Y)
    col1Y = col1Y + lineHeight
    
    love.graphics.setColor(0.8, 0.8, 0.8, self.fadeAlpha)
    love.graphics.print("Total Budget: $" .. format.number(self.contract.totalBudget or 0, 0), col1X, col1Y)
    col1Y = col1Y + lineHeight * 0.8
    
    love.graphics.print("Duration: " .. math.floor((self.contract.duration or 0) / 60) .. " minutes", col1X, col1Y)
    col1Y = col1Y + lineHeight * 0.8
    
    love.graphics.print("Reputation: +" .. (self.contract.reputationReward or 0), col1X, col1Y)
    col1Y = col1Y + lineHeight * 1.2
    
    -- Right column - Project details
    love.graphics.setColor(0.9, 0.9, 0.1, self.fadeAlpha)
    love.graphics.print("PROJECT DETAILS", col2X, col2Y)
    col2Y = col2Y + lineHeight
    
    love.graphics.setColor(0.8, 0.8, 0.8, self.fadeAlpha)
    if self.clientInfo then
        love.graphics.print("Risk Level: " .. self.clientInfo.riskLevel, col2X, col2Y)
        col2Y = col2Y + lineHeight * 0.8
        
        love.graphics.print("Contact: " .. self.clientInfo.contactPerson.name, col2X, col2Y)
        col2Y = col2Y + lineHeight * 0.8
        
        love.graphics.print("Title: " .. self.clientInfo.contactPerson.title, col2X, col2Y)
        col2Y = col2Y + lineHeight * 1.2
    end
    
    -- Project description
    currentY = math.max(col1Y, col2Y)
    love.graphics.setColor(0.9, 0.9, 0.1, self.fadeAlpha)
    love.graphics.print("PROJECT DESCRIPTION", contentX, currentY)
    currentY = currentY + lineHeight
    
    love.graphics.setColor(1, 1, 1, self.fadeAlpha)
    love.graphics.printf(self.contract.description or "No description available", contentX, currentY, contentW, "left")
    currentY = currentY + lineHeight * 2
    
    -- Client background (if available)
    if self.clientInfo then
        love.graphics.setColor(0.9, 0.9, 0.1, self.fadeAlpha)
        love.graphics.print("CLIENT BACKGROUND", contentX, currentY)
        currentY = currentY + lineHeight
        
        love.graphics.setColor(0.9, 0.9, 0.9, self.fadeAlpha)
        love.graphics.printf(self.clientInfo.background, contentX, currentY, contentW, "left")
        currentY = currentY + lineHeight * 1.5
        
        love.graphics.setColor(0.8, 0.8, 0.8, self.fadeAlpha)
        love.graphics.printf("Primary Concern: " .. self.clientInfo.primaryConcern, contentX, currentY, contentW, "left")
        currentY = currentY + lineHeight * 1.5
    end
    
    -- Action buttons
    local buttonY = modalY + modalH - 80
    local acceptX, declineX = modalX + 50, modalX + modalW - 200
    local buttonW, buttonH = 140, 35
    
    -- Accept button
    local acceptSelected = (self.selectedAction == "accept")
    local acceptColor = acceptSelected and {0.1, 0.9, 0.1} or {0.3, 0.6, 0.3}
    love.graphics.setColor(acceptColor[1], acceptColor[2], acceptColor[3], self.fadeAlpha)
    love.graphics.rectangle("fill", acceptX, buttonY, buttonW, buttonH, 4, 4)
    
    love.graphics.setColor(1, 1, 1, self.fadeAlpha)
    love.graphics.printf("ACCEPT CONTRACT", acceptX, buttonY + 8, buttonW, "center")
    
    -- Decline button
    local declineSelected = (self.selectedAction == "decline")
    local declineColor = declineSelected and {0.9, 0.1, 0.1} or {0.6, 0.3, 0.3}
    love.graphics.setColor(declineColor[1], declineColor[2], declineColor[3], self.fadeAlpha)
    love.graphics.rectangle("fill", declineX, buttonY, buttonW, buttonH, 4, 4)
    
    love.graphics.setColor(1, 1, 1, self.fadeAlpha)
    love.graphics.printf("DECLINE", declineX, buttonY + 8, buttonW, "center")
    
    -- Help text
    love.graphics.setColor(0.6, 0.6, 0.6, self.fadeAlpha)
    love.graphics.printf("TAB: Switch • ENTER: Confirm • ESC: Cancel", contentX, buttonY + 50, contentW, "center")
end

-- Check if modal is visible
function ContractModal:isVisible()
    return self.visible
end

return ContractModal