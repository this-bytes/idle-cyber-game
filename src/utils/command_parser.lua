-- Command Parser Utility
-- A simple utility to parse text-based commands from the player.

local CommandParser = {}

function CommandParser.parse(input)
    if not input or input == "" then
        return nil
    end

    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end

    if #parts == 0 then
        return nil
    end

    local command = table.remove(parts, 1):lower()
    local args = parts

    return {
        command = command,
        args = args
    }
end

return CommandParser
