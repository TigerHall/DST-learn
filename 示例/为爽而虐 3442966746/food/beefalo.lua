-- 使用远程武器攻击时不再使牛获得战牛训势；
local function OnRiderDoAttack2hm(inst, data)
    -- 获取骑牛的玩家
    local rider = inst.components.rideable and inst.components.rideable:GetRider()
    if rider and rider.components.combat then
        -- 检查玩家使用的武器是否是远程武器
        local weapon = rider.components.combat:GetWeapon()
        if weapon and weapon:HasTag("rangedweapon") then
            -- 如果是远程武器，则移除已增加的战牛训势
            inst.components.domesticatable:DeltaTendency(TENDENCY.ORNERY, -TUNING.BEEFALO_ORNERY_DOATTACK)
        end
    end
end

-- 未驯化完成时受击概率甩下骑手；
local function OnAttacked2hm(inst, data)
    if inst.components.domesticatable and not inst.components.domesticatable:IsDomesticated() then
        if inst.components.rideable and inst.components.rideable:GetRider() then
            local rider = inst.components.rideable:GetRider()
            local buckChance = 0.01  -- 默认概率           
            -- 根据体型调整概率
            if inst.myscale and inst.myscale > 1.5 then
                buckChance = 0.05
            elseif inst.myscale and inst.myscale > 1.2 then
                buckChance = 0.025
            end
            if math.random() < buckChance then
                inst.components.rideable:Buck()
            end
        end
    end
end

-- 牛的体型较大时骑手被甩下将会受到额外伤害；
local function ApplyBuckDamage(inst, mount)
    if mount and mount.prefab == "beefalo" then
        -- 检查牛牛是否未驯化
        if mount.components.domesticatable then
            local damage = 0
            -- 根据体型调整伤害
            if mount.myscale and mount.myscale > 1.5 then
                damage = 80
            elseif mount.myscale and mount.myscale > 1.2 then
                damage = 40
            end
            -- 对骑手造成伤害
            if damage > 0 and inst.components.health and not inst.components.health:IsDead() then
                inst.components.combat:GetAttacked(mount, damage)
                -- 播放受伤音效
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                inst.components.talker:Say((TUNING.isCh2hm and "这一下摔伤我了！" or "Ouch! That hurt!"))               
            end
        end
    end
end

AddStategraphPostInit("wilson", function(sg)
    -- 保存原始bucked状态进入函数
    local old_bucked_onenter = sg.states.bucked.onenter
    
    -- 修改bucked状态
    sg.states.bucked.onenter = function(inst, ...)
        -- 先执行原始逻辑
        if old_bucked_onenter then
            old_bucked_onenter(inst, ...)
        end
        
        -- 获取骑乘的牛牛
        local mount = inst.components.rider and inst.components.rider:GetMount()
        
        -- 应用伤害
        ApplyBuckDamage(inst, mount)
    end
end)
-- 玩家骑行皮弗洛牛时的攻击速度削弱为1.5倍（对远程武器不生效），若皮弗洛牛处于未驯成状态则为2倍
-- 驯化变慢（原先不用毛刷基础需要约20天，现在需要40天）


-- 沃尔特骑牛时弹弓射程削弱为0.5倍；
AddComponentPostInit("combat", function(component)
    local _GetAttackRange = component.GetAttackRange

    function component:GetAttackRange()
        local default_range = _GetAttackRange(self)
        local weapon = self:GetWeapon()
        -- 仅沃尔特骑牛时生效
        if self.inst.prefab == "walter" and 
           self.inst.components.rider and 
           self.inst.components.rider:IsRiding() and 
           self.inst.components.rider:GetMount():HasTag("beefalo") and
           weapon and weapon:HasTag("slingshot") then
            return default_range * 0.5
        end
        return default_range
    end
end)

--绑定牛铃难度增加
STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.USEITEMON.STRANGER2HM = TUNING.isCh2hm and "我需要先驯化它一段时间" or "I need to tame it for sometime."
if STRINGS.CHARACTERS then
    for _, data in pairs(STRINGS.CHARACTERS) do
        if data and data.ACTIONFAIL and data.ACTIONFAIL.USEITEMON then
            data.ACTIONFAIL.USEITEMON.STRANGER2HM = STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.USEITEMON.STRANGER2HM
        end
    end
end

local function resetonuse(inst)
    if not inst:HasTag("minotaurhorn2hm") and inst.components.useabletargeteditem then
        local onusefn = inst.components.useabletargeteditem.onusefn
        inst.components.useabletargeteditem:SetOnUseFn(function(inst, target, user, ...)
            if target and target:IsValid() and not POPULATING and GetTime() - target.spawntime > FRAMES then
                if target:HasTag("swc2hm") or (target.components.persistent2hm and target.components.persistent2hm.data.supermonster) then
                    return false, "BEEF_BELL_INVALID_TARGET"
                elseif target.components.domesticatable then
                    local domestication = target.components.domesticatable:GetDomestication()
                    if domestication < 0.3 then
                        return false, "STRANGER2HM"
                    end
                end
            end
            return unpack({onusefn(inst, target, user, ...)})
        end)
    end
end

AddPrefabPostInit("beef_bell", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(FRAMES, resetonuse)
end)
AddPrefabPostInit("shadow_beef_bell", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(FRAMES, resetonuse)
end)
-- AddRecipePostInit("beef_bell", function(inst) table.insert(inst.ingredients, Ingredient("orangegem", 1)) end)


-- 牛被喂食扣血时反击
local function OnTrade(inst, data)
    local item = data.item
    if item and data.giver and item.components.edible ~= nil and
        (item.components.edible.secondaryfoodtype == FOODTYPE.MONSTER or item.components.edible.healthvalue < 0) and inst.components.combat then
        inst.components.combat:SetTarget(data.giver)
    end
end


--牛具有初始驯化倾向
local TENDENCY = {ORNERY = "ORNERY", RIDER = "RIDER", PUDGY = "PUDGY"}
local tendencies = {TENDENCY.ORNERY, TENDENCY.RIDER, TENDENCY.PUDGY}
local function setTendency(inst) if inst.SetTendency then inst:SetTendency() end end
AddComponentPostInit("domesticatable", function(self)
    if self.inst and self.tendencies and math.random() < 0.5 then
        self.tendencies[tendencies[math.random(#tendencies)]] = 0.15
        self.inst:DoTaskInTime(0, setTendency)
    end
    local CheckForChanges = self.CheckForChanges
    self.CheckForChanges = function(self, ...)
        local tendencies = self.tendencies
        CheckForChanges(self, ...)
        self.tendencies = tendencies
    end
end)



AddPrefabPostInit("beefalo", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("trade", OnTrade)
    if inst.components.combat and inst.components.combat.min_attack_period and inst.components.combat.min_attack_period > 3 then
        inst.components.combat.min_attack_period = math.max(3, inst.components.combat.min_attack_period * 3 / 4)
    end
    inst:ListenForEvent("attacked", OnAttacked2hm)
    inst:ListenForEvent("riderdoattackother", OnRiderDoAttack2hm)
end)