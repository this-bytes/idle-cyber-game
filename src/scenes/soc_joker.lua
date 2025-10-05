-- SOC Joker Scene - Card-based Roguelike Gameplay
-- Balatro-inspired cybersecurity breach containment runs

local SOCJoker = {}
SOCJoker.__index = SOCJoker

function SOCJoker.new(eventBus, luis, systems)
    local self = setmetatable({}, SOCJoker)
    
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "soc_joker"
    
    -- UI state
    self.selectedCardIndex = nil
    self.selectedThreatIndex = nil
    self.hoveredCardIndex = nil
    self.hoveredThreatIndex = nil
    
    -- Wave state
    self.threats = {}
    self.playerHealth = 100
    self.maxHealth = 100
    
    -- Shop state
    self.shopOfferings = {}
    
    -- Apply cyberpunk theme
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
    
    -- Subscribe to game events
    self:subscribeToEvents()
    
    return self
end

function SOCJoker:subscribeToEvents()
    -- Run events
    self.eventBus:subscribe("run_started", function(data)
        self:onRunStarted(data)
    end)
    
    self.eventBus:subscribe("wave_started", function(data)
        self:onWaveStarted(data)
    end)
    
    self.eventBus:subscribe("shop_opened", function(data)
        self:onShopOpened(data)
    end)
    
    self.eventBus:subscribe("run_ended", function(data)
        self:onRunEnded(data)
    end)
    
    -- Card events
    self.eventBus:subscribe("cards_drawn", function(data)
        self:refreshUI()
    end)
    
    self.eventBus:subscribe("card_played", function(data)
        self:onCardPlayed(data)
    end)
end

function SOCJoker:load(data)
    print("🃏 SOCJoker: Loading card-based roguelike mode")
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Check if we should start a new run
    if data and data.new_run then
        self.systems.runManager:startRun(data.ante or 1)
    else
        -- Show menu if not in a run
        local runState = self.systems.runManager:getRunState()
        if runState == "menu" then
            self:buildMenuUI()
        elseif runState == "wave" then
            self:buildWaveUI()
        elseif runState == "shop" then
            self:buildShopUI()
        elseif runState == "victory" or runState == "defeat" then
            self:buildResultsUI()
        end
    end
end

function SOCJoker:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

-- ============================================================================
-- MENU UI
-- ============================================================================

