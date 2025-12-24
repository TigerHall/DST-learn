local TOOLS_L = require("tools_legion")
local prefs = {}
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --专门放各个prefab独特的变量

fns.GetAssets = function(name, other)
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

fns.CommonFn = function(inst, bank, build, anim, isloop)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim or "idle", isloop)

    inst:AddTag("hat")
    inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制
end
fns.ServerFn = function(inst, img, OnEquip, OnUnequip)
    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = img
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..img..".xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end
fns.ServerFn_noequip = function(inst, img)
    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = img
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..img..".xml"
end

fns.SetPerishable = function(inst, time, replacement, onperish) --新鲜度组件
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(time)
    if replacement ~= nil then
        inst.components.perishable.onperishreplacement = replacement
    end
    if onperish ~= nil then
        inst.components.perishable:SetOnPerishFn(onperish)
    end
    inst.components.perishable:StartPerishing()
end
fns.SetBonus = function(inst, name, OnSetBonusOn, OnSetBonusOff)
    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES[name])
    inst.components.setbonus:SetOnEnabledFn(OnSetBonusOn)
    inst.components.setbonus:SetOnDisabledFn(OnSetBonusOff)
end
fns.SetKeepOnFinished = function(inst)
    if inst.components.armor.SetKeepOnFinished == nil then --有的mod替换了这个组件，导致没兼容官方的新函数
        inst.components.armor.keeponfinished = true
    else
        inst.components.armor:SetKeepOnFinished(true) --耐久为0不消失
    end
end

fns.OnLandedClient_new = function(self, ...)
    if self.OnLandedClient_legion ~= nil then
        self.OnLandedClient_legion(self, ...)
    end
    if self.floatparam_l ~= nil then
        self.inst.AnimState:SetFloatParams(self.floatparam_l, 1, self.bob_percent)
    end
end
fns.SetFloatable = function(inst, float) --漂浮组件
    MakeInventoryFloatable(inst, float[2], float[3], float[4])
    if float[1] ~= nil then
        local floater = inst.components.floater
        if floater.OnLandedClient_legion == nil then
            floater.OnLandedClient_legion = floater.OnLandedClient
            floater.OnLandedClient = fns.OnLandedClient_new
        end
        floater.floatparam_l = float[1]
    end
end

--------------------------------------------------------------------------
--[[ 苔衣发卡 ]]
--------------------------------------------------------------------------

pas.OnEquip_lichen = function(inst, owner)
    if inst._light == nil or not inst._light:IsValid() then
        inst._light = SpawnPrefab("lichenhatlight") --生成光源
        inst._light.entity:SetParent(owner.entity)  --给光源设置父节点
    end
    if inst._dd ~= nil then
        local dd = inst._dd
        if dd.isopentop then
            TOOLS_L.hat_on_opentop(owner, dd.build, dd.file)
        else
            TOOLS_L.hat_on(owner, dd.build, dd.file)
        end
        if dd.lightcolor ~= nil then
            inst._light.Light:SetColour(dd.lightcolor.r, dd.lightcolor.g, dd.lightcolor.b)
        end
    else
        TOOLS_L.hat_on_opentop(owner, "hat_lichen", "swap_hat")
    end

    TOOLS_L.AddTag(owner, "ignoreMeat", inst.prefab) --添加忽略带着肉的标签

    local soundemitter = owner.SoundEmitter or inst.SoundEmitter
    soundemitter:PlaySound("dontstarve/common/minerhatAddFuel") --装备时的音效
end
pas.OnUnequip_lichen = function(inst, owner)
    TOOLS_L.hat_off(inst, owner)

    TOOLS_L.RemoveTag(owner, "ignoreMeat", inst.prefab)
    if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove() --把光源移除
        end
        inst._light = nil
    end

    local soundemitter = owner.SoundEmitter or inst.SoundEmitter
    soundemitter:PlaySound("dontstarve/common/minerhatOut") --卸下时的音效
end

table.insert(prefs, Prefab("hat_lichen", function()
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "hat_lichen", nil, "anim", nil)
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
    inst:AddTag("open_top_hat") --虽然这个标签作用于植物人的贴图切换，但我没看出来到底哪里变了
    LS_C_Init(inst, "hat_lichen", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst._light = nil

    fns.ServerFn(inst, "hat_lichen", pas.OnEquip_lichen, pas.OnUnequip_lichen)
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED
    fns.SetPerishable(inst, TUNING.PERISH_ONE_DAY*5, nil, inst.Remove)
    MakeHauntableLaunchAndPerish(inst)

    return inst
end, fns.GetAssets("hat_lichen"), { "lichenhatlight" }))

table.insert(prefs, Prefab("lichenhatlight", function() ------苔衣发卡的光源实体
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetFalloff(0.4)  --衰减
    inst.Light:SetIntensity(.7) --亮度
    inst.Light:SetRadius(2)     --半径
    inst.Light:SetColour(237/255, 237/255, 209/255) --颜色，和灯泡花一样

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, nil, nil))

--------------------------------------------------------------------------
--[[ 牛仔帽 ]]
--------------------------------------------------------------------------

pas.COW_PERIOD = 10
pas.GAIN_DOMESTICATION = TUNING.BEEFALO_DOMESTICATION_GAIN_DOMESTICATION * 0.33 * pas.COW_PERIOD

