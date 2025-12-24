local prefs = {}
local TOOLS_L = require("tools_legion")

--------------------------------------------------------------------------
--[[ 通用函数 ]]
--------------------------------------------------------------------------

local function GetAssets(name, other)
    local sets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
local function Counterattack_base(inst, doer, attacker, data, range, atk)
    local x, y, z = doer.Transform:GetWorldPosition()
    local snap
    if inst._dd_fxfn ~= nil then
        snap = inst._dd_fxfn(inst, doer, attacker)
    else
        snap = SpawnPrefab("impact")
        snap.Transform:SetScale(1.5, 1.5, 1.5)
    end
    if inst.components.shieldlegion:Counterattack(doer, attacker, data, range, atk) then
        local x1, y1, z1 = attacker.Transform:GetWorldPosition()
        local angle = -math.atan2(z1 - z, x1 - x)
        snap.Transform:SetRotation(angle * RADIANS)
        snap.Transform:SetPosition(x1, y1, z1)
        return true
    else
        snap.Transform:SetPosition(x, y, z)
        return false
    end
end
local function OnCharged(inst)
    if inst.components.shieldlegion ~= nil then
        inst.components.shieldlegion.canatk = true
    end
end
local function OnDischarged(inst)
	if inst.components.shieldlegion ~= nil then
        inst.components.shieldlegion.canatk = false
    end
end

local function MakeShield(data)
	table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(data.name)
        inst.AnimState:SetBuild(data.name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("allow_action_on_impassable")
        inst:AddTag("shield_l")
        inst:AddTag("weapon")
        inst:AddTag("rechargeable")
        inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = data.name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.name..".xml"

        inst:AddComponent("shieldlegion")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HANDS

        inst:AddComponent("weapon")

        inst:AddComponent("armor")

        inst:AddComponent("rechargeable")
        inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
        inst.components.rechargeable:SetOnChargedFn(OnCharged)

        MakeHauntableLaunch(inst)

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, data.prefabs))
end

--------------------------------------------------------------------------
--[[ 砂之抵御 ]]
--------------------------------------------------------------------------

local damage_sandstorms = 42.5  --34*1.25
local damage_normal = 30.6      --34*0.9
local damage_raining = 17       --34*0.5

local absorb_sandstorms = 0.9
local absorb_normal = 0.75
local absorb_raining = 0.4

local mult_success_sandstorms = 0.1
local mult_success_normal = 0.2
local mult_success_raining = 0.5

local function SetSandSpike(attacker, num)
    if attacker ~= nil and attacker:IsValid() then
        local map = TheWorld.Map
        local x, y, z = attacker.Transform:GetWorldPosition()
        if not map:IsVisualGroundAtPoint(x, 0, z) then --敌人在水中，无法产生沙之咬
            return
        end
        local plus = num <= 2 and 1.2 or 2
        for i = 1, num do
            local rad = math.random() * plus
            local angle = math.random() * 2 * PI
            local xxx = x + rad * math.cos(angle)
            local zzz = z - rad * math.sin(angle)
            if map:IsVisualGroundAtPoint(xxx, 0, zzz) then --不在水中
                local spike = SpawnPrefab("sandspike_legion")
                if spike ~= nil then
                    spike.Transform:SetPosition(xxx, 0, zzz)
                end
            end
        end
    end
end
local function IsOnSand(owner)
    if
        TheWorld.state.issummer and
        owner.components.areaaware ~= nil and owner.components.areaaware:CurrentlyInTag("sandstorm")
    then
        return 2
    else
        local x, y, z = owner.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
        if tile == GROUND.DESERT_DIRT then
            return 1
        end
    end
end
local function OnAttacked_sand(owner, data)
    -- owner.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/out") --被攻击时播放像沙的声音
    -- owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_scalemail")
    if data.attacker == nil then return end
    if  owner:HasTag("genesis_gaia") or owner.legiontag_mightyearth or --大地之力
        (not TheWorld.state.israining and IsOnSand(owner) ~= nil) --不能下雨
    then
        SetSandSpike(data.attacker, 1)
    end
