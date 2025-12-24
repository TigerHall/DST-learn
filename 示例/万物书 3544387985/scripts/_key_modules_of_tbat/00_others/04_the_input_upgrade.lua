--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TheInput = require("input")
if TheInput.__tbat_update_custom_fns then
    return
end
--------------------------------------------------------------------------------------
    TheInput.__tbat_update_custom_fns = {}
    TheInput.__tbat_remove_fn = function(inst)
        TheInput:TBAT_Remove_Update_Custom_Fn(inst)
    end
    function TheInput:TBAT_Add_Update_Custom_Fn(inst,fn,...)
        if inst and type(fn) == "function" then
            self.__tbat_update_custom_fns[inst] = {fn,{...}}
        end
        inst:ListenForEvent("onremove",self.__tbat_remove_fn)
        -- print("TheInput add update modify fn",inst)
    end
    function TheInput:TBAT_Remove_Update_Custom_Fn(inst)
        local new_table = {}
        for k,v in pairs(self.__tbat_update_custom_fns) do
            if k ~= inst then
                new_table[k] = v
            end
        end
        self.__tbat_update_custom_fns = new_table
        inst:RemoveEventCallback("onremove",self.__tbat_remove_fn)
        -- print("TheInput remove update modify fn",inst)
    end

--------------------------------------------------------------------------------------
---
    local old_OnUpdate = TheInput.OnUpdate
    function TheInput:OnUpdate(...)
        if ThePlayer and ThePlayer:IsValid() then
            for inst,_table in pairs(self.__tbat_update_custom_fns) do
                _table[1](inst,unpack(_table[2]))
            end
        end
        return old_OnUpdate(self,...)
    end
--------------------------------------------------------------------------------------
---

    function TBAT:AddInputUpdateFn(inst,fn,...)
        TheInput:TBAT_Add_Update_Custom_Fn(inst,fn,...)
    end
    function TBAT:RemoveInputUpdateFn(inst)
        TheInput:TBAT_Remove_Update_Custom_Fn(inst)
    end

--------------------------------------------------------------------------------------