pas.CowboyTaming = function(inst)
    if inst.mycowboy == nil or not inst.mycowboy:IsValid() then
        if inst.task_cowboy ~= nil then
            inst.task_cowboy:Cancel()
            inst.task_cowboy = nil
        end
        inst.mycowboy = nil
        return
    end

    --取消骑行时间限制(先取消，后面可以少触发一些官方逻辑)
    local mount = inst.mycowboy.components.rider ~= nil and inst.mycowboy.components.rider:GetMount() or nil
    if mount ~= nil then
        if
            mount._bucktask ~= nil and
            mount.components.domesticatable ~= nil and
            mount.components.domesticatable:IsDomesticated() --只对已驯化完成的坐骑有用
        then
            mount._bucktask:Cancel()
            mount._bucktask = nil
        end
        mount = nil
    end
    --范围提升驯化度
    local x, y, z = inst.mycowboy.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, nil, { "INLIMBO", "NOCLICK" }, { "player", "domesticatable" })
    for _, v in ipairs(ents) do
        if v.entity:IsVisible() and
            (v.components.health == nil or not v.components.health:IsDead())
        then
            if v.components.rider ~= nil then --玩家
                mount = v.components.rider:GetMount()
            elseif v.components.domesticatable ~= nil then --坐骑
                if v.components.domesticatable:GetDomestication() > 0 then --驯化度不能为0
                    mount = v
                end
            end
            if mount ~= nil and mount.components.domesticatable ~= nil then
                mount = mount.components.domesticatable
                if mount:GetDomestication() < 1 then
                    mount:DeltaDomestication(pas.GAIN_DOMESTICATION)
                end
                if mount:GetObedience() < mount.maxobedience then
                    mount:DeltaObedience(0.2)
                end
            end
            mount = nil
        end
    end
end
pas.OnUnequip_cowboyscarf = function(owner, data)
    if data ~= nil and data.eslot == EQUIPSLOTS.BODY then
        owner.AnimState:OverrideSymbol("swap_body", owner.scarf_skin_l or "hat_cowboy", "swap_body")
    end
end
pas.OnMounted_cowboy = function(owner, data)
    TOOLS_L.AddTag(owner, "firmbody_l", "hat_cowboy")
end
pas.OnDismounted_cowboy = function(owner, data)
    TOOLS_L.RemoveTag(owner, "firmbody_l", "hat_cowboy")
end
pas.OnEquip_cowboy = function(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hat_on(owner, inst._dd.build, inst._dd.file)
        owner.scarf_skin_l = inst._dd.build
    else
        TOOLS_L.hat_on(owner, "hat_cowboy", "swap_hat")
        owner.scarf_skin_l = nil
    end

    if owner:HasTag("equipmentmodel") then return end --假人

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end
    owner:AddTag("beefalo") --牛牛的标签，加入后不会被发情牛主动攻击
    if owner:HasTag("player") then
        if owner.components.inventory ~= nil then --与传统帽子不同的是，这个帽子会有红色牛仔围巾的套装效果
            if owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == nil then --没穿衣服时，换上牛仔围巾
                owner.AnimState:OverrideSymbol("swap_body", owner.scarf_skin_l or "hat_cowboy", "swap_body")
            end
            owner:ListenForEvent("unequip", pas.OnUnequip_cowboyscarf)
        end
    end
    if owner.components.rider ~= nil then
        owner:ListenForEvent("mounted", pas.OnMounted_cowboy)
        owner:ListenForEvent("dismounted", pas.OnDismounted_cowboy)
        if owner.components.rider:IsRiding() then
            pas.OnMounted_cowboy(owner, nil)
        end
        TOOLS_L.AddTag(owner, "cowboy_l", inst.prefab)
    end

    if inst.task_cowboy ~= nil then
        inst.task_cowboy:Cancel()
    end
    inst.mycowboy = owner
    inst.task_cowboy = inst:DoPeriodicTask(pas.COW_PERIOD, pas.CowboyTaming, pas.COW_PERIOD+5*math.random())
end
pas.OnUnequip_cowboy = function(inst, owner)
    TOOLS_L.hat_off(inst, owner)
    owner.scarf_skin_l = nil

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
    owner:RemoveTag("beefalo")
    if owner:HasTag("player") then
        if owner.components.inventory ~= nil then
            if owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == nil then --没穿衣服时，去除牛仔围巾
                owner.AnimState:ClearOverrideSymbol("swap_body")
            end
        end
        owner:RemoveEventCallback("unequip", pas.OnUnequip_cowboyscarf)
    end
    owner:RemoveEventCallback("mounted", pas.OnMounted_cowboy)
    owner:RemoveEventCallback("dismounted", pas.OnDismounted_cowboy)
    pas.OnDismounted_cowboy(owner, nil)
    TOOLS_L.RemoveTag(owner, "cowboy_l", inst.prefab)

    if inst.task_cowboy ~= nil then
        inst.task_cowboy:Cancel()
        inst.task_cowboy = nil
    end
    inst.mycowboy = nil
end

table.insert(prefs, Prefab("hat_cowboy", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "hat_cowboy", nil, "anim", nil)
    LS_C_Init(inst, "hat_cowboy", true)
    inst:AddTag("waterproofer")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst.mycowboy = nil

    fns.ServerFn(inst, "hat_cowboy", pas.OnEquip_cowboy, pas.OnUnequip_cowboy)
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED --和高礼帽一样的精神恢复
    inst.components.equippable.insulated = true --防电

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_HUGE) --90%防水

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_MED) --2分钟
    inst.components.insulator:SetSummer() --设置为夏季后，就是延缓温度上升的效果了

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.TOTAL_DAY_TIME*10) --10天的佩戴时间
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("hat_cowboy"), nil))

