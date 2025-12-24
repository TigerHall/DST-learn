local _G = GLOBAL
local TheNet = _G.TheNet
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

-- 支持鱼人王、猪王、鸟笼、蚁狮

-- 重写给予动作
local old_give_fn = _G.ACTIONS.GIVE.fn
_G.ACTIONS.GIVE.fn = function(act)
    -- 批量给与给予对象
    if act.target and (act.target.prefab == "birdcage" or act.target.prefab == "pigking" 
		or act.target.prefab == "mermking" or act.target.prefab == "antlion") then
        -- 获取能否给予，失败原因
        local able, reason = act.target.components.trader:AbleToAccept(act.invobject, act.doer)
        -- 如果不能给予
        if not able then
            return false, reason
        end
        -- 给予物品数量
        local count = (act.invobject and act.invobject.components and act.invobject.components.stackable) and act.invobject.components.stackable:StackSize() or 1
        -- 特殊物品只能一个个给，如金腰带，总不能给10个开一次活动
        if act.invobject.prefab == "pig_token" then count = 1 end
		act.target.components.trader:AcceptGift(act.doer, act.invobject,count)
        return true
    end
    return old_give_fn(act)
end

-- ==================== 鱼人王相关 ====================
AddPrefabPostInit("mermking",function (inst)
	-- 批量交易
    local Old_TradeItem = inst.TradeItem
	inst.TradeItem = function(inst)
		local giver = inst.tradegiver
		local item = inst.itemtotrade
		local count = (item.components and item.components.stackable) and item.components.stackable:StackSize() or 1
        for i = 1, count do    
			inst.tradegiver = giver
			inst.itemtotrade = item
            Old_TradeItem(inst)
        end
    end
	-- 批量喂食
	local old_onaccept =  inst.components.trader.onaccept
	inst.components.trader.onaccept = function(inst, giver, item)
		local count = (item.components and item.components.stackable) and item.components.stackable:StackSize() or 1
        for i = 1, count do                 
            old_onaccept(inst, giver, item)
        end
    end
end)

-- ==================== 诸王相关 ====================
AddPrefabPostInit("pigking",function (inst)
    local old_onaccept =  inst.components.trader.onaccept
    inst.components.trader.onaccept = function(inst, giver, item)
		local count = (item.components and item.components.stackable) and item.components.stackable:StackSize() or 1
        for i = 1, count do                 
            old_onaccept(inst, giver, item)
        end
    end
end)

-- ==================== 鸟笼相关 ====================
AddPrefabPostInit("birdcage",function (inst)
    local old_onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = function(inst, giver, item)
       	local count = (item.components and item.components.stackable) and item.components.stackable:StackSize() or 1
        for i = 1, count do                 
            old_onaccept(inst, giver, item)
        end 
    end
end)

-- ==================== 蚁狮相关 ====================
AddPrefabPostInit("antlion",function (inst)
    local old_onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = function(inst, giver, item)
       	local count = (item.components and item.components.stackable) and item.components.stackable:StackSize() or 1
        for i = 1, count do                 
            old_onaccept(inst, giver, item)
			inst:GiveReward()
        end 
    end
end)