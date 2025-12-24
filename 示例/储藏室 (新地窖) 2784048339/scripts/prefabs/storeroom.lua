require "prefabutil"

local assets_regular =
{
	Asset("ANIM", "anim/storeroom_upgraded.zip"),
}

local prefabs_regular =
{
	"collapse_big",
	"chestupgrade_stacksize_fx",
	"alterguardianhatshard",
	"collapsed_treasurechest",
}

local function NoWorked(inst, worker)
    if worker ~= nil and (worker:HasTag("player") or worker.components.walkableplatform ~= nil) then
        return false
    end
    return true
end

local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
	inst.AnimState:PlayAnimation("open")
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
	inst.AnimState:PlayAnimation("closed")
end

local function onhammered(inst, worker)
	if TUNING.STOREROOM_DESTROY == "DestroyByPlayer" then
		if NoWorked(inst, worker) then	--不是玩家锤的则不掉出物品
			inst.components.workable:SetWorkLeft(5)
			return
		end
	end
	inst.components.lootdropper:DropLoot()
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
	end
	local fx = SpawnPrefab("collapse_big")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("closed")
	
	if inst.components.container then
		inst.components.container:Close()	--被打击时容器关闭
		if TUNING.STOREROOM_DESTROY == "DestroyByPlayer" then
			if NoWorked(inst, worker) then	--不是玩家打击的则不掉出物品
				inst.components.workable:SetWorkLeft(5)
				return
			end
		end
		
		inst.components.container:DropEverything(nil, true)
	end
end

local function onbuilt(inst)	--建成时动画
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    if inst.skin_place_sound then
        inst.SoundEmitter:PlaySound(inst.skin_place_sound)
    else
        inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
    end
end

local function OnSnowCoveredChagned_sr(inst, covered)
    if TheWorld.state.issnowcovered then
        inst.AnimState:OverrideSymbol("snow", "snow", "snow")	--如果是下雪将snow贴图替换成官方贴图
    else
        inst.AnimState:OverrideSymbol("snow", "snow", "emptysnow")	--否则使用emptysnow透明贴图
    end
end

local function MakeChest(name, bank, build, indestructible, master_postinit, prefabs, assets)
	local default_assets =
    {
        Asset("ANIM", "anim/storeroom.zip"),
        Asset("ANIM", "anim/storeroom_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x5.zip"),
		Asset("ANIM", "anim/ui_storeroom_6x6.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x8.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x12.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x16.zip"),
		Asset("ANIM", "anim/ui_storeroom_6x20.zip"),
		Asset("ANIM", "anim/ui_storeroom_7x20.zip"),
		Asset("ANIM", "anim/ui_storeroom_8x20.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x5_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_6x6_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x8_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x12_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_5x16_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_6x20_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_7x20_upgraded.zip"),
		Asset("ANIM", "anim/ui_storeroom_8x20_upgraded.zip"),
    }
    assets = assets ~= nil and JoinArrays(assets, default_assets) or default_assets
	
	local function fn()
		local inst = CreateEntity()
		
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		inst.MiniMapEntity:SetIcon("storeroom.tex")

		--MakeObstaclePhysics(inst, 1)	--碰撞体积

		inst:AddTag("structure")
		inst:AddTag("chest")
		inst:AddTag("meteor_protection") --防止被流星破坏
		
		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation("closed")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("container")
		inst.components.container:WidgetSetup(name)
		inst.components.container.onopenfn = onopen
		inst.components.container.onclosefn = onclose
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

		inst:AddComponent("lootdropper")

		if TUNING.STOREROOM_DESTROY == "DestroyByAll" or TUNING.STOREROOM_DESTROY == "DestroyByPlayer" then
			inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
			inst.components.workable:SetWorkLeft(5)
			inst.components.workable:SetOnFinishCallback(onhammered)
			inst.components.workable:SetOnWorkCallback(onhit)
		end
		
		--inst:ListenForEvent("onbuilt", onbuilt)	--建造时
		--MakeSnowCovered(inst)	--积雪覆盖
		inst:WatchWorldState("issnowcovered", OnSnowCoveredChagned_sr)	--监听是否下雪 legion
		inst:DoTaskInTime(.1, function(inst)	--建成时也需要判断是否下雪
			OnSnowCoveredChagned_sr(inst)
		end)
		
        if master_postinit ~= nil then	--Make传入有这个参数则可通过弹性空间升级
            master_postinit(inst)
        end

		return inst
	end
	
	return Prefab(name, fn, assets, prefabs)
end

--[[ regular ]]
--------------------------------------------------------------------------

local function regular_getstatus(inst, viewer)
	return inst._chestupgrade_stacksize and "UPGRADED_STACKSIZE" or nil
end

local function upgrade_onhammered(inst, worker)
	if TUNING.STOREROOM_DESTROY == "DestroyByPlayer" then
		if NoWorked(inst, worker) then	--不是玩家锤的则不掉出物品
			inst.components.workable:SetWorkLeft(5)
			return
		end
	end
	--sunk, drops more, but will lose the remainder
	inst.components.lootdropper:DropLoot()
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
	end
	
	inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD)
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
	return
	
	--fallback to default
	--onhammered(inst, worker)
