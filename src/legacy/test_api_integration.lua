#!/usr/bin/env lua
-- Test script for API integration (archived)
-- Run with: lua src/legacy/test_api_integration.lua

-- Add current directory to package path
package.path = package.path .. ";./?/init.lua;./?.lua"

-- Try to load our API module
local api = require("api")

print("Testing API Integration (archived)...")
print("=============================")

-- Basic smoke tests (archived helper)
local success, result = api.testConnection(nil, false)
if success then
    print("Connection test: SUCCESS")
else
    print("Connection test: FAILED", result)
end

print("API integration script (archived) finished.")
