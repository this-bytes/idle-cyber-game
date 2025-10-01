-- Smart UI Framework Demo
-- Demonstrates all core components with interactive examples

local Panel = require("src.ui.components.panel")
local Box = require("src.ui.components.box")
local Grid = require("src.ui.components.grid")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")
local ScrollContainer = require("src.ui.components.scroll_container")

local UIDemo = {}
UIDemo.__index = UIDemo

function UIDemo.new()
    local self = setmetatable({}, UIDemo)
    
    -- Content container (can grow beyond viewport)
    self.content = Box.new({
        direction = "vertical",
        gap = 20,
        padding = {20, 20, 20, 20}
    })
    
    -- Scrollable viewport
    self.root = ScrollContainer.new({
        backgroundColor = {0.05, 0.05, 0.1, 1},
        showScrollbars = true,
        scrollSpeed = 30
    })
    
    self.root:addChild(self.content)
    
    -- Create demo sections
    self:createHeader()
    self:createPanelDemo()
    self:createGridDemo()
    self:createButtonDemo()
    self:createFlexDemo()
    
    return self
end

-- Header section
function UIDemo:createHeader()
    local header = Panel.new({
        title = "SMART UI FRAMEWORK - DEMO",
        titleAlign = "center",
        cornerStyle = "cut",
        cornerSize = 12,
        glow = true,
        glowColor = {0, 1, 1, 0.2},
        glowSize = 3,
        minWidth = 984,
        minHeight = 80
    })
    
    local subtitle = Text.new({
        text = "Production-Ready Component System with Automatic Layout",
        color = {0.7, 0.7, 0.7, 1},
        fontSize = 12,
        textAlign = "center",
        padding = {8, 0, 8, 0}
    })
    
    header:addChild(subtitle)
    self.content:addChild(header)
end

-- Panel demo with various styles
function UIDemo:createPanelDemo()
    local container = Box.new({
        direction = "horizontal",
        gap = 10,
        minWidth = 984
    })
    
    -- Square panel
    local squarePanel = Panel.new({
        title = "SQUARE PANEL",
        cornerStyle = "square",
        minWidth = 240,
        minHeight = 120
    })
    
    squarePanel:addChild(Text.new({
        text = "Classic square corners\nwith solid borders",
        color = {0.8, 0.8, 0.8, 1},
        fontSize = 11,
        wrap = true,
        padding = {4, 4, 4, 4}
    }))
    
    -- Rounded panel
    local roundedPanel = Panel.new({
        title = "ROUNDED PANEL",
        cornerStyle = "rounded",
        cornerSize = 8,
        minWidth = 240,
        minHeight = 120
    })
    
    roundedPanel:addChild(Text.new({
        text = "Smooth rounded corners\nfor modern aesthetics",
        color = {0.8, 0.8, 0.8, 1},
        fontSize = 11,
        wrap = true,
        padding = {4, 4, 4, 4}
    }))
    
    -- Cut corners panel (cyberpunk)
    local cutPanel = Panel.new({
        title = "CUT PANEL",
        cornerStyle = "cut",
        cornerSize = 10,
        glow = true,
        minWidth = 240,
        minHeight = 120
    })
    
    cutPanel:addChild(Text.new({
        text = "Cyberpunk cut corners\nwith neon glow effect",
        color = {0.8, 0.8, 0.8, 1},
        fontSize = 11,
        wrap = true,
        padding = {4, 4, 4, 4}
    }))
    
    -- Shadow panel
    local shadowPanel = Panel.new({
        title = "SHADOW PANEL",
        shadow = true,
        shadowOffset = {4, 4},
        minWidth = 240,
        minHeight = 120
    })
    
    shadowPanel:addChild(Text.new({
        text = "Panel with drop shadow\nfor depth perception",
        color = {0.8, 0.8, 0.8, 1},
        fontSize = 11,
        wrap = true,
        padding = {4, 4, 4, 4}
    }))
    
    container:addChild(squarePanel)
    container:addChild(roundedPanel)
    container:addChild(cutPanel)
    container:addChild(shadowPanel)
    
    self.content:addChild(container)
end

-- Grid layout demo
function UIDemo:createGridDemo()
    local gridPanel = Panel.new({
        title = "GRID LAYOUT - DATA TABLE",
        cornerStyle = "cut",
        minWidth = 984,
        minHeight = 200
    })
    
    local grid = Grid.new({
        columns = 4,
        columnGap = 8,
        rowGap = 4,
        cellBorderColor = {0, 0.5, 0.5, 0.5},
        cellBorderWidth = 1,
        padding = {8, 8, 8, 8}
    })
    
    -- Header row
    local headers = {"SPECIALIST", "ROLE", "LEVEL", "STATUS"}
    for _, header in ipairs(headers) do
        grid:addChild(Text.new({
            text = header,
            color = {0, 1, 1, 1},
            fontSize = 12,
            bold = true,
            padding = {4, 4, 4, 4}
        }))
    end
    
    -- Data rows
    local data = {
        {"Alice Chen", "SOC Analyst", "12", "ACTIVE"},
        {"Bob Martinez", "Threat Hunter", "15", "ACTIVE"},
        {"Carol Kim", "Forensics", "8", "BREAK"},
        {"Dave Johnson", "Incident Resp", "20", "ACTIVE"}
    }
    
    for _, row in ipairs(data) do
        for i, cell in ipairs(row) do
            local color = {0.8, 0.8, 0.8, 1}
            if cell == "ACTIVE" then
                color = {0, 1, 0, 1}
            elseif cell == "BREAK" then
                color = {1, 0.8, 0, 1}
            end
            
            grid:addChild(Text.new({
                text = cell,
                color = color,
                fontSize = 11,
                padding = {4, 4, 4, 4}
            }))
        end
    end
    
    gridPanel:addChild(grid)
    self.content:addChild(gridPanel)