end
local function OnChangeArea_sand(owner, area, shield)
    if shield == nil then
        shield = owner ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
        if shield == nil or shield.prefab ~= "shield_l_sand" then
            return
        end
    end

    --if TheWorld.components.sandstorms ~= nil and TheWorld.components.sandstorms:IsSandstormActive() then
    if not TheWorld:HasTag("cave") and TheWorld.state.issummer then
        --处于沙暴之中时
        if owner ~= nil and owner.components.areaaware ~= nil and owner.components.areaaware:CurrentlyInTag("sandstorm") then
            shield.components.weapon:SetDamage(damage_sandstorms)
            shield.components.armor:SetAbsorption(absorb_sandstorms)
            shield.components.shieldlegion.armormult_success = mult_success_sandstorms
            return
        end
    end
    shield.components.weapon:SetDamage(damage_normal)
    shield.components.armor:SetAbsorption(absorb_normal)
    shield.components.shieldlegion.armormult_success = mult_success_normal
end
local function OnIsRaining_sand(inst, israining)
    local owner = inst.components.inventoryitem.owner --因为这里只在装备状态下才触发，所以直接获取owner即可
    if israining then
        if owner ~= nil then owner:RemoveEventCallback("changearea", OnChangeArea_sand) end
        inst.components.weapon:SetDamage(damage_raining)
        inst.components.armor:SetAbsorption(absorb_raining)
        inst.components.shieldlegion.armormult_success = mult_success_raining
    else
        OnChangeArea_sand(owner, nil, inst)
        if not TheWorld:HasTag("cave") and TheWorld.state.issummer then --不是在洞穴里，并且夏天时才会开始沙尘暴的监听
            if owner ~= nil then
                owner:ListenForEvent("changearea", OnChangeArea_sand)
            end
        end
    end
end
local function locomotor_SetExternalSpeedMultiplier_sand(self, source, key, m, ...)
    if self.inst.legiontag_sandrunner and key == "sandstorm" then
        self:RemoveExternalSpeedMultiplier(self.inst, "sandstorm")
        return
    end
    if self.SetExternalSpeedMultiplier_legion ~= nil then
        return self.SetExternalSpeedMultiplier_legion(self, source, key, m, ...)
    end
end

