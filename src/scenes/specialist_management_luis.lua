--[[
    Specialist Management Scene
    Complete specialist lifecycle: hiring, leveling, abilities, and deployment status
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
    self.selectedSpecialist = nil
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
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)

    luis.insertElement(self.layerName, luis.newLabel("SPECIALIST MANAGEMENT", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newButton("< BACK", 15, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "soc_view"}) 
    end, nil, 2, 3))

    -- Split screen layout
    local leftCol = 3
    local leftWidth = math.floor(numCols * 0.48)
    local rightCol = leftCol + leftWidth + 2
    local rightWidth = numCols - rightCol - 3

    -- LEFT: Your Team
    luis.insertElement(self.layerName, luis.newLabel("YOUR TEAM", leftWidth, 2, 6, leftCol, "left"))
    local teamRow = 8
    
    if #self.team > 0 then
        for i, specialist in ipairs(self.team) do
            -- Name and Level
            local statusIcon = "✅"
            if specialist.status == "busy" then
                statusIcon = "🔄"
            elseif specialist.status == "cooldown" then
                statusIcon = "⏳"
            end
            
            local text = string.format("%s %s - Level %d", statusIcon, specialist.name, specialist.level or 1)
            luis.insertElement(self.layerName, luis.newLabel(text, leftWidth - 2, 1, teamRow, leftCol, "left"))
            teamRow = teamRow + 1
            
            -- XP Progress (if exists)
            if specialist.xp ~= nil and specialist.level then
                local threshold = self.systems.specialistSystem.levelUpThresholds[specialist.level + 1] or 999999
                local xpText = string.format("  XP: %d/%d", specialist.xp, threshold)
                luis.insertElement(self.layerName, luis.newLabel(xpText, leftWidth - 2, 1, teamRow, leftCol, "left"))
                teamRow = teamRow + 1
            end
            
            -- Stats
            local stats = string.format("  Stats: Eff %.1f | Spd %.1f | Def %.1f", 
                specialist.efficiency or 1.0, 
                specialist.speed or 1.0, 
                specialist.defense or 1.0
            )
            luis.insertElement(self.layerName, luis.newLabel(stats, leftWidth - 2, 1, teamRow, leftCol, "left"))
            teamRow = teamRow + 1
            
            -- Abilities
            if specialist.abilities and #specialist.abilities > 0 then
                local abilitiesText = "  Abilities: " .. table.concat(specialist.abilities, ", ", 1, math.min(3, #specialist.abilities))
                luis.insertElement(self.layerName, luis.newLabel(abilitiesText, leftWidth - 2, 1, teamRow, leftCol, "left"))
                teamRow = teamRow + 1
            end
            
            teamRow = teamRow + 1 -- Gap between specialists
        end
    else
        luis.insertElement(self.layerName, luis.newLabel("No specialists hired yet.", leftWidth - 2, 1, teamRow, leftCol, "left"))
        teamRow = teamRow + 1
        luis.insertElement(self.layerName, luis.newLabel("Hire specialists from the right panel!", leftWidth - 2, 1, teamRow, leftCol, "left"))
    end

    -- RIGHT: Available for Hire
    luis.insertElement(self.layerName, luis.newLabel("AVAILABLE FOR HIRE", rightWidth, 2, 6, rightCol, "left"))
    local availableRow = 8
    
    if #self.available > 0 then
        for i, specialist in ipairs(self.available) do
            local canAfford = self.systems.resourceManager:hasSufficientResources(specialist.cost)
            
            -- Name and Tier
            local tierText = specialist.tier and (" [T" .. specialist.tier .. "]") or ""
            luis.insertElement(self.layerName, luis.newLabel(
                specialist.displayName .. tierText,
                rightWidth - 14,
                1,
                availableRow,
                rightCol,
                "left"
            ))
            
            -- Hire Button (inline on same row)
            local hireButton = luis.newButton("HIRE", 12, 2, function() 
                if canAfford then
                    self.systems.specialistSystem:hireSpecialist(specialist.id)
                    self:updateSpecialists()
                end
            end, nil, availableRow, rightCol + rightWidth - 13)

            if not canAfford then
                hireButton:setDisabled(true)
            end
            luis.insertElement(self.layerName, hireButton)
            
            availableRow = availableRow + 2
            
            -- Description
            if specialist.description then
                luis.insertElement(self.layerName, luis.newLabel(
                    specialist.description,
                    rightWidth - 2,
                    2,
                    availableRow,
                    rightCol,
                    "left"
                ))
                availableRow = availableRow + 2
            end
            
            -- Cost
            local costString = "Cost: "
            for currency, amount in pairs(specialist.cost) do
                costString = costString .. amount .. " " .. currency .. " "
            end
            luis.insertElement(self.layerName, luis.newLabel(costString, rightWidth - 2, 1, availableRow, rightCol, "left"))
            availableRow = availableRow + 1
            
            -- Base Stats
            local stats = string.format("Eff: %.1f | Spd: %.1f | Def: %.1f", 
                specialist.efficiency or 1.0, 
                specialist.speed or 1.0, 
                specialist.defense or 1.0
            )
            luis.insertElement(self.layerName, luis.newLabel(stats, rightWidth - 2, 1, availableRow, rightCol, "left"))
            availableRow = availableRow + 2
        end
    else
        luis.insertElement(self.layerName, luis.newLabel("No specialists available.", rightWidth - 2, 1, availableRow, rightCol, "left"))
        availableRow = availableRow + 1
        luis.insertElement(self.layerName, luis.newLabel("More specialists will become available as you progress.", rightWidth - 2, 2, availableRow, rightCol, "left"))
    end
end

function SpecialistManagementScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function SpecialistManagementScene:update(dt) end

function SpecialistManagementScene:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "soc_view"})
        return true
    end
end

function SpecialistManagementScene:mousepressed(x, y, button) end

return SpecialistManagementScene