--------------------------------------------------------------------------
--[[ 犀金胄甲 ]]
--------------------------------------------------------------------------

pas.SetBonusOn_beetlehat = function(inst)
    inst.components.armor.conditionlossmultipliers:SetModifier(inst, 0.6, "setbonus")
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil and owner.components.combat ~= nil then
        owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.2, "beetlepower")
    end
end
pas.SetBonusOff_beetlehat = function(inst)
    inst.components.armor.conditionlossmultipliers:RemoveModifier(inst, "setbonus")
    if inst.components.equippable and inst.components.equippable:IsEquipped() then --可能头甲卸下了，也可能是自己被卸下了
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.combat ~= nil then
            owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.1, "beetlepower")
        end
    end
end
pas.OnEquip_beetlehat = function(inst, owner)
    if inst._dd ~= nil then
        if inst._dd.isfullhead then
            TOOLS_L.hat_on_fullhead(owner, inst._dd.build, inst._dd.file)
        else
            TOOLS_L.hat_on(owner, inst._dd.build, inst._dd.file)
        end
    else
        TOOLS_L.hat_on(owner, "hat_elepheetle", "swap_hat")
    end
    if owner:HasTag("equipmentmodel") then return end --假人

    --工作效率
    if owner.components.workmultiplier == nil then
        owner:AddComponent("workmultiplier")
    end
    owner.components.workmultiplier:AddMultiplier(ACTIONS.CHOP,   1.5, inst)
    owner.components.workmultiplier:AddMultiplier(ACTIONS.MINE,   1.5, inst)
    owner.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, 1.5, inst)
    --攻击力。尽管 OnSetBonusOff 里也会设置，但是 setbonus 组件只会对玩家有效，这里写是为了兼容所有生物
    if owner.components.combat ~= nil then
        owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.1, "beetlepower")
    end
    --健身值
    -- if owner.components.mightiness ~= nil then
    --     owner.components.mightiness.ratemodifiers:SetModifier(inst, 0.3)
    -- end

    TOOLS_L.AddTag(owner, "burden_ignor_l", inst.prefab) --免疫装备减速 棱镜tag
end
pas.OnUnequip_beetlehat = function(inst, owner)
    if inst._dd ~= nil and inst._dd.isfullhead then
        TOOLS_L.hat_off_fullhead(inst, owner)
    else
        TOOLS_L.hat_off(inst, owner)
    end

    if owner:HasTag("equipmentmodel") then return end --假人

    if owner.components.workmultiplier ~= nil then
        owner.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP,   inst)
        owner.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE,   inst)
        owner.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, inst)
    end
    if owner.components.combat ~= nil then
        owner.components.combat.externaldamagemultipliers:RemoveModifier(inst, "beetlepower")
    end
    -- if owner.components.mightiness ~= nil then
    --     owner.components.mightiness.ratemodifiers:RemoveModifier(inst)
    -- end
    TOOLS_L.RemoveTag(owner, "burden_ignor_l", inst.prefab)
end
pas.foreverequip_beetlehat = {
    -- anim = nil, anim_broken = "broken", fn_broken = nil, fn_repaired = nil,
    fn_setequippable = function(inst)
        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(pas.OnEquip_beetlehat)
        inst.components.equippable:SetOnUnequip(pas.OnUnequip_beetlehat)
        inst.components.equippable.walkspeedmult = 0.85
    end
}

table.insert(prefs, Prefab("hat_elepheetle", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "hat_elepheetle", nil, nil, nil)
    inst:AddTag("waterproofer")
    inst:AddTag("burden_l")
    inst:AddTag("rp_bugshell_l")
    inst:AddTag("show_broken_ui") --装备损坏后展示特殊物品栏ui
    LS_C_Init(inst, "hat_elepheetle", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn_noequip(inst, "hat_elepheetle")
    pas.foreverequip_beetlehat.fn_setequippable(inst)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(1050, 0.8)

    fns.SetBonus(inst, "ELEPHEETLE", pas.SetBonusOn_beetlehat, pas.SetBonusOff_beetlehat)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    MakeHauntableLaunch(inst)

    TOOLS_L.MakeNoLossRepairableEquipment(inst, pas.foreverequip_beetlehat)

    return inst
end, fns.GetAssets("hat_elepheetle"), nil))

--------------------------------------------------------------------------
--[[ 子圭·汲 ]]
--------------------------------------------------------------------------

pas.OnSave_sivmask = function(inst, data)
    if inst.healthcounter > 0 then
        data.healthcounter = inst.healthcounter
    end
end
pas.OnLoad_sivmask = function(inst, data)
    if data ~= nil then
        if data.healthcounter ~= nil then
            inst.healthcounter = data.healthcounter
        end
    end
end

pas.TaskOff_life = function(inst, owner)
    if inst.task_life ~= nil then
        inst.task_life:Cancel()
        inst.task_life = nil
    end
    inst.lifetarget = nil
