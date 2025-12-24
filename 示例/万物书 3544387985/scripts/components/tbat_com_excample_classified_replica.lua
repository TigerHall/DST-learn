----------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
----------------------------------------------------------------------------------------------------------------------------------
---
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_excample_classified = Class(function(self, inst)
    self.inst = inst

    self.classified = nil

end)
------------------------------------------------------------------------------------------------------------------------------
--- classified API
    local function classified_inst_init_fn(classified)
        if classified.__excample_num == nil then
            classified.__excample_num = net_float(classified.GUID,"excample_num","excample_num_update")
        end
        classified.__excample_num:set(0)
        function classified:SetExcampeNum(num)
            if TheWorld.ismastersim then
                self.__excample_num:set(num)
            end
        end
        function classified:GetExcampeNum()
            return self.__excample_num:value()
        end
    end
    function tbat_com_excample_classified:GetClassifiedInitFn()
        return classified_inst_init_fn
    end
    function tbat_com_excample_classified:AttachClassified(classified)
        self.classified = classified
        self.inst:ListenForEvent("excample_num_update",function()
            print("info excample_classified_num_update",self:GetNum())
        end,classified)
    end
------------------------------------------------------------------------------------------------------------------------------
--- 
    function tbat_com_excample_classified:SetNum(num)
        if self.classified then
            self.classified:SetExcampeNum(num)
        end
    end
    function tbat_com_excample_classified:GetNum()
        if self.classified then
            return self.classified:GetExcampeNum()
        end
        return 0
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_excample_classified







