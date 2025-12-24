local assets =
{
    Asset("ANIM", "anim/trusty_shooter.zip"),
    Asset("ANIM", "anim/swap_trusty_shooter.zip"),
    Asset("ATLAS", "images/inventoryimages/trusty_shooter.xml"),
    Asset("ATLAS", "images/inventoryimages/trusty_shooter_unloaded.xml"),
    Asset("ATLAS_BUILD", "images/inventoryimages/trusty_shooter.xml", 256),          --小木牌和展柜使用
    Asset("ATLAS_BUILD", "images/inventoryimages/trusty_shooter_unloaded.xml", 256), --小木牌和展柜使用
}

RegisterInventoryItemAtlas("images/inventoryimages/trusty_shooter.xml", "trusty_shooter.tex")
RegisterInventoryItemAtlas("images/inventoryimages/trusty_shooter_unloaded.xml", "trusty_shooter_unloaded.tex")

----------------------------------------------------------------------------------------------------
local ITEM_DAMAGE = {
    rocks = 20,
    flint = 20,
    stinger = 20,
    houndstooth = 34,
    goldnugget = 50,
    moonrocknugget = 60,
    marble = 60,
}

local function GetDamage(weapon, attacker, target)
    local inst = weapon.projectile --我不能从Container里判断，因为最后一发已经发射出去了，我这里也拿不到投射物
    local damage = 10
    local ic = inst and inst.components
    local tc = target.components

    if not inst or not inst:IsValid() then
        --不处理
        weapon.projectile = nil
    elseif tc.inventory and not tc.inventory:IsFull() and tc.trader and tc.trader:AbleToAccept(inst, attacker, 1) and tc.trader:WantsToAccept(inst, attacker, 1) then
        damage = 0
    elseif ic.edible and target and tc.eater and tc.follower and tc.follower.leader == attacker then
        damage = 0
    elseif ic.edible and ic.edible.foodtype == FOODTYPE.VEGGIE and target and target:HasTag("pig") and tc.inventory then
        damage = 0 --全喂给猪人
    elseif ITEM_DAMAGE[inst.prefab] then
        damage = ITEM_DAMAGE[inst.prefab]
    elseif inst:HasTag("gem") then
        damage = (inst.prefab == "redgem" or inst.prefab == "bluegem") and 40 or 70
    end

    return damage
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function OnHit(inst, attacker, target)
    local isremove = true
    if target and target:IsValid() and not IsEntityDead(target) then
        local ic = inst.components
        local tc = target.components

        if tc.inventory and not tc.inventory:IsFull() and tc.trader and tc.trader:AbleToAccept(inst, attacker, 1) and tc.trader:WantsToAccept(inst, attacker, 1) then
            --交易
            tc.inventory:GiveItem(inst)
            if tc.trader:AcceptGift(attacker, inst, 1) then
                isremove = false --不用管了
            end
        elseif tc.eater and tc.eater and tc.follower and tc.follower.leader == attacker then
            --给随从回血
            if not tc.eater:Eat(inst, attacker) then
                isremove = false
                tc.components.inventoryitem:OnDropped(true)
            end
        elseif ic.edible and ic.edible.foodtype == FOODTYPE.VEGGIE and target and target:HasTag("pig") and tc.inventory and not tc.inventory:IsFull() then
            --猪人把菜吃了
            tc.inventory:GiveItem(inst)
            BufferedAction(target, inst, ACTIONS.EAT, inst):Do()
        elseif inst.prefab == "redgem" and tc.burnable then
            --红宝石点燃
            tc.burnable:Ignite(nil, inst, attacker)
        elseif inst.prefab == "bluegem" and tc.freezable then
            --蓝宝石冰冻
            tc.freezable:AddColdness(3)
        elseif (inst.prefab == "honey" or inst.prefab == "purplegem") and tc.locomotor then
            --蜂蜜、紫宝石减速
            local debuffkey = inst.prefab
            if target._aab_honey_speedmulttask ~= nil then
                target._aab_honey_speedmulttask:Cancel()
            end
            target._aab_honey_speedmulttask = target:DoTaskInTime(TUNING.SLINGSHOT_AMMO_MOVESPEED_DURATION, function(i)
                i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
                i._aab_honey_speedmulttask = nil
            end)

            tc.locomotor:SetExternalSpeedMultiplier(target, debuffkey, TUNING.SLINGSHOT_AMMO_MOVESPEED_MULT)
        elseif inst.prefab == "poop" and tc.target then
            --便便失去仇恨
            local targets_target = tc.combat.target
            if targets_target == nil or targets_target == attacker then
                tc.combat:SetShouldAvoidAggro(attacker)
                target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
                tc.combat:RemoveShouldAvoidAggro(attacker)
                tc.combat:DropTarget()
            end
        elseif inst.prefab == "thulecite_pieces" then
            --铥矿碎片生成暗影触手
            local pt = target:GetPosition()
            local theta = math.random() * TWOPI
            local offset = FindWalkableOffset(pt, theta, 2, 3, false, true, NoHoles, false, true)
            if offset ~= nil then
                local tentacle = SpawnPrefab("shadowtentacle")
                if tentacle ~= nil then
                    tentacle.owner = attacker
                    tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                    tentacle.components.combat:SetTarget(target)

                    tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_1")
                    tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_2")
                end
            end
        elseif ic.explosive then
            --爆炸物直接爆炸
            ic.explosive:OnBurnt()
        elseif inst.prefab == "cannonball_rock_item" then
            --炮弹
            local rock = SpawnAt("cannonball_rock", inst)
            rock.components.complexprojectile.onhitfn(rock, attacker, target)
        elseif ic.complexprojectile and ic.complexprojectile.onhitfn then
            --投射物，希望不会因为complexprojectile变量没初始化报什么错
            ic.complexprojectile.onhitfn(inst, attacker, target)
        elseif ic.health then
            --生物不要杀死，并且生物将仇视被攻击者
            if inst._aab_tempprojectile then
                inst._aab_tempprojectile = nil
            end
            if ic.combat then
                ic.combat:SetTarget(target)
            end
            isremove = false
        end
    end

    if isremove then
        inst:Remove()
    end
