----------------------------------------------------------------------------------------------------------------------------------
--[[


    tbat_com_map_jumper

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_map_jumper = Class(function(self, inst)
    self.inst = inst


end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_map_jumper:SetTestFn(fn)
        self.testfn = fn
    end
    function tbat_com_map_jumper:Test(doer,pos)
        return self.testfn ~= nil and self.testfn(self.inst,doer,pos) or false
    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_map_jumper:SetText(str)
        self.text = str
    end
    function tbat_com_map_jumper:GetActionStr()
        return self.text or "Blink"
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_map_jumper







