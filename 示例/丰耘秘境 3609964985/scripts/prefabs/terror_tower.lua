local RANGE = 20

local SLOT_ITEM_LIST = {
    [0] = "terror_blueberry_prime",
    [1] = "terror_ginger_prime",
    [2] = "terror_snakeskinfruit_prime",
}

local assets =
{
    Asset("ANIM", "anim/terror_tower.zip"),
}

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_craft")
end

local function OnOpen(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_open")
end

local function OnClose(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_close")
end

local function SlotTemperature(inst, slot)
    if slot and slot >= 4 then
        if TheWorld.state.temperature >= 40 then
            return 0
        elseif TheWorld.state.temperature <= 10 then
            return 60
        end
    end
end

local function OnHit(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle_loop", true)
end

local function OnDestroyed(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function UpdateBuff(inst, player, out_of_range)
    -- 恒温
    if inst.components.container:Has("terror_snakeskinfruit_prime", 1) and not out_of_range then
        HMR_UTIL.AddConstantTemperatureSource(player, inst)
    else
        HMR_UTIL.RemoveConstantTemperatureSource(player, inst)
    end

    -- 移速
    if player.components.locomotor ~= nil then
        if inst.components.container:Has("terror_ginger_prime", 1) and not out_of_range then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "terror_tower", 1.5)
        else
            player.components.locomotor:RemoveExternalSpeedMultiplier(player, "terror_tower")
        end
    end

    -- 潮湿度
    if inst.components.container:Has("terror_blueberry_prime", 1) and not out_of_range then
        player:AddTag("terror_tower_moisture_buff")
    else
        player:RemoveTag("terror_tower_moisture_buff")
    end
end

local function OnPlayerNear(inst, player)
    player._terror_tower_count = (player._terror_tower_count or 0) + 1
    if player._terror_tower_count == 1 then
        UpdateBuff(inst, player)
    end
end

local function OnPlayerFar(inst, player)
    player._terror_tower_count = (player._terror_tower_count or 1) - 1
    if player._terror_tower_count == 0 then
        UpdateBuff(inst, player, true)
    end
end

local function UpdateWaterFXAnim(inst, id)
    if inst._fxs == nil or inst._fxs[id] == nil then
        return
    end
    local item = inst.components.container:GetItemInSlot(id + 1)
    if item ~= nil and item.prefab == SLOT_ITEM_LIST[id] then
        inst._fxs[id].AnimState:PlayAnimation("water"..id.."_pre")
        inst._fxs[id].AnimState:PushAnimation("water"..id.."_loop", true)
    else
        inst._fxs[id].AnimState:PlayAnimation("water"..id.."_pst")
    end
end

local function SpawnWaterFX(inst)
    inst._fxs = {}
    for i = 0, 2 do
        local fx = SpawnPrefab("terror_tower_water"..tostring(i), "terror_tower_water"..(inst.linked_skinname or "")..i)
        fx.entity:SetParent(inst.entity)
        fx.Follower:FollowSymbol(inst.GUID, "water"..tostring(i), nil, nil, nil, true)
        inst._fxs[i] = fx
        UpdateWaterFXAnim(inst, i)
    end
end

local function GetIdByItemName(name)
    for i, item in pairs(SLOT_ITEM_LIST) do
        if name == item then
            return i
        end
    end
    return nil
end

local function OnItemChanged(inst, data)
    for _, player in pairs(AllPlayers) do
        if inst:GetDistanceSqToInst(player) <= RANGE*RANGE then
            UpdateBuff(inst, player)
        end
    end

    local item = data and (data.item or data.prev_item) or nil
    if item ~= nil then
        local id = GetIdByItemName(item.prefab)
        if id ~= nil then
            UpdateWaterFXAnim(inst, id)
        end
    end
end

local function HammerBlockTest(inst, target, worker)
    return (not worker:HasTag("player")) and target:HasTag("structure")-- and inst ~= target
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:SetPhysicsRadiusOverride(.16)
    MakeObstaclePhysics(inst, 0.2)

    inst.MiniMapEntity:SetIcon("terror_tower.tex")

    inst.AnimState:SetBank("terror_tower")
    inst.AnimState:SetBuild("terror_tower")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("structure")
    inst:AddTag("terror_tower")
    inst:AddTag("shadecanopysmall") -- 防野火，shadecanopysmall范围：22，shadecanopy范围：28

    inst.item_slot = SLOT_ITEM_LIST

    HMR_UTIL.AddDeployHelper(inst, RANGE, {147 / 255, 112 / 255, 219 / 255, 1})

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("terror_tower")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("hmrcontainermanager")
    inst.components.hmrcontainermanager:SetSlotTemperature(SlotTemperature)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetOnPlayerNear(OnPlayerNear)
    inst.components.playerprox:SetOnPlayerFar(OnPlayerFar)
    inst.components.playerprox:SetDist(RANGE, RANGE) -- In case a player manages to squeeze inside the doughnut physics.

    inst:AddComponent("lightningblocker")
    inst.components.lightningblocker:SetBlockRange(RANGE)

    inst:AddComponent("hmrworkblocker")
    inst.components.hmrworkblocker:SetBlockAction(ACTIONS.HAMMER, RANGE, HammerBlockTest)

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnHit)
    inst.components.workable:SetOnFinishCallback(OnDestroyed)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:ListenForEvent("itemget", OnItemChanged)
    inst:ListenForEvent("itemlose", OnItemChanged)

    inst:DoTaskInTime(0, SpawnWaterFX)

    MakeSnowCovered(inst)

    return inst
end

local function MakeWaterFX(id)
    local function fx_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddFollower()

        inst.AnimState:SetBank("terror_tower")
        inst.AnimState:SetBuild("terror_tower")
        inst.AnimState:PlayAnimation("water"..tostring(id).."_loop", true)

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        inst.persists = false

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end

    return Prefab("terror_tower_water"..tostring(id), fx_fn, assets)
end

----------------------------------------------------------------------------
---[[喷泉皮肤装饰物]]
----------------------------------------------------------------------------
local MakeFormationMember = require("prefabs/hmr_formation_common")

local function decor_commom_postinit(inst)
    inst.entity:SetCanSleep(false)

    RemovePhysicsColliders(inst)

    inst.AnimState:SetLightOverride(0.2)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")

    inst.persists = false
end

local function SetSkin(inst, skin_build)
    local POS_LIST = {
        [1] = "low",
        [2] = "med",
        [3] = "high",
    }
    local decor_id = math.random(0, 6)
    local height = POS_LIST[math.random(1, 3)]
    inst.AnimState:OverrideSymbol(height, skin_build, "decor"..decor_id)
end

local function decor_master_postinit(inst)
    inst.SetSkin = SetSkin
end

local light_data = {
    radius = 3,
    rotation_speed = 0.9,
    formation_type = "terror_tower_fountain",
    min_size = 5,
    max_size = 7,
    -- light = {
    --     colour = {0.2, 0.0, 0.8, 1},
    -- },
    bank = "terror_tower_fountain",
    build = "terror_tower_fountain",
    anim = "item_loop",
    anim_pre = "item_appear",
    anim_pst = "item_disappear",
    random_frame = true,
}

return Prefab("terror_tower", fn, assets),
       HMR_UTIL.MakePlacerWithRange("terror_tower_placer", "terror_tower", "terror_tower", "idle", RANGE),
       MakeWaterFX(0),
       MakeWaterFX(1),
       MakeWaterFX(2),

       MakeFormationMember("terror_tower_fountain_fx", decor_commom_postinit, decor_master_postinit, nil, nil, light_data)