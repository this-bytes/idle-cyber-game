-- Room Ambiance System
-- Provides atmospheric audio and visual suggestions for different room environments

local RoomAmbiance = {}

-- Room-specific ambiance definitions
RoomAmbiance.profiles = {
    personal_office = {
        name = "Executive Focus",
        description = "Quiet, professional atmosphere for strategic thinking",
        
        -- Visual effects
        lighting = {
            ambient = {0.8, 0.85, 0.9, 0.3},
            accent = {1.0, 1.0, 0.8, 0.4},
            mood = "focused_warm"
        },
        
        -- Audio suggestions (for future implementation)
        audio = {
            background = "quiet_office_hum.ogg",
            interactions = {
                "keyboard_typing.wav",
                "paper_shuffle.wav", 
                "phone_ring.wav",
                "pen_click.wav"
            },
            ambient_volume = 0.3,
            interaction_volume = 0.6
        },
        
        -- Particle effects
        particles = {
            dust_motes = { count = 5, speed = 0.1, alpha = 0.2 },
            screen_glow = { intensity = 0.3, color = {0.3, 0.5, 1.0} }
        },
        
        -- Environmental details
        details = {
            "Soft light from desk lamp",
            "Gentle hum of computer equipment", 
            "Professional certificates on wall",
            "Strategic planning documents visible"
        }
    },
    
    main_office_floor = {
        name = "Collaborative Energy",
        description = "Dynamic workspace with team activity and productivity",
        
        lighting = {
            ambient = {0.9, 0.95, 1.0, 0.4},
            accent = {0.7, 0.9, 1.0, 0.5},
            mood = "bright_energetic"
        },
        
        audio = {
            background = "office_activity.ogg",
            interactions = {
                "keyboard_chorus.wav",
                "team_discussion.wav",
                "printer_sounds.wav",
                "phone_chatter.wav"
            },
            ambient_volume = 0.5,
            interaction_volume = 0.7
        },
        
        particles = {
            activity_indicators = { count = 12, movement = "busy", alpha = 0.4 },
            collaboration_sparks = { frequency = 0.2, color = {1.0, 0.8, 0.3} }
        },
        
        details = {
            "Multiple workstations with active screens",
            "Team members collaborating",
            "Whiteboards with technical diagrams",
            "Coffee cups and productivity tools"
        }
    },
    
    hr_office = {
        name = "Human Focus",
        description = "Professional environment centered on people and development",
        
        lighting = {
            ambient = {0.95, 0.9, 0.95, 0.35},
            accent = {0.9, 0.7, 0.9, 0.4},
            mood = "professional_warm"
        },
        
        audio = {
            background = "quiet_professional.ogg",
            interactions = {
                "interview_discussion.wav",
                "file_cabinet.wav",
                "phone_conversation.wav",
                "training_materials.wav"
            },
            ambient_volume = 0.25,
            interaction_volume = 0.5
        },
        
        particles = {
            document_flow = { count = 3, pattern = "organized", alpha = 0.3 },
            people_energy = { warmth = 0.6, color = {1.0, 0.9, 0.7} }
        },
        
        details = {
            "Professional interview setup",
            "Personnel files and training materials",
            "Comfortable seating area",
            "Team development resources"
        }
    },
    
    kitchen_break_room = {
        name = "Social Warmth",
        description = "Relaxed social space promoting team bonding and creativity",
        
        lighting = {
            ambient = {1.0, 0.9, 0.8, 0.4},
            accent = {1.0, 0.8, 0.6, 0.5},
            mood = "warm_social"
        },
        
        audio = {
            background = "kitchen_ambiance.ogg",
            interactions = {
                "coffee_brewing.wav",
                "casual_conversation.wav",
                "microwave_beep.wav",
                "laughter.wav"
            },
            ambient_volume = 0.4,
            interaction_volume = 0.6
        },
        
        particles = {
            coffee_steam = { count = 8, rise_speed = 0.3, alpha = 0.3 },
            warmth_glow = { radius = 60, color = {1.0, 0.8, 0.6} }
        },
        
        details = {
            "Steam rising from coffee machines",
            "Comfortable seating arrangements",
            "Informal meeting spaces",
            "Warm, inviting atmosphere"
        }
    },
    
    server_room = {
        name = "Technical Precision", 
        description = "High-tech environment with critical infrastructure systems",
        
        lighting = {
            ambient = {0.6, 0.8, 1.0, 0.3},
            accent = {0.3, 1.0, 0.8, 0.6},
            mood = "cool_technical"
        },
        
        audio = {
            background = "server_room_hum.ogg",
            interactions = {
                "server_fans.wav",
                "network_activity.wav", 
                "cooling_systems.wav",
                "alert_beeps.wav"
            },
            ambient_volume = 0.6,
            interaction_volume = 0.8
        },
        
        particles = {
            data_streams = { count = 20, speed = 2.0, pattern = "flowing", alpha = 0.4 },
            status_lights = { blink_rate = 0.8, colors = {{0,1,0}, {1,1,0}, {1,0,0}} },
            cooling_mist = { density = 0.1, movement = "gentle_flow" }
        },
        
        details = {
            "Rows of server racks with blinking lights",
            "Climate control systems active",
            "Network cables and infrastructure",
            "Security monitoring displays"
        }
    },
    
    conference_room = {
        name = "Professional Presence",
        description = "Impressive space designed for client meetings and presentations",
        
        lighting = {
            ambient = {0.9, 0.95, 1.0, 0.35},
            accent = {1.0, 1.0, 0.95, 0.5},  
            mood = "professional_bright"
        },
        
        audio = {
            background = "conference_room.ogg",
            interactions = {
                "presentation_click.wav",
                "meeting_discussion.wav",
                "video_conference.wav",
                "whiteboard_marker.wav"
            },
            ambient_volume = 0.2,
            interaction_volume = 0.5
        },
        
        particles = {
            presentation_glow = { source = "screen", intensity = 0.4 },
            professional_atmosphere = { sophistication = 0.8, alpha = 0.25 }
        },
        
        details = {
            "Large conference table with executive chairs",
            "High-resolution presentation displays",
            "Professional lighting and acoustics",
            "Polished, impressive appearance"
        }
    },
    
    emergency_response_center = {
        name = "Crisis Command",
        description = "High-intensity command center for rapid crisis response",
        
        lighting = {
            ambient = {1.0, 0.3, 0.3, 0.4},
            accent = {1.0, 0.8, 0.0, 0.7},
            mood = "alert_urgent"
        },
        
        audio = {
            background = "command_center.ogg",
            interactions = {
                "alert_klaxon.wav",
                "radio_chatter.wav",
                "urgent_typing.wav",
                "coordination_calls.wav"
            },
            ambient_volume = 0.7,
            interaction_volume = 0.9
        },
        
        particles = {
            alert_pulses = { rate = 1.5, intensity = 0.8, color = {1.0, 0.2, 0.2} },
            radar_sweeps = { rotation_speed = 2.0, range = 100, alpha = 0.5 },
            urgency_indicators = { count = 15, movement = "rapid", colors = "warning_palette" }
        },
        
        details = {
            "Multiple monitoring screens showing threat data",
            "Emergency communication systems",
            "Rapid response coordination center",
            "High-stress operational environment"
        }
    }
}

