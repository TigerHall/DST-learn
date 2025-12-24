local FURNITURES = {}


----------------------------------------------------------------------------
---[[桌子]]
----------------------------------------------------------------------------
local function AddTable(name, table_data)
    local function GetStatus(inst)
        return (inst:HasTag("burnt") and "BURNT") or nil
    end

    local function OnHammer(inst, worker, workleft, workcount)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end

    local function OnHammered(inst, worker)
        local collapse_fx = SpawnPrefab("collapse_small")
        collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        collapse_fx:SetMaterial("wood")

        if inst.components.container then
            inst.components.container:DropEverything(nil, true)
        end

        inst.components.lootdropper:DropLoot()

        inst:Remove()
    end

    local function OnBuilt(inst)
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle", true)

        inst.SoundEmitter:PlaySound("dontstarve/common/repair_stonefurniture")
    end

    local function OnBurnt(inst)
        inst.components.inspectable.getstatus = nil

        DefaultBurntStructureFn(inst)
    end

    local function OnSave(inst, data)
        local burnable = inst.components.burnable
        if (burnable and burnable:IsBurning()) or inst:HasTag("burnt") then
            data.burnt = true
        end
    end

    local function OnLoad(inst, data)
        if data then
            if data.burnt then
                inst.components.burnable.onburnt(inst)
            end
        end
    end

    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }
    if table_data.assets ~= nil then
        for k, v in pairs(table_data.assets) do
            table.insert(assets, v)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

		inst:SetDeploySmartRadius(1) --recipe min_spacing/2

        MakeObstaclePhysics(inst, 0.7)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(-1)

        inst:AddTag("structure")

        if table_data.common_postinit then
            table_data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(5)
        inst.components.workable:SetOnWorkCallback(OnHammer)
        inst.components.workable:SetOnFinishCallback(OnHammered)

        MakeHauntableWork(inst)

        MakeMediumBurnable(inst, 60, nil, true)
        MakeMediumPropagator(inst)
        inst.components.burnable:SetOnBurntFn(OnBurnt)

        inst:ListenForEvent("onbuilt", OnBuilt)

        if table_data.master_postinit then
            table_data.master_postinit(inst)
        end

        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        return inst
    end

    table.insert(FURNITURES, Prefab(name, fn, assets))
    table.insert(FURNITURES, MakePlacer(name.."_placer", name, name, "idle"))
end

-- AddTable("hmr_table_glowisle", {

-- })

AddTable("hmr_cherry_table", {
    master_postinit = function(inst)
        inst:AddComponent("container")
        inst.components.container:WidgetSetup("hmr_cherry_table")
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        -- local show_list = {
        --     {slot = 1, symbol = "slot_0", bgsymbol = "slotbg_0", onshow = function() inst.AnimState:OverrideSymbol("plate_0", "hmr_cherry_table", "plate") end, onclear = function() inst.AnimState:ClearOverrideSymbol("plate_0") end},
        --     {slot = 2, symbol = "slot_1", bgsymbol = "slotbg_1", onshow = function() inst.AnimState:OverrideSymbol("plate_1", "hmr_cherry_table", "plate") end, onclear = function() inst.AnimState:ClearOverrideSymbol("plate_1") end},
        --     {slot = 3, symbol = "slot_2", bgsymbol = "slotbg_2", onshow = function() inst.AnimState:OverrideSymbol("plate_2", "hmr_cherry_table", "plate") end, onclear = function() inst.AnimState:ClearOverrideSymbol("plate_2") end},
        --     {slot = 4, symbol = "slot_3", bgsymbol = "slotbg_3", onshow = function() inst.AnimState:OverrideSymbol("plate_3", "hmr_cherry_table", "plate") end, onclear = function() inst.AnimState:ClearOverrideSymbol("plate_3") end},
        --     {slot = 5, symbol = "slot_4", bgsymbol = "slotbg_4", onshow = function() inst.AnimState:OverrideSymbol("plate_4", "hmr_cherry_table", "plate") end, onclear = function() inst.AnimState:ClearOverrideSymbol("plate_4") end},
        -- }
        local show_list = {
            {slot = 1, symbol = "slot_0", bgsymbol = "slotbg_0"},
            {slot = 2, symbol = "slot_1", bgsymbol = "slotbg_1"},
            {slot = 3, symbol = "slot_2", bgsymbol = "slotbg_2"},
            {slot = 4, symbol = "slot_3", bgsymbol = "slotbg_3"},
            {slot = 5, symbol = "slot_4", bgsymbol = "slotbg_4"},
        }
        inst:AddComponent("hshowinvitem")
        inst.components.hshowinvitem:SetShowSlot(show_list)

        inst:AddComponent("preserver")
        inst.components.preserver:SetPerishRateMultiplier(0)
    end,
    assets = {
        Asset("ANIM", "anim/hmr_cherry_table_ui_r5.zip"),
    }
})

