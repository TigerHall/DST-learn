--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local this_prefab = "tbat_container_pear_cat"
    local upgrade_item_prefab = "tbat_material_dandycat"
    local MAX_HIT_NUM = 9
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 拆
    local function onhammered(inst, worker)
        inst.components.lootdropper:DropLoot()
        inst.components.container:DropEverything()
        local fx = SpawnPrefab("collapse_big")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
        inst:Remove()
    end
    local function onhit(inst, worker)
        inst.components.container:Close()
    end
    local old_WorkedByFn = nil
    local new_workedbyfn = function(self,worker, numworks,...)
        if worker and worker:HasTag("player") then
            old_WorkedByFn(self,worker, numworks,...)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_test_fn(inst,item,doer,right_click)
        if right_click and (TBAT.DEBUGGING or TheWorld.state.isnewmoon) and not inst:HasTag("lv2") and item.prefab == upgrade_item_prefab then
            return true
        end
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
        --------------------------------------------------
        --- 
            inst:PushEvent("levelup")
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.UPGRADE.GENERIC)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    
    acceptable_com_install(inst)

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