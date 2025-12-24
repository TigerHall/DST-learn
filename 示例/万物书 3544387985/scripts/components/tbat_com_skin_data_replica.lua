-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    API:
        
        com:GetCurrent()
            output  : current_skin_name or nil

]]--
-----------------------------------------------------------------------------------------------------------------------------------------
--- 
-----------------------------------------------------------------------------------------------------------------------------------------
--- 
    local tbat_com_skin_data = Class(function(self, inst)
        self.inst = inst


        self.__current_skin_name = net_string(inst.GUID,"tbat_com_skin_data","tbat_com_skin_data.current_skin_name")
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("tbat_com_skin_data.current_skin_name",function()            
                local skin_name = self.__current_skin_name:value()
                if skin_name == nil or skin_name == "nil" or skin_name == "" then
                    self:Reset()
                else
                    self:ActiveReskinFn(skin_name)
                end
            end)
        end

    end)
-----------------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_skin_data:SetSkin(skin_name)
        if TheWorld.ismastersim then
            self.__current_skin_name:set(skin_name)
        end
    end
    function tbat_com_skin_data:GetCurrent()
        local temp = self.__current_skin_name:value()
        if temp == "nil" or temp == nil or temp == "" then
            return nil
        else
            return temp
        end
    end
    function tbat_com_skin_data:GetCurrentData()
        local current = self:GetCurrent()
        if current == nil then
            return nil
        end
        return TBAT.SKIN.SKINS_DATA_SKINS[current]
    end
    function tbat_com_skin_data:CanMirror()
        return self.inst:HasTag("tbat_tag.can_mirror")
    end
    function tbat_com_skin_data:SetRestFn(fn)
        self.__rest_fn = fn
    end
    function tbat_com_skin_data:Reset()
        if self.__rest_fn then
            self.__rest_fn(self.inst)
        end
    end
    function tbat_com_skin_data:ActiveReskinFn(skin_name)
        local skin_data = TBAT.SKIN.SKINS_DATA_SKINS[skin_name]
        if skin_data and skin_data.client_fn then
            skin_data.client_fn(self.inst)
        end
    end
-----------------------------------------------------------------------------------------------------------------------------------------
return tbat_com_skin_data