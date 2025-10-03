-- Test file for ResourcePanel component

local ResourcePanel = require("src.ui.components.resource_panel")
local EventBus = require("src.utils.event_bus")

-- Mock ResourceManager
local MockResourceManager = {}
MockResourceManager.__index = MockResourceManager
function MockResourceManager.new()
    local self = setmetatable({}, MockResourceManager)
    self.resources = {
        money = 1000,
        reputation = 50,
        xp = 250,
        missionTokens = 0
    }
    return self
end
function MockResourceManager:getAllResources()
    return self.resources
end

function MockResourceManager:setResource(name, value)
    self.resources[name] = value
end

-- Mock Theme
local MockTheme = {}
function MockTheme:getColor(name)
    return {1, 1, 1, 1} -- Just return white for all
end

TestRunner.test("ResourcePanel - Initialization", function()
    local resourceManager = MockResourceManager.new()
    local theme = MockTheme

    local panel = ResourcePanel.new({resourceManager = resourceManager, theme = theme})

    TestRunner.assertNotNil(panel, "Panel should initialize")
    TestRunner.assertEqual(panel.props.title, "BUSINESS RESOURCES", "Panel title should be set")
    TestRunner.assertNotNil(panel.resourceTexts.money, "Should create text for money")
    TestRunner.assertNotNil(panel.resourceTexts.reputation, "Should create text for reputation")
end)

TestRunner.test("ResourcePanel - Update", function()
    local resourceManager = MockResourceManager.new()
    local theme = MockTheme

    local panel = ResourcePanel.new({resourceManager = resourceManager, theme = theme})

    panel:update()

    -- Initial values
    TestRunner.assertContains(panel.resourceTexts.money.value.props.text, "1000", "Initial money should be formatted")
    TestRunner.assertContains(panel.resourceTexts.reputation.value.props.text, "50", "Initial reputation should be set")

    -- Change resource values
    resourceManager.resources.money = 2500000
    resourceManager.resources.reputation = 125

    panel:update()

    TestRunner.assertContains(panel.resourceTexts.money.value.props.text, "2500000", "Updated money should be formatted with suffix")
    TestRunner.assertContains(panel.resourceTexts.reputation.value.props.text, "125", "Updated reputation should be set")
end)

TestRunner.test("ResourcePanel - Mission Tokens Visibility", function()
    local resourceManager = MockResourceManager.new()
    local theme = MockTheme

    local panel = ResourcePanel.new({resourceManager = resourceManager, theme = theme})

    -- Should be invisible when 0
    TestRunner.assertEqual(panel.resourceTexts.missionTokens.row.visible, false, "Mission token row should be invisible when tokens are 0")

    -- Change resource value
    resourceManager.resources.missionTokens = 5
    panel:update()

    TestRunner.assertEqual(panel.resourceTexts.missionTokens.row.visible, true, "Mission token row should be visible when tokens are > 0")
end)