local function OnEquip_sand(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on_shield(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on_shield(owner, "shield_l_sand", "swap_shield")
    end
    if owner:HasTag("equipmentmodel") then return end --假人
    inst.components.shieldlegion:Equip(owner)

    -- inst:ListenForEvent("blocked", OnAttacked_sand, owner)
    inst:ListenForEvent("attacked", OnAttacked_sand, owner)
    if owner:HasTag("genesis_gaia") or owner.legiontag_mightyearth then --大地之力
        inst._mightyearth = true
        inst.components.weapon:SetDamage(damage_sandstorms)
        inst.components.armor:SetAbsorption(absorb_sandstorms)
        inst.components.shieldlegion.armormult_success = mult_success_sandstorms
    else
        OnIsRaining_sand(inst, TheWorld.state.israining)
        inst:WatchWorldState("israining", OnIsRaining_sand)
        inst:WatchWorldState("issummer", OnIsRaining_sand)
    end
    if owner.components.locomotor ~= nil then --能在沙暴中不减速行走
        local locomotor = owner.components.locomotor
        if locomotor.SetExternalSpeedMultiplier_legion == nil then
            locomotor.SetExternalSpeedMultiplier_legion = locomotor.SetExternalSpeedMultiplier
            locomotor.SetExternalSpeedMultiplier = locomotor_SetExternalSpeedMultiplier_sand
        end
        -- locomotor:RemoveExternalSpeedMultiplier(owner, "sandstorm") --切换装备时，下一帧会自动更新移速
        owner.legiontag_sandrunner = true
    end
end
local function OnUnequip_sand(inst, owner)
    TOOLS_L.hand_off_shield(inst, owner)
    if owner:HasTag("equipmentmodel") then return end --假人

    -- inst:RemoveEventCallback("blocked", OnAttacked_sand, owner)
    inst:RemoveEventCallback("attacked", OnAttacked_sand, owner)
    owner:RemoveEventCallback("changearea", OnChangeArea_sand)
    inst:StopWatchingWorldState("israining", OnIsRaining_sand)
    inst:StopWatchingWorldState("issummer", OnIsRaining_sand)
    if owner.legiontag_sandrunner ~= nil then
        owner.legiontag_sandrunner = false
    end
    inst._owner_onsand = nil
    inst._mightyearth = nil
    if inst.components.shieldlegion.armormult_success ~= mult_success_normal then --恢复默认数值
        inst.components.weapon:SetDamage(damage_normal)
        inst.components.armor:SetAbsorption(absorb_normal)
        inst.components.shieldlegion.armormult_success = mult_success_normal
    end
end
local function ShieldAtk_sand(inst, doer, attacker, data)
    if inst._mightyearth then
        inst._owner_onsand = nil
        SetSandSpike(attacker, math.random(4, 6))
    elseif not TheWorld.state.israining then --不能下雨
        local onsand = IsOnSand(doer)
        inst._owner_onsand = onsand
        if attacker ~= nil then
            if onsand == nil then
                onsand = math.random(2)
            elseif onsand == 1 then
                onsand = math.random(3, 4)
            else
                onsand = math.random(4, 6)
            end
            SetSandSpike(attacker, onsand)
        end
    else
        inst._owner_onsand = nil
    end
    Counterattack_base(inst, doer, attacker, data, 8, 3)
end
local function ShieldAtkStay_sand(inst, doer, attacker, data)
    if attacker ~= nil then
        if inst._mightyearth then
            SetSandSpike(attacker, 2)
        elseif not TheWorld.state.israining then --不能下雨
            local onsand = inst._owner_onsand --直接沿用已有的数据，就不需要再判定了
            if onsand == nil then
                onsand = 1
            elseif onsand == 1 then
                onsand = math.random(2)
            else
                onsand = 2
            end
            SetSandSpike(attacker, onsand)
        end
    end
    inst.components.shieldlegion:Counterattack(doer, attacker, data, 8, 1.5)
end

local function SetupEquippable_sand(inst)
    inst.components.equippable:SetOnEquip(OnEquip_sand)
    inst.components.equippable:SetOnUnequip(OnUnequip_sand)
    inst.components.equippable.insulated = true --设为true，就能防电
    inst.components.equippable.walkspeedmult = 0.85
end
local foreverequip_sand = {
    -- anim = nil, anim_broken = "broken", fn_broken = nil, fn_repaired = nil,
    fn_setequippable = function(inst)
        inst:AddComponent("equippable")
        SetupEquippable_sand(inst)
    end
}

MakeShield({
    name = "shield_l_sand",
    assets = GetAssets("shield_l_sand", nil),
    prefabs = {
        "sandspike_legion", --对玩家友好的沙之咬
        "shield_attack_l_fx"
    },
    fn_common = function(inst)
        inst:AddTag("rp_sand_l")
        inst:AddTag("show_broken_ui") --装备损坏后展示特殊物品栏ui
        inst:AddTag("heavyarmor") --减轻击退效果 官方tag

        LS_C_Init(inst, "shield_l_sand", false)
    end,
    fn_server = function(inst)
        inst.components.inventoryitem:SetSinks(true) --它是石头做的，不可漂浮

        SetupEquippable_sand(inst)

        inst.hurtsoundoverride = "dontstarve/creatures/together/antlion/sfx/break"
        inst.components.shieldlegion.armormult_success = mult_success_normal
        inst.components.shieldlegion.atkfn = ShieldAtk_sand
        inst.components.shieldlegion.atkstayingfn = ShieldAtkStay_sand
        -- inst.components.shieldlegion.atkfailfn = function(inst, doer, attacker, data) end

        inst.components.weapon:SetDamage(damage_normal)

        inst.components.armor:InitCondition(1050, absorb_normal) --150*10*0.7= 1050防具耐久

        TOOLS_L.MakeNoLossRepairableEquipment(inst, foreverequip_sand)
    end
})

--------------------------------------------------------------------------
--[[ 木盾 ]]
--------------------------------------------------------------------------

local function ShieldAtk_log(inst, doer, attacker, data)
    Counterattack_base(inst, doer, attacker, data, 6, 2.5)
end
local function ShieldAtkStay_log(inst, doer, attacker, data)
    inst.components.shieldlegion:Counterattack(doer, attacker, data, 6, 0.8)
end
local function OnEquip_log(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on_shield(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on_shield(owner, "shield_l_log", "swap_shield")
    end
    if owner:HasTag("equipmentmodel") then return end --假人
    inst.components.shieldlegion:Equip(owner)
end

MakeShield({
    name = "shield_l_log",
    assets = GetAssets("shield_l_log", nil),
    prefabs = { "shield_attack_l_fx" },
    fn_common = function(inst)
        LS_C_Init(inst, "shield_l_log", true)
    end,
    fn_server = function(inst)
        inst.components.equippable:SetOnEquip(OnEquip_log)
        inst.components.equippable:SetOnUnequip(TOOLS_L.hand_off_shield)

        inst.hurtsoundoverride = "dontstarve/wilson/hit_armour"
        inst.components.shieldlegion.armormult_success = 0.4
        inst.components.shieldlegion.atkfn = ShieldAtk_log
        inst.components.shieldlegion.atkstayingfn = ShieldAtkStay_log
        -- inst.components.shieldlegion.atkfailfn = function(inst, doer, attacker, data) end

        inst.components.weapon:SetDamage(27.2) --34*0.8

        inst.components.armor:InitCondition(525, 0.6) --150*5*0.7= 525防具耐久
        inst.components.armor:AddWeakness("beaver", TUNING.BEAVER_WOOD_DAMAGE)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
    end
})

--------------------------------------------------------------------------
--[[ 恐怖盾牌的机械火焰 ]]
--------------------------------------------------------------------------

local tags_cant_terror = TOOLS_L.TagsCombat3({ "player" })

table.insert(prefs, Prefab("shieldterror_fire", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("coldfire_fire")
    inst.AnimState:SetBuild("coldfire_fire")
    inst.AnimState:PlayAnimation("level1", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetScale(0.6, 0.6, 0.6)
    -- inst.AnimState:SetFinalOffset(3)

    inst.Light:Enable(true)
    inst.Light:SetRadius(0.3)
    inst.Light:SetFalloff(0.3)
    inst.Light:SetIntensity(.3)
    if math.random() < 0.5 then
        inst.Light:SetColour(99/255, 226/255, 11/255)
        inst.AnimState:SetMultColour(99/255, 226/255, 11/255, 0.8)
    else
        inst.Light:SetColour(13/255, 226/255, 141/255)
        inst.AnimState:SetMultColour(13/255, 226/255, 141/255, 0.8)
    end

    inst:AddTag("FX")

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    inst._belly = nil

    inst._taskfire = inst:DoPeriodicTask(2, function(inst)
        local number = 0
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 2, { "_combat", "_health" }, tags_cant_terror)
        for _,v in ipairs(ents) do
            if v.entity:IsVisible() and TOOLS_L.IsEnemy_player(inst, v) then
                v.components.health:DoDelta(-5, nil, "NIL", true, nil, true)
                number = number + 4
            end
        end
        if number > 0 and inst._belly ~= nil then
            if inst._belly:IsValid() then
                if inst._belly.components.armor ~= nil and inst._belly.components.armor:GetPercent() < 1 then
                    inst._belly.components.armor:Repair(number)
                end
            else
                inst._belly = nil
            end
        end
        if math.random() < 0.2 then
            inst._taskfire:Cancel()
            inst._taskfire = nil
            inst:Remove()
        end
    end, 0)

    return inst
end, { Asset("ANIM", "anim/coldfire_fire.zip") }, nil))

--------------------------------------------------------------------------
--[[ 艾力冈的剑 ]]
--------------------------------------------------------------------------

local damage_shield = 76.5 --34*2.25
local damage_sword = 119 --34*3.5
local absorb_shield = 0.1
local absorb_sword = 0.3
local resist_shield = 0.9
local resist_sword = 0.7/0.9
local planardefense_shield = 5
local planardefense_sword = 20
local bonus_shield = 1
local bonus_sword = 1.2
local planardamage_shield = 0
local planardamage_sword = 15
local shadowlvl_shield = TUNING.SKELETONHAT_SHADOW_LEVEL --3
local shadowlvl_sword = TUNING.THURIBLE_SHADOW_LEVEL --4

local function DeathCallForRain(owner)
    TheWorld:PushEvent("ms_forceprecipitation", true)
end
local function OnAttack_agron(inst, owner, target)
    if
        owner.components.health ~= nil and owner.components.health:GetPercent() > 0.3
    then
        local xx, yy, zz = owner.Transform:GetWorldPosition()
        local x, y, z = TOOLS_L.GetCalculatedPos(xx, yy+math.random()*0.5, zz, math.random()*0.5, nil)
        local fx = SpawnPrefab(inst._dd.fx or "agronssword_fx") --燃血特效
        fx.Transform:SetPosition(x, y, z)
        owner.components.health:DoDelta(-1.5, true, "agronssword")
    end
end
local function SetOwnerDefense(inst, owner, revolt)
    if owner.components.planardefense ~= nil then
        owner.components.planardefense:AddBonus(inst, revolt and planardefense_sword or planardefense_shield)
    end
end
local function TrySetOwnerSymbol(inst, doer, revolt)
    if doer == nil then --因为此时有可能不再是装备状态，doer 发生了改变
        doer = inst.components.inventoryitem:GetGrandOwner()
    end
    if doer then
        if doer:HasTag("player") then
            if doer.components.health and doer.components.inventory then
                if inst == doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                    doer.AnimState:OverrideSymbol("lantern_overlay", inst._dd.build, revolt and "swap2" or "swap1")
                    doer.AnimState:OverrideSymbol("swap_shield", inst._dd.build, revolt and "swap2" or "swap1")
                    inst.fn_onHealthDelta(doer, nil)
                    SetOwnerDefense(inst, doer, revolt)
                end
            end
        elseif doer:HasTag("equipmentmodel") then
            doer.AnimState:OverrideSymbol("lantern_overlay", inst._dd.build, revolt and "swap2" or "swap1")
            doer.AnimState:OverrideSymbol("swap_shield", inst._dd.build, revolt and "swap2" or "swap1")
        end
    end
    if revolt then
        inst.components.inventoryitem.atlasname = inst._dd.img_atlas2
        inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex2)
        inst.AnimState:PlayAnimation("idle2")
    else
        inst.components.inventoryitem.atlasname = inst._dd.img_atlas
        inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex)
        inst.AnimState:PlayAnimation("idle")
    end
end
local function DoFxTask_agron(inst)
    if inst._task_fx == nil then
        inst._task_fx = inst:DoPeriodicTask(0.25, function(inst)
            local doer = inst.components.inventoryitem:GetGrandOwner() or inst
            local xx, yy, zz = doer.Transform:GetWorldPosition()
            local x, y, z = TOOLS_L.GetCalculatedPos(xx, yy+math.random()*0.5, zz, math.random()*0.5, nil)
            local fx = SpawnPrefab(inst._dd.fx or "agronssword_fx")
            fx.Transform:SetPosition(x, y, z)
        end, math.random())
    end
end
local function DoRevolt(inst, doer)
    if not inst._revolt_l then
        inst._revolt_l = true
        inst._basedamage = damage_sword
        inst.components.weapon:SetDamage(damage_sword)
        inst.components.armor:SetAbsorption(absorb_sword)
        inst.components.planardamage:SetBaseDamage(planardamage_sword)
        -- inst.components.planardefense:SetBaseDefense(planardefense_sword)
        inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, bonus_sword, "revolt")
        inst.components.damagetyperesist:AddResist("shadow_aligned", inst, resist_sword, "revolt")
        inst.components.shadowlevel:SetDefaultLevel(shadowlvl_sword)

        TrySetOwnerSymbol(inst, doer, true)

        if inst._dd.fxfn ~= nil then
            inst._dd.fxfn(inst)
        else
            DoFxTask_agron(inst)
        end
    end
end
local function OnLoad_agron(inst, data)
    if inst.components.timer:TimerExists("revolt") then
        DoRevolt(inst, nil)
    end
end
local function TimerDone_agron(inst, data)
    if data.name == "revolt" then
        inst._revolt_l = nil
        inst._basedamage = damage_shield
        inst.components.weapon:SetDamage(damage_shield)
        inst.components.armor:SetAbsorption(absorb_shield)
        inst.components.planardamage:SetBaseDamage(planardamage_shield)
        -- inst.components.planardefense:SetBaseDefense(planardefense_shield)
        inst.components.damagetypebonus:RemoveBonus("lunar_aligned", inst, "revolt")
        inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "revolt")
        inst.components.shadowlevel:SetDefaultLevel(shadowlvl_shield)

        TrySetOwnerSymbol(inst, nil, false)

        if inst._task_fx ~= nil then
            inst._task_fx:Cancel()
            inst._task_fx = nil
        end
        if inst._dd.fxendfn ~= nil then
            inst._dd.fxendfn(inst)
        end
    end
