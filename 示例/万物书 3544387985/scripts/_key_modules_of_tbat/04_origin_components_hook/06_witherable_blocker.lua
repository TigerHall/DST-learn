---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    枯萎屏蔽器

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
    AddComponentPostInit("witherable", function(self)
        local function is_blocked()
            local pt = Vector3(self.inst.Transform:GetWorldPosition())
            local ents = TheSim:FindEntities(pt.x, 0, pt.z, 100, {"tbat_com_witherable_blocker"})
            for i,v in ipairs(ents) do
                if v.components.tbat_com_witherable_blocker and v.components.tbat_com_witherable_blocker:IsInBlockingArea(pt) then
                    return true
                end
            end
            return false
        end
        local old_Start = self.Start        
        self.Start = function(self,...)
            if is_blocked() then
                self:Stop()
                return
            end
            return old_Start(self,...)
        end

        local old_CanWither = self.CanWither
        self.CanWither = function(self,...)
            if is_blocked() then
                return false
            end
            return old_CanWither(self,...)
        end
    end)