local assets =
{
	Asset("ANIM", "anim/jx_tv.zip"),
}

local SOUNDS = {
    open  = "dontstarve/wilson/chest_open",
    close = "dontstarve/wilson/chest_close",
    built = "dontstarve/common/researchmachine_lvl2_place",
}

local function ShouldTurnOn(inst)
    return not inst:HasTag("burnt") and inst.components.container ~= nil and not inst.components.container:IsEmpty() and not inst:HasTag("burnt")
end

local function UpdateAnimState(inst, push_anim)
    if ShouldTurnOn(inst) then
        inst.Light:Enable(true)
        if not inst:HasTag("burnt") then
            if push_anim then
                inst.AnimState:PushAnimation("turn_on", false)
            else
                inst.AnimState:PlayAnimation("turn_on", false)
            end
            inst.AnimState:PushAnimation("idle_on", false)
        end
    else
        inst.Light:Enable(false)
        if not inst:HasTag("burnt") then
            if push_anim then
                inst.AnimState:PushAnimation("turn_off", false)
            else
                inst.AnimState:PlayAnimation("turn_off")
            end
            inst.AnimState:PushAnimation("idle_off", false)
        end
    end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
        inst.AnimState:PlayAnimation("hit")
        UpdateAnimState(inst, true)
    end
end

--V2C: also used for restoredfromcollapsed
local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_off", false)
    if inst.skin_place_sound then
        inst.SoundEmitter:PlaySound(inst.skin_place_sound)
    else
        inst.SoundEmitter:PlaySound(inst.sounds.built)
    end
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
    UpdateAnimState(inst)
end

local function OnBurnt(inst)
    inst.components.inspectable.getstatus = nil

	if inst.components.container ~= nil then
        inst.components.container:DropEverything()
	end

	--fallback to default
	DefaultBurntStructureFn(inst)
end

local function regular_OnDecontructStructure(inst, caster)
	if inst.components.container ~= nil then
        inst.components.container:DropEverything()
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:SetColour(1, 1, 1)
    inst.Light:SetIntensity(.85)
    inst.Light:SetFalloff(.7)
    inst.Light:SetRadius(10)

    inst.MiniMapEntity:SetIcon("jx_tv.tex")

    inst:SetDeploySmartRadius(0.5) --recipe min_spacing/2

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.AnimState:SetBank("jx_tv")
    inst.AnimState:SetBuild("jx_tv")
    inst.AnimState:PlayAnimation("idle_off")

    --MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = SOUNDS

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_tv")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)
    --MakeSnowCovered(inst)
    SetLunarHailBuildupAmountSmall(inst)

    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst:ListenForEvent("ondeconstructstructure", regular_OnDecontructStructure)

    inst:ListenForEvent("itemget", UpdateAnimState)
    inst:ListenForEvent("itemlose", UpdateAnimState)

    -- Save / load is extended by some prefab variants
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("jx_tv", fn, assets),
    MakePlacer("jx_tv_placer", "jx_tv", "jx_tv", "idle_off")