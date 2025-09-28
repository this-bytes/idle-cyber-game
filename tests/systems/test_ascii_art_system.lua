-- Tests for Dynamic ASCII Art System
-- Validates data-driven room generation, scaling, and interaction

local function run_ascii_art_tests()
    local AsciiArt = require("src.ui.ascii_art")
    local passed = 0
    local failed = 0
    
    local function assert_test(condition, message)
        if condition then
            passed = passed + 1
            print("✅ " .. message)
        else
            failed = failed + 1
            print("❌ " .. message)
        end
    end
    
    -- Test 1: Room creation for known room types
    local personalOffice = AsciiArt.Room.new("personal_office", 1024, 768)
    assert_test(personalOffice ~= nil, "ASCII Art Room: Create personal_office room")
    assert_test(personalOffice.roomType == "personal_office", "ASCII Art Room: Correct room type stored")
    assert_test(#personalOffice.interactiveAreas >= 4, "ASCII Art Room: Personal office has expected interactive areas (got " .. #personalOffice.interactiveAreas .. ")")
    
    -- Test 2: Fallback behavior for unknown room types
    local unknownRoom = AsciiArt.Room.new("nonexistent_room", 800, 600)
    assert_test(unknownRoom ~= nil, "ASCII Art Room: Fallback room creation")
    assert_test(#unknownRoom.interactiveAreas == 1, "ASCII Art Room: Fallback room has exactly 1 interactive area")
    assert_test(unknownRoom.interactiveAreas[1].id == "fallback_area", "ASCII Art Room: Fallback area has correct ID")
    
    -- Test 3: Grid size calculations
    local smallRoom = AsciiArt.Room.new("personal_office", 640, 480)
    assert_test(smallRoom.charWidth >= 40, "ASCII Art Room: Minimum width constraint (got " .. smallRoom.charWidth .. ")")
    assert_test(smallRoom.charHeight >= 20, "ASCII Art Room: Minimum height constraint (got " .. smallRoom.charHeight .. ")")
    
    local largeRoom = AsciiArt.Room.new("personal_office", 1920, 1080)
    assert_test(largeRoom.charWidth > smallRoom.charWidth, "ASCII Art Room: Larger window = larger grid")
    
    -- Test 4: Interactive area detection
    local testRoom = AsciiArt.Room.new("personal_office", 1024, 768)
    
    -- Get the first interactive area and test its center
    if #testRoom.interactiveAreas > 0 then
        local area1 = testRoom.interactiveAreas[1]
        local centerX = area1.x + area1.width / 2
        local centerY = area1.y + area1.height / 2
        local area = testRoom:getInteractiveAreaAt(centerX, centerY)
        assert_test(area ~= nil, "ASCII Art Room: Interactive area detection at center")
        assert_test(area.id == area1.id, "ASCII Art Room: Correct area detected")
        assert_test(area.action ~= nil, "ASCII Art Room: Interactive area has action")
    else
        assert_test(false, "ASCII Art Room: No interactive areas found")
    end
    
    -- Test click miss
    local missArea = testRoom:getInteractiveAreaAt(10000, 10000)
    assert_test(missArea == nil, "ASCII Art Room: Click miss returns nil")
    
    -- Test 5: Window resizing
    local resizeRoom = AsciiArt.Room.new("server_room", 800, 600)
    local originalWidth = resizeRoom.charWidth
    local originalAreas = #resizeRoom.interactiveAreas
    
    resizeRoom:resize(1600, 1200)
    assert_test(resizeRoom.charWidth > originalWidth, "ASCII Art Room: Resize increases grid width")
    assert_test(#resizeRoom.interactiveAreas == originalAreas, "ASCII Art Room: Resize preserves interactive areas")
    
    -- Test 6: Room rendering to string
    local renderRoom = AsciiArt.Room.new("kitchen_break_room", 1024, 768)
    local roomString = renderRoom:renderToString()
    assert_test(type(roomString) == "string", "ASCII Art Room: Renders to string")
    assert_test(#roomString > 100, "ASCII Art Room: Rendered string has content")
    assert_test(roomString:find("┌") ~= nil, "ASCII Art Room: Contains border characters")
    
    -- Test 7: All supported room types
    local roomTypes = {"personal_office", "main_office_floor", "hr_office", "kitchen_break_room", "server_room", "conference_room"}
    for _, roomType in ipairs(roomTypes) do
        local room = AsciiArt.Room.new(roomType, 1024, 768)
        assert_test(room ~= nil, "ASCII Art Room: Create " .. roomType)
        assert_test(#room.interactiveAreas > 0, "ASCII Art Room: " .. roomType .. " has interactive areas")
    end
    
    -- Test 8: Character sprite retrieval
    local ceoSprite = AsciiArt.renderCharacter("ceo")
    assert_test(type(ceoSprite) == "string", "ASCII Art Characters: CEO sprite renders")
    assert_test(ceoSprite:find("CEO") ~= nil, "ASCII Art Characters: CEO sprite contains title")
    
    local unknownChar = AsciiArt.renderCharacter("nonexistent")
    assert_test(unknownChar == "❓", "ASCII Art Characters: Unknown character returns fallback")
    
    -- Test 9: UI element access
    local deskIcon = AsciiArt.getIcon("money")
    assert_test(deskIcon == "💰", "ASCII Art UI: Resource icon retrieval")
    
    local borderElement = AsciiArt.getUIElement("corner_tl")
    assert_test(borderElement == "┌", "ASCII Art UI: Border element retrieval")
    
    -- Test 10: Color theme availability
    local matrixTheme = AsciiArt.getColorTheme("matrix")
    assert_test(type(matrixTheme) == "table", "ASCII Art Themes: Matrix theme available")
    assert_test(matrixTheme.primary ~= nil, "ASCII Art Themes: Theme has primary color")
    
    local defaultTheme = AsciiArt.getColorTheme()
    assert_test(type(defaultTheme) == "table", "ASCII Art Themes: Default theme fallback")
    
    -- Test 11: Legacy API compatibility  
    local legacyRoom = AsciiArt.renderRoom("personal_office", 800, 600)
    assert_test(type(legacyRoom) == "string", "ASCII Art Legacy: renderRoom compatibility")
    assert_test(#legacyRoom > 50, "ASCII Art Legacy: renderRoom produces content")
    
    print("\n🎨 ASCII Art System Tests Complete")
    print("=" .. string.rep("=", 50))
    print(string.format("Tests passed: %d", passed))
    print(string.format("Tests failed: %d", failed))
    print("=" .. string.rep("=", 50))
    
    return passed, failed
end

return {
    run_ascii_art_tests = run_ascii_art_tests
}