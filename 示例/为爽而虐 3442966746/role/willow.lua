
-- ================= 伯尼潮湿时额外承伤 =================
TUNING.BERNIE_BURNING_REFLECT_DAMAGE = 20  -- 伯尼燃烧反伤从50下调到20
local bernies = {"bernie_active", "bernie_big"}

local function OnAttacked(inst, data) 
    if inst:GetIsWet() and inst.components.health then 
        inst.components.health:DoDelta(-17) 
    end 
end

for index, bernie in ipairs(bernies) do
    AddPrefabPostInit(bernie, function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("blocked", OnAttacked)
        inst:ListenForEvent("attacked", OnAttacked)
    end)
end

-- ================= 薇洛月焰和影焰施法理智惩罚 =================

-- 30秒自动恢复理智上限
local function recoversanity(inst, sanity_comp)
    if inst and sanity_comp and sanity_comp.emberpenalty2hm then
        local recovery_amount = 0.1 -- 每30秒恢复10%的理智上限
        if sanity_comp.emberpenalty2hm > recovery_amount then
            sanity_comp.emberpenalty2hm = sanity_comp.emberpenalty2hm - recovery_amount
            sanity_comp:AddSanityPenalty("emberpenalty2hm", sanity_comp.emberpenalty2hm)
            -- 继续30秒后的下一次恢复
            sanity_comp.embersanitytask2hm = inst:DoTaskInTime(30, recoversanity, sanity_comp)
        else
            -- 完全恢复
            sanity_comp.emberpenalty2hm = nil
            sanity_comp:RemoveSanityPenalty("emberpenalty2hm")
            sanity_comp.embersanitytask2hm = nil
        end
    else
        -- 清理任务
        if sanity_comp and sanity_comp.embersanitytask2hm then
            sanity_comp.embersanitytask2hm = nil
        end
    end
end

-- 暗焰和月焰扣除理智上限
AddComponentPostInit("aoespell", function(self)
    if not self.inst then return end
    
    local original_CastSpell = self.CastSpell
    self.CastSpell = function(self, doer, pos, ...)
        -- 记录技能使用前的冷却状态
        local pre_lunar_cd = doer and doer.components.spellbookcooldowns and doer.components.spellbookcooldowns:IsInCooldown("lunar_fire")
        local pre_shadow_cd = doer and doer.components.spellbookcooldowns and doer.components.spellbookcooldowns:IsInCooldown("shadow_fire")
        
        local result, reason = original_CastSpell(self, doer, pos, ...)
        
        -- 只对薇洛ember相关的技能进行处理
        if result and doer and doer.prefab == "willow" and self.inst.prefab == "willow_ember" and doer.components.sanity then
            if doer.components.spellbookcooldowns then
                -- 检查技能使用后的冷却状态
                local post_lunar_cd = doer.components.spellbookcooldowns:IsInCooldown("lunar_fire")
                local post_shadow_cd = doer.components.spellbookcooldowns:IsInCooldown("shadow_fire")
                
                -- 通过对比前后冷却状态来判断使用了哪个技能
                local used_lunar = not pre_lunar_cd and post_lunar_cd
                local used_shadow = not pre_shadow_cd and post_shadow_cd
                
                if used_lunar or used_shadow then
                    -- 计算扣除20点理智上限对应的惩罚值
                    local penalty = 20 / doer.components.sanity.max
                    doer.components.sanity.emberpenalty2hm = (doer.components.sanity.emberpenalty2hm or 0) + penalty
                    doer.components.sanity:AddSanityPenalty("emberpenalty2hm", doer.components.sanity.emberpenalty2hm)
                    
                    -- 开始30秒后的自动恢复
                    if doer.components.sanity.embersanitytask2hm then 
                        doer.components.sanity.embersanitytask2hm:Cancel()
                    end
                    doer.components.sanity.embersanitytask2hm = doer:DoTaskInTime(30, recoversanity, doer.components.sanity)
                end
            end
        end
        
        return result, reason
    end
end)

