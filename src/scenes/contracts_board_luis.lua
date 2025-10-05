--[[
    Contracts Board Scene
    Shows both available contracts (to accept) and active contracts (in progress)
]]

local ContractsBoardScene = {}
ContractsBoardScene.__index = ContractsBoardScene

function ContractsBoardScene.new(eventBus, luis, systems)
    local self = setmetatable({}, ContractsBoardScene)
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "contracts_board"

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

    self.availableContracts = {}
    self.activeContracts = {}
    self.updateTimer = 0
    self.contractLabels = {}
    return self
end

function ContractsBoardScene:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:updateContracts()
end

function ContractsBoardScene:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function ContractsBoardScene:updateContracts()
    if self.systems and self.systems.contractSystem then
        if self.systems.contractSystem.getAvailableContracts then
            self.availableContracts = self.systems.contractSystem:getAvailableContracts() or {}
        else
            -- Fallback: access directly
            self.availableContracts = self.systems.contractSystem.availableContracts or {}
        end
        
        -- Get active contracts
        self.activeContracts = self.systems.contractSystem.activeContracts or {}
    else
        print("WARNING: Could not fetch contracts from contractSystem.")
        self.availableContracts = {}
        self.activeContracts = {}
    end
    self:rebuildUI()
end

function ContractsBoardScene:rebuildUI()
    if not self.luis then return end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self.contractLabels = {}
    self:buildUI()
end

function ContractsBoardScene:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)

    luis.insertElement(self.layerName, luis.newLabel("CONTRACTS BOARD", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newButton("< BACK", 15, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "soc_view"}) 
    end, nil, 2, 3))

    -- Split screen: Left side = Active Contracts, Right side = Available Contracts
    local leftCol = 3
    local leftWidth = math.floor(numCols * 0.45)
    local rightCol = leftCol + leftWidth + 3
    local rightWidth = numCols - rightCol - 3
    
    -- LEFT PANEL: Active Contracts
    luis.insertElement(self.layerName, luis.newLabel("ACTIVE CONTRACTS", leftWidth, 2, 6, leftCol, "left"))
    
    local currentRow = 8
    local hasActive = false
    for _, contract in pairs(self.activeContracts) do
        hasActive = true
        local progress = 0
        if contract.duration and contract.duration > 0 then
            progress = 100 - ((contract.remainingTime / contract.duration) * 100)
        end
        
        local nameLabel = luis.newLabel(
            contract.displayName or contract.clientName or "Contract",
            leftWidth - 2,
            1,
            currentRow,
            leftCol,
            "left"
        )
        luis.insertElement(self.layerName, nameLabel)
        table.insert(self.contractLabels, nameLabel)
        currentRow = currentRow + 1
        
        local progressLabel = luis.newLabel(
            string.format("Progress: %.0f%% | Remaining: %.0fs", progress, contract.remainingTime or 0),
            leftWidth - 2,
            1,
            currentRow,
            leftCol,
            "left"
        )
        luis.insertElement(self.layerName, progressLabel)
        table.insert(self.contractLabels, progressLabel)
        currentRow = currentRow + 1
        
        local incomeLabel = luis.newLabel(
            string.format("Income: $%.1f/s | Budget: $%d", contract.incomePerSecond or 0, contract.baseBudget or 0),
            leftWidth - 2,
            1,
            currentRow,
            leftCol,
            "left"
        )
        luis.insertElement(self.layerName, incomeLabel)
        currentRow = currentRow + 3
    end
    
    if not hasActive then
        luis.insertElement(self.layerName, luis.newLabel("No active contracts - accept some from the right!", leftWidth - 2, 2, 8, leftCol, "left"))
    end
    
    -- RIGHT PANEL: Available Contracts
    luis.insertElement(self.layerName, luis.newLabel("AVAILABLE CONTRACTS", rightWidth, 2, 6, rightCol, "left"))
    
    currentRow = 8
    if not self.availableContracts or (type(self.availableContracts) == "table" and next(self.availableContracts) == nil) then
        luis.insertElement(self.layerName, luis.newLabel("No contracts available. New contracts generate periodically.", rightWidth - 2, 3, currentRow, rightCol, "left"))
    else
        self:buildAvailableContractList(rightCol, rightWidth, currentRow)
    end
end

function ContractsBoardScene:buildAvailableContractList(startCol, cardWidth, startRow)
    local luis = self.luis
    local currentRow = startRow

    -- Convert available contracts (which might be a map) to array
    local contractsArray = {}
    if type(self.availableContracts) == "table" then
        for id, contract in pairs(self.availableContracts) do
            table.insert(contractsArray, contract)
        end
    end

    for i, contract in ipairs(contractsArray) do
        luis.insertElement(self.layerName, luis.newLabel(contract.displayName or contract.clientName, cardWidth - 2, 1, currentRow, startCol, "left"))
        currentRow = currentRow + 1
        
        luis.insertElement(self.layerName, luis.newLabel(contract.description or "Security contract", cardWidth - 2, 2, currentRow, startCol, "left"))
        currentRow = currentRow + 2
        
        local rewardString = string.format("💰 $%d | 🌟 %d Rep | ⏱ %ds", 
            contract.baseBudget or 0, 
            contract.reputationReward or 0,
            contract.baseDuration or 0
        )
        luis.insertElement(self.layerName, luis.newLabel(rewardString, cardWidth - 2, 1, currentRow, startCol, "left"))
        
        local acceptButton = luis.newButton("ACCEPT", 15, 2, function() 
            self.systems.contractSystem:acceptContract(contract.id)
            self:updateContracts()
        end, nil, currentRow - 1, startCol + cardWidth - 17)
        luis.insertElement(self.layerName, acceptButton)

        currentRow = currentRow + 3
    end
end

function ContractsBoardScene:update(dt)
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer > 0.5 then
        -- Update progress labels for active contracts
        local labelIndex = 1
        for _, contract in pairs(self.activeContracts) do
            if self.contractLabels[labelIndex + 1] then
                local progress = 0
                if contract.duration and contract.duration > 0 then
                    progress = 100 - ((contract.remainingTime / contract.duration) * 100)
                end
                if self.contractLabels[labelIndex + 1].setText then
                    self.contractLabels[labelIndex + 1]:setText(
                        string.format("Progress: %.0f%% | Remaining: %.0fs", progress, contract.remainingTime or 0)
                    )
                end
            end
            labelIndex = labelIndex + 3 -- Skip 3 labels per contract
        end
        self.updateTimer = 0
    end
end

function ContractsBoardScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function ContractsBoardScene:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
        return true
    end
end

function ContractsBoardScene:mousepressed(x, y, button) end

return ContractsBoardScene