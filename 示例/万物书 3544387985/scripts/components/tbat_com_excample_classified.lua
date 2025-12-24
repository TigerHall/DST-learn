----------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
----------------------------------------------------------------------------------------------------------------------------------
---     
    local function GetReplica(self)
        return self.inst.replica.tbat_com_excample_classified or self.inst.replica._.tbat_com_excample_classified
    end
    local function SetNum(self,num)
        local replica_com = GetReplica(self)
        if replica_com then
            replica_com:SetNum(num)
        end
    end
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_excample_classified = Class(function(self, inst)
    self.inst = inst

    self.num = 0

end,
nil,
{
    num = SetNum,
})
------------------------------------------------------------------------------------------------------------------------------
--- 
    function tbat_com_excample_classified:SetNum(num)
        self.num = num
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_excample_classified







