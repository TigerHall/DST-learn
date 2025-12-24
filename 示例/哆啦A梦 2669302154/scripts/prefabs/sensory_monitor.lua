--------------------------------
--[[ 感觉监视器]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-25]]
--[[ @updateTime: 2021-12-25]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Logger = require("util/logger")
local ScreenUtil = require("util/screen_util")
local SensoryMonitorFn = require("function/sensory_monitor_fn")
local Table =  require("util/table")
local assets =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB..".tex"),
}
local assets_item =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB..".tex"),
}
-- 不知道什么用,抄饥荒portablecookpot.lua
local prefabs =
{
    "collapse_small",
    "ash",
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB,
}
-- 不知道什么用,抄饥荒portablecookpot.lua
local prefabs_item =
{
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB,
}

-- 被删除
local function OnRemove(inst)
    -- 这里增加了严格判断是否在服务器(以兼容Burning Timer客户端mod,详见sensory_monitor_camera.prefab)
    -- 如果有正在使用的人
    if TheWorld.ismastersim  and TheWorld.net and TheWorld.net.components.doraemon_sensory_monitor then
        if inst._sensory_monitor_users then
            for _,v in pairs(inst._sensory_monitor_users) do
                if v:IsValid() then
                    SensoryMonitorFn:Exit(v)
                else
                    Table:RemoveValue(inst._sensory_monitor_users,v)
                end
            end
        end
    end

end

-- 更换成物品
local function ChangeToItem(inst)
    local item = SpawnPrefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB, inst.linked_skinname, inst.skin_id)
    item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    item.AnimState:PlayAnimation("collapse")
    item.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
end

-- 被锤
local function onhammered(inst)--, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst:HasTag("burnt") then
        inst.components.lootdropper:SpawnLootPrefab("ash")
        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("metal")
    else
        ChangeToItem(inst)
    end
    inst:Remove()
end
-- 被攻击
local function onhit(inst)--, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
        OnRemove(inst)
    end
end
-- 使用
local function onuse(act)
    SensoryMonitorFn:Onuse(act)
end

-- 燃尽
local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)
    RemovePhysicsColliders(inst)
    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    if inst.components.workable ~= nil then
        inst:RemoveComponent("workable")
    end
    if inst.components.portablestructure ~= nil then
        inst:RemoveComponent("portablestructure")
    end
    inst.persists = false
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:ListenForEvent("animover", ErodeAway)
    inst.AnimState:PlayAnimation("burnt_collapse")
    OnRemove(inst)
end


-- 保存着火
local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end
-- 加载着火
local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

-- 建筑构造方法
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    --碰撞体积
    inst:SetPhysicsRadiusOverride(.5)
    MakeObstaclePhysics(inst,inst.physicsradiusoverride)

    inst.MiniMapEntity:SetIcon(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB..".tex")
    inst.MiniMapEntity:SetPriority(1)
    inst:AddTag("structure")
    inst.Light:Enable(true)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235/255,62/255,12/255)

    inst.DynamicShadow:SetSize(2, 1)

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB)
    inst.AnimState:PlayAnimation("idle")

    inst:SetPrefabNameOverride(TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB)

    inst:AddComponent("doraemon_click_scene")
    inst.components.doraemon_click_scene.type = "LOOK"
    inst.components.doraemon_click_scene.deststate = "give"
    inst.components.doraemon_click_scene.canuse =function(inst, doer, actions, right)
        -- 左键 且无其它特殊窗口
        if not right and ScreenUtil:IsHudFront() then
            -- 没有人使用 且没烧焦
            -- 用户不是飞行或骑行状态
            if doer.replica.rider ~= nil and doer.replica.rider:IsRiding() then
                return false
            end
            -- busy用来判断是否有人使用，暂未未做限制，目前一个监视器可以多个人使用
            return  not inst:HasTag("busy") and not inst:HasTag("burnt")
        end
        return false
    end
    inst.components.doraemon_click_scene.onuse = onuse
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------
    -- 标识正在使用的用户
    inst._sensory_monitor_users = {}
    -- 便携
    inst:AddComponent("portablestructure")
    inst.components.portablestructure:SetOnDismantleFn(function (inst) -- 收回
        ChangeToItem(inst)
        inst:Remove()
    end)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst) -- 状态,不同状态给予不同描述
        return inst:HasTag("burnt") and "BURNT" or "GENERIC"
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"transistor","gears"}) -- 损失一个电子元件
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    MakeMediumBurnable(inst, nil, nil, true) -- 着火
    MakeSmallPropagator(inst) -- 传火
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst:ListenForEvent("onremove",OnRemove)
    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

-- 物品部署->建筑
local function ondeploy(inst, pt, deployer)
    local pot = SpawnPrefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB, inst.linked_skinname, inst.skin_id )
    if pot ~= nil then
        pot.Physics:SetCollides(false)
        pot.Physics:Teleport(pt.x, 0, pt.z)
        pot.Physics:SetCollides(true)
        pot.AnimState:PlayAnimation("place")
        pot.AnimState:PushAnimation("idle", false)
        pot.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
        inst:Remove()
        PreventCharacterCollisionsWithPlacedObjects(pot)
    end
end

-- 物品构造方法
local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB)
    inst.AnimState:PlayAnimation("item_idle")

    inst:AddTag("portableitem")

    MakeInventoryFloatable(inst, "med", 0.1, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB..".xml"

    inst:AddComponent("deployable")

    inst.components.deployable.ondeploy = ondeploy
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    --inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return  Prefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB, fn, assets,prefabs),
        MakePlacer(TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB.."_placer", TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB, TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB, "idle"),
        Prefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB, itemfn, assets_item, prefabs_item)