--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    【笔记】
        function PlayerController:DoActionAutoEquip(buffaction)
            local equippable = buffaction.invobject ~= nil and buffaction.invobject.replica.equippable or nil
            if equippable ~= nil and
                equippable:EquipSlot() == EQUIPSLOTS.HANDS and
                not equippable:IsRestricted(self.inst) and
                buffaction.action ~= ACTIONS.DROP and
                buffaction.action ~= ACTIONS.COMBINESTACK and
                buffaction.action ~= ACTIONS.STORE and
                buffaction.action ~= ACTIONS.BUNDLESTORE and
                buffaction.action ~= ACTIONS.EQUIP and
                buffaction.action ~= ACTIONS.GIVETOPLAYER and
                buffaction.action ~= ACTIONS.GIVEALLTOPLAYER and
                buffaction.action ~= ACTIONS.GIVE and
                buffaction.action ~= ACTIONS.ADDFUEL and
                buffaction.action ~= ACTIONS.ADDWETFUEL and
                buffaction.action ~= ACTIONS.DEPLOY and
                buffaction.action ~= ACTIONS.CONSTRUCT and
                buffaction.action ~= ACTIONS.ADDCOMPOSTABLE and
                (buffaction.action ~= ACTIONS.TOSS or not equippable.inst:HasTag("keep_equip_toss")) and
                buffaction.action ~= ACTIONS.DECORATESNOWMAN
            then
                self.inst.replica.inventory:EquipActionItem(buffaction.invobject)
                buffaction.autoequipped = true
            end
        end

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 尝试处理 可装备物品（主要是武器）的投入问题
    AddComponentPostInit("playercontroller", function(self)
        -- if not TheNet:IsDedicated() then  -- 【笔记】 服务器客户端都需要
            local old_DoActionAutoEquip = self.DoActionAutoEquip
            self.DoActionAutoEquip = function(self,buffaction,...)
                -- if TBAT.___test_equip_fn_skip and TBAT.___test_equip_fn_skip(buffaction) then
                --     return
                -- end
                if type(buffaction) == "table" and type(buffaction.target) == "table" and type(buffaction.target.replica) == "table" then
                    local target = buffaction.target
                    local com = target.replica.tbat_com_acceptable or target.replica._.tbat_com_acceptable
                    if com then
                        return
                    end
                end
                return old_DoActionAutoEquip(self,buffaction,...)
            end
        -- end
    end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local extra_distance_fn = function(doer, dest, bufferedaction)
    bufferedaction = bufferedaction or doer:GetBufferedAction() or {}
    local target = bufferedaction.target
    local tbat_com_acceptable = target and target.replica.tbat_com_acceptable
    if tbat_com_acceptable then
        return tbat_com_acceptable:GetDistance()
    end
end


local TBAT_COM_ACCEPTABLE_ACTION = Action({priority = 10 , extra_arrive_dist = extra_distance_fn ,canforce=true})   --- 距离 和 目标物体的 碰撞体积有关，为 0 也没法靠近。
TBAT_COM_ACCEPTABLE_ACTION.id = "TBAT_COM_ACCEPTABLE_ACTION"
TBAT_COM_ACCEPTABLE_ACTION.strfn = function(act) --- 客户端检查是否通过,同时返回显示字段
    local item = act.invobject
    local target = act.target
    local doer = act.doer
    if doer and target and target.replica.tbat_com_acceptable then
        local replica_com = target.replica.tbat_com_acceptable or target.replica._.tbat_com_acceptable
        if replica_com then
            return replica_com:GetTextIndex()
        end
    end
    return "DEFAULT"
end

TBAT_COM_ACCEPTABLE_ACTION.fn = function(act)    --- 只在服务端执行~
    local item = act.invobject
    local target = act.target
    local doer = act.doer
    if item and target and doer and target.components.tbat_com_acceptable then
        local replica_com = target.replica.tbat_com_acceptable or target.replica._.tbat_com_acceptable
        if replica_com and replica_com:Test(item,doer,true) then
            return target.components.tbat_com_acceptable:OnAccept(item,doer)
        end
    end
    return false
end
AddAction(TBAT_COM_ACCEPTABLE_ACTION)

--- 【重要笔记】AddComponentAction 函数有陷阱，一个MOD只能对一个组件添加一个动作。
--- 【重要笔记】例如AddComponentAction("USEITEM", "inventoryitem", ...) 在整个MOD只能使用一次。
--- 【重要笔记】modname 参数伪装也不能绕开。


-- AddComponentAction("EQUIPPED", "npng_com_book" , function(inst, doer, target, actions, right)    --- 装备后多个技能
-- AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right) -- -- 一个物品对另外一个目标用的技能，物品身上有 这个com 就能触发
-- AddComponentAction("SCENE", "npng_com_book" , function(inst, doer, actions, right)-------    建筑一类的特殊交互使用
-- AddComponentAction("INVENTORY", "npng_com_book", function(inst, doer, actions, right)   ---- 拖到玩家自己身上就能用
-- AddComponentAction("POINT", "complexprojectile", function(inst, doer, pos, actions, right)   ------ 指定坐标位置用。

-- 在后续注册了，这里暂时注释掉。

AddComponentAction("USEITEM", "inventoryitem", function(item, doer, target, actions, right_click) -- -- 一个物品对另外一个目标用的技能，
    if doer and item and target then
        local tbat_com_acceptable_com = target.replica.tbat_com_acceptable or target.replica._.tbat_com_acceptable
        if tbat_com_acceptable_com and tbat_com_acceptable_com:Test(item,doer,right_click) then
            table.insert(actions, ACTIONS.TBAT_COM_ACCEPTABLE_ACTION)
        end
    end
end)

local function handler_fn(player)
    local creash_flag , ret = pcall(function()
        local target = player.bufferedaction.target
        local item = player.bufferedaction.invobject
        local ret_sg_action = "give"
        local replica_com = target and ( target.replica.tbat_com_acceptable or target.replica._.tbat_com_acceptable )
        if replica_com then
            ret_sg_action = replica_com:GetSGAction()
            replica_com:DoPreAction(item,player)
        end
        return ret_sg_action
    end)
    if creash_flag == true then
        return ret
    else
        print("error in TBAT_COM_ACCEPTABLE_ACTION ActionHandler")
        print(ret)
    end
    return "give"
end

AddStategraphActionHandler("wilson",ActionHandler(TBAT_COM_ACCEPTABLE_ACTION,function(player)
    return handler_fn(player)
end))
AddStategraphActionHandler("wilson_client",ActionHandler(TBAT_COM_ACCEPTABLE_ACTION, function(player)    
    return handler_fn(player)
end))


STRINGS.ACTIONS.TBAT_COM_ACCEPTABLE_ACTION = STRINGS.ACTIONS.TBAT_COM_ACCEPTABLE_ACTION or {
    DEFAULT = STRINGS.ACTIONS.ADDCOMPOSTABLE
}



