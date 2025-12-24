local assets =
{
    Asset("ANIM", "anim/blowdart_lava.zip"),
    Asset("ANIM", "anim/swap_blowdart_lava.zip"),
}

local FADE_FRAMES = 5

local function CreateTail()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation("tail_1")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function OnUpdateProjectileTail(inst)
    local c = (not inst.entity:IsVisible() and 0) or (inst._fade ~= nil and (FADE_FRAMES - inst._fade:value() + 1) / FADE_FRAMES) or 1
    if c > 0 and not inst.entity:GetParent() then
        local tail = CreateTail()
        tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tail.Transform:SetRotation(inst.Transform:GetRotation())
        if c < 1 then
            tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
        end
    end
end

--要是玩家一直不按键，表中的对象得不到清理也不好
local function OnRemove(inst)
    if inst.attacker and inst.attacker._aab_burst_arrows then
        inst.attacker._aab_burst_arrows[inst] = nil
    end
end

local function OnHit(inst, attacker, target)
    if not attacker or not target or IsEntityDead(target) then
        inst:Remove()
        return
    end

    SpawnAt("aab_chain_arrow_hit_fx", target)

    target._aab_burst_arrow_count = (target._aab_burst_arrow_count or 0) + 1
    if target._aab_burst_arrow_count < 100 then --特效也不能一直生成
        local r = math.max(1, target:GetPhysicsRadius(1))
        inst.Transform:SetPosition(0, r * math.random(), 0)
        inst.AnimState:SetScale(1 + r * math.random(), 1)
        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
        inst.AnimState:Pause()
        inst.AnimState:SetMultColour(1, 1, 1, 0.6)
        target:AddChild(inst)
        inst:ListenForEvent("onremove", function() inst:Remove() end, target)
        inst:ListenForEvent("entitysleep", function() inst:Remove() end, target)

        inst.attacker = attacker
        inst:ListenForEvent("onremove", OnRemove)
        attacker._aab_burst_arrows[inst] = true
    else
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation("attack_3", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetAddColour(1, 1, 0, 0)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("weapon")
    inst:AddTag("projectile")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    if not TheNet:IsDedicated() then
        inst:DoPeriodicTask(0, OnUpdateProjectileTail)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(10)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(TUNING.HOUNDSTOOTH_BLOWPIPE_PROJECTILE_SPEED)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile.range = 30
    inst.components.projectile.has_damage_set = true

    inst.persists = false

    return inst
end

return Prefab("aab_chain_arrow_projectile", fn, assets)
