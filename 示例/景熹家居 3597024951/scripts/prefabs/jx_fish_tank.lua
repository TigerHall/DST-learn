local assets =
{
	Asset("ANIM", "anim/jx_fish_tank.zip"),
    -- Asset("ANIM", "anim/jx_chest_ui_3x3.zip"),
}

local SOUNDS = {
    open  = "dontstarve/wilson/chest_open",
    close = "dontstarve/wilson/chest_close",
    built = "dontstarve/common/chest_craft",
}

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")

        if inst.skin_open_sound then
            inst.SoundEmitter:PlaySound(inst.skin_open_sound)
        else
            inst.SoundEmitter:PlaySound(inst.sounds.open)
        end
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)

        if inst.skin_close_sound then
            inst.SoundEmitter:PlaySound(inst.skin_close_sound)
        else
            inst.SoundEmitter:PlaySound(inst.sounds.close)
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
        inst.AnimState:PushAnimation("closed", false)
    end
end

--V2C: also used for restoredfromcollapsed
local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
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
end

local function regular_OnBurnt(inst)
    inst.components.inspectable.getstatus = nil
    if inst.components.container ~= nil then
        --We might still have some overstacks, just not enough to "collapse"
        inst.components.container:DropEverything()
	end

	--fallback to default
	DefaultBurntStructureFn(inst)
end

local function regular_OnDecontructStructure(inst, caster)
	if inst.components.container ~= nil then
        --If not burnt, we might still have some overstacks, just not enough to "collapse"
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

    inst.MiniMapEntity:SetIcon("jx_fish_tank.tex")

    inst:SetDeploySmartRadius(0.5) --recipe min_spacing/2

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.AnimState:SetBank("jx_fish_tank")
    inst.AnimState:SetBuild("jx_fish_tank")
    inst.AnimState:PlayAnimation("closed")

    --MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_fish_tank")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 1--每分钟+60，每天+480

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)
    --MakeSnowCovered(inst)
    SetLunarHailBuildupAmountSmall(inst)

    inst.components.burnable:SetOnBurntFn(regular_OnBurnt)
    inst:ListenForEvent("ondeconstructstructure", regular_OnDecontructStructure)

    -- Save / load is extended by some prefab variants
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("jx_fish_tank", fn, assets),
    MakePlacer("jx_fish_tank_placer", "jx_fish_tank", "jx_fish_tank", "closed")