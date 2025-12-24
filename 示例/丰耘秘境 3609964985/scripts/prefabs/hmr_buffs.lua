-- 茶丛
local function HonorTeaPrimeAttached(inst, data)
    local target = data.target
    if target.components.stunnable == nil and (target.components.health ~= nil or target.components.combat ~= nil) then
        target:AddComponent("stunnable")
    end
    target.components.hstunnable:SetAwakable(false)
    if target.components.hstunnable ~= nil and not target.components.hstunnable:IsStunned() then
        if math.random() <= TUNING.HMR_HONOR_TEA_PRIME_STUN_CHANCE then
            target.components.hstunnable:Stun(TUNING.HMR_HONOR_TEA_PRIME_STUN_TIME)
        end
    end
end

local function SpiceHonorTeaPrimeAttached(inst, data)
    local target = data.target
    if target.components.stunnable == nil and (target.components.health ~= nil or target.components.combat ~= nil) then
        target:AddComponent("stunnable")
    end
    target.components.hstunnable:SetAwakable(true, TUNING.HMR_HONOR_TEA_PRIME_AWAKE_HEALTHPERCENT)
    if target.components.hstunnable ~= nil and not target.components.hstunnable:IsStunned() then
        target.components.hstunnable:AddStunDegree(TUNING.HMR_SPICE_HONOR_TEA_PRIME_AWAKE_DEGREE)
    end
end

-- 椰子
local function HonorCoconutPrimeAttached(inst, data)
    if math.random() <= TUNING.HMR_HONOR_COCONUT_PRIME_TREEGUARD_SPAWN_CHANCE then
        local treeguard = SpawnPrefab("honor_coconuttreeguard")
        treeguard.Transform:SetPosition(inst.Transform:GetWorldPosition())
        treeguard.components.follower:SetLeader(inst)
        treeguard:SetDisappear(TUNING.HMR_HONOR_COCONUT_PRIME_TREEGUARD_DISAPPEAR_TIME)
    end
end

local function SpiceHonorCoconutPrimeAttached(inst, data)
    if math.random() <= TUNING.HMR_SPICE_HONOR_COCONUT_PRIME_SPAWN_COCONUT_CHANCE then
        local target = data.target or inst
        if target ~= nil then
            local x, y, z = target.Transform:GetWorldPosition()
            for i = 1, math.random(1, 3) do
                local coconut = SpawnPrefab("honor_coconut")
                local r, theta = math.random(), math.random() * TWOPI
                local delay = math.random()
                coconut:DoTaskInTime(delay, function()
                    coconut.Transform:SetPosition(x + r * math.cos(theta), 20, z + r * math.sin(theta))
                end)
                coconut:DoTaskInTime(delay + 1, function()
                    local ents = TheSim:FindEntities(x, y, z, 1)
                    for k, v in pairs(ents) do
                        if v.components.health and not v:HasTag("player") and not v:HasTag("playerghost") then
                            HMR_UTIL.Attack(inst, v, TUNING.HMR_SPICE_HONOR_COCONUT_PRIME_SPAWN_COCONUT_DAMAGE)
                        end
                    end
                end)
            end
        end
    end
end

-- 小麦
local function HonorWheatPrimeAttached(inst, data)
    if math.random() <= TUNING.HMR_HONOR_WHEAT_PRIME_ADDCOLDNESS_CHANCE then
        local target = data.target
        if target ~= nil and target.components.freezable ~= nil and not target.components.freezable:IsFrozen() then
            target:DoTaskInTime(FRAMES, function() target.components.freezable:AddColdness(TUNING.HMR_HONOR_WHEAT_PRIME_ADDCOLDNESS_DEGREE, TUNING.HMR_HONOR_WHEAT_PRIME_FREEZE_TIME) end)
        end
    end
end

local function SpiceHonorWheatPrimeAttached(inst, data)
    if inst ~= nil and inst.components.higniter ~= nil then
        inst.components.higniter:AddIgnitionLevel(TUNING.HMR_SPICE_HONOR_WHEAT_PRIME_ADDIGNITIONLEVEL_DEGREE)
    end
end

-- 水稻
local function SpiceHonorRicePrimeAttached(inst, data)

end

