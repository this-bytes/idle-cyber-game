-- Not Implemented Yet
-- Appart of a room system i was thinking of
-- Sound System - Advanced audio management for immersive experience
-- Handles dynamic sound effects, ambient tracks, and reactive audio

local SoundSystem = {}
SoundSystem.__index = SoundSystem

function SoundSystem.new(eventBus)
    local self = setmetatable({}, SoundSystem)
    self.eventBus = eventBus
    
    -- Audio state management
    self.sounds = {}
    self.ambientTracks = {}
    self.currentAmbient = nil
    self.masterVolume = 0.7
    self.sfxVolume = 1.0
    self.musicVolume = 0.6
    self.enabled = true
    
    -- Sound categories for better organization
    self.categories = {
        ui = {},
        gameplay = {},
        ambient = {},
        crisis = {},
        success = {}
    }
    
    -- Load sound assets
    self:loadSoundAssets()
    
    -- Subscribe to game events for reactive audio
    self:subscribeToEvents()
    
    return self
end

-- Load sound assets (with placeholder generation)
function SoundSystem:loadSoundAssets()
    -- Define sound profiles for procedural generation
    self.soundProfiles = {
        -- UI Sounds
        ui_click = {type = "click", frequency = 800, duration = 0.1},
        ui_hover = {type = "hover", frequency = 600, duration = 0.05},
        ui_success = {type = "success", frequency = 1200, duration = 0.3, volume = 0.5},
        ui_error = {type = "error", frequency = 300, duration = 0.2, volume = 0.7},
        ui_notification = {type = "notification", frequency = 900, duration = 0.4},
        
        -- Gameplay Sounds
        contract_accept = {type = "accept", frequency = 1000, duration = 0.5, volume = 0.6},
        contract_complete = {type = "complete", frequency = 1400, duration = 0.7, volume = 0.8},
        money_earned = {type = "earn", frequency = 1100, duration = 0.3, volume = 0.7},
        level_up = {type = "levelup", frequency = 1600, duration = 1.0, volume = 0.9},
        achievement_unlock = {type = "achievement", frequency = 1500, duration = 1.2, volume = 1.0},
        
        -- Crisis Sounds
        crisis_alert = {type = "alert", frequency = 400, duration = 2.0, volume = 1.0, urgent = true},
        crisis_resolved = {type = "resolved", frequency = 1300, duration = 0.8, volume = 0.8},
        crisis_failed = {type = "failed", frequency = 200, duration = 1.5, volume = 0.9},
        
        -- Ambient Sounds
        office_ambient = {type = "ambient", frequency = 100, duration = -1, volume = 0.3, loop = true},
        datacenter_ambient = {type = "ambient", frequency = 150, duration = -1, volume = 0.4, loop = true}
    }
    
    -- Try to load actual audio files, fall back to procedural generation
    for soundId, profile in pairs(self.soundProfiles) do
        local loaded = self:tryLoadAudioFile(soundId)
        if not loaded then
            self.sounds[soundId] = {
                profile = profile,
                procedural = true
            }
        end
    end
    
    print("🎵 Sound system initialized with " .. self:countLoadedSounds() .. " sounds")
end

-- Try to load actual audio file
function SoundSystem:tryLoadAudioFile(soundId)
    if not love or not love.audio then return false end
    
    local paths = {
        "assets/sfx/" .. soundId .. ".ogg",
        "assets/sfx/" .. soundId .. ".wav",
        "assets/sounds/" .. soundId .. ".ogg",
        "assets/audio/" .. soundId .. ".ogg"
    }
    
    for _, path in ipairs(paths) do
        local success, source = pcall(love.audio.newSource, path, "static")
        if success and source then
            self.sounds[soundId] = {
                source = source,
                procedural = false
            }
            return true
        end
    end
    
    return false
end

-- Subscribe to game events for reactive audio
function SoundSystem:subscribeToEvents()
    if not self.eventBus then return end
    
    -- UI Events
    self.eventBus:subscribe("ui.click", function(data) 
        self:playSound("ui_click") 
    end)
    
    self.eventBus:subscribe("ui.hover", function(data) 
        if data and data.playSound then
            self:playSound("ui_hover") 
        end
    end)
    
    self.eventBus:subscribe("ui.success", function(data) 
        self:playSound("ui_success") 
    end)
    
    self.eventBus:subscribe("ui.error", function(data) 
        self:playSound("ui_error") 
    end)
    
    -- Gameplay Events
    self.eventBus:subscribe("contract_accepted", function(data)
        self:playSound("contract_accept")
    end)
    
    self.eventBus:subscribe("contract_completed", function(data)
        self:playSound("contract_complete")
        -- Play money earned sound with slight delay
        self:scheduleSound("money_earned", 0.3)
    end)
    
    self.eventBus:subscribe("currency_awarded", function(data)
        if data.currency == "money" and data.amount > 0 then
            self:playSound("money_earned", {pitch = self:calculateMoneyPitch(data.amount)})
        end
    end)
    
    self.eventBus:subscribe("achievement_unlocked", function(data)
        self:playSound("achievement_unlock")
    end)
    
    self.eventBus:subscribe("tier_promoted", function(data)
        self:playSound("level_up")
    end)
    
    -- Crisis Events
    self.eventBus:subscribe("crisis_started", function(data)
        self:playSound("crisis_alert")
        self:setAmbientTrack("crisis_ambient")
    end)
    
    self.eventBus:subscribe("crisis_resolved", function(data)
        self:playSound("crisis_resolved")
        self:setAmbientTrack("office_ambient")
    end)
    
    self.eventBus:subscribe("crisis_failed", function(data)
        self:playSound("crisis_failed")
        self:setAmbientTrack("office_ambient")
    end)
    
    -- Location Events
    self.eventBus:subscribe("location_changed", function(data)
        local ambientTrack = self:getAmbientForLocation(data.newLocation)
        if ambientTrack then
            self:setAmbientTrack(ambientTrack)
        end
    end)
