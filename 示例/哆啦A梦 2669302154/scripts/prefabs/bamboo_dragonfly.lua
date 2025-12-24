--------------------------------
--[[ 竹蜻蜓]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-10-28]]
--[[ @updateTime: 2021-12-05]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("constants")
require("util/logger")
local assets =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB..".zip"),--动画
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB..".tex"),
    Asset("SOUND", "sound/common.fsb"),--旋风扇声音
}

local prefab = TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB --prefab名称





local function takeEffect(inst,data)
    if data.enable then
        if data.sound then
            inst.SoundEmitter:KillSound("doraemon_fly_sound")
            inst.SoundEmitter:PlaySound("dontstarve/common/fan_twirl_LP", "doraemon_fly_sound")
        end
        inst.components.insulator:SetInsulation(TUNING.INSULATION_MED_LARGE)
        inst.components.heater:SetThermics(false, true)
    else
        if data.sound then
            inst.SoundEmitter:KillSound("doraemon_fly_sound")
        end
        inst.components.insulator:SetInsulation(0)
        inst.components.heater:SetThermics(false, false)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", prefab, "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    --这里其实跟装备是一样的 唯一的区别是这个不会隐藏head 这样适用于花环之类的不会遮住头发的帽子
    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAIR")
    inst._owner = owner
    if owner:HasTag("player") then
        -- 使用扩展的判断是否飞行方法 ,避免和其它mod冲突
        owner:AddTag(TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB)
        -- 如果在飞
        if owner.components.doraemon_fly and owner.components.doraemon_fly:IsFlying() then
            takeEffect(inst,{enable = true ,sound =true})
        else
            takeEffect(inst,{enable = false ,sound =false})
        end
    else --禁用
        takeEffect(inst,{enable = false ,sound =false})
    end
end


local function onunequip(inst, owner)
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner:RemoveTag(TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB)
    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end
    takeEffect(inst,{enable = true ,sound =false})
    if inst._owner ~= nil then
        inst._owner = nil
    end
end

--local function ondepleted(inst)
--    --如果在起飞 需要着落
--    if inst._owner ~= nil  and inst._owner.components.doraemon_fly and inst._owner.components.doraemon_fly:IsFlying()then
--        inst._owner.sg:GoToState("doraemon_flyskill_down")
--    end
--    if inst.components.inventoryitem ~= nil and inst.components.inventoryitem:IsHeld() then
--        inst.components.inventoryitem.owner:PushEvent("itemranout", {
--            prefab = inst.prefab,
--            equipslot = inst.components.equippable.equipslot,
--            announce = "ANNOUNCE_FAN_OUT",
--        })
--    end
--    inst:Remove()
--end


local function OnTakeFuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
end
local function onfuelchanged_yellow(inst, data)
    if data and data.percent and data.oldpercent and data.percent > data.oldpercent then
        inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
    end
end
local function getEquippedBambooDragonfly(owner)
    local bamboo_dragonfly_equipped = nil
    for _,tempItem in pairs(owner.replica.inventory:GetEquips()) do
        if tempItem ~= nil and tempItem.prefab == "bamboo_dragonfly"then
            bamboo_dragonfly_equipped = tempItem
            break
        end
    end
    return bamboo_dragonfly_equipped
end

-- 是否能右键
local function can_use_in_inventory(inst, doer, actions, right)
    if doer.components.doraemon_fly:IsFlying()then--起飞中
        --着陆条件
        return false
    else
        --起飞条件 对着装备栏使用 玩家未死亡 冷却已完成
        local equippedBambooDragonfly =  getEquippedBambooDragonfly(doer)
        return equippedBambooDragonfly ~= nil and inst == equippedBambooDragonfly and not doer:HasTag("playerghost")
            and not doer.components.doraemon_fly:IsFlyingBesidesOtherMod()
            and inst.components.doraemon_click_inventory._ischarged:value()
    end
end

