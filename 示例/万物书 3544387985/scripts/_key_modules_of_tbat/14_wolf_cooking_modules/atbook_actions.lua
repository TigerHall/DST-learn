local cooking = require("cooking")

-- 小狼大厨 点菜
local ATBOOK_ORDER = Action({ priority = 5 })
ATBOOK_ORDER.id = "ATBOOK_ORDER"
ATBOOK_ORDER.str = "点菜"
ATBOOK_ORDER.fn = function(act)
    local doer = act.doer
    local target = act.target

    if doer and target then
        local foods = {}
        local x, y, z = target.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 20, nil, {"LIMBO"})
        for _, ent in ipairs(ents) do
            if not ent.components.inventoryitem and ent.components.container then
                for k,v in pairs(ent.components.container.slots) do
                    if v ~= nil and v.prefab and cooking.ingredients[v.prefab] then
                        local num_found = 1
                        if v.components.stackable ~= nil then
                            num_found = v.components.stackable:StackSize()
                        end
                        if foods[v.prefab] then
                            foods[v.prefab] = math.min(40, foods[v.prefab] + num_found)
                        else
                            foods[v.prefab] = math.min(40, num_found)
                        end
                    end
                end
            end
        end
        SendModRPCToClient(CLIENT_MOD_RPC["ATBOOK"]["chefwolfwidget"], doer.userid, target, true, ZipAndEncodeString(foods))
    end

    return true
end
AddAction(ATBOOK_ORDER)
AddStategraphActionHandler("wilson", ActionHandler(ATBOOK_ORDER, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ATBOOK_ORDER, "give"))

AddComponentAction("SCENE", "atbook_ordermachine", function(inst, doer, actions, right)
    if right then
        table.insert(actions, ACTIONS.ATBOOK_ORDER)
    end
end)

--- 荡秋千
local ATBOOK_SITSWING = Action({ priority = 2, encumbered_valid = true })
ATBOOK_SITSWING.id = "ATBOOK_SITSWING"
ATBOOK_SITSWING.str = "坐上"
ATBOOK_SITSWING.fn = function(act)
    if act.doer and act.target then
        if act.target == "atbook_swing" and act.target:HasTag("isusing") then
            if act.doer.components.talker then
                act.doer.components.talker:Say("这个位置已经有人啦")
            end
            return true
        end
        act.doer.sg:GoToState("atbook_sitswing")
        return true
    end
end

AddAction(ATBOOK_SITSWING)

AddComponentAction("SCENE", "atbook_swing", function(inst, doer, actions, right)
    if right and not inst:HasTag("isusing") then
        table.insert(actions, ACTIONS.ATBOOK_SITSWING)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ATBOOK_SITSWING, nil))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ATBOOK_SITSWING, nil))

--- 坐沙发
local ATBOOK_SOFA = Action({ priority = 99, encumbered_valid = true })
ATBOOK_SOFA.id = "ATBOOK_SOFA"
ATBOOK_SOFA.str = "坐下"
ATBOOK_SOFA.fn = function(act)
    if act.doer and act.target then
        if act.target == "atbook_sofa" and act.target:HasTag("isusing") then
            if act.doer.components.talker then
                act.doer.components.talker:Say("这个位置已经有人啦")
            end
            return true
        end
        act.doer.sg:GoToState("atbook_sitsofa")
        return true
    end
end

AddAction(ATBOOK_SOFA)

AddComponentAction("SCENE", "atbook_sofa", function(inst, doer, actions, right)
    if not inst:HasTag("isusing") then
        table.insert(actions, ACTIONS.ATBOOK_SOFA)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ATBOOK_SOFA, nil))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ATBOOK_SOFA, nil))

--- 阅读
local ATBOOK_WIKI = Action({ priority = 2, encumbered_valid = true })
ATBOOK_WIKI.id = "ATBOOK_WIKI"
ATBOOK_WIKI.str = "阅读"
ATBOOK_WIKI.fn = function(act)
    if act.doer then
        SendModRPCToClient(CLIENT_MOD_RPC["ATBOOK"]["atbook_wiki"], act.doer.userid, true)
        return true
    end
end

AddAction(ATBOOK_WIKI)

AddComponentAction("SCENE", "atbook_wiki", function(inst, doer, actions, right)
    if not right and inst:HasTag("atbook_wiki_place") then
        table.insert(actions, ACTIONS.ATBOOK_WIKI)
    end
end)

AddComponentAction("INVENTORY", "atbook_wiki", function(inst, doer, actions)
    table.insert(actions, ACTIONS.ATBOOK_WIKI)
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ATBOOK_WIKI, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ATBOOK_WIKI, "give"))