--   沃拓克斯技能树优化   --

local SkillTreeDefs = require("prefabs/skilltree_defs")

if SkillTreeDefs.SKILLTREE_DEFS["wortox"] ~= nil then  

    local wortox_skill = SkillTreeDefs.SKILLTREE_DEFS["wortox"]

    -- 技能树文本改动
    wortox_skill.wortox_souljar_1.desc = 
        (TUNING.isCh2hm and "学习如何制作和使用灵魂罐来储存灵魂以供之后使用。\n没有带在身上的灵魂罐不再随着时间的推移泄漏灵魂。" or
        "Learn how to craft and use Soul Jars to store souls for later use.\nSoul Jars not carried on your person no longer leak souls over time.")
    wortox_skill.wortox_inclination_nice.desc = 
        (TUNING.isCh2hm and "你的善良让你的怪物本性不再惹是生非。\n释放灵魂会大幅影响理智值。\n吞噬灵魂获取的饱食度减半。" or
        "Your kindness prevents your monster nature from causing trouble.\nReleasing souls will greatly affect sanity.\nEating souls will only restore half of the hunger.")
    wortox_skill.wortox_inclination_naughty.desc =
        (TUNING.isCh2hm and "你的贪婪暂时阻止了灵魂能量的过载。\n吞噬和释放灵魂灵魂不会再影响理智。\n持有灵魂使你的身心愉悦。" or
        "Your greed temporarily prevents soul energy overload.\nEating souls will no longer affect sanity.\nHolding souls makes you feel good.")
    wortox_skill.wortox_inclination_meter.desc = 
        (TUNING.isCh2hm and "技能都将被你收入囊中，自行选择一个倾向吧。\n点亮其中一个后另一个会被撤销。" or
        "You will mastere all skills, now choose your inclination.")   
    wortox_skill.wortox_thief_3.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_THIEF_3_DESC ..
        (TUNING.isCh2hm and "你投掷的灵魂现在能伤害沿途的目标。\n丢出去的灵魂命中后不会消失，且有60%的概率可以被回收。" or
        "The souls you throw can now damage targets along the way and will not disappear on hit.\nThrown souls have a 60% chance to be recoverable.")
    wortox_skill.wortox_thief_4.desc = 
        (TUNING.isCh2hm and "被你吸引过来和投掷出去的灵魂命中后会先反飞，然后再飞向你。" or
        "Souls attracted to you and you throw will first fly away on hit, then fly back to you.")

    local nice = wortox_skill.wortox_inclination_nice
    local naughty = wortox_skill.wortox_inclination_naughty
    local meter = wortox_skill.wortox_inclination_meter
    
    -- 找到最大的 RPC ID
    local max_rpc_id = 0
    for skill_name, skill_data in pairs(wortox_skill) do
        if skill_data.rpc_id and skill_data.rpc_id > max_rpc_id then
            max_rpc_id = skill_data.rpc_id
        end
    end
    
    -- 禁用天平动画
    if meter then meter.button_decorations = nil end
    -- 好孩子技能改动
    if nice then
        nice.group = "nice"
        nice.tags = {}              
        nice.infographic = false    
        nice.lock_open = nil        
        nice.root = true         
        nice.forced_focus = nil     
        -- 手动分配 RPC ID
        nice.rpc_id = max_rpc_id + 1
        -- 添加到 RPC 查找表
        if SkillTreeDefs.SKILLTREE_METAINFO["wortox"] and SkillTreeDefs.SKILLTREE_METAINFO["wortox"].RPC_LOOKUP then
            SkillTreeDefs.SKILLTREE_METAINFO["wortox"].RPC_LOOKUP[nice.rpc_id] = "wortox_inclination_nice"
        end
        
        nice.onactivate = function(inst)
            inst.wortox_inclination = "nice"
            -- 移除怪物标签
            inst:RemoveTag("monster")
            inst:RemoveTag("playermonster")
            if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wortox_inclination_naughty") then
                -- 遗忘互斥的倾向技能
                inst.components.skilltreeupdater:DeactivateSkill("wortox_inclination_naughty")
            end
        end
        nice.ondeactivate = function(inst)
            inst.wortox_inclination = nil
            -- 重新添加怪物标签
            inst:AddTag("monster")
            inst:AddTag("playermonster")
        end
    end
    -- 淘气包技能改动
    if naughty then
        naughty.group = "naughty"
        naughty.tags = {}  
        naughty.infographic = false  
        naughty.lock_open = nil 
        naughty.root = true  
        naughty.forced_focus = nil 
        naughty.rpc_id = max_rpc_id + 2
        if SkillTreeDefs.SKILLTREE_METAINFO["wortox"] and SkillTreeDefs.SKILLTREE_METAINFO["wortox"].RPC_LOOKUP then
            SkillTreeDefs.SKILLTREE_METAINFO["wortox"].RPC_LOOKUP[naughty.rpc_id] = "wortox_inclination_naughty"
        end
        
        naughty.onactivate = function(inst)
            inst.wortox_inclination = "naughty"
            
            if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wortox_inclination_nice") then
                inst.components.skilltreeupdater:DeactivateSkill("wortox_inclination_nice")
            end
        end
        naughty.ondeactivate = function(inst)
            inst.wortox_inclination = nil
        end
    end
    
    -- 更新技能计数
    if SkillTreeDefs.SKILLTREE_METAINFO["wortox"] then
        SkillTreeDefs.SKILLTREE_METAINFO["wortox"].TOTAL_SKILLS_COUNT = max_rpc_id + 2
    end
    
