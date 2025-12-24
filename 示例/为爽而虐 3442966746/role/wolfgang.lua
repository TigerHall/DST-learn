-- 角色：沃尔夫冈削弱
local wolfgang = require("prefabs/wolfgang")
-- 工作暴击几率修正
TUNING.WOLFGANG_MIGHTY_WORK_CHANCE_1 = 0.97 -- 0.95
TUNING.WOLFGANG_MIGHTY_WORK_CHANCE_2 = 0.95 -- 0.9
TUNING.WOLFGANG_MIGHTY_WORK_CHANCE_3 = 0.93 -- 0.85
-- 教练技能随从伤害修正
TUNING.WOLFGANG_COACH_BUFF = (TUNING.WOLFGANG_COACH_BUFF - 1) / 2 + 1 -- 2 → 1.5
-- 大理石甲防御值
TUNING.ARMORMARBLE_ABSORPTION = 0.9
-- 理智上限修正
TUNING.WOLFGANG_SANITY = 150

-- 妥协大头改动未开启时生效
if not (TUNING.DSTU and TUNING.DSTU.WOLFGANG_HUNGERMIGHTY) then 
    -- 沃尔夫冈技能树文本改动
    local SkillTreeDefs = require("prefabs/skilltree_defs")
    if SkillTreeDefs.SKILLTREE_DEFS["wolfgang"] ~= nil then
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_critwork_1.desc = 
            TUNING.isCh2hm and "当力量值高于75时每5点力量值获得10%工作暴击概率，触发暴击时消耗12点力量值。\n暴击概率上限50%，未点亮本分支时基础暴击概率为0。" or
            "When mightiness is above 75, gain 10% chance to crit while working for every 5 mightiness, consuming 12 mightiness on crit.\n Max crit chance is 50%, base crit chance is 0% without this branch unlocked."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_critwork_2.desc = 
            TUNING.isCh2hm and "工作中暴击时消耗12→9力量值。" or
            "When you get a work crit, it consumes 12→9 mightiness."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_critwork_3.desc = 
            TUNING.isCh2hm and "工作中暴击时消耗9→6力量值。" or
            "When you get a work crit, it consumes an additional 9→6 mightiness."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_normal_speed.desc =
            TUNING.isCh2hm and "强壮形态下，移动速度增加 25%。" or
            "In mighty form, you gain 25% movement speed."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_dumbbell_crafting.desc = STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_DUMBBELL_CRAFTING_DESC ..
            (TUNING.isCh2hm and "\n魔法哑铃额外需要魔法科技。" or
            "\nThe magic dumbbell requires magic science.")
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_overbuff_1.desc = 
            TUNING.isCh2hm and "使用健身房或宝石哑铃来突破您的力量值极限。\n力量值最高可达 110。" or
            "Use the gym or gem-dumbbell to push your Mighty Meter past its limit.\n Mighty Meter can go up to 110."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_overbuff_2.desc =
            TUNING.isCh2hm and "使用健身房或宝石哑铃来突破您的力量值极限。\n力量值最高可达 120。" or
            "Use the gym or gem-dumbbell to push your Mighty Meter past its limit.\n Mighty Meter can go up to 120."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_overbuff_3.desc =
            TUNING.isCh2hm and "使用健身房或宝石哑铃来突破您的力量值极限。\n力量值最高可达 130。" or
            "Use the gym or gem-dumbbell to push your Mighty Meter past its limit.\n Mighty Meter can go up to 130."    
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_overbuff_4.desc =
            TUNING.isCh2hm and "使用健身房或宝石哑铃来突破您的力量值极限。\n力量值最高可达 140。" or
            "Use the gym or gem-dumbbell to push your Mighty Meter past its limit.\n Mighty Meter can go up to 140."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_overbuff_5.desc =
            TUNING.isCh2hm and "使用健身房或宝石哑铃来突破您的力量值极限。\n力量值最高可达 150。" or
            "Use the gym or gem-dumbbell to push your Mighty Meter past its limit.\n Mighty Meter can go up to 150."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_allegiance_shadow_1.desc = 
            TUNING.isCh2hm and "女王将以毁灭性的力量奖励你的忠诚。\n强壮形态下，与月亮阵营的生物战斗时，总伤害增加 +5%。" or
            "The Queen will reward your loyalty with devastating power.\n While Mighty, you deal +5% damage to Lunar creatures."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_allegiance_shadow_2.desc =
            TUNING.isCh2hm and "女王将以毁灭性的力量奖励你的忠诚。\n强壮形态下，与月亮阵营的生物战斗时，总伤害增加 +10%。" or
            "The Queen will reward your loyalty with devastating power.\n While Mighty, you deal +10% damage to Lunar creatures."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_allegiance_shadow_3.desc =
            TUNING.isCh2hm and "女王将以毁灭性的力量奖励你的忠诚。\n强壮形态下，与月亮阵营的生物战斗时，总伤害增加 +15%。" or
            "The Queen will reward your loyalty with devastating power.\n While Mighty, you deal +15% damage to Lunar creatures."   
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_allegiance_lunar_1.desc =
            TUNING.isCh2hm and "神秘创始人将通过揭露敌人的弱点来奖励你的好奇心。\n强壮形态下，与暗影阵营生物战斗时，总伤害增加+5%。" or
            "The Cryptic Founder will reward your curiosity by revealing the enemy's weaknesses.\nAdd +5% of total damage fighting Shadow-aligned creatures when Mighty."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_allegiance_lunar_2.desc =
            TUNING.isCh2hm and "神秘创始人将通过揭露敌人的弱点来奖励你的好奇心。\n强壮形态下，与暗影阵营生物战斗时，总伤害增加+10%。" or
            "The Cryptic Founder will reward your curiosity by revealing the enemy's weaknesses.\nAdd +10% of total damage fighting Shadow-aligned creatures when Mighty."
        SkillTreeDefs.SKILLTREE_DEFS["wolfgang"].wolfgang_allegiance_lunar_3.desc =
            TUNING.isCh2hm and "神秘创始人将通过揭露敌人的弱点来奖励你的好奇心。\n强壮形态下，与暗影阵营生物战斗时，总伤害增加+15%。" or
            "The Cryptic Founder will reward your curiosity by revealing the enemy's weaknesses.\nAdd +15% of total damage fighting Shadow-aligned creatures when Mighty."
    end

    -- 沃尔夫冈技能树阵营伤害修正
    TUNING.SKILLS.WOLFGANG_ALLEGIANCE_VS_LUNAR_BONUS_1 = 1.05
    TUNING.SKILLS.WOLFGANG_ALLEGIANCE_VS_LUNAR_BONUS_2 = 1.1/1.05
    TUNING.SKILLS.WOLFGANG_ALLEGIANCE_VS_LUNAR_BONUS_3 = 1.15/1.1
    TUNING.SKILLS.WOLFGANG_ALLEGIANCE_VS_SHADOW_BONUS_1 = 1.05
    TUNING.SKILLS.WOLFGANG_ALLEGIANCE_VS_SHADOW_BONUS_2 = 1.1/1.05
    TUNING.SKILLS.WOLFGANG_ALLEGIANCE_VS_SHADOW_BONUS_3 = 1.15/1.1

    -- 杂物锻炼，点亮后才获得工作暴击，力量值高于75每5点获得10%暴击率，上限50%，每级减少暴击消耗的力量值
    local function SpecialWorkMultiplier2hm(inst, action, target, tool, numworks, recoil)
        if not recoil and numworks ~= 0 and inst.components.mightiness:IsMighty() then
            local mightiness = inst.components.mightiness and inst.components.mightiness:GetCurrent()
            local cost = 12
            -- 未点亮技能时暴击概率为0
            local chance = 0  
            -- 点亮1/2/3级杂物锻炼后消耗的力量值分别为12/9/6
            if inst.components.skilltreeupdater then
                if inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_3") then
                    cost = 6
                    -- 100力量值时达到最高50%暴击率
                    if mightiness and mightiness > 75 then
                        chance = math.min(math.floor((mightiness - 5) / 15) * 10, 50)/100 
                    end
                elseif inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_2") then
                    cost = 9
                    if mightiness and mightiness > 75 then
                        chance = math.min(math.floor((mightiness - 5) / 15) * 10, 50)/100 
                    end
                elseif inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_1") then
                    cost = 12
                    if mightiness and mightiness > 75 then
                        chance = math.min(math.floor((mightiness - 5) / 15) * 10, 50)/100 
                    end
                end
            end
            if math.random() < chance then
                if inst.player_classified ~= nil then
                    inst.player_classified.playworkcritsound:push()
                end
                inst.components.mightiness:DoDelta(-cost)
                return 99999
            end
        end
    end

    -- 哑铃开发者：火铃和冰铃需要破损远古伪科技站解锁，宝石哑铃需要完整远古伪科技站解锁
    AddRecipePostInit("dumbbell_gem", function(recipe)
        recipe.level = TECH.MAGIC_THREE  
    end)
    AddRecipePostInit("dumbbell_redgem", function(recipe)
        recipe.level = TECH.MAGIC_TWO
    end)
    AddRecipePostInit("dumbbell_bluegem", function(recipe)
        recipe.level = TECH.MAGIC_TWO
    end)

    -- 沃尔夫冈饥饿速率修正
    local hunger_mult = {mighty = 1.75, normal = 1, wimpy = 0.75} -- 小头状态应用0.75倍饥饿速率

    local function statechange(inst, data) inst.components.hunger.burnrate = hunger_mult[data and data.state or "normal"] or 1 end
    
    local function init(inst)
        inst.components.hunger.burnrate = hunger_mult[inst.GetCurrentMightinessState and inst:GetCurrentMightinessState() or "normal"] or 1
    end

    local function RecalculateMightySpeed_heardmode2hm(inst)
        local skilltreeupdater = inst.components.skilltreeupdater
        if skilltreeupdater then
            if inst.components.mightiness:GetState() == "mighty" then
                if skilltreeupdater:IsActivated("wolfgang_normal_speed") then
                    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wolfgang_normal_speed", 1.25)
                end
            else
                inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wolfgang_normal_speed")
            end
        end
    end

    AddPrefabPostInit("wolfgang", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.workmultiplier.specialfn then
            inst.components.workmultiplier:SetSpecialMultiplierFn(SpecialWorkMultiplier2hm)
        end
        inst.RecalculateMightySpeed = RecalculateMightySpeed_heardmode2hm -- 强壮时获得1.25倍加速
        inst:ListenForEvent("mightiness_statechange", statechange)
        inst:DoTaskInTime(0, init)
        inst.hungermults2hm = hunger_mult
    end)
    
    AddComponentPostInit("mightydumbbell", function(mightydumbbell)
        local _DoWorkout = mightydumbbell.DoWorkout
        
        mightydumbbell.DoWorkout = function(self, doer)
            if doer.components.mightiness and doer:HasTag("strongman") then
                local mightiness = self:CheckEfficiency()
                -- 宝石哑铃可以突破上限
                if self.inst.prefab == "dumbbell_gem" then
                    -- 传递fromgym=true参数，允许突破上限
                    doer.components.mightiness:DoDelta(mightiness, false, false, false, true)
                else
                    doer.components.mightiness:DoDelta(mightiness)
                end
                
                if self.inst.components.finiteuses then
                    self.inst.components.finiteuses:Use(self.consumption)

                    if self.inst.components.finiteuses:GetUses() == 0 then
                        self:StopWorkout()
                        return false
                    end
                end
                return true
            end
            return _DoWorkout and _DoWorkout(self, doer)
        end
    end)
    
    -- 修改状态图以支持宝石哑铃突破上限
    AddStategraphPostInit("wilson", function(sg)
        local original_animover = sg.states.use_dumbbell_loop.events.animover.fn
        sg.states.use_dumbbell_loop.events.animover.fn = function(inst)
            inst.sg.statemem.dumbbell_anim_done = true
            
            -- 计算包含overbuff的上限百分比
            local mightiness_max = inst.components.mightiness:GetMax()
            local mightiness_overmax = inst.components.mightiness:GetOverMax() or 0
            local current_percent = inst.components.mightiness:GetPercent()
            
            -- 计算有效上限百分比
            local effective_percent_limit = 1
            if mightiness_overmax > 0 then
                -- 如果有overbuff技能，并且当前使用的是宝石哑铃
                local dumbbell = inst.components.dumbbelllifter and inst.components.dumbbelllifter.dumbbell
                if dumbbell and dumbbell.prefab == "dumbbell_gem" then
                    effective_percent_limit = 1 + mightiness_overmax / mightiness_max
                end
            end
            
            if inst.sg.statemem.queue_stop or inst.components.dumbbelllifter.dumbbell == nil then
                inst.sg:GoToState("use_dumbbell_pst")
            elseif inst.components.dumbbelllifter:Lift() and current_percent < effective_percent_limit then
                inst.sg:GoToState("use_dumbbell_loop")
            else
                inst.sg:GoToState("use_dumbbell_pst")
            end
        end
    end)
    
    
    AddComponentPostInit("mightiness", function(self)
        local oldBecomeState = self.BecomeState
        local oldDoDelta = self.DoDelta

        function self:BecomeState(state, silent, delay_skin, forcesound)
            oldBecomeState(self, state, silent, delay_skin, forcesound)
            
            -- 移除伤害乘数设置
            if self.inst.components.combat and self.inst.components.combat.externaldamagemultipliers then
                self.inst.components.combat.externaldamagemultipliers:RemoveModifier(self.inst)
            end

            -- 重置动态伤害乘数
            if self.inst.components.combat and self.inst.components.combat.externaldamagemultipliers then
                local damage_multiplier = self.current * 0.01 + 0.5 -- 基础为0.5倍，150力量值时2.0倍
                self.inst.components.combat.externaldamagemultipliers:SetModifier(self.inst, damage_multiplier)
            end

        end

        function self:DoDelta(delta, force_update, delay_skin, forcesound, fromgym)
            oldDoDelta(self, delta, force_update, delay_skin, forcesound, fromgym)
            
            -- 设置动态伤害乘数
            if self.inst.components.combat and self.inst.components.combat.externaldamagemultipliers then
                local damage_multiplier = self.current * 0.01 + 0.5
                self.inst.components.combat.externaldamagemultipliers:SetModifier(self.inst, damage_multiplier)
            end
        end
    end)
end

