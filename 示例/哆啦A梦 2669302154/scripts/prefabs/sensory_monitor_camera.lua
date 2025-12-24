--------------------------------
--[[ 感觉监视器摄像头]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-03-06]]
--[[ @updateTime: 2022-03-06]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Logger = require("util/logger")
local Table =  require("util/table")
local SensoryMonitorFn = require("function/sensory_monitor_fn")
local assets =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB..".tex"),
}
local assets_item =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB..".tex"),
}
-- 不知道什么用,抄饥荒portablecookpot.lua
local prefabs =
{
    "collapse_small",
    "ash",
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB,
}
-- 不知道什么用,抄饥荒portablecookpot.lua
local prefabs_item =
{
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB,
}
-- 是否生效
local function enable(inst,enable)
    -- 保险起见不光判断TheWorld.ismastersim,还判断net对应组件doraemon_sensory_monitor是否存在
    -- 比如:Burning Timer这个客户端mod,截取部分代码如下,如果只判断TheWorld.ismastersim会有问题
--[[
--  local inst
--	local IsMasterSim = _G.TheWorld.ismastersim
--	_G.TheWorld.ismastersim = true -- Your ingame data has just been corrupted
--  ....
--	inst = _G.SpawnPrefab(prefab)
--	if inst and inst.components.burnable and inst.components.burnable.burntime then
--		burntimeList[prefab] = inst.components.burnable.burntime
--	else
--		burntimeList[prefab] = false
--	end
--	inst:Remove()
]]
    if TheWorld.ismastersim   and TheWorld.net and TheWorld.net.components.doraemon_sensory_monitor then
        if enable then
            -- 记录到全局表
            if not Table:HasValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS,inst) then
                table.insert(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS,inst)
            end
            -- 更新
            TheWorld.net.components.doraemon_sensory_monitor:UpdateCameras()
        else
            -- 删除之前应该将所有监视的用户退到自己
            for _,player in pairs(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[inst]) do
                if TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[player] == inst and player:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then
                    SensoryMonitorFn:BackToSelf(player)
                else
                    Table:RemoveValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[inst],player)
                end
            end
            -- 从全局表中删除
            Table:RemoveValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS,inst)
            Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS,inst)
            -- 更新
            TheWorld.net.components.doraemon_sensory_monitor:UpdateCameras()
        end
    else -- 说明是客户端,该inst生成后垃圾数据也清除下
        -- 从全局表中删除
        Table:RemoveValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS,inst)
        Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS,inst)
    end
end
-- 被删除
local function OnRemove(inst)
    enable(inst,false)
end


-- 建造成功
local function onBuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
    enable(inst,true)
end
-- 写完也调用下enable,以更新摄像头文字
local function onWritten(inst, text, doer)
    enable(inst,true)
end

-- 更换成物品
local function ChangeToItem(inst)
    local item = SpawnPrefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB, inst.linked_skinname, inst.skin_id)
    item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    -- 没有这个动画
    --item.AnimState:PlayAnimation("collapse")
    --item.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
end

-- 被锤
local function onhammered(inst)--, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst:HasTag("burnt") then
        inst.components.lootdropper:SpawnLootPrefab("ash")
    else
        inst.components.lootdropper:DropLoot()
        --ChangeToItem(inst)
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end
-- 被攻击
local function onhit(inst)--, worker)
    if not inst:HasTag("burnt") then
        --inst.AnimState:PlayAnimation("hit")
        --inst.AnimState:PushAnimation("idle", false)
    end
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
    -- 无这个动画
    --inst.AnimState:PlayAnimation("burnt_collapse")
    OnRemove(inst)
end


-- 保存着火
local function onSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    if inst._owner ~= nil then -- 保存拥有者
        data._owner = inst._owner
    end
end
-- 加载着火
local function onLoad(inst, data)
    if data and data._owner ~= nil then -- 加载拥有者信息
        inst._owner = data._owner
    end
    if data and  data.burnt and inst.components.burnable then
        inst.components.burnable.onburnt(inst)
    else -- 有效的实体(不是烧焦的)加入到全局表中
        enable(inst,true) -- 这里
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

    inst.MiniMapEntity:SetIcon(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB..".tex")
    inst.MiniMapEntity:SetPriority(1)
    inst:AddTag("structure")

    inst.Light:Enable(true)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235/255,62/255,12/255)

    inst.DynamicShadow:SetSize(2, 1)

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB)
    inst.AnimState:PlayAnimation("idle")

    inst:SetPrefabNameOverride(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB)

    --Sneak these into pristine state for optimization
    inst:AddTag("_writeable")
    MakeSnowCoveredPristine(inst)
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------
    -- 初始化FOLLOWERS
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[inst] = {}

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_writeable")

    inst:AddComponent("inspectable")
    inst:AddComponent("writeable")
    inst.components.writeable:SetOnWrittenFn(onWritten)


    inst.components.inspectable.getstatus = function(inst) -- 状态,不同状态给予不同描述
        return inst:HasTag("burnt") and "BURNT" or "GENERIC"
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"transistor"}) -- 被锤掉一个电气元件,损失一个木板

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    -- 着火动画没做
    MakeMediumBurnable(inst, nil, nil, true) -- 着火
    MakeSmallPropagator(inst) -- 传火
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    MakeSnowCovered(inst)

    inst:ListenForEvent("onremove",OnRemove)
    inst.OnSave = onSave
    inst.OnLoad = onLoad

    MakeHauntableWork(inst)
    inst:ListenForEvent("onbuilt", onBuilt)
    return inst
end

-- 物品部署->建筑
local function ondeploy(inst, pt, deployer)
    local pot = SpawnPrefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB, inst.linked_skinname, inst.skin_id )
    if pot ~= nil then
        pot.Physics:SetCollides(false)
        pot.Physics:Teleport(pt.x, 0, pt.z)
        pot.Physics:SetCollides(true)
        -- 无place动画
        --pot.AnimState:PlayAnimation("place")
        pot.AnimState:PushAnimation("idle",false)
        --pot.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
        -- 传递拥有者
        pot._owner = inst.components.inventoryitem.owner
        inst:Remove()
        PreventCharacterCollisionsWithPlacedObjects(pot)
        -- 这个方法似乎不会触发onBuilt事件,手动触发下
        onBuilt(pot)
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

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB)
    inst.AnimState:PlayAnimation("item_idle")

    inst:AddTag("portableitem")

    MakeInventoryFloatable(inst, "med", 0.1, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB..".xml"

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

return  Prefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB, fn, assets,prefabs),
        MakePlacer(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB.."_placer", TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB, TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB, "idle"),
        Prefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB, itemfn, assets_item, prefabs_item)