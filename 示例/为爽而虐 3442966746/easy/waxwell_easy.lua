local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 麦斯威尔正常血量
if GetModConfigData("Maxwell Normal Health") then 

    if not hardmode then 
        TUNING.WAXWELL_HEALTH = TUNING.WILSON_HEALTH 
    end

    -- 暗影秘典不再燃烧
    AddPrefabPostInit("waxwelljournal", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.fuel then inst:RemoveComponent("fuel") end
        if inst.components.burnable then inst:RemoveComponent("burnable") end
    end)

end

-- 麦斯威尔吃花瓣获得恶魔花瓣
if GetModConfigData("Maxwell Eat Petals Get Dark Petals") then
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.prefab == "petals" then inst.components.inventory:GiveItem(SpawnPrefab("petals_evil")) end
    end
    local function unlockrecipes(inst)
        if inst.components.builder then
            if not inst.components.builder:KnowsRecipe("nightmarefuel") and inst.components.builder:CanLearn("nightmarefuel") then
                inst.components.builder:UnlockRecipe("nightmarefuel")
            end
        end
    end
    AddPrefabPostInit("waxwell", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", OnEat)
        inst:DoTaskInTime(0, unlockrecipes)
    end)
end

-- 麦斯威尔右键倒走
if GetModConfigData("Maxwell Right Wrapback") and false then
    AddPrefabPostInit("waxwell", function(inst)
        AddWrapAbility(inst)
        inst.rightaction2hm_cooldown = GetModConfigData("Maxwell Right Wrapback")
    end)
end

-- 麦斯威尔解锁暗影剑甲
if GetModConfigData("Maxwell Unlock Dark Sword/Armor") then
    -- table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WAXWELL, "nightsword")
    -- table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WAXWELL, "armor_sanity")
    local function unlockrecipes(inst)
        if inst.components.builder then
            if not inst.components.builder:KnowsRecipe("nightsword") and inst.components.builder:CanLearn("nightsword") then
                inst.components.builder:UnlockRecipe("nightsword")
            end
            if not inst.components.builder:KnowsRecipe("armor_sanity") and inst.components.builder:CanLearn("armor_sanity") then
                inst.components.builder:UnlockRecipe("armor_sanity")
            end
        end
    end
    AddPrefabPostInit("waxwell", function(inst)
        if not TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, unlockrecipes)
    end)
end