end
pas.SpawnLifeFx = function(target, owner, inst)
    local life = SpawnPrefab(inst.maskfxoverride_l or "siving_lifesteal_fx")
    if life ~= nil then
        life.movingTarget = owner
        life.minDistanceSq = 1.02
        life.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

pas.DrinkLife = function(mask, target, value)
    --积累生命
    if mask.healthcounter < mask.healthcounter_max then --由于 healthcounter_max 会变化，所以这里只加不减
        mask.healthcounter = math.min(mask.healthcounter_max, mask.healthcounter + value)
    end
    --吸取生命
    target.components.health:DoDelta(-value, true, mask.prefab, false, nil, true)
end
pas.HealOwner_sivmask = function(mask, owner)
    if owner.components.health ~= nil and not owner:HasTag("playerghost") and
        not owner.components.health:IsDead() and owner.components.health:GetPercentWithPenalty() < 0.98
    then
        --对旺达的回血只有特定原因才能成功：debug_key
        owner.components.health:DoDelta(mask.healpower_l or 2, true, "debug_key", true, nil, true)
        mask.healthcounter = mask.healthcounter - 4
        return true
    end
    return false
end
pas.HealArmor_sivmask = function(mask, owner, ismask2)
    if ismask2 then
        if owner._bloodarmor2_l ~= nil and owner._bloodarmor2_l.components.armor:GetPercent() < 1 then
            owner._bloodarmor2_l.components.armor:Repair(10)
        else
            ismask2 = false
        end
    end
    if mask.components.armor:GetPercent() < 1 then
        mask.components.armor:Repair(ismask2 and 30 or 40)
        mask.healthcounter = mask.healthcounter - 20
    else
        if ismask2 then
            mask.healthcounter = mask.healthcounter - 5
        end
    end
end
pas.IsValidVictim_sivmask = function(ent, owner, isfriendly)
    if ent.siv_blood_l_reducer_v ~= nil and ent.siv_blood_l_reducer_v >= 1 then
        return false
    end
    if isfriendly then --向善模式，只吸收对装备者有仇恨的对象
        return TOOLS_L.IsEnemy_me(owner, ent)
    else --皆苦模式，所有可能的敌人都会被吸收
        return TOOLS_L.MaybeEnemy_player(owner, ent, true)
    end
end
pas.StealHealth_sivmask = function(inst, owner, ismask2, isfriendly)
    local notags
    if owner:HasTag("player") or owner:HasTag("equipmentmodel") then --佩戴者是玩家、假人时，不吸收其他玩家
        notags = TOOLS_L.TagsSiving({ "player", "siving", "companion", "glommer", "friendlyfruitfly", "abigail" })
    else
        notags = TOOLS_L.TagsSiving({ "siving", "glommer", "friendlyfruitfly" })
    end
    local _taskcounter = 0
    local doit = false
    local x, y, z
    local target
    local costnow = 0
    inst.task_life = inst:DoPeriodicTask(0.5, function(inst)
        if not owner:IsValid() then
            pas.TaskOff_life(inst, owner)
            return
        end

        ----计数器管理
        _taskcounter = _taskcounter + 1
        doit = false
        if _taskcounter % 4 == 0 then --每过两秒
            doit = true
            _taskcounter = 0
        end

        ----吸取对象的管理
        x, y, z = owner.Transform:GetWorldPosition()
        target = inst.lifetarget
        if  target == nil or not target:IsValid() or target:IsInLimbo() or --吸血对象失效了，重新找新对象
            not pas.IsValidVictim_sivmask(target, owner, isfriendly) or
            target:GetDistanceSqToPoint(x, y, z) > 400 --20*20
        then
            target = FindEntity(owner, 20, function(ent, finder)
                return pas.IsValidVictim_sivmask(ent, finder, isfriendly)
            end, { "_health", "_combat" }, notags, nil)
            inst.lifetarget = target
        end

        ----窃血抵抗
        if target ~= nil then
            costnow = inst.bloodsteal_l or 2
            if target.siv_blood_l_reducer_v ~= nil then
                if target.siv_blood_l_reducer_v >= 1 then --经过了前面的判定，这里应该不会再触发了
                    costnow = 0
                else
                    costnow = costnow * (1-target.siv_blood_l_reducer_v)
                end
            end
            if costnow > 0 then --特效
                pas.SpawnLifeFx(target, owner, inst)
            end
        else
            costnow = 0
        end

        ----积累的管理
        if doit then
            if costnow > 0 then
                pas.DrinkLife(inst, target, costnow)
            end
            if ismask2 or target ~= nil then
                if inst.healthcounter >= 4 then
                    if pas.HealOwner_sivmask(inst, owner) then --优先为玩家恢复生命
                        if inst.healthcounter >= 24 then --剩余积累足够再回血时，则恢复自己耐久
                            pas.HealArmor_sivmask(inst, owner, ismask2)
                        end
                    else
                        if inst.healthcounter >= 20 then --其次才是恢复自己的耐久
                            pas.HealArmor_sivmask(inst, owner, ismask2)
                        end
                    end
                end
            else
                if inst.components.armor:GetPercent() < 1 then --自己损坏了
                    if not owner:HasTag("playerghost") and
                        owner.components.health ~= nil and not owner.components.health:IsDead()
                    then
                        pas.DrinkLife(inst, owner, inst.bloodsteal_l or 2)
                    end
                    if inst.healthcounter >= 20 then
                        pas.HealArmor_sivmask(inst, owner, false)
                    end
                end
            end
        end
    end, 0.5+2.5*math.random())
