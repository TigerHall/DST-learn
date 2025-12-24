-- 降低陷阱检测间隔，提高响应速度
AddComponentPostInit("trap", function(self)
    self.checkperiod = 0.2  
end)

-- 优化洞穴花环相关逻辑 --

local function RabbitsOnAttacked(inst, data) -- 受到惊吓
    local attacker = data and data.attacker
    if not (attacker and attacker:HasTag("rabbitdisguise")) then return end

    attacker:RemoveTag("rabbitdisguise") 
    
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, nil, {"INLIMBO"})
    local maxnum = 5
    for i = 1, math.min(#ents, maxnum) do -- 比原版更高效的循环方式
        ents[i]:PushEvent("gohome")
    end
end

local function MakeNewPickupFn(old_pickup) -- 增加拾起判断
    return function(inst, owner, ...)

        local result = old_pickup and old_pickup(inst, owner, ...)
    
        if (inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() == owner or 
            inst.components.inventoryitem:IsHeld()) or -- 已在物品栏
           (inst.sg and (inst.sg:HasStateTag("stunned") or inst.sg:HasStateTag("trapped"))) or -- 被控制状态
           not (owner and owner.components.inventory) then -- 无效的owner
            return result
        end

        -- 未装备兔子帽不判断
        local head_item = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if not head_item or head_item.prefab ~= "rabbithat" then
            return result
        end

        -- 已经消耗过不判断
        if inst._rabbithat_pickup2hm then return result end

        -- 检查是否有胡萝卜
        local has_carrot = owner.components.inventory:Has("carrot", 1) or 
                          owner.components.inventory:Has("carrot_cooked", 1)
        
        if has_carrot then
            inst._rabbithat_pickup2hm = true
            -- 消耗胡萝卜
            if owner.components.inventory:Has("carrot", 1) then
                owner.components.inventory:ConsumeByName("carrot", 1)
            else
                owner.components.inventory:ConsumeByName("carrot_cooked", 1)
            end
            return result
        else
            -- 延迟挣脱
            inst:DoTaskInTime(0.5, function() 
                if owner and owner.components.inventory and inst.components.inventoryitem 
                and inst.components.inventoryitem:GetGrandOwner() == owner then
                    -- 挣脱掉落
                    owner.components.inventory:DropItem(inst, true, true)
                    if inst.sg then inst.sg:GoToState("run") end

                    -- 播放声音和动画
                    if inst.SoundEmitter then
                        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
                    end
                    
                    -- 显示提示
                    if owner.components.talker then
                        owner.components.talker:Say(TUNING.isCh2hm and "需要胡萝卜才能留住兔子!" or "You need a carrot to keep the rabbit!")
                    end
                    
                    -- 触发受惊事件
                    RabbitsOnAttacked(inst, {attacker = owner})
                end
            end)
            
            return result
        end
    end
end

AddPrefabPostInit("rabbit", function(inst)
    if not TheWorld.ismastersim then return end

    -- 保存原有的拾取函数并替换
    if inst.components.inventoryitem then
        local old_pickup = inst.components.inventoryitem.onpickupfn
        inst.components.inventoryitem.onpickupfn = MakeNewPickupFn(old_pickup)
    end
    
    -- 添加攻击事件监听
    inst:ListenForEvent("attacked", RabbitsOnAttacked)
end)