end

-- 禁用原版倾向计算系统
AddPrefabPostInit("wortox", function(inst)
    if not TheWorld.ismastersim then return end

    if SkillTreeDefs.CUSTOM_FUNCTIONS and SkillTreeDefs.CUSTOM_FUNCTIONS.wortox then
        local original_CalculateInclination = SkillTreeDefs.CUSTOM_FUNCTIONS.wortox.CalculateInclination
        SkillTreeDefs.CUSTOM_FUNCTIONS.wortox.CalculateInclination = function(nice, naughty, affinitytype)
            -- 如果独立技能已激活，则忽略原版计算
            if inst.components.skilltreeupdater then
                if inst.components.skilltreeupdater:IsActivated("wortox_inclination_nice") then
                    return "nice"
                elseif inst.components.skilltreeupdater:IsActivated("wortox_inclination_naughty") then
                    return "naughty"
                end
            end

            return nil
        end
    end

    -- 禁用原版逻辑，倾向状态由独立技能管理
    local old_RecalculateInclination = inst.RecalculateInclination
    inst.RecalculateInclination = function(inst) 
        local skilltreeupdater = inst.components.skilltreeupdater
        if skilltreeupdater then
            -- 检查独立技能状态并同步倾向变量
            if skilltreeupdater:IsActivated("wortox_inclination_nice") then
                inst.wortox_inclination = "nice"
            elseif skilltreeupdater:IsActivated("wortox_inclination_naughty") then
                inst.wortox_inclination = "naughty"
            else
                inst.wortox_inclination = nil
            end
        end
        
        inst:PushEvent("wortox_inclination_changed", {inclination = inst.wortox_inclination})
    end

end)

AddPrefabPostInit("wortox", function(inst)
    if not TheWorld.ismastersim then return end
    
    if not inst.components.souleater then inst:AddComponent("souleater") end
    -- 吞噬灵魂理智惩罚减少 
    local oneat_soul_2hm = inst.components.souleater.oneatsoulfn
    if oneat_soul_2hm then
        local function OnEatSoul(inst, soul)
            oneat_soul_2hm(inst, soul)
            if inst.wortox_inclination == "nice" then
                inst.components.sanity:DoDelta(TUNING.SANITY_TINY) -- 原函数会扣去2份，这里返还1份，等于无技能点的1份
            end
        end
        inst.components.souleater:SetOnEatSoulFn(OnEatSoul)
    end

    -- 吞噬灵魂回复饱食度减少
    local oneat_soul_2hm = inst.components.souleater and inst.components.souleater.oneatsoulfn
    if oneat_soul_2hm then
        local function OnEatSoul(inst, soul)
            oneat_soul_2hm(inst, soul)
            if inst.wortox_inclination == "nice" then
                inst.components.hunger:DoDelta(-TUNING.CALORIES_MED * 0.5) -- 减少一半回复
            end
        end
        inst.components.souleater:SetOnEatSoulFn(OnEatSoul)
    end
end)
TUNING.NAUGHTY_SOULHEAL_RECEIVED_MULT = 1 -- 0.75→1 释放灵魂不再回复更少生命

