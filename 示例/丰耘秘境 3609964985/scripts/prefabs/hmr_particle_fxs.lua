local prefs = {}

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function MakeFX(name, data)
    local TEXTURE = resolvefilepath(data.texture)

    local SHADER = data.shader or "shaders/vfx_particle.ksh"

    local COLOUR_ENVELOPE_NAME = name.."_colourenvelope"
    local SCALE_ENVELOPE_NAME = name.."_scaleenvelope"

    local DEFAULT_COLOR_ENVELOPE = {
        { 0,    IntColour(255, 255, 255, 0) },
        { 0.1,  IntColour(255, 255, 255, 200) },
        { 0.9,  IntColour(255, 255, 255, 200) },
        { 1,    IntColour(255, 255, 255, 0) },
    }
    local DEFAULT_SCALE_ENVELOPE = {
        { 0,    { 1.5, 1.5 } },
        { 0.5,  { 1.5, 1.5 } },
        { 1,    { 1.5, 1.5 } },
    }

    local assets =
    {
        Asset("IMAGE", TEXTURE),
        Asset("SHADER", SHADER),
    }

    --------------------------------------------------------------------------

    local function InitEnvelope()
        EnvelopeManager:AddColourEnvelope(
            COLOUR_ENVELOPE_NAME,
            data.colour_envelope or DEFAULT_COLOR_ENVELOPE
        )

        EnvelopeManager:AddVector2Envelope(
            SCALE_ENVELOPE_NAME,
            data.scale_envelope or DEFAULT_SCALE_ENVELOPE
        )

        InitEnvelope = nil
        IntColour = nil
    end

    --------------------------------------------------------------------------
    local MAX_LIFETIME = data.max_lifetime or 4.5

    local function emit_fn(effect, emitter_fn)
        local vx = data.vx or 0.06 * UnitRand()
        local vy = data.vy or -0.15 + 0.06 * (UnitRand() - 1)
        local vz = data.vz or 0.06 * UnitRand()

        local lifetime = MAX_LIFETIME * (.6 + math.random() * .4)
        local px, py, pz = emitter_fn()

        local angle = data.angle and data.angle() or math.random() * 360
        local uv_offset = data.uv_offset~= nil and math.random(0, data.uv_offset.num-1) * (1 / data.uv_offset.num) or 0
        local ang_vel = data.ang_vel and data.ang_vel() or UnitRand() * 2

        effect:AddRotatingParticleUV(
            0,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            angle, ang_vel,     -- angle, angular_velocity
            uv_offset, 0        -- uv offset
        )
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.entity:SetPristine()

        inst.persists = false

        --Dedicated server does not need to spawn local particle fx
        if TheNet:IsDedicated() then
            return inst
        elseif InitEnvelope ~= nil then
            InitEnvelope()
        end

        local effect = inst.entity:AddVFXEffect()
        effect:InitEmitters(1)

        --SNOW
        effect:SetRenderResources(0, TEXTURE, SHADER)
        effect:SetRotationStatus(0, true)
        effect:SetGroundPhysics(0, true)
        if data.uv_offset ~= nil then
            effect:SetUVFrameSize(0, 1 / data.uv_offset.num, 1)
        end
        effect:SetMaxNumParticles(0, 200)
        effect:SetMaxLifetime(0, MAX_LIFETIME)
        effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
        effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
        effect:SetBlendMode(0, BLENDMODE.Premultiplied)
        --effect:EnableBloomPass(0, true)
        effect:SetSortOrder(0, 0)
        effect:SetSortOffset(0, 0)

        -----------------------------------------------------

        local tick_time = TheSim:GetTickTime()

        local desired_pps_low = data.num_to_emit and data.num_to_emit.low or 3
        local desired_pps_high = data.num_to_emit and data.num_to_emit.high or 50
        local low_per_tick = desired_pps_low * tick_time
        local high_per_tick = desired_pps_high * tick_time
        local num_to_emit = 0

        local emitter_fn = CreateBoxEmitter( data.x1 or -0.1, data.y1 or -0.3, data.z1 or -0.1, data.x2 or 0.1, data.y2 or 0.2, data.z2 or 0.1 )
        inst.last_pos = inst:GetPosition()

        EmitterManager:AddEmitter(inst, nil, function()
            local dist_moved = inst:GetPosition() - inst.last_pos
            local move = dist_moved:Length()
            move = math.clamp((move - 0.2) * 10, 0, 1)

            local per_tick = Lerp(low_per_tick, high_per_tick, move)

            inst.last_pos = inst:GetPosition()

            num_to_emit = per_tick-- num_to_emit + per_tick * math.random() * 3
            while num_to_emit > 0 do
                emit_fn(effect, emitter_fn)
                num_to_emit = num_to_emit - 1
            end
        end)

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

local fxs_data = {
    hmr_cherry_flower_fx = {
        texture = "images/fx/hmr_cherry_flower.tex",
        shader = "shaders/vfx_particle.ksh",
        color_envelope = {
            { 0,    IntColour(255, 182, 193, 0) },  -- 樱花粉色，完全透明
            { 0.2,  IntColour(255, 182, 193, 255) },  -- 樱花粉色，完全不透明
            { 0.4,  IntColour(255, 228, 225, 255) },  -- 渐变为较浅的粉色
            { 0.6,  IntColour(255, 240, 245, 255) },  -- 渐变为更浅的粉色
            { 0.8,  IntColour(255, 250, 240, 255) },  -- 渐变为接近米白色的粉色
            { 1,    IntColour(255, 255, 255, 0) },  -- 米白色，完全透明
        },
        scale_envelope = {
            { 0,    { 0.4, 0.4 } },
            { 0.2,  { 0.45, 0.45 } },
            { 0.4,  { 0.5, 0.5 } },
            { 0.6,  { 0.45, 0.45 } },
            { 0.8,  { 0.4, 0.4 } },
            { 1,    { 0.35, 0.35 } },
        },
        max_lifetime = 2.0,

        vx = 0.006 * UnitRand(),
        vy = -0.015 + 0.006 * (UnitRand() - 1),
        vz = 0.006 * UnitRand(),

        angle = function() return math.random() * 360 end,
        ang_vel = function() return (UnitRand() - 1) * 2 end,

        uv_offset = {num = 4, size = 128},

        --[[*初始位置
            粒子的初始位置位于一个长方体的小盒子内
            x1,y1,z1是小盒子的左下角坐标
            x2,y2,z2是小盒子的右上角坐标
            单位：墙单位
        ]]
        x1 = -0.1,
        y1 = -0.1,
        z1 = -0.1,
        x2 = 0.1,
        y2 = 0.2,
        z2 = 0.1,

        -- 粒子数量
        num_to_emit = {low = 0, high = 15},
    }
}

for name, data in pairs(fxs_data) do
    MakeFX(name, data)
end

return unpack(prefs)
