-- 天体科技削弱
AddRecipePostInit("moonrockidol", function(inst)
    -- table.insert(inst.ingredients, Ingredient("shadowheart", 1))
    table.insert(inst.ingredients, Ingredient("opalpreciousgem", 1))
end)

local monsters = {"crawlingnightmare", "nightmarebeak", "oceanhorror2hm"}
local function CallTeamMonster(inst, doer)
    local x, y, z = inst.Transform:GetWorldPosition()
    for index, monster in ipairs(monsters) do
        local shadow = SpawnPrefab(monster)
        shadow.Transform:SetPosition(x, y, z)
    end
end

-- 作祟触发暗影门
local function OnHaunt(inst, haunter)
    -- 强制设置为暗影形态（模拟月黑状态）
    if not inst:HasTag("shadowdoor2hm") then
        inst.AnimState:SetMultColour(0, 0, 0, 0.5)
        inst:AddTag("shadowdoor2hm")
        inst:RemoveComponent("hauntable")
        inst:RemoveTag("resurrector")
        return true
    end
end

local function resetfrommoonphase(inst, moonphase, disablesg)
    if moonphase == "new" and not inst.components.persistent2hm.data.hasshadowheart then
        inst.AnimState:SetMultColour(0, 0, 0, 0.5)
        inst:AddTag("shadowdoor2hm")
        inst:RemoveComponent("hauntable")
        inst:RemoveTag("resurrector")
        if not disablesg then inst.sg:GoToState("spawn_pre", true) end
    elseif moonphase ~= "new" and inst:HasTag("shadowdoor2hm") then
        inst.AnimState:SetMultColour(1, 1, 1, 1)
        inst:RemoveTag("shadowdoor2hm")
        if not inst.components.hauntable and GetPortalRez() then
            inst:AddComponent("hauntable")
            inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
            inst:AddTag("resurrector")
            inst.components.hauntable:SetOnHauntFn(OnHaunt)
        end
        if not disablesg then inst.sg:GoToState("spawn_pre", true) end
    end
end

local function onrepairedmultiplayer(inst, v, doer, item)
    if inst.components.persistent2hm.data.hasshadowheart or not inst:HasTag("shadowdoor2hm") then return false end
    inst.components.persistent2hm.data.hasshadowheart = true
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst:RemoveTag("shadowdoor2hm")
    if not inst.components.hauntable and GetPortalRez() then
        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
        inst:AddTag("resurrector")
    end
    inst:RemoveComponent("repairable2hm")
    CallTeamMonster(inst, doer)
    inst.sg:GoToState("spawn_pre", true)
    if item and item:IsValid() and item.components.stackable then item.components.stackable:Get(1):Remove() end
    return true
end


local function processpersistentmultiplayer(inst)
    if not inst.components.persistent2hm.data.hasshadowheart then
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.customrepair = onrepairedmultiplayer
        if TheWorld:HasTag("cave") then
            inst.AnimState:SetMultColour(0, 0, 0, 0.5)
            inst:AddTag("shadowdoor2hm")
            inst:RemoveComponent("hauntable")
            inst:RemoveTag("resurrector")
        else
            inst:WatchWorldState("moonphase", resetfrommoonphase)
            resetfrommoonphase(inst, TheWorld.state.moonphase, true)
        end
        if inst.components.moontrader then
            local oldcanaccept = inst.components.moontrader.canaccept
            inst.components.moontrader:SetCanAcceptFn(function(inst, ...)
                if inst:HasTag("shadowdoor2hm") then return false, "NOMOON" end
                return oldcanaccept(inst, ...)
            end)
        end
        if inst.components.hauntable then inst.components.hauntable:SetOnHauntFn(OnHaunt) end
    end
end


AddPrefabPostInit("multiplayer_portal", function(inst)
    inst.repairtext2hm = "PURIFY"
    inst.repairmaterials2hm = {opalpreciousgem = 0}
    if not TheWorld.ismastersim then return end
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    processpersistentmultiplayer(inst)
end)


