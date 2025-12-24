local hardmode = TUNING.hardmode2hm

-- 千影的新火腿棒
local newhambat = GetModConfigData("New Hambat 2")
TUNING.MAXHAMBATWEIGHT2HM = newhambat or 0
if newhambat then
    AddRecipePostInit("hambat", function(self)
        for _, ingredient in pairs(self.ingredients) do
            if ingredient.type == "meat" then
                ingredient.amount = ingredient.amount - 1
            end
        end
    end)
    AddPrefabPostInit("hambat", function(inst)
        inst:AddTag("hambat2hm")
        if not TheWorld.ismastersim then return end
        -- inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
        inst:AddComponent("hoverer2hm")
        inst:AddComponent("hambat2hm")
        -- 让 SHAVE 动作可以识别火腿棒
        inst:AddComponent("shaveable")
        inst.components.shaveable.prize_count = 0 
    end)
    local cooking = require "cooking"
    local _up_aliases = getupvalue2hm(AddRecipeCard, "aliases") or getupvalue2hm(cooking.CalculateRecipe, "aliases") or getupvalue2hm(cooking.IsCookingIngredient, "aliases") or {
        cookedsmallmeat = "smallmeat_cooked",
        cookedmonstermeat = "monstermeat_cooked",
        cookedmeat = "meat_cooked",
    }
    local function is_meat(item)
        local recipe = cooking.ingredients[_up_aliases[item.prefab] or item.prefab]
        if recipe and recipe.tags and recipe.tags.meat then return recipe end
        return false
    end

    local action = Action({})
    action.priority = 1
    action.id = "GIVEHAMBAT2HM"
    action.str = TUNING.isCh2hm and "补充" or "complement"
    action.fn = function(act)
        if act.target and act.target.components.hambat2hm and act.invobject then
            return act.target.components.hambat2hm:AddMeat(is_meat(act.invobject), act.invobject)
        else
            return false, "不是火腿"
        end
    end
    -- 添加动作
    AddAction(action)
    AddComponentAction("USEITEM", "edible", function(inst, doer, target, actions)
        if is_meat(inst) then
            if target and target:HasTag("hambat2hm") then
                table.insert(actions, ACTIONS.GIVEHAMBAT2HM)
            end
        end
    end)
    local handler = ActionHandler(ACTIONS.GIVEHAMBAT2HM, function(inst, action) return "domediumaction" end)
    AddStategraphActionHandler("wilson", handler)
    AddStategraphActionHandler("wilson_client", handler)

    local action = Action({})
    action.priority = 1
    action.id = "EATHAMBAT2HM"
    action.str = TUNING.isCh2hm and "啃食" or "taste"
    action.distance = 999999
    action.fn = function(act)
        if act.invobject and act.invobject.components.hambat2hm then
            return act.invobject.components.hambat2hm:Taste(act.doer)
        else
            return false, "不是火腿"
        end
    end
    -- 添加动作
    AddAction(action)

    AddComponentAction("INVENTORY", "hambat2hm", function(inst, doer, actions, right)
        if right and inst:HasTag("hambat2hm") then
            table.insert(actions, ACTIONS.EATHAMBAT2HM)
        end
    end)
    local handler = ActionHandler(ACTIONS.EATHAMBAT2HM, function(inst, action) return "eat" end)
    AddStategraphActionHandler("wilson", handler)
    AddStategraphActionHandler("wilson_client", handler)
    
    -- 处理喂食眼面具，恐怖盾牌
    local function processhambat2hm_eat(inst)
        -- 重写eater组件的Eat函数，专门处理火腿棒
        if inst.components.eater then
            local original_eat = inst.components.eater.Eat
            inst.components.eater.Eat = function(self, food, feeder)
                -- 检查是否是火腿棒
                if food and food.components.hambat2hm then
                    -- 检查火腿棒是否还有重量
                    if food.components.hambat2hm.weight < 1 then
                        return false
                    end
                    
                    -- 获取原始重量
                    local original_weight = food.components.hambat2hm.weight
                    
                    -- 计算火腿棒的营养值
                    local scale = 1 - (TUNING.food_change_2hm or 0) * 0.1
                    local foodValue = TUNING.CALORIES_SMALL * scale
                    local healthValue = -TUNING.HEALING_MED * (food.components.hambat2hm.dirty - 1) * 0.25
                    
                    -- 考虑新鲜度影响
                    if food.components.perishable then
                        if food.components.perishable:IsStale() then
                            foodValue = foodValue * 0.75
                            healthValue = healthValue < 0 and healthValue * 1.25 or healthValue * 0.75
                        elseif food.components.perishable:IsSpoiled() then
                            foodValue = foodValue * 0.5
                            healthValue = healthValue < 0 and healthValue * 1.5 or healthValue * 0.5
                        end
                    end
                    
                    -- 转换为修复值
                    local hunger_repair = math.abs(foodValue * 0.5) * self.hungerabsorption
                    local health_repair = math.abs(healthValue) * self.healthabsorption
                    
                    -- 修复装备
                    inst.components.armor:Repair(hunger_repair + health_repair)
                    
                    -- 播放动画和音效
                    local sound_name = inst.prefab == "shieldofterror" and "terraria1/eye_shield/eat" or "terraria1/eyemask/eat"
                    if not inst.inlimbo then
                        inst.AnimState:PlayAnimation("eat")
                        inst.AnimState:PushAnimation("idle", true)
                        inst.SoundEmitter:PlaySound(sound_name)
                    else
                        -- 物品在背包中时，让持有者播放声音
                        local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
                        if owner and owner.SoundEmitter then
                            owner.SoundEmitter:PlaySound(sound_name)
                        end
                    end
                    
                    -- 如果重量足够，只减少0.5重量，不移除食物
                    if original_weight > 0.5 then
                        food.components.hambat2hm.weight = original_weight - 0.5
                        return true -- 表示成功"吃"了，但不移除食物
                    else
                        -- 重量不足0.5，调用原始Eat函数正常消耗
                        return original_eat(self, food, feeder)
                    end
                else
                    -- 非火腿棒，使用原来的逻辑
                    return original_eat(self, food, feeder)
                end
            end
        end
    end
    
    AddPrefabPostInit("shieldofterror", function(inst)
        if not TheWorld.ismastersim then return end
        processhambat2hm_eat(inst)
    end)
    
    AddPrefabPostInit("eyemaskhat", function(inst)
        if not TheWorld.ismastersim then return end
        processhambat2hm_eat(inst)
    end)
end

-- 启迪之冠养老，保暖隔热防水绝缘冷源热源
local alterhat = GetModConfigData("Enlightened Crown Benefit From Spore")
if alterhat then
    local disablelight = alterhat == -1
    local function alterguardianhat_IsRed(inst) return inst.prefab == MUSHTREE_SPORE_RED end
    local function alterguardianhat_IsGreen(inst) return inst.prefab == MUSHTREE_SPORE_GREEN end
    local function alterguardianhat_IsBlue(inst) return inst.prefab == MUSHTREE_SPORE_BLUE end
    local function ondropped(inst)
        local owner = inst.externallyinsulatedowner2hm
        if owner and owner.components.inventory then
            owner.components.inventory.isexternallyinsulated:RemoveModifier(inst, "alterguardianhat")
            inst.externallyinsulatedowner2hm = nil
        end
    end
    local function onputininventory(inst)
        ondropped(inst)
        if inst.components.equippable.insulated then
            local owner = inst.components.inventoryitem:GetGrandOwner()
            if owner and owner.components.inventory then
                inst.externallyinsulatedowner2hm = owner
                owner.components.inventory.isexternallyinsulated:SetModifier(inst, true, "alterguardianhat")
            end
        end
    end
    local function activedisablelight(inst) if inst._light and inst._light:IsValid() then inst._light.Light:SetColour(180 / 255, 195 / 255, 150 / 255) end end
    local function alterguardianhat_update(inst)
        local r = #inst.components.container:FindItems(alterguardianhat_IsRed)
        local g = #inst.components.container:FindItems(alterguardianhat_IsGreen)
        local b = #inst.components.container:FindItems(alterguardianhat_IsBlue)
        inst.components.waterproofer:SetEffectiveness(g * 0.2)
        if g >= 5 then
            inst.components.equippable.insulated = true
            onputininventory(inst)
        else
            ondropped(inst)
            inst.components.equippable.insulated = false
        end
        if r >= b then
            inst.components.insulator:SetWinter()
            inst.components.insulator:SetInsulation(r * 60 - b * 60)
        else
            inst.components.insulator:SetSummer()
            inst.components.insulator:SetInsulation(b * 60 - r * 60)
        end
        if r >= 5 or b >= 5 then
            inst:AddTag("HASHEATER")
            if r > b then
                inst.components.heater:SetThermics(true, false)
                inst.components.heater.heat = 70
                inst.components.heater.equippedheat = 70
                inst.components.heater.carriedheat = 70
                inst.components.heater.carriedheatmultiplier = 2
            else
                inst.components.heater:SetThermics(false, true)
                inst.components.heater.heat = -5
                inst.components.heater.equippedheat = -5
                inst.components.heater.carriedheat = -5
                inst.components.heater.carriedheatmultiplier = 2
            end
        else
            inst:RemoveTag("HASHEATER")
            inst.components.heater:SetThermics(false, false)
            inst.components.heater.heat = nil
            inst.components.heater.equippedheat = nil
            inst.components.heater.carriedheat = nil
            inst.components.heater.carriedheatmultiplier = 1
        end
        if disablelight then activedisablelight(inst) end
    end
    AddPrefabPostInit("alterguardianhat", function(inst)
        inst:AddTag("waterproofer")
        inst:AddTag("goggles")
        inst:AddTag("moonstormgoggles")
        if not TheWorld.ismastersim then return end
        if not inst.components.waterproofer then inst:AddComponent("waterproofer") end
        inst.components.waterproofer:SetEffectiveness(0)
        if not inst.components.insulator then inst:AddComponent("insulator") end
        inst.components.insulator:SetInsulation(0)
        if not inst.components.heater then inst:AddComponent("heater") end
        inst.components.heater:SetThermics(false, false)
        alterguardianhat_update(inst)
        inst:ListenForEvent("onputininventory", onputininventory)
        inst:ListenForEvent("ondropped", ondropped)
        if disablelight then
            inst:ListenForEvent("equipped", activedisablelight)
            inst:ListenForEvent("onopen", activedisablelight)
            inst:ListenForEvent("onclose", activedisablelight)
        end
        inst:ListenForEvent("itemget", alterguardianhat_update)
        inst:ListenForEvent("itemlose", alterguardianhat_update)
        if inst.components.preserver then inst.components.preserver:SetPerishRateMultiplier(TUNING.FISH_BOX_PRESERVER_RATE) end
    end)
    local function onperish(inst)
        if inst:HasTag("fresh") then
            if inst.components.insulator then
                inst.components.insulator:SetInsulation(240)
            elseif inst.components.waterproofer then
                inst.components.waterproofer:SetEffectiveness(1)
            end
        elseif inst:HasTag("stale") then
            if inst.components.insulator then
                inst.components.insulator:SetInsulation(120)
            elseif inst.components.waterproofer then
                inst.components.waterproofer:SetEffectiveness(0.75)
            end
        elseif inst:HasTag("spoiled") then
            if inst.components.insulator then
                inst.components.insulator:SetInsulation(60)
            elseif inst.components.waterproofer then
                inst.components.waterproofer:SetEffectiveness(0.5)
            end
        end
    end
    AddPrefabPostInit("red_mushroomhat", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.insulator then inst:AddComponent("insulator") end
        inst.components.insulator:SetWinter()
        inst.components.insulator:SetInsulation(240)
        inst:ListenForEvent("forceperishchange", onperish)
    end)
    AddPrefabPostInit("green_mushroomhat", function(inst)
        inst:AddTag("waterproofer")
        if not TheWorld.ismastersim then return end
        if not inst.components.waterproofer then inst:AddComponent("waterproofer") end
        inst.components.waterproofer:SetEffectiveness(1)
        inst:ListenForEvent("forceperishchange", onperish)
    end)
    AddPrefabPostInit("blue_mushroomhat", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.insulator then inst:AddComponent("insulator") end
        inst.components.insulator:SetSummer()
        inst.components.insulator:SetInsulation(240)
        inst:ListenForEvent("forceperishchange", onperish)
    end)
    AddPrefabPostInit("minerhat", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.resistance then
            inst:AddComponent("resistance")
            inst.components.resistance:AddResistance("quakedebris")
            inst.components.resistance:AddResistance("lunarhaildebris")
        end
    end)
end

-- 多用斧镐万能
if GetModConfigData("Multi Tool Is Almighty Tool") then
    local function NewTerraform(self, pt, doer, ...)
        self.inst.RefreshSpecialAbility2hm(self.inst)
        return self.oldAction2hm(self, pt, doer, ...)
    end
    local TILLSOIL_IGNORE_TAGS = {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR", "WALKABLEPLATFORM", "soil"}
    local function NewTill(self, pt, doer, ...)
        if self.inst.oldtill2hm then return self.oldAction2hm(self, pt, doer, ...) end
        if not self.oldAction2hm(self, pt, doer, ...) then return false end
        local inst = self.inst
        local x, y, z = pt:Get()
        if not TheWorld.Map:GetTileAtPoint(x, 0, z) == WORLD_TILES.FARMING_SOIL then return false end
        local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(x, y, z)
        -- 获取地皮中心坐标点
        local spacing = 1.3
        -- 土堆间距
        local farm_plant_pos = {}
        -- 农场作物坐标
        local totaluse = 0
        -- 清除这块地皮上多余的土堆
        local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(cx, 0, cz)
        for _, ent in ipairs(ents) do
            if ent ~= doer and ent:HasTag("soil") then -- 是土堆，则清除
                if not ent:HasTag("NOCLICK") then totaluse = totaluse - 4 end
                ent:PushEvent("collapsesoil")
            end
        end
        -- 生成整齐的土堆
        for i = -1, 1 do
            for j = -1, 1 do
                local nx = cx + spacing * i
                local nz = cz + spacing * j
                local rot = doer and doer.Transform:GetRotation()
                if rot then
                    if rot <= -90 then
                        nx = cx + spacing * j
                        nz = cz - spacing * i
                    elseif rot <= 0 then
                        nx = cx - spacing * i
                        nz = cz - spacing * j
                    elseif rot >= 0 then
                        nx = cx - spacing * j
                        nz = cz + spacing * i
                    end
                end
                -- 生成的预置物名,默认为土堆
                local spawnItem = "farm_soil"
                if TheWorld.Map:IsDeployPointClear(Vector3(nx, 0, nz), nil, GetFarmTillSpacing(), nil, nil, nil, TILLSOIL_IGNORE_TAGS) then
                    local plant = SpawnPrefab(spawnItem)
                    plant.Transform:SetPosition(nx, 0, nz)
                    totaluse = totaluse + 4
                end
            end
        end
        inst.components.finiteuses:Use(totaluse)
        return true
    end
    local function RemoveSpecialAbility(inst)
        if inst.specialtask2m then
            inst.specialtask2m:Cancel()
            inst.specialtask2m = nil
        end
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and owner.sg and owner.sg:HasStateTag("busy") then
            inst.specialtask2m = inst:DoTaskInTime(6, inst.RemoveSpecialAbility2hm)
            return
        end
        -- 干草叉,耕地机
        inst:RemoveInherentAction(ACTIONS.TERRAFORM)
        inst:RemoveComponent("terraformer")
    end
    local function RefreshSpecialAbility(inst)
        if inst.specialtask2m then
            inst.specialtask2m:Cancel()
            inst.specialtask2m = inst:DoTaskInTime(6, inst.RemoveSpecialAbility2hm)
        end
    end
    local function AddSpecialAbility(inst)
        if inst.specialtask2m then
            inst.specialtask2m:Cancel()
            inst.specialtask2m = inst:DoTaskInTime(6, inst.RemoveSpecialAbility2hm)
            return
        end
        inst.specialtask2m = inst:DoTaskInTime(6, inst.RemoveSpecialAbility2hm)
        -- 干草叉,耕地机
        inst:AddInherentAction(ACTIONS.TERRAFORM)
        inst:AddComponent("terraformer")
        inst.components.terraformer.oldAction2hm = inst.components.terraformer.Terraform
        inst.components.terraformer.Terraform = NewTerraform
    end
    ACTIONS.SHAVE.priority = math.max((ACTIONS.ROW.priority or 0) + 1, ACTIONS.SHAVE.priority or 0)
    AddComponentAction("EQUIPPED", "shaver2hm", function(inst, doer, target, actions, right)
        if right then
            if target:HasTag("bearded") and not (target:HasTag("beefalo") and not target:HasTag("brushable")) and
                (not target:HasTag("spiderden") or doer:HasTag("spiderwhisperer")) and
                not (target ~= doer and doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) then 
                table.insert(actions, ACTIONS.SHAVE) 
            end
        end
    end)
    -- 添加火腿棒的刮肉动作支持
    AddComponentAction("USEITEM", "shaver2hm", function(inst, doer, target, actions, right) -- 多用斧镐
        if target:HasTag("hambat2hm") then  
            table.insert(actions, ACTIONS.SHAVE)
        end
    end)
    AddComponentAction("USEITEM", "shaver", function(inst, doer, target, actions, right)
        if target:HasTag("hambat2hm") then
            table.insert(actions, ACTIONS.SHAVE)
        end
    end)
    local oldSHAVEfn = ACTIONS.SHAVE.fn
    ACTIONS.SHAVE.fn = function(act)
        -- 优先处理火腿棒刮肉
        if act.target and act.target.components.hambat2hm and act.invobject and 
           (act.invobject.components.shaver or act.invobject.components.shaver2hm) then
            return act.target.components.hambat2hm:Shave(act.doer)
        end

        local specialprocess = false
        if act.invobject and act.invobject.components.shaver2hm and not act.invobject.components.shaver then
            specialprocess = true
            act.invobject:AddComponent("shaver")
        end
        local result = oldSHAVEfn(act)
        if specialprocess then act.invobject:RemoveComponent("shaver") end
        return result
    end
    AddStategraphPostInit("wilson", function(sg)
        local oldOnEnter = sg.states.shave.onenter
        sg.states.shave.onenter = function(inst)
            local specialprocess = false
            local invobject = nil
            if inst.bufferedaction and inst.bufferedaction.invobject and inst.bufferedaction.invobject.components.shaver2hm and
                not inst.bufferedaction.invobject.components.shaver then
                specialprocess = true
                invobject = inst.bufferedaction.invobject
                invobject:AddComponent("shaver")
            end
            oldOnEnter(inst)
            if specialprocess then invobject:RemoveComponent("shaver") end
        end
    end)
    -- 排队论支持批量
    local function clientDetect(target)
        return (target:HasTag("bearded") and not (target:HasTag("beefalo") and not target:HasTag("brushable")) and
                   (not target:HasTag("spiderden") or ThePlayer:HasTag("spiderwhisperer")) and not target:HasTag("player") and
                   not (ThePlayer.replica.rider ~= nil and ThePlayer.replica.rider:IsRiding())) 
               or target:HasTag("hambat2hm") -- 添加火腿棒支持
    end
    AddComponentPostInit("actionqueuer", function(self) if self.AddAction then self.AddAction("rightclick", "SHAVE", clientDetect) end end)
    local function modifyuseconsumption(uses, action, doer, target)
        if (action == ACTIONS.ROW or action == ACTIONS.ROW_FAIL or action == ACTIONS.ROW_CONTROLLER) and doer:HasTag("master_crewman") then
            uses = uses / 2
        end
        return uses
    end
    AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
        inst:AddTag("allow_action_on_impassable")
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("ondropped", AddSpecialAbility)
        -- inst:ListenForEvent("onremove", inst.RemoveSpecialAbility2hm)
        inst.AddSpecialAbility2hm = AddSpecialAbility
        inst.RefreshSpecialAbility2hm = RefreshSpecialAbility
        inst.RemoveSpecialAbility2hm = RemoveSpecialAbility
        -- 干草叉,掉地上才有
        inst.components.finiteuses:SetConsumption(ACTIONS.TERRAFORM, 0.5)
        -- 剃须刀
        -- inst:AddComponent("shaver")
        inst:AddComponent("shaver2hm")
        -- 铲子
        inst.components.tool:SetAction(ACTIONS.DIG, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
        inst:AddInherentAction(ACTIONS.DIG)
        inst.components.finiteuses:SetConsumption(ACTIONS.DIG, 4)
        -- 锤子
        inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
        inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 1.334)
        -- 园艺锄,耕地机
        inst:AddInherentAction(ACTIONS.TILL)
        inst:AddComponent("farmtiller")
        inst.components.farmtiller.oldAction2hm = inst.components.farmtiller.Till
        inst.components.farmtiller.Till = NewTill
        inst.components.finiteuses:SetConsumption(ACTIONS.TILL, 4)
        -- 桨
        inst:AddComponent("oar")
        inst.components.oar.force = TUNING.BOAT.OARS.MONKEY.FORCE
        inst.components.oar.max_velocity = TUNING.BOAT.OARS.MONKEY.MAX_VELOCITY
        inst.components.finiteuses:SetConsumption(ACTIONS.ROW, 0.2)
        inst.components.finiteuses:SetConsumption(ACTIONS.ROW_CONTROLLER, 0.2)
        inst.components.finiteuses:SetConsumption(ACTIONS.ROW_FAIL, TUNING.BOAT.OARS.MONKEY.ROW_FAIL_WEAR * 0.2)
        inst.components.finiteuses.modifyuseconsumption = modifyuseconsumption
        -- 劈砍动作
        if ACTIONS.HACK and TOOLACTIONS[ACTIONS.HACK.id] then inst.components.tool:SetAction(ACTIONS.HACK) end
    end)
    AddComponentPostInit("playercontroller", function(self)
        if self.automation_tasks and self.automation_tasks.paddle and self.automation_tasks.paddle.IsValidOar then
            local oldIsValidOar = self.automation_tasks.paddle.IsValidOar
            self.automation_tasks.paddle.IsValidOar = function(ent, ...)
                return ent ~= nil and (oldIsValidOar(ent, ...) or ent.prefab == "multitool_axe_pickaxe")
            end
        end
    end)
    AddRecipePostInit("multitool_axe_pickaxe",
                      function(inst) inst.ingredients = {Ingredient("goldenpickaxe", 1), Ingredient("hammer", 1), Ingredient("thulecite", 2)} end)
end

