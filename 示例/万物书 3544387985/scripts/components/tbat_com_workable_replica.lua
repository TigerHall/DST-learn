----------------------------------------------------------------------------------------------------------------------------------
--[[

     TBAT_OnEntityReplicated.
     
]]--
----------------------------------------------------------------------------------------------------------------------------------
STRINGS.ACTIONS.TBAT_COM_WORKABLE_ACTION = STRINGS.ACTIONS.TBAT_COM_WORKABLE_ACTION or {
    DEFAULT = STRINGS.ACTIONS.OPEN_CRAFTING.USE
}


local tbat_com_workable = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}

    self.sg = "dolongaction"
    self.str_index = "DEFAULT"
    self.str = "test"

end,
nil,
{

})


--------------------------------------------------------------------------------------------------------------
--- test 函数
    function tbat_com_workable:SetTestFn(fn)
        if type(fn) == "function" then
            self._test_fn = fn
        end
    end

    function tbat_com_workable:Test(doer,right_click)
        if self.inst:HasTag("tbat_com_workable_can_not_work") then
            return false
        end
        if self._test_fn then
            return self._test_fn(self.inst,doer,right_click)
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------
--- DoPreActionFn
    function tbat_com_workable:SetPreActionFn(fn)
        if type(fn) == "function" then
            self.__pre_action_fn = fn
        end
    end
    function tbat_com_workable:DoPreAction(doer)
        if self.__pre_action_fn then
            return self.__pre_action_fn(self.inst,doer)
        end
    end
--------------------------------------------------------------------------------------------------------------
--- sg
    function tbat_com_workable:SetSGAction(sg)
        self.sg = sg
    end
    function tbat_com_workable:GetSGAction()
        return self.sg
    end
--------------------------------------------------------------------------------------------------------------
--- 显示文本
    function tbat_com_workable:SetText(index,str)
        self.str_index = string.upper(index)
        self.str = str
        STRINGS.ACTIONS.TBAT_COM_WORKABLE_ACTION[self.str_index] = str
    end

    function tbat_com_workable:GetTextIndex()
        return self.str_index
    end
--------------------------------------------------------------------------------------------------------------
--- distance
    function tbat_com_workable:SetDistance(num)
        self.distance = num
    end
    function tbat_com_workable:GetDistance()
        return self.distance or 0
    end
--------------------------------------------------------------------------------------------------------------
--- 动作
    function tbat_com_workable:InitActions(_table,doer,right_click)
        if self.init_actions_fn then
            self.init_actions_fn(self.inst,doer,_table,right_click)
        end
    end
    function tbat_com_workable:SetInitActionsFn(fn)
        self.init_actions_fn = fn
    end
--------------------------------------------------------------------------------------------------------------
    function tbat_com_workable:GetCanWorlk()
        return not self.inst:HasTag("tbat_com_workable_can_not_work")
    end
--------------------------------------------------------------------------------------------------------------

return tbat_com_workable






