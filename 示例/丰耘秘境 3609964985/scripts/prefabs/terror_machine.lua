local assets =
{
    Asset("ANIM", "anim/terror_machine.zip"),
}

local bloom_symbols = {
    "gem",
    "book",
    "platform",
    "staff",
    "plant"
}

local function SetSymbolsBloom(inst, bloom)
    for _, symbol in ipairs(bloom_symbols) do
        if bloom then
            inst.AnimState:SetSymbolBloom(symbol)
            inst.AnimState:SetSymbolLightOverride(symbol, 0.8)
        else
            inst.AnimState:ClearSymbolBloom(symbol)
            inst.AnimState:SetSymbolLightOverride(symbol, 0)
        end
    end
end

local function onturnon(inst)
    if inst._activetask == nil and not inst:HasTag("burnt") then
        if inst.AnimState:IsCurrentAnimation("proximity_loop") then
            inst.AnimState:PlayAnimation("proximity_loop", true)
        else
            if inst.AnimState:IsCurrentAnimation("place") then
                inst.AnimState:PushAnimation("proximity_pre")
            else
                inst.AnimState:PlayAnimation("proximity_pre")
            end
            inst.AnimState:PushAnimation("proximity_loop", true)
        end

        if not inst.SoundEmitter:PlayingSound("idlesound") then
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_idle_LP", "idlesound")
        end

        SetSymbolsBloom(inst, true)
    end
end

local function onturnoff(inst)
    if inst._activetask == nil and not inst:HasTag("burnt") then
        inst.AnimState:PushAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
        inst.SoundEmitter:KillSound("idlesound")

        SetSymbolsBloom(inst, false)
    end
end

local function doonact(inst, soundprefix)
    if inst._activecount > 1 then
        inst._activecount = inst._activecount - 1
    else
        inst._activecount = 0
        inst.SoundEmitter:KillSound("sound")

        SetSymbolsBloom(inst, false)
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_ding")
end

local function doneact(inst)
    inst._activetask = nil
    if not inst:HasTag("burnt") then
        if inst.components.prototyper.on then
            onturnon(inst)
        else
            onturnoff(inst)
        end
    end
end

local function onactivate(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("use")
        inst.AnimState:PushAnimation("idle", false)

        SetSymbolsBloom(inst, true)

        inst.AnimState:SetSymbolBloom("light_yellow_on")
        if not inst.SoundEmitter:PlayingSound("sound") then
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl3_run", "sound")
        end
        inst._activecount = inst._activecount + 1
        inst:DoTaskInTime(1.5, doonact, "lvl3")

        if inst._activetask ~= nil then
            inst._activetask:Cancel()
        end
        inst._activetask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, doneact)
    end
end

local function onbuiltsound(inst, soundprefix)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_place")
end

local function onbuilt(inst, data)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst:DoTaskInTime(0.15, onbuiltsound, "lvl3")
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        if inst.components.prototyper.on then
            inst.AnimState:PushAnimation("proximity_loop", true)
        else
            inst.AnimState:PushAnimation("idle", false)
        end
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:SetDeploySmartRadius(1)
    MakeObstaclePhysics(inst, .4)

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("terror_machine.tex")

    inst.AnimState:SetBank("terror_machine")
    inst.AnimState:SetBuild("terror_machine")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("prototyper")

    inst.scrapbook_specialinfo = "SCIENCEPROTOTYPER"

    MakeSnowCoveredPristine(inst)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._activecount = 0
    inst._activetask = nil

    inst:AddComponent("inspectable")
    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.TERROR_TECH
    inst.components.prototyper.onactivate = onactivate

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    MakeSnowCovered(inst)

    -- MakeLargeBurnable(inst, nil, nil, true)
    -- MakeLargePropagator(inst)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("terror_machine", fn, assets),
       MakePlacer("terror_machine_placer", "terror_machine", "terror_machine", "idle")