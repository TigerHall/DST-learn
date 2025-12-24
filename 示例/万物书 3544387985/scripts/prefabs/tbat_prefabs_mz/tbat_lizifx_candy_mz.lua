local RESOURCES = {
    TEXTURES = {
        BOW = resolvefilepath("fx/tbat_lizifx_bow.tex"),
        RABBIT = resolvefilepath("fx/tbat_lizifx_rabbit.tex"),
        CHOCOLATE = resolvefilepath("fx/tbat_lizifx_chocolate.tex"),
        CANDY = resolvefilepath("fx/tbat_lizifx_candy.tex"),
    },
    SHADER = "shaders/vfx_particle.ksh",
}

local EFFECT_CONFIGS = {
    BOW = {
        envelope_suffix = "bow",
        max_scale = 0.5,
        end_scale = 0.8,
        uv_frame_size = 1 / 4,
        uv_divisions = 4
    },
    RABBIT = {
        envelope_suffix = "rabbit",
        max_scale = 0.5,
        end_scale = 0.8,
        uv_frame_size = 1 / 4,
        uv_divisions = 4
    },
    CHOCOLATE = {
        envelope_suffix = "chocolate",
        max_scale = 0.33,
        end_scale = 0.66,
        uv_frame_size = 1 / 8,
        uv_divisions = 8
    },
    CANDY = {
        envelope_suffix = "candy",
        max_scale = 0.33,
        end_scale = 0.66,
        uv_frame_size = 1 / 8,
        uv_divisions = 8
    },
}

local assets = {}
for _, tex in pairs(RESOURCES.TEXTURES) do
    table.insert(assets, Asset("IMAGE", tex))
end
table.insert(assets, Asset("SHADER", RESOURCES.SHADER))

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()
    for effect_type, config in pairs(EFFECT_CONFIGS) do
        local color_envelope_name = "tbat_lizifx_" .. config.envelope_suffix .. "_colourenvelope"
        EnvelopeManager:AddColourEnvelope(color_envelope_name, {
            { 0,   IntColour(255, 255, 255, 255) },
            { 0.5, IntColour(255, 255, 255, 255) },
            { 1,   IntColour(255, 255, 255, 0) },
        })

        local scale_envelope_name = "tbat_lizifx_" .. config.envelope_suffix .. "_scaleenvelope"
        EnvelopeManager:AddVector2Envelope(scale_envelope_name, {
            { 0,   { config.max_scale, config.max_scale } },
            { 0.5, { config.max_scale, config.max_scale } },
            { 1,   { config.end_scale * config.max_scale, config.end_scale * config.max_scale } },
        })
    end

    InitEnvelope = nil
    IntColour = nil
end

local MAX_LIFETIME = 2

local function emit_particle_fn(effect, i, spark_sphere_emitter, uv_divisions)
    local lifetime = MAX_LIFETIME * (0.5 + UnitRand() * 0.5)
    local px, py, pz = spark_sphere_emitter()
    local vx, vy, vz = px * 0.33, -0.1 + py * 0.1, pz * 0.33

    local angle = math.random() * 360
    local uv_offset = math.random(0, uv_divisions - 1) / uv_divisions
    local ang_vel = (UnitRand() - 1) * 5

    effect:AddRotatingParticleUV(
        i,
        lifetime,
        px, py, pz,
        vx, vy, vz,
        angle, ang_vel,
        uv_offset, 0
    )
end

local function createParticleEffectFn(effectType, texture, config)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst.entity:SetPristine()
        inst.persists = false

        -- Dedicated server does not need to spawn local particle fx
        if TheNet:IsDedicated() then
            return inst
        elseif InitEnvelope ~= nil then
            InitEnvelope()
        end

        local effect = inst.entity:AddVFXEffect()
        effect:InitEmitters(1)
        effect:SetRenderResources(0, texture, RESOURCES.SHADER)
        effect:SetRotationStatus(0, true)
        effect:SetUVFrameSize(0, config.uv_frame_size, 1)
        effect:SetMaxNumParticles(0, 75)
        effect:SetMaxLifetime(0, MAX_LIFETIME)
        effect:SetColourEnvelope(0, "tbat_lizifx_" .. config.envelope_suffix .. "_colourenvelope")
        effect:SetScaleEnvelope(0, "tbat_lizifx_" .. config.envelope_suffix .. "_scaleenvelope")
        effect:SetBlendMode(0, BLENDMODE.Premultiplied)
        effect:EnableBloomPass(0, true)
        effect:SetSortOrder(0, 0)
        effect:SetSortOffset(0, 0)
        effect:SetDragCoefficient(0, 0.1)

        -----------------------------------------------------
        local tick_time = TheSim:GetTickTime()
        local desired_pps_low = 3
        local desired_pps_high = 15
        local low_per_tick = desired_pps_low * tick_time
        local high_per_tick = desired_pps_high * tick_time
        local num_to_emit = 0

        local emitter_fn = CreateSphereEmitter(0.25)
        inst.last_pos = inst:GetPosition()

        EmitterManager:AddEmitter(inst, nil, function()
            local dist_moved = inst:GetPosition() - inst.last_pos
            local move = dist_moved:Length()
            move = math.clamp(move * 6, 0, 1)

            local per_tick = Lerp(low_per_tick, high_per_tick, move)
            inst.last_pos = inst:GetPosition()

            num_to_emit = num_to_emit + per_tick * math.random() * 3
            while num_to_emit > 1 do
                emit_particle_fn(effect, 0, emitter_fn, config.uv_divisions)
                num_to_emit = num_to_emit - 1
            end
        end)

        return inst
    end
end

local prefabs = {}
for effect_type, config in pairs(EFFECT_CONFIGS) do
    local fn = createParticleEffectFn(effect_type, RESOURCES.TEXTURES[effect_type], config)
    table.insert(prefabs, Prefab("tbat_lizifx_" .. config.envelope_suffix, fn, assets))
end

return unpack(prefabs)
