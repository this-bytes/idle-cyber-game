#!/usr/bin/env lua
-- Standalone test runner for Incident and Specialist Management System
-- Can be run without LÖVE framework

-- Mock the love.filesystem functions for standalone testing
love = {
    filesystem = {
        getInfo = function(path)
            local file = io.open(path, "r")
            if file then
                file:close()
                return {type = "file"}
            end
            return nil
        end,
        read = function(path)
            local file = io.open(path, "r")
            if file then
                local content = file:read("*a")
                file:close()
                return content
            end
            return nil
        end
    }
}

-- Set package path for requiring modules
package.path = package.path .. ";./?.lua;./?/init.lua"

-- Run the tests
local TestIncidentSpecialistSystem = require("tests.systems.test_incident_specialist_system")
local passed, failed = TestIncidentSpecialistSystem.run_all_tests()

-- Exit with appropriate code
if failed > 0 then
    os.exit(1)
else
    os.exit(0)
end