end

pas.SetBonusOn_sivmask = function(inst)
	inst.bloodsteal_l = 3
    inst.healthcounter_max = 120
end
pas.SetBonusOff_sivmask = function(inst)
	inst.bloodsteal_l = 2
    inst.healthcounter_max = 80
end
pas.GetSwapSymbol_sivmask = function(owner)
    local maps = {
        wolfgang = true,
        waxwell = true,
        wathgrithr = true,
        winona = true,
        wortox = true,
        wormwood = true,
        wurt = true,
        pigman = true,
        pigguard = true,
        moonpig = true,
        bunnyman = true,
        sewing_mannequin = true
    }
    if owner.sivmask_swapsymbol or maps[owner.prefab] then
        return "swap_other"
    else
        return "swap_hat"
    end
end
pas.SetSymbols_sivmask = function(inst, owner)
    if inst._dd ~= nil then
        local dd = inst._dd
        if dd.startfn ~= nil then
            dd.startfn(inst, owner)
            return
        end
        if dd.isopentop then
            TOOLS_L.hat_on_opentop(owner, dd.build, dd.file or pas.GetSwapSymbol_sivmask(owner))
        else
            TOOLS_L.hat_on(owner, dd.build, dd.file or pas.GetSwapSymbol_sivmask(owner))
        end
    else
        TOOLS_L.hat_on_opentop(owner, inst.prefab, pas.GetSwapSymbol_sivmask(owner))
    end
end
pas.ClearSymbols_sivmask = function(inst, owner)
    if inst._dd ~= nil then
        if inst._dd.endfn ~= nil then
            inst._dd.endfn(inst, owner)
        end
    end
    TOOLS_L.hat_off(inst, owner)
end
pas.OnEquip_sivmask = function(inst, owner)
    pas.SetSymbols_sivmask(inst, owner)
    pas.StealHealth_sivmask(inst, owner, false, false)
    if owner:HasTag("equipmentmodel") then return end --假人
    TOOLS_L.AddEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1, 0.25)
end
pas.OnUnequip_sivmask = function(inst, owner)
    pas.ClearSymbols_sivmask(inst, owner)
    TOOLS_L.RemoveEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1)
    pas.TaskOff_life(inst, owner)
end
pas.DealData_sivmask = function(inst, data)
    local dd = {
        v = tostring(data.v or 0),
        vmax = tostring(data.vmax or 80),
        st = tostring(data.st or 2),
        h = "2"
    }
    return subfmt(STRINGS.NAMEDETAIL_L.SIVMASK, dd)
end
pas.GetData_sivmask = function(inst)
    local data = {}
    if inst.healthcounter > 0 then
        data.v = TOOLS_L.ODPoint(inst.healthcounter, 10) --变化大的数据记得省略小数点
    end
    if inst.healthcounter_max ~= 80 then
        data.vmax = inst.healthcounter_max
    end
    if inst.bloodsteal_l ~= 2 then
        data.st = inst.bloodsteal_l
    end
    return data
end

table.insert(prefs, Prefab("siving_mask", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "siving_mask", nil, nil, nil)
    TOOLS_L.InitMouseInfo(inst, pas.DealData_sivmask, pas.GetData_sivmask)
    LS_C_Init(inst, "siving_mask", false)

    -- inst:AddTag("open_top_hat")
    -- inst:AddTag("siv_mask")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.healthcounter = 0
    -- inst.lifetarget = nil
    inst.bloodsteal_l = 2 --窃血值
    inst.healthcounter_max = 80 --积累上限

    fns.ServerFn(inst, "siving_mask", pas.OnEquip_sivmask, pas.OnUnequip_sivmask)
    inst.components.inventoryitem:SetSinks(true) --它是石头做的，不可漂浮

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(315, 0.7)

    fns.SetBonus(inst, "SIVING", pas.SetBonusOn_sivmask, pas.SetBonusOff_sivmask)

    MakeHauntableLaunch(inst)

    inst.OnSave = pas.OnSave_sivmask
    inst.OnLoad = pas.OnLoad_sivmask

    return inst
end, fns.GetAssets("siving_mask"), { "siving_lifesteal_fx" }))

--------------------------------------------------------------------------
--[[ 子圭·歃 ]]
--------------------------------------------------------------------------

pas.OnRepaired_sivmask2 = function(inst, amount)
    if amount > 0 and inst._broken then
        inst._broken = nil
        inst:AddTag("siv_mask2")
        inst.components.armor:SetAbsorption(0.75)
    end
end
pas.OnBroken_sivmask2 = function(inst)
    if not inst._broken then
        inst._broken = true
        inst:RemoveTag("siv_mask2")
        inst.components.armor:SetAbsorption(0)
        inst:PushEvent("percentusedchange", { percent = 0 }) --界面需要更新百分比
    end
