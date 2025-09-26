-- Utility: write placeholder PNGs if missing
-- This is a minimal writer using the love filesystem binary write. The PNGs are tiny 16x16 solid-color images encoded as raw PNG bytes (precomputed).

local M = {}

-- Two tiny 16x16 PNGs (blue for player, gray for department)
local playerPng = "\137PNG\13\10\26\10\0\0\0\rIHDR\0\0\0\16\0\0\0\16\8\2\0\0\0\x1f\x15\xc4\x89\0\0\0\x0cIDAT\x08\x99c\xfc\xff\xff?\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x00\x07\x8d\x02\xf5\xab\x1c\x02\x00\x00\x00\x00IEND\xaeB`\x82"
local deptPng = "\137PNG\13\10\26\10\0\0\0\rIHDR\0\0\0\16\0\0\0\16\8\2\0\0\0\x1f\x15\xc4\x89\0\0\0\x0cIDAT\x08\x99c\xf8\xff\xff?\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x00\x07\x8d\x02\xf5\xab\x1c\x02\x00\x00\x00\x00IEND\xaeB`\x82"

function M.ensure()
    if not love.filesystem.getInfo("assets/player.png") then
        local ok, err = love.filesystem.write("assets/player.png", playerPng)
        if not ok then print("❌ Failed to write player placeholder:", err) end
    end
    if not love.filesystem.getInfo("assets/department.png") then
        local ok, err = love.filesystem.write("assets/department.png", deptPng)
        if not ok then print("❌ Failed to write department placeholder:", err) end
    end
end

return M
