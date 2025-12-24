require "prefabutil"

----------------------------------------------------------------------------------------
---[[柱子]]
----------------------------------------------------------------------------------------
local assets =
{
    Asset("ANIM", "anim/honor_balance_maintainer.zip"),
}

local function ItemTradeTest(inst, item)
    if item and item.prefab == "opalpreciousgem"  then
        return true
    end
    return false
end

local function OnGemGiven(inst, giver, item, count)
    -- inst.SoundEmitter:PlaySound("dontstarve/common/telebase_hum", "hover_loop")
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
    inst.components.trader:Disable()
    inst.components.pickable:SetUp("opalpreciousgem", 1000000)
    inst.components.pickable:Pause()
    inst.components.pickable.caninteractwith = true
    inst.AnimState:PlayAnimation("idle_full_loop", true)
    inst.gem = true
end

local function OnGemTaken(inst)
    -- inst.SoundEmitter:KillSound("hover_loop")
    inst.components.trader:Enable()
    inst.components.pickable.caninteractwith = false
    inst.AnimState:PlayAnimation("idle_empty")
    inst.gem = false
end

local function OnLoad(inst, data)
    if not inst.components.pickable.caninteractwith then
        OnGemTaken(inst)
    else
        OnGemGiven(inst)
    end
end

local function getstatus(inst)
    return inst.components.pickable.caninteractwith and "VALID" or "GEMS"
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("honor_balance_maintainer")
    inst.AnimState:SetBuild("honor_balance_maintainer")
    inst.AnimState:PlayAnimation("idle_empty")

    inst:AddTag("gemsocket")
    inst:AddTag("trader")
    inst:AddTag("shibie")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("pickable")
    inst.components.pickable.caninteractwith = false
    inst.components.pickable.onpickedfn = OnGemTaken

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGemGiven

    inst:AddComponent("hauntable")

    inst.OnLoad = OnLoad

    return inst
end

----------------------------------------------------------------------------------------
---[[地面三角]]
----------------------------------------------------------------------------------------
local ground_assets =
{
    Asset("ANIM", "anim/honor_balance_maintainer_ground.zip")
}

--开始光照
local function StartLight(inst)
    inst._startlighttask = nil
    inst.Light:Enable(true)
    if inst._staffstar == nil then
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
end

--停止光照
local function StopLight(inst)
    inst._stoplighttask = nil
    inst.Light:Enable(false)
    if inst._staffstar == nil then
        inst.AnimState:ClearBloomEffectHandle()
    end
end

--开始特效
local function SoundFadeOut(inst)
    for time = 1, 8 do
        inst:DoTaskInTime(time * 0.1, function()
            inst.SoundEmitter:SetParameter("beam", "intensity", 0.8 - time * 0.1)
            if time == 8 then
                inst.SoundEmitter:KillSound("beam")
            end
        end)
    end
end

local function StartFX(inst)
    if inst._fxfront == nil or inst._fxback == nil then
        local x, y, z = inst.Transform:GetWorldPosition()

        if inst._fxpulse ~= nil then
            inst._fxpulse:Remove()
        end
        inst._fxpulse = SpawnPrefab("positronpulse")
        inst._fxpulse.Transform:SetPosition(x, y, z)
        SoundFadeOut(inst._fxpulse)

        if inst._fxfront ~= nil then
            inst._fxfront:Remove()
        end
        inst._fxfront = SpawnPrefab("positronbeam_front")
        inst._fxfront.Transform:SetPosition(x, y, z)

        if inst._fxback ~= nil then
            inst._fxback:Remove()
        end
        inst._fxback = SpawnPrefab("positronbeam_back")
        inst._fxback.Transform:SetPosition(x, y, z)

        if inst._startlighttask ~= nil then
            inst._startlighttask:Cancel()
        end
        inst._startlighttask = inst:DoTaskInTime(3 * FRAMES, StartLight)
    end
    if inst._stoplighttask ~= nil then
        inst._stoplighttask:Cancel()
        inst._stoplighttask = nil
    end
    inst.lightfx = true
end

--停止特效
local function StopFX(inst)
    if inst._fxpulse ~= nil then
        inst._fxpulse:KillFX()
        inst._fxpulse = nil
    end
    if inst._fxfront ~= nil or inst._fxback ~= nil then
        if inst._fxback ~= nil then
            inst._fxfront:KillFX()
            inst._fxfront = nil
        end
        if inst._fxback ~= nil then
            inst._fxback:KillFX()
            inst._fxback = nil
        end
        if inst._stoplighttask ~= nil then
            inst._stoplighttask:Cancel()
        end
        inst._stoplighttask = inst:DoTaskInTime(9 * FRAMES, StopLight)
    end
    if inst._startlighttask ~= nil then
        inst._startlighttask:Cancel()
        inst._startlighttask = nil
    end
    inst.lightfx = nil
end

