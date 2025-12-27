local assets =
{
  Asset("ANIM", "anim/jx_chest.zip"),
  -- Asset("ANIM", "anim/jx_chest_ui_3x3.zip"),
  Asset("ANIM", "anim/jx_chest_upgraded.zip"),
}

local prefabs =
{
	"collapse_small",
	"chestupgrade_stacksize_fx",
	"alterguardianhatshard",
	"collapsed_treasurechest",
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

local function regular_getstatus(inst, viewer)
	return inst._chestupgrade_stacksize and "UPGRADED_STACKSIZE" or nil
end

local function regular_ConvertToCollapsed(inst, droploot, burnt)
	if inst.components.burnable and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	if droploot then
		local fx = SpawnPrefab("collapse_small")
		fx.Transform:SetPosition(x, y, z)
		fx:SetMaterial("wood")
		inst.components.lootdropper.min_speed = 2.25
		inst.components.lootdropper.max_speed = 2.75
		if burnt then
			inst:AddTag("burnt")
			inst.components.lootdropper:DropLoot()
			inst:RemoveTag("burnt")
		else
			inst.components.lootdropper:DropLoot()
		end
		inst.components.lootdropper.min_speed = nil
		inst.components.lootdropper.max_speed = nil
	end

	inst.components.container:Close()
	inst.components.workable:SetWorkLeft(2)

	local pile = SpawnPrefab("collapsed_treasurechest")
	pile.Transform:SetPosition(x, y, z)
	pile:SetChest(inst, burnt)
end

local function regular_Upgrade_OnHit(inst, worker)
	if not inst:HasTag("burnt") then
		if inst.components.container then
			inst.components.container:DropEverything(nil, true)
			inst.components.container:Close()
		end
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("closed", false)
	end
end

local function regular_ShouldCollapse(inst)
	if inst.components.container and inst.components.container.infinitestacksize then
		local overstacks = 0
		for k, v in pairs(inst.components.container.slots) do
			local stackable = v.components.stackable
			if stackable then
				overstacks = overstacks + math.ceil(stackable:StackSize() / (stackable.originalmaxsize or stackable.maxsize))
				if overstacks >= TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD then
					return true
				end
			end
		end
	end
	return false
end

local function regular_Upgrade_OnHammered(inst, worker)
	if regular_ShouldCollapse(inst) then
		if TheWorld.Map:IsPassableAtPoint(inst.Transform:GetWorldPosition()) then
			inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)
			if not inst.components.container:IsEmpty() then
				regular_ConvertToCollapsed(inst, true, false)
				return
			end
		else
			if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
				inst.components.burnable:Extinguish()
			end
			inst.components.lootdropper:DropLoot()
			inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD)
			local fx = SpawnPrefab("collapse_small")
			fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			fx:SetMaterial("wood")
			inst:Remove()
			return
		end
	elseif inst.components.container ~= nil then
        inst.components.container:DropEverything()
	end

	onhammered(inst, worker)
end

local function regular_Upgrade_OnRestoredFromCollapsed(inst)
	inst.AnimState:PlayAnimation("rebuild")
	inst.AnimState:PushAnimation("closed", false)
	if inst.skin_place_sound then
		inst.SoundEmitter:PlaySound(inst.skin_place_sound)
	else
		inst.SoundEmitter:PlaySound(inst.sounds.built)
	end
end

local function DoUpgradeVisuals(inst)
    --local skin_name = (inst.AnimState:GetSkinBuild() or ""):gsub("treasurechest_", "")
    inst.AnimState:SetBank("jx_chest_upgraded")
    inst.AnimState:SetBuild("jx_chest_upgraded")
    --if skin_name ~= "" then
    --    skin_name = "treasurechest_upgraded_" .. skin_name
    --    inst.AnimState:SetSkin(skin_name, "treasure_chest_upgraded")
    --end
end

local function OnUpgrade(inst, performer, upgraded_from_item)
    local numupgrades = inst.components.upgradeable.numupgrades
    if numupgrades == 1 then
        inst._chestupgrade_stacksize = true
        if inst.components.container ~= nil then
            inst.components.container:Close()
            inst.components.container:EnableInfiniteStackSize(true)
            inst.components.inspectable.getstatus = regular_getstatus
        end
        if upgraded_from_item then
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("chestupgrade_stacksize_fx")
            fx.Transform:SetPosition(x, y, z)
            local total_hide_frames = 6
            inst:DoTaskInTime(total_hide_frames * FRAMES, DoUpgradeVisuals)
        else
            DoUpgradeVisuals(inst)
        end
    end
    inst.components.upgradeable.upgradetype = nil

    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:SetLoot({ "alterguardianhatshard" })
    end
	inst.components.workable:SetOnWorkCallback(regular_Upgrade_OnHit)
	inst.components.workable:SetOnFinishCallback(regular_Upgrade_OnHammered)
	inst:ListenForEvent("restoredfromcollapsed", regular_Upgrade_OnRestoredFromCollapsed)
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

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        OnUpgrade(inst)
    end
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("jx_chest.tex")

    inst:SetDeploySmartRadius(0.5) --recipe min_spacing/2

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.AnimState:SetBank("jx_chest")
    inst.AnimState:SetBuild("jx_chest")
    inst.AnimState:PlayAnimation("closed")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jx_chest")
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

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)
    MakeSnowCovered(inst)
    SetLunarHailBuildupAmountSmall(inst)

    inst.components.burnable:SetOnBurntFn(regular_OnBurnt)
    inst:ListenForEvent("ondeconstructstructure", regular_OnDecontructStructure)

    inst.OnSave = onsave
    inst.OnLoad = onload
    
    inst.scrapbook_removedeps = { "alterguardianhatshard" }
    
    local upgradeable = inst:AddComponent("upgradeable")
    upgradeable.upgradetype = UPGRADETYPES.CHEST
    upgradeable:SetOnUpgradeFn(OnUpgrade)

    return inst
end

return Prefab("jx_chest", fn, assets, prefabs),
    MakePlacer("jx_chest_placer", "jx_chest", "jx_chest", "closed")