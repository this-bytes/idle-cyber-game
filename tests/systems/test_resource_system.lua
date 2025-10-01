-- Legacy test stub for resource system (compatibility for test runner dofile)
if TestRunner and TestRunner.test then
    TestRunner.test("legacy:resource_system_stub", function()
        -- No-op legacy stub
    end)
end

return {}
