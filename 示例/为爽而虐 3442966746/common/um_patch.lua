local UpvalueHacker = require "tools/upvaluehacker"

-- ============================================================================================================================
-- 减少妥协影怪噩梦燃料掉落
local function reduced_nightmarefueldrop(inst)
    if not TheWorld.ismastersim then return end        
    if inst.components.lootdropper then
        local SpawnLootPrefab = inst.components.lootdropper.SpawnLootPrefab
        inst.components.lootdropper.SpawnLootPrefab = function(self, lootprefab, ...)
            if lootprefab then
                if lootprefab == "nightmarefuel" then
                    if math.random() < 1/3 then return end      -- 噩梦燃料掉落减少
                end
            end
            return SpawnLootPrefab(self, lootprefab, ...)
        end
    end
end

for _, prefab in ipairs({"dreadeye", "creepingfear", "ancient_trepidation"}) do
    AddPrefabPostInit(prefab, reduced_nightmarefueldrop)
end

-- ==========================================================================================================================
-- 妥协厨师袋也可以移动中打开
AddPrefabPostInit("spicepack", function(inst)
    inst:RemoveTag("portablestorage")
    inst:AddTag("portablestoragePG")
    if not TheWorld.ismastersim then return end
    if inst.components.container.droponopen then inst.components.container.droponopen = nil end
end)

-- ==========================================================================================================================
-- 恐怖之眼和双子魔眼逃离后泰拉盒子进入cd

-- ============================================================================================================
-- 地下蟹兵螃蟹生成的发条重上游戏掉落物重置bug修复
local function lootdropper_patch(inst)
    if not TheWorld.ismastersim then return end
    inst.OnSave = function(inst, data)
    data.chanceloottable = inst.components.lootdropper.chanceloottable
    end
    inst.OnLoad = function(inst, data)
        if data and data.chanceloottable then
            inst.components.lootdropper:SetChanceLootTable(data.chanceloottable)
        end
    end
end

for _, prefab in ipairs({"khook", "roship", "bight"}) do
    AddPrefabPostInit(prefab, lootdropper_patch)
end

-- ==========================================================================================================================
-- 增强蜂后帽
if TUNING.DSTU.BEEBOX_NERF then 
    AddPrefabPostInit("beebox", function(inst)    
        if not TheWorld.ismastersim then return end        
        local old_ReleaseBees2hm = inst.ReleaseBees        
        local function ReleaseBees2hm(inst, picker)
            if picker and picker.components.inventory then
                local beehat = picker.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
                if beehat and beehat.prefab == "hivehat" and beehat.components.armor then
                    beehat.components.armor:TakeDamage(1)  -- 每次只扣1耐久
                    return  -- 直接返回
                end
            end
            if old_ReleaseBees2hm then 
                old_ReleaseBees2hm(inst, picker) 
            end
        end
        
        inst.ReleaseBees = ReleaseBees2hm
    end)
end

-- ==========================================================================================================
-- 妥协火荨麻防止崩溃
local function delayremove(inst) inst:DoTaskInTime(0, inst.Remove2hm) end
local function makedelayremove(inst)
    if not TheWorld.ismastersim then return end
    inst.Remove2hm = inst.Remove
    inst.Remove = delayremove
end

AddPrefabPostInit("um_pyre_nettles", makedelayremove) 

-- ============================================================================================================================
-- 妥协气垫船被帝王蟹炮塔识别摧毁的崩溃问题
local function InstantlyBreakBoat(inst)
    -- This is not for SGboat but is for safety on physics.
    if inst.components.boatphysics then
        inst.components.boatphysics:SetHalting(true)
    end
    --Keep this in sync with SGboat.
    for entity_on_platform in pairs(inst.components.walkableplatform:GetEntitiesOnPlatform()) do
        entity_on_platform:PushEvent("abandon_ship")
    end
    for player_on_platform in pairs(inst.components.walkableplatform:GetPlayersOnPlatform()) do
        player_on_platform:PushEvent("onpresink")
    end
    inst:sinkloot()
    if inst.postsinkfn then
        inst:postsinkfn()
    end
    inst:Remove()
end
AddPrefabPostInit("portableboat", function(inst)
if not TheWorld.ismastersim then return end
    if not inst.InstantlyBreakBoat then
        inst.InstantlyBreakBoat = InstantlyBreakBoat
    end
end)


