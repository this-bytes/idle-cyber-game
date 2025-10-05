-- System Registry
-- ==================
-- Automatic system discovery, dependency injection, and initialization orchestration
-- Eliminates boilerplate by auto-discovering systems and resolving dependencies
--
-- USAGE:
--   local registry = SystemRegistry.new(eventBus)
--   registry:discoverSystems()
--   registry:instantiateSystems()
--   registry:initializeSystems()
--   local systems = registry:getAllSystems()
--
-- SYSTEM METADATA FORMAT (optional, declare at top of system file):
--   SystemName.metadata = {
--       priority = 1,              -- Lower = earlier initialization (default: 100)
--       dependencies = {           -- System names this depends on
--           "ResourceManager",
--           "DataManager"
--       },
--       systemName = "customName"  -- Override auto-detected name (optional)
--   }

local SystemRegistry = {}
SystemRegistry.__index = SystemRegistry

-- Constants
local SYSTEMS_PATH = "src/systems"
local SYSTEM_PATTERN = "_system%.lua$"  -- Matches *_system.lua files
local MANAGER_PATTERN = "_manager%.lua$"  -- Matches *_manager.lua files (DataManager, ResourceManager, etc.)
local IGNORE_FILES = {
    "system_registry.lua",
    "game_state_engine.lua",  -- Special case - initialized first
    "effect_processor.lua",    -- Utility, not a system
    "formula_engine.lua",      -- Utility, not a system
    "item_registry.lua",       -- Utility, not a system
    "proc_gen.lua",            -- Utility, not a system
    "synergy_detector.lua",    -- Utility, not a system
    "analytics_collector.lua", -- Utility, not a system
}

function SystemRegistry.new(eventBus)
    local self = setmetatable({}, SystemRegistry)
    self.eventBus = eventBus
    
    -- System storage
    self.systemModules = {}      -- name -> module (class table)
    self.systemInstances = {}    -- name -> instance
    self.systemMetadata = {}     -- name -> metadata
    self.initializationOrder = {} -- ordered list of system names
    
    -- Special systems that need early init
    self.coreSystemNames = {
        "GameStateEngine",
        "DataManager",
        "ResourceManager"
    }
    
    print("📋 SystemRegistry created")
    
    return self
end