-- 每有一个灵魂增加理智回复，上限15个，26.7/天
local function soul_count(inst) 
    if not inst.components.inventory then return false end
    local searchingenv = inst.components.inventory:FindItems(function(item) return item:IsValid() 
        and (item.prefab == "wortox_soul" or item.prefab == "wortox_souljar") end)
    local count = 0
    for i, v in pairs(searchingenv) do
        if v.prefab == "wortox_soul" then 
            count = count + (v.components.stackable ~= nil and v.components.stackable:StackSize() or 1) 
        elseif v.prefab == "wortox_souljar" then 
            count = count + (v.soulcount or 0)
        end
    end
    return count 
end

local function UpdateSoulSanityGain(inst)  
    inst._soul_sanity_gain = 0
    if inst.wortox_inclination ~= "naughty" then return end
    local soul_count = soul_count(inst) or 0
    soul_count = math.min(soul_count, 15)   
    inst._soul_sanity_gain = soul_count * (TUNING.DAPPERNESS_MED / 15)
end

AddPrefabPostInit("wortox", function(inst)
    if not TheWorld.ismastersim then return end
    
    local old_custom_rate_fn = inst.components.sanity.custom_rate_fn
    inst.components.sanity.custom_rate_fn = function(inst, dt)
        local base_rate = old_custom_rate_fn and old_custom_rate_fn(inst, dt) or 0
        return base_rate + inst._soul_sanity_gain
    end
    
    inst._update_soul_sanity_task = inst:DoPeriodicTask(1, UpdateSoulSanityGain)
    
    inst:ListenForEvent("itemget", function(inst, data)
        if data and data.item and data.item.prefab == "wortox_soul" then
            UpdateSoulSanityGain(inst)
        end
    end)
    
    inst:ListenForEvent("itemlose", function(inst, data)
        if data and data.prev_item and data.prev_item.prefab == "wortox_soul" then
            UpdateSoulSanityGain(inst)
        end
    end)
    
    inst:ListenForEvent("unlockskill", function(inst, data)
        UpdateSoulSanityGain(inst)
    end)

    inst:DoTaskInTime(0, UpdateSoulSanityGain)
end)

-- 灵魂罐灵魂不泄漏
AddPrefabPostInit("wortox_souljar", function(inst)
    if not TheWorld.ismastersim then return end

    local old_UpdatePercent = inst.UpdatePercent
    inst.UpdatePercent = function(self, ...)

        if self.leaksoulstask then
            self.leaksoulstask:Cancel()
            self.leaksoulstask = nil
        end

        old_UpdatePercent(self, ...)

        if self.leaksoulstask then
            self.leaksoulstask:Cancel()
            self.leaksoulstask = nil
        end
    end

    -- 禁用泄漏条件判断
    local old_LeakSouls = inst.LeakSouls
    inst.LeakSouls = function() end 

    -- 打开罐子时不再结束回响
    if inst.components.container and inst.components.container.onopenfn then
        inst.components.container.onopenfn = function(inst)
            inst.components.inventoryitem:ChangeImageName("wortox_souljar_open")
            if not inst.components.inventoryitem:IsHeld() then
                inst.AnimState:PlayAnimation("lidoff")
                inst.AnimState:PushAnimation("lidoff_idle")
                inst.SoundEmitter:PlaySound("meta5/wortox/souljar_open")
                inst:UpdatePercent()
            else
                inst.AnimState:PlayAnimation("lidoff_idle")
            end
        end
    end
end)

-- ===================================================
-- 灵魂投射武器系统
local wortox_soul_common = require("prefabs/wortox_soul_common")
local SCALE = .8
local SOUL_SPEAR_TICK_TIME = 0.1

-- 创建灵魂尾迹特效
local function CreateTail()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)
    inst.Physics:ClearCollisionMask()

    inst.AnimState:SetBank("wortox_soul_ball")
    inst.AnimState:SetBuild("wortox_soul_ball")
    inst.AnimState:PlayAnimation("disappear")
    inst.AnimState:SetScale(SCALE, SCALE)
    inst.AnimState:SetFinalOffset(3)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