end

local function OnEquip_agron(inst, owner)
    local revolt = inst.components.timer:TimerExists("revolt")
    TOOLS_L.hand_on_shield(owner, inst._dd.build, revolt and "swap2" or "swap1")
    if owner:HasTag("equipmentmodel") then return end --假人
    inst.components.shieldlegion:Equip(owner)

    SetOwnerDefense(inst, owner, revolt)
    if owner.components.health ~= nil then
        owner:ListenForEvent("death", DeathCallForRain)
        owner:ListenForEvent("healthdelta", inst.fn_onHealthDelta)
        inst.fn_onHealthDelta(owner, nil)
    end
end
local function OnUnequip_agron(inst, owner)
    owner:RemoveEventCallback("death", DeathCallForRain)
    owner:RemoveEventCallback("healthdelta", inst.fn_onHealthDelta)
    inst.components.weapon:SetDamage(inst._basedamage) --卸下时，恢复攻击力，为了让巨人之脚识别到
    if owner.components.planardefense ~= nil then
        owner.components.planardefense:RemoveBonus(inst, nil)
    end
    TOOLS_L.hand_off_shield(inst, owner)
end
local function HealMe(doer, data)
    local percent = doer.components.health:GetPercent()
    if percent > 0 and percent <= 0.3 then
        percent = (data.damage+data.otherdamage)*0.08
        doer.components.health:DoDelta(percent, true, "debug_key", true, nil, true) --对旺达的回血只有特定原因才能成功
    end
