-- api.lua - Client-Server Bridge for Cyberspace Tycoon
-- Handles all HTTP communication with the Flask backend

local json = require("dkjson")
local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")

-- IMPORTANT: Replace with the actual URL of your Flask backend
local BASE_URL = "http://localhost:5000/api/player"

local M = {}

-- Global state for async requests
M.pendingRequests = {}
M.requestId = 0

--- Utility function for making synchronous API calls.
-- @param method string The HTTP method ('GET', 'POST', 'PUT').
-- @param endpoint string The unique part of the URL (e.g., "/create").
-- @param data table Optional Lua table to be sent as JSON.
-- @return boolean, table/string success status and decoded response or error message
local function makeSyncRequest(method, endpoint, data)
    local url = BASE_URL .. endpoint
    local responseBody = {}
    
    local options = {
        method = method,
        url = url,
        headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        },
        sink = ltn12.sink.table(responseBody)
    }
    
    if data then
        local jsonData = json.encode(data)
        options.source = ltn12.source.string(jsonData)
        options.headers["Content-Length"] = string.len(jsonData)
    end
    
    -- Make the HTTP request
    local result, statusCode, headers, statusLine = http.request(options)
    
    if result and statusCode and statusCode >= 200 and statusCode < 300 then
        local responseString = table.concat(responseBody)
        if responseString and responseString ~= "" then
            local decoded_data, err = json.decode(responseString)
            if decoded_data and not err then
                return true, decoded_data
            else
                return false, "JSON decode error: " .. (err or "unknown")
            end
        else
            return true, {}
        end
    else
        local errorMessage = table.concat(responseBody) or statusLine or "Unknown error"
        return false, "HTTP error " .. (statusCode or "unknown") .. ": " .. errorMessage
    end
end

--- Utility function for making asynchronous API calls using love.thread.
-- @param method string The HTTP method ('GET', 'POST', 'PUT').
-- @param endpoint string The unique part of the URL (e.g., "/create").
-- @param data table Optional Lua table to be sent as JSON.
-- @param callback function The function to call on completion (takes success, result).
local function makeAsyncRequest(method, endpoint, data, callback)
    M.requestId = M.requestId + 1
    local requestId = M.requestId
    
    -- Store the callback for later
    M.pendingRequests[requestId] = {
        callback = callback,
        startTime = love.timer.getTime()
    }
    
    -- Create thread code as a string
    local threadCode = string.format([[
        local json = require("dkjson")
        local socket = require("socket")
        local http = require("socket.http")
        local ltn12 = require("ltn12")
        
        local method = %q
        local url = %q
        local jsonData = %q
        local requestId = %d
        
        local responseBody = {}
        local options = {
            method = method,
            url = url,
            headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            sink = ltn12.sink.table(responseBody)
        }
        
        if jsonData and jsonData ~= "" then
            options.source = ltn12.source.string(jsonData)
            options.headers["Content-Length"] = string.len(jsonData)
        end
        
        local result, statusCode, headers, statusLine = http.request(options)
        
        -- Send result back to main thread
        local response = {
            requestId = requestId,
            success = result and statusCode and statusCode >= 200 and statusCode < 300,
            statusCode = statusCode,
            body = table.concat(responseBody),
            error = statusLine
        }
        
        love.thread.getChannel("http_response"):push(response)
    ]], method, BASE_URL .. endpoint, data and json.encode(data) or "", requestId)
    
    -- Create and start the thread
    local thread = love.thread.newThread(threadCode)
    thread:start()
end

--- Update function to handle asynchronous request responses.
-- Call this in love.update to process completed requests.
function M.update()
    local responseChannel = love.thread.getChannel("http_response")
    local response = responseChannel:pop()
    
    while response do
        local requestInfo = M.pendingRequests[response.requestId]
        if requestInfo and requestInfo.callback then
            if response.success then
                local decoded_data, err = json.decode(response.body)
                if decoded_data and not err then
                    requestInfo.callback(true, decoded_data)
                else
                    requestInfo.callback(false, "JSON decode error: " .. (err or "unknown"))
                end
            else
                local errorMessage = response.error or ("HTTP " .. (response.statusCode or "unknown"))
                requestInfo.callback(false, errorMessage)
            end
        end
        
        -- Clean up
        M.pendingRequests[response.requestId] = nil
        
        -- Get next response
        response = responseChannel:pop()
    end
    
    -- Clean up old requests (timeout after 30 seconds)
    local currentTime = love.timer.getTime()
    for requestId, requestInfo in pairs(M.pendingRequests) do
        if currentTime - requestInfo.startTime > 30 then
            if requestInfo.callback then
                requestInfo.callback(false, "Request timeout")
            end
            M.pendingRequests[requestId] = nil
        end
    end
end

-- ==========================================================
-- A. GAME CLIENT API FUNCTIONS
-- ==========================================================

--- Registers a new player with the backend.
-- @param username string The player's chosen username.
-- @param callback function Called on completion (takes success, player_data/error).
-- @param useAsync boolean Optional, defaults to true. Set false for synchronous operation.
function M.createPlayer(username, callback, useAsync)
    local data = { username = username }
    
    if useAsync == false then
        local success, result = makeSyncRequest("POST", "/create", data)
        if callback then callback(success, result) end
        return success, result
    else
        makeAsyncRequest("POST", "/create", data, callback)
    end