----------------------------------------------------------------------------
---[[椅子]]
----------------------------------------------------------------------------
local function AddChair(name, chair_data)
    local function OnHit(inst, worker, workleft, numworks)
        if not inst:HasTag("burnt") then
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle", false)
            if inst.back ~= nil then
                inst.back.AnimState:PlayAnimation("hit")
                inst.back.AnimState:PushAnimation("idle", false)
            end
        end
    end

    local function OnHammered(inst, worker)
        local collapse_fx = SpawnPrefab("collapse_small")
        collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        collapse_fx:SetMaterial("wood")

        inst.components.lootdropper:DropLoot()

        inst:Remove()
    end

    local function OnBuilt(inst, data)
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle", false)
        if inst.back ~= nil then
            inst.back.AnimState:PlayAnimation("place")
            inst.back.AnimState:PushAnimation("idle", false)
        end

        inst.SoundEmitter:PlaySound("dontstarve/common/repair_stonefurniture")

        local builder = (data and data.builder) or nil
        TheWorld:PushEvent("CHEVO_makechair", {target = inst, doer = builder})
    end

    local function OnChairBurnt(inst)
        DefaultBurntStructureFn(inst)

        if inst.back ~= nil then
            inst.back.AnimState:PlayAnimation("burnt")
        end

        inst:RemoveComponent("sittable")
    end

    local function GetStatus(inst)
        return (inst:HasTag("burnt") and "BURNT") or
            (inst.components.sittable:IsOccupied() and "OCCUPIED") or
            nil
    end

    local function OnSave(inst, data)
        local burnable = inst.components.burnable
        if (burnable and burnable:IsBurning()) or inst:HasTag("burnt") then
            data.burnt = true
        end
    end

    local function OnLoad(inst, data)
        if data then
            if data.burnt then
                inst.components.burnable.onburnt(inst)
            end
        end
    end

	local assets =
	{
		Asset("ANIM", "anim/"..name..".zip"),
	}

    if chair_data.assets then
        for k, v in pairs(chair_data.assets) do
            table.insert(assets, v)
        end
    end

	if chair_data.hasback then
		local function OnBackReplicated(inst)
			local parent = inst.entity:GetParent()
			if parent ~= nil and (parent.prefab == inst.prefab:sub(1, -6)) then
				parent.highlightchildren = { inst }
			end
		end

		local function backfn()
			local inst = CreateEntity()

			inst.entity:AddTransform()
			inst.entity:AddAnimState()
			inst.entity:AddNetwork()

			inst.Transform:SetFourFaced()

			inst:AddTag("FX")

            inst.AnimState:SetBank(name)
            inst.AnimState:SetBuild(name)
			inst.AnimState:PlayAnimation("idle", true)
			inst.AnimState:SetFinalOffset(3)
			inst.AnimState:Hide("parts")

			inst.entity:SetPristine()

			if not TheWorld.ismastersim then
				inst.OnEntityReplicated = OnBackReplicated

				return inst
			end

			inst.persists = false

			return inst
		end

		table.insert(FURNITURES, Prefab(name.."_back", backfn, assets))
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst:SetDeploySmartRadius(0.875) --recipe min_spacing/2

		MakeObstaclePhysics(inst, 0.25)

		inst.Transform:SetFourFaced()

		inst:AddTag("structure")
        if chair_data.limited then
            inst:AddTag("limited_chair")
        else
            inst:AddTag("faced_chair")
            inst:AddTag("rotatableobject")
        end

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:SetFinalOffset(-1)
		inst.AnimState:Hide("back_over")

        if chair_data.common_postinit then
            chair_data.common_postinit(inst)
        end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		if chair_data.hasback then
			inst.back = SpawnPrefab(name.."_back")
			inst.back.entity:SetParent(inst.entity)
			inst.highlightchildren = { inst.back }
		end

        inst.scrapbook_facing  = FACING_DOWN

		inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

		inst:AddComponent("lootdropper")

		inst:AddComponent("sittable")

        if not chair_data.limited then
            inst:AddComponent("savedrotation")
            inst.components.savedrotation.dodelayedpostpassapply = true
        end

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnWorkCallback(OnHit)
		inst.components.workable:SetOnFinishCallback(OnHammered)

		inst:ListenForEvent("onbuilt", OnBuilt)

		MakeHauntableWork(inst)

        MakeMediumBurnable(inst, 45, nil, true)
        inst.components.burnable:SetOnBurntFn(OnChairBurnt)
        MakeSmallPropagator(inst)

        if chair_data.master_postinit then
            chair_data.master_postinit(inst)
        end

		inst.OnLoad = OnLoad
		inst.OnSave = OnSave

		return inst
	end

	table.insert(FURNITURES, Prefab(name, fn, assets))
	table.insert(FURNITURES, MakePlacer(name.."_placer", name, name, "idle", nil, nil, nil, nil, 15, "four"))
