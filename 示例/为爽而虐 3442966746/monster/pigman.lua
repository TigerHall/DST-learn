local speedup = GetModConfigData("extra_change") and GetModConfigData("boss_speed") or 1

-- 浣猫优化
if TUNING.DSTU and TUNING.DSTU.MONSTER_CATCOON_HEALTH_CHANGE then 
    AddPrefabPostInit("catcoon", function(inst)
        inst.Transform:SetScale(1.3, 1.3, 1.3) 
    end) 
end

TUNING.PIG_HEALTH = TUNING.PIG_HEALTH * 2
TUNING.BUNNYMAN_HEALTH = TUNING.BUNNYMAN_HEALTH * 2

-- 猪人增强（黄金交易特殊逻辑，武器装备已在文件末尾统一处理）
AddPrefabPostInit("pigman", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.trader then
        local onaccept = inst.components.trader.onaccept
        inst.components.trader.onaccept = function(inst, giver, item, ...)
            if onaccept then onaccept(inst, giver, item, ...) end
            -- 猪人特殊逻辑：黄金交易（每天一次）
            if item and item:IsValid() and (inst.goldtradecycle2hm or -1) < TheWorld.state.cycles and item.components.tradable and
                item.components.tradable.goldvalue > 0 then
                inst.goldtradecycle2hm = TheWorld.state.cycles
                for k = 1, item.components.tradable.goldvalue do
                    giver.components.inventory:GiveItem(SpawnPrefab("goldnugget"), nil, inst:GetPosition())
                end
            end
        end
    end
end)
local pigs = {"pigman", "pigguard", "moonpig"}
local function IsNonWerePig(dude) return dude:HasTag("pig") and not dude:HasTag("werepig") end
local function OnAttacked(inst, data)
    local attacker = data.attacker
    if attacker ~= nil then
        if attacker.prefab ~= "deciduous_root" and not attacker:HasTag("pigelite") then
            if inst:HasTag("werepig") then
                inst.components.combat:ShareTarget(attacker, 30, IsNonWerePig, 10)
            elseif not inst:HasTag("werepig") and attacker:HasTag("werepig") and inst.components.werebeast then
                inst.components.werebeast:SetWere(120)
            end
        end
    end
end
local function OnTrade(inst, data)
    local item = data.item
    if item and data.giver and item.components.edible ~= nil and
        (item.components.edible.secondaryfoodtype == FOODTYPE.MONSTER or item.components.edible.healthvalue < 0) then
        inst.components.combat:SetTarget(data.giver)
    end
end
for index, pig in ipairs(pigs) do
    AddPrefabPostInit(pig, function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("attacked", OnAttacked)
        inst:ListenForEvent("trade", OnTrade)
        if inst.components.lootdropper then inst.components.lootdropper:AddChanceLoot("batnose", 0.1) end
    end)
end

-- 猪王无条件小游戏
if TUNING.DSTU then
    local function AbleToAcceptTest(inst, item, giver)
        if item.prefab == "pig_token" then return true end
        return true
    end
    AddPrefabPostInit("pigking", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.trader then inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest) end
    end)
end

