----------------------------------------------------------------------------------------------------------------------------------
--[[

    combat 组件的 装备位面防御入口：
        
        damage, spdamage = self.inst.components.inventory:ApplyDamage(damage, attacker, weapon, spdamage)

        fn = function(player,damage, attacker, weapon, spdamage)
            return damage,spdamage
        end


]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_inventory_custom_apply_damage = Class(function(self, inst)
    self.inst = inst

    self.__BeforeApplyDamageFns = {}
    self.__remove_event_fn_before = function(tempInst)
        self:RemoveBeforeApplyDamageFn(tempInst)
    end

    self.__AfterApplyDamageFns = {}
    self.__remove_event_fn_after = function(tempInst)
        self:RemoveAfterApplyDamageFn(tempInst)
    end
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
--- 前置结算
    function tbat_com_inventory_custom_apply_damage:BeforeApplyDamage(damage, attacker, weapon, spdamage)
        local ret_damage = damage
        local ret_spdamage = nil
        if type(spdamage) == "table" then
            ret_spdamage = spdamage
        end
        for k,v in pairs(self.__BeforeApplyDamageFns) do
            ret_damage,ret_spdamage = v(self.inst,ret_damage, attacker, weapon, ret_spdamage)
            ret_damage = ret_damage or damage
            ret_spdamage = ret_spdamage or spdamage
        end
        return ret_damage,ret_spdamage
    end
    function tbat_com_inventory_custom_apply_damage:AddBeforeApplyDamageFn(tempInst,fn)
        self:RemoveBeforeApplyDamageFn(tempInst)
        if tempInst and type(fn) == "function" then
            self.__BeforeApplyDamageFns[tempInst] = fn
        end
        self.inst:ListenForEvent("onremove", self.__remove_event_fn_before, tempInst)
    end
    function tbat_com_inventory_custom_apply_damage:RemoveBeforeApplyDamageFn(tempInst)
        if self.__BeforeApplyDamageFns[tempInst] then
            local new_table = {}
            for k,v in pairs(self.__BeforeApplyDamageFns) do
                if k ~= tempInst then
                    new_table[k] = v
                end
            end
            self.__BeforeApplyDamageFns = new_table
            self.inst:RemoveEventCallback("onremove", self.__remove_event_fn_before, tempInst)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- 后置结算
    function tbat_com_inventory_custom_apply_damage:AfterApplyDamage(damage, attacker, weapon, spdamage)
        local ret_damage = damage
        local ret_spdamage = nil
        if type(spdamage) == "table" then
            ret_spdamage = spdamage
        end
        for k,v in pairs(self.__AfterApplyDamageFns) do
            ret_damage,ret_spdamage = v(self.inst,ret_damage, attacker, weapon, ret_spdamage)
            ret_damage = ret_damage or damage
            ret_spdamage = ret_spdamage or spdamage
        end
        return ret_damage,ret_spdamage
    end
    function tbat_com_inventory_custom_apply_damage:AddAfterApplyDamageFn(tempInst,fn)
        self:RemoveAfterApplyDamageFn(tempInst)
        if tempInst and type(fn) == "function" then
            self.__AfterApplyDamageFns[tempInst] = fn
        end
        self.inst:ListenForEvent("onremove", self.__remove_event_fn_after, tempInst)
    end
    function tbat_com_inventory_custom_apply_damage:RemoveAfterApplyDamageFn(tempInst)
        if self.__AfterApplyDamageFns[tempInst] then
            local new_table = {}
            for k,v in pairs(self.__AfterApplyDamageFns) do
                if k ~= tempInst then
                    new_table[k] = v
                end
            end
            self.__AfterApplyDamageFns = new_table
            self.inst:RemoveEventCallback("onremove", self.__remove_event_fn_after, tempInst)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_inventory_custom_apply_damage







