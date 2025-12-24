
----------------------------------------------------------------------------------------------------------------------------

local WEIGHTED_TAIL_FXS =
{
    ["tail_5_8"] = 1,
    ["tail_5_9"] = .5,
}

local LAUNCH_OFFSET_Y = 0.75

----------------------------------------------------------------------------------------------------------------------------

-- 治愈吹箭对自己的效果
local function CureOnHitOther(owner, data)
    local damageresolved = data.damageresolved

    if owner:HasTag("playerghost") then
        owner:PushEvent("respawnfromghost")
    end

    if owner.components.health ~= nil and owner.components.health:IsHurt() then
        if damageresolved > 0 then
            owner.components.health:DoDelta(damageresolved * TUNING.HMR_HONOR_BLOWDART_CURE_PLAYER_MULT)
        end
        if owner.components.health:IsDead() then
            owner:PushEvent("respawnfromghost")
        end
    end
end

local function MakeBlowDart(name, type, maxuses)
    local assets =
    {
        Asset("ANIM", "anim/blow_dart.zip"),
        Asset("ANIM", "anim/swap_honor_blowdart_"..type..".zip"),
        Asset("ANIM", "anim/honor_blowdart.zip"),
        Asset("ATLAS", "images/inventoryimages/honor_blowdart_"..type..".xml"),
        Asset("IMAGE", "images/inventoryimages/honor_blowdart_"..type..".tex")
    }

    local prefab =
    {
        name.."_proj",
    }

    local function OnEquip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_honor_blowdart_"..type, "swap_honor_blowdart_"..type)

        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")

        if type == "cure" then
            owner:ListenForEvent("onhitother", CureOnHitOther)
        end
    end

    local function OnUnequip(inst, owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")

        if type == "cure" then
            owner:RemoveEventCallback("onhitother", CureOnHitOther)
        end
    end

    local function OnProjectileLaunched(inst, attacker, target, proj)
        inst.components.finiteuses:Use(1)
        if inst.components.finiteuses:GetUses() == 0 then
            if inst.components.stackable:IsStack() then
                inst.components.stackable:Get()
                inst.components.finiteuses:SetUses(maxuses)
            else
                if type == "cure" then
                    local owner = inst.components.inventoryitem:GetGrandOwner() or attacker
                    if owner ~= nil then
                        owner:RemoveEventCallback("onhitother", CureOnHitOther)
                    end
                end

                inst:Remove()
            end
        end
    end

    ----------------------------------------------------------------------------------------------------------------------------

    local floater_swap_data =
    {
        sym_build = "swap_honor_blowdart_"..type,
        sym_name  = "swap_honor_blowdart_"..type,
        bank = "blow_dart",
        anim = "idle_"..type
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("honor_blowdart")
        inst.AnimState:SetBuild("honor_blowdart")
        inst.AnimState:PlayAnimation("idle_"..type)

        --weapon (from weapon component) added to pristine state for optimization.
        inst:AddTag("weapon")

        inst:AddTag("blowpipe") -- For SG state.
        inst:AddTag("rangedweapon")

        inst:AddTag("honor_blowdart_"..type)

        MakeInventoryFloatable(inst, "small", 0.05, {0.75, 0.5, 0.75}, true, -4, floater_swap_data)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- inst.scrapbook_anim = "idle_houndstooth"
        -- inst.scrapbook_weaponrange  = TUNING.HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST_MAX
        -- inst.scrapbook_weapondamage = TUNING.HOUNDSTOOTH_BLOWPIPE_DAMAGE
        -- inst.scrapbook_planardamage = TUNING.HOUNDSTOOTH_BLOWPIPE_PLANAR_DAMAGE

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_blowdart_"..type..".xml"
        inst.components.inventoryitem.imagename = "honor_blowdart_"..type

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(OnEquip)
        inst.components.equippable:SetOnUnequip(OnUnequip)
        inst.components.equippable.equipstack = true

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)
        inst.components.weapon:SetProjectile(name.."_proj")
        inst.components.weapon:SetRange(TUNING.HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST, TUNING.HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST_MAX)
        inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(maxuses)
        inst.components.finiteuses:SetUses(maxuses)

        MakeHauntableLaunch(inst)

        return inst
    end
    return Prefab(name, fn, assets, prefab)
end


local function FireOnHit(inst, attacker, target)
    if attacker ~= nil and attacker.SoundEmitter ~= nil then
        attacker.SoundEmitter:PlaySound(inst.skin_sound or "dontstarve/wilson/fireball_explo")
    end

    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    elseif target.components.burnable ~= nil and not target.components.burnable:IsBurning() then
        -- 不点燃拳击袋
        if target:HasTag("structure") or target:HasTag("equipmentmodel") then
            return
        elseif target.components.freezable ~= nil and target.components.freezable:IsFrozen() then
            target.components.freezable:Unfreeze()
        elseif target.components.fueled == nil
            or (target.components.fueled.fueltype ~= FUELTYPE.BURNABLE and
                target.components.fueled.secondaryfueltype ~= FUELTYPE.BURNABLE) then
            --does not take burnable fuel, so just burn it
            if target.components.burnable.canlight or target.components.combat ~= nil then
                target.components.burnable:Ignite(true, attacker)
            end
        elseif target.components.fueled.accepting then
            --takes burnable fuel, so fuel it
            local fuel = SpawnPrefab("cutgrass")
            if fuel ~= nil then
                if fuel.components.fuel ~= nil and
                    fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
                    target.components.fueled:TakeFuelItem(fuel)
                else
                    fuel:Remove()
                end
            end
        end
    end

    if target.components.freezable ~= nil then
        target.components.freezable:AddColdness(-1) --Does this break ice staff?
        if target.components.freezable:IsFrozen() then
            target.components.freezable:Unfreeze()
        end
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    target:PushEvent("attacked", { attacker = attacker, damage = TUNING.HMR_HONOR_BLOWDART_FIRE_DAMAGE, weapon = inst })
end

local function IceOnHit(inst, attacker, target)
    if not target:IsValid() then
        return
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.burnable ~= nil then
        if target.components.burnable:IsBurning() then
            target.components.burnable:Extinguish()
        elseif target.components.burnable:IsSmoldering() then
            target.components.burnable:SmotherSmolder()
        end
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
        target:PushEvent("attacked", { attacker = attacker, damage = TUNING.HMR_HONOR_BLOWDART_ICE_DAMAGE, weapon = inst })
    end

	--V2C: valid check in case any of the previous callbacks or events removed the target
	if target.components.freezable ~= nil and target:IsValid() then
        target.components.freezable:AddColdness(1)
        target.components.freezable:SpawnShatterFX()
    end
end

-- 治愈吹箭对他人的效果
local function CureOnHit(inst, attacker, target)
    -- 无效物体不会出现在这里
    if target.components.hcurable ~= nil then
        if target:HasTag("playerghost") or target.components.health ~= nil and target.components.health:IsDead() then
            -- 死玩家
            target.hmr_blowdart_curetimes = (target.hmr_blowdart_curetimes or 0) + 1
            if target.hmr_blowdart_curetimes >= TUNING.HMR_HONOR_BLOWDART_CURE_RESPAWNPLAYER_TIMES then
                -- 复活玩家
                target:PushEvent("respawnfromghost")
            end
        elseif target.components.health ~= nil and target.components.health:GetPercent() < 1 then
            -- 活玩家
            target.components.health:DoDelta(TUNING.HMR_HONOR_BLOWDART_CURE_DAMAGE * TUNING.HMR_HONOR_BLOWDART_CURE_PLAYER_MULT)
        end
    else
        -- 生物
        if target.components.combat ~= nil then
            target.components.combat:SuggestTarget(attacker)
        end

        if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
            target.components.sleeper:WakeUp()
        end

        target:PushEvent("attacked", { attacker = attacker, damage = TUNING.HMR_HONOR_BLOWDART_CURE_DAMAGE, weapon = inst })
    end
end

local function MakeDart(name, type, fx_addcolor, damage, speed, onhitfn)
    local assets =
    {
        Asset("ANIM", "anim/honor_dart.zip"),
    }

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

        inst.AnimState:SetAddColour(unpack(fx_addcolor))

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

            return tail -- Mods.
        end
    end

    local function Projectile_OnThrown(inst, owner, target, attacker)
        inst._target:set(target)
    end

    local function Projectile_SpawnImpactFx(inst, attacker, target)
        if target ~= nil and attacker ~= nil and target:IsValid() and attacker:IsValid() then
            local impactfx = SpawnPrefab("hitsparks_piercing_fx")
            impactfx:Setup(attacker, target, inst, fx_addcolor, true, LAUNCH_OFFSET_Y)

            return impactfx -- Mods.
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
        if target ~= nil and target:IsValid() and onhitfn ~= nil and
                (target.components.health == nil or not target.components.health:IsDead()) then
            onhitfn(inst, attacker, target)
        end
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddLight()

        inst.Light:SetFalloff(0.6)
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(0.4)
        inst.Light:SetColour(237/255, 237/255, 209/255)
        inst.Light:Enable(true)

        MakeProjectilePhysics(inst)

        inst.AnimState:SetBank("honor_dart")
        inst.AnimState:SetBuild("honor_dart")
        inst.AnimState:PlayAnimation("idle_"..type.."dart", true)

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

        inst._target = net_entity(inst.GUID, "honor_"..type.."dart_proj._target")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst.SpawnImpactFx = Projectile_SpawnImpactFx

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(damage)
        if type == "fire" then
            inst.components.weapon:SetOnProjectileLaunched(function(inst, attacker, target, proj) proj:AddTag("controlled_burner") end)
        end

        -- 暗影阵营1.1倍增伤
        inst:AddComponent("damagetypebonus")
        inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.HOUNDSTOOTH_BLOWPIPE_VS_SHADOW_BONUS)

        inst:AddComponent("projectile")
        inst.components.projectile:SetSpeed(speed)
        inst.components.projectile:SetHoming(false)
        inst.components.projectile:SetOnThrownFn(Projectile_OnThrown)
        inst.components.projectile:SetOnPreHitFn(Projectile_OnPreHit)
        inst.components.projectile:SetOnHitFn(Projectile_OnHit)
        inst.components.projectile:SetHitDist(1.5)
        inst.components.projectile:SetLaunchOffset(Vector3(2.5, LAUNCH_OFFSET_Y, 2.5))
        inst.components.projectile:SetOnMissFn(inst.Remove)
        inst.components.projectile.range = 30
        inst.components.projectile.has_damage_set = true

        return inst
    end
    return Prefab(name, fn, assets)
end

return  MakeBlowDart("honor_blowdart_fire", "fire", TUNING.HMR_HONOR_BLOWDART_FIRE_MAXUSES),
        MakeDart("honor_blowdart_fire_proj", "fire", {1, 0.2, 0, 1}, TUNING.HMR_HONOR_BLOWDART_FIRE_DAMAGE, TUNING.HMR_HONOR_BLOWDART_FIRE_SPEED, FireOnHit),
        MakeBlowDart("honor_blowdart_ice", "ice", TUNING.HMR_HONOR_BLOWDART_ICE_MAXUSES),
        MakeDart("honor_blowdart_ice_proj", "ice", {0, 0, 1, 1}, TUNING.HMR_HONOR_BLOWDART_ICE_DAMAGE, TUNING.HMR_HONOR_BLOWDART_ICE_SPEED, IceOnHit),
        MakeBlowDart("honor_blowdart_cure", "cure", TUNING.HMR_HONOR_BLOWDART_CURE_MAXUSES),
        MakeDart("honor_blowdart_cure_proj", "cure", {0, 1, 0, 1}, TUNING.HMR_HONOR_BLOWDART_CURE_DAMAGE, TUNING.HMR_HONOR_BLOWDART_CURE_SPEED, CureOnHit)