-- ===========================================================================================================================
-- 为爽pvp启用时妥协牛上受伤时崩溃问题,给官方打个补丁
AddComponentPostInit("rider", function(self)
local oldMount = self.Mount
    self.Mount = function(self, target, instant, ...)
        oldMount(self, target, instant, ...)
        if self.inst.components.combat.redirectdamagefn ~= nil then
            local oldredirectdamagefn = function(inst, attacker, damage, weapon, stimuli, ...)
                return target:IsValid()
                    and not (target.components.health ~= nil and target.components.health:IsDead())
                    and not (weapon ~= nil and (
                        weapon.components.projectile ~= nil or
                        weapon.components.complexprojectile ~= nil or
                        (weapon.components.weapon and weapon.components.weapon:CanRangedAttack())
                    ))
                    and stimuli ~= "electric"
                    and stimuli ~= "darkness"
                    and target
                    or nil
            end
            self.inst.components.combat.redirectdamagefn = function(inst, attacker, damage, weapon, stimuli, ...)
                return stimuli ~= "beefalo_half_damage" and oldredirectdamagefn(inst, attacker, damage, weapon, stimuli, ...) or nil
            end
        end
    end
end)

-- ===========================================================================================================================
-- 勋章坎普斯添加妥协所需的组件
AddPrefabPostInit("medal_naughty_krampus", function(inst)
    if not TheWorld.ismastersim then return end
    if not inst.components.thief then inst:AddComponent("thief") end
end)

-- =========================================================================================================================
-- 月龙火龙脱加载不移动
local function PatchDragonflySleep(inst)
    if not TheWorld.ismastersim then return end
    local _OnEntitySleep = nil
    local count_fn = 0
    local LeaveWorld = nil
    for i, func in ipairs(inst.event_listeners["entitysleep"][inst]) do
        local success, leaveWorldFunc = pcall(UpvalueHacker.GetUpvalue, func, "LeaveWorld")
        if success and leaveWorldFunc then
            _OnEntitySleep = func
            LeaveWorld = leaveWorldFunc
            count_fn = count_fn + 1
        end
    end
    if _OnEntitySleep ~= nil and count_fn == 1 and LeaveWorld ~= nil then
        local function OnEntitySleep(inst)
            local PlayerPosition = inst:GetNearestPlayer()
            if inst.shouldGoAway then LeaveWorld(inst) end
        end
        inst:RemoveEventCallback("entitysleep", _OnEntitySleep)
        inst:ListenForEvent("entitysleep", OnEntitySleep)
        inst.OnEntitySleep2hm = OnEntitySleep
    end
end

for _, prefab in ipairs({"moonmaw_dragonfly", "mock_dragonfly"}) do
    AddPrefabPostInit(prefab, PatchDragonflySleep)
end

-- ==============================================================================================================================       
-- 增强玻璃甲，每次攻击都生成玻璃碎片
AddPrefabPostInit("armor_glassmail", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 装备时进行修改
    if inst.components.equippable then
        local original_onequip = inst.components.equippable.onequipfn
        inst.components.equippable:SetOnEquip(function(inst, owner)
            if original_onequip then original_onequip(inst, owner) end
            
            -- 创建攻击处理函数
            local function UpdateGlass2hm(owner, data)
                if data and data.target and (data.target.components.combat and data.target.components.combat.defaultdamage > 0) or (data.target.prefab == "dummytarget" or data.target.prefab == "antlion" or data.target.prefab == "stalker_atrium" or data.target.prefab == "stalker") then

                    if not owner.lavae then return end

                    -- 执行旋转效果（TempDamage的功能）
                    for i = 1, 8 do
                        if owner.lavae[i] and owner.lavae[i].Speen then
                            owner.lavae[i]:Speen()
                        end
                    end
                    
                    -- 每次攻击都尝试生成玻璃碎片
                    if inst.armormeleehits == nil then inst.armormeleehits = 0 end
                    inst.armormeleehits = inst.armormeleehits + 1
                    
                    -- 检查是否还有隐藏的玻璃碎片可以生成
                    local hasHiddenCrystal = false
                    local hiddenCount = 0
                    for i = 1, 8 do
                        if owner.lavae[i] and owner.lavae[i].hidden then
                            hasHiddenCrystal = true
                            hiddenCount = hiddenCount + 1
                        end
                    end
                    
                    -- 修改为每次攻击都生成（原版是>=3）
                    if inst.armormeleehits >= 1 and hasHiddenCrystal then
                        -- 尝试添加玻璃碎片
                        local function TryAddCrystal()
                            local rand = math.random(1, 8)
                            if owner.lavae[rand] and owner.lavae[rand].hidden then
                                owner.lavae[rand].hidden = false
                                owner.lavae[rand]:Show()
                                if owner.lavae[rand].Light then
                                    owner.lavae[rand].Light:Enable(true)
                                end
                                if owner.lavae[rand].SummonShard then
                                    owner.lavae[rand]:SummonShard()
                                end
                                return true
                            else
                                -- 递归尝试其他位置
                                return TryAddCrystal()
                            end
                        end
                        
                        TryAddCrystal()
                        inst.armormeleehits = 0
                    end
                end
            end
            
            inst:DoTaskInTime(0.1, function()
                if owner.lavae then
                    -- 移除原有的监听器并添加我们的
                    for i, func in ipairs(owner.event_listeners["onattackother"][owner] or {}) do
                        owner:RemoveEventCallback("onattackother", func)
                    end
                    owner:ListenForEvent("onattackother", UpdateGlass2hm)
                    inst.updateGlass_2hm = UpdateGlass2hm
                end
            end)
        end)
        
        -- 卸下时清理
        local original_onunequip = inst.components.equippable.onunequipfn
        inst.components.equippable:SetOnUnequip(function(inst, owner)
            if inst.updateGlass_2hm then
                owner:RemoveEventCallback("onattackother", inst.updateGlass_2hm)
                inst.updateGlass_2hm = nil
            end
            if original_onunequip then
                original_onunequip(inst, owner)
            end
        end)
    end
end)

