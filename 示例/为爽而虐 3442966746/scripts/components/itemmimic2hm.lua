-- 处理临时装备
local itemmimic2hm = Class(function(self, inst)
    self.inst = inst
    self.data = {}
end)

function itemmimic2hm:TurnEvil(target)

    local replaced = ReplacePrefab(self.inst, "nightmarefuel")
    replaced.Transform:SetPosition(self.inst.Transform:GetWorldPosition())

    if target and target.sg and target:IsValid() then
        target:PushEvent("startled")
        if target.components.sanity and not GetGameModeProperty("no_sanity") then
            target.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
        end
    end
end


return itemmimic2hm