-- 尾迹更新函数
local function OnUpdateProjectileTail(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for tail, _ in pairs(inst._tails) do tail:ForceFacePoint(x, y, z) end
    if inst.entity:IsVisible() then
        local tail = CreateTail()
        local rot = inst.Transform:GetRotation()
        tail.Transform:SetRotation(rot)
        rot = rot * DEGREES
        local offsangle = math.random() * TWOPI
        local offsradius = (math.random() * .2 + .2) * SCALE
        local hoffset = math.cos(offsangle) * offsradius
        local voffset = math.sin(offsangle) * offsradius
        tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
        local speed = TUNING.WORTOX_SOUL_PROJECTILE_SPEED or 10
        tail.Physics:SetMotorVel(speed * (.2 + math.random() * .3), 0, 0)
        inst._tails[tail] = true
        inst:ListenForEvent("onremove", function(tail) inst._tails[tail] = nil end, tail)
        tail:ListenForEvent("onremove", function(inst)
            tail.Transform:SetRotation(tail.Transform:GetRotation() + math.random() * 30 - 15)
        end, inst)
    end
end

-- 尾迹效果
local function OnHasTailDirty(inst)
    if inst._hastail:value() and inst._tails == nil then
        inst._tails = {}
        if inst.components.updatelooper == nil then
            inst:AddComponent("updatelooper")
        end
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateProjectileTail)
    end
end

-- 移除实体时清理尾迹
local function OnTargetDirty(inst)
    if inst._target:value() ~= nil and inst._tinttarget == nil then
        if inst.components.updatelooper == nil then
            inst:AddComponent("updatelooper")
        end
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateTargetTint)
        inst._tinttarget = inst._target:value()
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

local function Setup(inst, target)
    inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
    inst._target:set(target)
    if not TheNet:IsDedicated() then
        OnTargetDirty(inst)
    end
end

local function OnThrownTimeout(inst)
    if inst._timeouttask ~= nil then
        inst._timeouttask:Cancel()
        inst._timeouttask = nil
    end
    
    if inst:IsValid() and inst.components.projectile then
        inst.components.projectile:Stop()
        inst:Remove()
    end
end

local function OnMiss(inst, attacker, target)
    if inst._timeouttask ~= nil then
        inst._timeouttask:Cancel()
        inst._timeouttask = nil
    end
    
    if inst:IsValid() then
        inst:Remove()
    end
end

local function OnThrown(inst, owner, target, attacker)
    if inst._timeouttask ~= nil then
        inst._timeouttask:Cancel()
        inst._timeouttask = nil
    end
    
    local duration = TUNING.WORTOX_SOUL_PROJECTILE_LIFETIME or 6
    if target and target.components.skilltreeupdater and target.components.skilltreeupdater:IsActivated("wortox_thief_2") then
        duration = duration + TUNING.SKILLS.WORTOX.SOUL_PROJECTILE_LIFETIME_BONUS
    end
    inst._timeouttask = inst:DoTaskInTime(duration, OnThrownTimeout)
    
    inst._original_owner = owner
    
    inst.AnimState:Hide("blob")
    inst._hastail:set(true)
    if not TheNet:IsDedicated() then
        OnHasTailDirty(inst)
    end
    
end

-- 命中消失，点亮穿刺可生成普通灵魂，但收回时概率自动释放而不进库存
local function OnHit(inst, attacker, target)

    if target ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local fx = SpawnPrefab("wortox_soul_in_fx")
        fx.Transform:SetPosition(x, y, z)
        fx:Setup(target)
        
        local owner = inst._original_owner
        if owner and owner:IsValid() and owner.components.skilltreeupdater and 
            owner.components.skilltreeupdater:IsActivated("wortox_thief_3") then
            -- 生成一个新的普通灵魂
            local soul_spawn = SpawnPrefab("wortox_soul_spawn")
            if soul_spawn then
                soul_spawn.Transform:SetPosition(x, y, z)
                soul_spawn._soulsource = owner
                soul_spawn._is_from_weapon = true 
            end
        else 
            fx = SpawnPrefab("wortox_soul")
            fx.Transform:SetPosition(x, y, z)
            fx.components.inventoryitem:OnDropped(true) 
        end  
    end
    inst:Remove()
end

local function GetSoulWeaponDamage(inst, attacker, target)
    if attacker and attacker.components.skilltreeupdater and attacker.components.skilltreeupdater:IsActivated("wortox_thief_3") then

        local damage = TUNING.SKILLS.WORTOX.SOUL_SPEAR_DAMAGE
        if attacker.components.skilltreeupdater:IsActivated("wortox_souljar_3") then
            local souls_max = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_MAX_SOULS    -- 100
            local damage_percent = math.min(attacker.soulcount or 0, souls_max) / souls_max
            local bonus_mult = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_SOULS_BONUS_MULT  -- 1.25
            damage = damage * (1 + (bonus_mult - 1) * damage_percent)
        end
        
        return damage
    end
    
    -- 无技能时基础伤害51
    return TUNING.SKILLS.WORTOX.SOUL_SPEAR_DAMAGE * 2 
