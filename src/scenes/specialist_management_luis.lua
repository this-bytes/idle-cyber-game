--[[
    Specialist Management Scene
    This is a self-contained scene file that follows the original, working architecture.
]]

local SpecialistManagementScene = {}
SpecialistManagementScene.__index = SpecialistManagementScene

function SpecialistManagementScene.new(eventBus, luis, systems)
    local self = setmetatable({}, SpecialistManagementScene)
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "specialist_management"

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
        disabledTextColor = {0.5, 0.5, 0.5, 0.5},
        disabledBgColor = {0.1, 0.1, 0.1, 0.5},
        disabledBorderColor = {0.3, 0.3, 0.3, 0.5},
    }
    if self.luis.setTheme then
        self.luis.setTheme(cyberpunkTheme)
    end

    self.team = {}
    self.available = {}
    return self
end

function SpecialistManagementScene:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:updateSpecialists()
end

function SpecialistManagementScene:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function SpecialistManagementScene:updateSpecialists()
    if self.systems and self.systems.specialistSystem then
        self.team = self.systems.specialistSystem:getTeam()
        self.available = self.systems.specialistSystem:getAvailableSpecialists()
    else
        print("WARNING: Could not fetch specialists from specialistSystem.")
    end
    self:rebuildUI()
end

function SpecialistManagementScene:rebuildUI()
    if not self.luis then return end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end

function SpecialistManagementScene:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)

    luis.insertElement(self.layerName, luis.newLabel("SPECIALIST MANAGEMENT", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newButton("< BACK", 15, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "soc_view"}) 
    end, nil, 2, 3))

    luis.insertElement(self.layerName, luis.newLabel("YOUR TEAM", 40, 2, 6, 6, "left"))
    local teamRow = 8
    if #self.team > 0 then
        for i, specialist in ipairs(self.team) do
            local text = string.format("%s - Level %d", specialist.name, specialist.level)
            luis.insertElement(self.layerName, luis.newLabel(text, 40, 1, teamRow, 6, "left"))
            teamRow = teamRow + 1
        end
    else
        luis.insertElement(self.layerName, luis.newLabel("No specialists hired.", 40, 1, teamRow, 6, "left"))
    end

    luis.insertElement(self.layerName, luis.newLabel("AVAILABLE FOR HIRE", numCols - 50, 2, 6, 50, "left"))
    local availableRow = 8
    if #self.available > 0 then
        for i, specialist in ipairs(self.available) do
            local canAfford = self.systems.resourceManager:hasSufficientResources(specialist.cost)
            
            luis.insertElement(self.layerName, luis.newLabel(specialist.displayName, 30, 1, availableRow, 50, "left"))
            
            local costString = "Cost: "
            for currency, amount in pairs(specialist.cost) do
                costString = costString .. amount .. " " .. currency .. " "
            end
            luis.insertElement(self.layerName, luis.newLabel(costString, 30, 1, availableRow + 1, 50, "left"))

            local hireButton = luis.newButton("HIRE", 12, 2, function() 
                if canAfford then
                    self.systems.specialistSystem:hireSpecialist(specialist.id)
                    self:updateSpecialists()
                end
            end, nil, availableRow, 50 + 32)

            if not canAfford then
                hireButton:setDisabled(true)
            end
            luis.insertElement(self.layerName, hireButton)

            availableRow = availableRow + 3
        end
    else
        luis.insertElement(self.layerName, luis.newLabel("No specialists available for hire.", 40, 1, availableRow, 50, "left"))
    end
end

function SpecialistManagementScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function SpecialistManagementScene:update(dt) end
function SpecialistManagementScene:keypressed(key) end
function SpecialistManagementScene:mousepressed(x, y, button) end

return SpecialistManagementScene