local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 沃利使用新鲜武器增伤
if GetModConfigData("Warly Use Perishable Weapon") then
    local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
        if mount == nil then
            if weapon ~= nil and weapon.components.perishable then
                if weapon.components.perishable:IsSpoiled() then
                    return 0.75
                elseif weapon.components.perishable:IsStale() then
                    return 1.0
                else
                    return 1.25
                end
            end
        end
        return 1
    end
    AddPrefabPostInit("warly", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.combat.customdamagemultfn then
            inst.components.combat.customdamagemultfn = CustomCombatDamage
        else
            local old = inst.components.combat.customdamagemultfn
            inst.components.combat.customdamagemultfn = function(...) return (old(...) or 1) * CustomCombatDamage(...) end
        end
    end)
end

-- 沃利更强的消化系统，收集食谱升级
if GetModConfigData("Warly Balanced Food") then
    
    AddPrefabPostInit("warly", function(inst)
        if not TheWorld.ismastersim then return end
        -- 初始化食谱收集列表
        inst.cooklist2hm = {}
        
        -- 设置食物记忆无衰减
        if inst.components.foodmemory then
            inst.components.foodmemory.GetFoodMultiplier2hm = inst.components.foodmemory.GetFoodMultiplier
            inst.components.foodmemory.GetFoodMultiplier = function() return 1  end
        end
        
        -- 设置食物效果
        if inst.components.eater then
            local _custom_stats_mod_fn = inst.components.eater.custom_stats_mod_fn
            inst.components.eater.custom_stats_mod_fn = function(inst, health_delta, hunger_delta, sanity_delta, food, ...)
             
                if _custom_stats_mod_fn then
                    health_delta, hunger_delta, sanity_delta = _custom_stats_mod_fn(inst, health_delta, hunger_delta, sanity_delta, food, ...)
                end
                
                -- 血量：正面1.5倍，负面减半
                if health_delta > 0 then
                    health_delta = health_delta * 1.5
                elseif health_delta < 0 then
                    health_delta = health_delta * 0.5
                end
                
                -- 获取原始的食物记忆倍率用于计算额外理智损失
                local base_mult = inst.components.foodmemory and inst.components.foodmemory.GetFoodMultiplier2hm and
                                      inst.components.foodmemory:GetFoodMultiplier2hm(food.prefab) or 1
                local original_sanity_delta = sanity_delta
                          
                -- 额外理智损失：基于重复食物的衰减倍率，减去收集的食谱数量
                if base_mult < 1 then
                    -- 妥协会莫名其妙地翻倍损耗，那就把基础损耗减半，实际仍然为40，50，65，80，90
                    local base_extra_loss = 50 * (1 - base_mult)  -- 基础额外损失
                    local recipe_reduction = inst.cooklist2hm and #inst.cooklist2hm or 0  -- 食谱减免
                    local final_extra_loss = math.max(0, base_extra_loss - recipe_reduction)  -- 最少为0
                    sanity_delta = sanity_delta - final_extra_loss
                end
                
                return health_delta, hunger_delta, sanity_delta
            end
        end
        
        -- 食谱学习监听函数
        local function OnLearnCookbookRecipe(inst, data)
            if data and data.product and not table.contains(inst.cooklist2hm, data.product) then
                table.insert(inst.cooklist2hm, data.product)
                if inst.components.talker then 
                    inst.components.talker:Say((TUNING.isCh2hm and "又学会了一道菜！" or "Learned a new recipe!"))
                end
            end
        end
        
        -- 数据保存/加载函数
        local function OnSave(inst, data)
            data.cooklist2hm = inst.cooklist2hm
        end
        
        local function OnLoad(inst, data)
            if data and data.cooklist2hm then
                inst.cooklist2hm = data.cooklist2hm
            end
        end
        
        -- 设置事件监听和数据处理
        inst:ListenForEvent("learncookbookrecipe", OnLearnCookbookRecipe)
        
        if inst.components.persistent2hm == nil then 
            inst:AddComponent("persistent2hm") 
        end
        SetOnSave2hm(inst, OnSave)
        SetOnLoad2hm(inst, OnLoad)
    end)
end

