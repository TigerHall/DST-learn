--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,max_hit_num,cmd)
    cmd 可以为nil。 下面是参数表。

    cmd = {
        fx = "collapse_big",                            --- 拆解特效、可以是 false 表示无特效 ,为nil的时候默认为 "collapse_big"
        block_remove = true,                            --- 是否阻止Remove()方法，为true的时候，调用Remove()方法不会删除此物品
        
        onhit = function(inst,worker) end,
        onfinished = function(inst,worker) end,
    }

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local MAX_HIT_NUM = 9
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 拆
    local function onhammered(inst, worker)
        if inst.components.lootdropper then
            inst.components.lootdropper:DropLoot()
        end
        if inst.components.container then
            inst.components.container:DropEverything()
        end
        if inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD then
            if PrefabExists(inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.fx) then
                local fx = SpawnPrefab(inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.fx)
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())                
            elseif inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.fx == false then

            else
                local fx = SpawnPrefab("collapse_big")
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                fx:SetMaterial("wood")
            end
            if inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.onfinished then
                inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.onfinished(inst,worker)
            end
        end
        if inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD and inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.block_remove then

        else
            inst:Remove()
        end
    end
    local function onhit(inst, worker)
        if inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD and inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.onhit then
            inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD.onhit(inst,worker)
        end
        if inst.components.container then
            inst.components.container:Close()
        end
    end

    local new_workedbyfn = function(self,worker, numworks,...)
        if worker and worker:HasTag("player") then
            self.old_tbat_WorkedBy(self,worker, numworks,...)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local function fn(inst)
        if not TheWorld.ismastersim then
            return
        end
        if inst.components.lootdropper == nil then
            inst:AddComponent("lootdropper")
        end
        if inst.components.workable == nil then
            inst:AddComponent("workable")
        end
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(MAX_HIT_NUM)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)
        if inst.components.workable.old_tbat_WorkedBy == nil then
            inst.components.workable.old_tbat_WorkedBy = inst.components.workable.WorkedBy
        end
        inst.components.workable.WorkedBy = new_workedbyfn
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local default_cmd = {
    fx = "collapse_big"
}
function TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,max_hit_num,cmd)
    fn(inst)
    if type(max_hit_num) == "number" then
        inst.components.workable:SetWorkLeft(max_hit_num)
    end
    inst.TBAT_OFFICIAL_WORKABLE_DESTROY_CMD = cmd or default_cmd
    if cmd then
        if cmd.action then
            inst.components.workable:SetWorkAction(cmd.action)
        end
    end
end