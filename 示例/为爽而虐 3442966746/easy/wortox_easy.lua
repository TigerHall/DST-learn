local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 沃拓克斯吃食物获取75%三维
if GetModConfigData("Wortox Eat Food Normal") then
    AddPrefabPostInit("wortox", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.eater ~= nil then inst.components.eater:SetAbsorptionModifiers(0.75, 0.75, 0.75) end
    end)
end

-- 沃拓克斯灵魂不掉落
if GetModConfigData("Wortox No Drop Soul") then
    AddPrefabPostInit("wortox_soul", function(inst)
        inst:DoTaskInTime(0, function()
            MakeUnlimitStackSize(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.keepondeath = true
                inst.components.inventoryitem.keepondrown = true
            end
        end)
    end)
end

-- 沃拓克斯首传免费
if GetModConfigData("Wortox Free Blink") then
    TUNING.WORTOX_FREEHOP_TIMELIMIT = TUNING.WORTOX_FREEHOP_TIMELIMIT * 1.6
    
    -- 灵魂计数函数
    local function soul_limit(inst)
        if not inst.components.inventory then return false end
        local searchingenv = inst.components.inventory:FindItems(function(item) 
            return item:IsValid() and 
            (item.prefab == "wortox_soul" or item.prefab == "wortox_souljar") 
        end)
        local count = 0
        for i, v in pairs(searchingenv) do
            if v.prefab == "wortox_soul" then -- 对灵魂数量进行计数
                count = count + (v.components.stackable ~= nil and v.components.stackable:StackSize() or 1) 
            elseif v.prefab == "wortox_souljar" then -- 对灵魂罐灵魂进行计数
                count = count + (v.soulcount or 0)
            end
        end
        return count < 10
    end
    
    AddPrefabPostInit("wortox", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- CD结束时不再消耗灵魂（仅针对灵魂数量小于10）
        local FinishPortalHop = inst.FinishPortalHop
        inst.FinishPortalHop2hm = function(inst, ...)
            if soul_limit(inst) then
                local inv = inst.components.inventory
                inst.components.inventory = nil
                FinishPortalHop(inst, ...)
                inst.components.inventory = inv
            else
                FinishPortalHop(inst, ...)
            end
        end
        
        -- 重写跳跃逻辑，在第一段回声结束时使用免费函数
        local oldTryToPortalHop = inst.TryToPortalHop
        inst.TryToPortalHop = function(inst, souls, consumeall, ...)
            local skilltreeupdater = inst.components.skilltreeupdater
            local hops_per_soul = TUNING.WORTOX_FREEHOP_HOPSPERSOUL
            if skilltreeupdater and skilltreeupdater:IsActivated("wortox_liftedspirits_3") then
                hops_per_soul = hops_per_soul + TUNING.SKILLS.WORTOX.WORTOX_FREEHOP_HOPSPERSOUL_ADD
            end
            
            local was_free_counter = inst._freesoulhop_counter
            
            if oldTryToPortalHop(inst, souls, consumeall, ...) then
                -- 判断是否应该在第一段回声结束时免费
                -- 条件：跳跃前计数器为0（第一段回声开始）且不是地图跳跃
                local should_use_free_finish = was_free_counter <= 0 and not consumeall
                
                if should_use_free_finish then
                    local cooldowntime = inst:GetSoulEchoCooldownTime()
                    if inst.finishportalhoptask ~= nil then
                        inst.finishportalhoptask:Cancel()
                        inst.finishportalhoptask = inst:DoTaskInTime(cooldowntime, inst.FinishPortalHop2hm)
                    end
                end
                return true
            end
            return false
        end
    end)
end

-- 沃拓克斯增伤
if GetModConfigData("Wortox damage upgrade") then
    local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
        if mount or not target:IsValid() then return 1 end
        -- 基础增益计算
        local buff = inst.components.sanity:GetPercent() >= 0.5 and inst.components.health:GetPercent() >= 0.5 and 0.25 or 0
        -- 困难模式惩罚计算
        local debuff = 0
        if hardmode then 
            debuff = (inst.components.sanity:GetPercent() <= 0.25 or inst.components.health:GetPercent() <= 0.25) and 0.25 or 0
        end        
        -- 最终倍率 
        return 1 + buff - debuff
    end
    AddPrefabPostInit("wortox", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.combat.customdamagemultfn then
            inst.components.combat.customdamagemultfn = CustomCombatDamage
        else
            local old = inst.components.combat.customdamagemultfn
            inst.components.combat.customdamagemultfn = function(...) return (old(...) or 1) * CustomCombatDamage(...) end
        end
        -- if not inst.components.combat.onhitotherfn then inst.components.combat.onhitotherfn = WilowAttackFx end
    end)
end

-- 沃拓克斯额外掉落灵魂
if GetModConfigData("Wortox Extra Soul Drop") then
    if not (TUNING.DSTU and TUNING.DSTU.WORTOXCHANGES) then return end

    local function DropExtraSouls(victim, wortox_player)
        if not victim or not victim.components.health or not wortox_player then return end
        
        local maxhealth = victim.components.health.maxhealth
        local x, y, z = victim.Transform:GetWorldPosition()
        local extra_souls = 0
        
        -- 高于100血的有10%的概率额外掉落第一个灵魂
        if maxhealth > 100 and math.random() < 0.1 then extra_souls = extra_souls + 1 end
        
        -- 高于500血的有30%的概率额外掉落第二个灵魂
        if maxhealth > 500 and math.random() < 0.3 then extra_souls = extra_souls + 1 end
        
        -- 高于1000血的有50%的概率额外掉落第三个灵魂
        if maxhealth > 1000 and math.random() < 0.5 then extra_souls = extra_souls + 1 end
        
        if extra_souls > 0 then
            local wortox_soul_common = require("prefabs/wortox_soul_common")
            if wortox_soul_common and wortox_soul_common.SpawnSoulAt then
                for i = 1, extra_souls do
                    local theta = math.random() * TWOPI
                    local radius = 0.8 + math.random() * 0.4
                    wortox_soul_common.SpawnSoulAt(
                        x + math.cos(theta) * radius, 
                        0, 
                        z - math.sin(theta) * radius, 
                        victim, 
                        false
                    )
                end
            end
        end
    end
    
    AddPrefabPostInit("wortox", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- 监听entity_droploot事件，在原版灵魂掉落后触发额外掉落
        local function OnExtraEntityDropLoot(inst, data)
            local victim = data.inst
            if not victim or victim.nosoultask or not victim:IsValid() then
                return
            end
            
            local shouldspawn = victim == inst
            if shouldspawn or (
                not inst.components.health:IsDead() and
                victim.components.health and victim.components.health:IsDead()
            ) then
                if not shouldspawn then
                    local range = TUNING.WORTOX_SOULEXTRACT_RANGE
                    if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wortox_thief_1") then
                        range = range + TUNING.SKILLS.WORTOX.SOULEXTRACT_RANGE_BONUS
                    end
                    shouldspawn = inst:IsNear(victim, range)
                end
                
                if shouldspawn then
                    -- 检查是否有灵魂（使用原版的HasSoul逻辑）
                    local wortox_soul_common = require("prefabs/wortox_soul_common")
                    if wortox_soul_common and wortox_soul_common.HasSoul and wortox_soul_common.HasSoul(victim) then
                        DropExtraSouls(victim, inst)
                    end
                end
            end
        end
        
        -- 兼容没有lootdropper的情况
        local function OnExtraEntityDeath(inst, data)
            if data.inst ~= nil then
                if (data.inst.components.lootdropper == nil or data.inst.components.lootdropper.forcewortoxsouls or data.explosive) then
                    OnExtraEntityDropLoot(inst, data)
                end
            end
        end
        
        inst.onextraentitydroploot2hm = function(src, data) OnExtraEntityDropLoot(inst, data) end
        inst:ListenForEvent("entity_droploot", inst.onextraentitydroploot2hm, TheWorld)
        
        inst.onextraentitydeath2hm = function(src, data) OnExtraEntityDeath(inst, data) end
        inst:ListenForEvent("entity_death", inst.onextraentitydeath2hm, TheWorld)
    end)
end