-- 沃利专属buff双倍收益
if GetModConfigData("Warly Double Personal Buff Time") then
    -- 大厨料理识别函数：检查是否为便携锅专属料理
    local function IsChefFood(food_prefab)
        local cooking = require("cooking")
        if cooking and cooking.recipes and cooking.recipes.portablecookpot then
            -- 检查是否在便携锅配方中但不在普通锅配方中
            local in_portable = cooking.recipes.portablecookpot[food_prefab] ~= nil
            local in_normal = cooking.recipes.cookpot and cooking.recipes.cookpot[food_prefab] ~= nil
            
            -- 只在便携锅中有配方的食物才是大厨料理
            return in_portable and not in_normal
        end
        return false
    end
    
    -- 检查是否为调味料食物（带调味粉后缀）
    local function IsSpicedFood(food_prefab)
        return string.find(food_prefab, "_spice_") ~= nil
    end
    
    -- 调味料buff表（基于原版spicedfoods.lua）
    local SPICE_BUFFS = {
        spice_garlic = "buff_playerabsorption",   -- 蒜粉：免伤buff
        spice_sugar = "buff_workeffectiveness",   -- 蜂蜜粉：工作效率buff
        spice_chili = "buff_attack",              -- 辣粉：攻击buff
        spice_salt = nil                          -- 盐粉：无buff，只是保鲜
    }
    
    -- 大厨料理buff表（基于原版preparedfoods_warly.lua）
    local CHEF_FOOD_BUFFS = {
        voltgoatjelly = "buff_electricattack",          -- 羊角冻：电击buff
        frogfishbowl = "buff_moistureimmunity",         -- 蓝带鱼排：免疫潮湿buff
        glowberrymousse = "wormlight_light_greater",    -- 发光浆果慕斯：发光效果（特殊处理）
        nightberrymosse2hm = "nightvisionbuff2hm",      -- 夜视浆果慕斯：夜视buff（特殊处理）
        dragonchilisalad = nil,                         -- 辣龙椒沙拉：升温（体温系统）
        gazpacho = nil,                                 -- 芦笋冷汤：降温（体温系统）
    }
    
    -- 修改食物buff效果
    local function ModifyFoodBuffEffects(inst, data)
        if not data or not data.food then return end
        
        local food = data.food
        local eater = inst
        local is_chef_food = IsChefFood(food.prefab)
        local is_spiced_food = IsSpicedFood(food.prefab)
        local is_warly = eater.prefab == "warly"
        
        if not is_chef_food and not is_spiced_food then return end
        
        -- 延迟处理buff修改，确保buff已被添加
        eater:DoTaskInTime(0.5, function()
            
            -- === 处理调味料buff ===
            if is_spiced_food then
                for spice_name, buff_name in pairs(SPICE_BUFFS) do
                    if buff_name and string.find(food.prefab, "_" .. spice_name) then
                        local buff = eater:GetDebuff(buff_name)
                        if buff and buff.components.timer then
                            local current_time = buff.components.timer:GetTimeLeft("buffover")
                            if current_time then
                                local new_duration
                                if is_warly then
                                    new_duration = current_time * 2  -- 沃利时长翻倍
                                elseif hardmode then
                                    new_duration = current_time * 0.5  -- 困难模式减半
                                else
                                    new_duration = current_time  -- 简单模式正常
                                end
                                
                                buff.components.timer:StopTimer("buffover")
                                buff.components.timer:StartTimer("buffover", new_duration)
                            end
                        end
                        break -- 一个食物只有一种调味粉
                    end
                end
            end
            
            -- === 处理专属料理buff ===
            if is_chef_food then
                -- 处理辣龙椒沙拉和芦笋冷汤的温度效果，需要拦截食物设置过程
                if food.prefab == "dragonchilisalad" or string.find(food.prefab, "dragonchilisalad_spice_") or
                    food.prefab == "gazpacho" or string.find(food.prefab, "gazpacho_spice_") then

                    if eater.components.temperature and eater.components.temperature.bellytemperaturedelta then
                        local current_delta = eater.components.temperature.bellytemperaturedelta
                        local current_end_time = eater.components.temperature.bellytime
                        local current_duration = current_end_time - GetTime()
                        
                        if current_duration > 0 then
                            local new_duration = current_duration
                            
                            if is_warly then
                                new_duration = current_duration * 2  -- 沃利温度效果时长翻倍
                            elseif hardmode then
                                new_duration = current_duration * 0.5  -- 困难模式减半
                            end
                            
                            -- 重新设置温度效果
                            eater.components.temperature:SetTemperatureInBelly(current_delta, new_duration)
                            
                            -- 标记这是沃利的专属料理温度效果，用于保护
                            if is_warly then
                                eater.warly_chef_temp_effect = {
                                    delta = current_delta,
                                    end_time = GetTime() + new_duration,
                                    food_name = food.prefab
                                }
                            end
                        end
                    end

                else
                    -- 处理其他大厨料理buff
                    for food_name, buff_name in pairs(CHEF_FOOD_BUFFS) do
                        if buff_name and (food.prefab == food_name or string.find(food.prefab, food_name .. "_spice_")) then
                            
                            -- -- === 处理发光浆果慕斯的发光效果 ===
                            -- === 处理夜莓慕斯的夜视buff ===
                            if buff_name == "nightvisionbuff2hm" then
                                local buff = eater:GetDebuff(buff_name)
                                if buff and buff.task then
                                    local current_time = GetTaskRemaining(buff.task)
                                    if current_time then
                                        local new_duration
                                        -- 沃利不翻倍（2天已经很久），其他人困难模式减半到1天
                                        if is_warly then
                                            new_duration = current_time  
                                        elseif hardmode then
                                            new_duration = TUNING.TOTAL_DAY_TIME * 1  
                                        else
                                            new_duration = current_time  
                                        end
                                        
                                        -- 重新设置夜视buff时长
                                        buff.task:Cancel()
                                        buff.task = buff:DoTaskInTime(new_duration, function() buff.components.debuff:Stop() end)
                                    end
                                end
                            
                            -- === 处理其他buff ===
                            else
                                local buff = eater:GetDebuff(buff_name)
                                if buff and buff.components.timer then
                                    local current_time = buff.components.timer:GetTimeLeft("buffover")
                                    if current_time then
                                        local new_duration
                                        if is_warly then
                                            new_duration = current_time * 2
                                        elseif hardmode then
                                            new_duration = current_time * 0.5
                                        else
                                            new_duration = current_time
                                        end
                                        buff.components.timer:StopTimer("buffover")
                                        buff.components.timer:StartTimer("buffover", new_duration)
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            end
        end)
    end
    
    -- 给所有玩家添加食物buff修改监听
    AddPlayerPostInit(function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", ModifyFoodBuffEffects)
    end)