end

-- 改装灵魂为投射武器
AddPrefabPostInit("wortox_soul", function(inst)
    if not inst._hastail then
        inst._hastail = net_bool(inst.GUID, "wortox_soul._hastail", "hastaildirty")
        if not TheWorld.ismastersim then 
            inst:ListenForEvent("hastaildirty", OnHasTailDirty) 
        end
    end
    if not inst._target then
        inst._target = net_entity(inst.GUID, "wortox_soul._target", "targetdirty")
        if not TheWorld.ismastersim then
            inst:ListenForEvent("targetdirty", OnTargetDirty)
        end
    end
    if not TheWorld.ismastersim then return end
    
    if not inst.components.weapon and not inst.components.projectile then

        inst:AddTag("weapon")
        inst:AddTag("rangedweapon")
        inst:AddTag("projectile")
        

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(GetSoulWeaponDamage)
        inst.components.weapon:SetRange(8, 25)              
        inst.components.weapon:SetProjectile("wortox_soul") 
        
        inst:AddComponent("projectile")
        inst.components.projectile:SetRange(25)
        inst.components.projectile:SetSpeed(20)
        inst.components.projectile:SetHitDist(0.5)
        inst.components.projectile:SetHoming(true)
        inst.components.projectile:SetOnThrownFn(OnThrown)
        inst.components.projectile:SetOnHitFn(OnHit)
        inst.components.projectile:SetOnMissFn(OnMiss)
        
        inst:AddComponent("equippable")
        inst.components.equippable.equipstack = true
        inst.components.equippable.restrictedtag = "souleater"
        
        inst.SoulSpearTick = SoulSpearTick
        
        local old_Remove = inst.Remove
        inst.Remove = function(inst)
            if inst._tails then
                for tail, _ in pairs(inst._tails) do
                    if tail and tail:IsValid() then
                        tail:Remove()
                    end
                end
                inst._tails = nil
            end
            old_Remove(inst)
        end
    end
end)

-- 投射的灵魂75%几率回收，并检查目标是否能接收灵魂
AddPrefabPostInit("wortox_soul_spawn", function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.projectile then

        local _OnHit = inst.components.projectile.onhitfn
        
        inst.components.projectile:SetOnHitFn(function(inst, attacker, target)

            if target ~= nil then
                local x, y, z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("wortox_soul_in_fx")
                fx.Transform:SetPosition(x, y, z)
                fx:Setup(target)
                
                -- 检查目标是否有资格接收灵魂
                local can_receive_soul = target:HasTag("souleater") or target.medal_soulstealer
                
                if target.components.inventory ~= nil and target.components.inventory.isopen then
                    -- 投射武器的灵魂有25%概率直接掉落
                    if inst._is_from_weapon and math.random() > 0.75 then
                        local soul = SpawnPrefab("wortox_soul")
                        soul.Transform:SetPosition(x, y, z)
                        soul.components.inventoryitem:OnDropped(true)
                    -- 目标有资格接收灵魂
                    elseif can_receive_soul then
                        target.components.inventory:GiveItem(SpawnPrefab("wortox_soul"), nil, target:GetPosition())
                    -- 目标没资格，灵魂掉落
                    else
                        local soul = SpawnPrefab("wortox_soul")
                        soul.Transform:SetPosition(x, y, z)
                        soul.components.inventoryitem:OnDropped(true)
                    end
                else
                    -- 背包未打开，灵魂掉落
                    local soul = SpawnPrefab("wortox_soul")
                    soul.Transform:SetPosition(x, y, z)
                    soul.components.inventoryitem:OnDropped(true)
                end
            end
            inst:Remove()
        end)
    end
end)

-- ===================================================
-- 非恶魔角色不能携带灵魂
AddComponentPostInit("inventory", function(self)
    local old_GiveItem = self.GiveItem
    self.GiveItem = function(self, item, slot, src_pos, ...)
        if item and item.prefab == "wortox_soul" then
            if not self.inst:HasTag("souleater") and not self.inst.medal_soulstealer then
                item:Remove()
                return nil
            end
        end

        return old_GiveItem(self, item, slot, src_pos, ...)
    end
end)