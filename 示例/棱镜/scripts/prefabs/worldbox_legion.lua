local prefs = {}
-- local TOOLS_L = require("tools_legion")

--------------------------------------------------------------------------
--[[ 世界容器-云青松容器 ]]
--------------------------------------------------------------------------

local function OnAnyOpenStorage(inst, data)
	if inst.components.container.opencount > 1 then
		--multiple users, make it global to all players now
		inst.Network:SetClassifiedTarget(nil)
	else
		--just one user, only network to that player
		inst.Network:SetClassifiedTarget(data.doer)
	end
end
local function OnAnyCloseStorage(inst, data)
	local opencount = inst.components.container.opencount
	if opencount == 0 then
		--all closed, disable networking
		inst.Network:SetClassifiedTarget(inst)
	elseif opencount == 1 then
		--only one user remaining, only network to that player
		local opener = next(inst.components.container.openlist)
		inst.Network:SetClassifiedTarget(opener)
	end
end
local function MakeWorldBox(data) --这些内容和官方差不多一样的，具体请查看 \prefabs\pocketdimensioncontainers.lua
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()

        if TheWorld.ismastersim then
            inst.entity:AddTransform() --按官方说法，有这个才能实行保存机制
        end
        inst.entity:AddNetwork()
        inst.entity:AddServerNonSleepable()
        inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst:AddTag("CLASSIFIED")
        inst:AddTag("pocketdimension_container")
        inst:AddTag("irreplaceable")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.Network:SetClassifiedTarget(inst)

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(data.name)
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true
        inst.components.container.skipautoclose = true
        inst.components.container.onanyopenfn = OnAnyOpenStorage
        inst.components.container.onanyclosefn = OnAnyCloseStorage

        TheWorld:SetPocketDimensionContainer(data.boxkey, inst)

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, data.prefabs))
end

local function SetPerishRate_pine(inst, item)
    if item ~= nil and (item.foliageath_data ~= nil or item.legiontag_pinebelonger) then --能入鞘的才能保鲜
        return 0
    end
    return inst.perishrate_l or 1 --要是别的mod想改，可以改这个变量
end
local function FnServer_pine(inst)
    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(SetPerishRate_pine)
end

local function SwordRecovery_box4(inst, doer)
    if inst.healtime_l == nil then
        inst.healtime_l = GetTime()
    else
        local dt = inst.healtime_l
        inst.healtime_l = GetTime()
        dt = inst.healtime_l - dt
        if inst.healdt_l ~= nil then
            dt = dt + inst.healdt_l
            inst.healdt_l = nil
        end
        if dt <= 0 then
            return
        end
        for _, v in pairs(inst.components.container.slots) do
            if v ~= nil and (v.foliageath_data ~= nil or v.legiontag_pinebelonger) then
                if v.foliageath_data ~= nil and v.foliageath_data.fn_recover ~= nil then
                    v.foliageath_data.fn_recover(v, dt, doer, "foliageath")
                elseif v.components.perishable ~= nil then
                    local cpt = v.components.perishable
                    if cpt.perishtime and cpt.perishremainingtime and cpt.perishremainingtime < cpt.perishtime then
                        cpt.perishremainingtime = math.min(cpt.perishremainingtime+dt, cpt.perishtime)
                        v:PushEvent("perishchange", {percent = v.components.perishable:GetPercent()})
                    end
                end
            end
        end
    end
end
local function OnOpenStorage_box4(inst, data) -- data = {doer = doer}
    inst.SwordRecovery_l(inst, data and data.doer or nil)
end
local function OnCloseStorage_box4(inst, doer) --官方在干啥，一会用表把 doer 包起来，一会又不包了
    if inst.healtime_l == nil then
        inst.healtime_l = GetTime()
    end
end
local function OnLongUpdate_box4(inst, dt)
    if dt ~= nil and dt > 0 then
        inst.healdt_l = (inst.healdt_l or 0) + dt
    end
end
local function OnSave_box4(inst, data)
    local dt = inst.healdt_l or 0
    if inst.healtime_l ~= nil then
        dt = GetTime() - inst.healtime_l + dt
    end
    if dt > 0 then
        data.healdt = dt
    end
end
local function OnLoad_box4(inst, data)
    if data ~= nil then
        if data.healdt ~= nil then
            inst.healdt_l = data.healdt
        end
    end
end

MakeWorldBox({
    name = "cloudpine_box_l1", boxkey = "cloudpine_l1",
    assets = {
        Asset("ANIM", "anim/ui_bookstation_4x5.zip"),
        Asset("ANIM", "anim/ui_cloudpine_box_4x1.zip")
    },
    fn_server = FnServer_pine
})
MakeWorldBox({
    name = "cloudpine_box_l2", boxkey = "cloudpine_l2",
    assets = {
        Asset("ANIM", "anim/ui_bookstation_4x5.zip"),
        Asset("ANIM", "anim/ui_cloudpine_box_4x3.zip")
    },
    fn_server = FnServer_pine
})
MakeWorldBox({
    name = "cloudpine_box_l3", boxkey = "cloudpine_l3",
    assets = {
        Asset("ANIM", "anim/ui_bookstation_4x5.zip"),
        Asset("ANIM", "anim/ui_cloudpine_box_4x6.zip")
    },
    fn_server = FnServer_pine
})
MakeWorldBox({
    name = "cloudpine_box_l4", boxkey = "cloudpine_l4",
    assets = {
        Asset("ANIM", "anim/ui_bookstation_4x5.zip"),
        Asset("ANIM", "anim/ui_cloudpine_box_4x6.zip")
    },
    fn_server = function(inst)
        FnServer_pine(inst)

        inst.SwordRecovery_l = SwordRecovery_box4
        inst.components.container.onopenfn = OnOpenStorage_box4
        inst.components.container.onclosefn = OnCloseStorage_box4

        inst.OnLongUpdate = OnLongUpdate_box4
        inst.OnSave = OnSave_box4
        inst.OnLoad = OnLoad_box4
    end
})

--------------------
--------------------

return unpack(prefs)