end

AddChair("hmr_lemon_stool", {
    assets = {
        Asset("ATLAS", "images/inventoryimages/hmr_lemon_stool.xml"),
        Asset("IMAGE", "images/inventoryimages/hmr_lemon_stool.tex"),
    },
    master_postinit = function(inst)
        local function OnSit(occupier)

        end

        local function OnLeave(occupier)

        end

        inst.components.sittable:SetOnSit(OnSit)
        inst.components.sittable:SetOnLeave(OnLeave)
    end
})

AddChair("hmr_lemon_chair", {
    hasback = true,
    assets = {
        Asset("ATLAS", "images/inventoryimages/hmr_lemon_chair.xml"),
        Asset("IMAGE", "images/inventoryimages/hmr_lemon_chair.tex"),
    }
})

AddChair("hmr_cherry_chair", {
    limited = true,
    assets = {
        -- Asset("ATLAS", "images/inventoryimages/hmr_cherry_chair.xml"),
        -- Asset("IMAGE", "images/inventoryimages/hmr_cherry_chair.tex"),
    }
})


----------------------------------------------------------------------------
---[[装饰墙]]
----------------------------------------------------------------------------
local function AddDecorWall(name, decorwall_data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local function OnHarmmer(inst)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
    end

    local function OnHammered(inst, worker)
        inst.lootdropper:DropLoot()

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")

        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.Transform:SetEightFaced()

        inst:SetDeploySmartRadius(0.5) --DEPLOYMODE.WALL assumes spacing of 1

        MakeObstaclePhysics(inst, .5)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)

        MakeSnowCoveredPristine(inst)

        if decorwall_data.common_postinit then
            decorwall_data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(5)
        inst.components.workable:SetOnFinishCallback(OnHammered)
        inst.components.workable:SetOnWorkCallback(OnHarmmer)

        MakeLargeBurnable(inst, 100, nil, true)
        MakeLargePropagator(inst)

        MakeHauntableWork(inst)

        MakeSnowCovered(inst)

        if decorwall_data.master_postinit then
            decorwall_data.master_postinit(inst)
        end

        return inst
    end

    table.insert(FURNITURES, Prefab(name, fn, assets))