end

--- Loads a player's game state from the backend.
-- @param username string The player's username.
-- @param callback function Called on completion (takes success, player_data/error).
-- @param useAsync boolean Optional, defaults to true. Set false for synchronous operation.
function M.loadPlayer(username, callback, useAsync)
    if useAsync == false then
        local success, result = makeSyncRequest("GET", "/" .. username, nil)
        if callback then callback(success, result) end
        return success, result
    else
        makeAsyncRequest("GET", "/" .. username, nil, callback)
    end
end

--- Saves the current game state to the backend.
-- @param username string The player's username.
-- @param currency integer The current currency amount.
-- @param prestige_level integer The current prestige level.
-- @param additionalData table Optional additional data (reputation, xp, etc.).
-- @param callback function Optional function called on completion.
-- @param useAsync boolean Optional, defaults to true. Set false for synchronous operation.
function M.savePlayer(username, currency, prestige_level, additionalData, callback, useAsync)
    local data = {
        username = username,
        current_currency = currency,
        prestige_level = prestige_level
    }
    
    -- Add additional data if provided
    if additionalData then
        for key, value in pairs(additionalData) do
            data[key] = value
        end
    end
    
    if useAsync == false then
        local success, result = makeSyncRequest("POST", "/save", data)
        if callback then callback(success, result) end
        return success, result
    else
        makeAsyncRequest("POST", "/save", data, callback)
    end
end

-- ==========================================================
-- B. GLOBAL GAME STATE (Read-only from client)
-- ==========================================================

--- Gets the global game state (multipliers) from the backend.
-- @param callback function Called on completion (takes success, global_data/error).
-- @param useAsync boolean Optional, defaults to true. Set false for synchronous operation.
function M.getGlobalState(callback, useAsync)
    -- Use admin endpoint for global state
    local globalUrl = "http://localhost:5000/admin/global"
    
    local function makeGlobalRequest(method, data, isAsync)
        local responseBody = {}
        local options = {
            method = method,
            url = globalUrl,
            headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            sink = ltn12.sink.table(responseBody)
        }
        
        if isAsync == false then
            local result, statusCode = http.request(options)
            if result and statusCode and statusCode >= 200 and statusCode < 300 then
                local responseString = table.concat(responseBody)
                local decoded_data, err = json.decode(responseString)
                if decoded_data and not err then
                    return true, decoded_data
                else
                    return false, "JSON decode error: " .. (err or "unknown")
                end
            else
                return false, "HTTP error " .. (statusCode or "unknown")
            end
        end
    end
    
    if useAsync == false then
        local success, result = makeGlobalRequest("GET", nil, false)
        if callback then callback(success, result) end
        return success, result
    else
        -- For async, we'll use a similar approach but with a custom thread
        M.requestId = M.requestId + 1
        local requestId = M.requestId
        
        M.pendingRequests[requestId] = {
            callback = callback,
            startTime = love.timer.getTime()
        }
        
        local threadCode = string.format([[
            local json = require("dkjson")
            local http = require("socket.http")
            local ltn12 = require("ltn12")
            
            local url = %q
            local requestId = %d
            
            local responseBody = {}
            local options = {
                method = "GET",
                url = url,
                headers = {
                    ["Accept"] = "application/json"
                },
                sink = ltn12.sink.table(responseBody)
            }
            
            local result, statusCode = http.request(options)
            
            local response = {
                requestId = requestId,
                success = result and statusCode and statusCode >= 200 and statusCode < 300,
                statusCode = statusCode,
                body = table.concat(responseBody)
            }
            
            love.thread.getChannel("http_response"):push(response)
        ]], globalUrl, requestId)
        
        local thread = love.thread.newThread(threadCode)
        thread:start()
    end
end

-- ==========================================================
-- C. UTILITY FUNCTIONS
-- ==========================================================

--- Test the connection to the backend server.
-- @param callback function Called on completion (takes success, result/error).
-- @param useAsync boolean Optional, defaults to true.
function M.testConnection(callback, useAsync)
    local healthUrl = "http://localhost:5000/health"
    
    if useAsync == false then
        local responseBody = {}
        local result, statusCode = http.request{
            url = healthUrl,
            sink = ltn12.sink.table(responseBody)
        }
        
        local success = result and statusCode and statusCode == 200
        local message = success and table.concat(responseBody) or "Connection failed"
        
        if callback then callback(success, message) end
        return success, message
    else
        -- Async version using thread
        M.requestId = M.requestId + 1
        local requestId = M.requestId
        
        M.pendingRequests[requestId] = {
            callback = callback,
            startTime = love.timer.getTime()
        }
        
        local threadCode = string.format([[
            local http = require("socket.http")
            local ltn12 = require("ltn12")
            
            local url = %q
            local requestId = %d
            
            local responseBody = {}
            local result, statusCode = http.request{
                url = url,
                sink = ltn12.sink.table(responseBody)
            }
            
            local response = {
                requestId = requestId,
                success = result and statusCode and statusCode == 200,
                statusCode = statusCode,
                body = table.concat(responseBody)
            }
            
            love.thread.getChannel("http_response"):push(response)
        ]], healthUrl, requestId)
        
        local thread = love.thread.newThread(threadCode)
        thread:start()
    end
end

return M