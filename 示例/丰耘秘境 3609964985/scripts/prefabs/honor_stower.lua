require("components/deployhelper") -- TriggerDeployHelpers lives here

local assets =
{
	Asset("ANIM", "anim/honor_stower_spellbook.zip"),
	Asset("ANIM", "anim/honor_stower.zip"),
}

local RANGE = 12
local RETICULE_PREFAB = "reticuleaoe_1d2_12"
local PING_PREFAB = "reticuleaoeping_1d2_12"
--------------------------------------------------------------------------
local function StartAOETargeting(inst)
	local playercontroller = ThePlayer.components.playercontroller
	if playercontroller ~= nil then
		playercontroller:StartAOETargetingUsing(inst)
	end
end

local function Takecare(inst, doer, pos)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, RANGE, {"honor_tower"})
	local honor_towers = {}
	for _, ent in ipairs(ents) do
		if ent:HasTag("honor_tower") then
			table.insert(honor_towers, ent)
		end
	end

	local tag = false
	if #honor_towers > 0 then
		for _, tower in ipairs(honor_towers) do
			if tower.DoTakecare then
				tower:DoTakecare(inst, doer)
				tag = true
			end
		end
	end
	return tag
end

local function Harvest(inst, doer, pos)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, RANGE, {"honor_tower"})
	local honor_towers = {}
	for _, ent in ipairs(ents) do
		if ent:HasTag("honor_tower") then
			table.insert(honor_towers, ent)
		end
	end

	local tag = false
	if #honor_towers > 0 then
		for _, tower in ipairs(honor_towers) do
			if tower.DoHarvest then
				tower:DoHarvest(inst, doer)
				tag = true
			end
		end
	end
	return tag
end

local function Harm(inst, doer, pos)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, RANGE, {"honor_tower"}) -- 替换 "指定标签" 为实际标签
	local honor_towers = {}
	for _, ent in ipairs(ents) do
		if ent:HasTag("honor_tower") then
			table.insert(honor_towers, ent)
		end
	end

	local tag = false
	if #honor_towers > 0 then
		for _, tower in ipairs(honor_towers) do
			if tower.DoHarm then
				tower:DoHarm(inst, doer)
				tag = true
			end
		end
	end
	return tag
end

local function Store(inst, doer, pos)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, RANGE, {"honor_tower"}) -- 替换 "指定标签" 为实际标签
	local honor_towers = {}
	for _, ent in ipairs(ents) do
		if ent:HasTag("honor_tower") then
			table.insert(honor_towers, ent)
		end
	end

	local tag = false
	if #honor_towers > 0 then
		for _, tower in ipairs(honor_towers) do
			if tower.DoStore then
				tower:DoStore(inst, doer)
				tag = true
			end
		end
	end
	return tag
end

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2

local function ReticuleTargetAllowWaterFn()
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	--Cast range is 30, leave room for error
	--15 is the aoe range
	for r = 10, 0, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos.x, 0, pos.z, true) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end

local function ShouldRepeatCast(inst, doer)
    return not inst:HasTag("usesdepleted")
end

local function PingTower(inst, doer, pos, catapult)
    local ping = SpawnPrefab("reticuleaoewinonaengineeringping")
    ping.Transform:SetPosition(catapult.Transform:GetWorldPosition())
    ping.Transform:SetRotation(catapult.Transform:GetRotation())

    ping.AnimState:SetMultColour(math.min(1, 0x6e/255+0.25), math.min(1, 0x60/255+0.75), math.min(1, 0x45/255+0.25), 1)
    ping.AnimState:SetAddColour(0.2, 0.2, 0.2, 0)

    return true
end

local TOWER_TAGS = {"honor_tower"}
local TOWER_NO_TAGS = { "burnt" }

local function ForEachCatapult(inst, doer, pos, fn)
	local success = false
	for i, v in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, RANGE, TOWER_TAGS, TOWER_NO_TAGS)) do
		if fn(inst, doer, pos, v) then
			success = true
		end
	end
	return success
end

local function UpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    reticule.Transform:SetPosition(pos:Get())
    if reticule.prefab == "reticuleaoecatapultwakeupping" then
        ForEachCatapult(inst, nil, pos, PingTower)
    else
        TriggerDeployHelpers(pos.x, 0, pos.z, 12, nil, reticule)
    end
end

