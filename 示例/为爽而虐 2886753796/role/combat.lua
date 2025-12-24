local SpDamageUtil = require("components/spdamageutil")
local mode = GetModConfigData("combat")
-- 伤害细节显示
local attackstatustip
local tiplength = 0
local function processexternaldamagemultipliers(v, mults, spmults, info)
    table.insert(mults, v._base or 1)
    if info and v._base and v._base ~= 1 then
        attackstatustip = attackstatustip .. "\n" .. tostring(v._base) .. info ..
                              (spmults and (TUNING.isCh2hm and "(支持特殊伤害)" or "(also Special dmg)") or "")
        tiplength = tiplength + 1
    end
    if spmults then table.insert(spmults, v._base or 1) end
    for source, src_params in pairs(v._modifiers) do
        for k, m in pairs(src_params.modifiers) do
            table.insert(mults, m or 1)
            if info and m and m ~= 1 then
                attackstatustip = attackstatustip .. "\n" .. tostring(m) .. info ..
                                      (k and k ~= "key" and type(k) == "string" and ((TUNING.isCh2hm and " 键 " or " Key ") .. k) or "") ..
                                      (source and (EntityScript.is_instance(source) or type(source) == "string") and
                                          ((TUNING.isCh2hm and " 源 " or " Src ") .. (source.name or source.prefab or source)) or "") ..
                                      (spmults and (TUNING.isCh2hm and " (支持特殊伤害)" or " (also Special dmg)") or "")
                tiplength = tiplength + 1
            end
            if spmults then table.insert(spmults, m or 1) end
        end
    end
end
local function processdamagetypebonus(self, target, mults, spmults, info)
    if target then
        for k, v in pairs(self.tags) do
            if target:HasTag(k) and v then
                processexternaldamagemultipliers(v, mults, spmults, info and
                                                     (info .. (TUNING.isCh2hm and "对" or " For ") .. k ..
                                                         (TUNING.isCh2hm and "标签伤害" or "Tag Dmg Mult")))
            end
        end
    end
end
local sptypenames = {planar = TUNING.isCh2hm and "[位面]" or "[planar]", medal_chaos = TUNING.isCh2hm and "[混沌]" or "[medal_chaos]"}
local function SpDamageUtilCollectSpDamage(ent, tbl, info)
    for sptype in pairs(SpDamageUtil._SpTypeMap) do
        local dmg = SpDamageUtil.GetSpDamageForType(ent, sptype)
        if dmg > 0 then
            if info then
                attackstatustip = attackstatustip .. "\n" ..
                                      (info .. (TUNING.isCh2hm and "特殊伤害" or " Special dmg") .. (sptypenames[sptype] or ("[" .. sptype .. "]")) ..
                                          ("：" .. tostring(dmg)))
                tiplength = tiplength + 1
            end
            tbl = tbl or {}
            tbl[sptype] = (tbl[sptype] or 0) + dmg
        end
    end
    return tbl
end
local function printspdamge(spdamage, info)
    for sptype in pairs(SpDamageUtil._SpTypeMap) do
        local dmg = spdamage[sptype]
        if dmg and dmg > 0 then
            attackstatustip = attackstatustip .. "\n" .. (info .. (sptypenames[sptype] or ("[" .. sptype .. "]")) .. ("：" .. tostring(dmg)))
            tiplength = tiplength + 1
        end
    end
