-- Minimal love.* mocks used in tests
local M = {}

-- timer mock
M.timer = {
    getTime = function()
        return os.clock()
    end
}

-- filesystem mock (in-memory)
local files = {}
M.filesystem = {
    write = function(path, content)
        files[path] = content
        return true
    end,
    read = function(path)
        return files[path]
    end,
    getInfo = function(path)
        if files[path] then return {name = path} end
        return nil
    end,
    remove = function(path)
        files[path] = nil
        return true
    end
}

return M
