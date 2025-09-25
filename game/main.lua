-- Cyberspace Tycoon - Idle Cybersecurity Game
-- Resource Display System Implementation

-- Game modules
local resources = require("resources")
local resourceDisplay = require("display")
local shop = require("shop")
local threats = require("threats")
local adminMode = require("admin_mode")
local format = require("format")

-- Game state
local gameState = {
    initialized = false,
    paused = false,
    showFPS = false,
    debugMode = false,
}

-- Performance tracking
local performance = {
    frameCount = 0,
    fps = 0,
    lastFPSUpdate = 0,
    updateTime = 0,
    drawTime = 0,
}

-- Initialize the game
function love.load()
    -- Set up LÖVE 2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Cyberspace Tycoon - Idle Cybersecurity Game")
    
    -- Set window size to be reasonable
    love.window.setMode(1024, 768, {resizable=true, minwidth=800, minheight=600})
    
    -- Initialize game systems with error handling
    local success, error_msg = pcall(function()
        resources.init()
        resourceDisplay.init()
        shop.init()
        threats.init()
        adminMode.init()
        
        -- Try to load saved game
        loadGame()
    end)
    
    if not success then
        print("Error during initialization: " .. tostring(error_msg))
        -- Continue with default values
    end
    
    gameState.initialized = true
    
    print("=== Cyberspace Tycoon ===")
    print("🚀 Welcome to the cybersecurity empire!")
    print("💡 Click on resources to earn Data Bits!")
    print("⌨️  Controls:")
    print("   A - The Admin's Watch (Real-time mode)")
    print("   U - Upgrades shop")
    print("   S - Detailed stats")
    print("   F - FPS display")
    print("   D - Debug mode")
    print("   P - Pause game")
    print("   C - Compact display")
    print("   F5 - Save game, F9 - Load game")
    print("   ESC - Quit")
end

-- Update game logic
function love.update(dt)
    if not gameState.initialized or gameState.paused then
        return
    end
    
    local updateStart = love.timer.getTime()
    
    -- Update game systems
    resources.update(dt)
    resourceDisplay.update(dt)
    shop.update(dt)
    threats.update(dt)
    adminMode.update(dt)
    
    -- Auto-save system
    autoSaveTimer = autoSaveTimer + dt
    if autoSaveTimer >= AUTO_SAVE_INTERVAL then
        autoSaveTimer = 0
        saveGame()
    end
    
    -- Update performance tracking
    performance.updateTime = love.timer.getTime() - updateStart
    performance.frameCount = performance.frameCount + 1
    
    -- Update FPS counter
    local currentTime = love.timer.getTime()
    if currentTime - performance.lastFPSUpdate >= 1.0 then
        performance.fps = performance.frameCount
        performance.frameCount = 0
        performance.lastFPSUpdate = currentTime
    end
end

-- Render the game
function love.draw()
    if not gameState.initialized then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Loading...", 10, 10)
        return
    end
    
    local drawStart = love.timer.getTime()
    
    -- Clear screen with dark background
    love.graphics.clear(0.05, 0.05, 0.1, 1)
    
    -- Draw Admin's Watch interface (if active)
    if adminMode.isActive() then
        adminMode.draw()
    else
        -- Draw regular idle game interface
        -- Draw resource display system
        resourceDisplay.draw()
        
        -- Draw shop system
        shop.draw()
        
        -- Draw shop toggle button
        if not shop.isOpen() then
            drawShopButton()
        end
        
        -- Draw mode toggle button
        drawAdminModeButton()
    end
    
    -- Draw debug information
    if gameState.showFPS or gameState.debugMode then
        drawDebugInfo()
    end
    
    performance.drawTime = love.timer.getTime() - drawStart
end

-- Handle mouse input
function love.mousepressed(x, y, button, istouch, presses)
    if not gameState.initialized then
        return
    end
    
    -- Let Admin's Watch mode handle clicks first (if active)
    if adminMode.mousepressed(x, y, button) then
        return -- Click was handled by admin mode
    end
    
    -- Let the shop handle clicks first (if open)
    if shop.mousepressed(x, y, button) then
        return -- Click was handled by shop system
    end
    
    -- Check for admin mode button click
    if checkAdminModeButtonClick(x, y) then
        return -- Admin mode button was clicked
    end
    
    -- Check for shop button click
    if checkShopButtonClick(x, y) then
        return -- Shop button was clicked
    end
    
    -- Let the resource display handle clicks
    if resourceDisplay.mousepressed(x, y, button) then
        return -- Click was handled by display system
    end
end

-- Handle keyboard input
function love.keypressed(key)
    -- Let Admin's Watch mode handle keys first
    if adminMode.keypressed(key) then
        return -- Key was handled by admin mode
    end
    
    if key == "escape" then
        love.event.quit()
    elseif key == "s" then
        resourceDisplay.toggleDetailedStats()
    elseif key == "f" then
        gameState.showFPS = not gameState.showFPS
    elseif key == "d" then
        gameState.debugMode = not gameState.debugMode
    elseif key == "c" then
        resourceDisplay.toggleCompactMode()
    elseif key == "p" then
        gameState.paused = not gameState.paused
        print(gameState.paused and "⏸️  Game paused" or "▶️  Game resumed")
    elseif key == "r" and gameState.debugMode then
        -- Debug: reset game state
        resources.init()
        resourceDisplay.init()
        print("🔄 Game state reset!")
    elseif key == "space" then
        -- Alternative click method (accessibility)
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        resourceDisplay.mousepressed(screenW / 2, screenH / 2, 1)
    elseif key == "u" then
        -- Toggle shop
        shop.toggle()
    elseif key == "f5" then
        -- Manual save
        saveGame()
    elseif key == "f9" then
        -- Manual load
        loadGame()
        resourceDisplay.init()  -- Refresh display
    end