-- =========================================================================================================================
-- wathom亮茄杖骑乘禁用
-- 原版伤害函数
local function original_onattack(inst, attacker, target, skipsanity)
    if inst.skin_sound then attacker.SoundEmitter:PlaySound(inst.skin_sound) end
    if not target:IsValid() then return end
    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end
    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end
    target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
end

local function addwathom_staff_lunarplant(inst)
    if inst.components.weapon and inst.components.weapon.onattack then 
        local _onattack = inst.components.weapon.onattack 
        local function OnAttack(inst, attacker, target, skipsanity)
            if attacker.components.rider and attacker.components.rider:IsRiding() then
                inst.components.weapon:SetProjectile("brilliance_projectile_fx")
                return original_onattack(inst, attacker, target, skipsanity)
            end
            return _onattack(inst, attacker, target, skipsanity)
        end
        inst.components.weapon:SetOnAttack(OnAttack)
    end
end

AddPrefabPostInit("staff_lunarplant", function(inst)
    if not TheWorld.ismastersim then return end
    addwathom_staff_lunarplant(inst) 
    if inst.components.forgerepairable then
        local _onrepaired = inst.components.forgerepairable.onrepaired
        inst.components.forgerepairable.onrepaired = function(inst, ...)
            _onrepaired(inst, ...)
            addwathom_staff_lunarplant(inst)
        end
    end
end)

-- ==========================================================================================================================
-- 修复武神装备与技能树相关的方法丢失
--  "attempt to call method 'RemoveSkillsChanges' (a nil value)" 
local function AddRemoveSkillsChangesMethod(prefab)
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then return end
        
        if inst.RemoveSkillsChanges then return end
        
        -- 这是一个兼容性方法，防止模组调用时出现nil错误
        inst.RemoveSkillsChanges = function(inst, owner) end
        
        -- 同时添加ApplySkillsChanges方法以保持完整性
        if not inst.ApplySkillsChanges then
            inst.ApplySkillsChanges = function(inst, owner) end
        end
    end)
end

local compatible_prefabs = {
    "spear_wathgrithr",
    "spear_wathgrithr_lightning", 
    "spear_wathgrithr_lightning_charged",
    "battlehelm",
    "wathgrithr_improvedhat",
}

for _, prefab in ipairs(compatible_prefabs) do
    AddRemoveSkillsChangesMethod(prefab)
end

-- ==========================================================================================================================
-- 修复融合发条电炮对无效目标攻击时的崩溃问题
-- 修复workshop-2039181790模组中roship.lua:57的"attempt to perform arithmetic on local 'a' (a nil value)"错误
AddPrefabPostInit("roship", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0.1, function()
        if inst.DoSnowballBelch then
            local original_DoSnowballBelch = inst.DoSnowballBelch
            inst.DoSnowballBelch = function(inst)
                -- 检查目标是否有效
                if inst.components.combat and inst.components.combat.target then
                    local target = inst.components.combat.target
                    if target and target:IsValid() and target.Transform then
                        local success, a, b, c = pcall(target.Transform.GetWorldPosition, target.Transform)
                        if success and a and b and c then
                            return original_DoSnowballBelch(inst)
                        end
                    end
                end
            end
        end
    end)
