--------------------------------
--[[ 还原光线相关设置]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-22]]
--[[ @updateTime: 2021-12-22]]
--[[ @email: x7430657@163.com]]
--------------------------------
--[[在以下组件中添加标签,以实现还原光线动作]]
AddComponentPostInit("fueled",function(self)
    self.inst:AddTag(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_TAG)
end)
AddComponentPostInit("finiteuses",function(self)
    self.inst:AddTag(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_TAG)
end)
AddComponentPostInit("armor",function(self)
    self.inst:AddTag(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_TAG)
end)
AddComponentPostInit("perishable",function(self)
    self.inst:AddTag(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_TAG)
end)