end

local function upgrade_onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("closed", false)
	
	if inst.components.container then
		inst.components.container:Close()	--被锤击、打击时容器关闭
		if TUNING.STOREROOM_DESTROY == "DestroyByPlayer" then
			if NoWorked(inst, worker) then	--不是玩家锤的则不掉出物品
				inst.components.workable:SetWorkLeft(5)
				return
			end
		end
		if not inst.components.container:IsEmpty() then --如果箱子里还有物品，那就不能被破坏
			inst.components.workable:SetWorkLeft(5)
		end
		inst.components.container:DropEverything(nil, true)
	end
end

local function DoUpgradeVisuals(inst)
    inst.AnimState:SetBank("storeroom_upgraded")
    inst.AnimState:SetBuild("storeroom_upgraded")
end

local function OnUpgrade_storeroom(inst, performer, upgraded_from_item)
    local numupgrades = inst.components.upgradeable.numupgrades
    if numupgrades == 1 then
        inst._chestupgrade_stacksize = true
        if inst.components.container ~= nil then -- NOTES(JBK): The container component goes away in the burnt load but we still want to apply builds.
            inst.components.container:Close()
            inst.components.container:EnableInfiniteStackSize(true)
            inst.components.inspectable.getstatus = regular_getstatus
			--对原物品进行转移整理一次
			-- local allitems = inst.components.container:RemoveAllItems()
            -- for _, v in ipairs(allitems) do
                -- inst.components.container:GiveItem(v)
            -- end
        end
		
        if upgraded_from_item then
            -- Spawn FX from an item upgrade not from loads.
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("chestupgrade_stacksize_taller_fx")
            fx.Transform:SetPosition(x, y, z)
            -- Delay chest visual changes to match fx.
            local total_hide_frames = 6 -- NOTES(JBK): Keep in sync with fx.lua! [CUHIDERFRAMES]
            inst:DoTaskInTime(total_hide_frames * FRAMES, DoUpgradeVisuals)
        else
            DoUpgradeVisuals(inst)
        end
    end
    inst.components.upgradeable.upgradetype = nil

    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:SetLoot({ "alterguardianhatshard" })
    end
	if inst.components.workable ~= nil then
		inst.components.workable:SetOnWorkCallback(upgrade_onhit)
		inst.components.workable:SetOnFinishCallback(upgrade_onhammered)
	end
	
	inst:AddTag("storeroom_upgraded")	--添加个升级标签，方便做其他管理
	--inst:ListenForEvent("restoredfromcollapsed", OnRestoredFromCollapsed)
end

local function OnSave_storeroom(inst, data)
    if inst.components.container then
        local items = {}
        for k, v in pairs(inst.components.container.slots) do
            if v and v:IsValid() then
                table.insert(items, {
                    prefab = v.prefab,
                    stacksize = v.components.stackable and v.components.stackable:StackSize() or 1
                })
            end
        end
        data.items = items
    end
end

local function OnLoad_storeroom(inst, data, newents)
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        OnUpgrade_storeroom(inst)
    end
	-- if data and data.items and inst.components.container then
        -- for _, itemdata in ipairs(data.items) do
            -- local item = SpawnPrefab(itemdata.prefab)
            -- if item and item:IsValid() then
                -- if item.components.stackable and itemdata.stacksize then
                    -- item.components.stackable:SetStackSize(itemdata.stacksize)
                -- end
                -- inst.components.container:GiveItem(item)
            -- end
        -- end
    -- end
end

local function regular_SCStoreroom(inst)	--解构后丢出所有物品
	if inst.components.container and inst.components.container.infinitestacksize then
		--NOTE: should already have called DropEverything(nil, true) (worked or burnt or deconstructed)
		--      so everything remaining counts as an "overstack"
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

local function regular_storeroom(inst, caster)	--解构
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper:SpawnLootPrefab("alterguardianhatshard")	--返还启迪碎片
        end
    end

	if regular_SCStoreroom(inst) then
		inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)
	end

	--fallback to default
	inst.no_delete_on_deconstruct = nil
end

----
local function regular_master_postinit(inst)	--fn 的 master_postinit 函数
    local upgradeable = inst:AddComponent("upgradeable")	--弹性升级组件
	upgradeable.upgradetype = UPGRADETYPES.CHEST
	upgradeable:SetOnUpgradeFn(OnUpgrade_storeroom)
	inst:ListenForEvent("ondeconstructstructure", regular_storeroom)	--监听解构
	
	if inst.components.container then
        inst.components.container.ignoreoverstacked = true	--添加这个可以禁用堆叠检查，这样就可以整理了
    end
	
	inst.OnLoad = OnLoad_storeroom
	--inst.OnSave = OnSave_storeroom
end

return MakeChest("storeroom", "storeroom", "storeroom", false, regular_master_postinit, prefabs_regular, assets_regular),
	--Prefab("common/storeroom", fn, assets),
	MakePlacer("storeroom_placer", "storeroom", "storeroom", "closed")