

local function ExtraDeployDist(doer, dest, bufferedaction)
    bufferedaction = bufferedaction or doer:GetBufferedAction()
    local invobject = bufferedaction and bufferedaction.invobject or nil
    local target = bufferedaction and bufferedaction.target or nil
    local tbat_com_workable = target and target.replica._.tbat_com_workable
    if tbat_com_workable == nil then
        tbat_com_workable = invobject and invobject.replica._.tbat_com_workable
    end
    local distance = 0
    if tbat_com_workable then
        distance = tbat_com_workable:GetDistance()
    end
    -- print("tbat_com_workable distance:",distance,tbat_com_workable and tbat_com_workable.inst)
    return distance
end

local TBAT_COM_WORKABLE_ACTION = Action({priority = 10 ,extra_arrive_dist = ExtraDeployDist})   --- 距离 和 目标物体的 碰撞体积有关，为 0 也没法靠近。
TBAT_COM_WORKABLE_ACTION.id = "TBAT_COM_WORKABLE_ACTION"
TBAT_COM_WORKABLE_ACTION.strfn = function(act) --- 客户端检查是否通过,同时返回显示字段
    local item = act.invobject
    local target = act.target
    local doer = act.doer
    if target == nil then
        target = item
    end    
    if doer and target and target.replica.tbat_com_workable then
        local replica_com = target.replica.tbat_com_workable or target.replica._.tbat_com_workable
        if replica_com then
            return replica_com:GetTextIndex()
        end
    end
    return "DEFAULT"
end

TBAT_COM_WORKABLE_ACTION.fn = function(act)    --- 只在服务端执行~
    local item = act.invobject
    local target = act.target
    local doer = act.doer

    if target == nil then
        target = item
    end

    if target and doer and target.components.tbat_com_workable then
        local replica_com = target.replica.tbat_com_workable or target.replica._.tbat_com_workable
        if replica_com and replica_com:Test(doer,true) then
            return target.components.tbat_com_workable:Active(doer)
        end
    end
    return false
end
AddAction(TBAT_COM_WORKABLE_ACTION)

--- 【重要笔记】AddComponentAction 函数有陷阱，一个MOD只能对一个组件添加一个动作。
--- 【重要笔记】例如AddComponentAction("USEITEM", "inventoryitem", ...) 在整个MOD只能使用一次。
--- 【重要笔记】modname 参数伪装也不能绕开。


-- AddComponentAction("EQUIPPED", "npng_com_book" , function(inst, doer, target, actions, right)    --- 装备后多个技能
-- AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right) -- -- 一个物品对另外一个目标用的技能，物品身上有 这个com 就能触发
-- AddComponentAction("SCENE", "npng_com_book" , function(inst, doer, actions, right)-------    建筑一类的特殊交互使用
-- AddComponentAction("INVENTORY", "npng_com_book", function(inst, doer, actions, right)   ---- 拖到玩家自己身上就能用
-- AddComponentAction("POINT", "complexprojectile", function(inst, doer, pos, actions, right)   ------ 指定坐标位置用。

-- 在后续注册了，这里暂时注释掉。

-- AddComponentAction("USEITEM", "tbat_com_item_use_to", function(item, doer, target, actions, right_click) -- -- 一个物品对另外一个目标用的技能，
--     if doer and item and target then
--         local tbat_com_item_use_to_com = item.replica.tbat_com_item_use_to or item.replica._.tbat_com_item_use_to

--         if tbat_com_item_use_to_com and tbat_com_item_use_to_com:Test(target,doer) then
--             table.insert(actions, ACTIONS.TBAT_COM_WORKABLE_ACTION)
--         end        
--     end
-- end)

AddComponentAction("SCENE", "tbat_com_workable" , function(target, doer, actions, right_click)-------    建筑一类的特殊交互使用
    if doer and target then
            local tbat_com_workable_com = target.replica.tbat_com_workable or target.replica._.tbat_com_workable
            if tbat_com_workable_com then
                tbat_com_workable_com:InitActions(actions,doer,right_click)
                if tbat_com_workable_com:Test(doer,right_click) then
                    table.insert(actions, ACTIONS.TBAT_COM_WORKABLE_ACTION)
                end
            end        
    end
end)
AddComponentAction("INVENTORY", "tbat_com_workable" , function(item, doer, actions, right_click)    -------    物品一类交互使用
    if doer and item then
            local tbat_com_workable_com = item.replica.tbat_com_workable or item.replica._.tbat_com_workable
            if tbat_com_workable_com then
                tbat_com_workable_com:InitActions(actions,doer,right_click)
                if tbat_com_workable_com:Test(doer,right_click) then
                    table.insert(actions, ACTIONS.TBAT_COM_WORKABLE_ACTION)
                end
            end  
    end
end)

local function handler_fn(player)
    local creash_flag , ret = pcall(function()
        local target = player.bufferedaction.target or player.bufferedaction.invobject
        local ret_sg_action = "dolongaction"
        local replica_com = target and ( target.replica.tbat_com_workable or target.replica._.tbat_com_workable )
        if replica_com then
            ret_sg_action = replica_com:GetSGAction()
            replica_com:DoPreAction(player)
        end
        return ret_sg_action

    end)
    if creash_flag == true then
        return ret
    else
        print("error in TBAT_COM_WORKABLE_ACTION ActionHandler")
        print(ret)
    end
    return "dolongaction"
end

AddStategraphActionHandler("wilson",ActionHandler(TBAT_COM_WORKABLE_ACTION,function(player)
    return handler_fn(player)
end))
AddStategraphActionHandler("wilson_client",ActionHandler(TBAT_COM_WORKABLE_ACTION, function(player)    
    return handler_fn(player)
end))


STRINGS.ACTIONS.TBAT_COM_WORKABLE_ACTION = STRINGS.ACTIONS.TBAT_COM_WORKABLE_ACTION or {
    DEFAULT = STRINGS.ACTIONS.OPEN_CRAFTING.USE
}



