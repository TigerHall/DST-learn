local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")


-- 沃姆伍德吃食物获得50%生命
if GetModConfigData("Wormwood Eat Food 50% Health") then
    AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.eater ~= nil then inst.components.eater:SetAbsorptionModifiers(0.5, 1, 1) end
    end)
end

-- 沃姆伍德采集农作物再生
if GetModConfigData("Wormwood Regrow Farm Plant") then
    local function RegeneratePlant(inst, picker)
        if hardmode and picker.components.hunger then picker.components.hunger:DoDelta(-1.5) end
        local x, y, z = inst.Transform:GetWorldPosition()
        if TheWorld.Map:GetTileAtPoint(x, 0, z) ~= WORLD_TILES.FARMING_SOIL then return false end
        local plant = SpawnPrefab(inst.prefab)
        plant.Transform:SetPosition(x, y, z)
        if plant.plant_def ~= nil then
            plant.long_life = true
            plant.no_oversized = false
            if plant.components.farmsoildrinker then plant.components.farmsoildrinker:CopyFrom(inst.components.farmsoildrinker) end
            plant.AnimState:OverrideSymbol("veggie_seed", "farm_soil", "seed")
        end
        inst.grew_into = plant
    end
    AddComponentPostInit("pickable", function(self)
        if not self.inst:HasTag("farm_plant") then return end
        local oldPick = self.Pick
        self.Pick = function(self, picker, ...)
            if self.inst and self.remove_when_picked and picker and picker:IsValid() and picker.prefab == "wormwood" then
                if hardmode then
                    local equip = picker.components.inventory and picker.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                    if equip and equip.prefab == "nutrientsgoggleshat" then RegeneratePlant(self.inst, picker) end
                else
                    RegeneratePlant(self.inst, picker)
                end
            end
            return oldPick(self, picker, ...)
        end
    end)
end

-- 沃姆伍德生长中安抚植物减少生长时间
if GetModConfigData("Wormwood TendTo Farm Plant Reduce Grow Time") then
    AddComponentPostInit("farmplanttendable", function(self)
        local oldTendTo = self.TendTo
        function self:TendTo(doer)
            local ans = oldTendTo(self, doer)
            if ans and doer and doer.prefab == "wormwood" then
                if doer.components.bloomness then
                    if self.inst.components.growable and self.wormwoodtendto2hm ~= self.inst.components.growable:GetStage() then
                        self.wormwoodtendto2hm = self.inst.components.growable:GetStage()
                        if self.inst.components.growable:IsGrowing() then
                            self.inst.components.growable:StartGrowing((self.inst.components.growable.targettime - GetTime()) * (1 - 0.09 * (doer.components.bloomness.level + 1)))
                        else
                            if self.inst.components.growable.pausedremaining then
                                self.inst.components.growable.pausedremaining = self.inst.components.growable.pausedremaining * (1 - 0.09 * (doer.components.bloomness.level + 1))
                            end
                        end
                        local level = doer.components.bloomness.level + 1
                        if level > 3 then
                            level = 3
                        elseif level < 3 then
                            level = 1
                        end
                        SpawnPrefab("halloween_firepuff_cold_" .. level).Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                    end
                end
            end
            return ans
        end
    end)
end

