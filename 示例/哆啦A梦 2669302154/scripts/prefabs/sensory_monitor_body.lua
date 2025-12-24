--------------------------------
--[[ 感觉监视器使用时产生的身体]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-29]]
--[[ @updateTime: 2022-03-08]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Table = require("util/table")

--local brain = require("brains/empty_brain")
local SensoryMonitorFn = require "function/sensory_monitor_fn"
local InventoryUtil =  require("util/inventory_util")
local assets =
{

}

local prefabs =
{

}
local function onIcon(inst)
    local prefab = inst._mapicon:value()
    inst:SetPrefabNameOverride(prefab)
    inst.MiniMapEntity:SetIcon(prefab..".png")
end



-- 设置所有者
local function setOwner(inst,owner)
    inst._owner = owner
    inst.components.health.maxhealth = owner.components.health.maxhealth
    inst.components.health:SetCurrentHealth(owner.components.health.currenthealth)
    inst.components.health:DoDelta(0)
    -- 如果是人物，则返回人物prefab，人物皮肤不像物品皮肤（物品皮肤是根据build）
    local build = Table:HasValue(DST_CHARACTERLIST,owner.prefab) and owner.prefab or owner.AnimState:GetBuild()
    --local build = owner.AnimState:GetBuild()

    inst.AnimState:SetBuild(build)
    inst.MiniMapEntity:SetIcon(build..".png")
    inst.name = owner.Network:GetClientName()
    inst.playercolour = owner.Network:GetPlayerColour()
    inst._mapicon:set(build)
    -- 同步皮肤，摆，皮肤同步不会。 TODO
    local skinner = inst.components.skinner
    local clothings = owner.components.skinner:GetClothing()
    Logger:Debug({"owner皮肤相关",prefab = owner.prefab ,build = build,AnimStateGetBuild = owner.AnimState:GetBuild() , clothings = clothings })
    -- 第一种尝试 结果：不止皮肤没同步，本应该显示人物warly，但实际是wilson
    --for k,v in pairs(clothings) do
    --    if k ~= "base" then
    --        skinner:SetClothing(v)
    --    else
    --        skinner:SetSkinName(v)
    --    end
    --end
    --skinner:SetSkinMode("normal_skin")
    -- 第二种尝试 结果：皮肤未同步。如果是付费人物（老奶奶），人物也会是wilson
    --SetSkinsOnAnim(inst.AnimState,inst.prefab,owner.AnimState:GetBuild(),clothings,"normal_skin",build)
    -- 转移装备栏
    InventoryUtil:TransferInventory(owner,inst)
    -- 先转移掉装备，再隐藏用户（移除用户碰撞，删除跟从者等）
    if owner.components.leader and inst.components.leader then
        for k,v in pairs(owner.components.leader.followers) do
            owner.components.leader:RemoveFollower(k)
            inst.components.leader:AddFollower(k)
        end
    end
end

local function removeOwner(inst)
    if inst._owner ~= nil then
        -- 还原装备栏
        InventoryUtil:TransferInventory(inst, inst._owner)
        if inst.components.leader and inst._owner.components.leader then
            for k,v in pairs(inst.components.leader.followers) do
                inst.components.leader:RemoveFollower(k)
                inst._owner.components.leader:AddFollower(k)
            end
        end
    end
end

-- 退出监视
local function exit(inst,data)
    -- 存在owner,且正在监视,退出监视
    if inst._owner ~= nil
            and inst._owner:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)
    then
        SensoryMonitorFn:Exit(inst._owner)
    end
end


-- 被攻击
local function onAttacked(inst, data)
    exit(inst, data)
end
-- 被传送
local function onTeleported(inst, data)
    exit(inst, data)
end
-- 被删除
local function onRemove(inst, data)
    if not inst._no_exit then
        exit(inst, data)
    end
end

-- 死亡
local function onDeath(inst)
    -- 存在owner,且正在监视,退出监视
    if inst._owner ~= nil
            and inst._owner:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)
    then
        SensoryMonitorFn:Exit(inst._owner)
    end
end


local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize(1.3, .6)
    -- 选择设置重量为0的方法,这样人物不会一碰就滑
    -- MakeCharacterPhysics设置后,根据群友回答,需要再设置一个脑子
    MakeObstaclePhysics(inst, .3)
    --MakeCharacterPhysics(inst, 75, .5)

    inst.Transform:SetFourFaced(inst)

    -- 需要设置正确的地图图标，人物的地图图标需要进行隐藏，如果没有对应方法，使用透明图片
    local prefabOverride = "wilson"
    inst:SetPrefabNameOverride(prefabOverride)
    inst.MiniMapEntity:SetPriority(10)
    inst.MiniMapEntity:SetCanUseCache(true)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetIcon(prefabOverride..".png")
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle")
    -- 注释掉这个tag，因为有这个tag 会被AddPlayerPostInit识别
    --inst:AddTag("player")
    -- 以下tag照抄神话脱壳符
    inst:AddTag("handfed")
    inst:AddTag("fedbyall")
    inst:AddTag("companion")
    inst:AddTag("character")

    inst._mapicon = net_string(inst.GUID, TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB..".icon", TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB..".icondirty")
    inst._mapicon:set(prefabOverride)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent(TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB..".icondirty", onIcon)
        return inst
    end

    inst.persists = false

    -- 隐藏第三只手
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Show("ARM_normal")

    inst:AddComponent("inspectable")
    inst:AddComponent("skinner")

    inst:AddComponent("lootdropper")

    inst:AddComponent("health")

    inst:AddComponent("combat")

    inst:AddComponent("leader")

    inst:AddComponent("inventory")
    --players handle inventory dropping manually in their stategraph
    inst.components.inventory:DisableDropOnDeath()

    -- 永久保鲜
    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(function(inst, item)
        return (item ~= nil) and 0 or nil
    end)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst:SetStateGraph("SGsensory_monitor_body")

    inst.setOwner = setOwner
    inst.removeOwner = removeOwner

    inst:ListenForEvent("attacked", onAttacked)
    inst:ListenForEvent("death",inst.my_death)
    inst:ListenForEvent("teleported",onTeleported)
    inst:ListenForEvent("onremove",onRemove)
    -- 需要增加装备栏，用于同步装备栏
    return inst
end

return Prefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB, fn, assets, prefabs)