-- Discover all systems in src/systems directory
function SystemRegistry:discoverSystems()
    print("🔍 Discovering systems...")
    
    -- Get all Lua files in systems directory
    local filesInfo = love.filesystem.getDirectoryItems(SYSTEMS_PATH)
    
    for _, filename in ipairs(filesInfo) do
        -- Check if it matches the system or manager pattern and isn't ignored
        local isSystem = filename:match(SYSTEM_PATTERN)
        local isManager = filename:match(MANAGER_PATTERN)
        
        if (isSystem or isManager) and not self:_isIgnoredFile(filename) then
            local modulePath = SYSTEMS_PATH .. "/" .. filename
            local systemName = self:_extractSystemName(filename)
            
            -- Load the module
            local success, moduleOrError = pcall(require, modulePath:gsub("/", "."):gsub(".lua$", ""))
            
            if success then
                local module = moduleOrError
                self.systemModules[systemName] = module
                
                -- Extract metadata if present
                local metadata = module.metadata or {}
                metadata.priority = metadata.priority or 100
                metadata.dependencies = metadata.dependencies or {}
                metadata.systemName = metadata.systemName or systemName
                self.systemMetadata[systemName] = metadata
                
                print("  ✓ Discovered: " .. systemName .. " (priority: " .. metadata.priority .. ")")
            else
                print("  ✗ Failed to load " .. filename .. ": " .. tostring(moduleOrError))
            end
        end
    end
    
    -- Calculate initialization order
    self:_calculateInitOrder()
    
    print("📋 System discovery complete: " .. #self.initializationOrder .. " systems found")
    
    return self.initializationOrder
end

-- Instantiate all discovered systems with dependency injection
function SystemRegistry:instantiateSystems()
    print("🏗️  Instantiating systems in dependency order...")
    
    for _, systemName in ipairs(self.initializationOrder) do
        local module = self.systemModules[systemName]
        local metadata = self.systemMetadata[systemName]
        
        if not module then
            print("  ⚠️  System module not found: " .. systemName)
        elseif not module.new then
            print("  ⚠️  System missing .new() constructor: " .. systemName)
        else
            -- Resolve dependencies
            local args = self:_resolveDependencies(systemName, metadata)
            
            -- Instantiate the system
            local success, instance = pcall(function()
                return module.new(unpack(args))  -- Lua 5.1 uses unpack, not table.unpack
            end)
            
            if success and instance then
                self.systemInstances[systemName] = instance
                print("  ✓ Instantiated: " .. systemName)
                
                -- CRITICAL: If this is DataManager, load data immediately
                if systemName == "DataManager" and instance.loadAllData then
                    instance:loadAllData()
                    print("  📊 DataManager loaded game data")
                end
            else
                print("  ✗ Failed to instantiate " .. systemName .. ": " .. tostring(instance))
            end
        end
    end
    
    print("🏗️  System instantiation complete")
end

-- Initialize all systems (call their initialize() methods if present)
function SystemRegistry:initializeSystems()
    print("🚀 Initializing systems...")
    
    for _, systemName in ipairs(self.initializationOrder) do
        local instance = self.systemInstances[systemName]
        
        if instance and instance.initialize then
            local success, error = pcall(function()
                instance:initialize()
            end)
            
            if success then
                print("  ✓ Initialized: " .. systemName)
            else
                print("  ✗ Failed to initialize " .. systemName .. ": " .. tostring(error))
            end
        end
    end
    
    print("🚀 System initialization complete")
end

-- Register all systems with GameStateEngine
function SystemRegistry:registerWithGameStateEngine(gameStateEngine)
    if not gameStateEngine then
        print("⚠️  GameStateEngine not provided, skipping registration")
        return
    end
    
    print("💾 Registering systems with GameStateEngine...")
    
    for systemName, instance in pairs(self.systemInstances) do
        -- Convert system name to the expected key format (e.g., ContractSystem -> contractSystem)
        local registryKey = self:_toRegistryKey(systemName)
        
        if gameStateEngine.registerSystem then
            gameStateEngine:registerSystem(registryKey, instance)
            print("  ✓ Registered: " .. systemName .. " as '" .. registryKey .. "'")
        end
    end
    
    print("💾 GameStateEngine registration complete")
end

-- Get all instantiated systems
function SystemRegistry:getAllSystems()
    return self.systemInstances
end

-- Get a specific system by name
function SystemRegistry:getSystem(name)
    return self.systemInstances[name]
end

-- Set a system instance (for manually created systems like GameStateEngine)
function SystemRegistry:setSystem(name, instance)
    self.systemInstances[name] = instance
    print("📌 Manually registered system: " .. name)
end

--------------------
-- PRIVATE METHODS
--------------------

-- Check if a file should be ignored
function SystemRegistry:_isIgnoredFile(filename)
    for _, ignored in ipairs(IGNORE_FILES) do
        if filename == ignored then
            return true
        end
    end
    return false
end

-- Extract system name from filename (e.g., "contract_system.lua" -> "ContractSystem")
function SystemRegistry:_extractSystemName(filename)
    -- Remove .lua extension
    local name = filename:gsub("%.lua$", "")
    
    -- Convert snake_case to PascalCase
    local parts = {}
    for part in name:gmatch("[^_]+") do
        parts[#parts + 1] = part:sub(1, 1):upper() .. part:sub(2)
    end
    
    return table.concat(parts, "")
end

-- Convert system name to registry key (e.g., "ContractSystem" -> "contractSystem")
function SystemRegistry:_toRegistryKey(systemName)
    return systemName:sub(1, 1):lower() .. systemName:sub(2)
end

-- Calculate initialization order using topological sort
function SystemRegistry:_calculateInitOrder()
    local visited = {}
    local tempMarked = {}
    local order = {}
    
    -- Helper function for depth-first search
    local function visit(name)
        if tempMarked[name] then
            print("⚠️  Circular dependency detected involving: " .. name)
            return
        end
        
        if visited[name] then
            return
        end
        
        tempMarked[name] = true
        
        -- Visit dependencies first
        local metadata = self.systemMetadata[name]
        if metadata and metadata.dependencies then
            for _, depName in ipairs(metadata.dependencies) do
                if self.systemModules[depName] then
                    visit(depName)
                end
            end
        end
        
        tempMarked[name] = false
        visited[name] = true
        table.insert(order, name)
    end
    
    -- Create a list of systems sorted by priority
    local systemsByPriority = {}
    for name, metadata in pairs(self.systemMetadata) do
        table.insert(systemsByPriority, {
            name = name,
            priority = metadata.priority or 100
        })
    end
    
    table.sort(systemsByPriority, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Visit systems in priority order
    for _, item in ipairs(systemsByPriority) do
        visit(item.name)
    end
    
    self.initializationOrder = order
end

-- Resolve dependencies for a system's constructor
function SystemRegistry:_resolveDependencies(systemName, metadata)
    local args = {}
    
    -- First argument is ALWAYS eventBus for all systems
    table.insert(args, self.eventBus)
    
    -- Add dependencies in the order they're declared
    if metadata.dependencies then
        for _, depName in ipairs(metadata.dependencies) do
            local depInstance = self.systemInstances[depName]
            if depInstance then
                table.insert(args, depInstance)
            else
                print("  ⚠️  Dependency not found for " .. systemName .. ": " .. depName)
                table.insert(args, nil)  -- Add nil placeholder
            end
        end
    end
    
    return args
end

-- Full initialization pipeline
function SystemRegistry:autoInitialize(gameStateEngine)
    print("\n" .. string.rep("=", 60))
    print("🤖 AUTOMATIC SYSTEM INITIALIZATION PIPELINE")
    print(string.rep("=", 60) .. "\n")
    
    -- Register GameStateEngine if provided
    if gameStateEngine then
        self:setSystem("GameStateEngine", gameStateEngine)
    end
    
    -- Step 1: Discovery
    self:discoverSystems()
    
    -- Step 2: Instantiation
    self:instantiateSystems()
    
    -- Step 3: GameStateEngine registration
    if gameStateEngine then
        self:registerWithGameStateEngine(gameStateEngine)
    end
    
    -- Step 4: Initialization
    self:initializeSystems()
    
    print("\n" .. string.rep("=", 60))
    print("✅ AUTOMATIC SYSTEM INITIALIZATION COMPLETE")
    print(string.rep("=", 60) .. "\n")
    
    return self.systemInstances
end

return SystemRegistry
