--------------------------------
--[[ 动作与组件动作]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local actions = {
    {
        id = "DORAEMON_FLY_OFF",--起飞
        priority = 3 ,
        str = STRINGS.DORAEMON_TECH.DORAEMON_FLY_OFF,
        fn = function(act)
            -- 骑乘状态
            if act.doer.replica.rider ~= nil and act.doer.replica.rider:IsRiding() then
                return false
            end
            -- 如果饱食度大于规定值才能起飞
            if act.doer.components.hunger and act.doer.replica.hunger:GetCurrent() >= TUNING.DORAEMON_TECH.DORAEMON_FLY_OFF_MIN_HUNGER then
                act.doer.components.doraemon_fly:SetFlying(true)
                return true
            else
                return false
            end
        end,
        state = "doraemon_flyskill_up"
    },
    {
        id = "DORAEMON_FLY_LAND",--着落
        priority = 3 ,
        str = STRINGS.DORAEMON_TECH.DORAEMON_FLY_LAND,
        fn = function(act)
            act.doer.components.doraemon_fly:SetFlying(false,false,true)
            return true
        end,
        state = "doraemon_flyskill_down"
    },
    {
        id = "DORAEMON_MAGIC_FLASHLIGHT_ACTION",-- 还原
        priority = 3 ,
        str = STRINGS.DORAEMON_TECH.DORAEMON_MAGIC_FLASHLIGHT_ACTION,
        fn = function(act)
            local obj = act.invobject
            if obj and obj.components.doraemon_click_useitem then
                return obj.components.doraemon_click_useitem.onuse(act)
            end
            return true
        end,
        state = "dolongaction"
    },
    {
        id = "DORAEMON_MEMORY_BREAD_ACTION",-- 记忆
        priority = 3 ,
        str = STRINGS.DORAEMON_TECH.DORAEMON_MEMORY_BREAD_ACTION,
        fn = function(act)
            local obj = act.invobject
            if obj and obj.components.doraemon_click_useitem then
                return obj.components.doraemon_click_useitem.onuse(act)
            end
            return true
        end,
        state = "dolongaction"
    },
    {
        id = "DORAEMON_GARBAGE_DESTROY_ACTION",-- 销毁垃圾
        priority = 3 ,
        str = STRINGS.DORAEMON_TECH.DORAEMON_ACTION_GARBAGE_DESTROY,
        fn = function(act)
            local target = act.target
            Logger:Debug({"销毁垃圾动作执行",target},2)
            if target and target.components.doraemon_secret_garbage_can then
                return target.components.doraemon_secret_garbage_can:Destroy(act.doer)
            end
            return true
        end,
        state = nil
    },
    {
        id = "DORAEMON_CLICK_INVENTORY",-- 动作
        priority = 3 ,
        stringsDefineFn = function()-- 声明动作相关名称,需要在添加动作之后
            -- 动作相关
            STRINGS.ACTIONS.DORAEMON_CLICK_INVENTORY = {
                GENERIC = STRINGS.DORAEMON_TECH.DORAEMON_ACTION_USE,
                FLY_OFF = STRINGS.DORAEMON_TECH.DORAEMON_FLY_OFF,
            }
        end,
        strfn = function (act)
            if act.invobject and act.invobject.components.doraemon_click_inventory then
                return act.invobject.components.doraemon_click_inventory:GetType()
            end
            if act.target and act.target.components.doraemon_click_inventory then
                return act.target.components.doraemon_click_inventory:GetType()
            end
            return "GENERIC"--默认
        end,
        fn = function(act)
            if act.invobject and act.invobject.components.doraemon_click_inventory then
                return act.invobject.components.doraemon_click_inventory.onuse(act)
            end
            if act.target and act.target.components.doraemon_click_inventory then
                return act.target.components.doraemon_click_inventory.onuse(act)
            end
        end,
        -- inst为entityscript类型,应该是人物对象
        -- act: bufferaction
        -- 这里有个问题state 要么直接为null,要么需要指定一个不为null的状态
        state = function(inst,act)
            if act.invobject and act.invobject.components.doraemon_click_inventory then
                return act.invobject.components.doraemon_click_inventory.deststate
            end
            if act.target and act.target.components.doraemon_click_inventory then
                return act.target.components.doraemon_click_inventory.deststate
            end
            return nil
        end
    },
    {
        id = "DORAEMON_CLICK_SCENE",-- 动作
        priority = 3 ,
        stringsDefineFn = function()-- 声明动作相关名称,需要在添加动作之后
            -- 动作相关
            STRINGS.ACTIONS.DORAEMON_CLICK_SCENE = {
                GENERIC = STRINGS.DORAEMON_TECH.DORAEMON_ACTION_USE,
                LOOK = STRINGS.DORAEMON_TECH.DORAEMON_ACTION_LOOK,
            }
        end,
        strfn = function (act)
            if act.invobject and act.invobject.components.doraemon_click_scene then
                return act.invobject.components.doraemon_click_scene:GetType()
            end
            if act.target and act.target.components.doraemon_click_scene then
                return act.target.components.doraemon_click_scene:GetType()
            end
            return "GENERIC"--默认
        end,
        fn = function(act)
            if act.invobject and act.invobject.components.doraemon_click_scene then
                return act.invobject.components.doraemon_click_scene.onuse(act)
            end
            if act.target and act.target.components.doraemon_click_scene then
                return act.target.components.doraemon_click_scene.onuse(act)
            end
        end,
        -- inst为entityscript类型,应该是人物对象
        -- act: bufferaction
        -- 这里有个问题state 要么直接为null,要么需要指定一个不为null的状态
        state = function(inst,act)
            if act.invobject and act.invobject.components.doraemon_click_scene then
                return act.invobject.components.doraemon_click_scene.deststate
            end
            if act.target and act.target.components.doraemon_click_scene then
                return act.target.components.doraemon_click_scene.deststate
            end
            return nil
        end
    },
}

--[[获取已装备的竹蜻蜓]]
local function getEquippedBambooDragonfly(owner)
    local bamboo_dragonfly_equipped = nil
    for _,tempItem in pairs(owner.replica.inventory:GetEquips()) do
        if tempItem ~= nil and tempItem.prefab == TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB then
            bamboo_dragonfly_equipped = tempItem
            break
        end
    end
    return bamboo_dragonfly_equipped
end


-- 不同类型的参数不同
--SCENE --args: inst, doer, actions, right
--USEITEM = --args: inst, doer, target, actions, right
--POINT = --args: inst, doer, pos, actions, right
--EQUIPPED = --args: inst, doer, target, actions, right
--INVENTORY = --args: inst, doer, actions, right
local component_actions = {
    {
        type = "INVENTORY",
        component = "doraemon_click_inventory",
        tests = {
            {
                action_id = "DORAEMON_CLICK_INVENTORY",
                testfn = function(inst, doer, actions, right)
                    if inst and inst.components.doraemon_click_inventory then
                        return inst.components.doraemon_click_inventory.canuse(inst, doer, actions, right)
                    end
                    return false
                end
            },
        }
    },
    {
        type = "SCENE",
        component = "doraemon_fly",
        tests = {
            {
                action_id = "DORAEMON_FLY_OFF",
                testfn = function(inst, doer, actions, right)
                    -- 需要获取竹蜻蜓
                    local bamboo_dragonfly = getEquippedBambooDragonfly(doer)
                    if bamboo_dragonfly  then
                        -- testfn写在了竹蜻蜓的doraemon_click_scene组件中
                        --       非人物的doraemon_click_scene组件(人物中这个组件已删除)
                        return bamboo_dragonfly.components.doraemon_click_scene.canuse(inst, doer, actions, right)
                    end
                    return false
                end
            },
            {
                action_id = "DORAEMON_FLY_LAND",
                testfn = function(inst, doer, actions, right)
                    -- 这里inventory关闭了 拿不到竹蜻蜓 只能通过人物组件来做了 shit
                    local IsFlying = function(inst) return inst and inst.components.doraemon_fly and inst.components.doraemon_fly:IsFlying()end
                    return (inst == doer) and IsFlying(doer) and not inst:HasTag("playerghost")
                end
            },
        }
    },
    {
        type = "SCENE",
        component = "doraemon_click_scene",
        tests = {
            {
                action_id = "DORAEMON_CLICK_SCENE",
                testfn = function(inst, doer, actions, right)
                    if inst and inst.components.doraemon_click_scene then
                        return inst.components.doraemon_click_scene.canuse(inst, doer, actions, right)
                    end
                    return false
                end
            },
        }
    },
    {
        type = "USEITEM",
        component = "doraemon_click_useitem",
        tests = {
            {
                action_id = "DORAEMON_MAGIC_FLASHLIGHT_ACTION",
                testfn = function(inst, doer, target, actions, right)
                    if inst.prefab == TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB and  inst.components and inst.components.doraemon_click_useitem then
                        return inst.components.doraemon_click_useitem.canuse(inst, doer, target, actions, right)
                    end
                    return false
                end
            },
            {
                action_id = "DORAEMON_MEMORY_BREAD_ACTION",
                testfn = function(inst, doer, target, actions, right)
                    if inst.prefab == TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB and inst.components and inst.components.doraemon_click_useitem then
                        return inst.components.doraemon_click_useitem.canuse(inst, doer, target, actions, right)
                    end
                    return false
                end
            },
        }
    },

}



return {actions = actions, component_actions = component_actions }