-- Legacy test stub for specialist system (compatibility for test runner dofile)
if TestRunner and TestRunner.test then
    TestRunner.test("legacy:specialist_system_stub", function()
        -- No-op legacy stub
    end)
end
return {}