--[[
    动物箱庭系统 - Container Live System
    该文件实现了容器内生物的自动进食和相互作用功能
--]]

-- 配置常量
local ignorerange = GetModConfigData("container_live") == -1  -- 是否忽略进食范围限制
local DONT_ACCEPT_FOODTYPES = {[FOODTYPE.INSECT] = true}      -- 不接受的食物类型列表

--[[
    检查实例是否可以食用指定食物
    @param inst 要检查的实例
    @param food 要检查的食物
    @return boolean 是否可以食用
--]]
local function caneat(inst, food)
    -- 基础检查：食物必须有效且可食用
    if not (food and food:IsValid() and food.prefab ~= inst.prefab and 
            food.components.edible and not food:HasTag("curse2hm") and
            not DONT_ACCEPT_FOODTYPES[food.components.edible.foodtype]) then
        return false
    end
    
    -- 常规进食检查
    if inst.components.eater and inst.components.eater:CanEat(food) then
        return true
    end
    
    -- 鱼类特殊进食
    if (inst.fish_def or inst:HasTag("pondfish")) and 
       not (food.fish_def or food:HasTag("pondfish")) then
        local diet = inst.fish_def and inst.fish_def.diet and inst.fish_def.diet.caneat or FOODGROUP.BERRIES_AND_SEEDS
        
        if diet then
            for i, v in ipairs(diet) do
                if type(v) == "table" then
                    for i2, v2 in ipairs(v.types) do 
                        if food:HasTag("edible_" .. v2) then 
                            return true 
                        end 
                    end
                elseif food:HasTag("edible_" .. v) then
                    return true
                end
            end
        end
    end
    
    return false
end
--[[
    尝试让鱼类杀死其他鱼类（弱肉强食机制）
    @param inst 攻击者鱼类
    @param fish 被攻击的鱼类
    @param rate 攻击成功率修正值
    @return 被杀死的鱼类实例，如果未成功则返回nil
--]]
local function trykillfish(inst, fish, rate)
    -- 基础检查：目标必须是有效的鱼类且不是自己
    if not (fish and fish:IsValid() and (fish.fish_def or fish:HasTag("pondfish")) and 
            fish.prefab ~= inst.prefab) then
        return false
    end
    
    -- 获取双方重量，用于判断强弱关系
    local weight1 = inst.components.weighable and inst.components.weighable.weight or math.random(25, 315)
    local weight2 = fish.components.weighable and fish.components.weighable.weight or math.random(25, 315)
    
    -- 如果攻击者比目标轻，无法杀死
    if weight1 < weight2 then 
        return false 
    end
    
    -- 根据重量差和成功率计算是否杀死成功
    if math.random() < math.abs((weight1 - weight2) / 300 / (rate or 8)) then
        fish:DoTaskInTime(0, fish.Remove)
        return fish
    end
    
    return false
end

--[[
    取消实例的进食任务
    @param inst 要取消任务的实例
--]]
local function canceleatfoodtask(inst)
    if inst.eatfood2hmtask then
        inst.eatfood2hmtask:Cancel()
        inst.eatfood2hmtask = nil
    end
end

--[[
    核心功能：在容器中寻找并尝试食用食物
    @param inst 寻找食物的实例
--]]
local function tryfindfood(inst)
    -- 获取实例的拥有者（容器）
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if not (owner and owner:IsValid()) then
        canceleatfoodtask(inst)
        return
    end
    
    -- 获取容器信息
    local container = owner.components.inventory or owner.components.container
    local slots = container.itemslots or container.slots or {}
    local numslots = container.maxslots or container.numslots or 0
    
    -- 如果容器太小（只有一个槽位），取消任务
    if numslots <= 1 then
        canceleatfoodtask(inst)
        return
    end
    
    -- 找到当前实例在容器中的位置
    local prevslot
    for i = 1, numslots, 1 do
        if slots[i] == inst then
            prevslot = i
            break
        end
    end
    
    -- 如果找不到当前位置，取消任务
    if not prevslot then
        canceleatfoodtask(inst)
        return
    end
    
    -- 寻找可食用的食物
    local foodslot
    for i = 1, numslots, 1 do
        local v = slots[i]
        if v ~= inst and caneat(inst, v) then
            if ignorerange then
                -- 忽略范围限制模式：直接食用
                local food = v
                -- 非火腿棒，正常处理
                if not (inst.components.eater and inst.components.eater:Eat(food)) then 
                    container:RemoveItem(food):Remove() 
                end

                return
            elseif foodslot then
                -- 选择距离最近的食物
                foodslot = math.abs(prevslot - foodslot) > math.abs(prevslot - i) and i or foodslot
            else
                foodslot = i
            end
        end
    end
    
    -- 处理找到的食物
    if foodslot then
        if math.abs(prevslot - foodslot) <= 1 then
            -- 食物在相邻位置，直接食用
            local food = slots[foodslot]
            if food then
                if not (inst.components.eater and inst.components.eater:Eat(food)) then 
                    container:RemoveItem(food):Remove() 
                end
            end
        elseif inst.components.locomotor then
            -- 食物不在相邻位置且实例可移动，尝试移动到食物附近
            local elseslot = foodslot > prevslot and prevslot + 1 or prevslot - 1
            container:RemoveItem(inst, true)
            local other = slots[elseslot]
            if other then 
                container:RemoveItem(other, true) 
            end
            container:GiveItem(inst, elseslot)
            if other then 
                container:GiveItem(other, prevslot) 
            end
        end
    elseif inst.fish_def or inst:HasTag("pondfish") then
        -- 如果是鱼类且没找到食物，尝试捕食其他鱼类
        if ignorerange then
            -- 忽略范围限制模式：可以攻击容器内任何鱼类
            local rate = (container.maxslots or container.numslots or 0) * 8
            for k, v in pairs(slots) do 
                if trykillfish(inst, v, rate) == inst then 
                    return 
                end 
            end
        else
            -- 范围限制模式：只能攻击相邻的鱼类
            if trykillfish(inst, slots[prevslot - 1]) ~= inst then 
                trykillfish(inst, slots[prevslot + 1]) 
            end
        end
    end
end

--[[
    检查实例是否在容器中，并管理进食任务
    @param inst 要检查的实例
--]]
local function checkinventory(inst)
    if inst.components.inventoryitem and inst.components.inventoryitem:GetSlotNum() ~= nil then
        -- 实例在容器中，启动周期性进食任务
        if not inst.eatfood2hmtask then 
            inst.eatfood2hmtask = inst:DoPeriodicTask(60, tryfindfood, math.random(10, 60) + math.random()) 
        end
    elseif inst.eatfood2hmtask then
        -- 实例不在容器中，取消进食任务
        inst.eatfood2hmtask:Cancel()
        inst.eatfood2hmtask = nil
    end
end

--[[
    当实例被放入容器时的回调函数
    @param inst 被放入容器的实例
--]]
local function onputininventory(inst) 
    inst:DoTaskInTime(0, checkinventory) 
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 只对可放入容器且具有进食能力或鱼类属性的实例生效
    if inst.components.inventoryitem and 
       (inst.components.eater or inst.fish_def or inst:HasTag("pondfish")) then
        inst:ListenForEvent("onputininventory", onputininventory)
        inst:DoTaskInTime(FRAMES, checkinventory)
    end
end)