-- 麦斯威尔右键闪袭,攻击无敌
if GetModConfigData("Maxwell Right Lunge") or GetModConfigData("Maxwell Attacked Disappear") then
    local canlunge = GetModConfigData("Maxwell Right Lunge")
    local candisappear = GetModConfigData("Maxwell Attacked Disappear")
    
    -- 参考骨甲的护盾逻辑
    local MAXWELL_RESISTANCES = {
        "_combat",
        "explosive", 
        "quakedebris",
        "lunarhaildebris",
        "caveindebris",
        "trapdamage",
        "rock_tree",
    }
    
    local SHIELD_DURATION = 10 * FRAMES
    local SHIELD_VARIATIONS = 3
    local MAIN_SHIELD_CD = 1.2
    
    local function PickShield(inst)
        local t = GetTime()
        local flipoffset = math.random() < .5 and SHIELD_VARIATIONS or 0
        local dt = t - (inst.lastmainshield or 0)
        if dt >= MAIN_SHIELD_CD then
            inst.lastmainshield = t
            return flipoffset + 3
        end
        
        local rnd = math.random()
        if rnd < dt / MAIN_SHIELD_CD then
            inst.lastmainshield = t
            return flipoffset + 3
        end
        
        return flipoffset + (rnd < dt / (MAIN_SHIELD_CD * 2) + .5 and 2 or 1)
    end
    
    -- 创建虚拟护盾装备的免伤逻辑
    local function MaxwellOnResistDamage(inst, damage_amount, attacker)
        -- 冷却时间
        if not inst.disappeartask2hm then
            inst.disappeartask2hm = inst:DoTaskInTime(math.max(20 - (inst.shadowlevel2hm or 4) * 2, 8), function() 
                inst.disappeartask2hm = nil 
            end)
        end
        
        local fx = SpawnPrefab("shadow_shield"..tostring(PickShield(inst)))
        fx.entity:SetParent(inst.entity)

        if inst.maxwell_shield_task2hm ~= nil then
            inst.maxwell_shield_task2hm:Cancel()
        end

        inst.maxwell_shield_task2hm = inst:DoTaskInTime(SHIELD_DURATION, function()
            inst.maxwell_shield_task2hm = nil
            -- 护盾结束后重新启用抗性检查
        end)
    end
    
    -- 重写inventory的ApplyDamage方法来实现麦斯威尔的免伤
    local function MaxwellApplyDamageOverride(self, damage, attacker, weapon, spdamage)
        -- 检查麦斯威尔的免伤条件
        if candisappear and self.inst.prefab == "waxwell" then
            local level = self.inst.shadowlevel2hm or 0
            local canresist = level >= 4 
                             and not self.inst.disappeartask2hm 
                             and not self.inst.allmiss2hm
                             and not self.inst.maxwell_shield_task2hm
            
            if canresist then
                -- 检查是否应该抵抗这种伤害类型
                local should_resist = false
                if attacker ~= nil then
                    for _, resist_tag in ipairs(MAXWELL_RESISTANCES) do
                        if attacker:HasTag(resist_tag) or (weapon ~= nil and weapon:HasTag(resist_tag)) then
                            should_resist = true
                            break
                        end
                    end
                end
                
                if should_resist then
                    MaxwellOnResistDamage(self.inst, damage, attacker)
                    return 0, nil -- 完全免疫伤害
                end
            end
        end
        
        -- 调用原始的ApplyDamage方法
        return self._original_ApplyDamage(self, damage, attacker, weapon, spdamage)
    end
    
    local function checklevel(inst)
        if inst.shadowlungeendfn2hm then inst.shadowlungeendfn2hm = nil end
        local level = 0
        for k, v in pairs(EQUIPSLOTS) do
            local equip = inst.components.inventory:GetEquippedItem(v)
            if equip ~= nil and equip.components.shadowlevel ~= nil then 
                level = level + equip.components.shadowlevel:GetCurrentLevel() 
            end
        end
        inst.shadowlevel2hm = level
        
        if canlunge then
            if inst.shadowlungecdtask2hm then
                inst.shadowlungeendfn2hm = checklevel
            elseif level >= 4 then
                if not inst:HasTag("shadowlunge2hm") then inst:AddTag("shadowlunge2hm") end
            elseif inst:HasTag("shadowlunge2hm") then
                inst:RemoveTag("shadowlunge2hm")
            end
        end
    end
    
    AddPrefabPostInit("waxwell", function(inst)
        if canlunge then AddLungeAbility(inst) end
        if not TheWorld.ismastersim then return end
        inst.shadowlevel2hm = 0
        inst.lastmainshield = 0
        
        if candisappear then
            local inventory = inst.components.inventory
            if inventory then
                inventory._original_ApplyDamage = inventory.ApplyDamage
                inventory.ApplyDamage = MaxwellApplyDamageOverride
            end
        end
        
        inst:ListenForEvent("equip", checklevel)
        inst:ListenForEvent("unequip", checklevel)
        -- 初始检查
        inst:DoTaskInTime(0, checklevel)
    end)
end

-- 覆盖麦斯威尔不妥协战斗暗影仆从削弱
if GetModConfigData("Maxwell removes UM nerf") then
    if not TUNING.DSTU then return end
    -- 移除理智上限消耗增加
    TUNING.SHADOWWAXWELL_SANITY_PENALTY.SHADOWPROTECTOR = 0.15  --30
    -- 移除存在时间减半
    TUNING.SHADOWWAXWELL_PROTECTOR_DURATION = 120  
    -- 移除受到伤害增加
    TUNING.SHADOWWAXWELL_PROTECTOR_HEALTH_CLAMP_TAKEN = 15
end

-- 麦斯威尔右键自身睡前故事
if GetModConfigData("Maxwell Right Self Sleepytime Stories") then
    AddReadBookRightSelfAction("waxwell", "book_sleep", GetModConfigData("Maxwell Right Self Sleepytime Stories"),
                               STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BIRDCAGE.SLEEPING)
end
