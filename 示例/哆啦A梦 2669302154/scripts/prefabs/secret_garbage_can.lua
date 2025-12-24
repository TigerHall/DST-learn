--------------------------------
--[[ 秘密垃圾桶,该prefab参考了自动分拣机mod,特此感谢]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-03-14]]
--[[ @updateTime: 2022-03-14]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local assets =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".zip"),
    Asset("ANIM", "anim/ui_largechest_5x5.zip"), -- 自动分拣机资源
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".tex"),
}
local prefabs =
{
    "collapse_small",
    "sand_puff",
    "sand_puff_large_front",
    "gift",
}
-- 建造成功
local function onBuilt(inst)

end

local function onhit(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", false)
    if inst.components.container then -- 有人在打,快来看看
        inst.components.container:Close()
    end
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()

    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end
--[[显示销毁特殊物品的范围]]
local function enableRing(inst, enabled)
    if enabled then
        if inst.destroy_helper == nil then
            inst.destroy_helper = CreateEntity()
            --inst.destroy_helper.entity:AddNetwork()
            inst.destroy_helper.entity:SetCanSleep(false)

            inst.destroy_helper.entity:AddTransform()
            inst.destroy_helper.entity:AddAnimState()
            inst.destroy_helper.persists = false

            inst.destroy_helper:AddTag("CLASSIFIED")
            inst.destroy_helper:AddTag("NOCLICK")
            inst.destroy_helper:AddTag("placer")
            -- 雪球机 PLACER_SCALE = 1.55 ,距离是15
            --local scale =  0.104 * math.ceil(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_RANGE)
            local scale =  0.7
            inst.destroy_helper.Transform:SetScale(scale, scale, scale)

            inst.destroy_helper.AnimState:SetBank("firefighter_placement")
            inst.destroy_helper.AnimState:SetBuild("firefighter_placement")
            inst.destroy_helper.AnimState:PlayAnimation("idle")
            inst.destroy_helper.AnimState:SetLightOverride(1)
            inst.destroy_helper.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.destroy_helper.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.destroy_helper.AnimState:SetSortOrder(1)
            inst.destroy_helper.AnimState:SetAddColour(0, .2, .5, 0)
            --220,20,60
            --inst.destroy_helper.AnimState:SetMultColour(255/255,255/255,255/255,1)

            inst.destroy_helper.entity:SetParent(inst.entity)
        end
    elseif inst.destroy_helper ~= nil then
        inst.destroy_helper:Remove()
        inst.destroy_helper = nil
    end
end


local function onopen(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("idle", false)
    if inst.ring_show then
        inst.ring_show:set(true)
    end
end
local function onclose(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("idle", false)
    if inst.ring_show then
        inst.ring_show:set(false)
    end
end

local function onRingShowDirty(inst)
    enableRing(inst,inst.ring_show:value())
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".tex")
    inst.MiniMapEntity:SetPriority(1)

    --MakeObstaclePhysics(inst, 1.5)
    inst:AddTag("structure")
    inst:AddTag("chest")
    -- 用于兼容loot pump mod , 添加此tag,不会被该mod识别,自动放入物品
    -- inst:AddTag("decor") -- 去除这块限制,有人愿意当做仓库就当仓库吧

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB)
    inst.AnimState:PlayAnimation("place")
    if TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_BACKPACK or TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_HEAVY then
        inst.ring_show = net_bool(inst.GUID, TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB..".ring_show", TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB.."._ring_showdirty")
        inst.ring_show:set(false)
    end

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        if inst.ring_show then
            inst:ListenForEvent(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB.."._ring_showdirty", function()
                onRingShowDirty(inst)
            end)
        end
        return inst
    end

    inst:AddComponent("inspectable")
    -- 销毁和奖励组件
    inst:AddComponent("doraemon_secret_garbage_can")


    inst:AddComponent("container")
    inst.components.container:WidgetSetup(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB)
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose


    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    MakeSnowCovered(inst)
    MakeMediumPropagator(inst)

    inst.Transform:SetScale(0.8, 0.8, 0.8)
    inst:ListenForEvent("onbuilt", onBuilt)
    --inst.OnSave = onsave
    --inst.OnLoad = onload
    return inst
end
--function MakePlacer(name, bank, build, anim, onground, snap, metersnap, scale, fixedcameraoffset, facing, postinit_fn, offset, onfailedplacement)
return Prefab(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB, fn, assets,prefabs),
MakePlacer(TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB.."_placer", TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB, TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB, "idle")