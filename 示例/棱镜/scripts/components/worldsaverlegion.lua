local WorldSaverLegion = Class(function(self, inst)
    self.inst = inst
end)

function WorldSaverLegion:OnSave()
    LS_SkinCache2File()
    -- return {}
end

-- function WorldSaverLegion:OnLoad(data)
-- 	if data ~= nil then
-- 	end
-- end

return WorldSaverLegion
