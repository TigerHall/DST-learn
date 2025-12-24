
local RESOURCES = {
    TEXTURES = {
        BLOOMER = resolvefilepath("fx/tbat_lizifx_bflower.tex"),
        GREENFLOWER = resolvefilepath("fx/tbat_lizifx_gflower.tex"),
        GHOST = resolvefilepath("fx/tbat_lizifx_ghost.tex"),
        REDFLOWER = resolvefilepath("fx/tbat_lizifx_rflower.tex"),
        ROSE = resolvefilepath("fx/tbat_lizifx_rose.tex"),
        STAR = resolvefilepath("fx/tbat_lizifx_star.tex"),
    },
    SHADER = "shaders/vfx_particle.ksh",
}

local COLOUR_ENVELOPES = {
    BLOOMER = "tbat_lizifx_bflower_colourenvelope",
    GREENFLOWER = "tbat_lizifx_gflower_colourenvelope",
    GHOST = "tbat_lizifx_ghost_colourenvelope",
    REDFLOWER = "tbat_lizifx_rflower_colourenvelope",
    ROSE = "tbat_lizifx_rose_colourenvelope",
    STAR = "tbat_lizifx_star_colourenvelope",
}

local SCALE_ENVELOPES = {
    BLOOMER = "tbat_lizifx_bflower_scaleenvelope",
    GREENFLOWER = "tbat_lizifx_gflower_scaleenvelope",
    GHOST = "tbat_lizifx_ghost_scaleenvelope",
    REDFLOWER = "tbat_lizifx_rflower_scaleenvelope",
    ROSE = "tbat_lizifx_rose_scaleenvelope",
    STAR = "tbat_lizifx_star_scaleenvelope",
}


local MAX_LIFETIME = 4
local assets = {
    Asset("IMAGE", RESOURCES.TEXTURES.BLOOMER),
    Asset("IMAGE", RESOURCES.TEXTURES.GREENFLOWER),
    Asset("IMAGE", RESOURCES.TEXTURES.GHOST),
    Asset("IMAGE", RESOURCES.TEXTURES.REDFLOWER),
    Asset("IMAGE", RESOURCES.TEXTURES.ROSE),
    Asset("IMAGE", RESOURCES.TEXTURES.STAR),
    Asset("SHADER", RESOURCES.SHADER),
}


local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end


local function InitEnvelope()

    local colour_configs = {
        {
            name = COLOUR_ENVELOPES.BLOOMER,
            colours = {
                { 0,    IntColour(255, 255, 255, 255) },
                { 0.35, IntColour(255, 255, 255, 255) },
                { 0.5,  IntColour(255, 255, 255, 255) },
                { 0.75, IntColour(255, 255, 255, 160) },
                { 1,    IntColour(255, 255, 255, 0) },
            }
        },
        {
            name = COLOUR_ENVELOPES.GREENFLOWER,
            colours = {
                { 0,    IntColour(255, 255, 255, 255) },
                { 0.35, IntColour(255, 255, 255, 255) },
                { 0.5,  IntColour(255, 255, 255, 255) },
                { 0.75, IntColour(255, 255, 255, 160) },
                { 1,    IntColour(255, 255, 255, 0) },
            }
        },
        {
            name = COLOUR_ENVELOPES.GHOST,
            colours = {
                { 0,    IntColour(255, 255, 255, 255) },
                { 0.35, IntColour(255, 255, 255, 255) },
                { 0.5,  IntColour(255, 255, 255, 255) },
                { 0.75, IntColour(255, 255, 255, 160) },
                { 1,    IntColour(255, 255, 255, 0) },
            }
        },
        {
            name = COLOUR_ENVELOPES.REDFLOWER,
            colours = {
                { 0,    IntColour(255, 255, 255, 255) },
                { 0.35, IntColour(255, 255, 255, 255) },
                { 0.5,  IntColour(255, 255, 255, 255) },
                { 0.75, IntColour(255, 255, 255, 160) },
                { 1,    IntColour(255, 255, 255, 0) },
            }
        },
        {
            name = COLOUR_ENVELOPES.ROSE,
            colours = {
                { 0,    IntColour(255, 255, 255, 255) },
                { 0.35, IntColour(255, 255, 255, 255) },
                { 0.5,  IntColour(255, 255, 255, 255) },
                { 0.75, IntColour(255, 255, 255, 160) },
                { 1,    IntColour(255, 255, 255, 0) },
            }
        },
        {
            name = COLOUR_ENVELOPES.STAR,
            colours = {
                { 0,    IntColour(255, 255, 255, 255) },
                { 0.35, IntColour(255, 255, 255, 255) },
                { 0.5,  IntColour(255, 255, 255, 255) },
                { 0.75, IntColour(255, 255, 255, 160) },
                { 1,    IntColour(255, 255, 255, 0) },
            }
        },
    }

    for _, config in ipairs(colour_configs) do
        EnvelopeManager:AddColourEnvelope(config.name, config.colours)
    end
    local function createScaleEnvelope(name)
        local scale = .55
        local end_scale = .66
        EnvelopeManager:AddVector2Envelope(
            name,
            {
                { 0,   { scale, scale } },
                { 0.5, { scale, scale } },
                { 1,   { end_scale * scale, end_scale * scale } },
            }
        )
    end

    createScaleEnvelope(SCALE_ENVELOPES.BLOOMER)
    createScaleEnvelope(SCALE_ENVELOPES.GREENFLOWER)
    createScaleEnvelope(SCALE_ENVELOPES.GHOST)
    createScaleEnvelope(SCALE_ENVELOPES.REDFLOWER)
    createScaleEnvelope(SCALE_ENVELOPES.ROSE)
    createScaleEnvelope(SCALE_ENVELOPES.STAR)

    InitEnvelope = nil
    IntColour = nil
