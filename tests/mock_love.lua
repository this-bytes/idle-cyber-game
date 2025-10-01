-- Mock LÖVE Framework for Testing
-- Provides minimal LÖVE API stubs for running tests outside the engine

local MockLove = {}

-- Mock love.filesystem
MockLove.filesystem = {
    getInfo = function(path)
        local handle = io.open(path, "r")
        if handle then
            handle:close()
            return { type = "file" }
        end
        return nil
    end,
    
    read = function(path)
        local handle = io.open(path, "r")
        if handle then
            local content = handle:read("*all")
            handle:close()
            return content, nil
        end
        return nil, "File not found"
    end,
    
    getDirectoryItems = function(path)
        local items = {}
        local handle = io.popen("ls -1 " .. path .. " 2>/dev/null")
        if handle then
            for file in handle:lines() do
                table.insert(items, file)
            end
            handle:close()
        end
        return items
    end
}

-- Mock love.timer
MockLove.timer = {
    getTime = function()
        return os.time()
    end
}

-- Mock love.graphics (minimal)
MockLove.graphics = {
    newFont = function(...) return {} end,
    setFont = function() end,
    setDefaultFilter = function() end,
    setBackgroundColor = function() end,
    clear = function() end,
    setColor = function() end,
    printf = function() end,
    print = function() end,
    getFont = function() return { getWidth = function() return 10 end } end,
    getWidth = function() return 1024 end,
    getHeight = function() return 768 end
}

-- Mock love.window
MockLove.window = {
    setTitle = function() end,
    setMode = function() return true end
}

function MockLove.install()
    _G.love = MockLove
end

return MockLove