-- 妥协猪王守卫改动
if TUNING.DSTU and TUNING.DSTU.PK_GUARDS then
    AddPrefabPostInit("pigking", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        local function ErectPoleBuild(x, y, z)
            local pole = SpawnPrefab("pigking_pigtorch")
            local collapse = SpawnPrefab("collapse_big")
            pole.Transform:SetPosition(x, y, z)
            collapse.Transform:SetPosition(x, y, z)
            inst.sg:GoToState("cointoss")
        end

        inst.Rebuild = ErectPoleBuild

        inst:DoTaskInTime(0, function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if #TheSim:FindEntities(x, y, z, 30, { "pkpole" }) == 0 then
                ErectPoleBuild(x + 7, y, z + 7)
                ErectPoleBuild(x + 7, y, z - 7)
                ErectPoleBuild(x - 7, y, z + 7)
                ErectPoleBuild(x - 7, y, z - 7)
            end
        end)

        local function IsGuard(guy)
            return guy.prefab == "pigking_pigguard" and not guy:HasTag("swc2hm") and    -- 影子猪人除外
                not (guy.components.follower ~= nil and guy.components.follower.leader ~= nil)
        end
        
        local function FindRecruits(inst, count)
            local guards = {}
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 20, nil, { "player", "FX", "INLIMBO" })
            
            for _, guy in ipairs(ents) do
                if IsGuard(guy) then
                    table.insert(guards, guy)
                    if #guards >= count then
                        break
                    end
                end
            end
            return guards
        end

        local function AcceptTest2hm(inst, item, giver)
            -- Wurt can still play the mini-game though
            if giver:HasTag("merm") and item.prefab ~= "pig_token" then
                return false
            end

            local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and
                item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0

            -- 检查是否是肉类食物且饱食度足够
            if item.components.edible ~= nil and item.components.edible.hungervalue > 60 
                and item.components.edible.foodtype == FOODTYPE.MEAT then
                return #FindRecruits(inst, 1) > 0
            end

            return item.components.tradable.goldvalue > 0 or is_event_item or item.prefab == "pig_token" 

        end
        
        local function SendRecruits(inst, hunger, guards, giver)
            giver:PushEvent("makefriend")
            for _, guard in ipairs(guards) do
                if giver.components.leader ~= nil then
                    giver.components.leader:AddFollower(guard)
                end
                if guard.components.follower ~= nil then
                    guard.components.follower.leader = giver
                    guard.components.follower:AddLoyaltyTime(hunger * TUNING.PIG_LOYALTY_PER_HUNGER)
                    guard.components.follower.maxfollowtime =
                    giver:HasTag("polite")
                        and TUNING.PIG_LOYALTY_MAXTIME + TUNING.PIG_LOYALTY_POLITENESS_MAXTIME_BONUS
                        or TUNING.PIG_LOYALTY_MAXTIME
                end
            end
        end

        local _OnAcceptOld = inst.components.trader.onaccept

        local function OnGetItemFromPlayer2hm(inst, giver, item)
            if item.components.edible ~= nil and item.components.edible.hungervalue > 60 
            and item.components.edible.foodtype == FOODTYPE.MEAT then -- 仅需60饱食度
                local recruits = FindRecruits(inst, 2) -- 现在找最多2个守卫
                if #recruits > 0 then
                    SendRecruits(inst, item.components.edible.hungervalue, recruits, giver)
                    inst.sg:GoToState("cointoss")
                    return
                end                
            end
            _OnAcceptOld(inst, giver, item)
        end

        inst.components.trader:SetAcceptTest(AcceptTest2hm)
        inst.components.trader.onaccept = OnGetItemFromPlayer2hm
    end)
end

--------------------------------------------------------------------------------
-- 通用武器装备交易系统
local function AddFollowerWeaponTrade(inst, additional_check, on_weapon_equipped)
    if not inst.components.trader then return end
    
    inst.components.trader.acceptnontradable = true
    local test = inst.components.trader.test
    
    inst.components.trader:SetAcceptTest(function(inst, item, giver, ...)
        -- 检查是否是手部武器
        if not inst.rangeweapondata2hm and 
           item.components.equippable ~= nil and 
           item.components.equippable.equipslot == EQUIPSLOTS.HANDS and
           not inst.components.combat:TargetIs(giver) then
            -- 执行额外检查
            if additional_check then
                return additional_check(inst, item, giver)
            end
            return true
        end
        return test and test(inst, item, giver, ...)
    end)
    
    local onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = function(inst, giver, item, ...)
        -- 如果是手部装备，装备武器
        if item.components.equippable ~= nil and 
           item.components.equippable.equipslot == EQUIPSLOTS.HANDS then
            -- 卸下当前武器
            local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if current ~= nil then 
                inst.components.inventory:DropItem(current, true) 
            end
            -- 装备新武器
            inst.components.inventory:Equip(item)
            -- 执行装备后回调
            if on_weapon_equipped then
                on_weapon_equipped(inst, giver, item)
            end
            return
        end
        -- 执行原有交易逻辑
        if onaccept then onaccept(inst, giver, item, ...) end
    end
end

