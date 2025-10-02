-- Not implemented: src/systems/location_system.lua
-- ======================================================================
-- This module manages hierarchical locations (buildings > floors > rooms) with JSON-driven configuration.
-- It supports player movement, location-based bonuses, and event integration.
-- ======================================================================   
-- This is a idea im just starting to think through. It is not complete.
-- Should not be used yet.
-- It is a starting point for a location system that can be expanded upon.


local LocationSystem = {}
LocationSystem.__index = LocationSystem

local json = require("src.utils.dkjson")

-- Create new location system
function LocationSystem.new(eventBus)
    local self = setmetatable({}, LocationSystem)
    self.eventBus = eventBus
    
    -- Current location state
    self.currentBuilding = nil
    self.currentFloor = nil
    self.currentRoom = nil
    
    -- Location data
    self.buildings = {}
    self.navigation = {}
    self.bonuses = {}
    
    -- Load location data from JSON
    self:loadLocationData()
    
    -- Initialize to default location
    self:initializeDefaultLocation()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Load location data from JSON file
function LocationSystem:loadLocationData()
    local dataPath = "src/data/locations.json"
    local locationsData = nil
    
    -- Try to load from file system
    if love and love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo(dataPath) then
            local content = love.filesystem.read(dataPath)
            local ok, data = pcall(function() return json.decode(content) end)
            if ok and type(data) == "table" then
                locationsData = data
            end
        end
    else
        -- Fallback for non-LOVE environments
        local f = io.open(dataPath, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local ok, data = pcall(function() return json.decode(content) end)
            if ok and type(data) == "table" then
                locationsData = data
            end
        end
    end
    
    if locationsData then
        self.buildings = locationsData.buildings or {}
        self.navigation = locationsData.navigation or {}
        self.bonuses = locationsData.bonuses or {}
        print("📍 Loaded location data: " .. self:getBuildingCount() .. " buildings")
    else
        print("⚠️  Failed to load location data, using defaults")
        self:createDefaultLocations()
    end
end

-- Create default locations if JSON fails to load
function LocationSystem:createDefaultLocations()
    self.buildings = {
        home_office = {
            id = "home_office",
            name = "🏠 Home Office Building",
            description = "Your cozy starting location",
            unlocked = true,
            tier = 1,
            floors = {
                main = {
                    id = "main",
                    name = "Main Floor",
                    rooms = {
                        my_office = {
                            id = "my_office",
                            name = "My Office",
                            description = "Your personal workspace",
                            x = 160, y = 120, width = 100, height = 80,
                            departments = {"desk"},
                            bonuses = { focus = 1.1 }
                        }
                    }
                }
            }
        }
    }
    self.navigation = {
        default_building = "home_office",
        default_floor = "main", 
        default_room = "my_office",
        movement_speed = 120
    }
end

-- Initialize to default location
function LocationSystem:initializeDefaultLocation()
    local nav = self.navigation
    self.currentBuilding = nav.default_building or "home_office"
    self.currentFloor = nav.default_floor or "main"
    self.currentRoom = nav.default_room or "my_office"
    
    print("🏢 Initialized location: " .. self.currentBuilding .. "/" .. self.currentFloor .. "/" .. self.currentRoom)
end

-- Subscribe to location-related events
function LocationSystem:subscribeToEvents()
    self.eventBus:subscribe("player_move_to_room", function(data)
        self:moveToRoom(data.building, data.floor, data.room)
    end)
    
    self.eventBus:subscribe("player_move_to_floor", function(data)
        self:moveToFloor(data.building, data.floor)
    end)
    
    self.eventBus:subscribe("player_move_to_building", function(data)
        self:moveToBuilding(data.building)
    end)
end

-- Move player to a specific room
function LocationSystem:moveToRoom(building, floor, room)
    if not self:isValidLocation(building, floor, room) then
        print("❌ Invalid location: " .. tostring(building) .. "/" .. tostring(floor) .. "/" .. tostring(room))
        return false
    end
    
    local oldLocation = self:getCurrentLocationString()
    self.currentBuilding = building
    self.currentFloor = floor
    self.currentRoom = room
    
    print("🚶 Moved from " .. oldLocation .. " to " .. self:getCurrentLocationString())
    
    -- Show UI notification for location change
    local roomData = self.buildings[building].floors[floor].rooms[room]
    self.eventBus:publish("ui.toast", {
        text = "Moved to " .. roomData.name,
        type = "info",
        duration = 2.0
    })
    
    self.eventBus:publish("ui.log", {
        text = "Location changed: " .. oldLocation .. " → " .. self:getCurrentLocationString(),
        severity = "info"
    })
    
    -- Emit location change event
    self.eventBus:publish("location_changed", {
        oldBuilding = self.currentBuilding,
        oldFloor = self.currentFloor,
        oldRoom = self.currentRoom,
        newBuilding = building,
        newFloor = floor,
        newRoom = room,
        bonuses = self:getCurrentLocationBonuses()
    })
    
    return true
end

-- Move to a floor (default room in that floor)
function LocationSystem:moveToFloor(building, floor)
    if not self:validateBuilding(building) or not self:validateFloor(building, floor) then
        return false
    end
    
    -- Find first available room in the floor
    local floorData = self.buildings[building].floors[floor]
    local firstRoom = next(floorData.rooms)
    
    return self:moveToRoom(building, floor, firstRoom)
end

-- Move to a building (default floor and room)
function LocationSystem:moveToBuilding(building)
    if not self:validateBuilding(building) then
        return false
    end
    
    local buildingData = self.buildings[building]
    local firstFloor = next(buildingData.floors)
    local firstRoom = next(buildingData.floors[firstFloor].rooms)
    
    return self:moveToRoom(building, firstFloor, firstRoom)
end

-- Validation methods
function LocationSystem:isValidLocation(building, floor, room)
    return self:validateBuilding(building) and 
           self:validateFloor(building, floor) and 
           self:validateRoom(building, floor, room)
end

function LocationSystem:validateBuilding(building)
    return self.buildings[building] ~= nil
end

function LocationSystem:validateFloor(building, floor)
    return self.buildings[building] and 
           self.buildings[building].floors and 
           self.buildings[building].floors[floor] ~= nil
end

function LocationSystem:validateRoom(building, floor, room)
    return self:validateFloor(building, floor) and
           self.buildings[building].floors[floor].rooms and
           self.buildings[building].floors[floor].rooms[room] ~= nil
end

-- Get current location information
function LocationSystem:getCurrentLocation()
    return {
        building = self.currentBuilding,
        floor = self.currentFloor,
        room = self.currentRoom
    }
end

function LocationSystem:getCurrentLocationString()
    return self.currentBuilding .. "/" .. self.currentFloor .. "/" .. self.currentRoom
end

function LocationSystem:getCurrentLocationData()
    if not self:isValidLocation(self.currentBuilding, self.currentFloor, self.currentRoom) then
        return nil
    end
    
    return {
        building = self.buildings[self.currentBuilding],
        floor = self.buildings[self.currentBuilding].floors[self.currentFloor],
        room = self.buildings[self.currentBuilding].floors[self.currentFloor].rooms[self.currentRoom]
    }
end

-- Get current location bonuses
function LocationSystem:getCurrentLocationBonuses()
    local locationData = self:getCurrentLocationData()
    if not locationData or not locationData.room then
        return {}
    end
    
    return locationData.room.bonuses or {}
end

-- Get departments in current room
function LocationSystem:getCurrentDepartments()
    local locationData = self:getCurrentLocationData()
    if not locationData or not locationData.room then
        return {}
    end
    
    return locationData.room.departments or {}
end

-- Get available rooms in current floor
function LocationSystem:getAvailableRooms()
    if not self:validateFloor(self.currentBuilding, self.currentFloor) then
        return {}
    end
    
    local rooms = {}
    local floorData = self.buildings[self.currentBuilding].floors[self.currentFloor]
    
    for roomId, roomData in pairs(floorData.rooms) do
        table.insert(rooms, {
            id = roomId,
            name = roomData.name,
            description = roomData.description,
            departments = roomData.departments or {},
            bonuses = roomData.bonuses or {}
        })
    end
    
    return rooms
end

-- Get available floors in current building
function LocationSystem:getAvailableFloors()
    if not self:validateBuilding(self.currentBuilding) then
        return {}
    end
    
    local floors = {}
    local buildingData = self.buildings[self.currentBuilding]
    
    for floorId, floorData in pairs(buildingData.floors) do
        table.insert(floors, {
            id = floorId,
            name = floorData.name,
            description = floorData.description or "",
            roomCount = self:countRoomsInFloor(self.currentBuilding, floorId)
        })
    end
    
    return floors
end

-- Get available buildings
function LocationSystem:getAvailableBuildings()
    local buildings = {}
    
    for buildingId, buildingData in pairs(self.buildings) do
        if buildingData.unlocked then
            table.insert(buildings, {
                id = buildingId,
                name = buildingData.name,
                description = buildingData.description,
                tier = buildingData.tier or 1,
                floorCount = self:countFloorsInBuilding(buildingId)
            })
        end
    end
    
    -- Sort by tier
    table.sort(buildings, function(a, b) return a.tier < b.tier end)
    return buildings
end

-- Utility methods
function LocationSystem:getBuildingCount()
    local count = 0
    for _ in pairs(self.buildings) do count = count + 1 end
    return count
end

function LocationSystem:countFloorsInBuilding(buildingId)
    if not self.buildings[buildingId] then return 0 end
    local count = 0
    for _ in pairs(self.buildings[buildingId].floors) do count = count + 1 end
    return count
end

function LocationSystem:countRoomsInFloor(buildingId, floorId)
    if not self:validateFloor(buildingId, floorId) then return 0 end
    local count = 0
    for _ in pairs(self.buildings[buildingId].floors[floorId].rooms) do count = count + 1 end
    return count
end

-- Check if building can be unlocked
function LocationSystem:canUnlockBuilding(buildingId, resources)
    if not self.buildings[buildingId] then return false end
    if self.buildings[buildingId].unlocked then return true end
    
    local requirements = self.buildings[buildingId].unlockRequirements or {}
    
    for resource, required in pairs(requirements) do
        if not resources[resource] or resources[resource] < required then
            return false
        end
    end
    
    return true
end

-- Unlock a building
function LocationSystem:unlockBuilding(buildingId, resources)
    if not self:canUnlockBuilding(buildingId, resources) then
        return false
    end
    
    self.buildings[buildingId].unlocked = true
    
    -- Emit unlock event
    self.eventBus:publish("building_unlocked", {
        building = buildingId,
        data = self.buildings[buildingId]
    })
    
    print("🔓 Unlocked building: " .. self.buildings[buildingId].name)
    return true
end

-- Get save state
function LocationSystem:getState()
    return {
        currentBuilding = self.currentBuilding,
        currentFloor = self.currentFloor,
        currentRoom = self.currentRoom,
        unlockedBuildings = self:getUnlockedBuildingIds()
    }
end

-- Load state
function LocationSystem:setState(state)
    if state.currentBuilding then self.currentBuilding = state.currentBuilding end
    if state.currentFloor then self.currentFloor = state.currentFloor end
    if state.currentRoom then self.currentRoom = state.currentRoom end
    
    -- Restore unlocked buildings
    if state.unlockedBuildings then
        for _, buildingId in ipairs(state.unlockedBuildings) do
            if self.buildings[buildingId] then
                self.buildings[buildingId].unlocked = true
            end
        end
    end
end

function LocationSystem:getUnlockedBuildingIds()
    local unlocked = {}
    for buildingId, buildingData in pairs(self.buildings) do
        if buildingData.unlocked then
            table.insert(unlocked, buildingId)
        end
    end
    return unlocked
end

return LocationSystem