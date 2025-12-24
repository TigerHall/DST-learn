-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    hook 进 playercontroller 的 StartBuildPlacementMode ，让 皮肤参数进入 placer.SetBuilder 里面
    playercontroller.StartBuildPlacementMode 是放置建筑的时候SpawnPrefab( XXX_placer ) 的 官方API

]]--
-----------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------------
----- 叠堆的带皮肤的物品进行皮肤参数继承
AddComponentPostInit("stackable",function(self) 
    local old_Get = self.Get
    self.Get = function(self,...)
        if self.inst and self.inst.components.tbat_com_skin_data then
            local skin_name = self.inst.components.tbat_com_skin_data:GetCurrent() or nil
            local ret_inst = old_Get(self,...)            
            if ret_inst == self.inst then
                return ret_inst
            elseif skin_name then
                ret_inst.components.tbat_com_skin_data:SetCurrent(skin_name)
            end
            return ret_inst
        else
            return old_Get(self,...)
        end        
    end

end)
-----------------------------------------------------------------------------------------------------------------------------------------
