--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 自制的皮肤切换工具，可以切换本MOD的带皮肤的东西，可以 前后随便切换
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local tbat_com_skin_tool = Class(function(self, inst)
    self.inst = inst
end)

function tbat_com_skin_tool:NextSkin(target,doer)
    if target and target:HasTag("tbat_com_skin_data") and doer then
        doer.components.tbat_com_skins_controller:ReskinTarget(target)
    end
end
function tbat_com_skin_tool:LastSkin(target,doer)
    if target and target:HasTag("tbat_com_skin_data") and doer then
        doer.components.tbat_com_skins_controller:ReskinTarget(target,true)
    end
end

return tbat_com_skin_tool