end)

-- ==========================================================================================================================
-- 移除刮地皮头盔的无限堆叠
AddPrefabPostInit("antlionhat", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0.1, function()
        if inst.components.container then
            inst.components.container:EnableInfiniteStackSize(false)
        end
    end)
end)

-- ==========================================================================================================================
-- 修复妥协模组睡觉时食物buff对血量恢复停止的问题，睡觉时buff回血会判断invisible状态而回理智不会
AddComponentPostInit("debuff", function(self)
    local old_AttachTo = self.AttachTo
    
    self.AttachTo = function(self, name, target, followsymbol, followoffset, data, buffer)
        -- 只处理血量buff
        if self.inst.prefab == "healthregenbuff_vetcurse" or 
           self.inst.prefab == "healthregenbuff_vetcurse_walter_curse" then
            self.keepondespawn = true
            
            old_AttachTo(self, name, target, followsymbol, followoffset, data, buffer)
            
            if self.inst.task then
                self.inst.task:Cancel()
                
                local duration = data ~= nil and data.duration and (data.duration / 2) or 1
                local warlybuff = (target:HasTag("warlybuffed") and (target:HasTag("vetcurse") and 1.8 or 2)) or target:HasTag("vetcurse") and 0.8 or 1
                duration = duration / warlybuff
                duration = math.floor(duration / FRAMES) * FRAMES
                
                -- 修复后的OnTick - 添加ignore_invincible参数
                self.inst.task = self.inst:DoPeriodicTask(data ~= nil and duration or 1, function(inst, target, data)
                    local tick_duration, maxhp_percent
                    if data ~= nil then
                        tick_duration = data.duration or 1
                        tick_duration = math.floor(tick_duration / FRAMES) * FRAMES
                        maxhp_percent = type(data.maxhp_percent) == "number" and data.maxhp_percent or 0
                    end
                    
                    if target.components.health ~= nil and
                        not target.components.health:IsDead() and
                        not target:HasTag("playerghost") then
                        if data ~= nil and data.negative_value ~= nil and data.negative_value then
                            if maxhp_percent ~= nil then
                                target.components.health:DeltaPenalty(maxhp_percent)
                            end
                            -- 第4个参数ignore_invincible设为true
                            target.components.health:DoDelta(data ~= nil and -tick_duration or -1, nil, inst.prefab, true)
                        else
                            if maxhp_percent ~= nil then
                                target.components.health:DeltaPenalty(-maxhp_percent)
                            end
                            -- 第4个参数ignore_invincible设为true
                            target.components.health:DoDelta(data ~= nil and tick_duration or 1, nil, inst.prefab, true)
                        end
                    else
                        inst.components.debuff:Stop()
                    end
                end, nil, target, data)
            end
        else
            old_AttachTo(self, name, target, followsymbol, followoffset, data, buffer)
        end
    end
end)

-- ==========================================================================================================================
-- 妥协8格电路槽会遮挡状态栏，需要下移
if TUNING.DSTU and TUNING.DSTU.WXLESS then
    AddClassPostConstruct("widgets/upgrademodulesdisplay", function(self)

        if self.battery_frame then
            self.battery_frame:SetPosition(0, 10)   -- 原为（0, 22)
        end
    end)
end

-- ==========================================================================================================================
-- 修复远古守护者跳跃落地时额外造成1次伤害的问题
AddStategraphPostInit("minotaur", function(sg)
    if sg.states and sg.states.leap_attack and sg.states.leap_attack.events and sg.states.leap_attack.events.animover then
        sg.states.leap_attack.events.animover.fn = function(inst)
            inst.forceleap = false
            -- inst.components.groundpounder:GroundPound()
            -- BounceStuff(inst)
            
            local x, y, z = inst.Transform:GetWorldPosition()
            if inst.components.combat and inst.components.combat.target and 
               ((inst.combo < math.random(2, 3) and (inst.components.health:GetPercent() > 0.3 and inst.components.health:GetPercent() < 0.6)) or 
                (inst.combo < math.random(4, 5) and inst.components.health:GetPercent() < 0.3)) then
                inst.sg:GoToState("leap_attack_pre_quick", inst.components.combat.target)
                inst.SoundEmitter:PlaySound("ancientguardian_rework/minotaur2/groundpound")
                inst.combo = inst.combo + 1
            else
                inst.components.groundpounder.numRings = 2
                inst.combo = 0
                
                local function RestartTimer(inst, name, time)
                    if inst.components.timer:TimerExists(name) then
                        inst.components.timer:SetTimeLeft(name, time)
                    else
                        inst.components.timer:StartTimer(name, time)
                    end
                end
                
                RestartTimer(inst, "forceleapattack", 30 + math.random(0, 15))
                
                if inst.jumpland and inst:jumpland() then
                    inst.sg:GoToState("leap_attack_pst")
                    inst.SoundEmitter:PlaySound("ancientguardian_rework/minotaur2/groundpound")
                elseif inst.components.health and inst.components.health:GetPercent() < 0.6 then
                    inst.sg:GoToState("stun", {land_stun = true})
                    return
                else
                    inst.sg:GoToState("leap_attack_pst")
                    return
                end
            end
        end
    end
end)

