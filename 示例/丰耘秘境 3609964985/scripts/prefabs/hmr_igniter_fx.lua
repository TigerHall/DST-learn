----------------------------------------------------------------------
---[[拖尾特效]]
----------------------------------------------------------------------

local ANIM_HEART_TEXTURE = resolvefilepath("images/inventoryimages/honor_wheat.tex")
local REVEAL_SHADER = "shaders/vfx_particle_reveal.ksh"

local COLOUR_ENVELOPE_NAME = "heart_colourenvelope"
local SCALE_ENVELOPE_NAME = "heart_scaleenvelope"

local assets =
{
    Asset("IMAGE", ANIM_HEART_TEXTURE),
    Asset("SHADER", REVEAL_SHADER),
}

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    IntColour(255, 165, 0, 255) },
            { .1,  IntColour(255, 140, 0, 192) },
            { .2,  IntColour(255, 69, 0, 128) },
            { .3,  IntColour(32, 32, 32, 128) },
            { .65,  IntColour(16, 16, 16, 128) },
            { 1,    IntColour(8, 8, 8, 64) },
        }
    )

    local glow_max_scale = .6
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { glow_max_scale * 0.4, glow_max_scale * 0.4 } },
            { .55,  { glow_max_scale * 0.5, glow_max_scale * 0.5 } },
            { 1,    { glow_max_scale * 0.6, glow_max_scale * 0.6 } },
        }
    )

    InitEnvelope = nil
    IntColour = nil
end

local GLOW_MAX_LIFETIME = 1

local function emit_glow_fn(effect, emitter_fn)
    local vx, vy, vz = .005 * UnitRand(), 0, .005 * UnitRand()
    local lifetime = GLOW_MAX_LIFETIME
    local px, py, pz = emitter_fn()

    px = px + math.random(-1,1) * .2
    py = py + math.random(-1,1) * .2
    pz = pz + math.random(-1,1) * .2
    local uv_offset = math.random(0, 3) * .25
    effect:AddRotatingParticle(
        0,
        lifetime,
        px, py, pz,
        vx, vy, vz,
        uv_offset,
        0
    )
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.entity:SetPristine()

    inst.persists = false

    if TheNet:IsDedicated() then
        return inst
    elseif InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, ANIM_HEART_TEXTURE, REVEAL_SHADER)
    effect:SetMaxNumParticles(0, 128)
    effect:SetRotationStatus(0, true)
    effect:SetMaxLifetime(0, GLOW_MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.AlphaBlended)
    effect:EnableBloomPass(0, true)
    effect:SetSortOrder(0, 0)
    effect:SetSortOffset(0, 0)
    effect:SetKillOnEntityDeath(0, true)

    local tick_time = TheSim:GetTickTime()

    local sparkle_desired_pps_low = 5
    local sparkle_desired_pps_high = 50
    local low_per_tick = sparkle_desired_pps_low * tick_time
    local high_per_tick = sparkle_desired_pps_high * tick_time
    local num_to_emit = 0

    local sphere_emitter = CreateSphereEmitter(.25)
    inst.last_pos = inst:GetPosition()

    EmitterManager:AddEmitter(inst, nil, function()
        local dist_moved = inst:GetPosition() - inst.last_pos
        local move = dist_moved:Length()
        move = math.clamp(move * 6, 0, 1)

        local per_tick = Lerp(low_per_tick, high_per_tick, move)

        inst.last_pos = inst:GetPosition()

        num_to_emit = num_to_emit + per_tick * math.random() * 6
        while num_to_emit > 1 do
            emit_glow_fn(effect, sphere_emitter)
            num_to_emit = num_to_emit - 1
        end
    end)

    return inst
end

----------------------------------------------------------------------
---[[溅射物]]
----------------------------------------------------------------------

local function OnThrown(inst, attacker)
	inst:AddTag("NOCLICK")
	inst.persists = false

	inst.ispvp = attacker ~= nil and attacker:IsValid() and attacker:HasTag("player")

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(1)

    if inst.SoundEmitter then
	    inst.SoundEmitter:PlaySound("rifts/lunarthrall_bomb/throw", "toss")
    end

	inst.Physics:SetMass(0.2)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)
	inst.Physics:SetCapsule(.2, .2)
end

local function OnHit(inst, attacker, target)
	local x, y, z = inst.Transform:GetWorldPosition()

    if inst.SoundEmitter then
	    inst.SoundEmitter:KillSound("toss")
    end

	inst:AddComponent("explosive")
	inst.components.explosive.explosiverange = TUNING.BOMB_LUNARPLANT_RANGE
	inst.components.explosive.explosivedamage = 5
	inst.components.explosive.lightonexplode = false
	if inst.ispvp then
		inst.components.explosive:SetPvpAttacker(attacker)
	else
		inst.components.explosive:SetAttacker(attacker)
	end
	inst.components.explosive:OnBurnt()
	--exploding should have removed me

	local anim = "small"..(math.random() > 0.3 and "_firecrackers" or "")
    local scale = 0.3 + math.random() * 0.3
    local colour = 0.7 + math.random() * 0.3
    inst.AnimState:SetBank("explode")
    inst.AnimState:SetBuild("explode")
	inst.AnimState:PlayAnimation(anim)
    inst.AnimState:SetScale(scale, scale)
    inst.AnimState:SetAddColour(colour, colour, colour, 1)

    local frames = inst.AnimState:GetCurrentAnimationNumFrames()
    inst:DoTaskInTime(frames * FRAMES, function()
        inst:Remove()
    end)
end

local function item_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("donot_remove") -- 禁止explosive组件移除该物品

    inst.AnimState:SetBank("projectile")
    inst.AnimState:SetBuild("staff_projectile")
    inst.AnimState:PlayAnimation("fire_spin_loop")
    inst.AnimState:Hide("flames")
    inst.AnimState:SetMultColour(0.2, 0.1, 0.0, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(9)
    inst.components.complexprojectile:SetGravity(-10)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 0.2, 0))
    inst.components.complexprojectile:SetOnLaunch(OnThrown)
    inst.components.complexprojectile:SetOnHit(OnHit)

    return inst
end

return  Prefab("hmr_igniter_fx", fx_fn, assets),
        Prefab("hmr_igniter_item", item_fn)