-- Get ambiance profile for a room
function RoomAmbiance.getProfile(roomId)
    return RoomAmbiance.profiles[roomId] or RoomAmbiance.profiles.personal_office
end

-- Apply visual ambiance effects
function RoomAmbiance.applyVisualEffects(roomId, graphics)
    local profile = RoomAmbiance.getProfile(roomId)
    if not profile or not graphics then return end
    
    -- Apply ambient lighting if Love2D graphics context available
    if profile.lighting and profile.lighting.ambient then
        local ambient = profile.lighting.ambient
        -- This would be implemented when Love2D is available
        -- graphics.setColor(ambient[1], ambient[2], ambient[3], ambient[4])
    end
end

-- Get audio cues for room (for future audio implementation)
function RoomAmbiance.getAudioCues(roomId)
    local profile = RoomAmbiance.getProfile(roomId)
    return profile.audio or {}
end

-- Get environmental details for narrative/UI display
function RoomAmbiance.getEnvironmentalDetails(roomId)
    local profile = RoomAmbiance.getProfile(roomId)
    return profile.details or {}
end

-- Suggest particle effects for room
function RoomAmbiance.getParticleEffects(roomId)
    local profile = RoomAmbiance.getProfile(roomId)
    return profile.particles or {}
end

-- Get mood descriptor for room
function RoomAmbiance.getMood(roomId)
    local profile = RoomAmbiance.getProfile(roomId)
    return (profile.lighting and profile.lighting.mood) or "neutral"
end

-- Get atmospheric description
function RoomAmbiance.getDescription(roomId)
    local profile = RoomAmbiance.getProfile(roomId)
    return profile.description or "Standard office environment"
end

return RoomAmbiance