end
pas.OnAttackOther_sivmask2 = function(owner, data, mask)
    if data == nil or mask.components.modelegion.now ~= 1 then
        return
    end
    if  data.target ~= nil and data.target:IsValid() and
        data.target.components.health ~= nil and not data.target.components.health:IsDead() and
        (data.target.siv_blood_l_reducer_v == nil or data.target.siv_blood_l_reducer_v < 1) and
        not data.target:HasAnyTag("ghost", "wall", "structure", "balloon", "playerghost")
    then
        mask.lifetarget = data.target
    end
end
pas.CalcuCost_sivmask2 = function(mask, doer, cost)
    if mask.healthcounter == nil then
        mask.healthcounter = 0
    elseif mask.healthcounter >= cost then
        mask.healthcounter = mask.healthcounter - cost
        return true
    else
        cost = cost - mask.healthcounter
    end
    if doer.components.health ~= nil then
        if doer.components.oldager ~= nil then --无语，还要考虑旺达
            if doer.components.health.currenthealth <= (cost*TUNING.OLDAGE_HEALTH_SCALE) then
                return false
            end
        elseif doer.components.health.currenthealth <= cost then
            return false
        end
        mask.healthcounter = 0
        doer.components.health:DoDelta(-cost, true, mask.prefab, false, nil, true)
        return true
    end
    return false
end
pas.SetLifeBendFx = function(target, doer)
    local fx = SpawnPrefab("life_trans_fx")
    if fx ~= nil then
        fx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
    if doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound("monkeyisland/wonkycurse/curse_fx")
    end
end
pas.Bend_sivmask2 = function(mask, doer, target, options)
    if target == nil or not target:IsValid() then
        return false
    end

    if target.OnLifebBend_l ~= nil then --生命容器
        local reason = target.OnLifebBend_l(mask, doer, target, options)
        if reason ~= nil then
            return false, reason
        end
    elseif target.prefab == "flower_withered" then --枯萎花
        if pas.CalcuCost_sivmask2(mask, doer, 5) then
            local flower = SpawnPrefab("planted_flower")
            if flower ~= nil then
                flower.Transform:SetPosition(target.Transform:GetWorldPosition())
                target:Remove()
                target = flower
            end
        else
            return false, "NOLIFE"
        end
    elseif target.prefab == "mandrake" then --死掉的曼德拉草
        if pas.CalcuCost_sivmask2(mask, doer, 20) then
            local flower = SpawnPrefab("mandrake_planted")
            if flower ~= nil then
                flower.Transform:SetPosition(target.Transform:GetWorldPosition())
                flower:replant()
                if target.components.stackable ~= nil then
                    target.components.stackable:Get():Remove()
                else
                    target:Remove()
                end
                target = flower
            end
        else
            return false, "NOLIFE"
        end
    elseif target:HasTag("playerghost") then --玩家鬼魂
        if pas.CalcuCost_sivmask2(mask, doer, 120) then
            target:PushEvent("respawnfromghost", { source = mask, user = doer })
            target.components.health:DeltaPenalty(TUNING.REVIVE_HEALTH_PENALTY)
            target:DoTaskInTime(1, function()
                local healthcpt = target.components.health
                if healthcpt ~= nil and not healthcpt:IsDead() then
                    --旺达一样恢复10岁吧，因为她回血困难
                    healthcpt:SetVal(target.components.oldager == nil and 10 or 10/TUNING.OLDAGE_HEALTH_SCALE)
                    healthcpt:DoDelta(0, true, nil, true, nil, true)
                end
            end)
        else
            return false, "NOLIFE"
        end
    elseif target:HasTag("ghost") then --幽灵
        return false, "GHOST"
    elseif target.components.health ~= nil then --有生命组件的对象
        if not target.components.health:IsDead() and target.components.health:IsHurt() then
            if pas.CalcuCost_sivmask2(mask, doer, 20) then
                target.components.health:DoDelta(15, true, mask.prefab, true, nil, true)
            else
                return false, "NOLIFE"
            end
        else
            return false, "NOTHURT"
        end
    elseif target:HasTag("weed") then --杂草
        if target.components.growable ~= nil then
            local growable = target.components.growable
            if
                growable.stages and growable.stages[growable.stage] ~= nil and
                growable.stages[growable.stage].name == "bolting"
            then
                if pas.CalcuCost_sivmask2(mask, doer, 5) then
                    growable:SetStage(growable:GetStage() - 1) --回到上一个阶段
                    growable:StartGrowing()
                else
                    return false, "NOLIFE"
                end
            else
                return false, "NOWITHERED"
            end
        else
            return false, "NOWITHERED"
        end
    elseif target.components.farmplantstress ~= nil then --作物
        if
            target.components.growable ~= nil and
            target:HasTag("pickable_harvest_str") --这个标签代表作物腐烂了
        then
            if pas.CalcuCost_sivmask2(mask, doer, 5) then
                local growable = target.components.growable
                growable:SetStage(growable:GetStage() - 1) --回到上一个阶段
                growable:StartGrowing()
            else
                return false, "NOLIFE"
            end
        else
            return false, "NOWITHERED"
        end
    elseif target.components.perennialcrop ~= nil then --子圭垄植物
        local cpt = target.components.perennialcrop
        if cpt.isrotten then
            if pas.CalcuCost_sivmask2(mask, doer, 5) then
                cpt:StopGrowing() --恢复前清除生长进度
                cpt:SetStage(cpt.stage, cpt.ishuge, false)
            else
                return false, "NOLIFE"
            end
        else
            return false, "NOWITHERED"
        end
    elseif target.components.perennialcrop2 ~= nil then --异种植物
        local cpt = target.components.perennialcrop2
        if cpt.isrotten then
            if pas.CalcuCost_sivmask2(mask, doer, 5) then
                cpt:StopGrowing() --恢复前清除生长进度
                cpt:SetStage(cpt.stage, false)
            else
                return false, "NOLIFE"
            end
        else
            return false, "NOWITHERED"
        end
    elseif target.components.witherable ~= nil or target.components.pickable ~= nil then --普通植物
        if target.components.pickable ~= nil then
            if target.components.pickable:CanBeFertilized() then --贫瘠或缺水枯萎
                if pas.CalcuCost_sivmask2(mask, doer, 5) then
                    local poop = SpawnPrefab("poop")
                    if poop ~= nil then
                        target.components.pickable:Fertilize(poop, nil)
                        poop:Remove()
                    end
                else
                    return false, "NOLIFE"
                end
            else
                return false, "NOWITHERED"
            end
        else
            if target.components.witherable:CanRejuvenate() then --缺水枯萎
                if pas.CalcuCost_sivmask2(mask, doer, 5) then
                    target.components.witherable:Protect(TUNING.FIRESUPPRESSOR_PROTECTION_TIME)
                else
                    return false, "NOLIFE"
                end
            else
                return false, "NOWITHERED"
            end
        end
    end

    pas.SetLifeBendFx(target, doer)

    return true
