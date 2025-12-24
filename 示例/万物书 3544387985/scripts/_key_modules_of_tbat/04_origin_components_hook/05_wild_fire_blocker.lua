---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    野火屏蔽器

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
    local old_StartWildfire = nil
    local new_StartWildfire = function(self,...)
        local pt = Vector3(self.inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x, 0, pt.z, 100, {"tbat_com_wild_fire_blocker"})
        for i,v in ipairs(ents) do
            if v.components.tbat_com_wild_fire_blocker and v.components.tbat_com_wild_fire_blocker:IsInBlockingArea(pt) then
                return
            end
        end
        return old_StartWildfire(self,...)
    end
    AddComponentPostInit("burnable", function(self)
        if old_StartWildfire == nil then
            old_StartWildfire = self.StartWildfire
        end
        if old_StartWildfire then
            self.StartWildfire = new_StartWildfire
        end
    end)