end
local function cancelcdshowtask2hm(inst) inst.inspectstatustaskcd2hm = nil end
local function saytext(inst, self, text, time) self:Say(text, time or 20, true, true) end
local function NewCalcDamage(self, target, weapon, multiplier)
    if target:HasTag("alwaysblock") then return 0 end

    local printinfo = self.inspectstatus2hm and not self.inst.inspectstatustaskcd2hm
    if printinfo then
        attackstatustip = ""
        tiplength = 1
        self.inst.inspectstatustaskcd2hm = self.inst:DoTaskInTime(3, cancelcdshowtask2hm)
    else
        attackstatustip = nil
        tiplength = 0
    end

    local mults = {}
    local spmults = {}
    local basedamage
    local spdamage
    -- 需要后续读取的加成列表和相关信息
    local isplayertarget = target ~= nil and target:HasTag("player")
    local mount
    local basemultiplier = self.damagemultiplier
    local externaldamagemultipliers = self.externaldamagemultipliers -- 许多加成
    local bonus = self.damagebonus -- not affected by multipliers

    -- NOTE: playermultiplier is for damage towards players
    --      generally only applies for NPCs attacking players

    if weapon ~= nil and weapon.components.weapon ~= nil then
        -- No playermultiplier when using weapons
        -- basedamage, spdamage = weapon.components.weapon:GetDamage(self.inst, target)
        basedamage = FunctionOrValue(weapon.components.weapon.damage, weapon, self.inst, target) or 0
        if printinfo then
            attackstatustip = attackstatustip .. "\n" .. ((TUNING.isCh2hm and "武器伤害：" or "Weapon Dmg：") .. tostring(basedamage))
            tiplength = tiplength + 1
        end
        -- #DiogoW: entity's own SpDamage stacks with weapon's SpDamage
        spdamage = SpDamageUtilCollectSpDamage(self.inst, spdamage, printinfo and (TUNING.isCh2hm and "角色" or " Role"))
        spdamage = SpDamageUtilCollectSpDamage(weapon, spdamage, printinfo and (TUNING.isCh2hm and "武器" or " Weapon"))
        -- #V2C: entity's own damagetypebonus stacks with weapon's damagetypebonus
        if self.inst.components.damagetypebonus ~= nil then
            processdamagetypebonus(self.inst.components.damagetypebonus, target, mults, spmults, printinfo and (TUNING.isCh2hm and "倍 角色" or " Role"))
        end
        if weapon.components.damagetypebonus ~= nil then
            processdamagetypebonus(weapon.components.damagetypebonus, target, mults, spmults, printinfo and (TUNING.isCh2hm and "倍 武器" or "Weapon"))
        end
    else
        if self.inst.components.rider ~= nil and self.inst.components.rider:IsRiding() then
            mount = self.inst.components.rider:GetMount()
            if mount ~= nil and mount.components.combat ~= nil then
                basedamage = mount.components.combat.defaultdamage
                if printinfo then
                    attackstatustip = attackstatustip .. "\n" .. ((TUNING.isCh2hm and "坐骑伤害：" or "Mount Dmg：") .. tostring(basedamage or 0))
                    tiplength = tiplength + 1
                end
                spdamage = SpDamageUtilCollectSpDamage(mount, spdamage, printinfo and (TUNING.isCh2hm and "坐骑" or " Mount"))
                basemultiplier = mount.components.combat.damagemultiplier
                externaldamagemultipliers = mount.components.combat.externaldamagemultipliers
                bonus = mount.components.combat.damagebonus
                if mount.components.damagetypebonus ~= nil then
                    processdamagetypebonus(mount.components.damagetypebonus, target, mults, spmults, printinfo and (TUNING.isCh2hm and "倍 坐骑" or " Mount"))
                end
                local saddle = self.inst.components.rider:GetSaddle()
                if saddle ~= nil and saddle.components.saddler ~= nil then
                    local saddlebonusdmg = saddle.components.saddler:GetBonusDamage()
                    basedamage = basedamage + saddlebonusdmg
                    if printinfo and saddlebonusdmg and saddlebonusdmg ~= 0 then
                        attackstatustip = attackstatustip .. "\n" ..
                                              ((TUNING.isCh2hm and "牛鞍额外伤害：" or "Saddle Extra Dmg：") .. tostring(saddlebonusdmg))
                        tiplength = tiplength + 1
                    end
                    spdamage = SpDamageUtilCollectSpDamage(saddle, spdamage, printinfo and (TUNING.isCh2hm and "牛鞍" or " Saddle"))
                    if saddle.components.damagetypebonus ~= nil then
                        processdamagetypebonus(saddle.components.damagetypebonus, target, mults, spmults,
                                               printinfo and (TUNING.isCh2hm and "倍 牛鞍" or " Saddle"))
                    end
                end
            end
        end
        if mount == nil or mount.components.combat == nil then
            basedamage = self.defaultdamage
            if printinfo then
                attackstatustip = attackstatustip .. "\n" .. ((TUNING.isCh2hm and "角色伤害：" or "Role Dmg：") .. tostring(basedamage or 0))
                tiplength = tiplength + 1
            end
            spdamage = SpDamageUtilCollectSpDamage(self.inst, spdamage, printinfo and (TUNING.isCh2hm and "角色" or " Role"))
            if self.inst.components.damagetypebonus ~= nil then
                processdamagetypebonus(self.inst.components.damagetypebonus, target, mults, spmults, printinfo and (TUNING.isCh2hm and "倍 角色" or " Role"))
            end
        end
        local playermultiplier = isplayertarget and self.playerdamagepercent or 1
        table.insert(mults, playermultiplier)
        if printinfo and playermultiplier and playermultiplier ~= 1 then
            attackstatustip = attackstatustip .. "\n" .. tostring(playermultiplier) ..
                                  (TUNING.isCh2hm and "倍 对角色空手伤害" or " Role For player EmptyHands Dmg Mult")
            tiplength = tiplength + 1
        end
    end
    -- 可以直接得到的加成列表
    table.insert(mults, multiplier or 1)
    if printinfo and multiplier and multiplier ~= 1 then
        attackstatustip = attackstatustip .. "\n" .. tostring(multiplier) ..
                              (TUNING.isCh2hm and "倍 带电伤害或范围伤害" or " Electric/Areaattack Dmg Mult")
        tiplength = tiplength + 1
    end
    local pvpmultiplier = isplayertarget and self.inst:HasTag("player") and self.pvp_damagemod or 1
    table.insert(mults, pvpmultiplier)
    if printinfo and pvpmultiplier and pvpmultiplier ~= 1 then
        attackstatustip = attackstatustip .. "\n" .. tostring(pvpmultiplier) ..
                              (TUNING.isCh2hm and "倍 角色互相伤害(支持特殊伤害)" or " Role PVP Dmg Mult")
        tiplength = tiplength + 1
    end
    table.insert(spmults, pvpmultiplier)
    -- 后续读取加成列表完毕
    table.insert(mults, basemultiplier or 1)
    if printinfo and basemultiplier and basemultiplier ~= 1 then
        attackstatustip = attackstatustip .. "\n" .. tostring(basemultiplier) ..
                              (mount ~= nil and mount.components.combat ~= nil and (TUNING.isCh2hm and "倍 坐骑伤害系数" or " Mount Dmg Mult") or
                                  (TUNING.isCh2hm and "倍 角色伤害" or " Role Dmg Mult"))
        tiplength = tiplength + 1
    end
    processexternaldamagemultipliers(externaldamagemultipliers, mults, nil,
                                     printinfo and
                                         ((mount ~= nil and mount.components.combat ~= nil and
                                             (TUNING.isCh2hm and "倍 坐骑额外伤害" or " Mount Extra Dmg Mult") or
                                             (TUNING.isCh2hm and "倍 角色额外伤害" or " Role Extra Dmg Mult"))))
    table.insert(mults, (bonus or 0) + 1)
    if printinfo and bonus and bonus ~= 0 then
        attackstatustip = attackstatustip .. "\n" .. tostring(bonus + 1) ..
                              (mount ~= nil and mount.components.combat ~= nil and (TUNING.isCh2hm and "倍 坐骑伤害增幅" or " Mount Dmg Bonus") or
                                  (TUNING.isCh2hm and "倍 角色伤害增幅" or " Role Dmg Bonus"))
        tiplength = tiplength + 1
    end
    if self.customdamagemultfn ~= nil then
        local mult = self.customdamagemultfn(self.inst, target, weapon, multiplier, mount) or 1
        table.insert(mults, mult)
        if printinfo and mult and mult ~= 1 then
            attackstatustip = attackstatustip .. "\n" .. tostring(mult) .. (TUNING.isCh2hm and "倍 角色自适应伤害" or " Role Custrom Dmg Mult")
            tiplength = tiplength + 1
        end
    end
    -- 最后伤害计算
    local damage = basedamage or 0
    if damage ~= 0 then
        local mult = 1
        if mode == 2 then -- 2025.10.4 melon:小于1.5的倍率乘算，大于等于1.5的倍率加算，先乘算完再加算
            local add = 0
            for _, v in ipairs(mults) do
                if v >= 1.5 then
                    add = add + (v - 1)
                else
                    mult = mult * v
                end
            end
            mult = mult + add
        elseif mode == 3 then -- 全加算
            local maxmult = 1
            local extramult = 1
            for _, v in ipairs(mults) do
                if v > 1 then
                    extramult = extramult + (v - 1) / 2
                    if v > maxmult then maxmult = v end
                elseif v < 1 then
                    mult = mult * v
                end
            end
            if maxmult > 1 then
                extramult = extramult - (maxmult - 1) / 2
                mult = mult * (maxmult + math.min(extramult, maxmult) - 1)
            end
        else -- 原本
            for _, v in ipairs(mults) do mult = mult * v end
        end
        if printinfo and mult and mult ~= 1 then
            local calc = mode == 2 and (TUNING.isCh2hm and "[算法：小于1.5的倍率乘算，大于等于1.5的倍率加算，先乘算完再加算]" or "[<1.5 -> mult, >=1.5 -> add, first mult then add]") or -- 2025.10.4 melon:先乘后加
                        mode == 3 and (TUNING.isCh2hm and "[算法：取最大增益,其他增益减半叠加但上限至最大]" or "[Damage Rate Change From multiply Into GetMax and part additive]") or -- 全加算
                        "" -- 原本
            attackstatustip = attackstatustip .. "\n" .. tostring(mult) .. (TUNING.isCh2hm and "倍 结算伤害加成累计" or " Final Dmg Mult") .. calc ..
                                  (TUNING.isCh2hm and "\n原始伤害：" or "\nOriginal Dmg：") .. tostring(damage) ..
                                  (TUNING.isCh2hm and " >> 结算伤害：" or "Final Dmg：") .. tostring(damage * mult)
            tiplength = tiplength + 2
        end
        damage = damage * mult
    end
    if spdamage ~= nil then
        local mult = 1
        if mode == 2 then -- 2025.10.4 melon:先乘后加
            local add = 0
            for _, v in ipairs(spmults) do
                if v >= 1.5 then
                    add = add + (v - 1)
                else
                    mult = mult * v
                end
            end
            mult = mult + add
        elseif mode == 3 then -- 全加算
            local maxmult = 1
            local extramult = 1
            for _, v in ipairs(spmults) do
                if v > 1 then
                    extramult = extramult + (v - 1) / 2
                    if v > maxmult then maxmult = v end
                elseif v < 1 then
                    mult = mult * v
                end
            end
            if maxmult > 1 then
                extramult = extramult - (maxmult - 1) / 2
                mult = mult * (maxmult + math.min(extramult, maxmult) - 1)
            end
            -- mult = mult * (maxmult + math.min(extramult, maxmult) - 1) -- melon:多写了一遍?
        else -- 原本
            for _, v in ipairs(spmults) do mult = mult * v end
        end
        if printinfo and mult and mult ~= 1 then
            printspdamge(spdamage, (TUNING.isCh2hm and "原始特殊伤害" or "Original Special Dmg"))
            attackstatustip = attackstatustip .. "\n" .. tostring(mult) .. (TUNING.isCh2hm and "倍 特殊伤害加成累计" or " Final Special Dmg Mult")
            tiplength = tiplength + 1
        end
        if mult ~= 1 then spdamage = SpDamageUtil.ApplyMult(spdamage, mult) end
        if printinfo and mult and mult ~= 1 then printspdamge(spdamage, (TUNING.isCh2hm and ">>结算特殊伤害" or "Final Special Dmg")) end
    end
    if printinfo and attackstatustip then
        if self.inst.components.talker then
            local time = 1 + tiplength * 2
            attackstatustip = (TUNING.isCh2hm and "[为爽而虐]攻击伤害计算显示,冷却3秒,本次显示" or
                                  "HappyPatch Damage Status Display,cd 3s,show") .. time .. (TUNING.isCh2hm and "秒" or "s") .. attackstatustip
            self.inst:DoTaskInTime(0.1, saytext, self.inst.components.talker, attackstatustip, time)
        end
        tiplength = 0
        attackstatustip = nil
    end
    return damage, spdamage
