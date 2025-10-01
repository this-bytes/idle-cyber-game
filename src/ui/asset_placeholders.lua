-- Not implemented: src/ui/asset_placeholders.lua
-- ======================================================================
-- This module provides small embedded PNG placeholders (base64) and returns Love Image objects.
-- Useful for UI elements that need image assets but where actual images are not yet available.
-- ======================================================================


local M = {}

-- Tiny 1x1 transparent PNG (base64)
local TRANSPARENT_PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII="

-- Base64 decode (simple implementation)
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function decode_base64(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i - f%2^(i-1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0 for i=1,8 do c=c + (x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- Create a Love Image from base64 PNG bytes
local function imageFromBase64(b64, name)
    if not love or not love.filesystem or not love.image or not love.graphics then
        return nil
    end
    local bytes = decode_base64(b64)
    -- Create FileData from string of bytes
    local fileData = love.filesystem.newFileData(bytes, name or "placeholder.png")
    local ok, imgData = pcall(love.image.newImageData, fileData)
    if not ok or not imgData then return nil end
    local ok2, img = pcall(love.graphics.newImage, imgData)
    if not ok2 then return nil end
    return img
end

local cache = {}

function M.getImages()
    if cache.player and cache.dept then
        return cache.player, cache.dept
    end
    -- For now both placeholders use the tiny transparent PNG so they are neutral placeholders
    local playerImg = imageFromBase64(TRANSPARENT_PNG, "player_placeholder.png")
    local deptImg = imageFromBase64(TRANSPARENT_PNG, "dept_placeholder.png")
    cache.player = playerImg
    cache.dept = deptImg
    return playerImg, deptImg
end

return M
