--[[ 
    Admin Incident Scene
    --------------------
    This scene provides a debug/admin interface for interacting with the incident system.
    It features a console-like interface for viewing incident data and entering commands.
]]

local BaseSceneLuis = require("src.scenes.base_scene_luis")

local AdminIncidentScene = {}
AdminIncidentScene.__index = AdminIncidentScene
setmetatable(AdminIncidentScene, {__index = BaseSceneLuis})


function AdminIncidentScene.new(eventBus, luis)
    local self = BaseSceneLuis.new(eventBus, luis, "admin_incident")
    setmetatable(self, AdminIncidentScene)

    -- Use the same cyberpunk theme for a consistent look and feel.
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
        -- Custom theme for the console input/output
        TextInput = {
            bgColor = {0, 0, 0, 0.7},
            textColor = {0, 1, 180/255, 1},
            borderColor = {0, 1, 180/255, 0.4},
            cursorColor = {0, 1, 180/255, 1},
        }
    }
    self:setTheme(cyberpunkTheme)

    -- Console state
    self.console_output = {"Welcome to the Incident Admin Console.", "Type 'help' for a list of commands."}
    self.console_input = ""

    return self
end


function AdminIncidentScene:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local gridSize = luis.gridSize
    local numCols = math.floor(screenWidth / gridSize)
    local numRows = math.floor(screenHeight / gridSize)

    -- Row 1: Incident information/help
    local helpText = "INCIDENT ADMINISTRATION TERMINAL. Type commands below. Press ESC to return to main menu."
    local helpLabel = luis.newLabel(helpText, numCols - 4, 3, 2, 3)
    luis.insertElement(self.layerName, helpLabel)

    -- Rows 2 & 3: An active console for player input
    -- For this, we'll use a multi-line text input for the output, and a single-line for the input.
    
    -- Console Output (read-only)
    -- We'll simulate a read-only text area by using a label with a background.
    -- A true read-only TextInput is not specified in the docs, so this is a safe approach.
    local output_text = table.concat(self.console_output, "\n")
    -- The height is calculated to span from near the top to just above the input line.
    local consoleOutputHeight = numRows - 12
    self.consoleOutputLabel = luis.newLabel(output_text, numCols - 4, consoleOutputHeight, 5, 3)
    luis.insertElement(self.layerName, self.consoleOutputLabel)

    -- Console Input
    local inputRow = numRows - 5
    self.consoleInput = luis.newTextInput(numCols - 4, 3, ">", function(new_text)
        self.console_input = new_text
    end, inputRow, 3)
    luis.insertElement(self.layerName, self.consoleInput)

    print("🎨 Admin Incident Scene UI built.")
end

function AdminIncidentScene:onUpdate(dt)
    -- In a real implementation, we would process commands here.
end

function AdminIncidentScene:onDraw()
    -- The base scene is enough, we just need a background color.
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

-- We need to handle keypresses to submit commands and close the scene.
function AdminIncidentScene:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
    elseif key == "return" or key == "kpenter" then
        -- User submitted a command
        local command = self.console_input
        table.insert(self.console_output, "> " .. command)
        
        -- Process the command
        self:processCommand(command)

        -- Clear the input field
        self.console_input = ""
        self.consoleInput:setText("") -- Assuming the text input object has a setText method.
        self.consoleOutputLabel:setText(table.concat(self.console_output, "\n"))
    end
end

function AdminIncidentScene:processCommand(command)
    local cmd_parts = {}
    for part in string.gmatch(command, "[^%s]+") do
        table.insert(cmd_parts, part)
    end
    local base_cmd = cmd_parts[1]

    if base_cmd == "help" then
        table.insert(self.console_output, "Available commands:")
        table.insert(self.console_output, "  - help: Show this message")
        table.insert(self.console_output, "  - clear: Clear the console")
        table.insert(self.console_output, "  - incidents: List active incidents (not implemented)")
    elseif base_cmd == "clear" then
        self.console_output = {"Console cleared."}
    else
        table.insert(self.console_output, string.format("Unknown command: '%s'. Type 'help' for commands.", command))
    end
end

return AdminIncidentScene