-- 是否能右键
local function can_use_in_scene(inst, doer, actions, right)
    if doer.components.doraemon_fly:IsFlying()then--起飞中
        --着陆条件 点的自己 且未死亡
        return inst == doer and not doer:HasTag("playerghost")
    else
        --起飞条件 点的自己 已装备竹蜻蜓 玩家未死亡 冷却已完成
        local equippedBambooDragonfly =  getEquippedBambooDragonfly(doer)
        return inst == doer  and not doer:HasTag("playerghost")
                and not doer.components.doraemon_fly:IsFlyingBesidesOtherMod()
                and equippedBambooDragonfly ~= nil and equippedBambooDragonfly.components.doraemon_click_scene._ischarged:value()
    end
end


local function onChargedFn(inst)
    inst.components.doraemon_click_scene._ischarged:set(true)
    inst.components.doraemon_click_inventory._ischarged:set(true)
end
local function onDischargedFn(inst)
    inst.components.doraemon_click_scene._ischarged:set(false)
    inst.components.doraemon_click_inventory._ischarged:set(false)
end
-- 飞行
local function onuse(act)
    -- 骑乘状态
    if act.doer.replica.rider ~= nil and act.doer.replica.rider:IsRiding() then
        return false
    end
    -- 如果饱食度大于规定值才能起飞
    if act.doer.components.hunger and act.doer.replica.hunger:GetCurrent() >= TUNING.DORAEMON_TECH.DORAEMON_FLY_OFF_MIN_HUNGER then
        act.doer.components.doraemon_fly:SetFlying(true)
        return true
    else
        return false
    end
end

local function fn()
    local inst = CreateEntity()
    --- 基本代码
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab)
    inst.AnimState:SetBuild(prefab)
    -- 和官方hat保持一致
    inst.AnimState:PlayAnimation("anim")
    inst:AddTag("hat")
    inst:AddTag("hide")

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    -- 右键
    inst:AddComponent("doraemon_click_inventory")
    inst.components.doraemon_click_inventory.canuse = can_use_in_inventory
    inst.components.doraemon_click_inventory.onuse = onuse
    inst.components.doraemon_click_inventory.type = "FLY_OFF"
    inst.components.doraemon_click_inventory.deststate= "doraemon_flyskill_up"
    inst:AddComponent("doraemon_click_scene")
    inst.components.doraemon_click_scene.canuse = can_use_in_scene

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -- 冷却
    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(onChargedFn)
    inst.components.rechargeable:SetOnDischargedFn(onDischargedFn)
    --可检查和可放入物品栏
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab..".xml"

    --可装备
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    ---------------以下需要参考旋风扇,羊角帽
    --加热 目标温度
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.equippedheat = TUNING.DORAEMON_TECH.DORAEMON_FLY_COOLER

    --耐久度
    --inst:AddComponent("fueled")
    --旋风扇:3 * seg, 竹蜻蜓: 乘以2,即 6 * seg ,  打算需要2个梦魇燃料补满
    --inst.components.fueled:InitializeFuelLevel(TUNING.MINIFAN_FUEL*2)--
    --inst.components.fueled:SetDepletedFn(ondepleted)
    --inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    --inst.components.fueled.accepting = true
    --inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE--梦魇燃料增加时间:seg_time * 6,
    --inst.components.fueled.bonusmult = 3/6 -- 100%需要4个噩梦燃料,所以一次应该是  seg_time*4 = bonusmult * seg_time * 6
    --
    --
    --
    --inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
    --inst:ListenForEvent("percentusedchange", onfuelchanged_yellow)

    -- 隔热
    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_MED_LARGE)
    inst.components.insulator:SetSummer()
    takeEffect(inst,{enable = true ,sound =false})
    inst:ListenForEvent("takeEffect", takeEffect)
    inst:AddComponent("tradable") --可交易组件  有了这个就可以给猪猪

    MakeHauntableLaunchAndPerish(inst) --作祟相关


    return inst
end



return  Prefab(prefab, fn, assets)