--[[
    Skill Tree Scene
    This is a self-contained scene file that follows the original, working architecture.
]]

local SkillTreeScene = {}
SkillTreeScene.__index = SkillTreeScene

function SkillTreeScene.new(eventBus, luis, systems)
    local self = setmetatable({}, SkillTreeScene)
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "skill_tree"

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

    self.skills = {}
    self.categories = {}
    return self
end

function SkillTreeScene:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:updateSkills()
end

function SkillTreeScene:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function SkillTreeScene:updateSkills()
    if self.systems and self.systems.skillSystem and self.systems.skillSystem.getSkillTree then
        self.skills = self.systems.skillSystem:getSkillTree()
        self:categorizeSkills()
    else
        print("WARNING: Could not fetch skills from skillSystem.")
    end
    self:rebuildUI()
end

function SkillTreeScene:categorizeSkills()
    self.categories = {}
    for id, skill in pairs(self.skills) do
        local cat = skill.category or "uncategorized"
        if not self.categories[cat] then
            self.categories[cat] = {}
        end
        table.insert(self.categories[cat], skill)
    end
end

function SkillTreeScene:rebuildUI()
    if not self.luis then return end
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end

function SkillTreeScene:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)

    luis.insertElement(self.layerName, luis.newLabel("SKILL TREE", numCols, 3, 2, 1, "center"))
    luis.insertElement(self.layerName, luis.newButton("< BACK", 15, 3, function() 
        self.eventBus:publish("request_scene_change", {scene = "soc_view"}) 
    end, nil, 2, 3))

    if not self.skills or next(self.skills) == nil then
        luis.insertElement(self.layerName, luis.newLabel("No skills available.", numCols, 3, 10, 1, "center"))
    else
        self:buildSkillList()
    end
end

function SkillTreeScene:buildSkillList()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local startCol = 6
    local numCats = 0
    for _ in pairs(self.categories) do numCats = numCats + 1 end
    local colWidth = math.floor((numCols - (startCol * 2)) / numCats)
    local currentCol = startCol

    for categoryName, skillsInCategory in pairs(self.categories) do
        luis.insertElement(self.layerName, luis.newLabel(string.upper(categoryName), colWidth, 2, 6, currentCol, "center"))
        local currentRow = 9

        for _, skill in ipairs(skillsInCategory) do
            local level = self.systems.skillSystem:getSkillLevel(skill.id)
            local cost = self.systems.skillSystem:getSkillLevelUpCost(skill.id)
            local canAfford = self.systems.resourceManager:hasSufficientResources({xp = cost})

            local levelText = string.format("%s [%d/%d]", skill.name, level, skill.maxLevel)
            luis.insertElement(self.layerName, luis.newLabel(levelText, colWidth - 2, 1, currentRow, currentCol, "left"))
            currentRow = currentRow + 1
            luis.insertElement(self.layerName, luis.newLabel(skill.description, colWidth - 2, 2, currentRow, currentCol, "left"))
            currentRow = currentRow + 2
            luis.insertElement(self.layerName, luis.newLabel("Cost: " .. cost .. " XP", colWidth - 2, 1, currentRow, currentCol, "left"))

            local button = luis.newButton("LEVEL UP", 15, 2, function() 
                if canAfford then
                    self.systems.skillSystem:levelUpSkill(skill.id)
                    self:updateSkills()
                end
            end, nil, currentRow - 1, currentCol + colWidth - 18)
            
            if not canAfford or level >= skill.maxLevel then
                button:setDisabled(true)
            end
            luis.insertElement(self.layerName, button)

            currentRow = currentRow + 4
        end
        currentCol = currentCol + colWidth
    end
end

function SkillTreeScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function SkillTreeScene:update(dt) end
function SkillTreeScene:keypressed(key) end
function SkillTreeScene:mousepressed(x, y, button) end

return SkillTreeScene