-- 获取状态
local function ground_getstatus(inst)
    return "VALID" or "GEMS"
end

-- 部件配置
local telebase_parts =
{
    { part = "honor_balance_maintainer", x = -1.3, z = -1.3 },
    { part = "honor_balance_maintainer", x =  2.4, z = -0.5 },
    { part = "honor_balance_maintainer", x = -0.5, z =  2.4 }
}

local function OnRemove(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Remove()
    end
end

local function dropgems(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.components.pickable ~= nil and v.components.pickable.caninteractwith then
            inst.components.lootdropper:SpawnLootPrefab("opalpreciousgem")
        end
    end
end

local function ondestroyed(inst)
    dropgems(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.components.pickable ~= nil and v.components.pickable.caninteractwith then
            v.AnimState:PlayAnimation("hit_full")
            v.AnimState:PushAnimation("idle_full_loop")
        else
            v.AnimState:PlayAnimation("hit_empty")
            v.AnimState:PushAnimation("idle_empty")
        end
    end
end

local function OnGemChange(inst)
    local objects = inst.components.objectspawner.objects
    local gemnum = 0
    for _, object in pairs(objects) do
        if object.gem then
            gemnum = gemnum + 1
        end
    end
    if gemnum == 3 then
        TheWorld.components.hmrterrorevent:AddPreventSource(inst)
        StartFX(inst)
    else
        TheWorld.components.hmrterrorevent:RemovePreventSource(inst)
        StopFX(inst)
    end
end

local function NewObject(inst, obj)
    local function OnGemChangeProxy()
        OnGemChange(inst)
    end
    inst:ListenForEvent("trade", OnGemChangeProxy, obj)
    inst:ListenForEvent("picked", OnGemChangeProxy, obj)
    OnGemChange(inst)
end

local function RevealPart(v)
    v:Show()
    v.AnimState:PlayAnimation("place")
    v.AnimState:PushAnimation("idle_empty")
end

-- 当传送基站建造完成时调用的函数
local function OnBuilt(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = (45 - inst.Transform:GetRotation()) * DEGREES
    local sin_rot = math.sin(rot)
    local cos_rot = math.cos(rot)
    -- 生成并设置传送基站的部件位置
    for i, v in ipairs(telebase_parts) do
        local part = inst.components.objectspawner:SpawnObject(v.part, inst.linked_skinname, inst.skin_id)
        part.Transform:SetPosition(x + v.x * cos_rot - v.z * sin_rot, 0, z + v.z * cos_rot + v.x * sin_rot)
    end
    -- 隐藏所有对象并延迟显示
    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Hide()
        v:DoTaskInTime(math.random() * 0.5, RevealPart)
    end
end

-- 创建放置部件的函数
local function createplacerpart()
    local inst = CreateEntity()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("honor_balance_maintainer")
    inst.AnimState:SetBuild("honor_balance_maintainer")
    inst.AnimState:PlayAnimation("idle_empty")

    return inst
end

-- 设置放置装饰的函数
local function placerdecor(inst)
    local rot = 45 * DEGREES
    local sin_rot = math.sin(rot)
    local cos_rot = math.cos(rot)
    -- 生成并设置放置部件的位置
    for i, v in ipairs(telebase_parts) do
        local part = createplacerpart()
        part.Transform:SetPosition(v.x * cos_rot - v.z * sin_rot, 0, v.z * cos_rot + v.x * sin_rot)
        part.entity:SetParent(inst.entity)
        inst.components.placer:LinkEntity(part)
    end
end

local function ground_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.Light:SetRadius(2)
    inst.Light:SetIntensity(.75)
    inst.Light:SetFalloff(.75)
    inst.Light:SetColour(128 / 255, 128 / 255, 255 / 255)
    inst.Light:Enable(false)

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("honor_balance_maintainer.tex")

    inst:AddTag("telebase")
    inst:AddTag("honor_balance_maintainer_ground")

    inst.AnimState:SetBuild("honor_balance_maintainer_ground")
    inst.AnimState:SetBank("honor_balance_maintainer_ground")
    inst.AnimState:PlayAnimation("idle")  
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.scrapbook_anim = "scrapbook"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = ground_getstatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst.components.workable:SetOnFinishCallback(ondestroyed)

    MakeHauntableWork(inst)

    inst:AddComponent("lootdropper")

    inst:AddComponent("objectspawner")
    inst.components.objectspawner.onnewobjectfn = NewObject

    inst:AddComponent("savedrotation")

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("ondeconstructstructure", dropgems)
    inst:ListenForEvent("onremove", OnRemove)

    return inst
end

return Prefab("honor_balance_maintainer", fn, assets),
    Prefab("honor_balance_maintainer_ground", ground_fn, ground_assets),
    MakePlacer("honor_balance_maintainer_ground_placer", "honor_balance_maintainer_ground", "honor_balance_maintainer_ground", "idle", true, nil, nil, nil, 90, nil, placerdecor)