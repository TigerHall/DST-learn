local FACTORY_CHEST_LIST = require("hmrmain/hmr_lists").FACTORY_CHEST_LIST

local assets =
{
    Asset("ANIM", "anim/hmr_chest_factory_core.zip"),
}

--------------------------------------------------------------------------
--[[灵枢织造箱核心]]
--------------------------------------------------------------------------
local function OnDismantle(inst, doer)
    local item = SpawnPrefab("hmr_chest_factory_core_item")
    if item ~= nil then
        local storage = inst.components.entitytracker:GetEntity("storage")
        if storage then
            item.components.entitytracker:TrackEntity("storage", storage)
        end

        if inst.components.hmrfactory ~= nil then
            inst.components.hmrfactory:CollectAllTempStorage(doer)
        end

        inst.AnimState:PlayAnimation("pack")
        local time = inst.AnimState:GetCurrentAnimationLength() - inst.AnimState:GetCurrentAnimationTime() + FRAMES
        inst:DoTaskInTime(time, function()
            if doer ~= nil and doer.components.inventory ~= nil then
                doer.components.inventory:GiveItem(item, nil, inst:GetPosition())
                if doer.SoundEmitter ~= nil then
                    doer.SoundEmitter:PlaySound("dontstarve/common/together/succulent_craft")
                end
            else
                item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst:Remove()
        end)
    end
end

local function OnProduce(inst)
    inst.AnimState:PlayAnimation("beam")
    if inst.components.hmrfactory:IsProducing() then
        inst.AnimState:PushAnimation("locating", true)
    else
        inst.AnimState:PushAnimation("idle_loop", true)
    end
end

local function OnCollectTempStorage(inst)
    if inst.components.hmrfactory:IsProducing() then
        inst.AnimState:PushAnimation("locating", true)
    else
        inst.AnimState:PushAnimation("idle_loop", true)
    end
end