-- 蛇皮果精华
local function TerrorSnakeskinfruitPrime(inst, data)
    local attacker = data.attacker
    if attacker ~= nil and math.random() <= TUNING.HMR_TERROR_SNAKESKINFRUIT_PRIME_IGNITE_CHANCE then
        if attacker.components.burnable ~= nil then
            attacker.components.burnable:Ignite(true, inst, inst)
        end
        for i = 1, math.random(3, 6) do
            local fire = SpawnPrefab("willow_throw_flame")
            local x, y, z = attacker.Transform:GetWorldPosition()
            local r, theta = math.random(), math.random() * TWOPI
            inst:DoTaskInTime(math.random(), function()
                local fx, fy, fz = x + r * math.cos(theta), y, z - r * math.sin(theta)
                fire.Transform:SetPosition(fx, fy, fz)
                local ents = TheSim:FindEntities(fx, fy, fz, 1)
                for _, ent in pairs(ents) do
                    HMR_UTIL.Attack(inst, ent, TUNING.HMR_TERROR_SNAKESKINFRUIT_PRIME_FIRE_DAMAGE)
                end
            end)
        end
    end
end

-- 蛇皮果果酱
local function SpiceTerrorSnakeskinfruitPrime(inst, data)
    local angle = inst.Transform:GetRotation()* DEGREES
    local x, y, z = inst.Transform:GetWorldPosition()
    for r = 1, 6 do
        inst:DoTaskInTime(r * 0.1, function()
            local fire = SpawnPrefab("willow_throw_flame")
            local fx, fy, fz = x + r * math.cos(angle), y, z - r * math.sin(angle)
            fire.Transform:SetPosition(fx, fy, fz)
            local ents = TheSim:FindEntities(fx, fy, fz, 1)
            for _, ent in pairs(ents) do
                HMR_UTIL.Attack(inst, ent, TUNING.HMR_SPICE_TERROR_SNAKESKINFRUIT_PRIME_FIRE_DAMAGE)
            end
        end)
    end
end