end
pas.TriggerMode_sivmask2 = function(inst, owner, mode)
    pas.TaskOff_life(inst, owner)
    if mode ~= 3 then
        pas.StealHealth_sivmask(inst, owner, true, mode == 2)
    end
end
pas.SetMode_sivmask2 = function(inst, newmode, doer)
    if inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner then
        if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
            pas.TriggerMode_sivmask2(inst, inst.components.inventoryitem.owner, newmode)
            if doer ~= nil then
                if doer.SoundEmitter ~= nil then
                    doer.SoundEmitter:PlaySound("dontstarve/characters/wendy/small_ghost/howl", nil, 0.5)
                    doer.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, 0.3)
                end
                TOOLS_L.SendMouseInfoRPC(doer, inst, { mo = newmode }, true, false)
            end
        end
    end
end
pas.OnEquip_sivmask2 = function(inst, owner)
    pas.SetSymbols_sivmask(inst, owner)
    pas.TriggerMode_sivmask2(inst, owner, inst.components.modelegion.now)
    if owner:HasTag("equipmentmodel") then return end --假人
    inst:AddTag("cansetmode_l") --模式切换必需，没有就代表无法切换
    inst:ListenForEvent("onattackother", inst.OnAttackOther_l, owner)
    TOOLS_L.AddEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1, 0.5)
    -- TOOLS_L.AddTag(owner, "PreventSivFlower", inst.prefab)
end
pas.OnUnequip_sivmask2 = function(inst, owner)
    pas.ClearSymbols_sivmask(inst, owner)
    inst:RemoveTag("cansetmode_l")
    inst:RemoveEventCallback("onattackother", inst.OnAttackOther_l, owner)
    TOOLS_L.RemoveEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1)
    -- TOOLS_L.RemoveTag(owner, "PreventSivFlower", inst.prefab)
    pas.TaskOff_life(inst, owner)
end
pas.SetBonusOn_sivmask2 = function(inst)
	inst.bloodsteal_l = 5.5
    inst.healthcounter_max = 225
    inst.healpower_l = 3
end
pas.SetBonusOff_sivmask2 = function(inst)
	inst.bloodsteal_l = 4
    inst.healthcounter_max = 135
    inst.healpower_l = 2
end
pas.DealData_sivmask2 = function(inst, data)
    local dd = {
        v = tostring(data.v or 0),
        vmax = tostring(data.vmax or 135),
        st = tostring(data.st or 4),
        h = tostring(data.h or 2)
    }
    return subfmt(STRINGS.NAMEDETAIL_L.SIVMASK, dd).."\n"..(STRINGS.NAMEDETAIL_L.SIVEQUIP_MODE[data.mo or 3])
end
pas.GetData_sivmask2 = function(inst)
    local data = {}
    if inst.healthcounter > 0 then
        data.v = TOOLS_L.ODPoint(inst.healthcounter, 10) --变化大的数据记得省略小数点
    end
    if inst.healthcounter_max ~= 135 then
        data.vmax = inst.healthcounter_max
    end
    if inst.bloodsteal_l ~= 4 then
        data.st = inst.bloodsteal_l
    end
    if inst.healpower_l ~= 2 then
        data.h = inst.healpower_l
    end
    if inst.components.modelegion.now ~= 3 then
        data.mo = inst.components.modelegion.now
    end
    return data
end

