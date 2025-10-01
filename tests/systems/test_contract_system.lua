-- Legacy test stub for contract system (compatibility for test runner dofile)
if TestRunner and TestRunner.test then
    TestRunner.test("legacy:contract_system_stub", function()
        -- No-op legacy stub
    end)
end

return {}