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
    function tbat_com_map_jumper:SetSpellFn(fn)
        self.spellfn = fn
    end
    function tbat_com_map_jumper:CastSpell(doer,pos)
        if self.spellfn ~= nil then
            return self.spellfn(self.inst,doer,pos)
        end
        return false
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_map_jumper