end

--沃利右键自身烹饪
if GetModConfigData("Warly Right Self Cook") then
    local function harvestcookpot(inst)
        if not inst:HasTag("playerghost") and inst.pot2hm and inst.pot2hm:IsValid() and inst.pot2hm.components.stewer then
            inst.pot2hm.components.stewer:Harvest(inst)
        end
    end
    local function processcookpot(inst, pot)
        inst.pot2hm = pot
        pot.master2hm = inst
        RemovePhysicsColliders(pot)
        pot:RemoveComponent("workable")
        pot:RemoveComponent("hauntable")
        pot:RemoveComponent("burnable")
        pot:RemoveComponent("propagator")
        pot:RemoveComponent("portablestructure")
        pot:AddTag("NOCLICK")
        pot:RemoveTag("structure")
        pot.Physics:SetActive(false)
        pot.DynamicShadow:Enable(false)
        pot.MiniMapEntity:SetEnabled(false)
        pot.components.container.skipautoclose = true
        pot:Hide()
        inst:AddChild(pot)
        pot:AddTag("NOBLOCK")
        pot.persists = false
        if pot.components.stewer and pot.components.stewer.ondonecooking then
            local ondonecooking = pot.components.stewer.ondonecooking
            pot.components.stewer.ondonecooking = function(pot, ...)
                ondonecooking(pot, ...)
                if not inst:HasTag("playerghost") then
                    inst:DoTaskInTime(0, harvestcookpot)
                end
            end
        end
    end
    local function OnSave(inst, data) data.pot = InGamePlay() and (inst.pot2hm and inst.pot2hm:IsValid() and inst.pot2hm:GetPersistData() or nil) or data.pot end
    local function initcookpot(inst)
        if not (inst.pot2hm and inst.pot2hm:IsValid()) then
            local pot = SpawnPrefab("portablecookpot")
            if pot then
                processcookpot(inst, pot)
                if inst.components.persistent2hm.data.pot then pot:SetPersistData(inst.components.persistent2hm.data.pot) end
            end
        end
        if inst.components.persistent2hm.data.pot then inst.components.persistent2hm.data.pot = nil end
    end
    AddPrefabPostInit("warly", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.persistent2hm == nil then inst:AddComponent("persistent2hm") end
        SetOnSave2hm(inst, OnSave)
        inst:DoTaskInTime(0, initcookpot)
    end)
    AddRightSelfAction("warly", 1, "dolongaction", nil, function(act)
        if act.doer and act.doer.prefab == "warly" and act.doer.pot2hm then
            local pot = act.doer.pot2hm
            if pot and pot:IsValid() then
                if pot.components.stewer and not pot.components.stewer:IsCooking() then
                    if pot.components.stewer:IsDone() then
                        return pot.components.stewer:Harvest(act.doer)
                    elseif pot.components.container and act.doer == pot.master2hm then
                        if pot.components.container.openlist[act.doer] then
                            pot.components.container:Close(act.doer)
                        else
                            pot.components.container:Open(act.doer)
                        end
                        return true
                    end
                end
            else
                act.doer:DoTaskInTime(0, initcookpot)
            end
        end
    end, STRINGS.NAMES.PORTABLECOOKPOT_ITEM, nil, STRINGS.CHARACTERS.WARLY.DESCRIBE.PORTABLECOOKPOT_ITEM.COOKING_LONG)
    if hardmode then
        for i = #TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WARLY, 1, -1 do
            if TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WARLY[i] == "portablecookpot_item" then
                table.remove(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WARLY, i)
                break
            end
        end
    end