-- ==========================================================================================================================
-- 修复妥协背包在库存内时可以被放入物品的问题
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    
    if inst:HasTag("backpack") and inst.components.container and inst.components.inventoryitem then
        local old_GiveItem = inst.components.container.GiveItem
        
        inst.components.container.GiveItem = function(self, item, slot, src_pos, drop_on_fail)

            if inst.components.inventoryitem.owner then
                local owner = inst.components.inventoryitem.owner
                
                if owner.components.container then
                    return false
                end
                
                if owner.components.inventory then
                    local is_equipped = false
                    if owner.components.inventory.equipslots then
                        for k, v in pairs(owner.components.inventory.equipslots) do
                            if v == inst then
                                is_equipped = true
                                break
                            end
                        end
                    end
                    
                    if not is_equipped then
                        return false
                    end
                end
            end

            return old_GiveItem(self, item, slot, src_pos, drop_on_fail)
        end
    end
end)

-- ==========================================================================================================================
-- 移除诅咒装备vetcurse标签限制
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()
        if inst:HasTag("vetcurse_item") and inst.components.equippable then
            local original_onequip = inst.components.equippable.onequipfn
            
            if original_onequip then
                inst.components.equippable:SetOnEquip(function(inst, owner)
                    local had_vetcurse = owner:HasTag("vetcurse")
                    if not had_vetcurse then
                        owner:AddTag("vetcurse")
                    end

                    original_onequip(inst, owner)

                    if not had_vetcurse then
                        owner:RemoveTag("vetcurse")
                    end
                end)
            end
        end
    end)
end)

-- ==========================================================================================================================
-- 削弱蜘蛛和沃利谋杀的额外掉落
local spider_extra_loots = {
    spider_warrior = "monstermeat",
    spider_dropper = "silk",
    spider_moon = "moonglass",
    spider_healer = "spidergland",
}

for prefab, extra_loot in pairs(spider_extra_loots) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then return end
        
        inst:DoTaskInTime(0, function()
            if inst.components.lootdropper then
                local old_GenerateLoot = inst.components.lootdropper.GenerateLoot
                inst.components.lootdropper.GenerateLoot = function(self, ...)
                    local loots = old_GenerateLoot(self, ...)
                    
                    -- 50%概率移除额外的特殊掉落
                    if math.random() < 0.5 then
                        for i = #loots, 1, -1 do
                            if loots[i] == extra_loot then
                                table.remove(loots, i)
                                break
                            end
                        end
                    end
                    
                    return loots
                end
            end
        end)
    end)
end

if TUNING.DSTU.WARLY_BUTCHER then
    local old_murder_fn = ACTIONS.MURDER.fn
    ACTIONS.MURDER.fn = function(act, ...)
        local murdered = act.invobject or act.target
        local is_warly = murdered ~= nil and act.doer ~= nil and act.doer:HasTag("masterchef")
        local should_double = is_warly and math.random() <= 0.5

        if is_warly and not should_double then
            act.doer:RemoveTag("masterchef")
            local result = old_murder_fn(act, ...)
            act.doer:AddTag("masterchef")
            return result
        end

        local result = old_murder_fn(act, ...)
        
        -- 成功翻倍时特殊台词
        if result and should_double and act.doer.components.talker then
            act.doer.components.talker:Say(TUNING.isCh2hm and "双倍美味！" or "Double the flavor!")
        end
        
        return result
    end
end

