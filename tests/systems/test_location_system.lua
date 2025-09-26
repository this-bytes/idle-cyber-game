-- Test Location System
local EventBus = require("src.utils.event_bus")
local LocationSystem = require("src.systems.location_system")

local function test_location_system_initialization()
    local eventBus = EventBus.new()
    local locationSystem = LocationSystem.new(eventBus)
    
    -- Test basic initialization
    assert(locationSystem ~= nil, "LocationSystem should initialize")
    
    -- Test default location
    local currentLocation = locationSystem:getCurrentLocation()
    assert(currentLocation.building ~= nil, "Should have a current building")
    assert(currentLocation.floor ~= nil, "Should have a current floor")
    assert(currentLocation.room ~= nil, "Should have a current room")
    
    print("✅ LocationSystem: Initialize with default location")
    return true
end

local function test_location_navigation()
    local eventBus = EventBus.new()
    local locationSystem = LocationSystem.new(eventBus)
    
    -- Test room movement
    local success = locationSystem:moveToRoom("home_office", "main", "my_office")
    assert(success, "Should be able to move to valid room")
    
    local location = locationSystem:getCurrentLocation()
    assert(location.building == "home_office", "Should be in home_office building")
    assert(location.floor == "main", "Should be on main floor")
    assert(location.room == "my_office", "Should be in my_office room")
    
    print("✅ LocationSystem: Navigate between rooms")
    return true
end

local function test_location_bonuses()
    local eventBus = EventBus.new()
    local locationSystem = LocationSystem.new(eventBus)
    
    -- Move to a room with bonuses
    locationSystem:moveToRoom("home_office", "main", "my_office")
    
    -- Get location bonuses
    local bonuses = locationSystem:getCurrentLocationBonuses()
    assert(type(bonuses) == "table", "Should return bonuses table")
    
    print("✅ LocationSystem: Location bonuses system")
    return true
end

local function test_available_locations()
    local eventBus = EventBus.new()
    local locationSystem = LocationSystem.new(eventBus)
    
    -- Test available buildings
    local buildings = locationSystem:getAvailableBuildings()
    assert(type(buildings) == "table", "Should return buildings table")
    assert(#buildings > 0, "Should have at least one available building")
    
    -- Test available rooms
    local rooms = locationSystem:getAvailableRooms()
    assert(type(rooms) == "table", "Should return rooms table")
    
    print("✅ LocationSystem: Get available locations")
    return true
end

local function test_location_validation()
    local eventBus = EventBus.new()
    local locationSystem = LocationSystem.new(eventBus)
    
    -- Test valid location
    local valid = locationSystem:isValidLocation("home_office", "main", "my_office")
    assert(valid, "Should validate existing location")
    
    -- Test invalid location
    local invalid = locationSystem:isValidLocation("nonexistent", "floor", "room")
    assert(not invalid, "Should reject nonexistent location")
    
    print("✅ LocationSystem: Location validation")
    return true
end

local function test_location_state_persistence()
    local eventBus = EventBus.new()
    local locationSystem = LocationSystem.new(eventBus)
    
    -- Change location
    locationSystem:moveToRoom("home_office", "main", "my_office")
    
    -- Get state
    local state = locationSystem:getState()
    assert(state.currentBuilding == "home_office", "State should track current building")
    assert(state.currentFloor == "main", "State should track current floor")
    assert(state.currentRoom == "my_office", "State should track current room")
    
    -- Test state restoration
    local newLocationSystem = LocationSystem.new(eventBus)
    newLocationSystem:setState(state)
    
    local restoredLocation = newLocationSystem:getCurrentLocation()
    assert(restoredLocation.building == "home_office", "Should restore building")
    assert(restoredLocation.floor == "main", "Should restore floor")
    assert(restoredLocation.room == "my_office", "Should restore room")
    
    print("✅ LocationSystem: State persistence")
    return true
end

-- Run all tests
local function run_location_tests()
    local tests = {
        test_location_system_initialization,
        test_location_navigation,
        test_location_bonuses,
        test_available_locations,
        test_location_validation,
        test_location_state_persistence
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local success, error_msg = pcall(test)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            print("❌ Test failed: " .. tostring(error_msg))
        end
    end
    
    return passed, failed
end

return {
    run_location_tests = run_location_tests
}