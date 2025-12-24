local PREFABS = {}

local CHAIN_INTERVAL = 0.25
local BASKET_INTERVAL = 1
local ARCH_HEIGHT = 5
local MAX_DISTANCE = 9

local assets =
{
	Asset("ANIM", "anim/yots_lantern_post.zip"),
	Asset("ANIM", "anim/ui_chest_1x1.zip"),
	Asset("ANIM", "anim/reticuledash.zip"),
}

--------------------------------------------------------------------------------------
---[[花拱门拱]]
--------------------------------------------------------------------------------------
local function OnWallUpdate(inst)
	local partner1 = inst._partner1:value()
    local partner2 = inst._partner2:value()
    local num = inst._num:value()

    if partner1 ~= nil and partner2 ~= nil and num ~= nil then
        local x1, y1, z1 = partner1.AnimState:GetSymbolPosition("swap_shackle")
        local x2, y2, z2 = partner2.AnimState:GetSymbolPosition("swap_shackle")

        local interval = inst.prefab == "hmr_flower_arch_chain" and CHAIN_INTERVAL or BASKET_INTERVAL
        local dist = math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
        local total_num = math.floor(dist / interval) + 1
        local spare_lenth = dist - (total_num - 1) * interval

        local lift = math.sin(PI * num / (total_num + 1))
        local x = x1 + (spare_lenth / 2 + (num - 1) * interval) * (x2 - x1) / dist
        local y = y1 + (spare_lenth / 2 + (num - 1) * interval) * (y2 - y1) / dist + lift
        local z = z1 + (spare_lenth / 2 + (num - 1) * interval) * (z2 - z1) / dist
        inst.Transform:SetPosition(x, y, z)
    end
end

local function OnSave(inst, data)
    data.num = inst._num:value()
end

local function OnLoad(inst, data)
    inst._num:set(data and data.num or 0)
end

local function OnLoadPostPass(inst)
	local partner1 = inst.components.entitytracker:GetEntity("partner1")
	local partner2 = inst.components.entitytracker:GetEntity("partner2")

	inst._partner1:set(partner1)
	inst._partner2:set(partner2)

    if partner1 ~= nil and partner2 ~= nil then
        inst:ListenForEvent("onremove", function() inst:ChainOnPartnerRemoved() end, partner1)
        inst:ListenForEvent("onremove", function() inst:ChainOnPartnerRemoved() end, partner2)
    else
        inst:Remove()
    end
end

local function ChainOnPartnerRemoved(inst)
    --inst.AnimState:PlayAnimation("link_1", true)
    inst:Remove()
end

local function chain_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	inst:AddTag("FX")
    inst:AddTag("hmr_flower_arch_chain")

	inst.AnimState:SetBank("yots_lantern_post")
	inst.AnimState:SetBuild("yots_lantern_post")
	inst.AnimState:PlayAnimation("link_"..math.random(1, 2), true)

    inst._partner1 = net_entity(inst.GUID, "chain_partner1")
    inst._partner2 = net_entity(inst.GUID, "chain_partner2")
    inst._num = net_smallbyte(inst.GUID, "chain_num")

    if not TheWorld.ismastersim or not TheNet:IsDedicated() then
        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnWallUpdateFn(OnWallUpdate)
    end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("entitytracker")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnWallUpdate = OnWallUpdate
    inst.ChainOnPartnerRemoved = ChainOnPartnerRemoved

	return inst
end
table.insert(PREFABS, Prefab("hmr_flower_arch_chain", chain_fn, assets))

local function OnItemChanged(inst, data)
    if data.item == nil then
        -- 清空动画
    else

    end
end

local function basket_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("hmr_flower_arch_chain")

    inst.AnimState:SetBank("yots_lantern_post")
	inst.AnimState:SetBuild("yots_lantern_post")
	inst.AnimState:PlayAnimation("lantern", true)

    inst._partner1 = net_entity(inst.GUID, "basket_partner1")
    inst._partner2 = net_entity(inst.GUID, "basket_partner2")
    inst._num = net_smallbyte(inst.GUID, "basket_num")

    if not TheWorld.ismastersim or not TheNet:IsDedicated() then
        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnWallUpdateFn(OnWallUpdate)
    end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("inspectable")

	inst:AddComponent("entitytracker")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("hmr_flower_arch_basket")
    inst:ListenForEvent("itemget", OnItemChanged)
    inst:ListenForEvent("itemlose", OnItemChanged)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnWallUpdate = OnWallUpdate
    inst.ChainOnPartnerRemoved = ChainOnPartnerRemoved

	return inst