table.insert(prefs, Prefab("siving_mask_gold", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "siving_mask_gold", nil, nil, nil)
    TOOLS_L.InitMouseInfo(inst, pas.DealData_sivmask2, pas.GetData_sivmask2)
    LS_C_Init(inst, "siving_mask_gold", false)

    -- inst:AddTag("open_top_hat")
    inst:AddTag("siv_mask2") --给特殊动作用
    inst:AddTag("modemystery_l")
    inst:AddTag("nobrokesg_l")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.healthcounter = 0
    -- inst.lifetarget = nil
    -- inst._broken = nil
    inst.bloodsteal_l = 4 --窃血值
    inst.healthcounter_max = 135 --积累上限
    inst.healpower_l = 2 --恢复力
    inst.OnCalcuCost_l = pas.CalcuCost_sivmask2
    inst.OnAttackOther_l = function(owner, data)
        pas.OnAttackOther_sivmask2(owner, data, inst)
    end

    fns.ServerFn(inst, "siving_mask_gold", pas.OnEquip_sivmask2, pas.OnUnequip_sivmask2)
    inst.components.inventoryitem:SetSinks(true) --它是石头做的，不可漂浮

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(735, 0.75)
    fns.SetKeepOnFinished(inst)
    inst.components.armor:SetOnFinished(pas.OnBroken_sivmask2)
    inst.components.armor.onrepair = pas.OnRepaired_sivmask2

    fns.SetBonus(inst, "SIVING2", pas.SetBonusOn_sivmask2, pas.SetBonusOff_sivmask2)

    inst:AddComponent("lifebender") --御血神通！然而并不
    inst.components.lifebender.fn_bend = pas.Bend_sivmask2

    inst:AddComponent("modelegion")
    inst.components.modelegion:Init(3, 3, nil, pas.SetMode_sivmask2)

    MakeHauntableLaunch(inst)

    inst.OnSave = pas.OnSave_sivmask
    inst.OnLoad = pas.OnLoad_sivmask

    return inst
end, fns.GetAssets("siving_mask_gold"), { "siving_lifesteal_fx", "life_trans_fx" }))

--------------------------------------------------------------------------
--[[ 语夜玫瑰 ]]
--------------------------------------------------------------------------

pas.OnHitOther_whisperose = function(owner, data) --攻击时会扣血
    local value = data.damageresolved or data.damage
    if value ~= nil and value > 0 and owner.legiontask_cost_whisperose == nil then --造成了伤害才行
        owner.legiontask_cost_whisperose = owner:DoTaskInTime(0, function()
            owner.legiontask_cost_whisperose = nil
            if owner.components.health ~= nil and not owner.components.health:IsDead() then
                if owner:HasTag("genesis_nyx") then
                    if owner.components.health:IsHurt() then
                        owner.components.health:DoDelta(1, nil, "hat_whisperose")
                    end
                else
                    owner.components.health:DoDelta(-1, true, "hat_whisperose")
                end
            end
        end)
    end
end
pas.OnAttackOther_whisperose = function(owner, data)
    if owner.legion_whisperose == 2 then
        TOOLS_L.UndefendedATK(owner, data)
    end
end
pas.DarkSet_whisperose = function(inst, phase)
    local state
    if phase == nil then
        if TheWorld.state.isnight then
            state = 2
        elseif TheWorld.state.isdusk then
            state = 1
        end
    elseif phase == "night" then
        state = 2
    elseif phase == "dusk" then
        state = 1
    end
    local owner = inst._owner_l
    if owner == nil then
        return
    elseif owner.components.combat == nil then
        owner.legion_whisperose = nil
        return
    end
    owner.legion_whisperose = state
    if state == 2 then
        owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.5)
    elseif state == 1 then
        owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.3)
    else
        owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
    end
end
pas.OnEquip_whisperose = function(inst, owner)
    TOOLS_L.hat_on_opentop(owner, "hat_whisperose", "swap_hat")
    owner.AnimState:SetSymbolLightOverride("swap_hat", 0.2)
    if owner:HasTag("equipmentmodel") then return end --假人
    inst._owner_l = owner
    inst:WatchWorldState("phase", pas.DarkSet_whisperose)
    owner:ListenForEvent("onhitother", pas.OnHitOther_whisperose)
    owner:ListenForEvent("onattackother", pas.OnAttackOther_whisperose)
    pas.DarkSet_whisperose(inst, nil)
end
pas.OnUnequip_whisperose = function(inst, owner)
    TOOLS_L.hat_off(inst, owner)
    owner.AnimState:SetSymbolLightOverride("swap_hat", 0)
    if owner:HasTag("equipmentmodel") then return end --假人
    inst:StopWatchingWorldState("phase", pas.DarkSet_whisperose)
    owner:RemoveEventCallback("onhitother", pas.OnHitOther_whisperose)
    owner:RemoveEventCallback("onattackother", pas.OnAttackOther_whisperose)
    pas.DarkSet_whisperose(inst, "day")
    inst._owner_l = nil
end

table.insert(prefs, Prefab("hat_whisperose", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "hat_whisperose", nil, nil, nil)
    fns.SetFloatable(inst, { 0.05, "small", 0.3, 1 })
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
    inst:AddTag("nyx_palace_opener") --【创世纪】可无消耗进入倪克斯的宫殿

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.legiontag_pinebelonger = true --在云青松里能无限保鲜

    fns.ServerFn(inst, "hat_whisperose", pas.OnEquip_whisperose, pas.OnUnequip_whisperose)
    fns.SetPerishable(inst, TUNING.PERISH_ONE_DAY*8, "nightmarefuel", nil)

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("hat_whisperose"), nil))

--------------------
--------------------

return unpack(prefs)
