local Constructor = require("aab_utils/constructor")
local Utils = require("aab_utils/utils")
AAB_AddCharacterRecipe("aab_changerole_moonrockidol", { Ig("rocks", 2), Ig("flint", 2), Ig("goldnugget", 2) }, {
    product = "moonrockidol",
    image = "moonrockidol.tex"
})

----------------------------------------------------------------------------------------------------

local function Init(inst)
    local item = SpawnPrefab("multiplayer_portal_moonrock_constr_plans")
    item.components.constructionplans:StartConstruction(inst)
    item:Remove()
end

AddPrefabPostInit("multiplayer_portal", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Init)
end)

----------------------------------------------------------------------------------------------------
local function Init2(inst)
    local item = SpawnPrefab("moonrocknugget")
    item.components.stackable.stacksize = 20
    inst.components.constructionsite:OnConstruct(AllPlayers[1] or inst, { item, SpawnPrefab("purplemooneye") })
end

AddPrefabPostInit("multiplayer_portal_moonrock_constr", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Init2)
end)

----------------------------------------------------------------------------------------------------

Constructor.AddAction({}, "AAB_CHANGE_ROLE", AAB_L("Change Role", "更换角色"), function(act)
    local portal = TheWorld._aab_multiplayer_portal
    if not portal then
        for _, v in pairs(Ents) do
            if v.prefab == "multiplayer_portal_moonrock" then
                TheWorld._aab_multiplayer_portal = v
                portal = v
                break
            end
        end
    end
    if not portal then
        --被玩家搞没了
        act.doer.components.talker:Say(AAB_L("No usable celestial portal found.", "没有找到可用的天体传送门。"))
        return false
    end

    TheWorld._aab_changerole_pos = TheWorld._aab_changerole_pos or {}
    TheWorld._aab_changerole_pos[act.doer.userid] = act.doer:GetPosition() --我需要之后能回到这里

    portal.components.moontrader:AcceptOffering(act.doer, act.invobject)
    return true
end, "dochannelaction", "dochannelaction")


AAB_AddComponentAction("INVENTORY", "moonrelic", function(inst, doer, actions, right)
    if not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) then
        table.insert(actions, ACTIONS.AAB_CHANGE_ROLE)
    end
end)

----------------------------------------------------------------------------------------------------

local function SpawnAtLocationBefore(self, inst, player, x, y, z, ...)
    local pos = TheWorld._aab_changerole_pos and TheWorld._aab_changerole_pos[player.userid]
    if pos then
        TheWorld._aab_changerole_pos[player.userid] = nil
        return nil, false, { self, inst, player, pos.x, pos.y, pos.z, ... }
    end
end

AddComponentPostInit("playerspawner", function(self)
    Utils.FnDecorator(self, "SpawnAtLocation", SpawnAtLocationBefore)
end)