-- 刮地皮头盔自动种树;放草叉自动刮地皮
if GetModConfigData("Turf-Raiser Helm Plant Tree Cone") then
    local containers = require("containers")
    if containers and containers.params and containers.params.antlionhat then
        local olditemtestfn = containers.params.antlionhat.itemtestfn
        local newitemtestfn = function(container, item, slot)
            return
                item:HasTag("deployable") or item:HasTag("tool") or item:HasTag("sharp") or item.prefab == "townportaltalisman" or item:HasTag("fertilizer") or
                    item.prefab == "cane" or item.prefab == "orangestaff" or item:HasTag("wateringcan")
        end
        containers.params.antlionhat.itemtestfn = function(container, item, slot, ...)
            return (olditemtestfn == nil or olditemtestfn(container, item, slot, ...)) or newitemtestfn(container, item, slot)
        end
    end
    local function trywatersource(self, item, owner, ents, px, py, pz)
        for _, ent in ipairs(ents) do
            if ent and ent:IsValid() and ent ~= owner and ent:HasTag("watersource") and item and item:IsValid() and item.components.fillable:Fill(ent) then
                self.totalwork2hm = (self.totalwork2hm or 0) + 0.25
                return ent
            end
        end
    end
    TUNING.ANTLIONHAT_REPAIR2hm = 20
    local actions_antlionhat = {ACTIONS.NET, ACTIONS.CHOP, ACTIONS.DIG, ACTIONS.MINE, ACTIONS.HAMMER}
    local actions2_antlionhat = {ACTIONS.NET, ACTIONS.CHOP, ACTIONS.DIG, ACTIONS.MINE}
    local function canitemdospecactions(item)
        if item and item:IsValid() and item.components.tool then
            for _, action in ipairs(actions_antlionhat) do if item.components.tool:CanDoAction(action) then return true end end
        end
    end
    local function canuseitemwork(item, owner, isusefullequip)
        return item and item:IsValid() and (isusefullequip or (item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HANDS and
                   (item.components.equippable.restrictedtag == nil or owner:HasTag(item.components.equippable.restrictedtag)) and
                   (not item:HasTag("vetcurse_item") or owner:HasTag("vetcurse")))) and
                   ((item.inherentactions and (item.inherentactions[ACTIONS.TERRAFORM] or item.inherentactions[ACTIONS.TILL])) or
                       (item.components.tool and canitemdospecactions(item)) or (item.components.wateryprotection and item.components.fillable))
    end
    local enablemultitool = GetModConfigData("Multi Tool Is Almighty Tool")
    local function useitemtowork(self, ents, tileents, owner, item, px, py, pz, cx, cy, cz, x, y, ...)
        -- -- 角色被打断时不再工作
        -- if owner.sg and owner.sg.currentstate and owner.sg.currentstate.name == "mine_recoil" then
        --     self.continuework2hm = true
        --     return true
        -- end
        -- self.continuework2hm = true则本次工作完成后一定延迟后进行下次工作
        -- return true则本次不继续工作
        if enablemultitool and item and item:IsValid() and item.prefab == "multitool_axe_pickaxe" and item.components.finiteuses and
            item.components.finiteuses.current <= 20 then return true end
        -- 清理陷坑
        if item and item:IsValid() and (item.inherentactions and item.inherentactions[ACTIONS.TERRAFORM]) or
            (enablemultitool and item.prefab == "multitool_axe_pickaxe") then
            for _, ent in ipairs(ents) do
                if ent and ent:IsValid() and ent ~= owner and item and item:IsValid() and ent.prefab == "antlion_sinkhole" and ent.persists and
                    ent.components.timer and item.components.finiteuses then
                    ent.remainingrepairs = ent.remainingrepairs or 1
                    local use = (ent.components.timer:GetTimeLeft("nextrepair") or 100) / TUNING.AUTOSAVE_INTERVAL * 4 *
                                    (item.components.finiteuses.consumption[ACTIONS.TERRAFORM] or .125)
                    if enablemultitool and item.prefab == "multitool_axe_pickaxe" and item.components.finiteuses.current <= use then return end
                    item.components.finiteuses:Use(use)
                    self:FinishTerraforming(px, py, pz)
                    ent.components.timer:StopTimer("nextrepair")
                    ent:PushEvent("timerdone", {name = "nextrepair"})
                    self.totalwork2hm = (self.totalwork2hm or 0) + 10
                    self.continuework2hm = true
                    return true
                elseif ent and ent:IsValid() and ent ~= owner and item and item:IsValid() and ent.prefab == "eyeofterror_sinkhole" and ent.persists and
                    ent.components.timer and item.components.finiteuses then
                    local use = (ent.components.timer:GetTimeLeft("repair") or 100) / TUNING.AUTOSAVE_INTERVAL * 4 *
                                    (item.components.finiteuses.consumption[ACTIONS.TERRAFORM] or .125)
                    if enablemultitool and item.prefab == "multitool_axe_pickaxe" and item.components.finiteuses.current <= use then return end
                    item.components.finiteuses:Use(use)
                    self:FinishTerraforming(px, py, pz)
                    ent.components.timer:StopTimer("repair")
                    ent:PushEvent("timerdone", {name = "repair"})
                    self.totalwork2hm = (self.totalwork2hm or 0) + 10
                    self.continuework2hm = true
                    return true
                end
            end
        end
        -- 捕虫,砍树,挖掘,挖矿,锤建筑
        local actions = self.handsitem2hm and actions2_antlionhat or actions_antlionhat
        for _, action in ipairs(actions) do
            if item and item:IsValid() and item.components.tool and item.components.tool:CanDoAction(action) then
                for _, ent in ipairs(ents) do
                    if ent and ent:IsValid() and ent ~= owner and item and item:IsValid() and ent:HasTag(action.id .. "_workable") and ent.components.workable and
                        ent.components.workable.action == action and not ent:HasTag("swc2hm") and not ent.rangeweapondata2hm then
                        for index = 1, 10 do
                            if ent and ent:IsValid() and item and item:IsValid() and not ent:HasTag("INLIMBO") and ent.components.workable and
                                ent.components.workable.action == action and ent.components.workable.workable then
                                local left = ent.components.workable.workleft
                                if BufferedAction(owner, ent, action, item):Do() then
                                    self.totalwork2hm = (self.totalwork2hm or 0) + 1
                                    if self.totalwork2hm and self.totalwork2hm >= 10 then
                                        self:FinishTerraforming(px, py, pz)
                                        self.continuework2hm = true
                                        return true
                                    end
                                    if ent:IsValid() and ent.components.workable and ent.components.workable.workleft == left then
                                        break
                                    end
                                else
                                    break
                                end
                            else
                                break
                            end
                        end
                    end
                end
                if self.totalwork2hm and self.totalwork2hm > 0 then
                    self:FinishTerraforming(px, py, pz)
                    self.continuework2hm = true
                    return true
                end
            end
        end
        -- 干草叉刮地皮
        if item and item:IsValid() and item.inherentactions and item.inherentactions[ACTIONS.TERRAFORM] then
            if BufferedAction(owner, nil, ACTIONS.TERRAFORM, item, Vector3(cx, cy, cz)):Do() then
                self.totalwork2hm = (self.totalwork2hm or 0) + 1
                self:FinishTerraforming(px, py, pz)
                return true
            end
        end
        -- 园艺锄挖坑
        if item and item:IsValid() and item.inherentactions and item.inherentactions[ACTIONS.TILL] and TheWorld.Map:GetTileAtPoint(cx, 0, cz) ==
            WORLD_TILES.FARMING_SOIL then
            local farm_plants = 0
            for _, ent in ipairs(tileents) do
                if ent and ent:IsValid() and ent ~= owner and ((ent:HasTag("soil") and not ent:HasTag("NOCLICK")) or ent:HasTag("farm_plant")) then
                    farm_plants = farm_plants + 1
                end
            end
            -- 地面上还有可能有物品导致挖坑不够
            if farm_plants < 9 then
                local farm_soils = 0
                for _, ent in ipairs(tileents) do
                    if ent and ent:IsValid() and ent ~= owner and ent:HasTag("soil") then
                        if not ent:HasTag("NOCLICK") then farm_soils = farm_soils + 1 end
                        ent:PushEvent("collapsesoil")
                    end
                end
                if item.prefab == "multitool_axe_pickaxe" and enablemultitool then item.oldtill2hm = true end
                local spacing = 1.3
                local index = 1
                for i = -1, 1 do
                    for j = -1, 1 do
                        local nx = cx - spacing * i
                        local nz = cz - spacing * j
                        local rot = owner.Transform:GetRotation()
                        if rot then
                            if rot <= -90 then
                                nx = cx - spacing * j
                                nz = cz + spacing * i
                            elseif rot <= 0 then
                                nx = cx + spacing * i
                                nz = cz + spacing * j
                            elseif rot >= 0 then
                                nx = cx + spacing * j
                                nz = cz - spacing * i
                            end
                        end
                        if index <= farm_soils then
                            if TheWorld.Map:CanTillSoilAtPoint(nx, 0, nz, false) then
                                index = index + 1
                                TheWorld.Map:CollapseSoilAtPoint(nx, 0, nz)
                                SpawnPrefab("farm_soil").Transform:SetPosition(nx, 0, nz)
                            end
                        elseif item and item:IsValid() and BufferedAction(owner, nil, ACTIONS.TILL, item, Vector3(nx, 0, nz)):Do() then
                            self.totalwork2hm = (self.totalwork2hm or 0) + 1
                        end
                    end
                end
                if item.prefab == "multitool_axe_pickaxe" and enablemultitool then item.oldtill2hm = nil end
            end
            if self.totalwork2hm and self.totalwork2hm > 0 then self:FinishTerraforming(px, py, pz) end
            return true
        end
        -- 水壶浇水
        if item and item:IsValid() and item:HasTag("wateringcan") and item.components.wateryprotection and item.components.fillable and
            item.components.finiteuses then
            local firsttrywatersource = item.components.finiteuses:GetPercent() <= 0
            local watersource = firsttrywatersource and trywatersource(self, item, owner, ents, px, py, pz) or nil
            if not firsttrywatersource or watersource then
                item.components.wateryprotection:SpreadProtectionAtPoint(px, 0, pz, 4)
                SpawnPrefab("ocean_splash_med2").Transform:SetPosition(px, 0, pz)
                self.totalwork2hm = (self.totalwork2hm or 0) + 0.25
                if firsttrywatersource then
                    if watersource and watersource:IsValid() and watersource:HasTag("watersource") and item and item:IsValid() then
                        item.components.fillable:Fill(watersource)
                    end
                else
                    watersource = trywatersource(self, item, owner, ents, px, py, pz)
                end
                self:FinishTerraforming(px, py, pz)
                self.continuework2hm = true
                return true
            elseif watersource then
                self:FinishTerraforming(px, py, pz)
                self.continuework2hm = true
                return true
            end
        end
    end
    -- 工作代码
    local function findnearents(px, py, pz, checkPhysicsRadius)
        local ents = TheSim:FindEntities(px, py, pz, checkPhysicsRadius and 8 or 4, nil,
                                         {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR", "walkableplatform", "walkableperipheral"})
        if not checkPhysicsRadius then return ents end
        local tmpents = {}
        for index, ent in ipairs(ents) do
            local range = 4 + ent:GetPhysicsRadius(0)
            if ent:GetDistanceSqToPoint(px, py, pz) < range * range then table.insert(tmpents, ent) end
        end
        return tmpents
    end
    local function newDoTerraform(self, px, py, pz, x, y, ...)
        -- 只处理蚁狮头盔
        if self.inst.prefab ~= "antlionhat" then return self.oldDoTerraform2hm(self, px, py, pz, x, y, ...) end
        self.totalwork2hm = 0
        -- 没有被装备则不工作
        local owner = self.inst.components.inventoryitem.owner
        if not (owner and owner.components.locomotor and owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) == self.inst) then
            self:StopTerraforming()
            return
        end
        -- 读取手部单位和容器内单位并预备补充容器内材料
        self.inst.itemname2hm = nil
        local item = self.container:GetItemInSlot(1)
        local handsitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if not ((item and item:IsValid()) or (handsitem and handsitem:IsValid())) then return end
        local canhandsitem = canuseitemwork(handsitem, owner, true)
        if item == nil and not canhandsitem then return end
        self.inst.itemname2hm = item and item.prefab
        -- 开始工作
        if item and item.prefab == "townportaltalisman" and item.components.stackable and self.inst.components.finiteuses then
            -- 消耗格子内沙之石补充耐久
            local needs = math.floor((self.inst.components.finiteuses.total - self.inst.components.finiteuses.current) / TUNING.ANTLIONHAT_REPAIR2hm)
            local stacksize = item.components.stackable.stacksize
            if needs and needs > 0 and stacksize then
                local uses = math.min(needs, stacksize)
                item.components.stackable:Get(uses):Remove()
                self.inst.components.finiteuses:Repair(uses * TUNING.ANTLIONHAT_REPAIR2hm)
            end
            return
        end
        -- 读取可操作对象
        if item and (item.prefab == "cane" or item.prefab == "orangestaff") then
            -- 重置陷阱,限速1次1个,以防恢复速度太快，必须手杖放格子里，否则会有不必要的性能
            local ents = findnearents(px, py, pz)
            for _, ent in ipairs(ents) do
                if ent and ent:IsValid() and ent ~= owner and ent:HasTag("minesprung") and not ent:HasTag("mine_not_reusable") then
                    if BufferedAction(owner, ent, ACTIONS.RESETMINE):Do() then
                        self.totalwork2hm = (self.totalwork2hm or 0) + 1
                        self:FinishTerraforming(px, py, pz)
                        return true
                    end
                elseif ent and ent:IsValid() and ent ~= owner and ent.components.deployable and
                    (ent.prefab == "dug_trap_starfish" or (ent.components.mine and ent.components.mine.inactive == true)) then
                    if ent.components.deployable:Deploy(ent:GetPosition(), owner) then
                        self.totalwork2hm = (self.totalwork2hm or 0) + 1
                        self:FinishTerraforming(px, py, pz)
                        return true
                    end
                end
            end
        elseif canhandsitem then
            -- 手部有工具,优先使用手部工具并支持和格子内工具混用，此时不进行后续各类种植部署操作
            self.handsitem2hm = true
            local ents = findnearents(px, py, pz, true)
            local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(px, py, pz)
            local tileents = TheWorld.Map:GetEntitiesOnTileAtPoint(cx, 0, cz)
            for _, ent in ipairs(tileents) do
                if ent and ent:IsValid() and ent ~= owner and not table.contains(ents, ent) then table.insert(ents, ent) end
            end
            self.continuework2hm = nil
            if useitemtowork(self, ents, tileents, owner, handsitem, px, py, pz, cx, cy, cz, x, y, ...) then
                self.inst.itemname2hm = nil
                return self.continuework2hm
            elseif canuseitemwork(item, owner) then
                self.handsitem2hm = false
                if useitemtowork(self, ents, tileents, owner, item, px, py, pz, cx, cy, cz, x, y, ...) then return self.continuework2hm end
            end
        elseif canuseitemwork(item, owner) then
            -- 手部无工具，格子内有工具
            self.handsitem2hm = false
            local ents = findnearents(px, py, pz, true)
            local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(px, py, pz)
            local tileents = TheWorld.Map:GetEntitiesOnTileAtPoint(cx, 0, cz)
            for _, ent in ipairs(tileents) do
                if ent and ent:IsValid() and ent ~= owner and not table.contains(ents, ent) then table.insert(ents, ent) end
            end
            self.continuework2hm = nil
            if useitemtowork(self, ents, tileents, owner, item, px, py, pz, cx, cy, cz, x, y, ...) then return self.continuework2hm end
        elseif item and item:IsValid() and item.tile then
            -- 铺地皮
            self.totalwork2hm = 1
            return self.oldDoTerraform2hm(self, px, py, pz, x, y, ...)
        elseif item and item:IsValid() and item.components.fertilizer then
            -- 给枯萎浆果丛施肥
            local ents = findnearents(px, py, pz)
            local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(px, py, pz)
            local tileents = TheWorld.Map:GetEntitiesOnTileAtPoint(cx, 0, cz)
            for _, ent in ipairs(tileents) do
                if ent and ent:IsValid() and ent ~= owner and not table.contains(ents, ent) then table.insert(ents, ent) end
            end
            for _, ent in ipairs(ents) do
                if ent and ent:IsValid() and ent ~= owner and item and item:IsValid() and not ent:HasTag("player") and item.components.stackable and
                    item.components.stackable.stacksize >= 1 and
                    ((ent:HasTag("notreadyforharvest") and not ent:HasTag("withered")) or ent:HasTag("fertile") or ent:HasTag("infertile") or
                        ent:HasTag("barren") or ent:HasTag("fertilizable")) then
                    if BufferedAction(owner, ent, ACTIONS.FERTILIZE, item):Do() then
                        self.totalwork2hm = (self.totalwork2hm or 0) + 1
                        self:FinishTerraforming(px, py, pz)
                        return true
                    end
                end
            end
        elseif item and item:IsValid() and item.components.deployable and item.components.deployable:IsDeployable(owner) then
            -- 浆果丛各类等种植部署
            local spacing = item.components.deployable:DeploySpacingRadius()
            if item.components.deployable.spacing == DEPLOYSPACING.DEFAULT then
                if item._custom_candeploy_fn and item.components.deployable.mode == DEPLOYMODE.CUSTOM then
                    if item:HasTag("deployedfarmplant") then spacing = 1.3 end
                end
            end
            if item.components.deployable.usegridplacer then spacing = 2.1 end
            -- 陷阱范围调整
            if item.components.mine and spacing and spacing < 2 and not (handsitem and (handsitem.prefab == "cane" or handsitem.prefab == "orangestaff")) then
                spacing = 2
            end
            if spacing == nil or spacing == 0 then return end
            local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(px, py, pz)
            local obj = self.container:RemoveItem(item)
            if obj and obj:IsValid() then
                local num = math.floor(2 / spacing)
                for i = -num, num do
                    for j = -num, num do
                        local nx = cx - spacing * i
                        local nz = cz - spacing * j
                        local rot = owner.Transform:GetRotation()
                        if rot then
                            if rot <= -90 then
                                nx = cx - spacing * j
                                nz = cz + spacing * i
                            elseif rot <= 0 then
                                nx = cx + spacing * i
                                nz = cz + spacing * j
                            elseif rot >= 0 then
                                nx = cx + spacing * j
                                nz = cz - spacing * i
                            end
                        end
                        if obj.components.deployable:Deploy(Vector3(nx, 0, nz), owner, rot) then
                            self.totalwork2hm = (self.totalwork2hm or 0) + 1
                            self:FinishTerraforming(px, py, pz)
                            return true
                        end
                    end
                end
                self.container:GiveItem(obj)
            end
        elseif item and item:IsValid() and item.components.farmplantable then
            -- 种子埋坑里
            local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(px, py, pz)
            local tileents = TheWorld.Map:GetEntitiesOnTileAtPoint(cx, 0, cz)
            local obj = self.container:RemoveItem(item)
            if obj and obj:IsValid() then
                for _, ent in ipairs(tileents) do
                    if ent and ent:IsValid() and ent ~= owner and ent:HasTag("soil") and not ent:HasTag("NOCLICK") and
                        obj.components.farmplantable:Plant(ent, owner) then
                        self.totalwork2hm = (self.totalwork2hm or 0) + 1
                        self:FinishTerraforming(px, py, pz)
                        return true
                    end
                end
                self.container:GiveItem(obj)
            end
        end
    end
    -- 计算实际消耗耐久,是原来的十倍;补充用完的道具
    local function newFinishTerraforming(self, x, y, z, ...)
        if self.totalwork2hm and self.totalwork2hm > 0 then
            if self.inst.components.finiteuses then self.inst.components.finiteuses:Use(-(10 - self.totalwork2hm) / 10) end
            self.totalwork2hm = 0
        end
        if self.inst.itemname2hm and self.container:GetItemInSlot(1) == nil then
            local owner = self.inst.components.inventoryitem.owner
            if owner and owner.components.inventory then
                local newitem = owner.components.inventory:FindItem(function(item) return item.prefab == self.inst.itemname2hm end)
                if newitem ~= nil and newitem:IsValid() then
                    local item
                    if newitem.components.stackable and newitem.components.stackable.stacksize >
                        (newitem.components.stackable.originalmaxsize or newitem.components.stackable.maxsize) then
                        item = newitem.components.stackable:Get(newitem.components.stackable.originalmaxsize or newitem.components.stackable.maxsize)
                    else
                        item = newitem.components.inventoryitem:RemoveFromOwner(true)
                    end
                    self.container:GiveItem(item, 1)
                end
            end
            self.inst.itemname2hm = nil
        end
        return self.oldFinishTerraforming2hm(self, x, y, z, ...)
    end
    -- 切换手中道具或格子内道具都会刷新一次工作
    local function newOnUpdate(self, dt, ...)
        self.oldOnUpdate2hm(self, dt, ...)
        local px, py, pz = self.inst.Transform:GetWorldPosition()
        local x, y = TheWorld.Map:GetTileXYAtPoint(px, py, pz)
        if not ((self.last_x == nil and self.last_y == nil) or (self.last_x ~= x or self.last_y ~= y) or
            (self.last_x == x and self.last_y == y and self.repeat_delay == 0)) then
            local owner = self.inst.components.inventoryitem.owner
            local item = self.container:GetItemInSlot(1)
            local handsitem = owner and owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if self.last_owner2hm ~= owner or self.last_item2hm ~= item or self.last_handsitem2hm ~= handsitem then
                self.last_owner2hm = owner
                self.last_item2hm = item
                self.last_handsitem2hm = handsitem
                self.repeat_delay = nil
                local repeat_tile = self:DoTerraform(px, py, pz, x, y)
                self.last_x, self.last_y = x, y
                if repeat_tile then self.repeat_delay = self.repeat_tile_delay end
            end
        end
    end
    -- 快速修复耐久
    local function onitemget(inst, data)
        if inst.prefab == "antlionhat" and inst.components.container:GetItemInSlot(1) ~= nil and inst.components.autoterraformer then
            local item = inst.components.container:GetItemInSlot(1)
            if item and item.prefab == "townportaltalisman" and item.components.stackable and inst.components.finiteuses then
                local needs = math.floor((inst.components.finiteuses.total - inst.components.finiteuses.current) / TUNING.ANTLIONHAT_REPAIR2hm)
                local stacksize = item.components.stackable.stacksize
                if needs and needs > 0 and stacksize then
                    local uses = math.min(needs, stacksize)
                    item.components.stackable:Get(uses):Remove()
                    inst.components.finiteuses:Repair(uses * TUNING.ANTLIONHAT_REPAIR2hm)
                    inst.components.autoterraformer.totalwork2hm = 0
                    local px, py, pz = inst.Transform:GetWorldPosition()
                    inst.components.autoterraformer:FinishTerraforming(px, py, pz)
                end
            end
        end
    end
    AddComponentPostInit("autoterraformer", function(self)
        self.totalwork2hm = 0
        self.oldDoTerraform2hm = self.DoTerraform
        self.DoTerraform = newDoTerraform
        self.oldFinishTerraforming2hm = self.FinishTerraforming
        self.FinishTerraforming = newFinishTerraforming
        self.oldOnUpdate2hm = self.OnUpdate
        self.OnUpdate = newOnUpdate
        self.inst:ListenForEvent("itemget", onitemget)
    end)
    local function onequip(inst, data)
        if data.owner and data.owner:HasTag("player") and data.owner.components.carefulwalker then
            data.owner.carefulwalkingspeedmult2hm = data.owner.components.carefulwalker.carefulwalkingspeedmult
            data.owner.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(1)
        end
    end
    local function onunequip(inst, data)
        if data.owner and data.owner:HasTag("player") and data.owner.components.carefulwalker then
            data.owner.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(data.owner.carefulwalkingspeedmult2hm or TUNING.CAREFUL_SPEED_MOD)
        end
    end
    local processhack
    AddPrefabPostInit("antlionhat", function(inst)
        inst:AddTag("goggles")
        inst.repairmaterials2hm = {townportaltalisman = TUNING.ANTLIONHAT_REPAIR2hm}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
        inst:ListenForEvent("equipped", onequip)
        inst:ListenForEvent("unequipped", onunequip)
        if ACTIONS.HACK and not processhack and TOOLACTIONS[ACTIONS.HACK.id] then
            processhack = true
            table.insert(actions_antlionhat, ACTIONS.HACK)
            table.insert(actions2_antlionhat, ACTIONS.HACK)
        end
    end)
end

-- 铥矿棒格挡攻击
local ThuleciteMode = GetModConfigData("Thulecite Equip Parry")
if ThuleciteMode then
    local function Parry(inst, target, pos, caster)
        if not pos and target then pos = target:GetPosition() end
        caster:PushEvent("combat_parry", {direction = inst:GetAngleToPoint(pos), duration = 5, weapon = inst})
        inst.components.rechargeable:Discharge(12)
        inst.components.spellcaster.canuseontargets = false
        inst.components.spellcaster.canuseondead = false
        inst.components.spellcaster.canuseonpoint = false
        inst.components.spellcaster.canuseonpoint_water = false
        inst.components.spellcaster.spell = nil
        inst.reticule2hm:set(false)
        if inst.components.parryweapon then inst.components.parryweapon.parrytargets = {} end
    end
    local function OnPreParry(inst, doer)
        if doer and doer.SoundEmitter then
            if ThuleciteMode == -1 and doer.sg and doer.Physics then
                if doer.sg.statemem then doer.sg.statemem.isphysicstoggle = nil end
                doer.Physics:ClearCollisionMask()
                doer.Physics:CollidesWith(COLLISION.WORLD)
                doer.Physics:CollidesWith(COLLISION.OBSTACLES)
                doer.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
                doer.Physics:CollidesWith(COLLISION.CHARACTERS)
                doer.Physics:CollidesWith(COLLISION.GIANTS)
            end
            doer.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_pre")
        end
        if inst.components.parryweapon then inst.components.parryweapon.parrytargets = {} end
    end
    local function OnParry(inst, doer, attacker, damage)
        if doer and doer.SoundEmitter then
            doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)
            doer.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
            inst.components.finiteuses:Use(attacker and attacker:HasTag("epic") and 1 or 0.34)
            if doer.prefab == "wathgrithr" and doer.components.skilltreeupdater ~= nil and
                doer.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_shield_2") and inst.components.rechargeable and
                inst.components.rechargeable:GetPercent() < TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION then
                inst.components.rechargeable:SetPercent(TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION)
            end
        end
        if inst.components.parryweapon and inst.components.parryweapon.parrytargets and attacker and attacker:IsValid() then
            table.insert(inst.components.parryweapon.parrytargets, attacker.GUID)
        end
    end
    local function ReticuleTargetFn() return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0)) end
    local function ReticuleMouseTargetFn(inst, mousepos)
        if mousepos ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            local dx = mousepos.x - x
            local dz = mousepos.z - z
            local l = dx * dx + dz * dz
            if l <= 0 then return inst.components.reticule.targetpos end
            l = 6.5 / math.sqrt(l)
            return Vector3(x + dx * l, 0, z + dz * l)
        end
    end
    local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
        local x, y, z = inst.Transform:GetWorldPosition()
        reticule.Transform:SetPosition(x, 0, z)
        local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
        if ease and dt ~= nil then
            local rot0 = reticule.Transform:GetRotation()
            local drot = rot - rot0
            rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
        end
        reticule.Transform:SetRotation(rot)
    end
    local function disableStatus(inst)
        inst.components.spellcaster.canuseontargets = false
        inst.components.spellcaster.canuseondead = false
        inst.components.spellcaster.canuseonpoint = false
        inst.components.spellcaster.canuseonpoint_water = false
        inst.components.spellcaster.spell = nil
        inst.reticule2hm:set(false)
    end
    local function enableStatus(inst)
        inst.components.spellcaster:SetSpellFn(Parry)
        inst.components.spellcaster.canuseontargets = true
        inst.components.spellcaster.canuseondead = true
        inst.components.spellcaster.canuseonpoint = true
        inst.components.spellcaster.canuseonpoint_water = true
        inst.reticule2hm:set(true)
    end
    local function UpdateStatus(inst)
        if not inst:IsValid() then return end
        local owner = inst.components.inventoryitem.owner
        if inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.rechargeable and inst.components.rechargeable:IsCharged() and
            owner and owner:IsValid() and owner:HasTag("player") and not owner:HasTag("playerghost") and
            not (owner.components.rider and owner.components.rider:IsRiding()) then
            enableStatus(inst)
        else
            disableStatus(inst)
        end
    end
    local function EnableReticule(inst, enable)
        if enable then
            if inst.components.reticule == nil then
                inst:AddComponent("reticule")
                inst.components.reticule.reticuleprefab = "reticulearc"
                inst.components.reticule.pingprefab = "reticulearcping"
                inst.components.reticule.targetfn = ReticuleTargetFn
                inst.components.reticule.mousetargetfn = ReticuleMouseTargetFn
                inst.components.reticule.updatepositionfn = ReticuleUpdatePositionFn
                inst.components.reticule.validcolour = {1, .75, 0, 1}
                inst.components.reticule.invalidcolour = {.5, 0, 0, 1}
                inst.components.reticule.ease = true
                inst.components.reticule.mouseenabled = true
                inst.components.reticule.ispassableatallpoints = true
                if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                    ThePlayer.replica.inventory:IsHolding(inst) then ThePlayer.components.playercontroller:RefreshReticule() end
            end
        elseif inst.components.reticule ~= nil then
            inst:RemoveComponent("reticule")
            if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                ThePlayer.replica.inventory:IsHolding(inst) then ThePlayer.components.playercontroller:RefreshReticule() end
        end
    end
    local function OnreticuleDirty(inst) EnableReticule(inst, inst.reticule2hm:value()) end
    local function onequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            inst:ListenForEvent("mounted", inst._updatestatus, data.owner)
            inst:ListenForEvent("dismounted", inst._updatestatus, data.owner)
            inst:ListenForEvent("death", inst._updatestatus, data.owner)
        end
        UpdateStatus(inst)
    end
    local function onunequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            inst:RemoveEventCallback("mounted", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("dismounted", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("death", inst._updatestatus, data.owner)
        end
        UpdateStatus(inst)
    end
    STRINGS.ACTIONS.CASTSPELL.RUINS_BAT = STRINGS.ACTIONS.CASTAOE.LAVAARENA_HEAVYBLADE
    local function actfn(act, inst)
        if act.action == ACTIONS.CASTSPELL and not act.pos and act.target then
            act.pos = DynamicPosition(not TheNet:IsDedicated() and TheInput:GetWorldPosition() or act.target:GetPosition())
        end
    end
    AddPrefabPostInit("ruins_bat", function(inst)
        inst.spelltype = "RUINS_BAT"
        if not inst:HasTag("parryweapon") then
            inst:AddTag("parryweapon2hm")
            inst:AddTag("allow_action_on_impassable")
            inst.reticule2hm = net_bool(inst.GUID, "ruinsbat.reticule2hm", "ruinsbatreticule2hmdirty")
            inst:ListenForEvent("ruinsbatreticule2hmdirty", OnreticuleDirty)
            inst.actfn2hm = actfn
        end
        if not TheWorld.ismastersim then return end
        if TheWorld:HasTag("cave") then inst.components.equippable.insulated = true end
        if not inst:HasTag("parryweapon") and not inst.components.parryweapon and not inst.components.rechargeable and not inst.components.spellcaster then
            inst:AddComponent("spellcaster")
            inst.components.spellcaster:SetSpellFn(Parry)
            inst.components.spellcaster.canuseontargets = true
            inst.components.spellcaster.canuseondead = true
            inst.components.spellcaster.canuseonpoint = true
            inst.components.spellcaster.canuseonpoint_water = true
            inst.components.spellcaster.canusefrominventory = false
            inst.components.spellcaster.can_cast_fn = truefn
            inst:AddComponent("parryweapon")
            inst.components.parryweapon.onpreparryfn = OnPreParry
            inst.components.parryweapon.onparryfn = OnParry
            inst:AddComponent("rechargeable")
            inst.components.rechargeable:SetMaxCharge(12)
            inst.components.rechargeable:SetOnChargedFn(UpdateStatus)
            inst.components.rechargeable:SetOnDischargedFn(UpdateStatus)
            inst:ListenForEvent("equipped", onequip)
            inst:ListenForEvent("unequipped", onunequip)
            inst._updatestatus = function() UpdateStatus(inst) end
        end
    end)
    AddComponentPostInit("parryweapon", function(self)
        local TryParry = self.TryParry
        self.TryParry = function(self, doer, attacker, damage, ...)
            if not (attacker and attacker:IsValid()) or TryParry(self, doer, attacker, damage, ...) then return true end
            if self.parrytargets and table.contains(self.parrytargets, attacker.GUID) then
                if self.onparryfn ~= nil then self.onparryfn(self.inst, doer, attacker, damage) end
                return true
            end
            return false
        end
        -- local OnPreParry = self.OnPreParry
        self.OnPreParry = function(self, doer, ...)
            if doer.sg then doer.sg:PushEvent("start_parry") end
            if self.onparrystart ~= nil then self.onparrystart(self.inst, doer) end
            if self.onpreparryfn ~= nil then self.onpreparryfn(self.inst, doer) end
        end
    end)
    AddStategraphPostInit("wilson", function(sg)
        local _OldCASTSPELL = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
        sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
            if action.invobject and action.invobject:HasTag("parryweapon2hm") then
                return "parry_pre"
            else
                return _OldCASTSPELL(inst, action, ...)
            end
        end
    end)
    AddStategraphPostInit("wilson_client", function(sg)
        local _OldCASTSPELL = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
        sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
            if action.invobject and action.invobject:HasTag("parryweapon2hm") then
                return "parry_pre"
            else
                return _OldCASTSPELL(inst, action, ...)
            end
        end
    end)
    -- 洞穴绝缘
    AddPrefabPostInit("ruinshat", function(inst)
        if not TheWorld.ismastersim then return end
        if TheWorld:HasTag("cave") then inst.components.equippable.insulated = true end
    end)
    AddPrefabPostInit("armorruins", function(inst)
        if not TheWorld.ismastersim then return end
        if TheWorld:HasTag("cave") then inst.components.equippable.insulated = true end
    end)
end

-- 玻璃刀跳劈
local GlassCutter = GetModConfigData("Glass Cutter Leap Attack")
if GlassCutter then
    local function disableStatus(inst)
        inst.components.weapon:SetRange(nil)
        inst:RemoveTag("leapattack2hm")
        inst.components.spellcaster.canuseontargets = false
        inst.components.spellcaster.canuseondead = false
        inst.components.spellcaster.canuseonpoint = false
        inst.components.spellcaster.canuseonpoint_water = false
        inst.components.spellcaster.spell = nil
        inst.reticule2hm:set(false)
        inst.level2hm = 0
        inst.weaponlevel2hm:set(inst.level2hm)
        inst.components.weapon.attackrange = nil
        inst.components.weapon.hitrange = nil
        local owner = inst.components.inventoryitem.owner
        if owner and owner.prefab == "wathom" then
            inst.damagemultiplier2hm = nil
            inst.components.aoeweapon_leap:SetDamage(inst.components.weapon.damage)
        else
            inst.damagemultiplier2hm = 1.5
            inst.components.aoeweapon_leap:SetDamage(inst.components.weapon.damage * inst.damagemultiplier2hm)
        end
    end
    local function costhunger(inst, hungervalue)
        local owner = inst.components.inventoryitem.owner
        if owner and owner.components.hunger and owner.components.hunger.current > hungervalue then
            owner.components.hunger:DoDelta(-hungervalue)
            return true
        end
        return false
    end
    local function enableStatus(inst)
        local owner = inst.components.inventoryitem.owner
        if not owner or not owner.components.sanity then return disableStatus(inst) end
        -- if not owner.components.sanity:IsSane() then return disableStatus(inst) end
        local extrasanity = owner.components.sanity:IsInsanityMode() and ((owner.components.sanity:GetPercentWithPenalty() or 0) - 0.35) or
                                (0.65 - (owner.components.sanity:GetPercentWithPenalty() or 0))
        inst.level2hm =
            owner.prefab ~= "wathom" and (math.clamp(math.ceil(math.max(extrasanity / 0.2, inst.components.perishable:GetPercent() / 0.25)), 1, 4)) or 1
        inst.weaponlevel2hm:set(inst.level2hm)
        inst.components.weapon.attackrange = ({2, 4, 5, 6})[inst.level2hm]
        inst.components.weapon.hitrange = nil
        if owner.prefab ~= "wathom" then
            inst.damagemultiplier2hm = (1.25 + inst.level2hm * 0.25)
            inst.components.aoeweapon_leap:SetDamage(inst.components.weapon.damage * inst.damagemultiplier2hm)
        else
            inst.damagemultiplier2hm = nil
            inst.components.aoeweapon_leap:SetDamage(inst.components.weapon.damage)
        end
        inst:AddTag("leapattack2hm")
        inst.components.spellcaster:SetSpellFn(inst.spell2hm)
        inst.components.spellcaster.canuseontargets = true
        inst.components.spellcaster.canuseondead = true
        inst.components.spellcaster.canuseonpoint = true
        inst.components.spellcaster.canuseonpoint_water = true
        inst.reticule2hm:set(true)
    end
    local function actiondistanceFunc(inst, bufferedAction)
        return 20
    end
    local function UpdateStatus(inst)
        if not inst:IsValid() then return end
        local owner = inst.components.inventoryitem.owner
        if not inst.components.perishable or (inst.components.perishable.perishremainingtime or 0) <= 0 or not inst.components.equippable:IsEquipped() or
            not inst.components.rechargeable or not inst.components.rechargeable:IsCharged() or not (owner and owner:IsValid()) or not owner:HasTag("player") or
            owner:HasTag("playerghost") or (owner.components.rider and owner.components.rider:IsRiding()) then return disableStatus(inst) end
        enableStatus(inst)
    end
    local function AnvilStrike(inst, target, pos, doer)
        if doer.components.combat then
            doer.components.combat:RestartCooldown()
        end
        local x, y, z = doer.Transform:GetWorldPosition()
        if not pos then if target then pos = target:GetPosition() end end
        if TheWorld.Map:IsAboveGroundAtPoint(pos.x, pos.y, pos.z) or TheWorld.Map:GetPlatformAtPoint(pos.x, pos.z) ~= nil then
            doer:PushEvent("combat_leap", {targetpos = pos, weapon = inst})
            local pulse_fx = SpawnPrefab("alterguardian_phase3trapgroundfx")
            pulse_fx.Transform:SetPosition(pos.x, 0, pos.z)
            pulse_fx.AnimState:SetDeltaTimeMultiplier(4)
            pulse_fx:DoTaskInTime(3, pulse_fx.Remove)
            pulse_fx.AnimState:SetMultColour(1, 1, 1, 0.5)
            inst.pulse_fx = pulse_fx
        else
            doer.components.talker:Say(TUNING.isCh2hm and "唔,差点跳到海里" or "Swimming is not a good idea.")
        end
    end
    local function OnPreLeap(inst, doer, startingpos, targetpos)
        if doer then
            if doer.components.combat then
                doer.components.combat:RestartCooldown()
            end
        end
    end
    local function OnLeap(inst, doer, startingpos, targetpos)
        if inst.pulse_fx and inst.pulse_fx:IsValid() then
            inst.pulse_fx.AnimState:PlayAnimation("meteorground_pst")
            inst.pulse_fx.AnimState:SetDeltaTimeMultiplier(1)
            inst.pulse_fx:ListenForEvent("animover", inst.pulse_fx.Remove)
            inst.pulse_fx = nil
        end
        local range = math.sqrt(distsq(startingpos.x, startingpos.z, targetpos.x, targetpos.z))
        if doer and doer.components.locomotor then
            doer.components.locomotor.isrunning = true
            doer.Physics:SetMotorVel(range / 2 + 2.5 + (inst.level2hm or 1) * 2.5, 0, 0)
            doer.components.locomotor:StartUpdatingInternal()
        end
        if not costhunger(inst, 4 + range / 4) then
            if inst:IsValid() and inst.components.rechargeable then inst.components.rechargeable:Discharge(6 + range / 2) end
        end
        UpdateStatus(inst)
        if inst.components.perishable then inst.components.perishable:AddTime(-(range / 8 + 2) * TUNING.MOONGLASS_CHARGED_PERISH_TIME / 75) end
        if inst.components.finiteuses then inst.components.finiteuses:Use(range / 8 + 2) end
        if doer and doer.sg then
            doer.sg:RemoveStateTag("busy")
            doer.sg:RemoveStateTag("doing")
            doer.sg:RemoveStateTag("nopredict")
            doer.sg:AddStateTag("idle")
        end
        if doer and doer.components.playercontroller then doer.components.playercontroller:Enable(true) end
    end
    local function ReticuleTargetFn()
        local player = ThePlayer
        local ground = TheWorld.Map
        local pos = Vector3()
        for r = 7, 0, -.25 do
            pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
            if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then return pos end
        end
        return pos
    end
    local function EnableReticule(inst, enable)
        if enable then
            if inst.components.reticule == nil then
                inst:AddComponent("reticule")
                inst.components.reticule.reticuleprefab = "reticuleaoe"
                inst.components.reticule.pingprefab = "reticuleaoeping"
                inst.components.reticule.targetfn = ReticuleTargetFn
                inst.components.reticule.validcolour = {1, .75, 0, 1}
                inst.components.reticule.invalidcolour = {.5, 0, 0, 1}
                inst.components.reticule.ease = true
                inst.components.reticule.mouseenabled = true
                inst.components.reticule.ispassableatallpoints = true
                if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                    ThePlayer.replica.inventory:IsHolding(inst) then ThePlayer.components.playercontroller:RefreshReticule() end
            end
        elseif inst.components.reticule ~= nil then
            inst:RemoveComponent("reticule")
            if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                ThePlayer.replica.inventory:IsHolding(inst) then ThePlayer.components.playercontroller:RefreshReticule() end
        end
    end
    local function OnreticuleDirty(inst) EnableReticule(inst, inst.reticule2hm:value()) end
    local function onequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            inst:ListenForEvent("sanitydelta", inst._updatestatus, data.owner)
            inst:ListenForEvent("mounted", inst._updatestatus, data.owner)
            inst:ListenForEvent("dismounted", inst._updatestatus, data.owner)
            inst:ListenForEvent("death", inst._updatestatus, data.owner)
        end
        UpdateStatus(inst)
    end
    local function onunequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            inst:RemoveEventCallback("sanitydelta", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("mounted", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("dismounted", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("death", inst._updatestatus, data.owner)
        end
        UpdateStatus(inst)
    end
    local function resetweaponperishableview(inst)
        inst.resetviewtask2hm = nil
        local grandowner = inst.components.inventoryitem:GetGrandOwner()
        if not (grandowner and grandowner.Transform) then return end
        local x, y, z = grandowner.Transform:GetWorldPosition()
        if not TheWorld.Map:IsPassableAtPoint(x, y, z, true) then return end
        local owner = inst.components.inventoryitem.owner
        if owner and owner.components.inventory then
            if inst.components.equippable:IsEquipped() then
                owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
                owner:AddChild(inst)
                inst:RemoveFromScene()
                inst:DoTaskInTime(0, function() owner.components.inventory:Equip(inst) end)
            else
                local prevslot = owner.components.inventory:GetItemSlot(inst)
                owner.components.inventory:RemoveItem(inst)
                owner:AddChild(inst)
                inst:RemoveFromScene()
                inst:DoTaskInTime(0, function() owner.components.inventory:GiveItem(inst, prevslot) end)
            end
        elseif owner and owner.components.container then
            local prevslot = owner.components.container:GetItemSlot(inst)
            owner.components.container:RemoveItem(inst)
            owner:AddChild(inst)
            inst:RemoveFromScene()
            inst:DoTaskInTime(0, function() owner.components.container:GiveItem(inst, prevslot) end)
        end
    end
    local function onrepaired(inst, repairuse, doer, repair_item, useitems)
        if repair_item.prefab == "moonglass_charged" or repair_item.prefab == "purebrilliance" or repair_item.prefab == "purebrilliance2hm" then
            if inst.components.finiteuses:GetPercent() >= 1 then useitems = useitems + 0.5 end
            local is_pure = (repair_item.prefab == "purebrilliance" or repair_item.prefab == "purebrilliance2hm")
            if not inst.components.perishable then
                inst:AddTag("show_spoilage")
                inst:AddComponent("perishable")
                inst.components.perishable.perishtime = TUNING.MOONGLASS_CHARGED_PERISH_TIME
                inst.components.perishable.perishremainingtime = TUNING.MOONGLASS_CHARGED_PERISH_TIME / 5 * math.clamp(useitems, 1, 5) *
                                                                     (is_pure and 2 or 1)
                inst.components.perishable:StartPerishing()
                if not inst.resetviewtask2hm then inst.resetviewtask2hm = inst:DoTaskInTime(0, resetweaponperishableview) end
                UpdateStatus(inst)
            else
                inst.components.perishable:AddTime(TUNING.MOONGLASS_CHARGED_PERISH_TIME / 5 * useitems * (is_pure and 2 or 1))
            end
        end
    end
    local function onperished(inst)
        if inst.components.perishable then
            inst:RemoveTag("show_spoilage")
            inst:RemoveComponent("perishable")
            inst:DoTaskInTime(0, resetweaponperishableview)
            UpdateStatus(inst)
        end
    end
    local function checkweapon(inst)
        if inst.components.perishable and (inst.components.perishable.perishremainingtime or 0) <= 0 then
            inst:RemoveTag("show_spoilage")
            inst:RemoveComponent("perishable")
            if not inst.resetviewtask2hm then inst.resetviewtask2hm = inst:DoTaskInTime(0, resetweaponperishableview) end
            UpdateStatus(inst)
        end
    end
    local function DisplayNameFn(inst)
        return inst:HasTag("show_spoilage") and ((TUNING.isCh2hm and "注能" or "Infused ") .. STRINGS.NAMES.GLASSCUTTER ..
                   (inst.weaponlevel2hm and inst.weaponlevel2hm:value() > 0 and
                       (" Lv" .. inst.weaponlevel2hm:value() .. (inst.weaponlevel2hm:value() >= 4 and " Max" or "")) or "")) or nil
    end
    local function itemtiletextfn(inst, itemtile)
        local leveltext
        local tmplevel = inst.weaponlevel2hm and inst.weaponlevel2hm:value()
        if tmplevel and tmplevel > 0 then
            leveltext = "Lv" .. tmplevel
            inst.spelltype = "GLASSCUTTER" .. tmplevel
            if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                ThePlayer.replica.inventory:IsHolding(inst) and ThePlayer.HUD and ThePlayer.HUD.controls and ThePlayer.HUD.controls.hover then
                ThePlayer.HUD.controls.hover:OnUpdate()
            end
        end
        return "weaponlevel2hmdirty", leveltext
    end
    STRINGS.ACTIONS.CASTSPELL.GLASSCUTTER = TUNING.isCh2hm and "跃斩" or "Leap Attack"
    STRINGS.ACTIONS.CASTSPELL.GLASSCUTTER1 = TUNING.isCh2hm and "跃斩 Lv1" or "Leap Atk Lv1"
    STRINGS.ACTIONS.CASTSPELL.GLASSCUTTER2 = TUNING.isCh2hm and "跃斩 Lv2" or "Leap Atk Lv2"
    STRINGS.ACTIONS.CASTSPELL.GLASSCUTTER3 = TUNING.isCh2hm and "跃斩 Lv3" or "Leap Atk Lv3"
    STRINGS.ACTIONS.CASTSPELL.GLASSCUTTER4 = TUNING.isCh2hm and "跃斩 Lv4 Max" or "Leap Atk Lv4 Max"
    AddPrefabPostInit("glasscutter", function(inst)
        if inst:HasTag("aoeweapon_leap") then return end
        inst.spelltype = "GLASSCUTTER"
        inst.repairmaterials2hm = {moonglass_charged = TUNING.GLASSCUTTER.USES / 7, purebrilliance = TUNING.GLASSCUTTER.USES / 3, purebrilliance2hm = TUNING.GLASSCUTTER.USES / 3}
        if GetModConfigData("Construction Amulet Repair Equip") then inst.repairmaterials2hm.moonglass = TUNING.GLASSCUTTER.USES / 7 end
        inst.displaynamefn = DisplayNameFn
        inst.itemtilefn2hm = itemtiletextfn
        -- inst:AddTag("hide_percentage")
        inst:AddTag("show_spoilage")
        inst:AddTag("allow_action_on_impassable")
        inst._explode2hm = net_event(inst.GUID, "glasscutter._explode")
        inst.reticule2hm = net_bool(inst.GUID, "glasscutter.reticule2hm", "glasscutterreticule2hmdirty")
        inst:ListenForEvent("glasscutterreticule2hmdirty", OnreticuleDirty)
        inst.weaponlevel2hm = net_tinybyte(inst.GUID, "weapon.level2hm", "weaponlevel2hmdirty")
        if not TheWorld.ismastersim then
            inst:ListenForEvent("glasscutter._explode", CreateGroundFX)
            return inst
        end
        if GlassCutter == true and inst.components.weapon then
            local onattack = inst.components.weapon.onattack
            inst.components.weapon:SetOnAttack(function(inst, attacker, target, ...)
                local shadow_aligned, shadowcreature
                if target and target:IsValid() then
                    shadow_aligned = TUNING.DSTU and target:HasTag("shadow_aligned")
                    shadowcreature = target:HasOneOfTags({"shadowcreature", "nightmarecreature"})
                end
                if shadow_aligned then target:RemoveTag("shadow_aligned") end
                if onattack ~= nil then onattack(inst, attacker, target, ...) end
                if target:IsValid() then
                    if shadow_aligned then target:AddTag("shadow_aligned") end
                    if shadowcreature and target.components.health and target.components.health:IsDead() and attacker and attacker:IsValid() and
                        attacker.components.sanity then attacker.components.sanity:DoDelta(target.components.health.maxhealth * 0.05) end
                end
            end)
        end
        if inst.components.aoeweapon_leap then return end
        inst:AddComponent("aoeweapon_leap")
        if not inst.components.aoeweapon_leap.damage then
            inst:RemoveComponent("aoeweapon_leap")
            inst:RemoveTag("show_spoilage")
            inst:RemoveTag("allow_action_on_impassable")
            return
        end
        inst.components.aoeweapon_leap:SetDamage(inst.components.weapon.damage)
        inst.components.aoeweapon_leap:SetWorkActions()
        inst.components.aoeweapon_leap.tags = {"_combat"}
        inst.components.aoeweapon_leap:SetOnLeaptFn(OnLeap)
        inst.components.aoeweapon_leap:SetOnPreLeapFn(OnPreLeap)
        inst:AddComponent("perishable")
        inst.components.perishable.perishtime = TUNING.MOONGLASS_CHARGED_PERISH_TIME
        inst.components.perishable.perishremainingtime = 0
        inst.components.perishable:StartPerishing()
        inst:DoTaskInTime(0, checkweapon)
        inst:ListenForEvent("perished", onperished)
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.ignoremax = true
        inst.components.repairable2hm.onrepaired = onrepaired
        inst:AddComponent("spellcaster")
        inst.components.spellcaster:SetSpellFn(AnvilStrike)
        inst.components.spellcaster.canuseontargets = true
        inst.components.spellcaster.canuseondead = true
        inst.components.spellcaster.canuseonpoint = true
        inst.components.spellcaster.canuseonpoint_water = true
        inst.components.spellcaster.canusefrominventory = false
        inst.components.spellcaster.can_cast_fn = truefn
        inst.actiondistanceFunc2hm = actiondistanceFunc
        inst:AddComponent("rechargeable")
        inst.components.rechargeable:SetMaxCharge(24)
        inst.components.rechargeable:SetOnChargedFn(UpdateStatus)
        inst.components.rechargeable:SetOnDischargedFn(UpdateStatus)
        inst:ListenForEvent("equipped", onequip)
        inst:ListenForEvent("unequipped", onunequip)
        inst._updatestatus = function() UpdateStatus(inst) end
        inst.spell2hm = AnvilStrike
        inst.level2hm = 0
        inst.weaponlevel2hm:set(0)
    end)
    local leapattackstate = State {
        name = "leapattack2hm",
        tags = {"attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt"},
        onenter = function(inst, data)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            if target then
                local canRange = inst.components.combat:CalcAttackRangeSq(target)
                canRange = math.min(canRange * 1.2, canRange + 12)
                if inst:GetDistanceSqToInst(target) > canRange then
                    inst.sg:GoToState("knockback2hm", {
                        propsmashed = true,
                        knocker = inst,
                        radius = 3,
                        strengthmult = 1,
                    })
                    return
                end
            end
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_leap", false)
            inst.Transform:SetEightFaced()
            -- inst.AnimState:ClearOverrideBuild("player_lunge")
            -- inst.AnimState:ClearOverrideBuild("player_attack_leap")
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            if inst.components.playercontroller ~= nil then inst.components.playercontroller:RemotePausePrediction() end
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.sg.statemem.level = equip and equip.level2hm or 1
            costhunger(equip, 4)
            if equip and equip.components.perishable then equip.components.perishable:AddTime(-TUNING.MOONGLASS_CHARGED_PERISH_TIME / 75) end
            inst.sg.statemem.flash = 0
            if inst.prefab ~= "wathom" then
                inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + inst.sg.statemem.level * 0.25, "glasscutter2hm")
            end
        end,
        onexit = function(inst)
            if inst.prefab ~= "wathom" then inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "glasscutter2hm") end
            -- inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then inst.components.combat:CancelAttack() end
            inst.Transform:SetFourFaced()
            inst.components.locomotor:Stop()
            inst.Physics:ClearMotorVelOverride()
            inst:DoTaskInTime(0, function(inst) if inst.components.playercontroller then inst.components.playercontroller:Enable(true) end end)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            if inst.sg.statemem.flash then
                inst.components.bloomer:PopBloom("leap2hm")
                inst.components.colouradder:PopColour("leap2hm")
            end
            -- inst.AnimState:AddOverrideBuild("player_lunge")
            -- inst.AnimState:AddOverrideBuild("player_attack_leap")
        end,
        timeline = {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.WORLD)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                if target ~= nil then
                    inst.sg.statemem.startingpos = inst:GetPosition()
                    inst.sg.statemem.targetpos = target:GetPosition()
                    if target ~= nil then
                        if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                            inst.leapvelocity2hm = math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                                                    inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES)
                        end
                    end
                end
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
            end),
            TimeEvent(10 * FRAMES, function(inst) if inst.sg.statemem.flash then inst.components.colouradder:PushColour("leap2hm", .1, .1, 0, 0) end end),
            TimeEvent(11 * FRAMES, function(inst) if inst.sg.statemem.flash then inst.components.colouradder:PushColour("leap2hm", .2, .2, 0, 0) end end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.flash then inst.components.colouradder:PushColour("leap2hm", .4, .4, 0, 0) end
                inst.sg:RemoveStateTag("abouttoattack")
                inst.components.locomotor:Stop()
                inst.Physics:ClearMotorVelOverride()
                inst:PerformBufferedAction()
                inst.components.playercontroller:Enable(false)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.sg:RemoveStateTag("busy")
                inst.Physics:CollidesWith(COLLISION.OBSTACLES)
                inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PushBloom("leap2hm", "shaders/anim.ksh", -2)
                    inst.components.colouradder:PushColour("leap2hm", 1, 1, 0, 0)
                    inst.sg.statemem.flash = 1.3
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                inst.leapvelocity2hm = inst.sg.statemem.level * 2.5 + (not inst:HasTag("wearingheavyarmor") and 2.5 or 0)
                SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end),
            TimeEvent(19 * FRAMES, function(inst) SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
            TimeEvent(24 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("attack")
                inst.sg:RemoveStateTag("nointerrupt")
                inst.sg:RemoveStateTag("pausepredict")
                inst.sg:AddStateTag("idle")
                inst.leapvelocity2hm = 0
                inst.Physics:Stop()
                inst.Physics:CollidesWith(COLLISION.CHARACTERS) -- Re-enabling Wathom's normal collision.
                inst.Physics:CollidesWith(COLLISION.GIANTS)
                inst.components.playercontroller:Enable(true)
                if inst.sg.statemem.flash then inst.components.bloomer:PopBloom("leap2hm") end
            end)
        },
        onupdate = function(inst)
            if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                inst.components.colouradder:PushColour("leap2hm", c, c, 0, 0)
            end
            if inst.leapvelocity2hm then inst.Physics:SetMotorVel(inst.leapvelocity2hm, 0, 0) end
        end,
        events = {EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)}
    }
    AddStategraphState("wilson", leapattackstate)
    AddStategraphPostInit("wilson", function(sg)
        -- sg.states.combat_leap.tags.notalking = true
        local _OldCASTSPELL = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
        sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
            if not (inst.components.rider and inst.components.rider:IsRiding()) and action.invobject and action.invobject:HasTag("aoeweapon_leap") and
                action.invobject:HasTag("leapattack2hm") then
                return "combat_leap_start"
            else
                return _OldCASTSPELL(inst, action, ...)
            end
        end
        local Attack_Old = sg.actionhandlers[ACTIONS.ATTACK].deststate
        sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
            local handler = Attack_Old(inst, action, ...)
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local rider = inst.replica.rider
            if not (rider and rider:IsRiding()) and equip and equip:HasTag("aoeweapon_leap") and equip:HasTag("leapattack2hm") and
                not inst.components.rider:IsRiding() then
                    return "leapattack2hm"
                end
            return handler
        end
    end)
    AddStategraphPostInit("wilson_client", function(sg)
        local _OldCASTSPELL = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
        sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
            if action.invobject and action.invobject:HasTag("aoeweapon_leap") and action.invobject:HasTag("leapattack2hm") then
                return "combat_leap_start"
            else
                return _OldCASTSPELL(inst, action, ...)
            end
        end
        sg.states.combat_leap_start.server_states[hash("leapattack2hm")] = true
        local ClientAttack_Old = sg.actionhandlers[ACTIONS.ATTACK].deststate
        sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
            local handler = ClientAttack_Old(inst, action, ...)
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local rider = inst.replica.rider
            if equip and equip:HasTag("aoeweapon_leap") and equip:HasTag("leapattack2hm") and not (rider ~= nil and rider:IsRiding()) then
                return "combat_leap_start"
            end
            return handler
        end
    end)
