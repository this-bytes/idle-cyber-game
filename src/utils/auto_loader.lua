-- Auto Loader - Automatic File Import System
-- Helps with auto-importing new files in the project structure
-- Provides utilities for dynamic module loading and dependency resolution

local AutoLoader = {}

-- Recursively scan a directory for Lua files
function AutoLoader.scanDirectory(path, pattern)
    pattern = pattern or "%.lua$"
    local files = {}
    
    -- Use love.filesystem if available (in LÖVE 2D)
    if love and love.filesystem then
        local items = love.filesystem.getDirectoryItems(path)
        for _, item in ipairs(items) do
            local fullPath = path .. "/" .. item
            local info = love.filesystem.getInfo(fullPath)
            
            if info then
                if info.type == "file" and item:match(pattern) then
                    table.insert(files, {
                        name = item:gsub("%.lua$", ""),
                        path = fullPath,
                        relativePath = fullPath:gsub("^./", ""):gsub("/", ".")
                    })
                elseif info.type == "directory" and not item:match("^%.") then
                    -- Recursively scan subdirectories
                    local subFiles = AutoLoader.scanDirectory(fullPath, pattern)
                    for _, subFile in ipairs(subFiles) do
                        table.insert(files, subFile)
                    end
                end
            end
        end
    else
        -- Fallback for non-LÖVE environments (limited functionality)
        print("AutoLoader: love.filesystem not available, limited scanning capability")
    end
    
    return files
end

-- Automatically require all modules in a directory
function AutoLoader.requireDirectory(path, filter)
    local modules = {}
    local files = AutoLoader.scanDirectory(path)
    
    for _, file in ipairs(files) do
        -- Skip files that don't match filter
        if not filter or file.name:match(filter) then
            -- Skip legacy, backup, and test files
            if not file.name:match("legacy") and 
               not file.name:match("backup") and 
               not file.name:match("test") and
               not file.name:match("demo") then
                
                local success, module = pcall(require, file.relativePath:gsub("%.lua$", ""))
                if success then
                    modules[file.name] = module
                    print("AutoLoader: Loaded " .. file.name)
                else
                    print("AutoLoader: Failed to load " .. file.name .. " - " .. tostring(module))
                end
            end
        end
    end
    
    return modules
end

-- Generate require statements for discovered modules
function AutoLoader.generateRequireStatements(path, prefix)
    prefix = prefix or ""
    local files = AutoLoader.scanDirectory(path)
    local statements = {}
    
    for _, file in ipairs(files) do
        if not file.name:match("legacy") and 
           not file.name:match("backup") and 
           not file.name:match("test") and
           not file.name:match("demo") then
            
            local varName = prefix .. file.name:gsub("_", ""):gsub("%-", "")
            local requirePath = file.relativePath:gsub("%.lua$", "")
            
            table.insert(statements, string.format("local %s = require(\"%s\")", varName, requirePath))
        end
    end
    
    return statements
end

-- Smart module resolver - attempts to find and load a module by name
function AutoLoader.smartRequire(moduleName, searchPaths)
    searchPaths = searchPaths or {
        "src.core",
        "src.systems", 
        "src.utils",
        "src.ui",
        "src.modes"
    }
    
    -- Try exact name first
    local success, module = pcall(require, moduleName)
    if success then
        return module
    end
    
    -- Try with search paths
    for _, path in ipairs(searchPaths) do
        local fullPath = path .. "." .. moduleName
        success, module = pcall(require, fullPath)
        if success then
            print("AutoLoader: Found " .. moduleName .. " at " .. fullPath)
            return module
        end
    end
    
    -- Try snake_case conversion
    local snakeName = moduleName:gsub("([A-Z])", function(c) 
        return "_" .. c:lower() 
    end):gsub("^_", "")
    
    for _, path in ipairs(searchPaths) do
        local fullPath = path .. "." .. snakeName
        success, module = pcall(require, fullPath)
        if success then
            print("AutoLoader: Found " .. moduleName .. " as " .. snakeName .. " at " .. fullPath)
            return module
        end
    end
    
    error("AutoLoader: Could not find module " .. moduleName)
end

-- Get module dependencies by analyzing require statements
function AutoLoader.analyzeDependencies(filePath)
    local dependencies = {}
    
    if love and love.filesystem then
        local content = love.filesystem.read(filePath)
        if content then
            -- Find require statements
            for requirePath in content:gmatch('require%s*%(?%s*["\']([^"\']+)["\']%s*%)?') do
                table.insert(dependencies, requirePath)
            end
        end
    end
    
    return dependencies
end

-- Check for circular dependencies
function AutoLoader.checkCircularDependencies(startPath)
    local visited = {}
    local stack = {}
    
    local function checkFile(filePath, currentStack)
        if stack[filePath] then
            print("AutoLoader: Circular dependency detected!")
            print("Path: " .. table.concat(currentStack, " -> ") .. " -> " .. filePath)
            return true
        end
        
        if visited[filePath] then
            return false
        end
        
        visited[filePath] = true
        stack[filePath] = true
        table.insert(currentStack, filePath)
        
        local deps = AutoLoader.analyzeDependencies(filePath)
        for _, dep in ipairs(deps) do
            if checkFile(dep, currentStack) then
                return true
            end
        end
        
        stack[filePath] = nil
        table.remove(currentStack)
        return false
    end
    
    return checkFile(startPath, {})
end

-- Helper to create a module registry
function AutoLoader.createModuleRegistry()
    return {
        modules = {},
        
        register = function(self, name, module)
            self.modules[name] = module
            print("Registry: Registered " .. name)
        end,
        
        get = function(self, name)
            return self.modules[name]
        end,
        
        list = function(self)
            local names = {}
            for name, _ in pairs(self.modules) do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end,
        
        clear = function(self)
            self.modules = {}
        end
    }
end

return AutoLoader