end

table.insert(PREFABS, Prefab("hmr_flower_arch_basket", basket_fn, assets))

--------------------------------------------------------------------------------------
---[[花拱门套件]]
--------------------------------------------------------------------------------------
local function OnDeploy(inst, pt, deployer, rot)
    local arch = SpawnPrefab("hmr_flower_arch")
    if arch ~= nil then
        arch.Transform:SetPosition(pt:Get())
        arch.AnimState:PlayAnimation("place")
        arch.AnimState:PushAnimation("idle", true)
        arch:FindPartner()

        inst:Remove()
    end
end

local function item_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("yots_lantern_post")
	inst.AnimState:SetBuild("yots_lantern_post")
	inst.AnimState:PlayAnimation("kit", true)

    inst:AddTag("hmr_flower_arch_item")
    inst:AddTag("eyeturret") --眼球塔的专属标签，但为了deployable组件的摆放名字而使用（显示为“放置”）

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem.imagename = "hmr_chest_factory_core_item"
    -- inst.components.inventoryitem.atlasname = "images/inventoryimages/hmr_chest_factory_core_item.xml"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_dhp_cooked.xml"
    inst.components.inventoryitem.imagename = "honor_dhp_cooked"

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
    inst.components.deployable.ondeploy = OnDeploy

    MakeHauntableLaunch(inst)

    return inst
end

-- placer
local function placer_onupdatetransform(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, MAX_DISTANCE, {"hmr_flower_arch"})

	local target=nil
	local dist = 99999

    if #ents > 0 then
        for _, ent in pairs(ents) do
            local entdist = ent:GetDistanceSqToInst(inst)
            if ent ~= inst and entdist < dist and not ent._partner:value() then
                target = ent
                dist = entdist
            end
        end
    end

	if inst.line then
		if target then
			local tx,ty,tz = target.Transform:GetWorldPosition()
			inst.line.Transform:SetRotation(inst:GetAngleToPoint(tx,ty,tz))
			inst.line:Show()

			local chunk = 0.73
			local num = math.floor(math.sqrt(dist)/chunk)

			for i=1, 13 do
				if i > num +1 then
					inst.line.AnimState:Hide("target"..i)
				else
					inst.line.AnimState:Show("target"..i)
				end
			end
		else
			inst.line:Hide()
		end
	end
end

local function placer_postinit_fn(inst)
	inst.components.placer.onupdatetransform = placer_onupdatetransform

	local function makeline()
		local l = CreateEntity()

	    --[[Non-networked entity]]
	    l.entity:SetCanSleep(false)
	    l.persists = false

	    l.entity:AddTransform()
	    l.entity:AddAnimState()

	    l:AddTag("CLASSIFIED")
	    l:AddTag("NOCLICK")
	    l:AddTag("placer")

	    l.AnimState:SetBank("reticuledash")
	    l.AnimState:SetBuild("reticuledash")
	    l.AnimState:PlayAnimation("idle")
	    l.AnimState:SetLightOverride(1)
		l.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

	    l.entity:SetParent(inst.entity)

	    l:Hide()

	    return l
	end

	inst.line = makeline()
end

table.insert(PREFABS, Prefab("hmr_flower_arch_item", item_fn, assets))
table.insert(PREFABS, MakePlacer("hmr_flower_arch_item_placer", "yots_lantern_post", "yots_lantern_post", "placer", nil, nil, nil, nil, nil, nil, placer_postinit_fn))

--------------------------------------------------------------------------------------
---[[花拱门柱子]]
--------------------------------------------------------------------------------------
local function OnWorked(inst, worker, workleft, numworks)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")

	inst.SoundEmitter:KillSound("vibrate_loop")
	inst.SoundEmitter:KillSound("chain_vibrate_loop")
end

local function OnWorkFinished(inst, worker)
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")

    inst:Remove()
end

