#!/usr/bin/env lua
-- Proper test for screenshot tool - validates no files are created and correct data is returned

local ScreenshotTool = require('tools.screenshot_tool')

print('=== PROPER SCREENSHOT TOOL TEST ===')

-- Test 1: Check no files exist before test
local test_files = {'test_screenshot.png', 'test_screenshot.txt', 'screenshot_20251002_221017.png'}
print('Files before test:')
for _, file in ipairs(test_files) do
    local exists = io.open(file, 'r') ~= nil
    print('  ' .. file .. ': ' .. (exists and 'EXISTS' or 'NOT FOUND'))
end

-- Test 2: Take screenshot using the real API (should create an image file)
print('\nTaking screenshot (real)...')
-- Optionally create a fake old screenshot only when CLEAR_SCREENSHOTS=1 is set
-- (tests should not remove screenshots by default because CI/agents inspect them).
local clear_requested = os.getenv('CLEAR_SCREENSHOTS') == '1'
local screenshots_dir = os.getenv('SCREENSHOT_DIR') or 'screenshots'
local fake_old
if clear_requested then
    fake_old = screenshots_dir .. '/screenshot_20200101_000000.png'
    os.execute('mkdir -p "' .. screenshots_dir .. '" 2>/dev/null')
    local f = io.open(fake_old, 'wb')
    if f then
        f:write('old')
        f:close()
    end
end

local out_path, out_err = ScreenshotTool.takeScreenshot('test_integration_screenshot.png')
local result = out_path or out_err

-- Test 3: Validate return type and content
print('\nValidation:')
print('  Result path or error: ' .. tostring(result))
if out_path then
    local f = io.open(out_path, 'rb')
    if f then
        local content = f:read('*a')
        f:close()
        print('  File exists: YES')
        print('  File size (bytes): ' .. #content)
        if #content > 0 then
            print('  Non-empty file: YES')
        else
            print('  Non-empty file: NO')
        end
    -- Do not auto-delete the screenshot; leave it in screenshots/ so CI
    -- and coding agents can inspect UI output. If you want tests to
    -- clean up, set CLEAR_SCREENSHOTS=1 in the environment.
    print('  Generated screenshot left in place for inspection: ' .. tostring(out_path))
    else
        print('  File exists: NO')
    end
else
    print('  No output path returned, error: ' .. tostring(out_err))
end

-- Test 4: Check no files were created after test
print('\nFiles after test:')
-- If we requested cleanup, ensure previously created fake file was removed by the cleanup routine
if clear_requested and fake_old then
    local fake_exists = io.open(fake_old, 'r') ~= nil
    print('  Fake old screenshot present after run (should be removed): ' .. (fake_exists and 'YES (ERROR)' or 'NO (GOOD)'))
else
    print('  Cleanup not requested (CLEAR_SCREENSHOTS not set) — screenshots left for inspection.')
end

for _, file in ipairs(test_files) do
    local exists = io.open(file, 'r') ~= nil
    print('  ' .. file .. ': ' .. (exists and 'EXISTS (ERROR!)' or 'NOT FOUND (GOOD)'))
end

-- Test 5: Test createPlaceholderScreenshot still returns textual data
print('\nTesting textual placeholder with nil filename...')
local nil_result = ScreenshotTool.createPlaceholderScreenshot(nil)
print('  Nil test passed: ' .. (type(nil_result) == 'string' and 'YES' or 'NO'))

print('\n=== TEST COMPLETE ===')