end
local function processplayercombat(inst) if inst.components.combat then inst.components.combat.CalcDamage = NewCalcDamage end end
if mode == 2 or mode == 3 then
    AddPlayerPostInit(function(inst)
        if not TheWorld.ismastersim then return end
        inst:DoTaskInTime(1, processplayercombat)
    end)
end
-- 显示开关
local function wheninspectpunchingbag(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.inspectable then
        local GetDescription = inst.components.inspectable.GetDescription
        inst.components.inspectable.GetDescription = function(self, viewer, ...)
            local txt
            if viewer and viewer:IsValid() and viewer.userid and viewer.components.combat then
                viewer.components.combat.inspectstatus2hm = not viewer.components.combat.inspectstatus2hm
                txt = viewer.components.combat.inspectstatus2hm and
                          (TUNING.isCh2hm and "\n\n[为爽而虐]攻击伤害计算显示已开启\n检查拳击袋开关此功能" or
                              "\n\nHappyPatch Damage Status Display Now open\nInspect punching bag to close") or
                          (TUNING.isCh2hm and "\n\n[为爽而虐]攻击伤害计算显示已关闭\n检查拳击袋开关此功能" or
                              "\n\nHappyPatch Damage Status Display Now close\nInspect punching bag to open")
                if mode == 1 then
                    if viewer.components.combat.inspectstatus2hm then
                        viewer.components.combat.CalcDamage2hm = viewer.components.combat.CalcDamage
                        viewer.components.combat.CalcDamage = NewCalcDamage
                    else
                        viewer.components.combat.CalcDamage = viewer.components.combat.CalcDamage2hm
                        viewer.components.combat.CalcDamage2hm = nil
                    end
                end
            end
            local desc, filter_context, author = GetDescription(self, viewer, ...)
            desc = (desc or "") .. (txt or "")
            return desc, filter_context, author
        end
    end
end
AddPrefabPostInit("punchingbag", wheninspectpunchingbag)
AddPrefabPostInit("punchingbag_lunar", wheninspectpunchingbag)
AddPrefabPostInit("punchingbag_shadow", wheninspectpunchingbag)
AddPrefabPostInit("punchingbag_chaos", wheninspectpunchingbag)
