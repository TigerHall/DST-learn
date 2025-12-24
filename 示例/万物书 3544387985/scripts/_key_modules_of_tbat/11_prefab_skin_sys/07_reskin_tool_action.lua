-- require("componentactions")
-- local AddComponentAction = GLOBAL.AddComponentAction


-----------------------------------------------------------------------------------------------------
--- NEXT skin
    local TBAT_RESKIN_ACTION_NEXT = Action({mount_valid = true,distance = 6,priority = 10,show_primary_input_left = true})
    TBAT_RESKIN_ACTION_NEXT.id = "TBAT_RESKIN_ACTION_NEXT"
    TBAT_RESKIN_ACTION_NEXT.strfn = function(act)
        if act.target and act.doer and act.invobject then
            return "NEXT"
        end
        return "NONE"
    end

    TBAT_RESKIN_ACTION_NEXT.fn = function(act)
        if act.invobject and act.doer and act.target and act.invobject.components.tbat_com_skin_tool  then
            act.invobject.components.tbat_com_skin_tool:NextSkin(act.target,act.doer)
            -- print("next ++++++++++")
            return true
        end
    end
    AddAction(TBAT_RESKIN_ACTION_NEXT)

-----------------------------------------------------------------------------------------------------
--- LAST skin
    local TBAT_RESKIN_ACTION_LAST = Action({mount_valid = true,distance = 6,priority = 10,show_secondary_input_right = true})
    TBAT_RESKIN_ACTION_LAST.id = "TBAT_RESKIN_ACTION_LAST"
    TBAT_RESKIN_ACTION_LAST.strfn = function(act)
        if act.target and act.doer and act.invobject then
            return "LAST"
        end
        return "NONE"
    end

    TBAT_RESKIN_ACTION_LAST.fn = function(act)
        if act.invobject and act.doer and act.target and act.invobject.components.tbat_com_skin_tool then
            -- print("last ++++++")
            act.invobject.components.tbat_com_skin_tool:LastSkin(act.target,act.doer)
            return true
        end
    end
    AddAction(TBAT_RESKIN_ACTION_LAST)
-----------------------------------------------------------------------------------------------------

AddComponentAction("EQUIPPED", "tbat_com_skin_tool" , function(inst, doer, target, actions, right)   ---- 这个会在 client 上执行
    if target and target:HasTag("tbat_com_skin_data")  and inst and doer then        
        if not right then
            table.insert(actions, ACTIONS.TBAT_RESKIN_ACTION_NEXT)   
        else
            table.insert(actions, ACTIONS.TBAT_RESKIN_ACTION_LAST)
        end
    end
end,modname)


AddStategraphActionHandler("wilson",ActionHandler(TBAT_RESKIN_ACTION_NEXT,function(inst)
    return "quickcastspell"
end))
AddStategraphActionHandler("wilson_client",ActionHandler(TBAT_RESKIN_ACTION_NEXT, function(inst)
    return "quickcastspell"
end))
AddStategraphActionHandler("wilson",ActionHandler(TBAT_RESKIN_ACTION_LAST,function(inst)
    return "quickcastspell"
end))
AddStategraphActionHandler("wilson_client",ActionHandler(TBAT_RESKIN_ACTION_LAST, function(inst)
    return "quickcastspell"
end))

STRINGS.ACTIONS.TBAT_RESKIN_ACTION_NEXT = {
    ["NONE"] = "",
    ["NEXT"] = "Next",
    ["LAST"] = "Last"
}
STRINGS.ACTIONS.TBAT_RESKIN_ACTION_LAST = {
    ["NONE"] = "",
    ["NEXT"] = "Next",
    ["LAST"] = "Last"
}

---- 挂载动作
-- local action_strings = TUNING["Forward_In_Predicament.fn"].GetStringsTable("tbat_com_skins_tool")
--             ["tbat_com_skins_tool"] = { 
--                 ["NEXT"] = "下一个外观",
--                 ["LAST"] = "上一个外观",
--             },
-- for action_name, str in pairs(action_strings) do
--     STRINGS.ACTIONS.TBAT_RESKIN_ACTION_NEXT["NEXT"] = str
--     STRINGS.ACTIONS.TBAT_RESKIN_ACTION_LAST["LAST"] = str
-- end


-- STRINGS.ACTIONS.TBAT_RESKIN_ACTION_NEXT["NEXT"] = str
-- STRINGS.ACTIONS.TBAT_RESKIN_ACTION_LAST["LAST"] = str