local prefs = {}

----------------------------------------------------------------------------
---[[法杖]]
----------------------------------------------------------------------------
local assets =
{
    Asset("ANIM", "anim/honor_staff.zip"),
}

local PROJECTILES = {
    honor_staff_proj = {anim = "honor", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE},
    honor_rice_prime_proj = {anim = "rice", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE * TUNING.HMR_HONOR_RICE_PRIME_PROJ_DAMAGE_MULTIPLIER},
    honor_wheat_prime_proj = {anim = "wheat", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE * TUNING.HMR_HONOR_WHEAT_PRIME_PROJ_DAMAGE_MULTIPLIER},
    honor_coconut_prime_proj = {anim = "coconut", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE},
    honor_tea_prime_proj = {anim = "tea", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE * TUNING.HMR_HONOR_TEA_PRIME_PROJ_DAMAGE_MULTIPLIER},
    honor_aloe_prime_proj = {anim = "aloe", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE},
    honor_hamimelon_prime_proj = {anim = "hamimelon", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE},
    honor_goldenlanternfruit_prime_proj = {anim = "goldenlanternfruit", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE},
    honor_nut_prime_proj = {anim = "nut", damage = TUNING.HMR_HONOR_STAFF_BASE_DAMAGE},
}

local SWAP_DATA_BROKEN = { sym_build = "honor_staff", sym_name = "swap_object_broken_float", bank = "honor_staff", anim = "idle_broken" }
local SWAP_DATA = { sym_build = "honor_staff", sym_name = "swap_object", bank = "honor_staff", anim = "idle" }

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
    inst.components.floater:SetBankSwapOnFloat(true, -1, SWAP_DATA_BROKEN)
    inst._broken:set(true)
end

local function GetProjAnim(inst)
    return PROJECTILES[inst.components.weapon.projectile] and PROJECTILES[inst.components.weapon.projectile].anim
end

local function UpdateCoreAnim(inst)
    local anim = GetProjAnim(inst)
    if inst._core ~= nil and anim ~= nil then
        inst._core.AnimState:PlayAnimation(anim)
    end
end

local function SpawnStaffCore(inst)
    if inst.components.inventoryitem.owner ~= nil then
        return
    end

    if inst._core ~= nil then
        inst._core:Remove()
    end

    local core = SpawnPrefab("honor_staff_core")
    core.Transform:SetPosition(inst.Transform:GetWorldPosition())
    core.entity:SetParent(inst.entity)
    local x, y, z = -60, -220, 0
    if inst.skin_staff_offset ~= nil then
        x, y, z = unpack(inst.skin_staff_offset)
    end
    core.Follower:FollowSymbol(inst.GUID, "staff", x, y, z, true)
    inst._core = core

    UpdateCoreAnim(inst)
end

local function OnRepaired(inst)
    inst.components.floater:SetBankSwapOnFloat(true, -20, SWAP_DATA)
    inst._broken:set(false)

end

local function OnBrokenDirty(inst)
    if inst._broken:value() then
        inst.components.floater:SetScale({0.8, 0.6, 1.1})
    else
        inst.components.floater:SetScale({1.5, 0.5, 1.1})
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_object", inst.GUID, "honor_staff")
        local fx = inst.skin_follow_fx
        if fx ~= nil then
            local follow_fx = SpawnPrefab(fx)
            follow_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            follow_fx.entity:SetParent(owner.entity)
            follow_fx.entity:AddFollower()
            follow_fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -180, 0)
            inst._fx = follow_fx
        end
    else
        owner.AnimState:OverrideSymbol("swap_object", "honor_staff", "swap_object")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst._core ~= nil then
        inst._core:Remove()
    end
    local core = SpawnPrefab("honor_staff_core")
    core.Transform:SetPosition(inst.Transform:GetWorldPosition())
    core.entity:SetParent(owner.entity)
    local x, y, z = 0, -180, 0
    if inst.skin_swap_object_offset ~= nil then
        x, y, z = unpack(inst.skin_swap_object_offset)
    end
    core.Follower:FollowSymbol(owner.GUID, "swap_object", x, y, z, true)
    inst._core = core

    UpdateCoreAnim(inst)
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst._fx ~= nil then
        inst._fx:Remove()
        inst._fx = nil
    end

    if inst._core ~= nil then
        inst._core:Remove()
    end
end

local function OnBlink(staff, pos, caster)
    staff.components.finiteuses:Use(3)
    staff.components.rechargeable:Discharge(5)
end

local function GetProjType(inst)
    local items_accepted_num = GetTableSize(inst.items_accepted)
    if math.random() < items_accepted_num / 8 then
        local rand = math.random(1, items_accepted_num)
        local proj_name = nil
        for k, v in pairs(inst.items_accepted) do
            if rand == 1 then
                proj_name = k.."_proj"
                break
            end
            rand = rand - 1
        end
        if proj_name ~= nil then
            return proj_name
        end
    end
    return "honor_staff_proj"
end

local function UpdateProj(inst)
    local proj = GetProjType(inst)
    inst.components.weapon:SetProjectile(proj)
    UpdateCoreAnim(inst)
end