end

-- 充能暗夜剑
local ChargedNightsword = GetModConfigData("Charged Nightsword")
if ChargedNightsword then

    local NIGHTSWORD_CHARGE_TIME = 5000                         -- 充能时间5000秒 
    local NIGHTSWORD_CHARGED_PHYSICAL = 48                      -- 充能状态物理伤害
    local NIGHTSWORD_CHARGED_PLANAR = 20                        -- 充能状态位面伤害
    local MAX_SHADOW_MINIONS = 5                                -- 最多召唤5个暗影小人
    
    local function ResetWeaponView(inst)
        inst.resetviewtask2hm = nil
        local grandowner = inst.components.inventoryitem:GetGrandOwner()
        if not (grandowner and grandowner.Transform) then return end
        local x, y, z = grandowner.Transform:GetWorldPosition()
        if not TheWorld.Map:IsPassableAtPoint(x, y, z, true) then return end
        local owner = inst.components.inventoryitem.owner
        if owner and owner.components.inventory then
            if inst.components.equippable:IsEquipped() then
                owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
                owner:AddChild(inst)
                inst:RemoveFromScene()
                inst:DoTaskInTime(0, function() owner.components.inventory:Equip(inst) end)
            else
                local prevslot = owner.components.inventory:GetItemSlot(inst)
                owner.components.inventory:RemoveItem(inst)
                owner:AddChild(inst)
                inst:RemoveFromScene()
                inst:DoTaskInTime(0, function() owner.components.inventory:GiveItem(inst, prevslot) end)
            end
        elseif owner and owner.components.container then
            local prevslot = owner.components.container:GetItemSlot(inst)
            owner.components.container:RemoveItem(inst)
            owner:AddChild(inst)
            inst:RemoveFromScene()
            inst:DoTaskInTime(0, function() owner.components.container:GiveItem(inst, prevslot) end)
        end
    end
    
    local function OnRepaired(inst, repairuse, doer, repair_item)

        if repair_item.prefab == "horrorfuel" then

            if not inst:HasTag("charged_nightsword") then

                inst:AddTag("charged_nightsword")
                inst:AddTag("jab")  
                inst:AddTag("pointy")  

                inst:AddTag("hide_percentage") 
                inst:AddTag("show_spoilage")                

                if not inst.components.planardamage then
                    inst:AddComponent("planardamage")
                    inst.components.planardamage:SetBaseDamage(NIGHTSWORD_CHARGED_PLANAR)
                end

                if inst.components.weapon then
                    inst.components.weapon:SetDamage(NIGHTSWORD_CHARGED_PHYSICAL)
                end
                
                if not inst.components.perishable then
                    inst:AddComponent("perishable")
                    inst.components.perishable.perishtime = NIGHTSWORD_CHARGE_TIME
                    inst.components.perishable.perishremainingtime = NIGHTSWORD_CHARGE_TIME / 2
                    inst.components.perishable:StartPerishing()
                else
                    inst.components.perishable.perishtime = NIGHTSWORD_CHARGE_TIME
                end
                
                if not inst.resetviewtask2hm then 
                    inst.resetviewtask2hm = inst:DoTaskInTime(0, ResetWeaponView) 
                end
            else
                inst.components.perishable:AddTime(NIGHTSWORD_CHARGE_TIME / 2)
            end
            
            if doer and doer.SoundEmitter then
                doer.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
            end
            
            if repair_item.components and repair_item.components.stackable then
                repair_item.components.stackable:Get(useitems):Remove()
            else
                repair_item:Remove()
            end            
            return true
        elseif repair_item.prefab == "nightmarefuel" then
            return -1
        end
        return -1
    end
    
    local function OnPerished(inst)
        inst:RemoveTag("charged_nightsword")
        inst:RemoveTag("jab")  
        inst:RemoveTag("pointy")  
        
        
        if inst.components.planardamage then
            inst:RemoveComponent("planardamage")
        end
        
        if inst.components.weapon then
            inst.components.weapon:SetDamage(TUNING.NIGHTSWORD_DAMAGE or 68)
        end
        
        inst.stab_count = 0
        
        if inst.components.perishable then
            inst.components.perishable:StopPerishing()
            inst:RemoveComponent("perishable")
        end

        -- 失效后恢复耐久显示
        inst:RemoveTag("show_spoilage")
        inst:RemoveTag("hide_percentage")  

        if not inst.resetviewtask2hm then 
            inst.resetviewtask2hm = inst:DoTaskInTime(0, ResetWeaponView) 
        end
    end

    local function CheckCharged(inst)
        if inst.components.perishable and (inst.components.perishable.perishremainingtime or 0) > 0 then

            if not inst:HasTag("charged_nightsword") then

                inst:AddTag("charged_nightsword")
                inst:AddTag("show_spoilage")
                inst:AddTag("jab")  
                inst:AddTag("pointy")  
                inst:AddTag("hide_percentage")  -- 充能后隐藏耐久显示
                
                if not inst.components.planardamage then
                    inst:AddComponent("planardamage")
                    inst.components.planardamage:SetBaseDamage(NIGHTSWORD_CHARGED_PLANAR)
                end
                
                if inst.components.weapon then
                    inst.components.weapon:SetDamage(NIGHTSWORD_CHARGED_PHYSICAL)
                end
                
            end
        elseif inst:HasTag("charged_nightsword") then
            OnPerished(inst)
        end
    end
    
    local function DisplayNameFn(inst)
        return inst:HasTag("charged_nightsword") and ((TUNING.isCh2hm and "充能" or "Charged ") .. STRINGS.NAMES.NIGHTSWORD) or nil
    end
    
    AddPrefabPostInit("nightsword", function(inst)

        inst.displaynamefn = DisplayNameFn
        inst:AddTag("allow_action_on_impassable")
        inst:AddTag("show_spoilage")

        inst.repairmaterials2hm = inst.repairmaterials2hm or {}
        inst.repairmaterials2hm.nightmarefuel = TUNING.NIGHTSWORD_USES / 7  
        inst.repairmaterials2hm.horrorfuel = 1
        
        -- 移除充能状态下的"变质的"前缀
        inst.displayadjectivefn = function(inst)
            if inst:HasTag("charged_nightsword") then
                return nil  
            end
            -- 默认逻辑
            if inst:HasTag("stale") then
                return inst:HasTag("frozen") and STRINGS.UI.HUD.STALE_FROZEN or STRINGS.UI.HUD.STALE
            elseif inst:HasTag("spoiled") then
                return inst:HasTag("frozen") and STRINGS.UI.HUD.STALE_FROZEN or STRINGS.UI.HUD.SPOILED
            end
            return nil
        end

        if not TheWorld.ismastersim then return end

        
        if inst.components.weapon then
            local old_onattack = inst.components.weapon.onattack
            inst.components.weapon:SetOnAttack(function(weapon, attacker, target, ...)
                -- 充能状态下使用攻击计数机制
                if inst:HasTag("charged_nightsword") and target and target:IsValid() then
                    -- 前3次攻击：普通攻击消耗能量，第4次攻击在sg的lunge中处理，不在这里计数
                    if inst.components.perishable then
                        local damage = NIGHTSWORD_CHARGED_PHYSICAL + NIGHTSWORD_CHARGED_PLANAR
                        inst.components.perishable:ReducePercent(damage / NIGHTSWORD_CHARGE_TIME)
                    end
                end
                
                if old_onattack then
                    old_onattack(weapon, attacker, target, ...)
                end
            end)
        end
        -- 充能时消耗能量而非耐久
        if inst.components.finiteuses then
            local old_use = inst.components.finiteuses.Use
            inst.components.finiteuses.Use = function(self, num, ...)
                if inst:HasTag("charged_nightsword") then
                    return
                end
                return old_use(self, num, ...)
            end
        end

        inst:AddComponent("perishable")
        inst.components.perishable.perishtime = NIGHTSWORD_CHARGE_TIME
        inst.components.perishable.perishremainingtime = 0
        inst.components.perishable:StartPerishing()
        inst:ListenForEvent("perished", OnPerished)

        inst.stab_count = 0

        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.ignoremax = true
        inst.components.repairable2hm.customrepair = OnRepaired

        inst:DoTaskInTime(0, CheckCharged)

    end)

    -- 召唤暗影小人进行突袭攻击
    local function SpawnLungeShadowMinion(target_pos, owner, target, index, total)
        local theta = (index / total) * TWOPI
        local radius = 3.5
        local offset = Vector3(math.cos(theta) * radius, 0, math.sin(theta) * radius)
        local spawn_pos = target_pos + offset
        
        -- 检查生成位置是否可用
        if not TheWorld.Map:IsPassableAtPoint(spawn_pos:Get()) then
            radius = 2.5
            offset = Vector3(math.cos(theta) * radius, 0, math.sin(theta) * radius)
            spawn_pos = target_pos + offset
        end
        
        SpawnPrefab("statue_transition_2").Transform:SetPosition(spawn_pos:Get())
        
        -- 创建临时暗影角斗士
        local shadow = SpawnPrefab("shadowprotector")
        if not shadow then return end
        
        shadow.Transform:SetPosition(spawn_pos:Get())
        shadow:ForceFacePoint(target_pos:Get())
        
        shadow:AddTag("NOCLICK")                    -- 不可被鼠标选中
        shadow:AddTag("notarget")                   -- 不可被作为攻击目标
        shadow:AddTag("shadowminion_nightsword")    -- 标记为暗夜剑召唤物
        
        if shadow.components.health then shadow:RemoveComponent("health") end
        
        -- 复制主人的皮肤
        if owner and shadow.components.skinner and not (owner.components.health and owner.components.health:IsDead()) and not owner:HasTag("playerghost") then
            shadow.components.skinner:CopySkinsFromPlayer(owner)
        end
        
        if shadow.components.combat then
            shadow.components.combat:SetDefaultDamage(20)   -- 小人伤害固定20，冲刺会翻1.5倍
            shadow.components.combat:SetTarget(target)
            shadow.components.combat:SetRange(5)  
        end
        
        shadow.persists = false
        
        shadow:DoTaskInTime(0, function()
            if not (shadow and shadow:IsValid()) then return end
            
            if not (target and target:IsValid()) then
                shadow:Remove()
                return
            end
            
            -- 命令小人突袭
            if shadow.sg then
                shadow.sg:GoToState("lunge_pre", target)
                shadow:DoTaskInTime(1, function()
                    if shadow and shadow:IsValid() then
                        shadow:Remove()
                    end
                end)
            else
                shadow:Remove()
            end
        end)
    end
    
    -- 在目标位置召唤暗影小人
    local function SummonShadowMinions(target_pos, owner, target)
        if not target_pos or not target or not target:IsValid() then
            return
        end
        
        for i = 1, MAX_SHADOW_MINIONS do
            owner:DoTaskInTime((i - 1) * 0.2, function()
                if target and target:IsValid() then
                    SpawnLungeShadowMinion(target:GetPosition(), owner, target, i, MAX_SHADOW_MINIONS)
                end
            end)
        end
    end

    AddStategraphPostInit("wilson", function(sg)

        -- 添加暗袭状态到状态图
        -- 暗袭准备状态
        local nightsword_lunge_pre_state = State{
            name = "nightsword_lunge_pre",
            tags = {"attack", "busy", "evade", "nointerrupt"},
            
            onenter = function(inst, target)

                if not target or not target:IsValid() then
                    inst.sg:GoToState("idle")
                    return
                end
                
                inst.components.locomotor:Stop()
                
                local targetpos = target:GetPosition()
                inst:ForceFacePoint(targetpos:Get())
                
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos = targetpos
                inst.sg.statemem.weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                inst.sg.statemem.startpos = inst:GetPosition()
                
                -- 临时无敌
                inst.allmiss2hm = true
                
                inst.AnimState:PlayAnimation("lunge_pre")
                inst.SoundEmitter:PlaySound("dontstarve/common/twirl")
            end,
            
            timeline = {
                TimeEvent(8 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/common/twirl", nil, nil, true)
                end)
            },
            
            events = {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("nightsword_lunge_loop", {
                            weapon = inst.sg.statemem.weapon,
                            target = inst.sg.statemem.target,
                            targetpos = inst.sg.statemem.targetpos,
                            startpos = inst.sg.statemem.startpos
                        })
                    end
                end),
            },
            
            onexit = function(inst)
                if inst.allmiss2hm then
                    inst:DoTaskInTime(0.1, function(inst2) inst2.allmiss2hm = nil end)
                end
            end,
        }
        
        -- 暗袭执行状态
        local nightsword_lunge_loop_state = State{
            name = "nightsword_lunge_loop",
            tags = {"attack", "busy", "noattack", "evade"},
            
            onenter = function(inst, data)
                local weapon = data.weapon
                local target = data.target
                local targetpos = data.targetpos
                
                inst.AnimState:PlayAnimation("lunge_pst")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
                inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_shadow_med_sharp")
                
                if not target or not target:IsValid() then
                    inst.sg:GoToState("idle")
                    return
                end
                
                -- 设置临时无敌
                inst.allmiss2hm = true
                
                -- 面向目标
                inst:ForceFacePoint(targetpos:Get())
                
                -- 计算暗袭位移
                local start_pos = data.startpos
                local current_targetpos = target:GetPosition()
                
                -- 玩家与目标的实际距离
                local actual_distance = math.sqrt(distsq(start_pos.x, start_pos.z, current_targetpos.x, current_targetpos.z))
                
                -- 穿越方向（从起始位置到目标）
                local direction = (current_targetpos - start_pos):GetNormalized()
                
                local dest_pos = current_targetpos + direction * actual_distance * 1.5
                
                -- 检查是否在地面或平台上，避免落水
                if not (TheWorld.Map:IsAboveGroundAtPoint(dest_pos:Get()) or TheWorld.Map:GetPlatformAtPoint(dest_pos.x, dest_pos.z) ~= nil) then
                    -- 不在地面，尝试目标后方逐步缩短距离
                    for i = 1, 10 do
                        local try_distance = actual_distance * (1 - i * 0.1)
                        if try_distance < 0.5 then break end
                        dest_pos = current_targetpos + direction * try_distance
                        if TheWorld.Map:IsAboveGroundAtPoint(dest_pos:Get()) or TheWorld.Map:GetPlatformAtPoint(dest_pos.x, dest_pos.z) ~= nil then
                            break
                        end
                    end
                    -- 如果还是不行，就放在目标位置
                    if not (TheWorld.Map:IsAboveGroundAtPoint(dest_pos:Get()) or TheWorld.Map:GetPlatformAtPoint(dest_pos.x, dest_pos.z) ~= nil) then
                        dest_pos = current_targetpos
                    end
                end
                

                inst:DoTaskInTime(6 * FRAMES, function(inst)
                    if target and target:IsValid() then
                        if TheWorld.Map:IsPassableAtPoint(dest_pos:Get()) then
                            inst.Physics:Teleport(dest_pos:Get())
                        end
                        
                        -- 传送后面向目标
                        inst:ForceFacePoint(target:GetPosition():Get())
                    end
                end)
                
                -- 造成伤害
                inst:DoTaskInTime(8 * FRAMES, function(inst)
                    if not weapon or not weapon:IsValid() or not target or not target:IsValid() then
                        return
                    end
                    
                    if weapon.components.perishable then
                        local damage = NIGHTSWORD_CHARGED_PHYSICAL + NIGHTSWORD_CHARGED_PLANAR
                        weapon.components.perishable:ReducePercent(damage / NIGHTSWORD_CHARGE_TIME)
                    end
                    
                    if target.components.health and not target.components.health:IsDead() and target.components.combat and inst.components.combat then

                        local dmg, spdmg = inst.components.combat:CalcDamage(target, weapon, 1)
                        
                        target.components.combat:GetAttacked(inst, dmg, weapon, nil, spdmg)
                        
                        inst:PushEvent("onattackother", { target = target, weapon = weapon, projectile = nil, stimuli = nil })
                        
                        -- 在目标位置召唤暗影仆从
                        SummonShadowMinions(target:GetPosition(), inst, target)
                    end
                    
                                            
                    -- 无敌结束后仇恨会丢失，重新恨设置为玩家
                    target:DoTaskInTime(2, function(target) 
                        if target and target:IsValid() and target.components.combat then
                            if target.components.combat:CanTarget(inst) then
                                target.components.combat:SetTarget(inst)
                                target.components.combat:SuggestTarget(inst)
                            end
                        end
                    end)

                    inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_impact")
                    local hit_fx = SpawnPrefab("shadowstrike_slash_fx")
                    if hit_fx then
                        hit_fx.Transform:SetPosition(target.Transform:GetWorldPosition())
                    end
                end)
                
                inst.sg:SetTimeout(0.5)
            end,
            
            ontimeout = function(inst)
                inst.sg:GoToState("idle")
            end,
            
            events = {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
            
            onexit = function(inst)
                if inst.allmiss2hm then
                    inst:DoTaskInTime(0.1, function(inst) 
                        inst.allmiss2hm = nil
                    end)
                end
            end,
        }
        

        sg.states["nightsword_lunge_pre"] = nightsword_lunge_pre_state
        sg.states["nightsword_lunge_loop"] = nightsword_lunge_loop_state


        -- 攻击前检查是否需要触发暗袭
        local attack_state = sg.states["attack"]
        local old_attack_onenter_for_lunge = attack_state.onenter
        attack_state.onenter = function(inst, ...)
            
            local weapon = inst.components.combat and inst.components.combat:GetWeapon()
            
            if weapon and weapon.prefab == "nightsword" and weapon:HasTag("charged_nightsword") and weapon:HasTag("jab") then
                weapon.stab_count = (weapon.stab_count or 0) + 1
                
                -- 第4次攻击触发暗袭
                if weapon.stab_count >= 4 then
                    
                    local buffaction = inst:GetBufferedAction()
                    local target = buffaction ~= nil and buffaction.target or nil
                    
                    if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
                        -- 暗袭范围4格
                        local lunge_range = 4
                        local dist = inst:GetDistanceSqToInst(target)
                        local max_dist_sq = lunge_range * lunge_range
                        
                        if dist <= max_dist_sq then
                            weapon.stab_count = 0
                            -- 成功
                            inst.components.combat:SetTarget(target)
                            inst.components.combat:StartAttack()
                            inst.components.locomotor:Stop()
                            inst.sg:GoToState("nightsword_lunge_pre", target)
                            return
                        end
                    end
                    
                    -- 失败
                    weapon.stab_count = 0
                end
                
            end

            if old_attack_onenter_for_lunge then
                old_attack_onenter_for_lunge(inst, ...)
            end
        end
        

        local old_attack_onenter_for_speed = attack_state.onenter
        attack_state.onenter = function(inst, ...)

            if old_attack_onenter_for_speed then 
                old_attack_onenter_for_speed(inst, ...) 
            end
            
            -- 如果没有被暗袭拦截，且是充能暗夜剑，则提升攻速
            if inst.sg.currentstate.name == "attack" then
                local weapon = inst.components.combat and inst.components.combat:GetWeapon()
                if weapon and weapon.prefab == "nightsword" and weapon:HasTag("charged_nightsword") and weapon:HasTag("jab") then
                    -- 原版jab是21帧，改为10帧
                    inst.sg:SetTimeout(10 * FRAMES)
                    inst.AnimState:SetDeltaTimeMultiplier(1.5)  -- 加速动画以匹配更低的冷却
                end
            end
        end
        
        local old_attack_onexit = attack_state.onexit
        attack_state.onexit = function(inst, ...)
            inst.AnimState:SetDeltaTimeMultiplier(1)
            if old_attack_onexit then 
                old_attack_onexit(inst, ...) 
            end
        end
        
    end)
    
    -- 客户端状态图同步
    AddStategraphPostInit("wilson_client", function(sg)
        
        local old_client_attack_onenter_for_lunge = sg.states["attack"].onenter
        sg.states["attack"].onenter = function(inst, ...)
            local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            
            if weapon and weapon.prefab == "nightsword" and weapon:HasTag("charged_nightsword") and weapon:HasTag("jab") then
                weapon.stab_count = (weapon.stab_count or 0) + 1
                
                -- 触发暗袭
                if weapon.stab_count >= 4 then

                    local target = inst.replica.combat and inst.replica.combat:GetTarget()
                    
                    if target and target:IsValid() then
                        local lunge_range = 4
                        local dist = inst:GetDistanceSqToInst(target)
                        local max_dist_sq = lunge_range * lunge_range
                        
                        if dist <= max_dist_sq then
                            -- 成功
                            weapon.stab_count = 0
                            
                            if inst.replica.locomotor then
                                inst.replica.locomotor:Stop()
                            end
                            inst.sg:GoToState("nightsword_lunge_pre_client")
                            return
                        end
                    end

                    weapon.stab_count = 0
                end
            end
            
            if old_client_attack_onenter_for_lunge then
                old_client_attack_onenter_for_lunge(inst, ...)
            end
        end
        
        local old_client_attack_onenter_for_speed = sg.states["attack"].onenter
        sg.states["attack"].onenter = function(inst, ...)

            if old_client_attack_onenter_for_speed then 
                old_client_attack_onenter_for_speed(inst, ...) 
            end
            
            -- 如果没有被暗袭拦截，且是充能暗夜剑，则提升攻速
            if inst.sg.currentstate.name == "attack" then
                local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if weapon and weapon.prefab == "nightsword" and weapon:HasTag("charged_nightsword") and weapon:HasTag("jab") then
                    inst.sg:SetTimeout(10 * FRAMES)
                    inst.AnimState:SetDeltaTimeMultiplier(1.5)
                end
            end
        end
        
        local old_client_attack_onexit = sg.states["attack"].onexit
        sg.states["attack"].onexit = function(inst, ...)
            inst.AnimState:SetDeltaTimeMultiplier(1)
            if old_client_attack_onexit then 
                old_client_attack_onexit(inst, ...) 
            end
        end
        
        -- 客户端暗袭预备状态
        local nightsword_lunge_pre_client = State{
            name = "nightsword_lunge_pre_client",
            tags = {"attack", "busy", "evade", "nointerrupt"},
            
            onenter = function(inst)
                if inst.replica.combat:InCooldown() then
                    inst.sg:GoToState("idle", true)
                    return
                end
                
                local target = inst.replica.combat and inst.replica.combat:GetTarget()
                if not target or not target:IsValid() then
                    inst.sg:GoToState("idle")
                    return
                end
                
                inst.replica.combat:StartAttack()
                if inst.replica.locomotor then
                    inst.replica.locomotor:Stop()
                    inst.replica.locomotor:Clear()
                end
                
                inst:ClearBufferedAction()
                inst.entity:FlattenMovementPrediction()
                inst.entity:SetIsPredictingMovement(false)
                
                local targetpos = target:GetPosition()
                inst:ForceFacePoint(targetpos:Get())
                
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos = targetpos
                
                inst.AnimState:PlayAnimation("lunge_pre")
                inst.SoundEmitter:PlaySound("dontstarve/common/twirl")
            end,
            
            timeline = {
                TimeEvent(8 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/common/twirl", nil, nil, true)
                end)
            },
            
            events = {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("nightsword_lunge_loop_client", {
                            target = inst.sg.statemem.target,
                            targetpos = inst.sg.statemem.targetpos
                        })
                    end
                end),
            },
        }
        
        local nightsword_lunge_loop_client = State{
            name = "nightsword_lunge_loop_client",
            tags = {"attack", "busy", "noattack", "evade"},
            
            onenter = function(inst, data)
                inst.AnimState:PlayAnimation("lunge_pst")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
                inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_shadow_med_sharp")
                
                local targetpos = data and data.targetpos
                if targetpos then
                    inst:ForceFacePoint(targetpos:Get())
                end
                
                inst.sg:SetTimeout(2)
            end,
            
            onupdate = function(inst)
                if inst.sg:ServerStateMatches() then
                    if inst.entity:FlattenMovementPrediction() then 
                        inst.sg:GoToState("idle", "noanim") 
                    end
                elseif inst.bufferedaction == nil then
                    inst.sg:GoToState("idle")
                end
            end,
            
            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,
            
            events = {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
            
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        }
        
        sg.states["nightsword_lunge_pre_client"] = nightsword_lunge_pre_client
        sg.states["nightsword_lunge_loop_client"] = nightsword_lunge_loop_client

    end)