local buffs = {
    terror_blueberry_hat = {    --蓝莓帽
        -- duration = 60,
        name = "terror_blueberry_hat",
        attach = function (inst, target)
            if target ~= nil and target:IsValid() and not target:HasTag("playerghost") then
                if target.components.temperature~= nil then
                    target.components.temperature:SetTemperature(25)
                    target:StopUpdatingComponent(target.components.temperature)
                end
                if target.components.moisture~= nil then
                    target.components.moisture:AddRateBonus(inst, 0.5, "terror_blueberry_cap")
                end
            end
        end,
        extend = function (inst, target) end,
        detach = function (inst, target)
            if target ~= nil and target:IsValid() and not target:HasTag("playerghost") then
                if target.components.temperature~= nil then
                    target:StartUpdatingComponent(target.components.temperature)
                end
                if target.components.moisture~= nil then
                    target.components.moisture:RemoveRateBonus(inst, "terror_blueberry_cap")
                end
            end
        end
    },

    hmr_blueberry_carpet = {    --蓝莓毯
        name = "hmr_blueberry_carpet",
        attach = function (inst, target)
            if target ~= nil and target:IsValid() and not target:HasTag("playerghost") then
                if target.components.locomotor ~= nil then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst, "hmr_blueberry_carpet", 1.5)
                end

                if target.components.moisture~= nil then
                    if target.prefab == "wurt" then
                        target.components.moisture:AddRateBonus(inst, 2, "terror_blueberry_cap")
                    else
                        target.components.moisture:AddRateBonus(inst, -1, "terror_blueberry_cap")
                    end
                end
            end
        end,
        extend = function (inst, target) end,
        detach = function (inst, target)
            if target ~= nil and target:IsValid() and not target:HasTag("playerghost") then
                if target.components.locomotor ~= nil then
                    target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "hmr_blueberry_carpet")
                end

                if target.components.moisture~= nil then
                    target.components.moisture:RemoveRateBonus(inst, "terror_blueberry_cap")
                end
            end
        end
    },

    honor_dhp = {   --大红袍
        duration = 60,
        name = "honor_dhp",
        attach = function (inst, target)
            if target ~= nil and target:HasTag("player") and not target:HasTag("playerghost") and target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier('honor_dhp',2)
            end
        end,
        detach = function (inst, target)
            target.components.combat.externaldamagemultipliers:RemoveModifier('honor_dhp')
        end
    },

    honor_jasmine = {   --茉莉花
        duration = 90,
        name = "honor_jasmine",
        attach = function (inst, target)
            if target ~= nil and target:HasTag("player") and not target:HasTag("playerghost") and target.components.locomotor then
                if target.prefab == "wanda" then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst, "honor_jasmine", 1.1)
                    target.health_task = target:DoPeriodicTask(5, function()
                        if target.components.health then
                            target.components.health:DoDelta(-3)
                        end
                    end)
                else
                    target.components.locomotor:SetExternalSpeedMultiplier(inst, "honor_jasmine", 1.07)
                end
            end
        end,
        detach = function (inst, target)
            if target.health_task then
                target.health_task:Cancel()
                target.health_task = nil
            end
            target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "honor_jasmine")
        end,
    },

    honor_dhp_cooked = {    --烤大红袍
        duration = 60*1.4,
        name = "honor_dhp_cooked",
        attach = function (inst, target)
            if target ~= nil and target:HasTag("player") and not target:HasTag("playerghost") and target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier('honor_dhp_cooked',2)
            end
        end,
        detach = function (inst, target)
            target.components.combat.externaldamagemultipliers:RemoveModifier('honor_dhp_cooked',2)
        end,
    },

    honor_jasmine_cooked = {    --烤茉莉花
        duration = 90*1.4,
        name = "honor_jasmine_cooked",
        attach = function (inst, target)
            if target ~= nil and target:HasTag("player") and not target:HasTag("playerghost") and target.components.locomotor then
                if target.prefab == "wanda" then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst, "honor_jasmine_cooked", 1.1)
                    target.health_task2 = target:DoPeriodicTask(5, function()
                        if target.components.health then
                            target.components.health:DoDelta(-3)
                        end
                    end)
                else
                    target.components.locomotor:SetExternalSpeedMultiplier(inst, "honor_jasmine_cooked", 1.07)
                end
            end
        end,
        detach = function (inst, target)
            if target.health_task2 then
                target.health_task2:Cancel()
                target.health_task2 = nil
            end
            target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "honor_jasmine_cooked")
        end,
    },

    honor_tea_prime = { -- 茶丛精华
        duration = 240,
        name = "honor_tea_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", HonorTeaPrimeAttached)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", HonorTeaPrimeAttached)
            end
        end,
    },

    spice_honor_tea_prime = {   -- 茶叶（茶丛精华调味料）
        duration = 240,
        name = "spice_honor_tea_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", SpiceHonorTeaPrimeAttached)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", SpiceHonorTeaPrimeAttached)
            end
        end,
    },

    honor_coconut_prime = { -- 椰子精华
        duration = 480,
        name = "honor_coconut_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", HonorCoconutPrimeAttached)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", HonorCoconutPrimeAttached)
            end
        end,
    },

    spice_honor_coconut_prime = {   -- 椰蓉
        duration = 360,
        name = "spice_honor_coconut_prime",
        attach = function(inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", SpiceHonorCoconutPrimeAttached)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", SpiceHonorCoconutPrimeAttached)
            end
        end,
    },

    honor_wheat_prime = { -- 小麦精华
        duration = 240,
        name = "honor_wheat_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", HonorWheatPrimeAttached)
                inst.old_fire_damage_scale = target.components.health.fire_damage_scale
                target.components.health.fire_damage_scale = TUNING.WILLOW_FIRE_DAMAGE
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", HonorWheatPrimeAttached)
                target.components.health.fire_damage_scale = TUNING[string.upper(target.prefab).."_FIRE_DAMAGE"] or inst.old_fire_damage_scale or 1
            end
        end,
    },

    spice_honor_wheat_prime = { -- 面粉
        duration = 180,
        name = "spice_honor_wheat_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", SpiceHonorWheatPrimeAttached)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", SpiceHonorWheatPrimeAttached)
            end
        end,
    },

    honor_rice_prime = { -- 水稻精华
        duration = 600,
        name = "honor_rice_prime",
        attach = function (inst, target)
            if target ~= nil then
                if target.components.workmultiplier == nil then
                    target:AddComponent("workmultiplier")
                end
                target.components.workmultiplier:AddMultiplier(ACTIONS.CHOP,   TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
                target.components.workmultiplier:AddMultiplier(ACTIONS.MINE,   TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
                target.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
                target.components.workmultiplier:AddMultiplier(ACTIONS.TILL,   TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
                target.components.workmultiplier:AddMultiplier(ACTIONS.DIG,    TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)

                if not target:HasTag("hmr_ignore_speed_mult") then
                    target:AddTag("hmr_ignore_speed_mult")
                end

                if target.components.combat ~= nil then
                    target.components.combat.externaldamagemultipliers:SetModifier(inst, TUNING.BUFF_ATTACK_MULTIPLIER)
                end
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                if target.components.workmultiplier ~= nil then
                    target.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP,   inst)
                    target.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE,   inst)
                    target.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, inst)
                    target.components.workmultiplier:RemoveMultiplier(ACTIONS.TILL,   inst)
                    target.components.workmultiplier:RemoveMultiplier(ACTIONS.DIG,    inst)
                end

                if target:HasTag("hmr_ignore_speed_mult") then
                    target:RemoveTag("hmr_ignore_speed_mult")
                end

                if target.components.combat ~= nil then
                    target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
                end
            end
        end,
    },

    spice_honor_rice_prime = {  -- 米酒
        duration = 180,
        name = "spice_honor_rice_prime",
        attach = function (inst, target)
            if target ~= nil then
                if target.components.attackdodger == nil then
                    target:AddComponent("attackdodger")
                end
                local function CanDodge(player, attacker)
                    if player.components.debuffable ~= nil and player.components.debuffable:HasDebuff("spice_honor_rice_prime_buff") and
                        math.random() < TUNING.HMR_SPICE_HONOR_RICE_PRIME_DODGE_CHANCE
                    then
                        return true
                    end
                    return false
                end
                local function OnDodge(player, attacker)
                    if player.components.talker ~= nil then
                        player.components.talker:Say(STRINGS.HMR.ONDOGE_LINE[math.random(1, #STRINGS.HMR.ONDOGE_LINE)])
                    end
                    local px, py, pz = player.Transform:GetWorldPosition()
                    local angle = player:GetAngleToPoint(attacker.Transform:GetWorldPosition()) * DEGREES
                    local tx, ty, tz = px - math.cos(angle) * TUNING.HMR_SPICE_HONOR_RICE_PRIME_DODGE_DISTANCE, py, pz + math.sin(angle) * TUNING.HMR_SPICE_HONOR_RICE_PRIME_DODGE_DISTANCE
                    player.Physics:Teleport(tx, ty, tz)

                    local fx = SpawnPrefab("chester_transform_fx")
                    fx.Transform:SetPosition(px, py, pz)
                end
                target.components.attackdodger:SetCanDodgeFn(CanDodge)
                target.components.attackdodger:SetOnDodgeFn(OnDodge)

                if target.components.locomotor ~= nil then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst, "hmr_spice_honor_rice_prime_buff", TUNING.HMR_SPICE_HONOR_RICE_PRIME_SPEED_MULT)
                end
            end
        end,
        detach = function (inst, target)
            if target ~= nil and target.components.locomotor ~= nil then
                target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "hmr_spice_honor_rice_prime_buff")
            end
        end,
    },

    terror_blueberry_prime = {  -- 蓝莓精华
        duration = 600,
        name = "terror_blueberry_prime",
    },

    spice_terror_blueberry_prime = {  -- 蓝莓酱
        duration = 0.1,
        name = "spice_terror_blueberry_prime",
        attach = function (inst, target)
            if target ~= nil then
                local GIFT_LIST = {"mermhat", "mosquitomusk", "mosquitobomb", "mosquitofertilizer"}
                if target.prefab == "wormwood" then
                    GIFT_LIST = {"mermhat", "mosquitofertilizer", "mosquitofertilizer", "mosquitofertilizer"}
                end
                local gift = SpawnPrefab("gift")
                gift.components.unwrappable:WrapItems(GIFT_LIST, target)
                HMR_UTIL.DropLoot(target, gift)
            end
        end,
    },

    terror_ginger_prime = {
        duration = 600,
        name = "terror_ginger_prime",
        attach = function (inst, target)
            if target ~= nil then
                local eater = target.components.eater
                if eater ~= nil then
                    inst.old_eat_absorption = {eater.healthabsorption, eater.hungerabsorption, eater.sanityabsorption}
                    local function GetAbsorption(orig)
                        if orig <= 0.5 then
                            return TUNING.HMR_SPICE_TERROR_GINGER_PRIME_ABSORPTION_MULTIPLIER * 0.5
                        else
                            return orig * TUNING.HMR_TERROR_GINGER_PRIME_ABSORPTION_MULTIPLIER
                        end
                    end
                    target.components.eater:SetAbsorptionModifiers(
                        GetAbsorption(inst.old_eat_absorption[1]),
                        GetAbsorption(inst.old_eat_absorption[2]),
                        GetAbsorption(inst.old_eat_absorption[3])
                    )
                end
                HMR_UTIL.AddCharacterSkill(target, "expertchef", "terror_ginger_prime_buff")
                HMR_UTIL.AddCharacterSkill(target, "professionalchef", "terror_ginger_prime_buff")
                HMR_UTIL.AddCharacterSkill(target, "masterchef", "terror_ginger_prime_buff")
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                local eater = target.components.eater
                if eater ~= nil then
                    if inst.old_eat_absorption ~= nil then
                        eater:SetAbsorptionModifiers(
                            inst.old_eat_absorption[1],
                            inst.old_eat_absorption[2],
                            inst.old_eat_absorption[3]
                        )
                    end
                    inst.old_eat_absorption = nil
                end
                HMR_UTIL.RemoveCharacterSkill(target, "expertchef", "terror_ginger_prime_buff")
                HMR_UTIL.RemoveCharacterSkill(target, "professionalchef", "terror_ginger_prime_buff")
                HMR_UTIL.RemoveCharacterSkill(target, "masterchef", "terror_ginger_prime_buff")
            end
        end,
    },

    spice_terror_ginger_prime = {  -- 姜粉
        duration = 540,
        name = "spice_terror_ginger_prime",
        attach = function (inst, target)
            if target ~= nil then
                local eater = target.components.eater
                if eater ~= nil then
                    inst.old_eat_absorption = {eater.healthabsorption, eater.hungerabsorption, eater.sanityabsorption}
                    local function GetAbsorption(orig)
                        if orig <= 0.5 then
                            return TUNING.HMR_SPICE_TERROR_GINGER_PRIME_ABSORPTION_MULTIPLIER * 0.5
                        else
                            return orig * TUNING.HMR_SPICE_TERROR_GINGER_PRIME_ABSORPTION_MULTIPLIER
                        end
                    end
                    target.components.eater:SetAbsorptionModifiers(
                        GetAbsorption(inst.old_eat_absorption[1]),
                        GetAbsorption(inst.old_eat_absorption[2]),
                        GetAbsorption(inst.old_eat_absorption[3])
                    )
                end
                HMR_UTIL.AddCharacterSkill(target, "expertchef", "spice_terror_ginger_prime")
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                local eater = target.components.eater
                if eater ~= nil then
                    if inst.old_eat_absorption ~= nil then
                        eater:SetAbsorptionModifiers(
                            inst.old_eat_absorption[1],
                            inst.old_eat_absorption[2],
                            inst.old_eat_absorption[3]
                        )
                    end
                end
                HMR_UTIL.RemoveCharacterSkill(target, "expertchef", "spice_terror_ginger_prime")
            end
        end,
    },

    terror_snakeskinfruit_prime = {
        duration = 240,
        name = "terror_snakeskinfruit_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("attacked", TerrorSnakeskinfruitPrime)
                target:ListenForEvent("blocked", TerrorSnakeskinfruitPrime)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("attacked", TerrorSnakeskinfruitPrime)
                target:RemoveEventCallback("blocked", TerrorSnakeskinfruitPrime)
            end
        end,
    },

    spice_terror_snakeskinfruit_prime = {  -- 蛇皮果
        duration = 180,
        name = "spice_terror_snakeskinfruit_prime",
        attach = function (inst, target)
            if target ~= nil then
                target:ListenForEvent("onattackother", SpiceTerrorSnakeskinfruitPrime)
            end
        end,
        detach = function (inst, target)
            if target ~= nil then
                target:RemoveEventCallback("onattackother", SpiceTerrorSnakeskinfruitPrime)
            end
        end,
    },
}

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, prefabs)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        if inst.components.timer ~= nil then
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", duration)
        end

        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        if duration ~= nil then -- 为空则为持续性buff
            inst:AddComponent("timer")
            inst.components.timer:StartTimer("buffover", duration)
            inst:ListenForEvent("timerdone", OnTimerDone)
        end

        return inst
    end

    return Prefab(name.."_buff", fn)
end

local prefs = {}
for k, v in pairs(buffs) do
    table.insert(prefs, MakeBuff(v.name or k, v.attach, v.extend, v.detach, v.duration, v.priority, v.prefabs))
end

return unpack(prefs)