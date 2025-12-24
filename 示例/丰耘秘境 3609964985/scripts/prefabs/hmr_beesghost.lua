local REVEAL_SHADER = "shaders/vfx_particle_reveal.ksh"

--------------------------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local COLOR_ENVELOPE = {
    honorbee_ghost = {
        { 0,    IntColour(2, 57, 47, 160) },           -- 青铜墨绿色
        { .2,   IntColour(34, 82, 60, 150) },           -- 调整过渡
        { .4,   IntColour(75, 115, 90, 120) },           -- 中间颜色
        { .6,   IntColour(130, 170, 130, 90) },          -- 进一步渐变
        { .8,   IntColour(210, 220, 185, 50) },          -- 过渡到浅色
        { 1,    IntColour(255, 243, 207, 0) },           -- 奶油白玉色
    },
    terrorbee_ghost = {
        { 0,    IntColour(60, 0, 20, 160) },          -- 调暗后的酒红色
        { .2,   IntColour(55, 0, 25, 140) },           -- 渐变开始
        { .4,   IntColour(50, 0, 18, 100) },           -- 中间色
        { .6,   IntColour(45, 0, 12, 80) },            -- 进一步渐变
        { .75,  IntColour(40, 0, 5, 50) },             -- 过渡到静脉血色调
        { .9,   IntColour(30, 0, 2, 25) },              -- 准备接近黑色
        { 1,    IntColour(10, 0, 0, 0) }               -- 接近黑色
    }
}

local function MakeBeeGhost(name, texture, data)
    local COLOUR_ENVELOPE_NAME = name.."_colourenvelope"
    local SCALE_ENVELOPE_NAME = name.."_scaleenvelope"
    local ANIM_SMOKE_TEXTURE = resolvefilepath(texture)

    local assets = {--注册需要COCONUT = resolvefilepath("images/fx/honor_fruit_coconut.tex"),
        Asset("IMAGE", ANIM_SMOKE_TEXTURE),
        Asset("SHADER", REVEAL_SHADER),
        Asset("ANIM", "anim/hmr_beesghost.zip")
    }

    local function InitEnvelope()
        EnvelopeManager:AddColourEnvelope(
            COLOUR_ENVELOPE_NAME,
            COLOR_ENVELOPE[name]
        )

        local glow_max_scale = .21
        EnvelopeManager:AddVector2Envelope(
            SCALE_ENVELOPE_NAME,
            {
                { 0,    { glow_max_scale * 0.7, glow_max_scale * 0.7 } },
                { .55,  { glow_max_scale * 1.2, glow_max_scale * 1.2 } },
                { 1,    { glow_max_scale * 1.3, glow_max_scale * 1.3 } },
            }
        )

        InitEnvelope = nil
        IntColour = nil
    end

    --------------------------------------------------------------------------
    local GLOW_MAX_LIFETIME = 2.1

    local function emit_glow_fn(effect, emitter_fn)
        local vx, vy, vz = .005 * UnitRand(), 0, .005 * UnitRand()
        local lifetime = GLOW_MAX_LIFETIME * (.9 + math.random() * .1)
        local px, py, pz = emitter_fn()

        effect:AddRotatingParticle(
            0,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            math.random() * 360,-- angle
            UnitRand()          -- angle velocity
        )
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst.entity:AddAnimState()
        inst.AnimState:SetBuild("hmr_beesghost")
        inst.AnimState:SetBank("hmr_beesghost")
        inst.AnimState:PlayAnimation("hmr_beesghost")
        inst.AnimState:SetMultColour(0, 0, 0, 0)
        --inst.AnimState:SetScale(2, 2)
        --MakeGhostPhysics(inst, 1, 0.15)
        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        -- inst.persists = false

        if not TheWorld.ismastersim then

            if InitEnvelope ~= nil then
                InitEnvelope()
            end

            local effect = inst.entity:AddVFXEffect()
            effect:InitEmitters(1)

            effect:SetRenderResources(0, ANIM_SMOKE_TEXTURE, REVEAL_SHADER)
            effect:SetMaxNumParticles(0, 128)
            effect:SetRotationStatus(0, true)
            effect:SetMaxLifetime(0, GLOW_MAX_LIFETIME)
            effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
            effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
            effect:SetBlendMode(0, BLENDMODE.AlphaBlended)
            effect:EnableBloomPass(0, true)
            effect:SetSortOrder(0, 0)
            effect:SetSortOffset(0, -1)
            effect:SetKillOnEntityDeath(0, true)
            effect:SetFollowEmitter(0, true)

            -----------------------------------------------------

            local tick_time = TheSim:GetTickTime()

            local glow_desired_pps = 3
            local glow_particles_per_tick = glow_desired_pps * tick_time
            local glow_num_particles_to_emit = 0

            local sphere_emitter = CreateSphereEmitter(.05)

            EmitterManager:AddEmitter(inst, nil, function()

                while glow_num_particles_to_emit > 1 do
                    emit_glow_fn(effect, sphere_emitter)
                    glow_num_particles_to_emit = glow_num_particles_to_emit - 1
                end
                glow_num_particles_to_emit = glow_num_particles_to_emit + glow_particles_per_tick * math.random() * 3

            end)

            return inst
        end

        inst:AddComponent("hmovefx")
        inst.components.hmovefx:SetSpeed(data.walkspeed, data.runspeed)
        --inst.components.hmovefx:SetOnReachTarget(data.onreachtargetfn)
        inst.components.hmovefx:SetMAxMoveCount(data.movecount)

        inst:AddComponent("inspectable")

        return inst
    end

    return Prefab(name, fn, assets)
end

local data = {
    honorbee_ghost = {
        walkspeed = 1,
        runspeed = 2,
        movecount = 500,
        onreachtargetfn = function(inst, target)
            local x, y, z = inst.Transform:GetWorldPosition()
            local players = TheSim:FindEntities(x, y, z, 5, {"player"})
            for _, player in pairs(players) do
                if player:IsValid() then
                    if player.components.health and not player.components.health:IsDead() then
                        player.components.health:DoDelta(TUNING.HMR_HONORBEEGHOST_HEALTH_DELTA)
                    end
                    if not player.components.hstunnable then
                        player:AddComponent("hstunnable")
                    end
                    player.components.hstunnable:Stun(TUNING.HMR_HONORBEEGHOST_STUN_TIME)
                end
            end
        end
    },
    terrorbee_ghost = {
        walkspeed = 4,
        runspeed = 6,
        movecount = 100,
    }
}

return MakeBeeGhost("honorbee_ghost", "fx/animsmoke.tex", data.honorbee_ghost),
        MakeBeeGhost("terrorbee_ghost", "fx/animsmoke.tex", data.terrorbee_ghost)