-- 沃姆伍德灵魂消除地裂
if GetModConfigData("Wormwood Soul Heal Soil") then
    AddPrefabPostInit("player_soul2hm", function(inst)
        if not TheWorld.ismastersim then end
        inst:ListenForEvent("onremove", function(inst)
            if inst.prefabName and inst.prefabName == "wormwood" and inst.isDisappear2hm then
                if TheWorld.Map:IsFarmableSoilAtPoint(inst.Transform:GetWorldPosition()) then
                    local x, y, z = TheWorld.Map:GetTileCenterPoint(inst.Transform:GetWorldPosition())
                    SpawnPrefab("halloween_moonpuff").Transform:SetPosition(x, y, z)
                    for i, v in ipairs(TheSim:FindEntities(x, 0, z, 4, {"farmdock2hm"})) do
                        if v and v:IsValid() then
                            local x1, y1, z1 = TheWorld.Map:GetTileCenterPoint(v.Transform:GetWorldPosition())
                            if x == x1 and y == y1 and z == z1 then
                                v:Remove()
                            end
                        end
                    end
                    for i, v in ipairs(TheSim:FindEntities(x, 0, z, 4, {"farm_plant"})) do
                        if v and v:IsValid() then
                            local x1, y1, z1 = TheWorld.Map:GetTileCenterPoint(v.Transform:GetWorldPosition())
                            if x == x1 and y == y1 and z == z1 then
                                v.notlosewaterandsoil = true
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- 沃姆伍德光合作用
if GetModConfigData("Wormwood Photosynthesis") then
    AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then end
        local deltaSanity = 0
        inst.photosynthesistask = inst:DoPeriodicTask(5, function(inst)
            if TheWorld.state.isday and inst.components.health and not inst.components.health:IsDead() and inst.components.sanity then
                if inst.components.bloomness then
                    deltaSanity = deltaSanity + (inst.components.bloomness.level + 1) / (inst.components.bloomness.max + 1)
                    if deltaSanity >= 1 then
                        inst.components.sanity:DoDelta(deltaSanity)
                        deltaSanity = 0
                        local fx = SpawnPrefab("farm_plant_unhappy")
                        fx.entity:SetParent(inst.entity)
                    end
                end
            end
        end)
    end)
end

-- 沃姆伍德右键睡觉
if GetModConfigData("Wormwood Right Self To Hide") then
    local function rightselfstrfn2hm(act)
        return act.doer and act.doer:HasTag("hiding") and (act.doer:HasTag("sleeping") and "SLEEPOUT" or "SLEEPIN") or "WORMWOOD"
    end
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.SLEEPIN = TUNING.isCh2hm and "休憩" or "Rest"
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.SLEEPOUT = TUNING.isCh2hm and "苏醒" or "Wake"
    local function whenwakeup(doer)
        if doer:IsValid() and not doer:HasTag("hiding") and not doer:HasTag("playerghost") and
            not (doer.components.freezable ~= nil and doer.components.freezable:IsFrozen()) and
            not (doer.components.pinnable ~= nil and doer.components.pinnable:IsStuck()) and
            not (doer.components.fossilizable ~= nil and doer.components.fossilizable:IsFossilized()) then
            local sleeptime = TUNING.MOON_MUSHROOM_SLEEPTIME
            if doer.components.sleeper ~= nil then
                doer.components.sleeper:AddSleepiness(4, sleeptime)
            elseif doer.components.grogginess ~= nil then
                doer.components.grogginess:AddGrogginess(2, sleeptime)
            else
                doer:PushEvent("knockedout")
            end
        end
    end
    local function sleepfx(inst)
        if inst and inst:IsValid() and inst:HasTag("sleeping") then
            local fx = SpawnPrefab("fx_book_sleep")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            fx.Transform:SetRotation(inst.Transform:GetRotation())
            -- 主动睡眠,2秒后就可以右键苏醒
            Overriderightactioncd(inst, 2)
        end
    end
    local function onwake(inst, doer, ...)
        -- 被动苏醒,进入CD
        Overriderightactioncd(doer)
        if doer and doer:IsValid() then doer:DoTaskInTime(0.25, whenwakeup) end
        if inst.sleepingbag2hm then inst:DoTaskInTime(0, function() inst:RemoveComponent("sleepingbag") end) end
    end
    local function delaysleep(inst, hat)
        if hat and hat.prefab == "bushhat" and hat:IsValid() and hat.components.sleepingbag then
            hat.components.useableitem:StartUsingItem()
            hat.components.sleepingbag:DoSleep(inst)
            hat.disablestopuse2hm = nil
            if inst.sg then inst.sg:AddStateTag("sleeping") end
            inst:DoTaskInTime(1, sleepfx)
        end
    end
    AddRightSelfAction("wormwood", hardmode and 60 or 1, "dolongaction", function(inst, action)
        inst.bushhatnextaction2hm = inst and inst:HasTag("hiding") and (inst:HasTag("sleeping") and "SLEEPOUT" or "SLEEPIN")
        if inst.bushhatnextaction2hm == "SLEEPIN" or inst.bushhatnextaction2hm == "SLEEPOUT" then
            inst.rightselfaction2hm_handler = inst:HasTag("sleeping") and "hide" or "idle"
            if inst.rightselfaction2hm_fn then inst.rightselfaction2hm_fn(action) end
        else
            inst.rightselfaction2hm_handler = "dolongaction"
        end
    end, function(act)
        if act.doer and act.doer.components.inventory then
            if act.doer.bushhatnextaction2hm == "SLEEPIN" or act.doer.bushhatnextaction2hm == "SLEEPOUT" then
                local hat = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if hat and hat.prefab == "bushhat" and hat:IsValid() then
                    if hat.components.sleepingbag then
                        hat.components.sleepingbag:DoWakeUp(true)
                        if act.doer.sg then act.doer.sg:RemoveStateTag("sleeping") end
                        -- 右键苏醒,进入CD
                        Overriderightactioncd(act.doer)
                    else
                        hat.sleepingbag2hm = true
                        hat:AddComponent("sleepingbag")
                        hat.components.sleepingbag.onwake = onwake
                        if not hat.setstop2hm and hat.components.useableitem then
                            hat.setstop2hm = true
                            local onstopusefn = hat.components.useableitem.onstopusefn
                            hat.components.useableitem:SetOnStopUseFn(function(inst, ...)
                                if hat.components.sleepingbag then hat.components.sleepingbag:DoWakeUp(true) end
                                if onstopusefn ~= nil then onstopusefn(inst, ...) end
                            end)
                        end
                        if act.doer.sg then
                            hat.disablestopuse2hm = true
                            act.doer.sg:GoToState("idle")
                            act.doer:DoTaskInTime(0, delaysleep, hat)
                        end
                    end
                    return true
                end
            else
                local hat = SpawnPrefab("bushhat")
                if hat then
                    hat.persists = false
                    if not act.doer.components.inventory:Equip(hat) then
                        hat:Remove()
                        return
                    end
                    hat.components.useableitem:StartUsingItem()
                    hat.components.useableitem:SetOnStopUseFn(function() if not hat.disablestopuse2hm then hat:DoTaskInTime(3, function(hat)
								hat:Remove()
							end)
						end
					end)
                    hat:ListenForEvent("unequipped", function(hat)
						hat:DoTaskInTime(3, function(hat)
							hat:Remove()
						end)
					end)
                    hat.components.inventoryitem:SetOnDroppedFn(function(hat)
						hat:DoTaskInTime(3, function(hat)
							hat:Remove()
						end)
					end)
                    if hardmode then hat:ListenForEvent("onremove", function() Overriderightactioncd(act.doer) end) end
                    Overriderightactioncd(act.doer, 1)
                    -- 生成的浆果帽立即就可以睡眠,但浆果帽消失后CD60秒
                    return true
                end
            end
            if act.doer.bushhatnextaction2hm then act.doer.bushhatnextaction2hm = nil end
        end
    end, STRINGS.NAMES.BUSHHAT)
    AddPrefabPostInit("wormwood", function(inst) inst.rightselfstrfn2hm = rightselfstrfn2hm end)
end

-- 沃姆伍德吃食物获得装备
if GetModConfigData("Wormwood Eat Rewards Equip") then
    require "prefabutil"
    local foodequips = {
        -- 头部
        cookedmeat = {equips = {"footballhat"}},                -- 猪皮头盔
        seeds_cooked = {equips = {"nutrientsgoggleshat"}},      -- 耕作帽
        lightbulb = {equips = {"minerhat"}},                    -- 矿工帽
        wormlight_lesser = {equips = {"molehat"}},              -- 鼹鼠帽
        red_cap_cooked = {equips = {"red_mushroomhat"}},        -- 红蘑菇帽
        green_cap_cooked = {equips = {"green_mushroomhat"}},    -- 绿蘑菇帽
        blue_cap_cooked = {equips = {"blue_mushroomhat"}},      -- 蓝蘑菇帽
        moon_cap_cooked = {equips = {"moon_mushroomhat"}},      -- 月亮蘑菇帽
        moonbutterflywings = {equips = {"alterguardianhat"}},   -- 启迪之冠
        -- 手部
        moon_tree_blossom = {equips = {"moonglassaxe"}},        -- 月光玻璃斧
        batwing_cooked = {equips = {"batbat"}},                 -- 蝙蝠棒
        cookedmonstermeat = {equips = {"tentaclespike"}},       -- 触手尖刺   
        quagmire_goatmilk = {equips = {"nightstick"}},          -- 晨星     
        milkywhites = {equips = {"shieldofterror"}},            -- 恐怖盾牌
        butterflywings = {equips = {"cane"}},                   -- 手杖
        -- 身体
        potato_cooked = {equips = {"armormarble"}},             -- 大理石甲
        dragonfruit_cooked = {equips = {"armordragonfly"}},     -- 火龙甲
        cutlichen = {equips = {"armorskeleton"}},               -- 骨甲
		cactus_meat_cooked = {equips = {"armor_bramble"}},      -- 荆棘甲
        fishmeat_small_cooked = {equips = {"raincoat"}},        -- 雨衣
        froglegs_cooked = {equips = {"raincoat"}},              -- 雨衣     
        
    }
    -- 变为临时装备
    local function processequip(inst, data)

        if not inst.components.tempequip2hm then
            inst:AddComponent("tempequip2hm")
        end

        inst.components.tempequip2hm.perishtime = TUNING.TOTAL_DAY_TIME * 6
        inst.components.tempequip2hm.remainingtime2hm = TUNING.TOTAL_DAY_TIME * 6

        if data and data.remainingtime2hm then
            inst.components.tempequip2hm.remainingtime2hm = data.remainingtime2hm
        end
        if inst.components.persistent2hm then
            inst.components.persistent2hm.data.food_equip = true -- 标记为食物装备
        end
        inst.components.tempequip2hm:BecomePerishable()

        -- 武器和工具隐藏耐久，拦截耐久消耗转为新鲜度消耗
        if inst.components.finiteuses then
            inst:AddTag("hide_percentage") 
            
            local old_Use = inst.components.finiteuses.Use
            inst.components.finiteuses.Use = function(self, amount, ...)

                -- 如果是临时装备，拦截耐久消耗，改为消耗新鲜度
                if inst.components.tempequip2hm and inst.components.perishable then
                    local loss = (amount or 1) * 0.007  -- 每次使用消耗0.7%新鲜度
                    inst.components.perishable:ReducePercent(loss)
                    return
                end
                
                return old_Use(self, amount, ...)
            end
        end

        -- 护甲额外损耗（兼容原版平摊机制）
        if inst.components.armor then
            inst:AddTag("hide_percentage")
            local absorb_percent = inst.components.armor.absorb_percent 
            local maxcondition = inst.components.armor.maxcondition
            
            -- 将护甲设为不可摧毁，禁用标准耐久度系统
            inst.components.armor:InitIndestructible(absorb_percent)
            
            -- 恐怖盾牌捉虫子等特殊工具行为
            if inst.components.armor.OnUsedAsItem then
                local old_OnUsedAsItem = inst.components.armor.OnUsedAsItem
                inst.components.armor.OnUsedAsItem = function(self, action, doer, target)
                    if inst.components.tempequip2hm and inst.components.perishable then

                        if action == ACTIONS.NET then
                            inst.components.perishable:ReducePercent(0.03)
                            return
                        end
                    end
                    return old_OnUsedAsItem(self, action, doer, target)
                end
            end
            
            -- 原版护甲平摊逻辑在ApplyDamage中计算，我们需要根据实际吸收的伤害来扣除新鲜度
            inst._onattacked_tempequip = function(owner, data)
                if not inst.components.perishable then return end
                if not data then return end
                if not owner or not owner.components.inventory then return end
                
                local original_damage = data.original_damage or data.damage or 0
                if original_damage <= 0 then return end
                
                -- 收集所有护甲的吸收率（包括原版和临时）
                local absorbers = {}
                local total_absorption = 0
                
                for k, v in pairs(owner.components.inventory.equipslots) do
                    if v and v.components.armor then
                        local absorption = v.components.armor:GetAbsorption(data.attacker, data.weapon)
                        if absorption and absorption > 0 then
                            if not v.components.armor:IsIndestructible() then
                                -- 原版护甲也要计入总吸收率
                                absorbers[v] = {
                                    absorption = absorption,
                                    maxcondition = v.components.armor.maxcondition,
                                    is_temp = false
                                }
                                total_absorption = total_absorption + absorption
                            elseif v.components.perishable then
                                -- 临时护甲
                                absorbers[v] = {
                                    absorption = absorption,
                                    maxcondition = v.components.armor.maxcondition,
                                    is_temp = true
                                }
                                total_absorption = total_absorption + absorption
                            end
                        end
                    end
                end
                
                if total_absorption <= 0 then return end
                
                -- 计算最大吸收率（用于确定实际吸收的伤害）
                local max_absorb_percent = 0
                for v, info in pairs(absorbers) do
                    if info.absorption > max_absorb_percent then
                        max_absorb_percent = info.absorption
                    end
                end
                
                -- 被护甲吸收的总伤害
                local absorbed_damage = original_damage * max_absorb_percent
                
                -- 本护甲承受的额外伤害
                local bonus_damage = 0
                if data.attacker and inst.components.armor then
                    bonus_damage = inst.components.armor:GetBonusDamage(data.attacker, data.weapon) or 0
                end
                
                -- 本护甲承受的伤害（按比例平摊）
                local my_info = absorbers[inst]
                if not my_info then return end
                
                local my_absorption = my_info.absorption
                local armor_damage = absorbed_damage * (my_absorption / total_absorption) + bonus_damage
                
                -- 转换为新鲜度损失百分比
                local freshness_loss = armor_damage / maxcondition
                inst.components.perishable:ReducePercent(freshness_loss)
            end
            
            local old_onequip = inst.components.equippable.onequipfn
            inst.components.equippable:SetOnEquip(function(inst, owner)
                if old_onequip then
                    old_onequip(inst, owner)
                end
                inst:ListenForEvent("attacked", inst._onattacked_tempequip, owner)
            end)
            
            local old_onunequip = inst.components.equippable.onunequipfn
            inst.components.equippable:SetOnUnequip(function(inst, owner)
                if old_onunequip then
                    old_onunequip(inst, owner)
                end
                inst:RemoveEventCallback("attacked", inst._onattacked_tempequip, owner)
            end)
        end
    end

    local all_equip_prefabs = {}
    for food, config in pairs(foodequips) do
        if config.equips then
            for _, equip in ipairs(config.equips) do
                if not table.contains(all_equip_prefabs, equip) then
                    table.insert(all_equip_prefabs, equip)
                end
            end
        end
    end

    for _, prefab_name in ipairs(all_equip_prefabs) do
        AddPrefabPostInit(prefab_name, function(inst)
            if not TheWorld.ismastersim then return end
            
            if not inst.components.persistent2hm then
                inst:AddComponent("persistent2hm")
            end

            inst.components.persistent2hm.data.id = inst.GUID

            local function OnSave(inst, data) 
                if inst.components.tempequip2hm and inst.components.perishable then
                    data.remainingtime2hm = inst.components.perishable.perishremainingtime
                end
            end
            
            local function OnLoad(inst, data) 
                if data and data.remainingtime2hm and data.food_equip and not data.treasure_equip then
                    processequip(inst, data)
                end
            end
            
            SetOnSave2hm(inst, OnSave)
            SetOnLoad2hm(inst, OnLoad)
        end)
    end

    -- 吃食物获取装备
    local function oneat(inst, data)
        if data and data.food then
            local prefab = data.food.prefab
            if not (foodequips[prefab] and foodequips[prefab].equips) then return end
            local persistentdata = inst.components.persistent2hm.data
            if hardmode and (persistentdata.equipcd or 0) > TheWorld.state.cycles + 1 then 
                if inst.components.talker then
                    inst.components.talker:Say((TUNING.isCh2hm and "今天已经吃过了" or "Have already eaten today"))
                end
                return 
            end
            
            -- 随机选择一个装备
            local selected_equip = foodequips[prefab].equips[math.random(#foodequips[prefab].equips)]
            local item = SpawnPrefab(selected_equip)
            if item then
                -- 处理为临时装备
                processequip(item, nil)
                
                if inst and inst.components.inventory then
                    inst.components.inventory:GiveItem(item, nil, inst:GetPosition())
                else
                    item.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
                persistentdata.equipcd = math.max(persistentdata.equipcd or 0, TheWorld.state.cycles) + 0.6 -- 每天限1次
            end
        end
    end

    -- 让原版护甲和临时护甲能正确平摊
    AddComponentPostInit("inventory", function(self)
        local old_ApplyDamage = self.ApplyDamage
        self.ApplyDamage = function(self, damage, attacker, weapon, spdamage)
            -- 先收集所有护甲（包括临时和原版）
            local all_absorbers = {}
            local total_absorption = 0
            local has_temp_armor = false
            
            for k, v in pairs(self.equipslots) do
                if v and v.components.armor then
                    local absorption = v.components.armor:GetAbsorption(attacker, weapon)
                    if absorption and absorption > 0 then
                        if v.components.armor:IsIndestructible() and v.components.perishable then
                            -- 临时护甲
                            has_temp_armor = true
                            all_absorbers[v] = {
                                absorption = absorption,
                                is_temp = true
                            }
                            total_absorption = total_absorption + absorption
                        elseif not v.components.armor:IsIndestructible() then
                            -- 原版护甲
                            all_absorbers[v] = {
                                absorption = absorption,
                                is_temp = false
                            }
                            total_absorption = total_absorption + absorption
                        end
                    end
                end
            end
            
            -- 如果有临时护甲和原版护甲混搭，需要修改原版护甲的耐久损耗
            if has_temp_armor and total_absorption > 0 then
                local old_TakeDamages = {}
                for armor, info in pairs(all_absorbers) do
                    if not info.is_temp and armor.components.armor then
                        local old_TakeDamage = armor.components.armor.TakeDamage
                        old_TakeDamages[armor] = old_TakeDamage
                        
                        -- 计算这个护甲的平摊比例
                        local armor_ratio = info.absorption / total_absorption
                        
                        armor.components.armor.TakeDamage = function(self, damage_amount, ...)
                            -- 按平摊比例调整伤害
                            local adjusted_damage = damage_amount * armor_ratio
                            return old_TakeDamage(self, adjusted_damage, ...)
                        end
                    end
                end
                
                local result1, result2 = old_ApplyDamage(self, damage, attacker, weapon, spdamage)
                
                for armor, old_TakeDamage in pairs(old_TakeDamages) do
                    if armor and armor.components.armor then
                        armor.components.armor.TakeDamage = old_TakeDamage
                    end
                end
                
                return result1, result2
            else
                return old_ApplyDamage(self, damage, attacker, weapon, spdamage)
            end
        end
    end)

    -- 应用给沃姆伍德
    AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.persistent2hm then
            inst:AddComponent("persistent2hm")
        end
        inst:ListenForEvent("oneat", oneat)
    end)
    
    -- 恐怖盾牌喂食恢复新鲜度（临时装备）
    AddPrefabPostInit("shieldofterror", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- 检查是否为临时装备，如果是则添加喂食恢复新鲜度功能
        local function check_and_add_feeding(inst)
            if inst.components.tempequip2hm and inst.components.perishable and inst.components.eater then
                local old_oneatfn = inst.components.eater.oneatfn
                inst.components.eater.oneatfn = function(inst, food)
                    -- 先执行原有的喂食逻辑（恢复耐久）
                    if old_oneatfn then
                        old_oneatfn(inst, food)
                    end
                    
                    -- 计算食物营养值(同永不妥协计算公式)
                    local health = food.components.edible:GetHealth(inst) * inst.components.eater.healthabsorption
                    local hunger = food.components.edible:GetHunger(inst) * inst.components.eater.hungerabsorption
                    
                    if health < 0 then
                        health = food.components.edible:GetHealth(inst)
                    end
                    
                    if hunger < 0 then
                        hunger = food.components.edible:GetHunger(inst)
                    end
                    
                    if (health + hunger) < 0 then
                        health = 0
                        hunger = 0
                    end
                    
                    -- 恢复新鲜度，根据食物营养价值
                    if health + hunger > 0 and inst.components.perishable then
                        local freshness_restore = (health + hunger) / inst.components.armor.maxcondition -- 将营养值转换为新鲜度恢复比例
                        inst.components.perishable:SetPercent(math.min(1, inst.components.perishable:GetPercent() + freshness_restore))
                    end
                end
            end
            
            -- 恐怖盾牌作为武器攻击时的新鲜度消耗
            if inst.components.tempequip2hm and inst.components.perishable and inst.components.armor then
                local old_weaponused_callback = inst._weaponused_callback
                inst._weaponused_callback = function(owner, data)
                    if data.weapon ~= nil and data.weapon == inst then
                        -- 原版调用的armor:TakeDamage已经是Indestructible，改为消耗新鲜度
                        local weapon_damage = TUNING.SHIELDOFTERROR_USEDAMAGE or 2 -- 武器使用损耗
                        local freshness_loss = weapon_damage / inst.components.armor.maxcondition
                        inst.components.perishable:ReducePercent(freshness_loss)
                    end
                end
                
                -- 如果已经装备了，需要重新监听事件
                if inst.components.inventoryitem and inst.components.inventoryitem.owner then
                    local owner = inst.components.inventoryitem.owner
                    owner:RemoveEventCallback("onattackother", old_weaponused_callback)
                    owner:ListenForEvent("onattackother", inst._weaponused_callback)
                end
            end
        end
        
        inst:DoTaskInTime(0, check_and_add_feeding)
    end)
end

-- 沃姆伍德吃种子果蔬杂草获得BUFF
if GetModConfigData("Wormwood Eat Seeds Debuff") then

    local function addBuff(inst, buff, hunger)
        local hungerDelta = 0
        if inst.components.debuffable and inst.components.debuffable:GetDebuff(buff) and inst.components.hunger then
            hungerDelta = hunger and hunger / 4 or -5
        elseif inst.components.hunger then
            hungerDelta = hunger or -20
        end
        if inst.components.hunger then
            inst.components.hunger:DoDelta(hungerDelta)
        end
        inst:AddDebuff(buff, buff)
    end

    local weeds = {"tillweed", "forgetmelots", "firenettles"}
    local randombuffs = {
        "buff_playerabsorption",
        "buff_workeffectiveness",
        "buff_attack",
		 "buff_moistureimmunity",
        "buff_sleepresistance",
        "buff_shadowdominance2hm"
    }

    local function saySpeech(inst, chineseText, englishText)
        inst.components.talker:Say((TUNING.isCh2hm and chineseText or englishText))
    end

    local debuffs = {
        tillweed = function(inst)
            saySpeech(inst, "唔,实实的", "Oh,heavy")
            addBuff(inst, "buff_heavybody2hm")
        end,
        forgetmelots = function(inst)
            saySpeech(inst, "唔,爽爽的", "Oh,nice")
            addBuff(inst, "buff_sanitynegaura2hm")
        end,
        firenettles = function(inst)
            saySpeech(inst, "唔,火辣辣", "Oh,hot")
            addBuff(inst, "buff_fireabsorption2hm")
        end,
        speedup = function(inst)
            saySpeech(inst, "哇唔", "Wow")
            addBuff(inst, "buff_shortspeedup2hm", -10)
        end,
        random = function(inst)
            saySpeech(inst, "唔,神秘力量", "Oh,secret power")
            addBuff(inst, randombuffs[math.random(#randombuffs)])
        end
    }

    local function oneat(inst, data)
        if data and data.food and data.food.components.edible and inst.components.talker then
            local foodPrefab = data.food.prefab
            local foodType = data.food.components.edible.foodtype

            if table.contains(weeds, foodPrefab) and debuffs[foodPrefab] and math.random() < 0.75 then
                debuffs[foodPrefab](inst)
            elseif foodPrefab == "pepper" and math.random() < 0.2 then
                saySpeech(inst, "唔,神秘力量", "Oh,secret power")
                addBuff(inst, "buff_attack")
            elseif foodPrefab == "garlic" and math.random() < 0.2 then
                saySpeech(inst, "唔,神秘力量", "Oh,secret power")
                addBuff(inst, "buff_playerabsorption")
            elseif foodPrefab == "rock_avocado_fruit" and math.random() < 0.1 then
                saySpeech(inst, "唔,神秘力量", "Oh,secret power")
                addBuff(inst, "buff_sleepresistance")
            elseif foodPrefab == "cutlichen" and math.random() < 0.1 then
                saySpeech(inst, "唔,神秘力量", "Oh,secret power")
                addBuff(inst, "buff_shadowdominance2hm")
            elseif foodType == FOODTYPE.SEEDS and math.random() < 0.3 then
                debuffs.speedup(inst)
            elseif foodType == FOODTYPE.SEEDS and math.random() < 0.05 then
                debuffs.random(inst)
            elseif foodType == FOODTYPE.VEGGIE and math.random() < 0.2 then
                debuffs.speedup(inst)
            elseif foodType == FOODTYPE.VEGGIE and math.random() < 0.05 then
                debuffs.random(inst)
            end
        end
    end

    AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then return end
        inst.stophungeroverflowspeech2hm = true
        inst:ListenForEvent("oneat", oneat)
    end)
end

-- 沃姆伍德刺针旋花
if GetModConfigData("Wormwood Thorns Generate Spiny Bindweed") then
    local function GetSpawnPoint(pt)
        if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then pt = FindNearbyLand(pt, 1) or pt end
        local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 5, 12, true, true, NoHoles2hm)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.z = offset.z + pt.z
            return offset
        end
    end
    local function growweed_ivy(inst)
        if math.random() < 0.25 then
            local pt = inst:GetPosition()
            local spawn_pt = GetSpawnPoint(pt)
            local weed_ivy = SpawnPrefab("weed_ivy")
            weed_ivy.Transform:SetPosition(spawn_pt:Get())
        end
    end
    AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("thorns", growweed_ivy)
    end)
end