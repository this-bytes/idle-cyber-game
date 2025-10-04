--[[
    Contracts Board Scene
    This is a self-contained scene file that follows the original, working architecture.
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

    self.contracts = {}
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
    if self.systems and self.systems.contractSystem and self.systems.contractSystem.getAvailableContracts then
        self.contracts = self.systems.contractSystem:getAvailableContracts()
    else
        print("WARNING: Could not fetch contracts from contractSystem.")
    end
    self:rebuildUI()
end

function ContractsBoardScene:rebuildUI()
    if not self.luis then return end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end

function ContractsBoardScene:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)

    luis.insertElement(self.layerName, luis.newLabel("CONTRACTS BOARD", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newButton("< BACK", 15, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "soc_view"}) 
    end, nil, 2, 3))

    if not self.contracts or #self.contracts == 0 then
        luis.insertElement(self.layerName, luis.newLabel("No contracts available.", numCols, 3, 10, 1, "center"))
    else
        self:buildContractList()
    end
end

function ContractsBoardScene:buildContractList()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local cardWidth = numCols - 10
    local cardCol = 6
    local currentRow = 6

    for i, contract in ipairs(self.contracts) do
        luis.insertElement(self.layerName, luis.newLabel(contract.displayName, cardWidth, 1, currentRow, cardCol, "left"))
        currentRow = currentRow + 1
        luis.insertElement(self.layerName, luis.newLabel(contract.description, cardWidth, 2, currentRow, cardCol, "left"))
        currentRow = currentRow + 2
        local rewardString = string.format("Rewards: $%d, %d Rep", contract.baseBudget, contract.reputationReward)
        luis.insertElement(self.layerName, luis.newLabel(rewardString, cardWidth, 1, currentRow, cardCol, "left"))
        
        local acceptButton = luis.newButton("ACCEPT", 15, 2, function() 
            self.systems.contractSystem:acceptContract(contract.id)
            self:updateContracts()
        end, nil, currentRow - 1, cardCol + cardWidth - 17)
        luis.insertElement(self.layerName, acceptButton)

        currentRow = currentRow + 3
    end
end

function ContractsBoardScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function ContractsBoardScene:update(dt) end
function ContractsBoardScene:keypressed(key) end
function ContractsBoardScene:mousepressed(x, y, button) end

return ContractsBoardScene