-- 通用攻击动画系统
local function AddFollowerWeaponAttackAnim(sg_name, prefab_name, anim_config)
    AddStategraphPostInit(sg_name, function(sg)
        if not sg.states.attack then return end
        
        local oldOnEnterattack = sg.states.attack.onenter
        sg.states.attack.onenter = function(inst, target, ...)
            -- 先检查武器，决定使用哪个动画
            local has_weapon = false
            if inst.prefab == prefab_name and inst.components.inventory then
                local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if current ~= nil then
                    has_weapon = true
                    inst.sg.statemem.weapon2hm = current
                end
            end
            
            -- 如果有武器，使用武器动画；否则调用原始逻辑
            if has_weapon then
                -- 停止移动和开始攻击（复制原版逻辑）
                if inst.components.locomotor ~= nil then
                    inst.components.locomotor:StopMoving()
                end
                if inst.components.combat then
                    inst.components.combat:StartAttack()
                end
                
                -- 播放武器攻击动画
                if anim_config.pre_anim then
                    inst.AnimState:PlayAnimation(anim_config.pre_anim)
                    inst.AnimState:PushAnimation(anim_config.attack_anim, false)
                else
                    inst.AnimState:PlayAnimation(anim_config.attack_anim)
                end
                
                -- 缓存目标（复制原版逻辑）
                inst.sg.statemem.target = target
            else
                -- 没有武器时使用原始攻击逻辑
                oldOnEnterattack(inst, target, ...)
            end
        end
        
        -- 处理动画队列
        if anim_config.need_queue then
            local oldfn = sg.states.attack.events.animover and sg.states.attack.events.animover.fn
            if oldfn then
                sg.states.attack.events.animover.fn = function(inst, ...) 
                    if not inst.sg.statemem.weapon2hm then 
                        oldfn(inst, ...) 
                    end 
                end
            end
            if not sg.states.attack.events.animqueueover then
                sg.states.attack.events.animqueueover = EventHandler("animqueueover", 
                    function(inst) inst.sg:GoToState("idle") end)
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 兔人武器交易
AddPrefabPostInit("bunnyman", function(inst)
    if not TheWorld.ismastersim then return end
    AddFollowerWeaponTrade(inst)
end)

-- 兔人武器攻击动画
AddFollowerWeaponAttackAnim("bunnyman", "bunnyman", {
    pre_anim = "idle_loop_overhead",
    attack_anim = "atk_object",
    need_queue = true
})

--------------------------------------------------------------------------------
-- 猪人武器交易
AddPrefabPostInit("pigman", function(inst)
    if not TheWorld.ismastersim then return end
    AddFollowerWeaponTrade(inst)
end)

-- 猪人武器攻击动画
AddFollowerWeaponAttackAnim("pig", "pigman", {
    attack_anim = "atk_object",
    need_queue = false
})

--------------------------------------------------------------------------------
-- 鱼人武器交易

if GetModConfigData("Trade Fish with Merm") then
    -- 普通鱼人
    AddPrefabPostInit("merm", function(inst)
        if not TheWorld.ismastersim then return end
        AddFollowerWeaponTrade(inst, 
            function(inst, item, giver)
                if not (giver:HasTag("merm") or giver:HasTag("mermdisguise")) then
                    return false
                end
                if inst.components.sleeper and inst.components.sleeper:IsAsleep() then 
                    inst.components.sleeper:WakeUp() 
                end
                return true
            end,
            -- 添加临时标签让鱼人识别这是他们的工具
            function(inst, giver, weapon)
                if not weapon:HasTag("merm_tool") then
                    weapon:AddTag("merm_tool")
                end
            end
        )
    end)
    
    -- 守卫鱼人
    AddPrefabPostInit("mermguard", function(inst)
        if not TheWorld.ismastersim then return end
        AddFollowerWeaponTrade(inst, 
            function(inst, item, giver)
                if not (giver:HasTag("merm") or giver:HasTag("mermdisguise")) then
                    return false
                end
                -- 移除原版的 king 限制
                -- if inst.king ~= nil then return false end
                if inst.components.sleeper and inst.components.sleeper:IsAsleep() then 
                    inst.components.sleeper:WakeUp() 
                end
                return true
            end,
            -- 添加标签让守卫识别武器
            function(inst, giver, weapon)
                if not weapon:HasTag("merm_tool") then
                    weapon:AddTag("merm_tool")
                end
            end
        )
    end)
    
    -- 鱼人武器攻击动画（merm 和 mermguard 共用 "merm" stategraph）
    -- 鱼人使用 "work" 动画来表示使用工具/武器
    AddFollowerWeaponAttackAnim("merm", "merm", {
        attack_anim = "work",
        need_queue = false
    })
    AddFollowerWeaponAttackAnim("merm", "mermguard", {
        attack_anim = "work",
        need_queue = false
    })
end

