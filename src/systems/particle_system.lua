-- Not implemented: src/systems/particle_system.lua
-- ======================================================================
-- I like the idea of a particle system for visual effects. Keeping it here for later development.
-- ======================================================================
-- Particle system for visual effects like money particles, achievement bursts, Incident alerts, and ambient effects
-- ======================================================================   


local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem.new(eventBus)
    local self = setmetatable({}, ParticleSystem)
    self.eventBus = eventBus
    
    -- Particle pools for efficiency
    self.particles = {}
    self.particleTypes = {}
    self.activeParticles = 0
    self.maxParticles = 200
    
    -- Initialize particle types
    self:initializeParticleTypes()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Initialize different particle effect types
function ParticleSystem:initializeParticleTypes()
    self.particleTypes = {
        -- Money particle effects
        money_gain = {
            lifetime = 1.5,
            speed = {min = 50, max = 100},
            gravity = -80,
            fade = true,
            color = {0.2, 0.9, 0.2, 1.0},
            size = {min = 8, max = 12},
            text = true
        },
        
        -- Achievement unlock burst
        achievement = {
            lifetime = 2.0,
            speed = {min = 80, max = 150},
            gravity = -50,
            fade = true,
            color = {1.0, 0.8, 0.2, 1.0},
            size = {min = 6, max = 10},
            burst = true,
            count = 15
        },
        
        -- Incident alert particles
        Incident_alert = {
            lifetime = 3.0,
            speed = {min = 30, max = 60},
            gravity = 0,
            fade = true,
            color = {1.0, 0.2, 0.2, 1.0},
            size = {min = 4, max = 8},
            pulse = true
        },
        
        -- Contract success sparkles
        contract_success = {
            lifetime = 1.8,
            speed = {min = 40, max = 90},
            gravity = -30,
            fade = true,
            color = {0.2, 0.7, 1.0, 1.0},
            size = {min = 5, max = 9},
            sparkle = true
        },
        
        -- Level up effects
        level_up = {
            lifetime = 2.5,
            speed = {min = 60, max = 120},
            gravity = -40,
            fade = true,
            color = {0.9, 0.9, 0.2, 1.0},
            size = {min = 10, max = 16},
            burst = true,
            count = 20
        },
        
        -- Ambient office particles
        ambient_office = {
            lifetime = 8.0,
            speed = {min = 5, max = 15},
            gravity = 0,
            fade = true,
            color = {0.8, 0.8, 0.9, 0.3},
            size = {min = 2, max = 4},
            drift = true
        }
    }
end

-- Subscribe to game events for particle effects
function ParticleSystem:subscribeToEvents()
    if not self.eventBus then return end
    
    -- Money effects
    self.eventBus:subscribe("currency_awarded", function(data)
        if data.currency == "money" and data.amount > 0 then
            local w, h = 800, 600 -- Default dimensions
            if love and love.graphics and love.graphics.getDimensions then
                w, h = love.graphics.getDimensions()
            end
            self:emitParticles("money_gain", w / 2, h / 2, {
                count = math.min(math.floor(data.amount / 100) + 1, 10),
                text = "$" .. data.amount
            })
        end
    end)
    
    -- Click reward effects (Phase 2)
    self.eventBus:subscribe("click_reward_earned", function(data)
        if data.amount > 0 then
            -- Use position from click data, default to money counter area
            local x = data.position and data.position.x or 150
            local y = data.position and data.position.y or 100
            
            self:emitParticles("money_gain", x, y, {
                count = math.min(math.floor(data.amount / 10) + 1, 5),
                text = "$" .. data.amount
            })
        end
    end)
    
    -- Achievement effects
    self.eventBus:subscribe("achievement_unlocked", function(data)
        local w, h = 800, 600 -- Default dimensions
        if love and love.graphics and love.graphics.getDimensions then
            w, h = love.graphics.getDimensions()
        end
        self:emitParticles("achievement", w / 2, h / 2 - 100, {
            text = data.achievement.title
        })
    end)
    
    -- Incident effects
    self.eventBus:subscribe("Incident_started", function(data)
        local w, h = 800, 600 -- Default dimensions
        if love and love.graphics and love.graphics.getDimensions then
            w, h = love.graphics.getDimensions()
        end
        self:emitParticles("Incident_alert", w / 2, 100, {
            count = 8
        })
    end)
    
    -- Contract success effects
    self.eventBus:subscribe("contract_completed", function(data)
        local w, h = 800, 600 -- Default dimensions
        if love and love.graphics and love.graphics.getDimensions then
            w, h = love.graphics.getDimensions()
        end
        self:emitParticles("contract_success", w / 2, h / 2, {
            count = 6
        })
    end)
    
    -- Level up effects
    self.eventBus:subscribe("tier_promoted", function(data)
        local w, h = 800, 600 -- Default dimensions
        if love and love.graphics and love.graphics.getDimensions then
            w, h = love.graphics.getDimensions()
        end
        self:emitParticles("level_up", w / 2, h / 2 - 50, {
            text = "LEVEL UP!"
        })
    end)
end

-- Emit particles of a specific type
function ParticleSystem:emitParticles(particleType, x, y, options)
    local particleSpec = self.particleTypes[particleType]
    if not particleSpec then return end
    
    options = options or {}
    local count = options.count or (particleSpec.burst and particleSpec.count) or 1
    
    for i = 1, count do
        if self.activeParticles >= self.maxParticles then
            break -- Don't exceed particle limit
        end
        
        local particle = self:createParticle(particleType, x, y, options)
        if particle then
            table.insert(self.particles, particle)
            self.activeParticles = self.activeParticles + 1
        end
    end
