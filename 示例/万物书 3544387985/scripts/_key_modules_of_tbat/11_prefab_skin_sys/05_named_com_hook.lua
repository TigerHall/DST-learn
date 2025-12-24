--------------------------------------------------------------------------------------------------------------------------------------------
--[[

    给物品组件添加个 方便自用的 API
    切皮肤重置名字

]]--
--------------------------------------------------------------------------------------------------------------------------------------------
AddComponentPostInit("named", function(self)


    function self:TBATSetName(name)
        -- name = name or STRINGS.NAMES[string.upper(self.inst.prefab)] or nil
        if name == nil then
            return
        end
        self.tbat_default_name = name
        self:SetName(name)
    end
    function self:TBATRest()
        self:SetName(self.tbat_default_name)

        -- if self.tbat_default_name then
        --     self:SetName(self.tbat_default_name)            
        -- end
    end

end)