local SPELLS =
{
	{
		label = STRINGS.HMR.HONOR_STOWER.TAKECARE,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.VOLLEY)
            inst.components.spellbook:SetSpellAction(nil)
            inst.components.aoetargeting:SetDeployRadius(0)
            inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
            inst.components.aoetargeting.reticule.reticuleprefab = RETICULE_PREFAB
            inst.components.aoetargeting.reticule.pingprefab = PING_PREFAB
            inst.components.aoetargeting.reticule.updatepositionfn = UpdatePositionFn
            if TheWorld.ismastersim then
                inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.aoespell:SetSpellFn(Takecare)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = StartAOETargeting,
		bank = "honor_stower_spellbook",
		build = "honor_stower_spellbook",
		anims =
		{
			idle = { anim = "icon_takecare" },
			focus = { anim = "icon_takecare_focus", loop = true },
			down = { anim = "icon_takecare_pressed" }
		},
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
	{
		label = STRINGS.HMR.HONOR_STOWER.HARVEST,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.VOLLEY)
            inst.components.spellbook:SetSpellAction(nil)
            inst.components.aoetargeting:SetDeployRadius(0)
            inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
            inst.components.aoetargeting.reticule.reticuleprefab = RETICULE_PREFAB
            inst.components.aoetargeting.reticule.pingprefab = PING_PREFAB
            inst.components.aoetargeting.reticule.updatepositionfn = UpdatePositionFn
            if TheWorld.ismastersim then
                inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.aoespell:SetSpellFn(Harvest)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = StartAOETargeting,
		bank = "honor_stower_spellbook",
		build = "honor_stower_spellbook",
		anims =
		{
			idle = { anim = "icon_harvest" },
			focus = { anim = "icon_harvest_focus", loop = true },
			down = { anim = "icon_harvest_pressed" }
		},
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
	{
		label = STRINGS.HMR.HONOR_STOWER.HARM,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.VOLLEY)
            inst.components.spellbook:SetSpellAction(nil)
            inst.components.aoetargeting:SetDeployRadius(0)
            inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
            inst.components.aoetargeting.reticule.reticuleprefab = RETICULE_PREFAB
            inst.components.aoetargeting.reticule.pingprefab = PING_PREFAB
            inst.components.aoetargeting.reticule.updatepositionfn = UpdatePositionFn
            if TheWorld.ismastersim then
                inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.aoespell:SetSpellFn(Harm)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = StartAOETargeting,
		bank = "honor_stower_spellbook",
		build = "honor_stower_spellbook",
		anims =
		{
			idle = { anim = "icon_harm" },
			focus = { anim = "icon_harm_focus", loop = true },
			down = { anim = "icon_harm_pressed" }
		},
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
	{
		label = STRINGS.HMR.HONOR_STOWER.STORE,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.VOLLEY)
            inst.components.spellbook:SetSpellAction(nil)
            inst.components.aoetargeting:SetDeployRadius(0)
            inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
            inst.components.aoetargeting.reticule.reticuleprefab = RETICULE_PREFAB
            inst.components.aoetargeting.reticule.pingprefab = PING_PREFAB
            inst.components.aoetargeting.reticule.updatepositionfn = UpdatePositionFn
            if TheWorld.ismastersim then
                inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.aoespell:SetSpellFn(Store)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = StartAOETargeting,
		bank = "honor_stower_spellbook",
		build = "honor_stower_spellbook",
		anims =
		{
			idle = { anim = "icon_store" },
			focus = { anim = "icon_store_focus", loop = true },
			down = { anim = "icon_store_pressed" },
		},
		clicksound = "meta4/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
}

local SPELLBOOK_BG =--按下遥控器后展示的界面
{
	bank = "honor_stower_spellbook",
	build = "honor_stower_spellbook",
	anim = "dpad",
	widget_scale = ICON_SCALE,
}

local function onfinished(inst)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_stower")
    inst.AnimState:SetBuild("honor_stower")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:OverrideSymbol("wire", "honor_stower", "dummy")

    inst:AddTag("remotecontrol")
    inst:AddTag("engineering")
    inst:AddTag("engineeringbatterypowered")

    MakeInventoryFloatable(inst, "small", 0.14, { 1.1, 1.15, 1 })

    inst:AddComponent("spellbook")
    --inst.components.spellbook:SetRequiredTag("portableengineer")--设置使用者必须拥有的标签
    inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)--设置法术轮的半径。
    inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)--设置法术轮的焦点半径。
    inst.components.spellbook:SetItems(SPELLS)--设置法术书中的项目
    inst.components.spellbook:SetBgData(SPELLBOOK_BG)-- 设置背景数据
    -- 设置法术书的声音
    inst.components.spellbook.opensound = "meta4/winona_UI/open"
    inst.components.spellbook.closesound = "meta4/winona_UI/close"
    inst.components.spellbook.focussound = "meta4/winona_UI/hover"

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAllowWater(true)
	inst.components.aoetargeting:SetRange(20)
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetAllowWaterFn
	inst.components.aoetargeting.reticule.validcolour = { 0x33/255, 0x66/255, 0xFF/255, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { 0.5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.reticule.twinstickmode = 1
	inst.components.aoetargeting.reticule.twinstickrange = 20

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 设置手持动画
    inst.swap_build = "honor_stower"

    -- 添加更新循环组件
    inst:AddComponent("updatelooper")
    inst:AddComponent("colouradder")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_stower.xml"
    inst.components.inventoryitem.imagename = "honor_stower"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(500)
    inst.components.finiteuses:SetUses(500)
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("aoespell")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("honor_stower", fn, assets)