end

-- 鳞甲防御冰冻
if GetModConfigData("Scalemail Parry Freezable") then
    if TUNING.ARMORDRAGONFLY_ABSORPTION < TUNING.ARMORWOOD_ABSORPTION then TUNING.ARMORDRAGONFLY_ABSORPTION = TUNING.ARMORWOOD_ABSORPTION end
    local function armordragonflytaskfn(inst) inst.armordragonflytask2hm = nil end
    AddComponentPostInit("freezable", function(self)
        local oldResolveWearOffTime = self.ResolveWearOffTime
        self.ResolveWearOffTime = function(self, wearofftime, ...)
            local time = oldResolveWearOffTime(self, wearofftime, ...)
            if self.inst:HasTag("player") and self.inst.armordragonfly2hm and time then time = time / 2 end
            return time
        end
        local oldUnFreeze = self.Unfreeze
        self.Unfreeze = function(self, ...)
            if self.inst:HasTag("player") and self.inst.armordragonfly2hm then
                if self.inst.armordragonflytask2hm then self.inst.armordragonflytask2hm:Cancel() end
                self.inst.armordragonflytask2hm = self.inst:DoTaskInTime(self.inst.prefab == "willow" and 3 or 2, armordragonflytaskfn)
            end
            return oldUnFreeze(self, ...)
        end
        local oldAddColdness = self.AddColdness
        self.AddColdness = function(self, ...)
            if self.inst:HasTag("player") and self.inst.armordragonfly2hm and (self.inst.armordragonflytask2hm or self:IsFrozen()) then return end
            return oldAddColdness(self, ...)
        end
        local oldFreeze = self.Freeze
        self.Freeze = function(self, ...)
            if self.inst:HasTag("player") and self.inst.armordragonfly2hm and (self.inst.armordragonflytask2hm or self:IsFrozen()) then return end
            return oldFreeze(self, ...)
        end
    end)
    local function onequip(inst, data)
        if data.owner and data.owner:HasTag("player") and data.owner.components.freezable then
            data.owner.armordragonfly2hm = true
            if data.owner.armordragonflytask2hm then data.owner.armordragonflytask2hm:Cancel() end
            data.owner.armordragonflytask2hm = data.owner:DoTaskInTime(2, armordragonflytaskfn)
        end
    end
    local function onunequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            data.owner.armordragonfly2hm = nil
            if data.owner.armordragonflytask2hm then
                data.owner.armordragonflytask2hm:Cancel()
                data.owner.armordragonflytask2hm = nil
            end
        end
    end
    AddPrefabPostInit("armordragonfly", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.armor then inst.components.armor.absorb_percent = TUNING.ARMORDRAGONFLY_ABSORPTION end
        inst:ListenForEvent("equipped", onequip)
        inst:ListenForEvent("unequipped", onunequip)
    end)
    -- 熔岩虫收回和召唤
    STRINGS.ACTIONS.STOPUSINGITEM.SHOWLAVAE2HM = TUNING.isCh2hm and "召唤" or "Out"
    STRINGS.ACTIONS.STOPUSINGITEM.HIDELAVAE2HM = TUNING.isCh2hm and "召回" or "In"
    local oldSTOPUSINGITEMstrfn = ACTIONS.STOPUSINGITEM.strfn
    ACTIONS.STOPUSINGITEM.strfn = function(act)
        local res = oldSTOPUSINGITEMstrfn(act)
        if res == "LAVAE_TOOTH" and act.invobject and act.invobject.prefab == "lavae_tooth" then
            return act.invobject:HasTag("haslavae2hm") and "HIDELAVAE2HM" or "SHOWLAVAE2HM"
        end
        return res
    end
    local function addtagforlavaetooth(inst)
        if inst and inst.components.petleash ~= nil and inst.components.petleash:IsFull() then
            inst:AddTag("haslavae2hm")
        else
            inst:RemoveTag("haslavae2hm")
        end
    end
    local function on_stop_use(inst)
        inst.components.useabletargeteditem.inuse_targeted = true
        if inst ~= nil and inst.components.petleash ~= nil and not inst.components.petleash:IsFull() then
            inst.components.petleash:SpawnPetAt(inst.Transform:GetWorldPosition())
            -- for k, v in pairs(inst.components.petleash.pets) do if v.components.hunger then v.components.hunger.current = 0 end end
            inst:DoTaskInTime(0, addtagforlavaetooth)
        elseif inst and inst.components.petleash ~= nil and inst.components.petleash:IsFull() then
            for k, v in pairs(inst.components.petleash.pets) do
                if v and (not v:IsValid() or (v.components.health and v.components.health:IsDead())) then return end
                inst.disableOnPetLost2hm = true
                local fx = SpawnPrefab("spawn_fx_medium")
                fx.Transform:SetPosition(v.Transform:GetWorldPosition())
                v:Remove()
            end
            inst.disableOnPetLost2hm = nil
            inst:DoTaskInTime(0, addtagforlavaetooth)
        end
    end
    AddPrefabPostInit("lavae_tooth", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.useabletargeteditem then return end
        inst:AddComponent("useabletargeteditem")
        inst.components.useabletargeteditem.inuse_targeted = true
        inst.components.useabletargeteditem.inventory_disableable = true
        inst.components.useabletargeteditem:SetOnStopUseFn(on_stop_use)
        inst:DoTaskInTime(0, addtagforlavaetooth)
        local oldOnPetLost = inst.OnPetLost
        inst.OnPetLost = function(...) if not inst.disableOnPetLost2hm then oldOnPetLost(...) end end
    end)