end

-- 粒子发射函数
local function emit_sparkle_fn(effect, sphere_emitter)
    local vx, vy, vz = 0, 0.025, 0
    local lifetime = 0.8
    local px, py, pz = sphere_emitter()
    py = math.random() * 1.2 + 0.1
    local angle = math.random() * 360
    local ang_vel = 0                        -- 粒子角速度
    local u_offset = math.random(0, 3) * .25 -- UV偏移量
    local v_offset = 0

    effect:AddRotatingParticleUV(
        0,
        lifetime,
        px, py, pz,
        vx, vy, vz,
        angle, ang_vel,
        u_offset, v_offset
    )
end

local function createParticleEffectFn(effectType, texture)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.entity:SetPristine()

        inst.persists = false

        -- 仅客户端需要粒子效果
        if TheNet:IsDedicated() then
            return inst
        elseif InitEnvelope ~= nil then
            InitEnvelope()
        end

        local effect = inst.entity:AddVFXEffect()
        effect:InitEmitters(1)
        effect:SetRenderResources(0, texture, RESOURCES.SHADER)
        effect:SetRotationStatus(0, true)
        effect:SetGroundPhysics(0, true)
        effect:SetMaxNumParticles(0, 256)
        effect:SetUVFrameSize(0, 0.25, 1)
        effect:SetMaxLifetime(0, MAX_LIFETIME)
        effect:SetColourEnvelope(0, COLOUR_ENVELOPES[effectType])
        effect:SetScaleEnvelope(0, SCALE_ENVELOPES[effectType])
        effect:SetBlendMode(0, BLENDMODE.Premultiplied)
        effect:EnableBloomPass(0, true)
        effect:SetSortOrder(0, 0)
        effect:SetSortOffset(0, 1)

        -----------------------------------------------------
        local tick_time = TheSim:GetTickTime()
        local emit_interval = 0.8
        local emit_accumulator = 0

        local sphere_emitter = CreateSphereEmitter(.75)
        inst.last_pos = inst:GetPosition()

        EmitterManager:AddEmitter(inst, nil, function()
            emit_accumulator = emit_accumulator + tick_time
            while emit_accumulator >= emit_interval do
                emit_sparkle_fn(effect, sphere_emitter)
                emit_accumulator = emit_accumulator - emit_interval -- 减去发射间隔
            end
        end)

        return inst
    end
end

local bloomer_fn = createParticleEffectFn("BLOOMER", RESOURCES.TEXTURES.BLOOMER)
local greenflower_fn = createParticleEffectFn("GREENFLOWER", RESOURCES.TEXTURES.GREENFLOWER)
local ghost_fn = createParticleEffectFn("GHOST", RESOURCES.TEXTURES.GHOST)
local redflower_fn = createParticleEffectFn("REDFLOWER", RESOURCES.TEXTURES.REDFLOWER)
local rose_fn = createParticleEffectFn("ROSE", RESOURCES.TEXTURES.ROSE)
local star_fn = createParticleEffectFn("STAR", RESOURCES.TEXTURES.STAR)

return Prefab("tbat_lizifx_bflower", bloomer_fn, assets),
    Prefab("tbat_lizifx_gflower", greenflower_fn, assets),
    Prefab("tbat_lizifx_ghost", ghost_fn, assets),
    Prefab("tbat_lizifx_rflower", redflower_fn, assets),
    Prefab("tbat_lizifx_rose", rose_fn, assets),
    Prefab("tbat_lizifx_star", star_fn, assets)
