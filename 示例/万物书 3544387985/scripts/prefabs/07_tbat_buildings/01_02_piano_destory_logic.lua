--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local MAX_HIT_NUM = 9
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 拆
    local function onhammered(inst, worker)
        inst.components.lootdropper:DropLoot()
        -- inst.components.container:DropEverything()
        local fx = SpawnPrefab("collapse_big")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
        inst:Remove()
    end
    local function onhit(inst, worker)
        -- inst.components.container:Close()
    end
    local old_WorkedByFn = nil
    local new_workedbyfn = function(self,worker, numworks,...)
        if worker and worker:HasTag("player") then
            old_WorkedByFn(self,worker, numworks,...)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(MAX_HIT_NUM)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    old_WorkedByFn = old_WorkedByFn or inst.components.workable.WorkedBy
    inst.components.workable.WorkedBy = new_workedbyfn
end