end

-- Play a sound effect
function SoundSystem:playSound(soundId, options)
    if not self.enabled then return end
    
    local sound = self.sounds[soundId]
    if not sound then return end
    
    options = options or {}
    local volume = (options.volume or 1.0) * self.sfxVolume * self.masterVolume
    
    if sound.procedural then
        self:playProceduralSound(sound.profile, volume, options)
    elseif sound.source then
        sound.source:setVolume(volume)
        if options.pitch then
            sound.source:setPitch(options.pitch)
        end
        if love and love.audio then
            love.audio.play(sound.source)
        end
    end
end

-- Generate and play procedural sound
function SoundSystem:playProceduralSound(profile, volume, options)
    -- TODO: Implement procedural audio generation
    -- For now, just print what would be played
    local pitch = options.pitch or 1.0
    local freq = profile.frequency * pitch
    
    if profile.urgent then
        print("🚨 [URGENT SOUND] " .. profile.type .. " @ " .. freq .. "Hz")
    else
        print("🎵 [SOUND] " .. profile.type .. " @ " .. freq .. "Hz (vol: " .. math.floor(volume * 100) .. "%)")
    end
end

-- Schedule a sound to play after a delay
function SoundSystem:scheduleSound(soundId, delay, options)
    -- TODO: Implement sound scheduling system
    print("⏰ [SCHEDULED] " .. soundId .. " in " .. delay .. "s")
end

-- Calculate pitch based on money amount (higher amounts = higher pitch)
function SoundSystem:calculateMoneyPitch(amount)
    local basePitch = 1.0
    local pitchMultiplier = math.min(2.0, 1.0 + (amount / 10000))
    return basePitch * pitchMultiplier
end

-- Set ambient track
function SoundSystem:setAmbientTrack(trackId)
    if not self.enabled then return end
    
    -- Stop current ambient
    if self.currentAmbient then
        self:stopAmbient()
    end
    
    local track = self.sounds[trackId]
    if track and track.source then
        track.source:setVolume(self.musicVolume * self.masterVolume)
        track.source:setLooping(true)
        if love and love.audio then
            love.audio.play(track.source)
        end
        self.currentAmbient = trackId
        print("🎼 Ambient track: " .. trackId)
    end
end

-- Stop current ambient track
function SoundSystem:stopAmbient()
    if self.currentAmbient then
        local track = self.sounds[self.currentAmbient]
        if track and track.source then
            if love and love.audio then
                love.audio.stop(track.source)
            end
        end
        self.currentAmbient = nil
    end
end

-- Get appropriate ambient track for location
function SoundSystem:getAmbientForLocation(location)
    local ambientMap = {
        ["datacenter"] = "datacenter_ambient",
        ["server_room"] = "datacenter_ambient", 
        ["office"] = "office_ambient",
        ["home_office"] = "office_ambient"
    }
    
    -- Extract location type from full location path
    for locType, ambient in pairs(ambientMap) do
        if string.find(location or "", locType) then
            return ambient
        end
    end
    
    return "office_ambient" -- Default
end

-- Update method (for sound processing)
function SoundSystem:update(dt)
    -- TODO: Update scheduled sounds, fade effects, etc.
end

-- Volume controls
function SoundSystem:setMasterVolume(volume)
    self.masterVolume = math.max(0, math.min(1, volume))
end

function SoundSystem:setSFXVolume(volume)
    self.sfxVolume = math.max(0, math.min(1, volume))
end

function SoundSystem:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    
    -- Update current ambient track volume
    if self.currentAmbient then
        local track = self.sounds[self.currentAmbient]
        if track and track.source then
            track.source:setVolume(self.musicVolume * self.masterVolume)
        end
    end
end

-- Toggle sound system
function SoundSystem:toggle()
    self.enabled = not self.enabled
    if not self.enabled then
        self:stopAmbient()
    end
    return self.enabled
end

-- Utility methods
function SoundSystem:countLoadedSounds()
    local count = 0
    for _ in pairs(self.sounds) do
        count = count + 1
    end
    return count
end

function SoundSystem:isEnabled()
    return self.enabled
end

-- Get state for saving
function SoundSystem:getState()
    return {
        masterVolume = self.masterVolume,
        sfxVolume = self.sfxVolume,
        musicVolume = self.musicVolume,
        enabled = self.enabled,
        currentAmbient = self.currentAmbient
    }
end

-- Load state
function SoundSystem:loadState(state)
    if not state then return end
    
    self.masterVolume = state.masterVolume or 0.7
    self.sfxVolume = state.sfxVolume or 1.0
    self.musicVolume = state.musicVolume or 0.6
    self.enabled = state.enabled ~= false
    
    if state.currentAmbient then
        self:setAmbientTrack(state.currentAmbient)
    end
end

return SoundSystem