local function OnProjectileLaunched(inst, attacker, target, proj)
    UpdateProj(inst)
end

local function OnDropped(inst)
    SpawnStaffCore(inst)
end

local function OnPutInInventory(inst)
    if inst._core ~= nil then
        inst._core:Remove()
    end
end

local function AcceptTest(inst, item, giver, count)
    return item:HasTag("honor_prime") and inst.items_accepted[item.prefab] == nil
end

local function OnAccept(inst, giver, item, count)
    inst.items_accepted[item.prefab] = true
    inst.components.finiteuses:SetPercent(1)
    UpdateProj(inst)
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function GetDamage(inst, attacker, target)
    local setbonus_enabled = inst.components.setbonus:IsEnabled()
    local proj = inst.components.weapon.projectile
    local proj_damage = PROJECTILES[proj] and PROJECTILES[proj].damage or TUNING.HMR_HONOR_STAFF_BASE_DAMAGE
    return proj_damage * (setbonus_enabled and TUNING.HMR_HONOR_STAFF_SETBONUS_DAMAGE_MULTIPLIER or 1)
end

local function OnSave(inst, data)
    data.items_accepted = inst.items_accepted
end

local function OnLoad(inst, data)
    inst.items_accepted = data and data.items_accepted or {}
    UpdateCoreAnim(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_staff")
    inst.AnimState:SetBuild("honor_staff")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("weapon")
    inst:AddTag("honor_weapon")
    inst:AddTag("honor_repairable")
    inst:AddTag("HMR_repairable")

    MakeInventoryFloatable(inst, "med", 0.05, {1.5, 0.5, 1.1}, true, -20, SWAP_DATA)
    inst._broken = net_bool(inst.GUID, "_broken", "broken_dirty")
    inst._broken:set(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("broken_dirty", OnBrokenDirty)
        return inst
    end

    inst.items_accepted = {}

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(GetDamage)
    inst.components.weapon:SetRange(10, 12)
    inst.components.weapon:SetProjectile("honor_staff_proj")
    inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.HMR_HONOR_STAFF_PLANAR_DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(400)
    inst.components.finiteuses:SetUses(400)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    -- inst:AddComponent("blinkstaff")
    -- inst.components.blinkstaff:SetFX("sand_puff_large_front", "sand_puff_large_back")
    -- inst.components.blinkstaff.onblinkfn = OnBlink

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("HONOR")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader:SetOnAccept(OnAccept)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.HONOR_STAFF, atlasname = "images/inventoryimages/honor_staff.xml", imagename = "honor_staff", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.HONOR_STAFF_BROKEN, atlasname = "images/inventoryimages/honor_staff_broken.xml", imagename = "honor_staff_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:SetOnRepairedFn(OnRepaired)
    inst.components.hmrrepairable:Toggle()

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0, SpawnStaffCore)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end
table.insert(prefs, Prefab("honor_staff", fn, assets))

----------------------------------------------------------------------------
---[[法杖核心]]
----------------------------------------------------------------------------
local core_assets =
{
    Asset("ANIM", "anim/honor_staff_core.zip"),
}

local function core_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("honor_staff_core")
    inst.AnimState:SetBuild("honor_staff_core")
    inst.AnimState:PlayAnimation("aloe")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    -- inst.AnimState:SetScale(0.5, 0.5, 0.5)

    inst.entity:SetPristine()

    inst.persists = false

    return inst
end
table.insert(prefs, Prefab("honor_staff_core", core_fn, core_assets))

----------------------------------------------------------------------------
---[[法球]]
----------------------------------------------------------------------------
local function MakeProj(name, data)
    local proj_assets =
    {
        Asset("ANIM", "anim/honor_staff_projs.zip"),
    }

    local WEIGHTED_TAIL_FXS =
    {
        ["tail_5_8"] = 1,
        ["tail_5_9"] = .5,
    }

    local LAUNCH_OFFSET_Y = 0.75
    local COLOR = data.color or {1, 1, 1, 1}

    local function Projectile_CreateTailFx()
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
        inst.AnimState:PlayAnimation(weighted_random_choice(WEIGHTED_TAIL_FXS))
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

        inst.AnimState:SetLightOverride(0.3)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetAddColour(unpack(COLOR))

        inst:ListenForEvent("animover", inst.Remove)

        return inst
    end

    local function Projectile_UpdateTail(inst)
        local c = (not inst.entity:IsVisible() and 0) or 1
        local target = inst._target:value()

        -- Does not spawn the tail if it is close to the target (visual bug).
        if c > 0 and not (target ~= nil and target:IsValid() and inst:IsNear(target, 1.5)) then
            local tail = inst:CreateTailFx()
            tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
            tail.Transform:SetRotation(inst.Transform:GetRotation())
            if c < 1 then
                tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
            end

            return tail
        end
    end

    local function Projectile_OnThrown(inst, owner, target, attacker)
        inst._target:set(target)
    end

    local function Projectile_SpawnImpactFx(inst, attacker, target)
        if target ~= nil and attacker ~= nil and target:IsValid() and attacker:IsValid() then
            local impactfx = SpawnPrefab("hitsparks_piercing_fx")
            impactfx:Setup(attacker, target, inst, COLOR, true, LAUNCH_OFFSET_Y)

            return impactfx
        end
    end

    -- NOTE(DiogoW): Using OnPreHit to be able to check health:IsDead().
    local function Projectile_OnPreHit(inst, attacker, target)
        if  target ~= nil      and
            target:IsValid()   and
            attacker ~= nil    and
            attacker:IsValid() and
            (target.components.health == nil or not target.components.health:IsDead())
        then
            inst:SpawnImpactFx(attacker, target)
        end
    end

    local function Projectile_OnHit(inst, attacker, target)
        if target ~= nil and target:IsValid() and data.onhitfn ~= nil and
                (target.components.health == nil or not target.components.health:IsDead()) then
            data.onhitfn(inst, attacker, target)
        end
        inst:Remove()
    end

    local function proj_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddLight()

        inst.Light:SetFalloff(0.6)
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(0.4)
        inst.Light:SetColour(unpack(COLOR))
        inst.Light:Enable(true)

        MakeProjectilePhysics(inst)

        inst.AnimState:SetBank("honor_staff_projs")
        inst.AnimState:SetBuild("honor_staff_projs")
        inst.AnimState:PlayAnimation(data.anim, true)

        inst.AnimState:SetLightOverride(0.2)

        inst.AnimState:SetSymbolBloom("flametail")
        inst.AnimState:SetSymbolLightOverride("flametail", 0.5)

        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

        --weapon (from weapon component) added to pristine state for optimization.
        inst:AddTag("weapon")

        --projectile (from projectile component) added to pristine state for optimization.
        inst:AddTag("projectile")

        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")

        if not TheNet:IsDedicated() then
            inst.CreateTailFx  = Projectile_CreateTailFx
            inst.UpdateTail    = Projectile_UpdateTail

            inst:DoPeriodicTask(0, inst.UpdateTail)
        end

        inst._target = net_entity(inst.GUID, name.."_target")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst.SpawnImpactFx = Projectile_SpawnImpactFx

        -- inst:AddComponent("weapon")
        -- inst.components.weapon:SetDamage(ProjectileDamage)

        inst:AddComponent("projectile")
        inst.components.projectile:SetSpeed(data.speed or TUNING.HMR_HONOR_STAFF_PROJECTILE_SPEED)
        inst.components.projectile:SetHoming(false)
        inst.components.projectile:SetOnThrownFn(Projectile_OnThrown)
        inst.components.projectile:SetOnPreHitFn(Projectile_OnPreHit)
        inst.components.projectile:SetOnHitFn(Projectile_OnHit)
        inst.components.projectile:SetHitDist(1.5)
        inst.components.projectile:SetLaunchOffset(Vector3(2.5, LAUNCH_OFFSET_Y, 2.5))
        inst.components.projectile:SetOnMissFn(inst.Remove)
        inst.components.projectile.range = 30
        inst.components.projectile.has_damage_set = false

        return inst
    end
    table.insert(prefs, Prefab(name, proj_fn, proj_assets))
end

MakeProj("honor_staff_proj", {
    anim = "honor",
    color = {0/255, 50/255, 0/255, 1}
})

MakeProj("honor_rice_prime_proj", {
    anim = "rice",
    color = {255/255, 180/255, 0/255, 1}
})

MakeProj("honor_wheat_prime_proj", {
    anim = "wheat",
    onhitfn = function(inst, attacker, target)
        if target.components.freezable ~= nil then
            target.components.freezable:AddColdness(TUNING.HMR_HONOR_WHEAT_PRIME_PROJ_ADDCOLDNESS)
        end
    end,
    color = {135/255, 206/255, 250/255, 1}
})

MakeProj("honor_tea_prime_proj", {
    anim = "tea",
    onhitfn = function(inst, attacker, target)
        if target.components.hstunnable ~= nil then
            target.components.hstunnable:AddStunDegree(TUNING.HMR_HONOR_TEA_PRIME_PROJ_ADDSTUNDEGREE)
        end
    end,
    color = {154/255, 205/255, 50/255, 1}
})

MakeProj("honor_coconut_prime_proj", {
    anim = "coconut",
    onhitfn = function(inst, attacker, target)
        local x, y, z = target.Transform:GetWorldPosition()
        for i = 1, 2 do
            local r = 0.5 + math.random() * 0.5
            local theta = math.random() * 2 * math.pi
            x = x + r * math.cos(theta)
            z = z - r * math.sin(theta)
            local coconut = SpawnPrefab("honor_coconut")
            coconut.Transform:SetPosition(x, 20, z)
            coconut:DoTaskInTime(1, function()
                local ents = TheSim:FindEntities(x, y, z, 2, nil, {"player"})
                for _, ent in pairs(ents) do
                    if ent:IsValid() and ent.components.health ~= nil and ent.components.combat ~= nil then
                        HMR_UTIL.Attack(attacker, ent, TUNING.HMR_HONOR_COCONUT_DROP_DAMAGE)
                    end
                end
            end)
        end
    end,
    color = {139/255, 69/255, 19/255, 1}
})

return unpack(prefs)