end

-- 沃利每天免费烹饪一次
if GetModConfigData("Warly Free Cook Per Day") then
    AddComponentPostInit("stewer", function(self)
        local StartCooking = self.StartCooking
        self.StartCooking = function(self, doer, ...)
            if self.targettime == nil and not self.multi2hm and doer and doer:IsValid() and doer.prefab == "warly" and doer.components.inventory and
                doer.components.persistent2hm and (doer.components.persistent2hm.data.freecook or -1) < TheWorld.state.cycles and self.inst.components.container and
                self.inst.components.container.numslots == 4 and not self.inst.components.container.acceptsstacks and not self.inst:HasTag("spicer") then
                doer.components.persistent2hm.data.freecook = TheWorld.state.cycles
                local DestroyContents = self.inst.components.container.DestroyContents
                self.inst.components.container.DestroyContents = function(container, ...)
                    local item = container:RemoveItem(container.slots[(hardmode and math.random() < 0.5) and 2 or 1])
                    if item then doer.components.inventory:GiveItem(item) end
                    if doer.components.talker then doer.components.talker:Say((TUNING.isCh2hm and "巧夺天工~" or "Free a ingredient~")) end
                    DestroyContents(container, ...)
                end
                StartCooking(self, doer, ...)
                if doer.components.sanity then doer.components.sanity:DoDelta(TUNING.SANITY_LARGE) end
                self.inst.components.container.DestroyContents = DestroyContents
                return
            end
            StartCooking(self, doer, ...)
        end
    end)
end



-- 为沃利添加温度效果保护机制
local old_SetTemperatureInBelly = nil
AddComponentPostInit("temperature", function(self)
    if old_SetTemperatureInBelly == nil then
        old_SetTemperatureInBelly = self.SetTemperatureInBelly
    end
    
    self.SetTemperatureInBelly = function(self, delta, time)
        local inst = self.inst
        
        -- 检查是否有沃利的专属料理温度效果正在进行
        if inst.warly_chef_temp_effect then
            local chef_effect = inst.warly_chef_temp_effect
            local current_time = GetTime()
            
            -- 如果专属料理的效果还没结束
            if current_time < chef_effect.end_time then
                return -- 拒绝新的温度效果
            else
                inst.warly_chef_temp_effect = nil -- 清除过期的标记
            end
        end
        
        -- 调用原始方法
        return old_SetTemperatureInBelly(self, delta, time)
    end
end)

-- 沃利盐调味料理双倍保鲜
if GetModConfigData("Wally Salt Seasoning Double Freshness") then
    
    
    AddPrefabPostInitAny(function(inst)
        if inst.prefab and string.find(inst.prefab, "_spice_salt") then
            if not TheWorld.ismastersim then return end

            if inst.components.perishable and not inst.salt_time_doubled then
                local perishable = inst.components.perishable

                if inst.from_doubled_salt_stack then
                    local true_percent = perishable.perishremainingtime / (perishable.perishtime * 2)
                    perishable.perishtime = perishable.perishtime * 2
                    perishable:SetPercent(true_percent)
                    inst.from_doubled_salt_stack = nil
                else
                    local current_percent = perishable:GetPercent()
                    perishable.perishtime = perishable.perishtime * 2
                    perishable:SetPercent(current_percent)
                end
                
                inst.salt_time_doubled = true
            end
            
            if inst.components.stackable then
                local old_ondestack = inst.components.stackable.ondestack
                inst.components.stackable:SetOnDeStack(function(newitem, sourceitem)
                    newitem.from_doubled_salt_stack = true
                    
                    if old_ondestack then
                        old_ondestack(newitem, sourceitem)
                    end
                end)
            end
            
            local old_OnSave = inst.OnSave
            inst.OnSave = function(inst, data)
                if old_OnSave then
                    old_OnSave(inst, data)
                end
                if inst.components.perishable then
                    data.salt_freshness_percent = inst.components.perishable:GetPercent()
                end
            end
            
            local old_OnLoad = inst.OnLoad
            inst.OnLoad = function(inst, data)
                if old_OnLoad then
                    old_OnLoad(inst, data)
                end
                if data and data.salt_freshness_percent and inst.components.perishable then
                    inst:DoTaskInTime(0, function()
                        if inst.components.perishable then
                            inst.components.perishable:SetPercent(data.salt_freshness_percent)
                        end
                    end)
                end
            end
        end
    end)
end