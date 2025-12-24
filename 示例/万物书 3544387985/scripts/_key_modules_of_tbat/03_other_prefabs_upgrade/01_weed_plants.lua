-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    农田野草屏蔽器。

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local need_to_hook_prefabs = {}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 农田野草
    local  weed_data = require("prefabs/weed_defs").WEED_DEFS
    for k, v in pairs(weed_data) do
        -- print(v.prefab)
        need_to_hook_prefabs[v.prefab] = true
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 检查
    local task_fn = function(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if not inst:IsValid() or x == nil or y == nil or z == nil then
            return
        end
        local blockers = TheSim:FindEntities(x,0,z,100,{"tbat_com_weed_plants_blocker"})
        for k, blocker in pairs(blockers) do
            if blocker:IsValid() and blocker.components.tbat_com_weed_plants_blocker:IsInBlockingArea(inst) then
                inst:Remove()
                return
            end
        end
    end
    for prefab, _ in pairs(need_to_hook_prefabs) do
        AddPrefabPostInit(prefab,function(inst)
            if not TheWorld.ismastersim then
                return
            end
            TheWorld.components.tbat_com_special_timer_for_theworld:AddOneTimeTimer(task_fn,inst)
        end)
    end