end

AddDecorWall(
    "hmr_decorate_wall",
    {
        common_postinit = function(inst)
            inst:AddComponent("hdecoratable")
            inst.components.hdecoratable:SetSwapSymbolData("swap_decor", 0, -300)
            inst:DoTaskInTime(2, function() inst.components.hdecoratable:Refresh() end)
        end,
        master_postinit = function(inst)
            inst:AddComponent("container")
            inst.components.container:WidgetSetup("hmr_decorate_wall")
            inst.components.container.skipclosesnd = true
            inst.components.container.skipopensnd = true
        end
    }
)


----------------------------------------------------------------------------
---[[地毯]]
----------------------------------------------------------------------------
local function AddCarpet(name, carpet_data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/hmr_blueberry_carpet_item.xml"),
        Asset("IMAGE", "images/inventoryimages/hmr_blueberry_carpet_item.tex"),
    }

    local function OnDeploy(inst, pt, deployer, rot)
        local carpet = SpawnPrefab(name)
        if carpet ~= nil then
            carpet.Transform:SetPosition(pt:Get())
            carpet.Transform:SetRotation(rot)
            inst:Remove()
        end
    end

    local function item_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("item")

        inst:AddTag("carpet_item")

        if carpet_data.item_common_postinit ~= nil then
            carpet_data.item_common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = name.."_item"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name.."_item.xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeploySpacing(0)
        inst.components.deployable.ondeploy = OnDeploy

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)

        if carpet_data.item_master_postinit ~= nil then
            carpet_data.item_master_postinit(inst)
        end

        return inst
    end

    local function OnWorked(inst)
        inst.components.lootdropper:SpawnLootPrefab(name.."_item")

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")

        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("ground")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetFinalOffset(1)

        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("carpet")

        -- 配合叉子做移除动作
        inst:AddTag("hmr_carpet")
        inst.radius = carpet_data.radius or 3

        if carpet_data.common_postinit ~= nil then
            carpet_data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        inst:AddComponent("savedrotation")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.TERRAFORM)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnWorked)

        if carpet_data.master_postinit ~= nil then
            carpet_data.master_postinit(inst)
        end

        return inst
    end

    table.insert(FURNITURES, Prefab(name.."_item", item_fn, assets))
    table.insert(FURNITURES, MakePlacer(name.."_item_placer", name, name, "ground", true, nil, nil, nil, 90))

    table.insert(FURNITURES, Prefab(name, fn, assets))
end

AddCarpet(
    "hmr_blueberry_carpet",
    {
        radius = 3,
        master_postinit = function(inst)
            local function OnNear(inst, player)
                player.hmr_blueberry_carpet_count = (player.hmr_blueberry_carpet_count or 0) + 1
                if player.hmr_blueberry_carpet_count == 1 and player.components.debuffable ~= nil then
                    player.components.debuffable:AddDebuff("hmr_blueberry_carpet_buff", "hmr_blueberry_carpet_buff")
                end
            end

            local function OnFar(inst, player)
                player.hmr_blueberry_carpet_count = math.max((player.hmr_blueberry_carpet_count or 0) - 1, 0)
                if player.hmr_blueberry_carpet_count <= 0 and player.components.debuffable ~= nil then
                    player.components.debuffable:RemoveDebuff("hmr_blueberry_carpet_buff")
                end
            end

            inst:AddComponent("playerprox")
            inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
            inst.components.playerprox:SetDist(3, 3)
            inst.components.playerprox:SetOnPlayerFar(OnFar)
            inst.components.playerprox:SetOnPlayerNear(OnNear)
        end
    }
)



return unpack(FURNITURES)