local function FindNewStorage(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local chests = TheSim:FindEntities(x, y, z, TUNING.HMR_CHEST_FACTORY_RELATE_DIST, {"hmr_chest_factory"})
    if chests ~= nil and #chests > 0 then
        table.sort(chests, function(a, b)
            return a:GetDistanceSqToInst(inst) < b:GetDistanceSqToInst(inst)
        end)
        return chests[1]
    end
end

local function SetStorage(inst, new_storage)
    local storage = new_storage or inst.components.entitytracker:GetEntity("storage")
    if storage == nil then
        storage = FindNewStorage(inst)
    end
    if storage and storage:IsValid() then
        inst.components.hmrfactory:SetStorage(storage)
        local x, y, z = storage.Transform:GetWorldPosition()
        inst:ForceFacePoint(x, y, z)

        inst.components.entitytracker:TrackEntity("storage", storage)
    end
end

local function GetTypeAndNum(prefab)
    local infos = {}
    for type, info in pairs(FACTORY_CHEST_LIST) do
        for member, num in pairs(info.members) do
            if member == prefab then
                table.insert(infos, {type = type, num = num})
                break
            end
        end
    end
    return #infos > 0 and infos or nil
end

local function GetFactoryType(inst)
    local items = inst.components.hmrroom:CollectItemsInRoom()
    if items ~= nil and #items > 0 then
        -- 记录每一类的成员总加权数量
        local classes = {}
        for _, ent in pairs(items) do
            local infos = GetTypeAndNum(ent.prefab)
            if infos and #infos > 0 then
                for _, info in pairs(infos) do
                    classes[info.type] = (classes[info.type] or 0) + info.num
                end
            end
        end

        -- 确定房间类型
        local highest_priority = 0
        local highest_priority_type = nil
        for type, num in pairs(classes) do
            if FACTORY_CHEST_LIST[type].priority > highest_priority then
                highest_priority = FACTORY_CHEST_LIST[type].priority
                highest_priority_type = type
            end
        end

        -- 返回房间类型和总加权数量
        return highest_priority_type, classes[highest_priority_type]
    end
end

local function OnEnterRoom(inst, areas)
    local type, num = GetFactoryType(inst)
    if type ~= nil then
        local product = FACTORY_CHEST_LIST[type] and FACTORY_CHEST_LIST[type].products
        inst.components.hmrfactory:SetProduct(product)
        inst.components.hmrfactory:SetEfficiency(num * 0.03)
        inst.components.hmrfactory:StartProduce()
    end

    inst.AnimState:PlayAnimation("locating", true)
end

local function OnLeaveRoom(inst)
    inst.components.hmrfactory:StopProduce()
    inst.AnimState:PlayAnimation("idle_loop", true)
end

local function OnUpdate(inst)
    local storage = inst.components.entitytracker:GetEntity("storage")
    if storage == nil or not storage:IsValid() then
        SetStorage(inst, FindNewStorage(inst))
    end
end

local function OnRemove(inst)
    inst.components.hmrfactory:CollectAllTempStorage()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2)
    inst:SetPhysicsRadiusOverride(.16)
    MakeObstaclePhysics(inst, inst.physicsradiusoverride)

    inst.Transform:SetFourFaced()

    -- inst.MiniMapEntity:SetIcon("hmr_chest_factory_core.tex")

    inst.AnimState:SetBank("hmr_chest_factory_core")
    inst.AnimState:SetBuild("hmr_chest_factory_core")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.65)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(251/255, 234/255, 234/255)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)

    inst:AddTag("structure")
    inst:AddTag("hmr_chest_factory_core")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("portablestructure")
    inst.components.portablestructure:SetOnDismantleFn(OnDismantle)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)

    inst:AddComponent("entitytracker")

    inst:AddComponent("hmrfactory")
    inst.components.hmrfactory:SetOnProduce(OnProduce)
    inst.components.hmrfactory:SetOnCollectTempStorage(OnCollectTempStorage)

    inst:AddComponent("hmrroom")
    inst.components.hmrroom:SetWatchInterval(TUNING.HMR_CHEST_FACTORY_ROOM_WATCH_INTERVAL)
    inst.components.hmrroom:SetMinRoomSize(TUNING.HMR_CHEST_FACTORY_MIN_ROOM_SIZE)
    inst.components.hmrroom:SetMaxRoomSize(TUNING.HMR_CHEST_FACTORY_MAX_ROOM_SIZE)
    inst.components.hmrroom:SetOnEnterRoom(OnEnterRoom)
    inst.components.hmrroom:SetOnUpdate(OnUpdate)
    inst.components.hmrroom:SetOnLeaveRoom(OnLeaveRoom)
    inst.components.hmrroom:StartWatch()

    MakeHauntable(inst)

    inst:DoTaskInTime(0, SetStorage)

    inst:ListenForEvent("onremove", OnRemove)

    return inst
end

--------------------------------------------------------------------------
--[[灵枢织造箱核心物品]]
--------------------------------------------------------------------------
local function OnDeploy(inst, pt, deployer, rot)
    local core = SpawnPrefab("hmr_chest_factory_core")
    if core ~= nil then
        local storage = inst.components.entitytracker:GetEntity("storage")
        if storage then
            core.components.entitytracker:TrackEntity("storage", storage)
        end

        core.Transform:SetPosition(pt:Get())
        core.AnimState:PlayAnimation("place")
        core.AnimState:PushAnimation("idle_loop")

        inst:Remove()
    end
end

local function item_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hmr_chest_factory_core")
    inst.AnimState:SetBuild("hmr_chest_factory_core")
    inst.AnimState:PlayAnimation("pack_loop")

    inst:AddTag("eyeturret") --眼球塔的专属标签，但为了deployable组件的摆放名字而使用（显示为“放置”）

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hmr_chest_factory_core_item"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hmr_chest_factory_core_item.xml"

    inst:AddComponent("entitytracker")

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
    inst.components.deployable.ondeploy = OnDeploy

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("hmr_chest_factory_core", fn, assets),
        Prefab("hmr_chest_factory_core_item", item_fn, assets),
        MakePlacer("hmr_chest_factory_core_item_placer", "hmr_chest_factory_core", "hmr_chest_factory_core", "idle_loop")