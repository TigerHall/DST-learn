----------------------------------------------------------------------------------------------------------------------------------
--[[

     TBAT_OnEntityReplicated.
     
     
]]--
----------------------------------------------------------------------------------------------------------------------------------
    STRINGS.ACTIONS.TBAT_COM_ACCEPTABLE_ACTION = STRINGS.ACTIONS.TBAT_COM_ACCEPTABLE_ACTION or {
        DEFAULT = STRINGS.ACTIONS.ADDCOMPOSTABLE
    }
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_acceptable = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}
    self.sg = "give"
    self.str_index = "DEFAULT"
    self.str = ""
end,
nil,
{

})
----------------------------------------------------------------------------------------------------------------------------------
------- distance
    function tbat_com_acceptable:SetDistance(distance)
        self.distance = distance
    end
    function tbat_com_acceptable:GetDistance()
        return self.distance or 0
    end
----------------------------------------------------------------------------------------------------------------------------------
------- test
    function tbat_com_acceptable:SetTestFn(fn)
        if type(fn) == "function" then
            self.Test_Fn = fn
        end
    end

    function tbat_com_acceptable:Test(item,doer,right_click)
        if self.Test_Fn then
            return self.Test_Fn(self.inst,item,doer,right_click)
        end
        return false
    end
----------------------------------------------------------------------------------------------------------------------------------
------ sg
    function tbat_com_acceptable:SetSGAction(sg)
        self.sg = sg
    end
    function tbat_com_acceptable:GetSGAction()
        return self.sg
    end
----------------------------------------------------------------------------------------------------------------------------------
----- text
    function tbat_com_acceptable:SetText(index,str)
        self.str_index = string.upper(index)
        self.str = str
        STRINGS.ACTIONS.TBAT_COM_ACCEPTABLE_ACTION[self.str_index] = str
    end
    function tbat_com_acceptable:GetTextIndex()
        return self.str_index
    end
----------------------------------------------------------------------------------------------------------------------------------
--- DoPreActionFn
    function tbat_com_acceptable:SetPreActionFn(fn)
        if type(fn) == "function" then
            self.__pre_action_fn = fn
        end
    end
    function tbat_com_acceptable:DoPreAction(item,doer)
        if self.__pre_action_fn then
            return self.__pre_action_fn(self.inst,item,doer)
        end
    end
----------------------------------------------------------------------------------------------------------------------------------
return tbat_com_acceptable






