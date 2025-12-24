----------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
----------------------------------------------------------------------------------------------------------------------------------
---
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_mushroom_snail_cauldron = Class(function(self, inst)
    self.inst = inst
    ---------------------------------------------------------------
    -- net
        self._remaining_time = net_float(inst.GUID, "._remaining_time","mushroom_snail_cauldron_update")
        self._remaining_time:set(0)
        self._product = net_string(inst.GUID, "._product","mushroom_snail_cauldron_update")
        self._product:set("")
        self._origin_product = net_string(inst.GUID, "._origin_product","mushroom_snail_cauldron_update")
        self._origin_product:set("")
        self._stacksize = net_float(inst.GUID, "._stacksize","mushroom_snail_cauldron_update")
        self._stacksize:set(0)
        self._cooker_userid = net_string(inst.GUID, "._cooker_userid","mushroom_snail_cauldron_update")
        self._cooker_userid:set("")
        self._cooker_name = net_string(inst.GUID, "._cooker_name","mushroom_snail_cauldron_update")
        self._cooker_name:set("")
        self._cook_fail = net_bool(inst.GUID, "._cook_fail","mushroom_snail_cauldron_update")
        self._cook_fail:set(false)
    ---------------------------------------------------------------
end)
------------------------------------------------------------------------------------------------------------------------------
--- server com
    local function get_server_com(self)
        return self.inst.components.tbat_com_mushroom_snail_cauldron
    end
------------------------------------------------------------------------------------------------------------------------------
--- product
    function tbat_com_mushroom_snail_cauldron:SetProduct(product)
        if TheWorld.ismastersim then
            self._product:set(product)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetProduct()
        if TheWorld.ismastersim then
            return get_server_com(self).product
        else
            return self._product:value()
        end
    end
    function tbat_com_mushroom_snail_cauldron:SetOriginProduct(product)
        if TheWorld.ismastersim then
            self._origin_product:set(product)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetOriginProduct()
        if TheWorld.ismastersim then
            return get_server_com(self).origin_product
        else
            return self._origin_product:value()
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- recipe
    function tbat_com_mushroom_snail_cauldron:GetRecipeData()
        local origin_product = self:GetOriginProduct()
        return TBAT.MSC:GetRecipeData(origin_product)
    end
------------------------------------------------------------------------------------------------------------------------------
--- stacksize
    function tbat_com_mushroom_snail_cauldron:SetStackSize(stacksize)
        if TheWorld.ismastersim then
            self._stacksize:set(stacksize)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetStackSize()
        if TheWorld.ismastersim then
            return get_server_com(self).stacksize
        else
            return self._stacksize:value()
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- cooker
    function tbat_com_mushroom_snail_cauldron:SetCookerUserid(id)
        if TheWorld.ismastersim then
            self._cooker_userid:set(id)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetCookerUserid()
        if TheWorld.ismastersim then
            return get_server_com(self).cooker_userid
        else
            return self._cooker_userid:value()
        end
    end
    function tbat_com_mushroom_snail_cauldron:SetCookerName(name)
        if TheWorld.ismastersim then
            self._cooker_name:set(name)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetCookerName()
        if TheWorld.ismastersim then
            return get_server_com(self).cooker_name
        else
            return self._cooker_name:value()
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- remaining_time
    function tbat_com_mushroom_snail_cauldron:SetRemainingTime(time)
        if TheWorld.ismastersim then
            self._remaining_time:set(time)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetRemainingTime()
        if TheWorld.ismastersim then
            return get_server_com(self).remaining_time
        else
            return self._remaining_time:value() or 0
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- on start api
    function tbat_com_mushroom_snail_cauldron:OnStartClick(doer)
        if self.__start_cd then
            return
        end
        self.__start_cd = true
        TBAT.FNS:RPC_PushEvent(doer,"start_clicked",
        {
            userid = doer.userid,
        },
        self.inst,
        function()
            self.__start_cd = nil
        end,
        function()
            self.inst:DoTaskInTime(3,function()
                self.__start_cd = nil
            end)
        end)
    end
------------------------------------------------------------------------------------------------------------------------------
--- harvest api
    function tbat_com_mushroom_snail_cauldron:OnHarvestClick(doer)
        if self.__harvest_cd then
            return
        end
        self.__harvest_cd = true
        TBAT.FNS:RPC_PushEvent(doer,"harvest_clicked",
        {
            userid = doer.userid,            
        },
        self.inst,
        function()
            self.__harvest_cd = nil
        end,
        function()
            self.inst:DoTaskInTime(3,function()
                self.__harvest_cd = nil
            end)
        end)
    end
------------------------------------------------------------------------------------------------------------------------------
--- cook_fail
    function tbat_com_mushroom_snail_cauldron:SetCookFail(flag)
        if TheWorld.ismastersim then
            self._cook_fail:set(flag)
        end
    end
    function tbat_com_mushroom_snail_cauldron:GetCookFail()
        if TheWorld.ismastersim then
            return get_server_com(self).cook_fail
        else
            return self._cook_fail:value()
        end
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_mushroom_snail_cauldron