local function SpawnChain(partner1, partner2)
    local dist = math.sqrt(partner1:GetDistanceSqToInst(partner2))
    local chain_num = math.floor(dist / CHAIN_INTERVAL) + 1
    local basket_num = math.floor(dist / BASKET_INTERVAL) + 1

    local x1, y1, z1 = partner1.Transform:GetWorldPosition()
    local x2, y2, z2 = partner2.Transform:GetWorldPosition()

    for i = 1, chain_num do
        local chain = SpawnPrefab("hmr_flower_arch_chain")
        chain.components.entitytracker:TrackEntity("partner1", partner1)
        chain.components.entitytracker:TrackEntity("partner2", partner2)
        chain._partner1:set(partner1)
        chain._partner2:set(partner2)
        chain._num:set(i)

        local total_num = math.floor(dist / CHAIN_INTERVAL) + 1
        local spare_lenth = dist - (total_num - 1) * CHAIN_INTERVAL

        local lift = math.sin(PI * i / (total_num + 1))
        local x = x1 + (spare_lenth / 2 + (i - 1) * CHAIN_INTERVAL) * (x2 - x1) / dist
        local y = ARCH_HEIGHT + lift
        local z = z1 + (spare_lenth / 2 + (i - 1) * CHAIN_INTERVAL) * (z2 - z1) / dist
        chain.Transform:SetPosition(x, y, z)

        chain:ListenForEvent("onremove", function() chain:ChainOnPartnerRemoved() end, partner1)
        chain:ListenForEvent("onremove", function() chain:ChainOnPartnerRemoved() end, partner2)
    end

    for i = 1, basket_num do
        local basket = SpawnPrefab("hmr_flower_arch_basket")
        basket.components.entitytracker:TrackEntity("partner1", partner1)
        basket.components.entitytracker:TrackEntity("partner2", partner2)
        basket._partner1:set(partner1)
        basket._partner2:set(partner2)
        basket._num:set(i)

        local total_num = math.floor(dist / BASKET_INTERVAL) + 1
        local spare_lenth = dist - (total_num - 1) * BASKET_INTERVAL

        local lift = math.sin(PI * i / (total_num + 1))
        local x = x1 + (spare_lenth / 2 + (i - 1) * BASKET_INTERVAL) * (x2 - x1) / dist
        local y = ARCH_HEIGHT + lift
        local z = z1 + (spare_lenth / 2 + (i - 1) * BASKET_INTERVAL) * (z2 - z1) / dist
        basket.Transform:SetPosition(x, y, z)

        basket:ListenForEvent("onremove", function() basket:ChainOnPartnerRemoved() end, partner1)
        basket:ListenForEvent("onremove", function() basket:ChainOnPartnerRemoved() end, partner2)
    end
end

local function OnPartnerRemoved(inst)
    inst._partner:set(false)
    inst.components.entitytracker:ForgetEntity("partner")
end

local function FindPartner(inst)
    local target = nil
    local dist = 99999

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, MAX_DISTANCE, {"hmr_flower_arch"})
    if #ents > 0 then
        for _, ent in ipairs(ents) do
            local entdist = ent:GetDistanceSqToInst(inst)
            if ent ~= inst and entdist < dist and not ent._partner:value() then
                target = ent
                dist = entdist
            end
        end
    end

    if target ~= nil then
        inst.components.entitytracker:TrackEntity("partner", target)
        inst._partner:set(true)
        target._partner:set(true)
        inst:ListenForEvent("onremove", function() inst:OnPartnerRemoved() end, target)
        target:ListenForEvent("onremove", function() target:OnPartnerRemoved() end, inst)
        SpawnChain(inst, target)
    end
end

local function PostOnLoadPostPass(inst)
    if inst.components.entitytracker:GetEntity("partner") ~= nil then
        inst._partner:set(true)
        inst:ListenForEvent("onremove", function() inst:OnPartnerRemoved() end, inst.components.entitytracker:GetEntity("partner"))
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .25)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES) --for ocean to block boats

	inst.AnimState:SetBank("yots_lantern_post")
	inst.AnimState:SetBuild("yots_lantern_post")
	inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("hmr_flower_arch")

    inst._partner = net_bool(inst.GUID, "net_partner")
    inst._partner:set(false)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnWorkCallback(OnWorked)
	inst.components.workable:SetOnFinishCallback(OnWorkFinished)

	inst:AddComponent("lootdropper")

	inst:AddComponent("entitytracker")

	-- inst:ListenForEvent("onbuilt", OnBuilt)
	-- inst:ListenForEvent("onremove", OnRemove)

    inst.FindPartner = FindPartner
    inst.OnPartnerRemoved = OnPartnerRemoved
    inst.OnLoadPostPass = PostOnLoadPostPass

	return inst
end

table.insert(PREFABS, Prefab("hmr_flower_arch", fn, assets))


return unpack(PREFABS)