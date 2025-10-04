--[[ 
    Admin Incident Scene
    This is a self-contained scene file that follows the original, working architecture.
]]

local AdminIncidentScene = {}
AdminIncidentScene.__index = AdminIncidentScene

function AdminIncidentScene.new(eventBus, luis, systems)
    local self = setmetatable({}, AdminIncidentScene)
    self.eventBus = eventBus
    self.luis = luis
    self.systems = systems
    self.layerName = "admin_incident"

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
        TextInput = {
            bgColor = {0, 0, 0, 0.7},
            textColor = {0, 1, 180/255, 1},
            borderColor = {0, 1, 180/255, 0.4},
            cursorColor = {0, 1, 180/255, 1},
        }
    }
    if self.luis.setTheme then
        self.luis.setTheme(cyberpunkTheme)
    end

    self.console_output = {"Welcome to the Incident Admin Console.", "Type 'help' for a list of commands."}
    self.console_input = ""
    return self
end

function AdminIncidentScene:load(data)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end

function AdminIncidentScene:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function AdminIncidentScene:buildUI()
    local luis = self.luis
    local numCols = math.floor(love.graphics.getWidth() / luis.gridSize)
    local numRows = math.floor(love.graphics.getHeight() / luis.gridSize)

    local helpText = "INCIDENT ADMINISTRATION TERMINAL. Type commands below. Press ESC to return to main menu."
    luis.insertElement(self.layerName, luis.newLabel(helpText, numCols - 4, 3, 2, 3))

    local output_text = table.concat(self.console_output, "\n")
    local consoleOutputHeight = numRows - 12
    self.consoleOutputLabel = luis.newLabel(output_text, numCols - 4, consoleOutputHeight, 5, 3)
    luis.insertElement(self.layerName, self.consoleOutputLabel)

    local inputRow = numRows - 5
    self.consoleInput = luis.newTextInput(numCols - 4, 3, ">", function(new_text)
        self.console_input = new_text
    end, inputRow, 3)
    luis.insertElement(self.layerName, self.consoleInput)
end

function AdminIncidentScene:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
    elseif key == "return" or key == "kpenter" then
        local command = self.console_input
        table.insert(self.console_output, "> " .. command)

        self:processCommand(command)

        self.console_input = ""
        self.consoleInput:setText("")
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

function AdminIncidentScene:draw()
    love.graphics.clear(0.05, 0.05, 0.1, 1.0)
end

function AdminIncidentScene:update(dt) end
function AdminIncidentScene:mousepressed(x, y, button) end

return AdminIncidentScene