end

-- Button demo with various states
function UIDemo:createButtonDemo()
    local buttonPanel = Panel.new({
        title = "INTERACTIVE BUTTONS",
        cornerStyle = "rounded",
        minWidth = 984,
        minHeight = 120
    })
    
    local buttonBox = Box.new({
        direction = "horizontal",
        gap = 12,
        padding = {8, 8, 8, 8},
        justify = "space-around"
    })
    
    -- Normal button
    local normalBtn = Button.new({
        label = "DEPLOY",
        cornerStyle = "cut",
        onClick = function(btn)
            print("Deploy button clicked!")
        end
    })
    
    -- Hover effect button
    local hoverBtn = Button.new({
        label = "INVESTIGATE",
        cornerStyle = "rounded",
        hoverColor = {0.2, 0.6, 0.8, 1},
        onClick = function(btn)
            print("Investigate button clicked!")
        end
    })
    
    -- Disabled button
    local disabledBtn = Button.new({
        label = "LOCKED",
        enabled = false,
        cornerStyle = "square"
    })
    
    -- Critical action button
    local criticalBtn = Button.new({
        label = "QUARANTINE",
        normalColor = {0.6, 0.1, 0.1, 1},
        hoverColor = {0.8, 0.2, 0.2, 1},
        pressColor = {0.4, 0.05, 0.05, 1},
        normalBorderColor = {1, 0, 0, 1},
        hoverBorderColor = {1, 0.3, 0.3, 1},
        cornerStyle = "cut",
        onClick = function(btn)
            print("QUARANTINE INITIATED!")
        end
    })
    
    buttonBox:addChild(normalBtn)
    buttonBox:addChild(hoverBtn)
    buttonBox:addChild(disabledBtn)
    buttonBox:addChild(criticalBtn)
    
    buttonPanel:addChild(buttonBox)
    self.content:addChild(buttonPanel)
end

-- Flexbox demo with various layouts
function UIDemo:createFlexDemo()
    local flexPanel = Panel.new({
        title = "FLEX LAYOUT - RESOURCE BARS",
        cornerStyle = "cut",
        minWidth = 984,
        minHeight = 140
    })
    
    local flexBox = Box.new({
        direction = "vertical",
        gap = 8,
        padding = {8, 8, 8, 8}
    })
    
    -- Create resource bars
    local resources = {
        {name = "CREDITS", value = "24,500", color = {1, 0.8, 0, 1}},
        {name = "REPUTATION", value = "850/1000", color = {0, 1, 0.5, 1}},
        {name = "MISSION TOKENS", value = "12", color = {1, 0, 1, 1}}
    }
    
    for _, resource in ipairs(resources) do
        local row = Box.new({
            direction = "horizontal",
            gap = 12,
            align = "center"
        })
        
        -- Label
        row:addChild(Text.new({
            text = resource.name,
            color = {0.7, 0.7, 0.7, 1},
            fontSize = 11,
            minWidth = 150
        }))
        
        -- Bar background
        local barBg = Box.new({
            backgroundColor = {0.1, 0.1, 0.15, 1},
            borderColor = {0.3, 0.3, 0.4, 1},
            borderWidth = 1,
            minWidth = 400,
            minHeight = 20,
            flex = 1
        })
        
        -- Bar fill
        local barFill = Box.new({
            backgroundColor = resource.color,
            minWidth = math.random(100, 380),
            minHeight = 18
        })
        
        barBg:addChild(barFill)
        row:addChild(barBg)
        
        -- Value
        row:addChild(Text.new({
            text = resource.value,
            color = resource.color,
            fontSize = 12,
            bold = true,
            minWidth = 100,
            textAlign = "right"
        }))
        
        flexBox:addChild(row)
    end
    
    flexPanel:addChild(flexBox)
    self.content:addChild(flexPanel)
end

-- Initialize the demo (call measure and layout)
function UIDemo:init(width, height)
    width = width or 1024
    height = height or 768
    
    -- Measure and layout the entire UI tree
    self.root:measure(width, height)
    self.root:layout(0, 0, width, height)
end

-- Resize handler
function UIDemo:resize(width, height)
    self:init(width, height)
end

-- Update (for animations, interactions)
function UIDemo:update(dt)
    self.root:update(dt)
end

-- Render the entire UI
function UIDemo:render()
    self.root:render()
end

-- Handle mouse movement
function UIDemo:mouseMoved(x, y)
    self.root:onMouseMove(x, y)
end

-- Handle mouse clicks
function UIDemo:mouseClicked(x, y, button)
    self.root:onMouseClick(x, y, button)
end

-- Handle mouse press
function UIDemo:mousePressed(x, y, button)
    self.root:onMousePress(x, y, button)
end

-- Handle mouse release
function UIDemo:mouseReleased(x, y, button)
    self.root:onMouseRelease(x, y, button)
end

-- Handle mouse wheel (for scrolling)
function UIDemo:mouseWheel(x, y)
    self.root:onMouseWheel(x, y)
end

return UIDemo