end

-- Create a single particle
function ParticleSystem:createParticle(particleType, x, y, options)
    local spec = self.particleTypes[particleType]
    if not spec then return nil end
    
    -- Random angle for burst effects
    local angle = math.random() * math.pi * 2
    local speed = spec.speed.min + math.random() * (spec.speed.max - spec.speed.min)
    
    -- Calculate velocity
    local vx, vy = 0, 0
    if spec.burst then
        vx = math.cos(angle) * speed
        vy = math.sin(angle) * speed
    elseif spec.drift then
        vx = (math.random() - 0.5) * speed
        vy = -speed * 0.3
    else
        vy = -speed
        vx = (math.random() - 0.5) * speed * 0.5
    end
    
    return {
        type = particleType,
        x = x + (math.random() - 0.5) * 20, -- Small random offset
        y = y + (math.random() - 0.5) * 10,
        vx = vx,
        vy = vy,
        life = spec.lifetime,
        maxLife = spec.lifetime,
        size = spec.size.min + math.random() * (spec.size.max - spec.size.min),
        color = {spec.color[1], spec.color[2], spec.color[3], spec.color[4]},
        rotation = math.random() * math.pi * 2,
        rotationSpeed = (math.random() - 0.5) * 4,
        text = options.text,
        pulsePhase = math.random() * math.pi * 2
    }
end

-- Update all particles
function ParticleSystem:update(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        local spec = self.particleTypes[particle.type]
        
        -- Update position
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Apply gravity
        particle.vy = particle.vy + spec.gravity * dt
        
        -- Update rotation
        particle.rotation = particle.rotation + particle.rotationSpeed * dt
        
        -- Update life
        particle.life = particle.life - dt
        
        -- Update alpha for fade effect
        if spec.fade then
            particle.color[4] = (particle.life / particle.maxLife) * spec.color[4]
        end
        
        -- Update pulse effect
        if spec.pulse then
            particle.pulsePhase = particle.pulsePhase + dt * 6
            local pulseFactor = 0.5 + 0.5 * math.sin(particle.pulsePhase)
            particle.size = spec.size.min + pulseFactor * (spec.size.max - spec.size.min)
        end
        
        -- Remove dead particles
        if particle.life <= 0 then
            table.remove(self.particles, i)
            self.activeParticles = self.activeParticles - 1
        end
    end
    
    -- Emit ambient particles occasionally
    if math.random() < dt * 0.5 then
        local w, h = love.graphics.getDimensions()
        self:emitParticles("ambient_office", math.random() * w, h + 10)
    end
end

-- Draw all particles
function ParticleSystem:draw()
    if not love.graphics then return end
    
    for _, particle in ipairs(self.particles) do
        love.graphics.push()
        
        -- Set particle color
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.color[4])
        
        -- Translate to particle position
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        
        -- Draw particle based on type
        if particle.text and particle.life > particle.maxLife * 0.7 then
            -- Draw text for money/achievement particles
            love.graphics.printf(particle.text, -50, -particle.size/2, 100, "center")
        elseif self.particleTypes[particle.type].sparkle then
            -- Draw sparkle particles (star shape)
            self:drawStar(0, 0, particle.size)
        else
            -- Draw regular circle particles
            love.graphics.circle("fill", 0, 0, particle.size)
        end
        
        love.graphics.pop()
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a star shape for sparkle particles
function ParticleSystem:drawStar(x, y, radius)
    local points = {}
    local numPoints = 5
    
    for i = 0, numPoints * 2 - 1 do
        local angle = (i * math.pi) / numPoints
        local r = (i % 2 == 0) and radius or radius * 0.4
        local px = x + r * math.cos(angle - math.pi / 2)
        local py = y + r * math.sin(angle - math.pi / 2)
        table.insert(points, px)
        table.insert(points, py)
    end
    
    if #points >= 6 then
        love.graphics.polygon("fill", points)
    end
end

-- Emit burst effect at specific location
function ParticleSystem:emitBurst(particleType, x, y, count, options)
    options = options or {}
    options.count = count or 10
    self:emitParticles(particleType, x, y, options)
end

-- Clear all particles (useful for scene transitions)
function ParticleSystem:clear()
    self.particles = {}
    self.activeParticles = 0
end

-- Get particle statistics
function ParticleSystem:getStats()
    local typeCount = 0
    for _ in pairs(self.particleTypes) do
        typeCount = typeCount + 1
    end
    
    return {
        active = self.activeParticles,
        max = self.maxParticles,
        types = typeCount
    }
end

-- Set maximum particle count
function ParticleSystem:setMaxParticles(count)
    self.maxParticles = math.max(50, math.min(500, count))
end

-- Enable/disable ambient particles
function ParticleSystem:setAmbientEnabled(enabled)
    self.ambientEnabled = enabled
    if not enabled then
        -- Remove ambient particles
        for i = #self.particles, 1, -1 do
            local particle = self.particles[i]
            if particle.type == "ambient_office" then
                table.remove(self.particles, i)
                self.activeParticles = self.activeParticles - 1
            end
        end
    end
end

-- Manual particle emission for special effects
function ParticleSystem:emitMoneyRain(x, y, amount)
    local particleCount = math.min(math.floor(amount / 500) + 3, 15)
    for i = 1, particleCount do
        local offsetX = (math.random() - 0.5) * 100
        local offsetY = (math.random() - 0.5) * 50
        self:emitParticles("money_gain", x + offsetX, y + offsetY, {
            text = "$" .. math.floor(amount / particleCount)
        })
    end
end

return ParticleSystem