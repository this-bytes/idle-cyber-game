-- Utility: write placeholder PNGs if missing (archived)

local M = {}

local playerPng = "\137PNG\13\10\26\10\0\0\0\rIHDR\0\0\0\16\0\0\0\16\8\2\0\0\0\x1f\x15\xc4\x89\0\0\0\x0cIDAT\x08\x99c\xfc\xff\xff?\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x00\x07\x8d\x02\xf5\xab\x1c\x02\x00\x00\x00\x00IEND\xaeB`\x82"
local deptPng = "\137PNG\13\10\26\10\0\0\0\rIHDR\0\0\0\16\0\0\0\16\8\2\0\0\0\x1f\x15\xc4\x89\0\0\0\x0cIDAT\x08\x99c\xf8\xff\xff?\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x00\x07\x8d\x02\xf5\xab\x1c\x02\x00\x00\x00\x00IEND\xaeB`\x82"

function M.ensure()
    if love and love.filesystem and not love.filesystem.getInfo("assets/player.png") then
        love.filesystem.write("assets/player.png", playerPng)
    end
    if love and love.filesystem and not love.filesystem.getInfo("assets/department.png") then
        love.filesystem.write("assets/department.png", deptPng)
    end
end

return M
