-- 电击险境：只有潮湿状态的非玩家生物才会被电击硬直
require("stategraphs/commonstates")

-- 削弱潮湿电击伤害倍率
TUNING.ELECTRIC_WET_DAMAGE_MULT = 0.5 -- 1→0.5

-- 提高晨星锤伤害
TUNING.NIGHTSTICK_DAMAGE = 34 -- 28.9→34

-- 判断生物是否处于潮湿状态（entityscript.lua中GetWetMultiplier）   
local function IsEntityWet(inst)
    if not inst or not inst:IsValid() then return false end
    
    if inst:HasTag("wet") then
        return true
    elseif inst:HasTag("moistureimmunity") then
        return false
    elseif inst.components.inventoryitem then
        return inst.components.inventoryitem:IsWet() and true or false
    end

    local moisture = inst.components.temp_moisture or inst.components.moisture
    if moisture then
        return moisture:GetMoisturePercent() > 0
    else
        return (
            (GLOBAL.TheWorld.state.iswet and not inst:HasTag("rainimmunity")) or
            (inst:HasTag("swimming") and not inst:HasTag("likewateroffducksback"))
        ) and true or false
    end
end

local try_electrocute_onattacked = rawget(CommonHandlers, "TryElectrocuteOnAttacked")
rawset(CommonHandlers, "TryElectrocuteOnAttacked", function(inst, data, ...)
        if inst:HasTag("player") or IsEntityWet(inst) then
            -- 对玩家和潮湿生物使用原版逻辑
            return try_electrocute_onattacked(inst, data, ...)
        else
            -- 不潮湿的生物不会被电击硬直
            return false 
        end
end)

-- 具有电免疫的的生物不会被电击硬直
local CanEntityBeElectrocuted = GLOBAL.CanEntityBeElectrocuted
GLOBAL.CanEntityBeElectrocuted = function(inst, ...)
    if inst:HasTag("electricdamageimmune") then return false end
    return CanEntityBeElectrocuted(inst, ...)
end

-- 修复妥协电气化电路反伤无冷却导致怪物无限僵直的问题
if TUNING.DSTU and TUNING.DSTU.WXLESS then
    
    -- 妥协的AltShockStun函数绕过了原版的电击僵直免疫系统，需要手动添加冷却机制
    local UpvalueHacker = require("tools/upvaluehacker")
    local module_definitions = require("um_wx78_moduledefs").module_definitions
    

    for _, def in ipairs(module_definitions) do
        if def.name == "taser" then
            local original_taser_onblockedorattacked = UpvalueHacker.GetUpvalue(def.activatefn, "taser_onblockedorattacked")
            
            if original_taser_onblockedorattacked then

                local function patched_taser_onblockedorattacked(wx, data, inst)
                    if (data and data.attacker and not data.redirected) and not inst._cdtask then
                        inst._cdtask = inst:DoTaskInTime(.3, function() inst._cdtask = nil end)

                        if data.attacker.components.combat and not (data.attacker.components.health and data.attacker.components.health:IsDead())
                            and (data.attacker.components.inventory == nil or not data.attacker.components.inventory:IsInsulated())
                            and (not data.weapon or (not data.weapon.components.projectile and (not data.weapon.components.weapon or not data.weapon.components.weapon.projectile))) then
                            
                            -- 检查攻击者是否已有电击僵直冷却（使用electricstunimmune标签）
                            if data.attacker:HasTag("electricstunimmune") then
                                -- 如果在冷却期内，只造成伤害，不触发僵直
                                SpawnPrefab("electrichitsparks"):AlignToTarget(data.attacker, wx, true)
                                
                                local damage_mult = 1
                                if not IsEntityElectricImmune(data.attacker) then
                                    damage_mult = TUNING.ELECTRIC_DAMAGE_MULT +
                                    TUNING.ELECTRIC_WET_DAMAGE_MULT * data.attacker:GetWetMultiplier()
                                end
                                
                                data.attacker.components.combat:GetAttacked(wx,
                                    damage_mult * (TUNING.WX78_TASERDAMAGE + (wx._cherriftchips and wx._cherriftchips > 0 and 10 * wx._cherriftchips or 0)),
                                    nil, "electric")
                                
                                -- 受击充电
                                if not data.attacker._chargeharvestable then
                                    data.attacker._chargeharvestable = true
                                    data.attacker:DoTaskInTime(3.5, function() data.attacker._chargeharvestable = nil end)
                                end
                            else
                                -- 正常触发僵直和伤害，然后添加冷却
                                SpawnPrefab("electrichitsparks"):AlignToTarget(data.attacker, wx, true)

                                local damage_mult = 1
                                if not IsEntityElectricImmune(data.attacker) then
                                    damage_mult = TUNING.ELECTRIC_DAMAGE_MULT +
                                    TUNING.ELECTRIC_WET_DAMAGE_MULT * data.attacker:GetWetMultiplier()
                                end

                                -- 触发僵直效果
                                if data.attacker.sg and data.attacker.sg:HasState("electrocute") and not IsEntityElectricImmune(data.attacker) then
                                    data.attacker:PushEvent("electrocute", { attacker = wx, stimuli = "electric" })
                                else
                                    -- 使用妥协的AltShockStun函数
                                    local AltShockStun = UpvalueHacker.GetUpvalue(def.activatefn, "AltShockStun")
                                    if AltShockStun then
                                        AltShockStun(data.attacker, wx)
                                    end
                                end
                                
                                data.attacker.components.combat:GetAttacked(wx,
                                    damage_mult * (TUNING.WX78_TASERDAMAGE + (wx._cherriftchips and wx._cherriftchips > 0 and 10 * wx._cherriftchips or 0)),
                                    nil, "electric")

                                -- 添加电击僵直冷却标签，持续10-12秒
                                data.attacker:AddTag("electricstunimmune")
                                data.attacker:DoTaskInTime(math.random(10, 12), function()
                                    if data.attacker and data.attacker:IsValid() then
                                        data.attacker:RemoveTag("electricstunimmune")
                                    end
                                end)
                                
                                if not data.attacker._chargeharvestable then
                                    data.attacker._chargeharvestable = true
                                    data.attacker:DoTaskInTime(3.5, function() data.attacker._chargeharvestable = nil end)
                                end
                            end
                        end
                    end
                end
                
                UpvalueHacker.SetUpvalue(def.activatefn, patched_taser_onblockedorattacked, "taser_onblockedorattacked")
            end
            break
        end
    end
end
