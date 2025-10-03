-- UI Component for displaying player resources

local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Box = require("src.ui.components.box")
local format = require("src.utils.format")

local ResourcePanel = setmetatable({}, {__index = Panel})
ResourcePanel.__index = ResourcePanel

function ResourcePanel.new(props)
    props = props or {}
    props.title = "BUSINESS RESOURCES"
    
    local self = Panel.new(props)
    setmetatable(self, ResourcePanel)
    
    self.resourceManager = props.resourceManager
    self.theme = props.theme

    -- Create text components for each resource
    self.resourceTexts = {}
    local resourcesToDisplay = {"money", "reputation", "xp", "missionTokens"}

    for _, resourceName in ipairs(resourcesToDisplay) do
        local row = Box.new({direction = "horizontal", justify = "space-between"})

        local label = Text.new({text = resourceName:upper() .. ":", color = self.theme:getColor("secondary")})
        local value = Text.new({text = "0", color = self.theme:getColor("success")})
        
        row:addChild(label)
        row:addChild(value)
        self:addChild(row)

        self.resourceTexts[resourceName] = {
            label = label,
            value = value,
            row = row
        }
    end

    self:update() -- Initial update
    
    return self
end

function ResourcePanel:update()
    if not self.resourceManager then return end

    local resources = self.resourceManager:getAllResources()

    -- Budget
    if self.resourceTexts.money then
        self.resourceTexts.money.value:setText("$" .. format.number(resources.money or 0, 0))
        self.resourceTexts.money.value.props.color = self.theme:getColor("success")
    end

    -- Reputation
    if self.resourceTexts.reputation then
        self.resourceTexts.reputation.value:setText(format.number(resources.reputation or 0, 0) .. " pts")
        self.resourceTexts.reputation.value.props.color = self.theme:getColor("accent")
    end

    -- Experience
    if self.resourceTexts.xp then
        self.resourceTexts.xp.value:setText(format.number(resources.xp or 0, 0) .. " XP")
        self.resourceTexts.xp.value.props.color = self.theme:getColor("primary")
    end

    -- Mission Tokens
    if self.resourceTexts.missionTokens then
        local tokens = resources.missionTokens or 0
        self.resourceTexts.missionTokens.value:setText(format.number(tokens, 0))
        self.resourceTexts.missionTokens.value.props.color = self.theme:getColor("warning")
        -- Hide the row if there are no tokens
        self.resourceTexts.missionTokens.row:setVisible(tokens > 0)
    end

    self:invalidateLayout()
end

return ResourcePanel