end

--重写发射逻辑
local function LaunchProjectile(self, attacker, target)
    local inst = self.inst

    inst.SoundEmitter:PlaySound("monkeyisland/cannon/shoot")
    -- inst.SoundEmitter:PlaySound("monkeyisland/cannon/hit")

    local ammo_stack = inst.components.container:GetItemInSlot(1)
    local proj = ammo_stack and inst.components.container:RemoveItem(ammo_stack, false)
    if proj ~= nil then
        if not proj.components.projectile then
            proj._aab_tempprojectile = true
            inst.projectile = proj
            proj:AddComponent("projectile")
            proj.components.projectile:SetSpeed(35)
            proj.components.projectile:SetOnHitFn(OnHit)
            proj.components.projectile:SetOnMissFn(proj.Remove)
            proj.components.projectile:SetLaunchOffset(Vector3(1, 1.2, 0))
        end

        proj.persists = false
        if self.projectile_offset ~= nil then
            local x, y, z = attacker.Transform:GetWorldPosition()

            local dir = (target:GetPosition() - Vector3(x, y, z)):Normalize()
            dir = dir * self.projectile_offset

            proj.Transform:SetPosition(x + dir.x, y, z + dir.z)
        else
            proj.Transform:SetPosition(attacker.Transform:GetWorldPosition())
        end
        proj.components.projectile:Throw(self.inst, target, attacker)
    end
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_trusty_shooter", "swap_trusty_shooter")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.components.container:Open(owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst.components.container:Close()
end

local function OnEquipToModel(inst, owner)
    inst.components.container:Close()
end

----------------------------------------------------------------------------------------------------

local function OnAmmoLoaded(inst, data)
    if data ~= nil and data.item ~= nil then
        inst.components.weapon:SetProjectile("aab_trusty_shooter_proj")
        inst.components.weapon:SetRange(TUNING.HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST, TUNING.HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST_MAX)
        inst:AddTag("rangedweapon")
        inst:AddTag("aab_gun")

        inst.components.inventoryitem.atlasname = "images/inventoryimages/trusty_shooter.xml"
        inst.components.inventoryitem:ChangeImageName("trusty_shooter")

        inst.SoundEmitter:PlaySound("monkeyisland/cannon/load")
    end
end

local function OnAmmoUnloaded(inst, data)
    inst.components.weapon:SetProjectile(nil)
    inst.components.weapon:SetRange(nil)
    inst:RemoveTag("rangedweapon")
    inst:RemoveTag("aab_gun")

    inst.components.inventoryitem.atlasname = "images/inventoryimages/trusty_shooter_unloaded.xml"
    inst.components.inventoryitem:ChangeImageName("trusty_shooter_unloaded")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("trusty_shooter")
    inst.AnimState:SetBuild("trusty_shooter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("weapon")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/trusty_shooter_unloaded.xml"
    inst.components.inventoryitem.imagename = "trusty_shooter_unloaded"

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(GetDamage)
    inst.components.weapon.LaunchProjectile = LaunchProjectile

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aab_trusty_shooter")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

    inst:ListenForEvent("itemget", OnAmmoLoaded)
    inst:ListenForEvent("itemlose", OnAmmoUnloaded)

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------------------------------------------------------------




-- 凑数用的
local function ProjectileFn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.persists = false
    inst:DoTaskInTime(0, inst.Remove)
    return inst
end

return Prefab("aab_trusty_shooter", fn, assets),
    Prefab("houndstooth_proj", ProjectileFn)