AddComponentPostInit("constructionplans", function(self)
    local oldStartConstruction = self.StartConstruction
    self.StartConstruction = function(self, target, ...)
        if target and target.prefab == "multiplayer_portal" and
           not (target.components and target.components.persistent2hm and target.components.persistent2hm.data.hasshadowheart) then
            if not target:HasTag("shadowdoor2hm") then
                target.AnimState:SetMultColour(0, 0, 0, 0.5)
                target:AddTag("shadowdoor2hm")
                target:RemoveComponent("hauntable")
                target:RemoveTag("resurrector")
                target.sg:GoToState("spawn_pre", true)
            end
            return nil, "MISMATCH"
        end
        return oldStartConstruction(self, target, ...)
    end
end)

-- 猴岛修理
local function onrepairedmonkeyisland(inst, v, doer, item)
    if inst.components.persistent2hm.data.hasshadowheart then return false end
    inst.components.persistent2hm.data.hasshadowheart = true
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst:RemoveTag("shadowdoor2hm")
    inst:RemoveComponent("repairable2hm")
    CallTeamMonster(inst, doer)
    return true
end

local function processpersistentmonkeyisland(inst)
    if not inst.components.persistent2hm.data.hasshadowheart then
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.onrepaired = onrepairedmonkeyisland
        inst.AnimState:SetMultColour(0, 0, 0, 0.5)
        inst:AddTag("shadowdoor2hm")
        if inst.components.trader then
            local oldabletoaccepttest = inst.components.trader.abletoaccepttest
            inst.components.trader:SetAbleToAcceptTest(function(inst, ...)
                if inst:HasTag("shadowdoor2hm") then return false, "BUSY" end
                return oldabletoaccepttest(inst, ...)
            end)
        end
    end
end

AddPrefabPostInit("monkeyisland_portal", function(inst)
    inst.repairtext2hm = "PURIFY"
    inst.repairmaterials2hm = {opalpreciousgem = 0}
    if not TheWorld.ismastersim then return end
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    inst:DoTaskInTime(0, processpersistentmonkeyisland)
end)
STRINGS.ACTIONS.REPAIR2HM.PURIFY = TUNING.isCh2hm and "净化" or "purify"

if GetModConfigData("moonrockidol") ~= -1 then
    local ex_fns = require "prefabs/player_common_extensions"
    local GivePlayerStartingItems = ex_fns.GivePlayerStartingItems
    local function delayGive(inst, items, starting_item_skins, ...)
        if inst.userid and inst.prefab and TheWorld then
            TheWorld.components.persistent2hm.data.startinvusers = TheWorld.components.persistent2hm.data.startinvusers or {}
            TheWorld.components.persistent2hm.data.startinvusers[inst.userid] = TheWorld.components.persistent2hm.data.startinvusers[inst.userid] or {}
            if not TheWorld.components.persistent2hm.data.startinvusers[inst.userid][inst.prefab] then
                TheWorld.components.persistent2hm.data.startinvusers[inst.userid][inst.prefab] = true
                if GetModConfigData("entergift upgrade") then
                    require("entergift2hm")(inst)
                end
                GivePlayerStartingItems(inst, items, starting_item_skins, ...)
            end
        end
    end
    ex_fns.GivePlayerStartingItems = function(inst, items, starting_item_skins, ...)
        if inst.starting_inventory == items then
            inst:DoTaskInTime(0, delayGive, items, starting_item_skins, ...)
        else
            GivePlayerStartingItems(inst, items, starting_item_skins, ...)
        end
    end
end
if GetModConfigData("entergift upgrade") then
    -- 通用物品（所有季节相同）
    local common_items = {
        "cutgrass", "cutgrass", "cutgrass", "cutgrass", "cutgrass", 
        "cutgrass", "cutgrass", "cutgrass", "cutgrass", "cutgrass",
        "cutgrass", "cutgrass", "cutgrass", "cutgrass", "cutgrass", 
        "cutgrass", "cutgrass", "cutgrass", "cutgrass", "cutgrass",
        "log", "log", "log", "log", "log", "log", "log", "log", "log", "log",
        "twigs", "twigs", "twigs", "twigs", "twigs", 
        "twigs", "twigs", "twigs", "twigs", "twigs", 
        "flint"
    }
    TUNING.EXTRA_STARTING_ITEMS = 
    {
        autumn = common_items,
        winter = common_items,
        spring = common_items,
        summer = common_items,
    }

    TUNING.SEASONAL_STARTING_ITEMS = 
	{
        autumn = { },
        winter = { "beefalohat","heatrock"},
        spring = { "raincoat" },
        summer = { "hawaiianshirt","heatrock"},
    }    
end
