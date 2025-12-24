----------------------------------------------------------------------------------------------------------------------------------
--[[

    野火屏蔽器

    需要hook 进 Burnable:StartWildfire()

]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_wild_fire_blocker = Class(function(self, inst)
    inst:AddTag("tbat_com_wild_fire_blocker")
    self.inst = inst

    self.radius_sq = 0
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_wild_fire_blocker:SetRadius(radius)
        self.radius_sq = radius * radius
    end
------------------------------------------------------------------------------------------------------------------------------
---
    function tbat_com_wild_fire_blocker:IsInBlockingArea(target_or_pt)
        local pt = nil
        if target_or_pt.Transform then
            pt = Vector3(target_or_pt.Transform:GetWorldPosition())
        elseif target_or_pt.x and target_or_pt.y and target_or_pt.z then
            pt = target_or_pt
        end
        if pt == nil then
            return false
        end
        return self.inst:GetDistanceSqToPoint(pt.x,pt.y,pt.z) <= self.radius_sq
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_wild_fire_blocker