-- 薇洛黑化理智保存和读取机制
AddComponentPostInit("sanity", function(self)
    if not self.inst or self.inst.prefab ~= "willow" then return end
    

    
    local OnSave = self.OnSave
    self.OnSave = function(self, ...)
        local data = OnSave(self, ...)
        if self.emberpenalty2hm then 
            data.emberpenalty2hm = self.emberpenalty2hm 
        end
        return data
    end
    
    local OnLoad = self.OnLoad
    self.OnLoad = function(self, data, ...)
        if data and data.emberpenalty2hm then
            self.emberpenalty2hm = data.emberpenalty2hm
            self:AddSanityPenalty("emberpenalty2hm", self.emberpenalty2hm)
            -- 重新开始30秒后的自动恢复
            self.embersanitytask2hm = self.inst:DoTaskInTime(30, recoversanity, self)
        end
        OnLoad(self, data, ...)
    end
end)

AddPrefabPostInit("willow", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:ListenForEvent("death", function()
        if inst.components.sanity and inst.components.sanity.embersanitytask2hm then
            inst.components.sanity.embersanitytask2hm:Cancel()
            inst.components.sanity.embersanitytask2hm = nil
        end
    end)
end)

-- ================= 月焰暗焰伤害抗性机制 =================
-- 为所有可战斗的实体添加火焰抗性
AddComponentPostInit("combat", function(self)
    if self.inst and not self.inst:HasTag("player") then -- 玩家不需要抗性
        self.inst:DoTaskInTime(0, function()
            if not self.inst.components.flameresist2hm then
                self.inst:AddComponent("flameresist2hm")
            end
        end)
    end
end)

AddPrefabPostInit("willow_shadow_flame", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.weapon then
        local GetDamage = inst.components.weapon.GetDamage
        inst.components.weapon.GetDamage = function(self, attacker, target, ...)
            local dmg, spdmg = GetDamage(self, attacker, target, ...)
            if target and target:IsValid() and target.components.flameresist2hm then
                if dmg and dmg > 0 then
                    local original_dmg = dmg
                    dmg = dmg * (1 - target.components.flameresist2hm:GetResistance())
                    target.components.flameresist2hm:OnFlameDamage(original_dmg, self.inst)
                end
                if spdmg then
                    for k, v in pairs(spdmg) do
                        if v > 0 then
                            local original_dmg = v
                            spdmg[k] = v * (1 - target.components.flameresist2hm:GetResistance())
                            target.components.flameresist2hm:OnFlameDamage(original_dmg, self.inst)
                        end
                    end
                end
            elseif target and target:IsValid() then
                -- 如果目标没有抗性组件，立即添加
                if not target.components.flameresist2hm then
                    target:AddComponent("flameresist2hm")
                end
            end
            return dmg, spdmg
        end
    end
end)

AddPrefabPostInit("flamethrower_fx", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.weapon then
        local GetDamage = inst.components.weapon.GetDamage
        inst.components.weapon.GetDamage = function(self, attacker, target, ...)
            local dmg, spdmg = GetDamage(self, attacker, target, ...)
            if target and target:IsValid() then
                -- 月焰灭火
                if target.components.burnable and (target.components.burnable:IsBurning() or target.components.burnable:IsSmoldering()) then
                    target.components.burnable:Extinguish()
                end
                
                -- 应用火焰抗性
                if target.components.flameresist2hm then
                    if dmg and dmg > 0 then
                        local original_dmg = dmg
                        dmg = dmg * (1 - target.components.flameresist2hm:GetResistance())
                        target.components.flameresist2hm:OnFlameDamage(original_dmg, self.inst)
                    end
                    if spdmg then
                        for k, v in pairs(spdmg) do
                            if v > 0 then
                                local original_dmg = v
                                spdmg[k] = v * (1 - target.components.flameresist2hm:GetResistance())
                                target.components.flameresist2hm:OnFlameDamage(original_dmg, self.inst)
                            end
                        end
                    end
                else
                    -- 如果目标没有抗性组件，立即添加
                    if not target.components.flameresist2hm then
                        target:AddComponent("flameresist2hm")
                    end
                end
            end
            return dmg, spdmg
        end
    end
end)