-- ==========================================================================================================================
-- 诅咒鹿角兼容
AddPrefabPostInit("cursed_antler", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()
        if inst.components.weapon and inst.components.weapon.onattack then
            local original_onattack = inst.components.weapon.onattack
            
            inst.components.weapon:SetOnAttack(function(inst, attacker, target)
                if target and target:IsValid() and attacker and attacker:IsValid() then
                    -- 临时添加标签
                    local had_vetcurse = attacker:HasTag("vetcurse")
                    if not had_vetcurse then
                        attacker:AddTag("vetcurse")
                    end
                    
                    original_onattack(inst, attacker, target)
    
                    if not had_vetcurse then
                        attacker:RemoveTag("vetcurse")
                    end
                else
                    original_onattack(inst, attacker, target)
                end
            end)
        end
    end)
end)

-- ==========================================================================================================================
-- 手持蜂巢兼容
local function patch_beegun_vetcurse(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()
        if inst.components.spellcaster and inst.components.spellcaster.can_cast_fn then
            local original_can_cast = inst.components.spellcaster.can_cast_fn
            
            inst.components.spellcaster:SetCanCastFn(function(doer, target, pos)
                local had_vetcurse = doer:HasTag("vetcurse")
                if not had_vetcurse then
                    doer:AddTag("vetcurse")
                end
                
                local result = original_can_cast(doer, target, pos)
                
                if not had_vetcurse then
                    doer:RemoveTag("vetcurse")
                end
                
                return result
            end)
        end
        
        if inst.components.weapon and inst.components.weapon.onattack then
            local original_onattack = inst.components.weapon.onattack
            
            inst.components.weapon:SetOnAttack(function(inst, attacker, target)
                if attacker then
                    local had_vetcurse = attacker:HasTag("vetcurse")
                    if not had_vetcurse then
                        attacker:AddTag("vetcurse")
                    end
                    
                    original_onattack(inst, attacker, target)
                    
                    if not had_vetcurse then
                        attacker:RemoveTag("vetcurse")
                    end
                else
                    original_onattack(inst, attacker, target)
                end
            end)
        end
    end)
end

AddPrefabPostInit("um_beegun", patch_beegun_vetcurse)
AddPrefabPostInit("um_beegun_cherry", patch_beegun_vetcurse)

-- ==============================================================================================================================
-- 妥协月光龙蝇，修改旋转岩浆虫的伤害来源为boss本身
if TUNING.DSTU then
    AddPrefabPostInit("moonmaw_lavae_ring", function(inst)
        if not TheWorld.ismastersim then return end
        
        inst:DoTaskInTime(0, function()
            if not inst:IsValid() then return end

            local TARGET_IGNORE_TAGS = { "INLIMBO", "moonglasscreature" }
            
            local function destroystuff_patched(inst)
                if inst.WINDSTAFF_CASTER == nil then
                    inst:Remove()
                    return
                end
                
                if inst.destroy and inst.hidden ~= true then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local ents = TheSim:FindEntities(x, y, z, 2, nil, TARGET_IGNORE_TAGS, { "_health" })
                    
                    for i, v in ipairs(ents) do
                        if v ~= inst.WINDSTAFF_CASTER and v:IsValid() then
                            if v.components.health ~= nil and
                                not v.components.health:IsDead() and
                                v.components.combat ~= nil and
                                v.components.combat:CanBeAttacked() then
                                
                                local damage = 40
                                -- 伤害来源改为boss（WINDSTAFF_CASTER）而不是岩浆虫自己
                                v.components.combat:GetAttacked(inst.WINDSTAFF_CASTER, damage, nil, "glass")

                                if v:HasTag("player") and not (v.components.rider ~= nil and v.components.rider:IsRiding()) then
                                    if v.moonmaw_lavae_stun == nil then
                                        v.moonmaw_lavae_stun = 0
                                    end
                                    v.moonmaw_lavae_stun = v.moonmaw_lavae_stun + 1
                                    if v.moonmaw_lavae_stun > 4 then
                                        if v.sg:HasStateTag("wixiepanic") then
                                            v.sg:GoToState("idle")
                                        end

                                        v:PushEvent("knockback", { knocker = inst.WINDSTAFF_CASTER, radius = 1, strengthmult = 1 })
                                        v:DoTaskInTime(1.5, function(v) v.moonmaw_lavae_stun = 0 end)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if inst._destroystuff_task then
                inst._destroystuff_task:Cancel()
            end
            inst:DoTaskInTime(1, function(inst)
                inst._destroystuff_task = inst:DoPeriodicTask(.15, destroystuff_patched)
            end)
        end)
    end)
end