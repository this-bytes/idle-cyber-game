-- Test to ensure scene modules expose a class-style `new` constructor
local scenes = {
    "src.scenes.main_menu",
    "src.scenes.soc_view",
    "src.scenes.upgrade_shop",
    "src.scenes.incident_response",
    "src.scenes.game_over"
}

local function test()
    local failures = {}
    for _, path in ipairs(scenes) do
        local ok, mod = pcall(require, path)
        if not ok or type(mod) ~= "table" then
            table.insert(failures, path .. " did not return a table module")
        else
            if type(mod.new) ~= "function" then
                table.insert(failures, path .. " does not expose a .new() constructor")
            end
        end
    end

    if #failures > 0 then
        print("❌ Scene module convention failures:")
        for _, msg in ipairs(failures) do print("  - " .. msg) end
        error("Scene module convention tests failed")
    end

    print("✅ Scene module convention: all scene modules expose .new()")
end

test()

return true
