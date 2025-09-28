#!/usr/bin/env lua5.3
-- Demo for Dynamic ASCII Art System
-- Shows all room types, scaling, and interactive features

local AsciiArt = require("src.ui.ascii_art")

print("🖥️  CYBER EMPIRE COMMAND - ASCII ART DEMO")
print("==================================================")

-- Test different room types
local roomTypes = {
    "personal_office",
    "main_office_floor", 
    "hr_office",
    "kitchen_break_room",
    "server_room",
    "conference_room"
}

print("\n🏢 ROOM LAYOUTS:")
print("------------------------------")

for _, roomType in ipairs(roomTypes) do
    print("\n📋 " .. roomType:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end) .. ":")
    
    -- Create room at standard size
    local room = AsciiArt.Room.new(roomType, 1024, 768)
    local rendered = room:renderToString()
    
    -- Show first 8 lines to keep demo manageable
    local lines = {}
    for line in rendered:gmatch("[^\n]+") do
        table.insert(lines, line)
        if #lines >= 8 then break end
    end
    
    for _, line in ipairs(lines) do
        print(line)
    end
    
    print("📍 Interactive Areas: " .. #room.interactiveAreas)
    for _, area in ipairs(room.interactiveAreas) do
        print("  • " .. area.id .. " (" .. (area.action or "no action") .. ")")
    end
end

print("\n🔧 SCALING DEMONSTRATION:")
print("------------------------------")

local testRoom = "personal_office"
local sizes = {
    {640, 480, "Small"},
    {1024, 768, "Medium"}, 
    {1920, 1080, "Large"}
}

for _, size in ipairs(sizes) do
    local room = AsciiArt.Room.new(testRoom, size[1], size[2])
    print(string.format("📐 %s (%dx%d): Grid %dx%d chars, %d interactive areas", 
        size[3], size[1], size[2], room.charWidth, room.charHeight, #room.interactiveAreas))
end

print("\n🖱️  INTERACTIVE DETECTION TEST:")
print("------------------------------")

local interactiveRoom = AsciiArt.Room.new("personal_office", 1024, 768)
local testCoords = {
    {100, 100},
    {200, 150},
    {400, 200},
    {10000, 10000} -- Miss test
}

for _, coord in ipairs(testCoords) do
    local area = interactiveRoom:getInteractiveAreaAt(coord[1], coord[2])
    if area then
        print(string.format("🎯 Click (%d,%d): HIT %s -> %s", coord[1], coord[2], area.id, area.action or "no action"))
    else
        print(string.format("❌ Click (%d,%d): MISS", coord[1], coord[2]))
    end
end

print("\n🎨 WINDOW RESIZE TEST:")
print("------------------------------")

local resizeRoom = AsciiArt.Room.new("server_room", 800, 600)
print(string.format("Original: %dx%d grid, %d areas", resizeRoom.charWidth, resizeRoom.charHeight, #resizeRoom.interactiveAreas))

resizeRoom:resize(1600, 1200)
print(string.format("Resized:  %dx%d grid, %d areas", resizeRoom.charWidth, resizeRoom.charHeight, #resizeRoom.interactiveAreas))

print("\n👥 CHARACTER SPRITES:")
print("------------------------------")

local characters = {"ceo", "security_analyst", "incident_responder", "penetration_tester"}
for _, char in ipairs(characters) do
    print("👤 " .. AsciiArt.renderCharacter(char))
end

print("\n🎨 UI ELEMENTS & THEMES:")
print("------------------------------")

print("Resource Icons:")
local resources = {"money", "reputation", "energy", "focus"}
for _, resource in ipairs(resources) do
    print("  " .. AsciiArt.getIcon(resource) .. " " .. resource)
end

print("\nUI Elements:")
local uiElements = {"status_online", "status_warning", "status_critical", "button_arrow"}
for _, element in ipairs(uiElements) do
    print("  " .. AsciiArt.getUIElement(element) .. " " .. element)
end

print("\nColor Themes Available:")
local themes = {"matrix", "cyberpunk", "neon"}
for _, theme in ipairs(themes) do
    local themeData = AsciiArt.getColorTheme(theme)
    print("  🎨 " .. theme .. " (primary: " .. table.concat(themeData.primary, ",") .. ")")
end

print("\n✅ DEMO COMPLETE!")
print("==================================================")
print("The dynamic ASCII art system is fully functional with:")
print("• Data-driven room layouts from JSON schemas")
print("• Dynamic scaling with window size")
print("• Interactive coordinate detection")
print("• Window resize support")
print("• Fallback system for unknown room types")
print("• Character sprites and UI elements")
print("• Multiple cyberpunk color themes")
print("==================================================")