end
local function ShieldAtk_agron(inst, doer, attacker, data)
    --先加攻击力，这样输出高一点
    local timeleft = inst.components.timer:GetTimeLeft("revolt") or 0
    inst.components.timer:StopTimer("revolt")
    inst.components.timer:StartTimer("revolt", math.min(120, timeleft+10))
    DoRevolt(inst, doer)

    Counterattack_base(inst, doer, attacker, data, 8, 1.3)

    --后回血，这样输出高一点
    HealMe(doer, data)
end
local function ShieldAtkStay_agron(inst, doer, attacker, data)
    inst.components.shieldlegion:Counterattack(doer, attacker, data, 8, 1)
    HealMe(doer, data)
end
local function Wax_agron(inst, doer, waxitem, right)
    local dd = {}
    if inst._revolt_l then
        dd.state = 1
    end
    return TOOLS_L.WaxObject(inst, doer, waxitem, "agronssword_item_waxed", dd, nil)
end

MakeShield({
    name = "agronssword",
    assets = GetAssets("agronssword", {
        Asset("ATLAS", "images/inventoryimages/agronssword2.xml"),
        Asset("IMAGE", "images/inventoryimages/agronssword2.tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/agronssword2.xml", 256)
    }),
    prefabs = { "agronssword_fx" },
    fn_common = function(inst)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("agronssword.tex")
        inst.MiniMapEntity:SetPriority(5) --稀有物品，优先级设高点

        inst:AddTag("sharp") --武器的标签跟攻击方式跟攻击音效有关 没有特殊的话就用这两个
        inst:AddTag("pointy")
        inst:AddTag("nonpotatable") --这个貌似是不可食用标签？
        inst:AddTag("hide_percentage")  --这个标签能让护甲耐久比例不显示出来
        inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分
        inst:AddTag("waxable_l")
        inst:AddTag("shadowlevel")
        inst:AddTag("shadow_item")
        if CONFIGS_LEGION.WORLDSWORDLIMITATION then
            inst:AddTag("meteor_protection") --防止被流星破坏
            inst:AddTag("noattack") --防止被巨型蠕虫吃掉
            inst:AddTag("nobundling") --不能被打包、不会被巨食草消化
        else
            inst:AddTag("irreplaceable") --防止被猴子、食人花、坎普斯等拿走，防止被流星破坏，并使其下线时会自动掉落
        end

        LS_C_Init(inst, "agronssword", true)
    end,
    fn_server = function(inst)
        inst._dd = {
            img_tex = "agronssword", img_atlas = "images/inventoryimages/agronssword.xml",
            img_tex2 = "agronssword2", img_atlas2 = "images/inventoryimages/agronssword2.xml",
            build = "agronssword", fx = "agronssword_fx"
        }
        -- inst._task_fx = nil
        -- inst._revolt_l = nil
        inst._basedamage = damage_shield
        inst.fn_doFxTask = DoFxTask_agron
        inst.fn_onHealthDelta = function(owner, data)
            local percent = 1.0
            if data and data.newpercent then
                percent = data.newpercent
            else
                percent = owner.components.health:GetPercent()
            end
            inst.components.weapon:SetDamage(math.floor( inst._basedamage*(1.2-percent) ))
        end
        inst.legionfn_wax = Wax_agron

        -- inst.components.inventoryitem:SetSinks(true) --落水时会下沉，但是因为标签的关系会回到附近岸边

        inst.components.weapon:SetDamage(damage_shield)
        inst.components.weapon:SetOnAttack(OnAttack_agron)

        inst.components.armor:InitCondition(100, absorb_shield)
        inst.components.armor.indestructible = true --无敌的护甲
        if inst.components.armor.SetKeepOnFinished == nil then --有的mod替换了这个组件，导致没兼容官方的新函数
            inst.components.armor.keeponfinished = true
        else
            inst.components.armor:SetKeepOnFinished(true) --防止因为别的mod导致耐久为0
        end

        inst.components.equippable:SetOnEquip(OnEquip_agron)
        inst.components.equippable:SetOnUnequip(OnUnequip_agron)

        inst:AddComponent("planardamage")
        inst.components.planardamage:SetBaseDamage(planardamage_shield)

        -- inst:AddComponent("planardefense")
	    -- inst.components.planardefense:SetBaseDefense(planardefense_shield)

        inst:AddComponent("damagetypebonus")
        inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, bonus_shield)

        inst:AddComponent("damagetyperesist")
	    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, resist_shield)

        inst:AddComponent("shadowlevel")
	    inst.components.shadowlevel:SetDefaultLevel(shadowlvl_shield)

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", TimerDone_agron)

        inst.hurtsoundoverride = "dontstarve/wilson/hit_armour"
        inst.components.shieldlegion.armormult_success = 0
        inst.components.shieldlegion.atkfn = ShieldAtk_agron
        inst.components.shieldlegion.atkstayingfn = ShieldAtkStay_agron
        -- inst.components.shieldlegion.atkfailfn = function(inst, doer, attacker, data) end
        inst.components.shieldlegion.shieldkey = "agronssword"
        inst.components.shieldlegion.time_charge = CONFIGS_LEGION.AGRONRECHARGETIME
        inst.components.shieldlegion.time_change = CONFIGS_LEGION.AGRONEXCHANGETIME

        inst.OnLoad = OnLoad_agron
    end
})

--------------------
--------------------

return unpack(prefs)