end

-- 建造护符修理装备
local amuletmode = GetModConfigData("Construction Amulet Repair Equip")
if amuletmode then
    if amuletmode == -1 then
        local function greenamuletUSEITEM(inst, doer, actions, right, target)
            return target and target.prefab and target.prefab ~= "greenamulet" and AllRecipes[target.prefab] ~= nil
        end
        local function actionfn(inst, doer, target, pos, act)
            if inst and inst.prefab == "greenamulet" and inst.components.finiteuses and target and target.prefab and target.prefab ~= "greenamulet" and
                AllRecipes[target.prefab] then
                local percentusedcomponent = target.components.armor or target.components.finiteuses or target.components.fueled
                if percentusedcomponent then
                    local percent = percentusedcomponent:GetPercent()
                    if percent < 1 then
                        local repair = math.min(1 - percent, 0.45)
                        inst.components.finiteuses:Use(repair / 0.45)
                        percentusedcomponent:SetPercent(percent + repair)
                        if doer and doer.SoundEmitter then doer.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel") end
                        return true
                    end
                end
            end
        end
        STRINGS.ACTIONS.ACTION2HM.GREENAMULET = STRINGS.ACTIONS.REPAIR.GENERIC
        AddPrefabPostInit("greenamulet", function(inst)
            inst.actionothercondition2hm = greenamuletUSEITEM
            if not TheWorld.ismastersim then return end
            inst:AddComponent("action2hm")
            inst.components.action2hm.actionfn = actionfn
        end)
    end
    AddPrefabPostInit("armorgrass", function(inst)
        inst.repairmaterials2hm = {cutgrass = TUNING.ARMORGRASS / 12}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("armor_sanity", function(inst)
        inst.repairmaterials2hm = {nightmarefuel = TUNING.ARMOR_SANITY / 8}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm") 
    end)
    AddPrefabPostInit("woodcarvedhat", function(inst) -- 伍迪硬木帽可修理
	    local WOODCARVEDHAT = 262.5        
        inst.repairmaterials2hm = {log = WOODCARVEDHAT / 8}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)    
    AddPrefabPostInit("ghostflowerhat", function (inst) -- 幽魂花冠可修理
        inst.repairmaterials2hm = {ghostflower = TUNING.PERISH_MED * 0.15}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("wathgrithr_shield", function(inst) -- 武神圆盾可修理
        inst.repairmaterials2hm = {goldnugget = TUNING.WATHGRITHR_SHIELD_ARMOR / 4}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("armorwood", function(inst)
        inst.repairmaterials2hm = {log = TUNING.ARMORWOOD / 10}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("armormarble", function(inst)
        inst.repairmaterials2hm = {marble = TUNING.ARMORMARBLE / 7}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("armordragonfly", function(inst)
        inst.repairmaterials2hm = {dragon_scales = TUNING.ARMORDRAGONFLY}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("moonglassaxe", function(inst)
        inst.repairmaterials2hm = {moonglass = TUNING.AXE_USES / 3}
        if not TheWorld.ismastersim then return end
        if hardmode then inst.needgreenamulet2hm = true end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("ruinshat", function(inst)
        inst.repairmaterials2hm = {thulecite_pieces = TUNING.ARMOR_RUINSHAT / 25.5, thulecite = TUNING.ARMOR_RUINSHAT / 4.25}
        if not TheWorld.ismastersim then return end
        if hardmode then inst.needgreenamulet2hm = true end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("armorruins", function(inst)
        inst.repairmaterials2hm = {thulecite_pieces = TUNING.ARMORRUINS / 30, thulecite = TUNING.ARMORRUINS / 5}
        if not TheWorld.ismastersim then return end
        if hardmode then inst.needgreenamulet2hm = true end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("ruins_bat", function(inst)
        inst.repairmaterials2hm = {
            thulecite_pieces = TUNING.RUINS_BAT_USES / 30,
            thulecite = TUNING.RUINS_BAT_USES / 5,
            goldnugget = TUNING.RUINS_BAT_USES / 120
        }
        if not TheWorld.ismastersim then return end
        if hardmode then inst.needgreenamulet2hm = true end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
        inst.repairmaterials2hm = {
            thulecite_pieces = TUNING.MULTITOOL_AXE_PICKAXE_USES / 13.5,
            thulecite = TUNING.MULTITOOL_AXE_PICKAXE_USES / 2.25,
            goldnugget = TUNING.MULTITOOL_AXE_PICKAXE_USES / 54
        }
        if not TheWorld.ismastersim then return end
        if hardmode then inst.needgreenamulet2hm = true end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("batnosehat", function(inst)
        local time = math.max(TUNING.PERISH_SLOW * 2 / 3, TUNING.BATNOSEHAT_PERISHTIME * 2 / 3)
        inst.repairmaterials2hm = {milkywhites = time, goatmilk = time, butter = time}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
    AddPrefabPostInit("orangestaff", function(inst)
        inst.repairmaterials2hm = {orangegem = TUNING.ORANGESTAFF_USES * 0.4}
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
    end)
end

-- 橙杖冷却时间
if GetModConfigData("cooldown_orangestaff") then
    local function onblink(staff, pos, caster)
        if caster then
            if caster.components.staffsanity then
                caster.components.staffsanity:DoCastingDelta(-TUNING.SANITY_MED)
            elseif caster.components.sanity ~= nil then
                caster.components.sanity:DoDelta(-TUNING.SANITY_MED)
            end
            
            -- 冷却时消耗耐久
            if not staff.components.rechargeable:IsCharged() then 
                staff.components.finiteuses:Use(1) 
            end
            staff.components.rechargeable:Discharge(15)
        end
    end

    AddPrefabPostInit("orangestaff", function(inst)
        if not TheWorld.ismastersim then return end
        inst:AddComponent("rechargeable")
        if inst.components.blinkstaff then inst.components.blinkstaff.onblinkfn = onblink end
    end)
end

-- 香炉吸取影怪血量恢复耐久,且切换到其他手部装备后仍照明和继续吸取
if GetModConfigData("Shadow Thurible Has Light") then
    local function risefx(inst, repairvalue)
        if hardmode then repairvalue = repairvalue / 2 end
        local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
        -- SpawnPrefab("sanity_raise").Transform:SetPosition(inst.Transform:GetWorldPosition())
        local parent = owner or inst
        parent:AddChild(SpawnPrefab("sanity_raise"))
        if not (owner and owner:IsValid()) then return end
        if owner.prefab == "waxwell" then
            repairvalue = repairvalue * math.max(owner.shadowlevel2hm or 4, 4) / 2
        elseif owner.prefab == "wanda" and owner.age_state == "old" then
            repairvalue = repairvalue * 2
        end
        if inst.components.fueled and inst.components.fueled:GetPercent() < 1 then
            local percent = inst.components.fueled:GetPercent()
            inst.components.fueled:SetPercent(math.clamp(0, percent + repairvalue, 1))
            repairvalue = (repairvalue + percent) <= 1 and 0 or (repairvalue + percent - 1)
            if repairvalue <= 0 then return end
        end
        if (not hardmode or owner:HasTag("shadowmagic")) and owner.components.inventory then
            for k, equip in pairs(owner.components.inventory.equipslots) do
                if equip and equip:IsValid() and (equip.prefab == "skeletonhat" or equip.prefab == "armorskeleton") then
                    if equip.components.fueled and equip.components.fueled:GetPercent() < 1 then
                        local percent = equip.components.fueled:GetPercent()
                        equip.components.fueled:SetPercent(math.clamp(0, percent + repairvalue, 1))
                        repairvalue = (repairvalue + percent) <= 1 and 0 or (repairvalue + percent - 1)
                    elseif equip.components.armor and equip.components.armor:GetPercent() < 1 then
                        local percent = equip.components.armor:GetPercent()
                        equip.components.armor:SetPercent(math.clamp(0, percent + repairvalue, 1))
                        repairvalue = (repairvalue + percent) <= 1 and 0 or (repairvalue + percent - 1)
                    end
                    if repairvalue <= 0 then return end
                end
            end
        end
    end
    local function doshadowtask(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 18, nil, {"player", "INLIMBO"}, {"shadowcreature", "nightmarecreature"})
        local repairvalue = 0
        for _, ent in ipairs(ents) do
            if ent and ent:IsValid() and ent.prefab ~= "shadowchanneler" and ent.Transform and ent.components.health and not ent.components.health:IsDead() and
                not ent.locktarget2hm then
                local health = ent.components.health.currenthealth
                if health > 100 then
                    repairvalue = repairvalue + 0.01
                    ent.components.health:DoDelta(-100, false, inst.prefab, true, inst, true)
                elseif ent.components.lootdropper and (ent.components.lootdropper.loot or ent.components.lootdropper.chanceloottable) then
                    ent.disabledeath2hm = true
                    ent.components.lootdropper:SetLoot()
                    ent.components.lootdropper:SetChanceLootTable()
                    ent.components.lootdropper.SpawnLootPrefab = nillootdropperSpawnLootPrefab
                    ent.components.lootdropper.GenerateLoot = emptytablefn
                    ent.components.lootdropper.DropLoot = emptytablefn
                    ent.components.health:DoDelta(-health, false, inst.prefab, true, inst, true)
                    repairvalue = repairvalue + 0.01 + health / 10000
                else
                    ent.disabledeath2hm = true
                    ent.components.health:DoDelta(-health, false, inst.prefab, true, inst, true)
                    repairvalue = repairvalue + health / 10000
                end
                ent:AddChild(SpawnPrefab("sanity_lower"))
            end
        end
        if repairvalue <= 0 then return end
        inst:DoTaskInTime(1, risefx, repairvalue)
    end
    local function checkstatus(inst)
        if inst.checkstatustask2hm then inst.checkstatustask2hm = nil end
        if inst.components.fueled and inst.components.inventoryitem and inst.components.equippable then
            local enable = (inst.components.equippable:IsEquipped() or inst.bindplayer2hm or not inst.components.inventoryitem:IsHeld()) and not inst:IsAsleep()
            if enable then
                if not inst.shadowtask2hm then inst.shadowtask2hm = inst:DoPeriodicTask(2.5, doshadowtask, 1.25) end
            elseif inst.shadowtask2hm then
                inst.shadowtask2hm:Cancel()
                inst.shadowtask2hm = nil
            end
            local percent = inst.components.fueled:GetPercent()
            if percent > 0 and enable and not (inst._light2hm and inst._light2hm:IsValid()) then
                inst._light2hm = SpawnPrefab("deathcurselight2hm")
                inst._light2hm.Light:SetFalloff(0.4)
                inst._light2hm.Light:SetIntensity(.7)
                inst._light2hm.Light:SetRadius(inst.bindplayer2hm and 9 or 18)
                inst._light2hm.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
                inst._light2hm.Light:Enable(true)
            elseif (percent <= 0 or not enable) and inst._light2hm and inst._light2hm:IsValid() then
                inst._light2hm:Remove()
                inst._light2hm = nil
            end
            if inst._light2hm and inst._light2hm:IsValid() then
                local owner = inst.components.inventoryitem:GetGrandOwner() or inst
                if owner and owner:IsValid() then owner:AddChild(inst._light2hm) end
                inst._light2hm.Light:SetRadius(inst.bindplayer2hm and 4 or 18)
            end
            
            local should_have_shadowlure = percent > 0 and enable
            if should_have_shadowlure and not inst:HasTag("shadowlure") then
                inst:AddTag("shadowlure")
            elseif not should_have_shadowlure and inst:HasTag("shadowlure") then
                inst:RemoveTag("shadowlure")
            end
            
            if percent <= 0 and inst:HasTag("nightvision") then
                -- 停止照明和夜视
                inst:RemoveTag("nightvision")
                local owner = inst.components.inventoryitem.owner
                if inst.components.equippable:IsEquipped() and owner and owner:HasTag("player") and owner.components.inventory then
                    inst.disablethuriblecheck2hm = true
                    owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
                    owner.components.inventory:Equip(inst)
                    inst.disablethuriblecheck2hm = nil
                end
            elseif percent > 0 and not inst:HasTag("nightvision") then
                -- 启用照明和夜视
                inst:AddTag("nightvision")
                local owner = inst.components.inventoryitem.owner
                if inst.components.equippable:IsEquipped() and owner and owner:HasTag("player") and owner.components.inventory then
                    inst.disablethuriblecheck2hm = true
                    owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
                    owner.components.inventory:Equip(inst)
                    inst.disablethuriblecheck2hm = nil
                end
            end
        end
    end
    local function delaycheckstatus(inst) if not inst.checkstatustask2hm then inst.checkstatustask2hm = inst:DoTaskInTime(0, checkstatus) end end
    local function DoExtinguishSound(inst, owner)
        inst._soundtask = nil
        (owner ~= nil and owner:IsValid() and owner.SoundEmitter or inst.SoundEmitter):PlaySound("dontstarve/common/fireOut")
    end
    local function PlayExtinguishSound(inst)
        if inst._soundtask == nil and inst:GetTimeAlive() > 0 then
            inst._soundtask = inst:DoTaskInTime(0, DoExtinguishSound, inst.components.inventoryitem and inst.components.inventoryitem.owner)
        end
    end
    local function checknewequip(inst)
        if inst.thurible2hm then
            local equip = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip == nil or not equip:IsValid() or equip == inst.thurible2hm or equip.prefab == "thurible" or not inst.thurible2hm:IsValid() or
                (inst.thurible2hm.components.fueled and inst.thurible2hm.components.fueled.currentfuel <= 0) or
                (inst.thurible2hm.components.inventoryitem and inst.thurible2hm.components.inventoryitem:GetGrandOwner() ~= inst) then
                if inst.checkthuriblestask2hm and inst.thuribleonownerunequip2hm then
                    inst.checkthuriblestask2hm:Cancel()
                    inst.checkthuriblestask2hm = nil
                    inst:RemoveEventCallback("equip", checknewequip)
                    inst:RemoveEventCallback("unequip", inst.thuribleonownerunequip2hm)
                    inst.thuribleonownerunequip2hm = nil
                end
                if inst.thuriblesmoke2hm and inst.thuriblesmoke2hm:IsValid() then inst.thuriblesmoke2hm:Remove() end
                inst.thuriblesmoke2hm = nil
                if equip ~= inst.thurible2hm and inst.thurible2hm:IsValid() and inst.thurible2hm.components.fueled and
                    inst.thurible2hm.components.fueled.consuming then
                    inst.thurible2hm.components.fueled:StopConsuming()
                    PlayExtinguishSound(inst.thurible2hm)
                end
                if inst.thurible2hm:IsValid() then
                    inst.thurible2hm.bindplayer2hm = nil
                    inst.thurible2hm:RemoveTag("shadowlure")
                    local thurible = inst.thurible2hm
                    inst.thurible2hm = nil
                    return checkstatus(thurible)
                else
                    inst.thurible2hm = nil
                end
            elseif not inst.thurible2hm.bindplayer2hm then
                if inst.thurible2hm.components.fueled and not inst.thurible2hm.components.fueled.consuming then
                    inst.thurible2hm.components.fueled:StartConsuming()
                end
                inst.thurible2hm.bindplayer2hm = inst
                inst.thurible2hm:AddTag("shadowlure")
                if not inst.thuriblesmoke2hm then
                    inst.thuriblesmoke2hm = SpawnPrefab("thurible_smoke")
                    inst.thuriblesmoke2hm.entity:AddFollower()
                    inst.thuriblesmoke2hm.Follower:FollowSymbol(inst.GUID, "swap_object", 68, -70, 0)
                end
                return checkstatus(inst.thurible2hm)
            elseif inst.thurible2hm.components.fueled and not inst.thurible2hm.components.fueled.consuming then
                inst.thurible2hm.components.fueled:StartConsuming()
            end
        end
    end
    local function onownerunequip(inst) inst:DoTaskInTime(0, checknewequip) end
    local rate = 5
    AddPrefabPostInit("thurible", function(inst)
        if not TheWorld.ismastersim then return end
        inst.checkstatus2hm = checkstatus
        inst:DoTaskInTime(0, checkstatus)
        inst:ListenForEvent("equipped", delaycheckstatus)
        inst:ListenForEvent("unequipped", delaycheckstatus)
        inst:ListenForEvent("ondropped", delaycheckstatus)
        inst:ListenForEvent("onputininventory", delaycheckstatus)
        inst:ListenForEvent("onfueldsectionchanged", delaycheckstatus)
        inst:ListenForEvent("entitysleep", delaycheckstatus)
        inst:ListenForEvent("entitywake", delaycheckstatus)
        if hardmode and inst.components.fueled then inst.components.fueled.rate_modifiers:SetModifier(inst.prefab, rate / 2, "2hm") end
        if inst.components.equippable then
            local onunequipfn = inst.components.equippable.onunequipfn
            inst.components.equippable.onunequipfn = function(inst, owner, ...)
                if inst:IsValid() and owner and owner:IsValid() and owner:HasTag("player") and 
                   inst.components.fueled and inst.components.fueled.currentfuel > 0 and not inst.disablethuriblecheck2hm then
                    if owner.thurible2hm and owner.thurible2hm:IsValid() then
                        if owner.thurible2hm.components.fueled and owner.thurible2hm.components.fueled.consuming then
                            owner.thurible2hm.components.fueled:StopConsuming()
                        end
                        owner.thurible2hm.bindplayer2hm = nil
                        owner.thurible2hm:RemoveTag("shadowlure")
                    end
                    owner.thurible2hm = inst
                    if not owner.checkthuriblestask2hm and not owner.thuribleonownerunequip2hm then
                        owner.checkthuriblestask2hm = owner:DoPeriodicTask(1, checknewequip)
                        owner:ListenForEvent("equip", checknewequip)
                        owner.thuribleonownerunequip2hm = onownerunequip
                        owner:ListenForEvent("unequip", owner.thuribleonownerunequip2hm)
                    end
                    owner:DoTaskInTime(0, checknewequip)
                end
                return onunequipfn(inst, owner, ...)
            end
        end
    end)
    if hardmode then TUNING.THURIBLE_FUEL_MAX = TUNING.THURIBLE_FUEL_MAX * rate end
end

-- 骨头头盔修复，耐久为零不消失
if GetModConfigData("Bone Helm No Remove") then
    local function checkstatus(inst)
        if inst.components.armor and inst.components.inventoryitem and inst.components.equippable and inst.persists then
            local owner = inst.components.inventoryitem.owner
            local percent = inst.components.armor:GetPercent()
            
            if owner and owner:IsValid() and owner.components.sanity and inst.components.equippable:IsEquipped() then
                owner.components.sanity:SetInducedInsanity(inst, percent > 0)
            end
            
            inst.components.equippable.dapperness = percent > 0 and TUNING.CRAZINESS_MED or 0
            inst.components.armor.absorb_percent = percent > 0 and TUNING.ARMOR_SKELETONHAT_ABSORPTION or 0
        end
    end
    
    local function onpercent(inst, data)
        if data and data.percent then
            if not inst.armorpercent2hm or (inst.armorpercent2hm <= 0 and data.percent > 0) then 
                checkstatus(inst) 
            end
            inst.armorpercent2hm = data.percent
        end
    end

    AddPrefabPostInit("skeletonhat", function(inst)
        inst.repairmaterials2hm = {nightmarefuel = TUNING.ARMOR_SKELETONHAT / 10}
        if not TheWorld.ismastersim then return end
        
        inst:AddComponent("repairable2hm")
        
        if inst.components.armor then
            inst.components.armor:SetKeepOnFinished(true)
            inst.components.armor:SetOnFinished(checkstatus)
            inst:ListenForEvent("percentusedchange", onpercent)
        end
        
        inst.checkstatus2hm = checkstatus
        inst:DoTaskInTime(0, checkstatus)
        inst:ListenForEvent("equipped", checkstatus)
        inst:ListenForEvent("unequipped", checkstatus)
    end)
end

-- 甲板照明灯装备头部
if GetModConfigData("Deck Illuminator Equip Head") then
    local LIGHT_RADIUS = {MIN = 2, MAX = 5}
    local LIGHT_COLOUR = Vector3(180 / 255, 195 / 255, 150 / 255)
    local LIGHT_INTENSITY = {MIN = 0.4, MAX = 0.8}
    local LIGHT_FALLOFF = .9
    local function lamp_fuelupdate(inst)
        if inst._light ~= nil and inst._light:IsValid() then
            local fuelpercent = inst.components.fueled:GetPercent()
            inst._light.Light:SetIntensity(Lerp(LIGHT_INTENSITY.MIN, LIGHT_INTENSITY.MAX, fuelpercent))
            inst._light.Light:SetRadius(Lerp(LIGHT_RADIUS.MIN, LIGHT_RADIUS.MAX, fuelpercent))
            inst._light.Light:SetFalloff(LIGHT_FALLOFF)
        end
    end
    local function lamp_turnoff(inst)
        inst.components.fueled:StopConsuming()
        if inst._lamp ~= nil and inst._lamp:IsValid() then
            inst._lamp:PushEvent("mast_lamp_off")
            inst._lamp.AnimState:PlayAnimation("off", true)
        end
        if inst._light and inst._light:IsValid() then inst._light.Light:Enable(false) end
    end
    local function lamp_turnon(inst)
        if not inst.components.fueled:IsEmpty() and inst.components.equippable:IsEquipped() then
            inst.components.fueled:StartConsuming()
            if inst._lamp ~= nil and inst._lamp:IsValid() then
                inst._lamp:PushEvent("mast_lamp_on")
                inst._lamp.AnimState:PlayAnimation("full", true)
            end
            if inst._light and inst._light:IsValid() then inst._light.Light:Enable(true) end
            lamp_fuelupdate(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
        end
    end
    local function onequiplamp(inst, owner)
        local upgrade_prefab = inst.upgrade_override or "mastupgrade_lamp"
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, upgrade_prefab)
        else
            owner.AnimState:OverrideSymbol("swap_hat", upgrade_prefab, "swap_hat")
        end
        owner.AnimState:ClearOverrideSymbol("headbase_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAIR_HAT")
        -- owner.AnimState:Hide("HAIR_NOHAT")
        -- owner.AnimState:Hide("HAIR")
        if owner:HasTag("player") then
            -- owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
            owner.AnimState:Show("HEAD_HAT_NOHELM")
            -- owner.AnimState:Hide("HEAD_HAT_HELM")
        end
        if inst._lamp == nil or not inst._lamp:IsValid() then
            if inst.linked_skinname then
                inst._lamp = SpawnPrefab(upgrade_prefab, inst.linked_skinname, inst.skin_id)
            else
                inst._lamp = SpawnPrefab(upgrade_prefab)
            end
            inst._lamp.Transform:SetScale(0.8, 0.8, 0.8)
            inst._lamp.AnimState:PlayAnimation("off", true)
            -- inst._lamp.AnimState:SetLayer(LAYER_BACKGROUND)
            inst._lamp._mast = owner
            inst._lamp.entity:SetParent(owner.entity)
            inst._lamp.entity:AddFollower():FollowSymbol(owner.GUID, "swap_hat", 0, -180, 0)
            inst._lamp.AnimState:SetInheritsSortKey(false)
        end
        if inst._light == nil or not inst._light:IsValid() then
            inst._light = SpawnPrefab("minerhatlight")
            inst._light.entity:SetParent(owner.entity)
            inst._light.Light:SetColour(LIGHT_COLOUR.x, LIGHT_COLOUR.y, LIGHT_COLOUR.z)
            lamp_fuelupdate(inst)
            inst._light.Light:Enable(false)
        end
        lamp_turnon(inst)
    end
    local function onunequiplamp(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then owner:PushEvent("unequipskinneditem", inst:GetSkinName()) end
        owner.AnimState:ClearOverrideSymbol("headbase_hat")
        owner.AnimState:ClearOverrideSymbol("swap_hat")
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
            owner.AnimState:Hide("HEAD_HAT_NOHELM")
            owner.AnimState:Hide("HEAD_HAT_HELM")
        end
        if inst._lamp and inst._lamp:IsValid() then
            inst._lamp:Remove()
            inst._lamp = nil
        end
        if inst._light and inst._light:IsValid() then
            inst._light:Remove()
            inst._light = nil
        end
        lamp_turnoff(inst)
    end
    local function upgradelamp(inst)
        inst:AddTag("firefuellight")
        inst:AddTag("waterproofer")
        if not TheWorld.ismastersim then return end
        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(onequiplamp)
        inst.components.equippable:SetOnUnequip(onunequiplamp)
        inst.components.equippable.walkspeedmult = TUNING.ICEHAT_SPEED_MULT
        inst:AddComponent("fueled")
        inst.components.fueled:InitializeFuelLevel(TUNING.MAST_LAMP_LIGHTTIME)
        inst.components.fueled:SetDepletedFn(lamp_turnoff)
        inst.components.fueled:SetUpdateFn(lamp_fuelupdate)
        inst.components.fueled:SetTakeFuelFn(lamp_turnon)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
        inst.components.fueled.accepting = true
        inst.components.fueled.canbespecialextinguished = true
    end
    AddPrefabPostInit("mastupgrade_lamp_item", upgradelamp)
    AddPrefabPostInit("mastupgrade_lamp_item_yotd", upgradelamp)
end

-- 衣物增强
if GetModConfigData("Clothing Enhancements") then
    -- ===========================================================================
    -- 隔热保暖增强

    -- 熊皮大衣保暖960
    AddPrefabPostInit("beargervest", function(inst)
        if not TheWorld.ismastersim then return end
        -- 240*4=960保暖
        if inst.components.insulator then inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE * 4) end
        
        -- 防止耐久导致的保暖降低
        if TUNING.DSTU and inst.components.fueled then inst.components.fueled:SetSectionCallback(nil) end
    end)

    -- 冰帽隔热480
    AddPrefabPostInit("icehat", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.insulator then inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE * 2) end
    end)
    
    -- ============================================================================
    -- 防水增强，应对极度潮湿的为爽天气

    -- 雨帽
    AddPrefabPostInit("rainhat", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.waterproofer then
            inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)
        end
    end)

    -- 雨伞
    AddPrefabPostInit("umbrella", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.waterproofer then
            inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)
        end
    end)

    TUNING.WATERPROOFNESS_PROMAX = 1.5
    -- 眼球伞
    AddPrefabPostInit("eyebrellahat", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.waterproofer then
            inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_PROMAX)
        end
    end)
    -- ============================================================================
    -- 羽毛扇可以驱散毒雾
    AddComponentPostInit("fan", function(self)
        local Fan = self.Fan
        
        self.Fan = function(self, target, ...)
            local result = Fan(self, target, ...)
            
            if result and target and target:IsValid() then
                local x, y, z = target.Transform:GetWorldPosition()

                local radius = (self.inst.prefab == "featherfan") and 
                            TUNING.FEATHERFAN_RADIUS * 2 or 
                            TUNING.FEATHERFAN_RADIUS
                
                -- 驱散范围内的毒雾
                local sporeclouds = TheSim:FindEntities(x, y, z, radius, {"sporecloud"})
                for i, v in ipairs(sporeclouds) do
                    if v.components.timer and v.components.timer:TimerExists("disperse") then
                        local timeleft = v.components.timer:GetTimeLeft("disperse")
                        v.components.timer:SetTimeLeft("disperse", timeleft - 60)
                    end
                end
                
                -- 范围内玩家施加持续降温buff
                local FANTARGET_CANT_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "playerghost"}
                local players = TheSim:FindEntities(x, y, z, radius, {"player"}, FANTARGET_CANT_TAGS)
                for i, v in ipairs(players) do
                    if v.components.temperature ~= nil then
                        v.components.temperature:SetTemperatureInBelly(TUNING.COLD_FOOD_BONUS_TEMP, 120)
                    end
                end
            end
            
            return true
        end
    end)

    -- 羽毛扇降温防过冷
    TUNING.FEATHERFAN_MINIMUM_TEMP = 10             -- 2.5→10

end

-- 恐怖盾牌增强
if GetModConfigData("Shieldofterror Eat Owner") then
    local function eattarget(inst, target, owner, value)
        if not target.components.health then return end
        -- 骑牛时无效
        if owner and owner.components.rider and owner.components.rider.riding then return end
        local current = target.components.health.currenthealth
        local v = math.abs(target.components.health:DoDelta(-value, nil, owner.nameoverride or owner.prefab or "NIL", nil, owner) or value)
        if target.components.health:IsDead() then
            v = current
            if owner ~= nil then owner:PushEvent("killed", {victim = target, attacker = owner}) end
            if target.components.combat and target.components.combat.onkilledbyother ~= nil then
                target.components.combat.onkilledbyother(target, owner)
            end
        end
        -- if target.Transform and owner ~= nil and owner.Transform then
        --     local fx = SpawnPrefab(math.random() < .5 and "shadowstrike_slash_fx" or "shadowstrike_slash2_fx")
        --     local x, y, z = target.Transform:GetWorldPosition()
        --     fx.Transform:SetPosition(x, y + 1.5, z)
        --     fx.Transform:SetRotation(owner.Transform:GetRotation())
        -- end
        if v <= 0 then return end
        -- if owner.SoundEmitter and inst.sound2hm then owner.SoundEmitter:PlaySound(inst.sound2hm) end
        if inst.components.armor:GetPercent() < 1 then
            local need = inst.components.armor.maxcondition - inst.components.armor.condition
            inst.components.armor:Repair(v * 2)
            if v <= need / 2 then return end
            v = v - need / 2
        end
        if owner and owner:IsValid() and not (owner.components.health and owner.components.health:IsDead()) then
            if owner.components.health and not owner.components.oldager and owner.components.health:GetPercent() < 1 then
                local current = owner.components.health.currenthealth
                owner.components.health:DoDelta(v / 8, nil, inst.prefab, nil, inst)
                local need = owner.components.health.currenthealth - current
                if v <= need * 8 then return end
                v = v - need * 8
            end
            if owner.components.hunger and owner.components.hunger:GetPercent() < 1 then owner.components.hunger:DoDelta(v / 6, nil, true) end
        end
    end
    local nocreaturetags = {
        "veggie",
        "structure",
        "wall",
        "balloon",
        "groundspike",
        "smashable",
        "companion",
        "equipmentmodel",
        "shadow",
        "shadowcreature",
        "shadowthrall",
        "nightmarecreature",
        "shadowchesspiece",
        "brightmare",
        "pigelite",
        "card"
    }
    local function IsValidVictim(victim)
        return victim.components.health and not victim.components.health:IsDead() and victim.components.combat and not victim:HasOneOfTags(nocreaturetags)
    end
    local function endeatattackertask(inst) inst.eatattacker2hmtask = nil end
    local function onattacked(inst, owner, data)
        if inst:IsValid() and owner and owner:IsValid() and not inst.eatattacker2hmtask and inst.components.armor and data and data.attacker and
            data.attacker:IsValid() and owner:IsNear(data.attacker, 4) and IsValidVictim(data.attacker) and
            (data.weapon == nil or
                (data.weapon.components.projectile == nil and (data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil))) then
            inst.eatattacker2hmtask = inst:DoTaskInTime(2, endeatattackertask)
            eattarget(inst, data.attacker, owner, 17)
        end
    end
    local function onhitother(inst, owner, data)
        if inst:IsValid() and owner and owner:IsValid() and not inst.eatattacker2hmtask and inst.components.armor and data and data.target and
            data.target:IsValid() and owner:IsNear(data.target, 4) and IsValidVictim(data.target) and owner.components.combat and
            owner.components.combat.lastdoattacktime and
            (not inst.lastdoattacktime2hm or owner.components.combat.lastdoattacktime - inst.lastdoattacktime2hm > 0.3) then
            inst.lastdoattacktime2hm = owner.components.combat.lastdoattacktime
            inst._hitcount2hm = (inst._hitcount2hm or 0) + 1
            if inst._hitcount2hm > 2.5 then
                inst._hitcount2hm = inst._hitcount2hm - 2.5
                inst.eatattacker2hmtask = inst:DoTaskInTime(0.3, endeatattackertask)
                eattarget(inst, data.target, owner, 17)
            end
        end
    end
    local function onequip(inst, data)
        if data and data.owner and data.owner:HasTag("player") then
            inst:ListenForEvent("attacked", inst.onattacked2hm, data.owner)
            if inst.prefab == "shieldofterror" then inst:ListenForEvent("onhitother", inst.onhitother2hm, data.owner) end
        end
    end
    local function onunequip(inst, data)
        if data and data.owner and data.owner:HasTag("player") then
            inst:RemoveEventCallback("attacked", inst.onattacked2hm, data.owner)
            if inst.prefab == "shieldofterror" then inst:RemoveEventCallback("onhitother", inst.onhitother2hm, data.owner) end
        end
    end
    local function endeatownertask(inst) inst.eatownercdtask2hm = nil end
    local function beforeTakeDamage(inst, self, damage)
        if damage and (damage >= self.condition or (not inst.eatownercdtask2hm and (self.condition - damage) / self.maxcondition < 0.5)) then
            local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
            if owner and owner:IsValid() and not owner:HasTag("equipmentmodel") then
                if owner.SoundEmitter and inst.sound2hm and owner.SoundEmitter:PlayingSound(inst.sound2hm) then return end
                local percent = damage >= self.condition and 1 or (1 - math.min((self.condition - damage) / self.maxcondition, 1))
                if owner.components.hunger and owner.components.hunger.current > 0 then
                    local hungerabsorption = inst.components.eater.hungerabsorption
                    if hungerabsorption == 0 or not hungerabsorption then hungerabsorption = 1.75 end
                    local needhunger = math.min(math.min(percent * owner.components.hunger.current, 17) * hungerabsorption, self.maxcondition - self.condition)
                    if needhunger > 0 then
                        self.condition = math.min(self.maxcondition, self.condition + needhunger)
                        owner.components.hunger:DoDelta(-needhunger / hungerabsorption, nil, true)
                        if owner.SoundEmitter and inst.sound2hm then owner.SoundEmitter:PlaySound(inst.sound2hm) end
                        if inst.eatownercdtask2hm then inst.eatownercdtask2hm:Cancel() end
                        inst.eatownercdtask2hm = inst:DoTaskInTime(math.max(0.3, (1 - percent) * 3), endeatownertask)
                    end
                elseif owner.components.health and owner.components.health.currenthealth > 0 then
                    local healthabsorption = inst.components.eater and inst.components.eater.healthabsorption
                    if healthabsorption == 0 or not healthabsorption then healthabsorption = 4 end
                    local needhealth = math.min(math.min(percent * owner.components.health.currenthealth, 17) * healthabsorption,
                                                self.maxcondition - self.condition)
                    if needhealth > 0 then
                        self.condition = math.min(self.maxcondition, self.condition + needhealth)
                        owner.components.health:DoDelta(-needhealth / healthabsorption, nil, inst.prefab, true, inst, true)
                        if owner.SoundEmitter and inst.sound2hm then owner.SoundEmitter:PlaySound(inst.sound2hm) end
                        if inst.eatownercdtask2hm then inst.eatownercdtask2hm:Cancel() end
                        inst.eatownercdtask2hm = inst:DoTaskInTime(math.max(0.3, (1 - percent) * 3), endeatownertask)
                    end
                end
            end
        end
    end
    local function OnUsedAsItem(self, action, doer, target)
        if action == ACTIONS.NET then
            if self:GetPercent() < 0.53 then beforeTakeDamage(self.inst, self, self.maxcondition * 0.03) end
            self:SetPercent(self:GetPercent() - 0.03)
        end
    end
    AddPrefabPostInit("shieldofterror", function(inst)
        if not TheWorld.ismastersim then return end
        inst.sound2hm = "terraria1/eye_shield/eat"
        inst:AddComponent("tool")
        inst.components.tool:SetAction(ACTIONS.NET)
        inst.onattacked2hm = function(owner, data) onattacked(inst, owner, data) end
        inst.onhitother2hm = function(owner, data) onhitother(inst, owner, data) end
        inst:ListenForEvent("equipped", onequip)
        inst:ListenForEvent("unequipped", onunequip)
        
        if inst.components.armor then
            local TakeDamage = inst.components.armor.TakeDamage
            inst.components.armor.TakeDamage = function(self, damage, ...)
                beforeTakeDamage(self.inst, self, damage)
                TakeDamage(self, damage, ...)
            end
            if not inst.components.armor.OnUsedAsItem then inst.components.armor.OnUsedAsItem = OnUsedAsItem end
        end
    end)
    AddPrefabPostInit("eyemaskhat", function(inst)
        if not TheWorld.ismastersim then return end
        inst.sound2hm = "terraria1/eyemask/eat"
        inst.onattacked2hm = function(owner, data) onattacked(inst, owner, data) end
        inst:ListenForEvent("equipped", onequip)
        inst:ListenForEvent("unequipped", onunequip)
        
        if inst.components.armor then
            local TakeDamage = inst.components.armor.TakeDamage
            inst.components.armor.TakeDamage = function(self, damage, ...)
                beforeTakeDamage(self.inst, self, damage)
                TakeDamage(self, damage, ...)
            end
        end
    end)
    AddStategraphPostInit("wilson", function(sg)
        local bugnet_start = sg.states.bugnet_start.onenter
        sg.states.bugnet_start.onenter = function(inst, ...)
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip and equip.prefab == "shieldofterror" then
                inst.sg:GoToState("bugnet")
                return
            end
            bugnet_start(inst, ...)
        end
        local bugnet = sg.states.bugnet.onenter
        sg.states.bugnet.onenter = function(inst, ...)
            bugnet(inst, ...)
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip and equip.prefab == "shieldofterror" then inst.AnimState:PlayAnimation("toolpunch") end
        end
    end)
    AddStategraphPostInit("wilson_client", function(sg)
        local bugnet_start = sg.states.bugnet_start.onenter
        sg.states.bugnet_start.onenter = function(inst, ...)
            bugnet_start(inst, ...)
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip and equip.prefab == "shieldofterror" then inst.sg:GoToState("bugnet") end
        end
        local bugnet = sg.states.bugnet.onenter
        sg.states.bugnet.onenter = function(inst, ...)
            bugnet(inst, ...)
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip and equip.prefab == "shieldofterror" then inst.AnimState:PlayAnimation("toolpunch") end
        end
    end)
end

-- 使用亮茄外壳或绝望石升级你的火把,外壳可以在装备时开启启迪状态同时释放催眠烟雾,绝望石可以召唤黑夜精灵袭击周围对自己有仇恨的敌人
if GetModConfigData("upgrade torch") then
    -- 亮茄尖刺攻击
    local TARGET_MUST_TAGS = {"_combat"}
    local TARGET_CANT_TAGS = {
        "lunarthrall_plant",
        "lunarthrall_plant_end",
        "playerghost",
        "ghost",
        "shadow",
        "shadowminion",
        "FX",
        "INLIMBO",
        "notarget",
        "noattack",
        "fx",
        "flight",
        "invisible"
    }
    local function newchooseaction(inst)
        if inst.components.freezable and inst.components.freezable:IsFrozen() then return end
        inst.target = inst.components.combat.target or FindEntity(inst, TUNING.LUNARTHRALL_PLANT_RANGE, function(guy)
            return guy ~= inst.parent2hm and guy.prefab ~= "lunarthrall_plant_vine" and guy.components.health and inst.components.combat:CanTarget(guy)
        end, TARGET_MUST_TAGS, TARGET_CANT_TAGS) or inst.target
        if not (inst.target and inst.target:IsValid() and inst.target.components.health and not inst.target.components.health:IsDead()) then
            inst.target = nil
            return
        end
        inst.mode = "attack"
        if inst.target and inst.mode == "attack" then
            inst.components.combat:SetTarget(inst.target)
            local dist = inst:GetDistanceSqToInst(inst.target)
            if dist < TUNING.LUNARTHRALL_PLANT_VINE_INITIATE_ATTACK * TUNING.LUNARTHRALL_PLANT_VINE_INITIATE_ATTACK then
                if not inst.components.timer:TimerExists("attack_cooldown") then inst:PushEvent("doattack") end
            elseif inst.target ~= inst.parent2hm then
                local pos = Vector3(inst.target.Transform:GetWorldPosition())
                local theta = inst:GetAngleToPoint(pos) * DEGREES
                local radius = math.sqrt(dist) - TUNING.LUNARTHRALL_PLANT_CLOSEDIST
                local ITERATIONS = 5
                local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
                local newpos = Vector3(inst.Transform:GetWorldPosition())
                local onwater = false
                for i = 1, ITERATIONS do
                    local testpos = newpos + offset * (i / ITERATIONS)
                    if not TheWorld.Map:IsVisualGroundAtPoint(testpos.x, testpos.y, testpos.z) then
                        onwater = true
                        break
                    end
                end
                newpos = newpos + offset
                dist = inst:GetDistanceSqToPoint(newpos)
                local moveback = nil
                for i, nub in ipairs(inst.tails) do
                    local nubdist = nub:GetDistanceSqToPoint(newpos)
                    if nubdist < dist then
                        dist = nubdist
                        moveback = true
                        break
                    end
                end
                if moveback and not onwater then
                    inst:PushEvent("moveback")
                else
                    if #inst.tails < 7 and not onwater then
                        inst:PushEvent("moveforward", {newpos = newpos})
                    else
                        inst:PushEvent("emerge")
                    end
                end
            end
        end
    end
    local function onvinehitother(inst, data)
        if data and data.target and data.target:IsValid() then data.target:AddDebuff("wormwood_vined_debuff", "wormwood_vined_debuff") end
    end
    local function vinedeath(inst) if inst.components.health and not inst.components.health:IsDead() then inst.components.health:Kill() end end
    local function vineback(inst)
        if not inst.target and inst.components.health and not inst.components.health:IsDead() and inst.sg then
            inst.mode = "return"
            inst:PushEvent("moveback")
        end
    end
    local function confirmlunarplanttentacleDespawn(inst)
        if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name ~= "attack_pst" then
            inst.sg:GoToState("attack_pst")
            inst:DoTaskInTime(3, inst.Remove)
        else
            inst:Remove()
        end
    end
    local function lunarplanttentacleDespawn(inst)
        if not (inst.components.combat and inst.components.combat.target) then confirmlunarplanttentacleDespawn(inst) end
    end
    local function SpawnVineAttack(inst)
        local parent = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or inst
        local x, y, z = parent.Transform:GetWorldPosition()
        if parent == inst or (parent and not parent:HasTag("moving")) then
            x = x + math.random(1, 8) - 4
            z = z + math.random(1, 8) - 4
        end
        if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
            if math.random() < 0.15 then
                local vine = SpawnPrefab("lunarthrall_plant_vine_end")
                vine.parent2hm = parent
                vine.ChooseAction = newchooseaction
                vine.Transform:SetPosition(x, y, z)
                vine.Transform:SetRotation(vine:GetAngleToPoint(x, y, z))
                if vine.sg then
                    vine.sg:RemoveStateTag("nub")
                    vine.sg:GoToState("hit")
                end
                vine:ListenForEvent("onhitother", onvinehitother)
                vine:DoTaskInTime(12, vinedeath)
                vine:DoTaskInTime(4, vineback)
                if vine.components.health then vine.components.health:StartRegen(-20, 1) end
            else
                local tentacle = SpawnPrefab("lunarplanttentacle")
                if tentacle then
                    tentacle.persists = false
                    tentacle.parent2hm = parent
                    tentacle.owner = parent
                    tentacle.Transform:SetPosition(x, y, z)
                    local target = FindEntity(tentacle, TUNING.LUNARTHRALL_PLANT_RANGE, function(guy)
                        return guy ~= parent and guy.prefab ~= "lunarthrall_plant_vine" and guy.components.health and tentacle.components.combat:CanTarget(guy)
                    end, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
                    if target then tentacle.components.combat:SetTarget(target) end
                    tentacle:DoTaskInTime(4, lunarplanttentacleDespawn)
                    tentacle:DoTaskInTime(10, confirmlunarplanttentacleDespawn)
                end
            end
        end
    end
    -- 催眠云雾控制,效果能持续更久到knockout晕倒或sleeping睡着的敌人苏醒
    local function clouddebuffend(ent) end
    local function OnClearCloudProtection2(ent)
        ent.CloudProtectTask2hm2 = nil
        if ent.sg ~= nil and not ent.sg:HasStateTag("waking") and
            ((ent.components.grogginess ~= nil and ent.sg:HasStateTag("knockout")) or (ent.components.sleeper ~= nil and ent.sg:HasStateTag("sleeping"))) then
            ent.CloudProtectTask2hm2 = ent:DoTaskInTime(1, OnClearCloudProtection2)
            return
        end
        if ent:HasTag("player") and ent.components.sanity then
            ent.components.sanity:EnableLunacy(false, "upgradetorch2hm")
            if ent.components.sanity._lunacy_sources then ent.components.sanity._lunacy_sources:SetModifier(ent, nil, "upgradetorch2hm") end
        end
        if not ent:HasTag("player") and ent.components.locomotor then ent.components.locomotor:RemoveExternalSpeedMultiplier(ent, "lunargoopcloud2hm") end
        if ent.cloudcombat2hm then
            ent.cloudcombat2hm = nil
            if ent.components.combat then ent.components.combat.externaldamagetakenmultipliers:RemoveModifier(ent, "upgradetorch2hm") end
        end
    end
    local function OnClearCloudProtection(ent)
        ent.CloudProtectTask2hm = nil
        ent.CloudProtectTask2hm2 = ent:DoTaskInTime(1, OnClearCloudProtection2)
    end
    local function SetCloudProtection(ent, duration)
        if ent:IsValid() then
            if ent.CloudProtectTask2hm2 ~= nil then
                ent.CloudProtectTask2hm2:Cancel()
                ent.CloudProtectTask2hm2 = nil
            end
            if ent.CloudProtectTask2hm ~= nil then ent.CloudProtectTask2hm:Cancel() end
            ent.CloudProtectTask2hm = ent:DoTaskInTime(duration, OnClearCloudProtection)
            if ent:HasTag("player") and ent.components.sanity then ent.components.sanity:EnableLunacy(true, "upgradetorch2hm") end
        end
    end
    local CLOUD_RADIUS = 2.5
    local PHYSICS_PADDING = 3
    local SLEEPER_TAGS = {"player", "sleeper"}
    local SLEEPER_NO_TAGS = {"playerghost", "lunar_aligned", "INLIMBO"}
    local function DoCloudTask(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, CLOUD_RADIUS + PHYSICS_PADDING, nil, SLEEPER_NO_TAGS, SLEEPER_TAGS)) do
            if v:IsValid() and (v.CloudProtectTask2hm == nil or (v.protectcloud2hm and v.protectcloud2hm ~= inst)) and v.entity:IsVisible() and
                not (v.components.health ~= nil and v.components.health:IsDead()) then
                local range = v:GetPhysicsRadius(0) + CLOUD_RADIUS
                if v:GetDistanceSqToPoint(x, y, z) < range * range then
                    local enable
                    if v.components.combat then
                        v.cloudcombat2hm = math.min((v.cloudcombat2hm or 0) + 1, 5)
                        v.components.combat.externaldamagetakenmultipliers:SetModifier(v, 1 + 0.05 * v.cloudcombat2hm, "upgradetorch2hm")
                        enable = true
                    end
                    if not v:HasTag("player") and v.components.locomotor then
                        v.components.locomotor:SetExternalSpeedMultiplier(v, "lunargoopcloud2hm", v:HasTag("epic") and 0.8 or 0.65)
                        enable = true
                    end
                    if not (v.sg ~= nil and v.sg:HasStateTag("waking")) then
                        if v.components.grogginess ~= nil then
                            if not (v.sg ~= nil and v.sg:HasStateTag("knockout")) then
                                v.components.grogginess:AddGrogginess(TUNING.LUNAR_GRAZER_GROGGINESS, TUNING.LUNAR_GRAZER_KNOCKOUTTIME)
                            end
                            enable = true
                        elseif v.components.sleeper ~= nil then
                            if not (v.sg ~= nil and v.sg:HasStateTag("sleeping")) then
                                v.components.sleeper:AddSleepiness(TUNING.LUNAR_GRAZER_GROGGINESS, TUNING.LUNAR_GRAZER_KNOCKOUTTIME)
                            end
                            enable = true
                        end
                    end
                    if enable then SetCloudProtection(v, 0.5) end
                end
            end
        end
    end
    local function CloudSanityAura(inst, observer) return observer and observer.CloudProtectTask2hm and TUNING.SANITYAURA_MED or TUNING.SANITYAURA_SMALL end
    local function SpawnCloudAttack(inst)
        local cloud = SpawnPrefab("lunar_goop_cloud_fx")
        cloud.persists = false
        cloud:AddComponent("sanityaura")
        cloud.components.sanityaura.aurafn = CloudSanityAura
        local parent = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or inst
        cloud.parent2hm = parent
        cloud.Transform:SetPosition(parent.Transform:GetWorldPosition())
        local time = math.random()
        cloud:DoTaskInTime(5.1 + time, cloud.Remove)
        cloud:DoPeriodicTask(1, DoCloudTask, time)
        if parent and parent:IsValid() and parent:HasTag("activeprojectile") or (parent.sg and parent.sg:HasStateTag("moving")) then
            parent.protectcloud2hm = cloud
            SetCloudProtection(parent, 1.5)
            if inst.waitdelay2hm then inst.waitdelay2hm = nil end
        elseif inst.components.burnable and (inst.waitdelay2hm or 0) > 2 then
            inst.components.burnable:Extinguish()
        else
            inst.waitdelay2hm = (inst.waitdelay2hm or 0) + 1
        end
    end
    -- 毒云灼烧攻击
    local function darkcloudhurthealth(inst, value)
        if inst.components.health and not inst.components.health:IsDead() then inst.components.health:DoDelta(value, nil, "miasma") end
    end
    local function OnDarkCloudHealthDelta(inst, data)
        if data and data.oldpercent and data.newpercent and data.newpercent > data.oldpercent and not inst.components.health:IsDead() then
            inst:DoTaskInTime(0, darkcloudhurthealth,
                              inst.components.health.maxhealth * (data.oldpercent - data.newpercent) * (0.3 + (inst.darkcloudhealth2hm or 1) * 0.05))
        end
    end
    local function OnClearDarkCloudProtection2(ent)
        ent.DarkCloudProtectTask2hm2 = nil
        if ent:HasTag("player") and ent.components.sanity then ent.components.sanity:SetInducedInsanity(ent, false) end
        if not ent:HasTag("player") and ent.components.locomotor then ent.components.locomotor:RemoveExternalSpeedMultiplier(ent, "miasma2hm") end
        if ent.darkcloudhealth2hm then
            ent.darkcloudhealth2hm = nil
            ent:RemoveEventCallback("healthdelta", OnDarkCloudHealthDelta)
        end
    end
    local function OnClearDarkCloudProtection(ent)
        ent.DarkCloudProtectTask2hm = nil
        ent.DarkCloudProtectTask2hm2 = ent:DoTaskInTime(0.5, OnClearDarkCloudProtection2)
    end
    local function SetDarkCloudProtection(ent, duration)
        if ent:IsValid() then
            if ent.DarkCloudProtectTask2hm2 ~= nil then
                ent.DarkCloudProtectTask2hm2:Cancel()
                ent.DarkCloudProtectTask2hm2 = nil
            end
            if ent.DarkCloudProtectTask2hm ~= nil then ent.DarkCloudProtectTask2hm:Cancel() end
            ent.DarkCloudProtectTask2hm = ent:DoTaskInTime(duration, OnClearDarkCloudProtection)
            if ent:HasTag("player") and ent.components.sanity then ent.components.sanity:SetInducedInsanity(ent, true) end
        end
    end
    local MIASMA_RADIUS = 2
    local MIASMA_NO_TAGS = {"playerghost", "ghost", "shadow", "shadowminion", "noauradamage", "FX", "INLIMBO", "notarget", "noattack", "flight", "invisible"}
    local function DoDarkCloudTask(inst)
        if inst.task == nil and inst.StartAllWatchers then inst:StartAllWatchers() end
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, MIASMA_RADIUS + PHYSICS_PADDING, nil, MIASMA_NO_TAGS)) do
            if v:IsValid() and (v.DarkCloudProtectTask2hm == nil or (v.protectcloud2hm and v.protectcloud2hm ~= inst)) and v.entity:IsVisible() and
                v.components.health ~= nil and not v.components.health:IsDead() and
                (v.components.inventory == nil or not v.components.inventory:EquipHasTag("miasmaimmune")) then
                local range = v:GetPhysicsRadius(0) + MIASMA_RADIUS
                if v:GetDistanceSqToPoint(x, y, z) < range * range then
                    if v.protectcloud2hm then v.protectcloud2hm = nil end
                    if not v:HasTag("player") and v.components.locomotor then
                        v.components.locomotor:SetExternalSpeedMultiplier(v, "miasma2hm", v:HasTag("epic") and 0.8 or 0.65)
                    end
                    if v.darkcloudhealth2hm == nil then
                        v.darkcloudhealth2hm = 1
                        v:ListenForEvent("healthdelta", OnDarkCloudHealthDelta)
                    else
                        v.darkcloudhealth2hm = math.min(v.darkcloudhealth2hm + 1, 3)
                    end
                    if not v:HasTag("player") then
                        v.components.health:DoDelta(TUNING.MIASMA_DEBUFF_TICK_VALUE * 2, nil, "miasma")
                        if not v.components.health.takingfiredamage then
                            v.components.health.takingfiredamage = true
                            v.components.health.takingfiredamagestarttime = GetTime()
                            v:StartUpdatingComponent(v.components.health)
                        end
                        v.components.health.lastfiredamagetime = GetTime()
                    end
                    SetDarkCloudProtection(v, 0.25)
                end
            end
        end
    end
    local function DarkCloudSanityAura(inst, observer)
        return observer and observer.DarkCloudProtectTask2hm and -TUNING.SANITYAURA_MED or -TUNING.SANITYAURA_SMALL
    end
    local function SpawnDarkCloudAttack(inst)
        local cloud = SpawnPrefab("miasma_cloud")
        cloud.OnEntityWake = nil
        cloud.persists = false
        cloud:AddComponent("sanityaura")
        cloud.components.sanityaura.aurafn = DarkCloudSanityAura
        -- cloud.StartAllWatchers = nilfn
        local parent = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or inst
        local x, y, z = parent.Transform:GetWorldPosition()
        if parent == inst then
            x = x + math.random() * 8 - 4
            z = z + math.random() * 8 - 4
        end
        cloud.parent2hm = parent
        cloud.Transform:SetPosition(x, y, z)
        local time = math.random() * .5
        cloud:DoTaskInTime(5.1 + time, cloud.Remove)
        cloud:DoPeriodicTask(0.5, DoDarkCloudTask, time)
        if parent and parent:IsValid() and parent:HasTag("activeprojectile") or (parent.sg and parent.sg:HasStateTag("moving")) then
            if parent:HasTag("player") and cloud.watchers_exiting then cloud.watchers_exiting[parent] = true end
            parent.protectcloud2hm = cloud
            SetDarkCloudProtection(parent, 0.75)
            if inst.waitdelay2hm then inst.waitdelay2hm = nil end
        elseif inst.components.burnable and (inst.waitdelay2hm or 0) > 3 then
            inst.components.burnable:Extinguish()
        else
            inst.waitdelay2hm = (inst.waitdelay2hm or 0) + 1
        end
    end
    -- 工作
    local function stopwork(inst)
        if inst.task2hm ~= nil then
            inst.task2hm:Cancel()
            inst.task2hm = nil
        end
        if inst.protectcloud2hm then inst.protectcloud2hm = nil end
        if inst.waitdelay2hm then inst.waitdelay2hm = nil end
    end
    local function startwork(inst)
        if inst.fires then
            for i, fx in ipairs(inst.fires) do fx:Remove() end
            inst.fires = {}
        end
        if not inst.task2hm then
            if inst.upgrade2hm == "lunarplant_husk" then inst.task2hm = inst:DoPeriodicTask(0.75, SpawnVineAttack) end
            if inst.upgrade2hm == "purebrilliance" then inst.task2hm = inst:DoPeriodicTask(1, SpawnCloudAttack) end
            if inst.upgrade2hm == "dreadstone" then
                inst.task2hm = inst:DoPeriodicTask(0.5, SpawnDarkCloudAttack)
                local parent = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or inst
                if parent ~= nil and parent._shadowdsubmissive_task == nil and inst.components.shadowdominance then
                    parent:AddTag("shadowdominance")
                end
            end
        end
    end
    local function sleepstopwork(inst) if inst.upgrade2hm and inst.components.burnable and inst.components.burnable:IsBurning() then stopwork(inst) end end
    local function wakestartwork(inst) if inst.upgrade2hm and inst.components.burnable and inst.components.burnable:IsBurning() then startwork(inst) end end
    local function checkstatus(inst)
        inst.checkstatustask2hm = nil
        if inst.components.burnable and inst.components.burnable:IsBurning() then
            if inst:HasTag("fire") then inst:RemoveTag("fire") end
            startwork(inst)
        else
            stopwork(inst)
        end
    end
    local function onignite(inst, data)
        if inst.upgrade2hm then
            if inst.checkstatustask2hm then inst.checkstatustask2hm:Cancel() end
            if inst:HasTag("fire") then inst:RemoveTag("fire") end
            inst.checkstatustask2hm = inst:DoTaskInTime(0, checkstatus)
        end
    end
    local function onextinguish(inst, data)
        if inst.upgrade2hm then
            if inst.fires then
                for i, fx in ipairs(inst.fires) do fx:Remove() end
                inst.fires = {}
            end
            if inst.checkstatustask2hm then inst.checkstatustask2hm:Cancel() end
            inst.checkstatustask2hm = inst:DoTaskInTime(0, checkstatus)
        end
    end
    local function onsave(inst, data) data.upgrade2hm = inst.upgrade2hm end
    local function onload(inst, data)
        if data and data.upgrade2hm then
            inst.upgrade2hm = data.upgrade2hm
            inst.components.repairable2hm.ignoremax = nil
            if inst.components.weapon then inst.components.weapon:SetOnAttack() end
            if inst.components.lighter then inst:RemoveComponent("lighter") end
            if inst.upgrade2hm == "lunarplant_husk" then
                inst:AddTag("lunarplant2hm")
                inst.repairmaterials2hm.purebrilliance = nil
                inst.repairmaterials2hm.dreadstone = nil
            end
            if inst.upgrade2hm == "purebrilliance" then
                inst:AddTag("brilliance2hm")
                inst.components.fueled:InitializeFuelLevel(TUNING.TORCH_FUEL * 4)
                inst.repairmaterials2hm.lunarplant_husk = nil
                inst.repairmaterials2hm.dreadstone = nil
                inst:AddTag("gestaltprotection")
            end
            if inst.upgrade2hm == "dreadstone" then
                inst:AddTag("dreadstone2hm")
                inst.components.fueled:InitializeFuelLevel(TUNING.TORCH_FUEL * 4)
                inst.repairmaterials2hm.lunarplant_husk = nil
                inst.repairmaterials2hm.purebrilliance = nil
                inst:AddComponent("shadowdominance")
            end
            inst.clientupgrade2hm:set(true)
        end
    end
    local function onrepaired(inst, repairuse, doer, repair_item, useitems)
        if inst.upgrade2hm then return end
        onload(inst, {upgrade2hm = repair_item and repair_item.prefab})
        checkstatus(inst)
    end
    local function DisplayNameFn(inst)
        if inst:HasTag("lunarplant2hm") then return (TUNING.isCh2hm and "亮茄" or "Brightshade ") .. STRINGS.NAMES.TORCH end
        if inst:HasTag("brilliance2hm") then return STRINGS.NAMES.PUREBRILLIANCE .. (TUNING.isCh2hm and "" or " ") .. STRINGS.NAMES.TORCH end
        if inst:HasTag("dreadstone2hm") then return (TUNING.isCh2hm and "绝望石" or "Dreadstone ") .. STRINGS.NAMES.TORCH end
    end
    local function itemtilefn(inst)
        if not inst.bgimage2hm then
            if inst:HasTag("lunarplant2hm") then inst.bgimage2hm = "lunarplant_husk.tex" end
            if inst:HasTag("brilliance2hm") then inst.bgimage2hm = "purebrilliance.tex" end
            if inst:HasTag("dreadstone2hm") then inst.bgimage2hm = "dreadstone.tex" end
            if inst.bgimage2hm then inst.bgaltas2hm = GetInventoryItemAtlas(inst.bgimage2hm) end
        end
        return "upgrade2hmdirty", nil, inst.bgaltas2hm, inst.bgimage2hm
    end
    AddPrefabPostInit("torch", function(inst)
        inst.repairmaterials2hm = {lunarplant_husk = TUNING.TORCH_FUEL, purebrilliance = TUNING.TORCH_FUEL * 4, dreadstone = TUNING.TORCH_FUEL * 4}
        inst.displaynamefn = DisplayNameFn
        inst.itemtilefn2hm = itemtilefn
        inst.clientupgrade2hm = net_bool(inst.GUID, "torch.upgrade2hm", "upgrade2hmdirty")
        inst.clientupgrade2hm:set(false)
        if not TheWorld.ismastersim then return end
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.ignoremax = true
        inst.components.repairable2hm.onrepaired = onrepaired
        inst:ListenForEvent("onremove", stopwork)
        inst:ListenForEvent("entitysleep", sleepstopwork)
        inst:ListenForEvent("entitywake", wakestartwork)
        inst:ListenForEvent("onignite", onignite)
        inst:ListenForEvent("onextinguish", onextinguish)
        SetOnSave(inst, onsave)
        SetOnLoad(inst, onload)
    end)
end

-- 月熠奔雷/月熠晨星,装备时可以月熠充电
if GetModConfigData("Moongleam Weapon") then
    local Image = require "widgets/image"
    -- 储备月熠后的武器每5次攻击消耗1次耐久
    local function makeweaponconsumemoongleam(inst, fn)
        local OnAttack = inst.components.weapon.OnAttack
        inst.components.weapon.OnAttack = function(self, attacker, target, ...)
            if inst.moongleamlevel2hm:value() > 0 and attacker and attacker:IsValid() and attacker.components.combat and target and target:IsValid() then
                if attacker.components.combat.ignorehitrange then
                    if self.attackwear ~= 0 and not TheWorld:HasTag("cave") and math.random() < 0.01 * inst.moongleamlevel2hm:value() then
                        SpawnPrefab("lightning").Transform:SetPosition(target.Transform:GetWorldPosition())
                    end
                elseif attacker.components.combat.lastdoattacktime and
                    (not self.lastdoattacktime2hm or attacker.components.combat.lastdoattacktime - self.lastdoattacktime2hm > 0.3) then
                    self.lastdoattacktime2hm = attacker.components.combat.lastdoattacktime
                    self.moongleamidx2hm = (self.moongleamidx2hm or 0) + 1
                    if self.moongleamidx2hm >= 5 then
                        self.moongleamidx2hm = self.moongleamidx2hm - 5
                        if inst.moongleamupgradefn2hm then inst.moongleamupgradefn2hm(self.inst, -1) end
                    end
                end
            end
            OnAttack(self, attacker, target, ...)
        end
    end
    local function cancelmultithrow(inst)
        inst.multithrow2hm = nil
        inst.multithrow2hmdelay = nil
        inst.projectileneedstartpos2hm = nil
        inst.components.weapon.projectiletmp2hm = nil
    end
    local function spellattack(inst, target, pos, doer)
        if doer and doer:IsValid() and doer.components.combat and doer.components.playercontroller and inst.components.weapon and
            not inst.components.weapon.projectile then
            inst:AddTag("projectile")
            local dist = math.clamp(inst.moongleamlevel2hm:value() / 5 + 14, 14, 18)
            if target and not TestCombatTarget2hm(doer, target, 22) then
                if not pos then pos = target:IsValid() and target:GetPosition() or nil end
                target = nil
            end
            if target == nil and pos and pos.x then
                local ents = TheSim:FindEntities(pos.x, 0, pos.z, 4, {"_combat", "_health"}, {"FX", "DECOR", "INLIMBO"})
                for _, ent in ipairs(ents) do
                    if TestCombatTarget2hm(doer, ent, dist + 4) then
                        target = ent
                        break
                    end
                end
            end
            inst:RemoveTag("projectile")
            if target then
                inst.components.weapon.projectiletmp2hm = "bishop_charge"
                inst.projectileneedstartpos2hm = true
                local multithrow2hm = 1
                -- local multithrow2hm = math.clamp(math.min(math.ceil(inst.moongleamlevel2hm:value() / 10),
                --                                           math.ceil(target.components.health.currenthealth / 100)), 1, 3)
                if multithrow2hm > 1 then
                    inst.multithrow2hm = multithrow2hm
                    inst.multithrow2hmdelay = 0.2
                    inst.components.weapon:LaunchProjectile(inst, target)
                    inst:DoTaskInTime(inst.multithrow2hmdelay * multithrow2hm + 10 * FRAMES, cancelmultithrow)
                else
                    inst.components.weapon:LaunchProjectile(inst, target)
                    inst.components.weapon.projectiletmp2hm = nil
                    inst.projectileneedstartpos2hm = nil
                end
                if inst.components.rechargeable then
                    if inst.moongleamlevel2hm:value() >= 20 and not inst.usedrefreshcd2hm then
                        inst.usedrefreshcd2hm = true
                    else
                        if inst.usedrefreshcd2hm then inst.usedrefreshcd2hm = nil end
                        inst.components.rechargeable:Discharge(multithrow2hm * 12)
                    end
                end
                if inst.moongleamupgradefn2hm then inst.moongleamupgradefn2hm(inst, -multithrow2hm) end
            elseif doer.sg and doer.sg.currentstate and doer.sg.currentstate.name == "quickcastspell" then
                doer.sg:GoToState("idle", true)
            end
        end
    end
    local function nightstickstopcd(inst)
        if inst.spellcaster2hm and not inst.components.spellcaster then
            inst:AddComponent("spellcaster")
            inst.components.spellcaster:SetSpellFn(spellattack)
            inst.components.spellcaster.canuseontargets = true
            inst.components.spellcaster.can_cast_fn = truefn
            inst.components.spellcaster.canuseonpoint = true
            inst.components.spellcaster.canuseonpoint_water = true
            inst.components.spellcaster.quickcast = true
        end
    end
    local function nightstickstartcd(inst) if inst.components.spellcaster then inst:RemoveComponent("spellcaster") end end
    STRINGS.ACTIONS.CASTSPELL.NIGHTSTICK2HM = STRINGS.ACTIONS.CASTAOE.SPEAR_WATHGRITHR_LIGHTNING_CHARGED
    -- 晨星给予月熠后，武器基础伤害大幅度提高,且可以远程攻击,连射攻击,0级后恢复原样
    local function nightstickmoongleamupgrade(inst, v)
        local newlevel = math.clamp(inst.moongleamlevel2hm:value() + (v or 1), 0, 40)
        inst.components.weapon:SetDamage(((inst.planarupgrade2hm:value() and TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_DAMAGE or
                                             TUNING.SPEAR_WATHGRITHR_LIGHTNING_DAMAGE) - TUNING.NIGHTSTICK_DAMAGE) * newlevel / 25 + TUNING.NIGHTSTICK_DAMAGE)
        inst.moongleamlevel2hm:set(newlevel)
        if not inst.components.weapon.moongleaminit2hm then makeweaponconsumemoongleam(inst) end
        if newlevel > 0 then
            if newlevel >= 10 then
                if not inst:HasTag("fastrepair2hm") then inst:AddTag("fastrepair2hm") end
            elseif inst:HasTag("fastrepair2hm") then
                inst:RemoveTag("fastrepair2hm")
            end
            if not inst.components.spellcaster then
                inst.spellcaster2hm = true
                inst:AddComponent("spellcaster")
                inst.components.spellcaster:SetSpellFn(spellattack)
                inst.components.spellcaster.canuseontargets = true
                inst.components.spellcaster.can_cast_fn = truefn
                inst.components.spellcaster.canuseonpoint = true
                inst.components.spellcaster.canuseonpoint_water = true
                inst.components.spellcaster.quickcast = true
                if not POPULATING and newlevel < 10 and inst.components.equippable and inst.components.equippable:IsEquipped() then
                    inst.components.rechargeable:Discharge(12)
                end
            end
        else
            if inst:HasTag("fastrepair2hm") then inst:RemoveTag("fastrepair2hm") end
            if inst.spellcaster2hm then
                if inst.components.spellcaster then inst:RemoveComponent("spellcaster") end
                -- if inst.components.rechargeable then
                --     inst:RemoveComponent("rechargeable")
                --     inst:AddTag("rechargeable")
                -- end
                inst.spellcaster2hm = nil
            end
        end
    end
    -- 电羊角武器可以给月熠升级,如果月熠储备已经满额,则多出月熠用来恢复耐久
    local function customrepair(inst, repairuse, doer, repair_item)
        local leftlevel
        if inst.planarupgrade2hm then
            leftlevel = (inst.planarupgrade2hm:value() and 25 or 5) - inst.moongleamlevel2hm:value()
        else
            leftlevel = (inst.upgradeplanar2hm and 25 or 5) - inst.moongleamlevel2hm:value()
        end
        if leftlevel <= 0 then return -1 end
        if repair_item and repair_item:IsValid() and repair_item.components.stackable then
            local neednum = math.min(repair_item.components.stackable.stacksize, leftlevel)
            repair_item.components.stackable:Get(neednum):Remove()
            if inst.components.finiteuses then
                local oldpercent = inst.components.finiteuses:GetPercent()
                inst.components.finiteuses:Repair(neednum * repairuse / 2)
                local newpercent = inst.components.finiteuses:GetPercent()
                if newpercent > 1 then inst.components.finiteuses:SetPercent(math.max(oldpercent, 1)) end
            elseif inst.components.fueled then
                local oldpercent = inst.components.fueled:GetPercent()
                inst.components.fueled:DoDelta(neednum * repairuse / 2, doer)
                local newpercent = inst.components.fueled:GetPercent()
                if newpercent > 1 then inst.components.fueled:SetPercent(math.max(oldpercent, 1)) end
            end
            if inst.moongleamupgradefn2hm then inst.moongleamupgradefn2hm(inst, neednum) end
            return true
        end
    end
    -- 月熠晨星刚装备时也会进入CD,充能且10级以后无装备CD
    local function onequipped(inst, data)
        if inst.binduserid2hm and not POPULATING and data and data.owner then
            if data.owner.userid ~= inst.binduserid2hm then
                inst:DoTaskInTime(0, ForceUnequipWeapon2hm)
            elseif inst.bindusername2hm:value() == "" and data.owner.name then
                inst.bindusername2hm:set(data.owner.name)
            end
        end
        if inst.moongleamlevel2hm:value() > 0 and inst.moongleamlevel2hm:value() < 10 and inst.components.rechargeable then
            inst.components.rechargeable:Discharge(12)
        end
    end
    -- 晨星给予约束静电后，获得移速加成和位面伤害,但也会绑定充能玩家，非充能玩家装备后就掉落
    local function planarupgrade(inst, userid, name)
        if inst.components.fueled then inst:AddTag("moonsparkchargeable") end
        inst.planarupgrade2hm:set(true)
        inst.repairmaterials2hm.moonstorm_static_item = nil
        if not inst.binduserid2hm then inst.binduserid2hm = userid end
        if name and name ~= inst.bindusername2hm:value() then inst.bindusername2hm:set(name) end
        if not inst.components.planardamage then
            inst:AddComponent("planardamage")
            inst.components.planardamage:SetBaseDamage(TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_PLANAR_DAMAGE)
        end
        inst.components.equippable.walkspeedmult = math.max(TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_SPEED_MULT, inst.components.equippable.walkspeedmult or 1)
    end
    -- 晨星可以给予约束静电升级一次
    local function nightstickcustomrepair(inst, repairuse, doer, repair_item)
        if not (doer and doer.userid) then return end
        if repair_item and repair_item:IsValid() and repair_item.prefab == "moonstorm_static_item" then
            if inst.binduserid2hm then return end
            planarupgrade(inst, doer.userid, doer.name)
            if inst.components.fueled then inst.components.fueled:SetPercent(math.max(inst.components.fueled:GetPercent(), 1)) end
            repair_item:Remove()
            return true
        end
        return customrepair(inst, repairuse, doer, repair_item)
    end
    local function itemtilefn(inst, self)
        local leveltext
        local level = inst.moongleamlevel2hm and inst.moongleamlevel2hm:value()
        if level > 0 then
            leveltext = "󰀏" .. tostring(level)
            if not inst.bgimage2hm then
                inst.bgimage2hm = "moonstorm_spark.tex"
                inst.bgaltas2hm = GetInventoryItemAtlas(inst.bgimage2hm)
            end
            inst.spelltype = inst.spelltype or "NIGHTSTICK2HM"
        elseif inst.bgimage2hm then
            inst.bgimage2hm = nil
            inst.bgaltas2hm = nil
        end
        if inst.planarupgrade2hm and inst.planarupgrade2hm:value() and not inst.itemtile_lightning then
            inst.repairmaterials2hm.moonstorm_static_item = nil
            inst.itemtile_lightning = true
            if self.image and not self.image.itemtile_lightning then
                self.image.itemtile_lightning = self.image:AddChild(Image(GetInventoryItemAtlas("itemtile_lightning.tex"), "itemtile_lightning.tex",
                                                                          "default.tex"))
            end
        end
        return "upgrade2hmdirty", leveltext, inst.bgaltas2hm, inst.bgimage2hm
    end
    local function nightstickonload(inst, data)
        if data and data.binduserid2hm then planarupgrade(inst, data.binduserid2hm, data.bindusername2hm) end
        if data and data.moongleam2hm then nightstickmoongleamupgrade(inst, data.moongleam2hm) end
    end
    local function nightstickonsave(inst, data)
        data.moongleam2hm = inst.moongleamlevel2hm:value()
        data.binduserid2hm = inst.planarupgrade2hm:value() and inst.binduserid2hm
        data.bindusername2hm = inst.bindusername2hm:value() ~= "" and inst.bindusername2hm:value()
    end
    local function nightstickDisplayNameFn(inst)
        return (inst.planarupgrade2hm:value() and (TUNING.isCh2hm and "充能" or "Charged ") or "") ..
                   (inst.moongleamlevel2hm:value() > 0 and STRINGS.NAMES.MOONSTORM_SPARK or "") .. (TUNING.isCh2hm and "" or " ") .. STRINGS.NAMES.NIGHTSTICK ..
                   (inst.bindusername2hm:value() ~= "" and ("(" .. inst.bindusername2hm:value() .. ")") or "")
    end
    local function nightstickactfn2hm(act, inst)
        if act.action == ACTIONS.CASTSPELL then act.distance = math.clamp(inst.moongleamlevel2hm:value() / 5 + 14, 14, 18) end
    end
    AddPrefabPostInit("nightstick", function(inst)
        inst:AddTag("rechargeable")
        inst.actfn2hm = nightstickactfn2hm
        inst.repairmaterials2hm = {moonstorm_spark = TUNING.NIGHTSTICK_FUEL / 20, moonstorm_static_item = 1}
        inst.displaynamefn = nightstickDisplayNameFn
        inst.itemtilefn2hm = itemtilefn
        inst.moongleamlevel2hm = net_smallbyte(inst.GUID, "nightstick.moongleamlevel2hm", "upgrade2hmdirty")
        inst.moongleamlevel2hm:set(0)
        inst.planarupgrade2hm = net_bool(inst.GUID, "nightstick.planarupgrade2hm", "upgrade2hmdirty")
        inst.planarupgrade2hm:set(false)
        inst.bindusername2hm = net_string(inst.GUID, "nightstick.bindusername2hm")
        inst.bindusername2hm:set("")
        if not TheWorld.ismastersim then return end
        if not inst.components.rechargeable then inst:AddComponent("rechargeable") end
        inst.components.rechargeable:SetOnDischargedFn(nightstickstartcd)
        inst.components.rechargeable:SetOnChargedFn(nightstickstopcd)
        inst.moongleamupgradefn2hm = nightstickmoongleamupgrade
        SetOnLoad(inst, nightstickonload)
        SetOnSave(inst, nightstickonsave)
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.customrepair = nightstickcustomrepair
        inst:ListenForEvent("equipped", onequipped)
    end)
    -- 奔雷给予月熠后,电击伤害大幅度提高,并解除装备和冲刺限制,0级后恢复限制
    local function newLightning_OnCharged(inst) inst.components.aoetargeting:SetEnabled(true) end
    local function spearmoongleamupgrade(inst, v)
        local newlevel = math.clamp(inst.moongleamlevel2hm:value() + (v or 1), 0, 40)
        inst.components.weapon:SetElectric((TUNING.ELECTRIC_DAMAGE_MULT - 1) * newlevel / 25 + 1, (TUNING.ELECTRIC_WET_DAMAGE_MULT -
                                               TUNING.SPEAR_WATHGRITHR_LIGHTNING_WET_DAMAGE_MULT) * newlevel / 25 +
                                               TUNING.SPEAR_WATHGRITHR_LIGHTNING_WET_DAMAGE_MULT)
        inst.moongleamlevel2hm:set(newlevel)
        if not inst.components.weapon.moongleaminit2hm then makeweaponconsumemoongleam(inst) end
        if newlevel > 0 then
            if newlevel >= 10 then
                if not inst:HasTag("fastrepair2hm") then inst:AddTag("fastrepair2hm") end
            elseif inst:HasTag("fastrepair2hm") then
                inst:RemoveTag("fastrepair2hm")
            end
            if inst.insulated2hm == nil then
                inst.insulated2hm = inst.components.equippable.insulated or false
                inst.components.equippable.insulated = true
            end
            if not inst.restrictedtag2hm then
                inst.restrictedtag2hm = inst.components.equippable.restrictedtag
                inst.components.equippable.restrictedtag = nil
            end
            -- 命中敌人不恢复耐久
            if inst.components.aoeweapon_lunge and inst.components.aoeweapon_lunge.onhitfn and not inst.onhitfn2hm then
                inst.onhitfn2hm = inst.components.aoeweapon_lunge.onhitfn
                inst.components.aoeweapon_lunge.onhitfn = function(inst, ...)
                    local owner = inst.components.inventoryitem:GetGrandOwner()
                    if inst.onhitfn2hm and
                        not (owner ~= nil and owner.components.skilltreeupdater ~= nil and
                            owner.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_spear_4")) then inst.onhitfn2hm(inst, ...) end
                end
            end
            -- 还消耗耐久
            if inst.components.aoeweapon_lunge and inst.components.aoeweapon_lunge.onlungedfn and not inst.onlungedfn2hm then
                inst.onlungedfn2hm = inst.components.aoeweapon_lunge.onlungedfn
                inst.components.aoeweapon_lunge.onlungedfn = function(inst, ...)
                    if inst.onlungedfn2hm then inst.onlungedfn2hm(inst, ...) end
                    -- 20级后可以无CD施法一次
                    if inst.usedrefreshcd2hm then
                        inst.usedrefreshcd2hm = nil
                    elseif inst.moongleamlevel2hm:value() >= 20 then
                        inst.usedrefreshcd2hm = true
                        inst.components.rechargeable:Discharge(0)
                    end
                    local owner = inst.components.inventoryitem:GetGrandOwner()
                    if inst.moongleamupgradefn2hm and
                        not (owner ~= nil and owner.components.skilltreeupdater ~= nil and
                            owner.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_spear_4")) then
                        inst.moongleamupgradefn2hm(inst, -1)
                    end
                    -- 冲刺时无敌帧,可以打断后摇
                    if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name == "combat_lunge" then
                        if inst.moongleamlevel2hm:value() >= 10 then inst.sg:AddStateTag("temp_invincible") end
                        if inst.moongleamlevel2hm:value() >= 20 then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:AddStateTag("idle")
                        end
                    end
                end
            end
            if not inst.onchargedfn2hm and inst.components.rechargeable and inst.components.rechargeable.onchargedfn then
                inst.onchargedfn2hm = inst.components.rechargeable.onchargedfn
                inst.components.rechargeable.onchargedfn = newLightning_OnCharged
                if inst.components.rechargeable:IsCharged() then inst.components.aoetargeting:SetEnabled(true) end
            end
        else
            if inst:HasTag("fastrepair2hm") then inst:RemoveTag("fastrepair2hm") end
            if inst.insulated2hm ~= nil then
                inst.components.equippable.insulated = inst.insulated2hm
                inst.insulated2hm = nil
            end
            if inst.onchargedfn2hm then
                if inst.components.rechargeable then inst.components.rechargeable.onchargedfn = inst.onchargedfn2hm end
                inst.onchargedfn2hm = nil
                if inst._onskillrefresh and inst.components.inventoryitem and inst.components.inventoryitem.owner then
                    inst._onskillrefresh(inst, inst.components.inventoryitem.owner)
                else
                    inst.components.aoetargeting:SetEnabled(false)
                end
            end
            if inst.onlungedfn2hm ~= nil then
                if inst.components.aoeweapon_lunge then inst.components.aoeweapon_lunge.onlungedfn = inst.onlungedfn2hm end
                inst.onlungedfn2hm = nil
            end
            if inst.onhitfn2hm ~= nil then
                if inst.components.aoeweapon_lunge then inst.components.aoeweapon_lunge.onhitfn = inst.onhitfn2hm end
                inst.onhitfn2hm = nil
            end
            if inst.restrictedtag2hm then
                inst.components.equippable.restrictedtag = inst.restrictedtag2hm
                inst.restrictedtag2hm = nil
                inst:DoTaskInTime(0, ForceUnequipWeapon2hm, function(owner) return not owner:HasTag(inst.components.equippable.restrictedtag) end)
            end
        end
    end
    local recentspear
    local function spearonload(inst, data)
        if recentspear == inst then recentspear = nil end
        if data and data.moongleam2hm then spearmoongleamupgrade(inst, data.moongleam2hm) end
    end
    local function spearonsave(inst, data) data.moongleam2hm = inst.moongleamlevel2hm:value() end
    local function spearDisplayNameFn(inst)
        if inst.moongleamlevel2hm:value() > 0 then
            return (inst.upgradeplanar2hm and (TUNING.isCh2hm and "充能" or "Charged ") or "") .. STRINGS.NAMES.MOONSTORM_SPARK ..
                       (TUNING.isCh2hm and "" or " ") .. STRINGS.NAMES.SPEAR_WATHGRITHR_LIGHTNING
        end
    end
    local function processskillrefresh(oldfn)
        return function(inst, ...)
            local SetEnabled
            if inst.components.aoetargeting and inst.moongleamlevel2hm:value() >= 1 then
                SetEnabled = inst.components.aoetargeting.SetEnabled
                inst.components.aoetargeting.SetEnabled = nilfn
            end
            oldfn(inst, ...)
            if SetEnabled then
                inst.components.aoetargeting.SetEnabled = SetEnabled
                if inst.components.rechargeable then inst.components.aoetargeting:SetEnabled(inst.components.rechargeable:IsCharged()) end
            end
        end
    end
    local function spearpostinit(inst)
        inst.repairmaterials2hm = {moonstorm_spark = TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_USES / 20}
        inst.displaynamefn = spearDisplayNameFn
        inst.itemtilefn2hm = itemtilefn
        inst.moongleamlevel2hm = net_smallbyte(inst.GUID, "wigfridspear.moongleamlevel2hm", "upgrade2hmdirty")
        inst.moongleamlevel2hm:set(0)
        if not TheWorld.ismastersim then return end
        inst.moongleamupgradefn2hm = spearmoongleamupgrade
        SetOnPreLoad(inst, spearonload)
        SetOnSave(inst, spearonsave)
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.customrepair = customrepair
        -- 升级的装备10级无切换CD,1级无冲刺技能加点限制
        if inst.components.equippable then
            if inst.components.equippable.onequipfn then
                local onequipfn = inst.components.equippable.onequipfn
                inst.components.equippable.onequipfn = processskillrefresh(function(inst, ...)
                    local Discharge
                    if inst.components.rechargeable and inst.moongleamlevel2hm:value() >= 10 then
                        Discharge = inst.components.rechargeable.Discharge
                        inst.components.rechargeable.Discharge = nilfn
                    end
                    onequipfn(inst, ...)
                    if Discharge then inst.components.rechargeable.Discharge = Discharge end
                end)
            end
            if inst.components.equippable.onunequipfn then
                inst.components.equippable.onunequipfn = processskillrefresh(inst.components.equippable.onunequipfn)
            end
        end
        if inst._onskillrefresh then inst._onskillrefresh = processskillrefresh(inst._onskillrefresh) end
    end
    local function clearrecentspear(inst) if recentspear == inst then recentspear = nil end end
    AddPrefabPostInit("spear_wathgrithr_lightning_charged", function(inst)
        inst.upgradeplanar2hm = true
        spearpostinit(inst)
        if not TheWorld.ismastersim then return end
        if not POPULATING then
            recentspear = inst
            inst:DoTaskInTime(0, clearrecentspear)
        end
    end)
    AddPrefabPostInit("spear_wathgrithr_lightning", function(inst)
        spearpostinit(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.upgradeable and inst.components.upgradeable.onupgradefn then
            local onupgradefn = inst.components.upgradeable.onupgradefn
            inst.components.upgradeable.onupgradefn = function(inst, ...)
                local level = inst.moongleamlevel2hm:value()
                onupgradefn(inst, ...)
                if recentspear and recentspear:IsValid() and level and level > 0 then spearmoongleamupgrade(recentspear, level) end
            end
        end
    end)
    AddStategraphPostInit("wilson", function(sg)
        sg.states.combat_lunge_start.tags.temp_invincible = true
        -- sg.states.combat_lunge.tags.temp_invincible = true
    end)
end

-- 蜂后帽可以修复，蜂巢/杀人蜂巢
if GetModConfigData("hivehat") then
    local function customrepair(inst, repairuse, doer, repair_item)
        if repair_item and repair_item:IsValid() and (repair_item.prefab == "bee" or repair_item.prefab == "killerbee") then
            local isbee = repair_item.prefab == "bee"
            local hive = SpawnPrefab(isbee and "beehive" or "wasphive")
            hive.Transform:SetPosition((doer or inst).Transform:GetWorldPosition())
            if inst.components.armor and hive.components.health then hive.components.health:SetPercent(inst.components.armor:GetPercent()) end
            if repair_item.components.stackable then
                local neednum = math.min(repair_item.components.stackable.stacksize, isbee and TUNING.BEEHIVE_EMERGENCY_BEES or TUNING.WASPHIVE_EMERGENCY_WASPS)
                repair_item.components.stackable:Get(neednum):Remove()
                if hive.components.childspawner then
                    hive.components.childspawner.emergencychildreninside = math.min(neednum, hive.components.childspawner.maxemergencychildren)
                end
            else
                repair_item:Remove()
            end
            inst.persists = false
            inst:DoTaskInTime(0, inst.Remove)
            return true
        else
            return -1
        end
    end
    local function onequip(inst, data) if data.owner and data.owner:IsValid() then data.owner.hivehat2hm = true end end
    local function onunequip(inst, data) if data.owner and data.owner:IsValid() then data.owner.hivehat2hm = nil end end
    AddPrefabPostInit("hivehat", function(inst)
        inst.repairmaterials2hm = {bee = 1, killerbee = 1, beeswax = TUNING.ARMOR_HIVEHAT, honeycomb = TUNING.ARMOR_HIVEHAT}
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("equipped", onequip)
        inst:ListenForEvent("unequipped", onunequip)
        inst:AddComponent("repairable2hm")
        inst.components.repairable2hm.customrepair = customrepair
    end)
    -- 靠近杀人蜂巢不出杀人蜂
    AddPrefabPostInit("wasphive", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.playerprox and inst.components.playerprox.onnear then
            local onnear = inst.components.playerprox.onnear
            inst.components.playerprox.onnear = function(inst, target, ...)
                if target and target.hivehat2hm then return end
                onnear(inst, target, ...)
            end
        end
    end)
    -- 采集蜂箱不出蜜蜂
    AddPrefabPostInit("beebox", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.childspawner and inst.components.childspawner.ReleaseAllChildren then
            local ReleaseAllChildren = inst.components.childspawner.ReleaseAllChildren
            inst.components.childspawner.ReleaseAllChildren = function(self, target, ...)
                if target and target.hivehat2hm then return end
                ReleaseAllChildren(self, target, ...)
            end
        end
    end)
    -- 杀人蜂和发情蜜蜂不主动仇恨玩家
end

-- 拾荒尖帽耐久增强，可修复，坠落伤害100%免伤，飞行伤害90%免伤，其余伤害75%免伤
if GetModConfigData("scraphat") then
    -- 耐久增强到640
    TUNING.ARMOR_SCRAP_HAT = 640
    -- 伤害减免75%
    TUNING.ARMOR_SCRAP_HAT_ABSORPTION = 0.75

    -- 0耐久不消失
    local function onequip_scraphat(inst, data) 
        if inst:HasTag("broken") and data and data.owner then
            inst:DoTaskInTime(0, function()     
                if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() and 
                   data.owner.components.inventory ~= nil then
                    local item = data.owner.components.inventory:Unequip(inst.components.equippable.equipslot)
                    -- 0耐久装备时卸下
                    if item ~= nil then
                        data.owner.components.inventory:GiveItem(item, nil, data.owner:GetPosition())
                    end
                end
            end)
            return
        end
    end

    local function OnBroken(inst) inst:AddTag("broken") end

    local function OnRepaired(inst) inst:RemoveTag("broken") end

    AddPrefabPostInit("scraphat", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- 免疫落石和落玻璃碎片伤害
        if not inst.components.resistance then
            inst:AddComponent("resistance")
            inst.components.resistance:AddResistance("quakedebris")
            inst.components.resistance:AddResistance("lunarhaildebris")
        end
        
        -- 标记为硬质护甲
        inst:AddTag("hardarmor")
        
        -- 可修复
        MakeForgeRepairable(inst, FORGEMATERIALS.WAGPUNKBITS, OnBroken, OnRepaired) 
        inst:ListenForEvent("equipped", onequip_scraphat)
    end)
    
    -- 修改玩家伤害计算
    AddComponentPostInit("inventory", function(self)
        if not self.inst:HasTag("player") then return end
        
        local oldApplyDamage = self.ApplyDamage
        self.ApplyDamage = function(self, damage, attacker, weapon, spdamage, ...)
            local scraphat = self:GetEquippedItem(EQUIPSLOTS.HEAD)
            
            if scraphat and scraphat.prefab == "scraphat" and scraphat.components.equippable:IsEquipped() and
               damage and damage > 0 and attacker and attacker:IsValid() then
                
                -- 检查是否为飞行伤害
                local isflying = attacker:HasTag("flying") and not attacker:HasTag("antlion") and
                    (weapon == nil or (weapon.components.projectile == nil and 
                     (weapon.components.weapon == nil or weapon.components.weapon.projectile == nil))) and
                    self.inst:IsNear(attacker, attacker:GetPhysicsRadius(0) + 
                     (attacker.components.combat and attacker.components.combat:GetHitRange() or 3))
                
                if isflying then
                    -- 飞行伤害90%减免（在75%基础减免后再减60%）
                    damage = damage * 0.4  
                end
            end
            
            return oldApplyDamage(self, damage, attacker, weapon, spdamage, ...)
        end
    end)
end


-- 铥矿皇冠升级
if GetModConfigData("ruinshat gem upgrade") then
    local function ruinshat_fxanim(inst)
        if inst._fx and inst._fx:IsValid() then
            inst._fx.AnimState:PlayAnimation("hit")
            inst._fx.AnimState:PushAnimation("idle_loop")
        end
    end

    local function ruinshat_unproc(inst)
        if inst:HasTag("forcefield") then
            inst:RemoveTag("forcefield")
            
            if inst._fx ~= nil then
                inst._fx:kill_fx()
                inst._fx = nil
            end

            inst:RemoveEventCallback("armordamaged", ruinshat_fxanim)
            if inst._shield_armordamaged_fn then
                inst:RemoveEventCallback("armordamaged", inst._shield_armordamaged_fn)
                inst._shield_armordamaged_fn = nil
                inst._shield_prev_armor = nil
                inst._shield_armordamaged_block = nil
            end
            if inst._shield_attacked_fn and inst._owner then
                inst:RemoveEventCallback("attacked", inst._shield_attacked_fn, inst._owner)
                inst._shield_attacked_fn = nil
            end

            if inst._shield_end_task then
                inst._shield_end_task:Cancel()
                inst._shield_end_task = nil
            end

            inst.components.armor:SetAbsorption(TUNING.ARMOR_RUINSHAT_ABSORPTION)
            inst.components.armor.ontakedamage = nil
        end
    end

    -- 紫宝石减速清除
    local function _Purple_EndSlow(target)
        target._attrpurple_task_ruinshat = nil
        if target._attrpurple_fx_ruinshat ~= nil then
            target._attrpurple_fx_ruinshat:KillFX()
            target._attrpurple_fx_ruinshat = nil
        end
        if target.components and target.components.locomotor ~= nil then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "attrpurple_ruinshat")
        end
    end

    -- 绿宝石中毒
    local function _Green_Tick(inst, src)
        if inst.components.health and not inst.components.health:IsDead() then
            local delta = -math.clamp(inst.components.health.maxhealth / 20, 1, 40)
            inst.components.health:DoDelta(delta, nil, src)
            local fx = SpawnPrefab("ghostlyelixir_speed_dripfx")
            if fx ~= nil then
                fx.Transform:SetScale(.5, .5, .5)
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end
        inst._attrgreen_idx_ruinshat = (inst._attrgreen_idx_ruinshat or 0) + 1
        if inst._attrgreen_idx_ruinshat >= 10 and inst._attrgreen_task_ruinshat then
            inst._attrgreen_task_ruinshat:Cancel()
            inst._attrgreen_task_ruinshat = nil
            inst._attrgreen_idx_ruinshat = nil
        end
    end

    -- 不同宝石护盾效果
    local GEM_SHIELD_EFFECTS = {
        redgem = {
            color = {1, 0.2, 0.2, 1},  
            absorption = TUNING.FULL_ABSORPTION,  -- 100%免伤
            ontakedamage = function(inst, owner, damage_amount, attacker)
                if owner ~= nil and owner.components.sanity ~= nil then
                    owner.components.sanity:DoDelta(-damage_amount * TUNING.ARMOR_RUINSHAT_DMG_AS_SANITY, false)
                end
            end
        },
        bluegem = {
            color = {0.1, 0.5, 1, 1},  
            absorption = TUNING.ARMOR_RUINSHAT_ABSORPTION,  
            ontakedamage = function(inst, owner, damage_amount, attacker)
                -- 冰冻
                if attacker ~= nil and attacker:IsValid() and attacker.components.freezable then
                    attacker.components.freezable:AddColdness(2)
                    attacker.components.freezable:SpawnShatterFX()
                    if owner and owner.SoundEmitter then
                        owner.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/ice_small")
                    end                    
                end
                if owner ~= nil and owner.components.sanity ~= nil then
                    owner.components.sanity:DoDelta(-1, false)
                end
            end
        },
        purplegem = {
            color = {0.7, 0.2, 1, 1},  
            absorption = TUNING.ARMOR_RUINSHAT_ABSORPTION, 
            ontakedamage = function(inst, owner, damage_amount, attacker)
                -- 减速
                if attacker ~= nil and attacker:IsValid() and attacker.components and 
                   attacker.components.locomotor ~= nil and attacker.entity then
                    if attacker._attrpurple_task_ruinshat ~= nil then
                        attacker._attrpurple_task_ruinshat:Cancel()
                    else
                        local fx = SpawnPrefab("shadow_trap_debuff_fx")
                        if fx ~= nil then
                            fx.entity:SetParent(attacker.entity)
                            fx:OnSetTarget(attacker)
                        end
                        attacker._attrpurple_fx_ruinshat = fx
                    end
                    attacker._attrpurple_task_ruinshat = attacker:DoTaskInTime(6, _Purple_EndSlow)
                    attacker.components.locomotor:SetExternalSpeedMultiplier(attacker, "attrpurple_ruinshat", 0.5)
                end
                if owner ~= nil and owner.components.sanity ~= nil then
                    owner.components.sanity:DoDelta(-1, false)
                end
            end
        },
        yellowgem = {
            color = {1, 0.9, 0, 1},  
            absorption = TUNING.ARMOR_RUINSHAT_ABSORPTION,  
            ontakedamage = function(inst, owner, damage_amount, attacker)
                -- 电击反伤
                if attacker ~= nil and attacker:IsValid() and attacker.components.combat ~= nil and 
                   (attacker.components.health ~= nil and not attacker.components.health:IsDead()) then
                    
                    if attacker:HasTag("electricstunimmune") then
                        -- 只造成伤害
                        SpawnPrefab("electrichitsparks"):AlignToTarget(attacker, owner, true)
                        local damage_mult = 1
                        if not (attacker:HasTag("electricdamageimmune") or 
                               (attacker.components.inventory ~= nil and attacker.components.inventory:IsInsulated())) then
                            damage_mult = TUNING.ELECTRIC_DAMAGE_MULT or 1
                            local wetness_mult = (attacker.components.moisture ~= nil and attacker.components.moisture:GetMoisturePercent()) or 
                                                (attacker:GetIsWet() and 1) or 0
                            damage_mult = damage_mult + TUNING.ELECTRIC_WET_DAMAGE_MULT * wetness_mult
                        end
                        attacker.components.combat:GetAttacked(owner, damage_mult * 15, nil, "electric")
                    else
                        -- 触发僵直和伤害
                        SpawnPrefab("electrichitsparks"):AlignToTarget(attacker, owner, true)
                        local damage_mult = 1
                        if not (attacker:HasTag("electricdamageimmune") or 
                               (attacker.components.inventory ~= nil and attacker.components.inventory:IsInsulated())) then
                            damage_mult = TUNING.ELECTRIC_DAMAGE_MULT or 1
                            local wetness_mult = (attacker.components.moisture ~= nil and attacker.components.moisture:GetMoisturePercent()) or 
                                                (attacker:GetIsWet() and 1) or 0
                            damage_mult = damage_mult + TUNING.ELECTRIC_WET_DAMAGE_MULT * wetness_mult
                        end

                        if attacker.sg and attacker.sg:HasState("electrocute") and 
                           not (attacker:HasTag("electricdamageimmune") or 
                               (attacker.components.inventory ~= nil and attacker.components.inventory:IsInsulated())) then
                            attacker:PushEvent("electrocute", { attacker = owner, stimuli = "electric" })
                        end
                        
                        attacker.components.combat:GetAttacked(owner, damage_mult * 15, nil, "electric")
                        
                        -- 冷却10-12秒
                        attacker:AddTag("electricstunimmune")
                        attacker:DoTaskInTime(math.random(10, 12), function()
                            if attacker and attacker:IsValid() then
                                attacker:RemoveTag("electricstunimmune")
                            end
                        end)
                    end
                end
                if owner ~= nil and owner.components.sanity ~= nil then
                    owner.components.sanity:DoDelta(-1, false)
                end
            end
        },
        orangegem = {
            color = {1, 0.4, 0, 1}, 
            absorption = TUNING.ARMOR_RUINSHAT_ABSORPTION,  
            ontakedamage = function(inst, owner, damage_amount, attacker)
                -- 传送
                if attacker ~= nil and attacker:IsValid() and attacker.Physics and owner and owner:IsValid() then
                    local px, py, pz = owner.Transform:GetWorldPosition()
                    local ax, ay, az = attacker.Transform:GetWorldPosition()
                    local angle = math.atan2(az - pz, ax - px)
                    local radius = 4
                    local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))
                    local dest = Vector3(ax, ay, az) + offset
                    
                    if TheWorld.Map:IsAboveGroundAtPoint(dest.x, dest.y, dest.z) and 
                       not TheWorld.Map:IsPointNearHole(dest) then
                        attacker.Physics:Teleport(dest.x, dest.y, dest.z)
                        SpawnPrefab("sand_puff_large_front").Transform:SetPosition(dest.x, dest.y, dest.z)
                        SpawnPrefab("sand_puff_large_back").Transform:SetPosition(ax, ay, az)
                    end
                end
                if owner ~= nil and owner.components.sanity ~= nil then
                    owner.components.sanity:DoDelta(-1, false)
                end
            end
        },
        greengem = {
            color = {0.2, 1, 0.3, 1},  
            absorption = TUNING.ARMOR_RUINSHAT_ABSORPTION,  
            ontakedamage = function(inst, owner, damage_amount, attacker)
                if owner ~= nil and owner.components.sanity ~= nil then
                    owner.components.sanity:DoDelta(-1, false)
                end
            end
        },
    }

    local function gem_proc(inst, owner, attacker, gem_type)
        local config = GEM_SHIELD_EFFECTS[gem_type]
        if not config then return end

        inst:AddTag("forcefield")
        
        if inst._fx ~= nil then
            inst._fx:kill_fx()
        end
        inst._fx = SpawnPrefab("forcefieldfx")
        inst._fx.entity:SetParent(owner.entity)
        inst._fx.Transform:SetPosition(0, 0.2, 0)
        

        if inst._fx.AnimState and config.color then
            inst._fx.AnimState:SetMultColour(unpack(config.color))
        end
        
        inst:ListenForEvent("armordamaged", ruinshat_fxanim)

        -- 设置减伤率
        inst.components.armor:SetAbsorption(config.absorption)


        local shield_owner = owner
        local shield_config = config

        inst._shield_attacked_fn = function(owner_inst, data)
            if shield_config.ontakedamage and data and data.attacker and data.attacker:IsValid() then
                shield_config.ontakedamage(inst, shield_owner, data.damage or 0, data.attacker)
            end
        end
        
        inst:ListenForEvent("attacked", inst._shield_attacked_fn, owner)
        -- 绿宝石：护盾期间被扣除的耐久以150%转化为回复
        if gem_type == "greengem" and inst.components.armor then
            inst._shield_prev_armor = inst.components.armor.condition or 0
            inst._shield_armordamaged_fn = function(inst, data)
                if not inst.components.armor then return end
                -- 防止在回复时再次触发导致循环
                if inst._shield_armordamaged_block then return end
                local cur = inst.components.armor.condition or 0
                local prev = inst._shield_prev_armor or cur
                local deducted = prev - cur
                if deducted and deducted > 0 then
                    local heal = deducted * 1.5
                    inst._shield_armordamaged_block = true
                    inst.components.armor:Repair(heal)
                    inst._shield_armordamaged_block = nil
                end
                inst._shield_prev_armor = inst.components.armor.condition or 0
            end
            inst:ListenForEvent("armordamaged", inst._shield_armordamaged_fn)
        end
        
        if gem_type == "redgem" then
            inst.components.armor.ontakedamage = function(inst, damage_amount)
                if shield_owner ~= nil and shield_owner.components.sanity ~= nil then
                    shield_owner.components.sanity:DoDelta(-damage_amount * TUNING.ARMOR_RUINSHAT_DMG_AS_SANITY, false)
                end
            end
        end

        if inst.components.rechargeable then
            inst.components.rechargeable:Discharge(TUNING.ARMOR_RUINSHAT_COOLDOWN)
        end


        if inst._shield_end_task then
            inst._shield_end_task:Cancel()
        end
        inst._shield_end_task = inst:DoTaskInTime(TUNING.ARMOR_RUINSHAT_DURATION, function() 
            ruinshat_unproc(inst)
            inst._shield_end_task = nil
        end)
    end

    -- 不同的触发效果
    local function tryproc_with_gem(inst, owner, data)
        if inst.components.rechargeable and not inst.components.rechargeable:IsCharged() then
            return
        end

        if data.redirected then return end
        if math.random() < TUNING.ARMOR_RUINSHAT_PROC_CHANCE then
            local gem_type = inst.upgrade_type2hm
            if gem_type and GEM_SHIELD_EFFECTS[gem_type] then
                gem_proc(inst, owner, data.attacker, gem_type)
            end
        end
    end

    -- 应用宝石升级
    local function apply_ruinshat_upgrade(inst, gem_type)
        local valid_gems = {"redgem", "bluegem", "purplegem", "yellowgem", "orangegem", "greengem"}
        if not table.contains(valid_gems, gem_type) then return end
        
        inst:AddTag("upgraded_" .. gem_type)
        inst.upgrade_type2hm = gem_type

        if inst.components.persistent2hm then
            inst.components.persistent2hm.data.upgraded = true
            inst.components.persistent2hm.data.upgrade_type = gem_type
        end

        if inst.clientupgrade2hm then
            inst.clientupgrade2hm:set(true)
        end
    end

    -- 物品栏图标显示
    local function ruinshat_itemtilefn(inst)
        if not inst.bgimage2hm then
            local gem_types = {"redgem", "bluegem", "purplegem", "yellowgem", "orangegem", "greengem"}
            for _, gem in ipairs(gem_types) do
                if inst:HasTag("upgraded_" .. gem) then
                    inst.bgimage2hm = gem .. ".tex"
                    break
                end
            end
            if inst.bgimage2hm then 
                inst.bgaltas2hm = GetInventoryItemAtlas(inst.bgimage2hm) 
            end
        end
        return "upgrade2hmdirty", nil, inst.bgaltas2hm, inst.bgimage2hm
    end
    
    local function ruinshat_DisplayNameFn(inst)
        local gem_names = {
            redgem = STRINGS.NAMES.REDGEM,
            bluegem = STRINGS.NAMES.BLUEGEM,
            purplegem = STRINGS.NAMES.PURPLEGEM,
            yellowgem = STRINGS.NAMES.YELLOWGEM,
            orangegem = STRINGS.NAMES.ORANGEGEM,
            greengem = STRINGS.NAMES.GREENGEM,
        }
        for gem, name in pairs(gem_names) do
            if inst:HasTag("upgraded_" .. gem) then
                return name .. (TUNING.isCh2hm and "" or " ") .. STRINGS.NAMES.RUINSHAT
            end
        end
    end
    
    local function ruinshat_onsave(inst, data)
        if inst.upgrade_type2hm then
            data.upgrade_type2hm = inst.upgrade_type2hm
        end
    end

    local function ruinshat_onload(inst, data)
        if data and data.upgrade_type2hm then
            apply_ruinshat_upgrade(inst, data.upgrade_type2hm)
            inst:DoTaskInTime(0, function()
                if inst.components.equippable and inst.components.equippable:IsEquipped() then
                    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
                    if owner and inst._gem_attacked_fn then
                        inst:RemoveEventCallback("attacked", inst._gem_attacked_fn, owner)
                        inst:ListenForEvent("attacked", inst._gem_attacked_fn, owner)
                    end
                end
            end)
        end
    end

    AddPrefabPostInit("ruinshat", function(inst)
        inst.displaynamefn = ruinshat_DisplayNameFn
        inst.itemtilefn2hm = ruinshat_itemtilefn
        inst.clientupgrade2hm = net_bool(inst.GUID, "ruinshat.upgrade2hm", "upgrade2hmdirty")
        inst.clientupgrade2hm:set(false)
        
        if not TheWorld.ismastersim then return end

        if not inst.components.rechargeable then
            inst:AddComponent("rechargeable")
        end

        local original_onfinished = inst.components.armor.onfinished
        inst.components.armor:SetOnFinished(function(inst)
            if inst:HasTag("forcefield") then
                ruinshat_unproc(inst)
            end
            if original_onfinished then
                original_onfinished(inst)
            end
        end)

        inst._gem_attacked_fn = function(owner, data) 
            tryproc_with_gem(inst, owner, data)
        end
        
        inst:DoTaskInTime(0, function()
            -- 设置一个永久的_task，让原版的tryproc永远认为处于冷却中
            if inst._task then
                inst._task:Cancel()
            end
            inst._task = inst:DoTaskInTime(999999, function() end)
            
            local original_onattach = inst.onattach
            local original_ondetach = inst.ondetach
            
            inst.onattach = function(owner)
                original_onattach(owner)
                if inst.upgrade_type2hm then
                    inst:ListenForEvent("attacked", inst._gem_attacked_fn, owner)
                end
            end
            
            inst.ondetach = function()
                if inst._owner then
                    if inst.upgrade_type2hm and inst._gem_attacked_fn then
                        inst:RemoveEventCallback("attacked", inst._gem_attacked_fn, inst._owner)
                    end

                    if inst:HasTag("forcefield") then
                        ruinshat_unproc(inst)
                    end
                end
                original_ondetach()
            end
        end)

        if not inst.components.persistent2hm then
            inst:AddComponent("persistent2hm")
        end

        if not inst.components.trader then
            inst:AddComponent("trader")
        end

        inst.components.trader.acceptnontradable = true
        
        inst.components.trader:SetAbleToAcceptTest(function(inst, item, giver)
            if inst.components.equippable and inst.components.equippable:IsEquipped() then
                giver:DoTaskInTime(.01, function()
                    if giver and giver.components.talker then
                        giver.components.talker:Say(TUNING.isCh2hm and "先把它摘下来吧" or "I need to unequip it first.")
                    end
                end)
                return false
            end
            
            local valid_gems = {"redgem", "bluegem", "purplegem", "yellowgem", "orangegem", "greengem"}
            return table.contains(valid_gems, item.prefab) and not inst.upgrade_type2hm
        end)
        
        inst.components.trader.onaccept = function(inst, giver, item)
            local valid_gems = {"redgem", "bluegem", "purplegem", "yellowgem", "orangegem", "greengem"}
            if table.contains(valid_gems, item.prefab) then
                if giver.SoundEmitter then
                    giver.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
                end
                apply_ruinshat_upgrade(inst, item.prefab)
                return true
            end
            return false
        end
        
        SetOnSave(inst, ruinshat_onsave)
        SetOnLoad(inst, ruinshat_onload)
    
        inst.upgrade_type2hm = nil
    end)

end