end

-- Draw debug information
function drawDebugInfo()
    local y = love.graphics.getHeight() - 120
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    
    -- Performance info
    if gameState.showFPS then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("FPS: " .. performance.fps, 10, y)
        y = y + 15
        
        if gameState.debugMode then
            love.graphics.print("Update: " .. string.format("%.2fms", performance.updateTime * 1000), 10, y)
            y = y + 15
            love.graphics.print("Draw: " .. string.format("%.2fms", performance.drawTime * 1000), 10, y)
            y = y + 15
        end
    end
    
    -- Debug info
    if gameState.debugMode then
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local currentResources = resources.getResources()
        local generation = resources.getGeneration()
        
        love.graphics.print("=== DEBUG INFO ===", 10, y)
        y = y + 15
        love.graphics.print("Raw DB: " .. string.format("%.6f", currentResources.dataBits), 10, y)
        y = y + 15
        love.graphics.print("Raw PP: " .. string.format("%.6f", currentResources.processingPower), 10, y)
        y = y + 15
        love.graphics.print("Raw SR: " .. string.format("%.6f", currentResources.securityRating), 10, y)
        y = y + 15
        love.graphics.print("DB/sec: " .. string.format("%.6f", generation.dataBits), 10, y)
        y = y + 15
        
        local clickInfo = resources.getClickInfo()
        love.graphics.print("Click Power: " .. clickInfo.power, 10, y)
        y = y + 15
        love.graphics.print("Combo: " .. string.format("%.2f", clickInfo.combo), 10, y)
    end
end

-- Handle window resize
function love.resize(w, h)
    -- Resource display will automatically adapt to new screen size
end

-- Draw shop toggle button
function drawShopButton()
    local screenW = love.graphics.getWidth()
    local buttonW = 120
    local buttonH = 40
    local x = screenW - buttonW - 20
    local y = 20
    
    -- Button background
    love.graphics.setColor(0.2, 0.4, 0.6, 0.9)
    love.graphics.rectangle("fill", x, y, buttonW, buttonH)
    
    -- Button border
    love.graphics.setColor(0.4, 0.6, 0.8, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, buttonW, buttonH)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local text = "Upgrades (U)"
    local textW = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, x + (buttonW - textW) / 2, y + 10)
end

-- Draw Admin's Watch toggle button
function drawAdminModeButton()
    local screenW = love.graphics.getWidth()
    local buttonW = 150
    local buttonH = 40
    local x = screenW - buttonW - 20
    local y = 70  -- Below the shop button
    
    -- Button background
    if adminMode.isActive() then
        love.graphics.setColor(0.8, 0.4, 0.2, 0.8)  -- Orange when active
    else
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)  -- Dark when inactive
    end
    love.graphics.rectangle("fill", x, y, buttonW, buttonH)
    
    -- Button border
    love.graphics.setColor(0.4, 0.4, 0.5, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, buttonW, buttonH)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    local text = adminMode.isActive() and "🏢 Admin Mode (A)" or "🎯 Admin's Watch (A)"
    local textW = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, x + (buttonW - textW) / 2, y + 12)
end

-- Check if admin mode button was clicked
function checkAdminModeButtonClick(x, y)
    local screenW = love.graphics.getWidth()
    local buttonW = 150
    local buttonH = 40
    local buttonX = screenW - buttonW - 20
    local buttonY = 70
    
    if x >= buttonX and x <= buttonX + buttonW and y >= buttonY and y <= buttonY + buttonH then
        adminMode.toggle()
        return true
    end
    return false
end

-- Check if shop button was clicked
function checkShopButtonClick(x, y)
    local screenW = love.graphics.getWidth()
    local buttonW = 120
    local buttonH = 40
    local buttonX = screenW - buttonW - 20
    local buttonY = 20
    
    if x >= buttonX and x <= buttonX + buttonW and y >= buttonY and y <= buttonY + buttonH then
        shop.toggle()
        return true
    end
    return false
end

-- Save/Load functionality
function saveGame()
    local saveData = {
        resources = resources.save(),
        version = "0.1.0",
        timestamp = os.time()
    }
    
    local success, error_msg = pcall(function()
        local serialized = serialize(saveData)
        love.filesystem.write("savegame.lua", serialized)
        print("Game saved successfully!")
    end)
    
    if not success then
        print("Save failed: " .. tostring(error_msg))
    end
end

function loadGame()
    if love.filesystem.getInfo("savegame.lua") then
        local success, saveData = pcall(function()
            local saveString = love.filesystem.read("savegame.lua")
            return loadstring("return " .. saveString)()
        end)
        
        if success and saveData then
            if saveData.version and saveData.resources then
                resources.load(saveData.resources)
                print("Game loaded successfully! (saved " .. 
                      os.date("%Y-%m-%d %H:%M:%S", saveData.timestamp) .. ")")
            else
                print("Save file corrupted, starting fresh")
            end
        else
            print("Could not load save file, starting fresh")
        end
    end
end

-- Simple serialization for save data
function serialize(t)
    local result = "{"
    for k, v in pairs(t) do
        if type(v) == "table" then
            result = result .. k .. "=" .. serialize(v) .. ","
        elseif type(v) == "string" then
            result = result .. k .. "=\"" .. v .. "\","
        else
            result = result .. k .. "=" .. tostring(v) .. ","
        end
    end
    result = result .. "}"
    return result
end

-- Auto-save every 30 seconds
local autoSaveTimer = 0
local AUTO_SAVE_INTERVAL = 30

-- Clean shutdown
function love.quit()
    print("💾 Saving game before exit...")
    saveGame()
    print("Thanks for playing Cyberspace Tycoon!")
    return false
end