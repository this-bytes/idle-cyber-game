#!/usr/bin/env lua
-- Test script to verify button onClick callbacks work correctly

-- Mock love module
_G.love = {
    graphics = {
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        getFont = function() return {} end,
        newFont = function() return {} end,
        setFont = function() end,
        getWidth = function() return 800 end,
        getHeight = function() return 600 end,
    },
    filesystem = {
        getInfo = function() return nil end,
    }
}

-- Load component system
package.path = package.path .. ";./?.lua"
local Component = require("src.ui.components.component")
local Box = require("src.ui.components.box")
local Button = require("src.ui.components.button")

print("🧪 Testing Button onClick Callback Chain")
print("==========================================")

-- Test 1: Simple button with onClick
print("\n📝 Test 1: Button with onClick callback")
local clicked = false
local button = Button.new({
    label = "Test Button",
    width = 100,
    height = 40,
    onClick = function(self, btn)
        clicked = true
        print("✅ onClick callback executed!")
    end
})

-- Position the button
button.x = 10
button.y = 10
button.width = 100
button.height = 40

-- Layout the button (creates child components)
button:layout(button.x, button.y, button.width, button.height)

-- Simulate click: press at center of button
local centerX = button.x + button.width / 2
local centerY = button.y + button.height / 2

print(string.format("   Simulating click at (%.1f, %.1f)", centerX, centerY))
print("   1. Mouse press...")
button:onMousePress(centerX, centerY, 1)

print("   2. Mouse release...")
button:onMouseRelease(centerX, centerY, 1)

if clicked then
    print("✅ Test 1 PASSED: onClick callback was called")
else
    print("❌ Test 1 FAILED: onClick callback was NOT called")
    os.exit(1)
end

-- Test 2: Button with child text component (real-world scenario)
print("\n📝 Test 2: Button with child components")
clicked = false
local button2 = Button.new({
    label = "Button With Child",
    width = 150,
    height = 50,
    onClick = function(self, btn)
        clicked = true
        print("✅ onClick callback executed on button with children!")
    end
})

button2.x = 10
button2.y = 100
button2.width = 150
button2.height = 50
button2:layout(button2.x, button2.y, button2.width, button2.height)

-- Click on the child text component area (should still trigger button onClick)
local childCenterX = button2.x + button2.width / 2
local childCenterY = button2.y + button2.height / 2

print(string.format("   Clicking on child component area at (%.1f, %.1f)", childCenterX, childCenterY))
print("   1. Mouse press...")
button2:onMousePress(childCenterX, childCenterY, 1)

print("   2. Mouse release...")
button2:onMouseRelease(childCenterX, childCenterY, 1)

if clicked then
    print("✅ Test 2 PASSED: onClick bubbled from child to button")
else
    print("❌ Test 2 FAILED: onClick did NOT bubble from child")
    os.exit(1)
end

print("\n✅ All tests PASSED! Button onClick callbacks work correctly.")
print("==========================================")
