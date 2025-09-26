-- Room System
-- Manages different rooms/locations that the player can move between

local RoomSystem = {}
RoomSystem.__index = RoomSystem

-- Create new room system
function RoomSystem.new(eventBus)
    local self = setmetatable({}, RoomSystem)
    self.eventBus = eventBus
    
    -- Current room state
    self.currentRoom = "my_office"  -- Starting room
    
    -- Room definitions
    self.rooms = {
        my_office = {
            id = "my_office",
            name = "My Office",
            description = "Your personal office space with your desk and equipment",
            width = 640,
            height = 200,
            backgroundColor = {0.02, 0.02, 0.03, 0.95},
            
            -- Departments/interactables in this room
            departments = {
                { id = "desk", name = "My Desk", x = 160, y = 120, radius = 18 },
                { id = "computer", name = "Computer", x = 140, y = 100, radius = 15 },
                { id = "bookshelf", name = "Bookshelf", x = 50, y = 80, radius = 20 },
            },
            
            -- Room exits (doors/transitions to other rooms)
            exits = {
                { id = "to_main_office", name = "Office Door", x = 600, y = 120, radius = 25, targetRoom = "main_office_floor", targetX = 50, targetY = 120 }
            }
        },
        
        main_office_floor = {
            id = "main_office_floor",
            name = "Main Office Floor",
            description = "The main office floor with various departments and colleagues",
            width = 800,
            height = 400,
            backgroundColor = {0.01, 0.03, 0.02, 0.95},
            
            departments = {
                { id = "reception", name = "Reception", x = 100, y = 100, radius = 30 },
                { id = "contracts", name = "Contracts", x = 200, y = 150, radius = 28 },
                { id = "research", name = "Research", x = 400, y = 100, radius = 28 },
                { id = "ops", name = "Operations", x = 600, y = 150, radius = 28 },
                { id = "meeting_room", name = "Meeting Room", x = 350, y = 300, radius = 35 },
            },
            
            exits = {
                { id = "to_my_office", name = "My Office", x = 50, y = 120, radius = 25, targetRoom = "my_office", targetX = 580, targetY = 120 },
                { id = "to_hr", name = "HR Office", x = 150, y = 350, radius = 25, targetRoom = "hr_office", targetX = 100, targetY = 50 },
                { id = "to_kitchen", name = "Kitchen", x = 700, y = 350, radius = 25, targetRoom = "kitchen", targetX = 100, targetY = 150 }
            }
        },
        
        hr_office = {
            id = "hr_office",
            name = "HR Office",
            description = "Human Resources office with personnel files and meeting area",
            width = 480,
            height = 300,
            backgroundColor = {0.03, 0.02, 0.04, 0.95},
            
            departments = {
                { id = "hr", name = "HR Desk", x = 200, y = 150, radius = 28 },
                { id = "training", name = "Training Materials", x = 350, y = 100, radius = 25 },
                { id = "personnel_files", name = "Personnel Files", x = 100, y = 200, radius = 20 },
            },
            
            exits = {
                { id = "to_main_office", name = "Main Office", x = 100, y = 50, radius = 25, targetRoom = "main_office_floor", targetX = 150, targetY = 330 }
            }
        },
        
        kitchen = {
            id = "kitchen",
            name = "Office Kitchen",
            description = "Break room and kitchen area for employees",
            width = 400,
            height = 250,
            backgroundColor = {0.04, 0.03, 0.02, 0.95},
            
            departments = {
                { id = "coffee_machine", name = "Coffee Machine", x = 150, y = 100, radius = 20 },
                { id = "microwave", name = "Microwave", x = 250, y = 80, radius = 18 },
                { id = "fridge", name = "Refrigerator", x = 80, y = 150, radius = 25 },
                { id = "table", name = "Break Table", x = 300, y = 180, radius = 30 },
            },
            
            exits = {
                { id = "to_main_office", name = "Main Office", x = 100, y = 150, radius = 25, targetRoom = "main_office_floor", targetX = 680, targetY = 330 }
            }
        }
    }
    
    return self
end

-- Get current room data
function RoomSystem:getCurrentRoom()
    return self.rooms[self.currentRoom]
end

-- Get room by ID
function RoomSystem:getRoom(roomId)
    return self.rooms[roomId]
end

-- Change to a different room
function RoomSystem:changeRoom(newRoomId, playerX, playerY)
    if not self.rooms[newRoomId] then
        print("⚠️ Room not found: " .. tostring(newRoomId))
        return false
    end
    
    local oldRoom = self.currentRoom
    self.currentRoom = newRoomId
    
    -- Publish room change event
    self.eventBus:publish("room_changed", {
        oldRoom = oldRoom,
        newRoom = newRoomId,
        playerX = playerX,
        playerY = playerY
    })
    
    print("🚪 Moved to: " .. self.rooms[newRoomId].name)
    return true
end

-- Check if player is near an exit
function RoomSystem:checkExits(playerX, playerY, playerRadius)
    local currentRoom = self:getCurrentRoom()
    if not currentRoom or not currentRoom.exits then
        return nil
    end
    
    for _, exit in ipairs(currentRoom.exits) do
        local dx = playerX - exit.x
        local dy = playerY - exit.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist <= exit.radius + playerRadius + 4 then
            return exit
        end
    end
    
    return nil
end

-- Get all departments for current room
function RoomSystem:getCurrentDepartments()
    local currentRoom = self:getCurrentRoom()
    if currentRoom and currentRoom.departments then
        return currentRoom.departments
    end
    return {}
end

-- Get all exits for current room
function RoomSystem:getCurrentExits()
    local currentRoom = self:getCurrentRoom()
    if currentRoom and currentRoom.exits then
        return currentRoom.exits
    end
    return {}
end

-- Subscribe to events
function RoomSystem:subscribeToEvents()
    -- Handle room transition requests
    self.eventBus:subscribe("request_room_change", function(data)
        if data.roomId and data.playerX and data.playerY then
            self:changeRoom(data.roomId, data.playerX, data.playerY)
        end
    end)
end

-- Update room system
function RoomSystem:update(dt)
    -- Room system doesn't need regular updates currently
    -- Could be used for room-specific ambient effects, NPCs, etc.
end

return RoomSystem