function SOCJoker:buildMenuUI()
    self.luis.clearLayer(self.layerName)
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    -- Title
    luis.insertElement(self.layerName, luis.newLabel("🃏 SOC JOKER", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newLabel("Breach Containment Runs", numCols, 2, 5, 1, "center"))
    
    -- Stats
    local stats = self.systems.runManager:getState()
    local statsText = string.format("Total Runs: %d | Victories: %d | High Score: %d", 
        stats.totalRuns or 0, stats.totalVictories or 0, stats.highScore or 0)
    luis.insertElement(self.layerName, luis.newLabel(statsText, numCols, 1, 8, 1, "center"))
    
    -- Ante selection buttons
    local buttonWidth = 20
    local centerCol = math.floor((numCols - buttonWidth) / 2)
    local startRow = 12
    
    luis.insertElement(self.layerName, luis.newButton("Start Run - Ante 1 (Easy)", buttonWidth, 3, function()
        self.systems.runManager:startRun(1)
    end, nil, startRow, centerCol))
    
    luis.insertElement(self.layerName, luis.newButton("Start Run - Ante 2 (Normal)", buttonWidth, 3, function()
        self.systems.runManager:startRun(2)
    end, nil, startRow + 4, centerCol))
    
    luis.insertElement(self.layerName, luis.newButton("Start Run - Ante 3 (Hard)", buttonWidth, 3, function()
        self.systems.runManager:startRun(3)
    end, nil, startRow + 8, centerCol))
    
    -- Back button
    luis.insertElement(self.layerName, luis.newButton("Back to Main Menu", buttonWidth, 3, function()
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
    end, nil, numRows - 5, centerCol))
end

-- ============================================================================
-- WAVE UI
-- ============================================================================

function SOCJoker:buildWaveUI()
    self.luis.clearLayer(self.layerName)
    self:refreshUI()
end

function SOCJoker:refreshUI()
    -- Don't rebuild during shop/results
    local runState = self.systems.runManager:getRunState()
    if runState ~= "wave" then return end
    
    self.luis.clearLayer(self.layerName)
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    
    -- Header with wave info
    local ante = self.systems.runManager:getCurrentAnte()
    local wave = self.systems.runManager:getCurrentWave()
    local waveConfig = self.systems.runManager:getWaveConfig()
    
    local header = string.format("Ante %d - Wave %d/3 | Threats: %d%s", 
        ante, wave, waveConfig.threats, waveConfig.boss and " + BOSS" or "")
    luis.insertElement(self.layerName, luis.newLabel(header, numCols, 2, 1, 1, "center"))
    
    -- Player status
    local currency = self.systems.runManager:getCurrency()
    local statusText = string.format("❤️ Health: %d/%d | 💰 Currency: $%d", 
        self.playerHealth, self.maxHealth, currency)
    luis.insertElement(self.layerName, luis.newLabel(statusText, numCols, 1, 3, 1, "center"))
    
    -- Deck info
    local deckSize = self.systems.deckManager:getDeckSize()
    local discardSize = self.systems.deckManager:getDiscardSize()
    local deckInfo = string.format("🎴 Deck: %d | 🗑️ Discard: %d", deckSize, discardSize)
    luis.insertElement(self.layerName, luis.newLabel(deckInfo, 20, 1, 5, 1))
    
    -- Action buttons
    luis.insertElement(self.layerName, luis.newButton("End Turn", 12, 2, function()
        self:endTurn()
    end, nil, 5, numCols - 13))
    
    luis.insertElement(self.layerName, luis.newButton("Forfeit", 12, 2, function()
        self.eventBus:publish("forfeit_run")
    end, nil, 8, numCols - 13))
end

function SOCJoker:onRunStarted(data)
    print(string.format("🎮 Run started: Ante %d", data.ante))
    self:generateWaveThreats()
    self:buildWaveUI()
end

function SOCJoker:onWaveStarted(data)
    print(string.format("⚔️ Wave %d started", data.wave))
    self:generateWaveThreats()
    self:buildWaveUI()
end

function SOCJoker:generateWaveThreats()
    local ante = self.systems.runManager:getCurrentAnte()
    local waveConfig = self.systems.runManager:getWaveConfig()
    
    -- Generate threat cards using ThreatSystem
    self.threats = {}
    for i = 1, waveConfig.threats do
        local threat = {
            id = "threat_" .. i,
            name = self:getRandomThreatName(),
            type = self:getRandomThreatType(),
            health = math.random(3, 8) * ante,
            maxHealth = math.random(3, 8) * ante,
            damage = math.random(2, 5) * ante
        }
        threat.maxHealth = threat.health
        table.insert(self.threats, threat)
    end
    
    if waveConfig.boss then
        local boss = {
            id = "threat_boss",
            name = "MEGA THREAT",
            type = "boss",
            health = 20 * ante,
            maxHealth = 20 * ante,
            damage = 8 * ante,
            isBoss = true
        }
        table.insert(self.threats, boss)
    end
end

function SOCJoker:getRandomThreatName()
    local names = {
        "Phishing Attack", "Ransomware", "DDoS Flood", "SQL Injection",
        "Zero-Day Exploit", "Credential Theft", "Malware Infection",
        "Social Engineering", "Data Breach", "Insider Threat"
    }
    return names[math.random(#names)]
end

function SOCJoker:getRandomThreatType()
    local types = {"network", "malware", "social", "data"}
    return types[math.random(#types)]
end

function SOCJoker:playCard(cardIndex, threatIndex)
    local hand = self.systems.deckManager:getHand()
    if cardIndex < 1 or cardIndex > #hand then return end
    
    local card = hand[cardIndex]
    local threat = nil
    if threatIndex and self.threats[threatIndex] then
        threat = self.threats[threatIndex]
    end
    
    -- Play the card
    local result = self.systems.deckManager:playCard(cardIndex, threat)
    
    -- Apply damage to threat
    if result.damage > 0 and threat then
        threat.health = threat.health - result.damage
        print(string.format("💥 %s deals %d damage to %s", card.name, result.damage, threat.name))
        
        -- Check if threat is defeated
        if threat.health <= 0 then
            print(string.format("✅ Defeated: %s", threat.name))
            self.systems.runManager:addThreatDefeated()
            table.remove(self.threats, threatIndex)
            
            -- Check if wave is complete
            if #self.threats == 0 then
                self:completeWave()
            end
        end
    end
    
    -- Apply AOE damage
    if result.aoe and result.aoe > 0 then
        for i, t in ipairs(self.threats) do
            t.health = t.health - result.aoe
            if t.health <= 0 then
                print(string.format("✅ Defeated: %s (AOE)", t.name))
                self.systems.runManager:addThreatDefeated()
            end
        end
        -- Remove defeated threats
        for i = #self.threats, 1, -1 do
            if self.threats[i].health <= 0 then
                table.remove(self.threats, i)
            end
        end
        if #self.threats == 0 then
            self:completeWave()
        end
    end
    
    -- Apply healing
    if result.heal and result.heal > 0 then
        self.playerHealth = math.min(self.maxHealth, self.playerHealth + result.heal)
        print(string.format("💚 %s heals %d HP! Health: %d/%d", card.name, result.heal, self.playerHealth, self.maxHealth))
    end
    
    -- Track card played
    self.systems.runManager:addCardPlayed()
    
    -- Refresh UI
    self:refreshUI()
end

function SOCJoker:onCardPlayed(data)
    self:refreshUI()
end

function SOCJoker:endTurn()
    -- Threats attack player
    for _, threat in ipairs(self.threats) do
        self.playerHealth = self.playerHealth - threat.damage
        print(string.format("💔 %s deals %d damage! Health: %d/%d", 
            threat.name, threat.damage, self.playerHealth, self.maxHealth))
    end
    
    -- Check if player died
    if self.playerHealth <= 0 then
        self:failWave()
        return
    end
    
    -- End turn in deck manager (discard hand, draw new)
    self.systems.deckManager:endTurn()
    
    self:refreshUI()
end

function SOCJoker:completeWave()
    print("🎉 Wave complete!")
    self.eventBus:publish("wave_complete", {success = true})
end

function SOCJoker:failWave()
    print("💀 Wave failed!")
    self.eventBus:publish("wave_complete", {success = false})
end

-- ============================================================================
-- SHOP UI
-- ============================================================================

function SOCJoker:buildShopUI()
    self.luis.clearLayer(self.layerName)
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    -- Title
    luis.insertElement(self.layerName, luis.newLabel("🛒 SHOP", numCols, 3, 2, 1, "center"))
    
    -- Currency display
    local currency = self.systems.runManager:getCurrency()
    luis.insertElement(self.layerName, luis.newLabel(
        string.format("💰 Available: $%d", currency), numCols, 1, 5, 1, "center"))
    
    -- Generate shop offerings
    self:generateShopOfferings()
    
    -- Display shop cards
    local startRow = 8
    local cardWidth = 20
    local cardGap = 3
    
    for i, offering in ipairs(self.shopOfferings) do
        local col = math.floor((numCols - (cardWidth * 3 + cardGap * 2)) / 2) + (i - 1) * (cardWidth + cardGap)
        
        -- Card name
        luis.insertElement(self.layerName, luis.newLabel(
            offering.name, cardWidth, 1, startRow, col, "center"))
        
        -- Card effect
        luis.insertElement(self.layerName, luis.newLabel(
            offering.effect, cardWidth, 2, startRow + 1, col, "center"))
        
        -- Price and buy button
        local canAfford = currency >= offering.cost
        local buttonText = canAfford and string.format("Buy $%d", offering.cost) or "Too Expensive"
        
        local button = luis.newButton(buttonText, cardWidth, 2, function()
            if canAfford then
                self:purchaseCard(i)
            end
        end, nil, startRow + 4, col)
        
        if not canAfford then
            button.disabled = true
        end
        
        luis.insertElement(self.layerName, button)
    end
    
    -- Skip shop button
    local buttonWidth = 20
    local centerCol = math.floor((numCols - buttonWidth) / 2)
    luis.insertElement(self.layerName, luis.newButton("Continue to Next Wave", buttonWidth, 3, function()
        self.systems.runManager:continueToNextWave()
    end, nil, numRows - 5, centerCol))
end

function SOCJoker:generateShopOfferings()
    self.shopOfferings = {}
    local availableCards = self.systems.deckManager:getAvailableCards()
    
    -- Randomly select 3 cards to offer
    for i = 1, 3 do
        local card = availableCards[math.random(#availableCards)]
        local offering = {
            id = card.id,
            name = card.name,
            effect = card.effect,
            cost = card.shopPrice or 50, -- Use shopPrice from card data
            cardData = card
        }
        table.insert(self.shopOfferings, offering)
    end
end

function SOCJoker:purchaseCard(index)
    local offering = self.shopOfferings[index]
    local currency = self.systems.runManager:getCurrency()
    
    if currency >= offering.cost then
        -- Deduct currency
        self.systems.runManager.currentRun.currency = currency - offering.cost
        
        -- Add card to deck
        self.systems.deckManager:addCardToDeck(offering.id)
        
        print(string.format("✅ Purchased: %s for $%d", offering.name, offering.cost))
        
        -- Rebuild shop UI
        self:buildShopUI()
    end
end

function SOCJoker:onShopOpened(data)
    print(string.format("🛒 Shop opened with $%d", data.currency))
    self:buildShopUI()
end

-- ============================================================================
-- RESULTS UI
-- ============================================================================

function SOCJoker:buildResultsUI()
    self.luis.clearLayer(self.layerName)
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)
    
    local runState = self.systems.runManager:getRunState()
    local currentRun = self.systems.runManager.currentRun
    
    -- Title
    if runState == "victory" then
        luis.insertElement(self.layerName, luis.newLabel("🏆 VICTORY!", numCols, 4, 3, 1, "center"))
    else
        luis.insertElement(self.layerName, luis.newLabel("💀 DEFEAT", numCols, 4, 3, 1, "center"))
    end
    
    -- Stats
    if currentRun then
        local statsText = string.format(
            "Ante: %d | Score: %d | Threats Defeated: %d | Cards Played: %d",
            currentRun.ante, currentRun.score, currentRun.threatsDefeated, currentRun.cardsPlayed
        )
        luis.insertElement(self.layerName, luis.newLabel(statsText, numCols, 2, 8, 1, "center"))
    end
    
    -- High score
    local highScore = self.systems.runManager.highScore
    luis.insertElement(self.layerName, luis.newLabel(
        string.format("High Score: %d", highScore), numCols, 1, 11, 1, "center"))
    
    -- Buttons
    local buttonWidth = 20
    local centerCol = math.floor((numCols - buttonWidth) / 2)
    
    luis.insertElement(self.layerName, luis.newButton("Play Again", buttonWidth, 3, function()
        self:buildMenuUI()
    end, nil, 15, centerCol))
    
    luis.insertElement(self.layerName, luis.newButton("Back to Main Menu", buttonWidth, 3, function()
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
    end, nil, 19, centerCol))
end

function SOCJoker:onRunEnded(data)
    print(string.format("🏁 Run ended: %s | Score: %d", 
        data.victory and "VICTORY" or "DEFEAT", data.score))
    self:buildResultsUI()
end

-- ============================================================================
-- CUSTOM DRAWING (Cards and Threats)
-- ============================================================================

function SOCJoker:draw()
    love.graphics.clear(0.02, 0.02, 0.05, 1.0)
    
    local runState = self.systems.runManager:getRunState()
    if runState == "wave" then
        self:drawWave()
    end
end

function SOCJoker:drawWave()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw threats at top
    self:drawThreats(screenWidth, screenHeight)
    
    -- Draw hand at bottom
    self:drawHand(screenWidth, screenHeight)
end

function SOCJoker:drawThreats(screenWidth, screenHeight)
    local cardWidth = 120
    local cardHeight = 80
    local cardGap = 10
    local totalWidth = #self.threats * (cardWidth + cardGap) - cardGap
    local startX = (screenWidth - totalWidth) / 2
    local startY = 80
    
    for i, threat in ipairs(self.threats) do
        local x = startX + (i - 1) * (cardWidth + cardGap)
        local y = startY
        
        -- Card background
        if i == self.selectedThreatIndex then
            love.graphics.setColor(1, 0.3, 0.3, 1)
        elseif i == self.hoveredThreatIndex then
            love.graphics.setColor(1, 0.5, 0.5, 1)
        else
            love.graphics.setColor(0.3, 0.1, 0.1, 1)
        end
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 5)
        
        -- Border
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 5)
        
        -- Threat name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(threat.name, x + 5, y + 5, cardWidth - 10, "center")
        
        -- Health bar
        local healthBarWidth = cardWidth - 20
        local healthBarHeight = 10
        local healthBarX = x + 10
        local healthBarY = y + cardHeight - 20
        
        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight)
        
        -- Health
        local healthPercent = threat.health / threat.maxHealth
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth * healthPercent, healthBarHeight)
        
        -- Health text
        love.graphics.setColor(1, 1, 1, 1)
        local healthText = string.format("%d/%d", threat.health, threat.maxHealth)
        love.graphics.printf(healthText, x, y + cardHeight - 35, cardWidth, "center")
    end
end

function SOCJoker:drawHand(screenWidth, screenHeight)
    local hand = self.systems.deckManager:getHand()
    if #hand == 0 then return end
    
    local cardWidth = 100
    local cardHeight = 140
    local cardGap = 10
    local totalWidth = #hand * (cardWidth + cardGap) - cardGap
    local startX = (screenWidth - totalWidth) / 2
    local startY = screenHeight - cardHeight - 20
    
    for i, card in ipairs(hand) do
        local x = startX + (i - 1) * (cardWidth + cardGap)
        local y = startY
        
        -- Lift card if hovered
        if i == self.hoveredCardIndex then
            y = y - 20
        end
        
        -- Card background
        if i == self.selectedCardIndex then
            love.graphics.setColor(0.2, 0.8, 1, 1)
        elseif i == self.hoveredCardIndex then
            love.graphics.setColor(0.1, 0.6, 0.8, 1)
        else
            love.graphics.setColor(0.05, 0.3, 0.4, 1)
        end
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 5)
        
        -- Border
        love.graphics.setColor(0, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 5)
        
        -- Card name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(card.name, x + 5, y + 10, cardWidth - 10, "center")
        
        -- Card effect
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf(card.effect, x + 5, y + 40, cardWidth - 10, "center")
        love.graphics.setFont(love.graphics.newFont(12))
        
        -- Damage indicator
        if card.damage > 0 then
            love.graphics.setColor(1, 0.5, 0.5, 1)
            love.graphics.printf(string.format("💥 %d", card.damage), x, y + cardHeight - 30, cardWidth, "center")
        end
    end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

function SOCJoker:update(dt)
    -- Update hovered card/threat based on mouse position
    local mx, my = love.mouse.getPosition()
    self:updateHover(mx, my)
end

function SOCJoker:updateHover(mx, my)
    local runState = self.systems.runManager:getRunState()
    if runState ~= "wave" then 
        self.hoveredCardIndex = nil
        self.hoveredThreatIndex = nil
        return 
    end
    
    -- Check hand hover
    local hand = self.systems.deckManager:getHand()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local cardWidth = 100
    local cardHeight = 140
    local cardGap = 10
    local totalWidth = #hand * (cardWidth + cardGap) - cardGap
    local startX = (screenWidth - totalWidth) / 2
    local startY = screenHeight - cardHeight - 20
    
    self.hoveredCardIndex = nil
    for i = 1, #hand do
        local x = startX + (i - 1) * (cardWidth + cardGap)
        local y = startY
        if i == self.hoveredCardIndex then
            y = y - 20
        end
        
        if mx >= x and mx <= x + cardWidth and my >= y and my <= y + cardHeight then
            self.hoveredCardIndex = i
            break
        end
    end
    
    -- Check threat hover
    local threatCardWidth = 120
    local threatCardHeight = 80
    local threatCardGap = 10
    local threatTotalWidth = #self.threats * (threatCardWidth + threatCardGap) - threatCardGap
    local threatStartX = (screenWidth - threatTotalWidth) / 2
    local threatStartY = 80
    
    self.hoveredThreatIndex = nil
    for i = 1, #self.threats do
        local x = threatStartX + (i - 1) * (threatCardWidth + threatCardGap)
        local y = threatStartY
        
        if mx >= x and mx <= x + threatCardWidth and my >= y and my <= y + threatCardHeight then
            self.hoveredThreatIndex = i
            break
        end
    end
end

function SOCJoker:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local runState = self.systems.runManager:getRunState()
    if runState ~= "wave" then return end
    
    -- Card selection
    if self.hoveredCardIndex then
        if self.selectedCardIndex == self.hoveredCardIndex then
            -- Deselect
            self.selectedCardIndex = nil
        else
            -- Select card
            self.selectedCardIndex = self.hoveredCardIndex
        end
    end
    
    -- Threat selection (play card if card is selected)
    if self.hoveredThreatIndex and self.selectedCardIndex then
        self:playCard(self.selectedCardIndex, self.hoveredThreatIndex)
        self.selectedCardIndex = nil
    end
end

function SOCJoker:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
        return true
    end
end

return SOCJoker
