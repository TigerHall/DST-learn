------------------------------------------------------------------------------------------------------------------------------------
--[[

    combat 组件的 装备位面防御入口：
        
        damage, spdamage = self.inst.components.inventory:ApplyDamage(damage, attacker, weapon, spdamage)


]]--
------------------------------------------------------------------------------------------------------------------------------------



AddComponentPostInit("inventory", function(self)

    if self.inst.components.tbat_com_inventory_custom_apply_damage == nil then
        self.inst:AddComponent("tbat_com_inventory_custom_apply_damage")
    end

    local old_ApplyDamage = self.ApplyDamage
    self.ApplyDamage = function(self, damage, attacker, weapon, spdamage,...)
        damage,spdamage = self.inst.components.tbat_com_inventory_custom_apply_damage:BeforeApplyDamage(damage, attacker, weapon, spdamage,...)
        damage,spdamage = old_ApplyDamage(self, damage, attacker, weapon, spdamage,...)
        damage,spdamage = self.inst.components.tbat_com_inventory_custom_apply_damage:AfterApplyDamage(damage, attacker, weapon, spdamage,...)
        return damage,spdamage
    end

end)