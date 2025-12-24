local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf") and GetModConfigData("wendy")

-- 温蒂伤害正常倍率
if GetModConfigData("Wendy Normal Attack Damage") then
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.combat.damagemultiplier = 1
    end)
end

-- -- TODO 温蒂攻击追加返回的阿比盖尔BUFF
-- if GetModConfigData("Wendy Attack with Recall Abigail") and false then
    -- local function OnHitOther(inst, data)
        -- local self = inst.components.ghostlybond
        -- if self == nil then return end
    -- end
    -- AddPrefabPostInit("wendy", function(inst)
        -- if not TheWorld.ismastersim then return end
        -- inst:ListenForEvent("onhitother", OnHitOther)
    -- end)
-- end

-- 帮助小惊吓后获得随机道具
if GetModConfigData("Pipspook Give Random Ghostly Elixir") then
    local items = {
        "ghostlyelixir_slowregen",
        "ghostlyelixir_slowregen",
        "ghostlyelixir_fastregen",
        "ghostlyelixir_attack",
        "ghostlyelixir_speed",
        "ghostlyelixir_speed",
        "ghostlyelixir_shield",
        "ghostlyelixir_shield",
        "ghostlyelixir_retaliation",
		"ghostlyelixir_revive"
    }
    AddPrefabPostInit("smallghost", function(inst)
        if not TheWorld.ismastersim then return end
        local pickup_toy = inst.PickupToy
        inst.PickupToy = function(inst, toy)
            pickup_toy(inst, toy)
            if inst._toys ~= nil and next(inst._toys) == nil then
                local tx, ty, tz = inst.Transform:GetWorldPosition()
                TheWorld:DoTaskInTime(0.25 + math.random() * 0.25, function()
                    local ghostlyelixir = SpawnPrefab(items[math.random(9)])
                    ghostlyelixir.Transform:SetPosition(tx, ty, tz)
                end)
            end
        end
    end)
end

-- 阿比盖尔等级保护,阿比盖尔死亡只降低1级且损失全部经验，温蒂死亡时不会减少增益，但会持续降级
local function consumeghostlybondtime(self, dt)
    if self.bondlevel == self.maxbondlevel then self:SetBondLevel(self.maxbondlevel - 1, self.bondlevelmaxtime) end
    self.bondleveltimer = (self.bondleveltimer or 0) - dt
    if self.bondleveltimer <= 0 and self.bondlevel > 1 then self:SetBondLevel(self.bondlevel - 1, self.bondlevelmaxtime + self.bondleveltimer) end
end
if GetModConfigData("Abigail Level Protect") then
    local function newondeath(inst)
        local self = inst.components.ghostlybond
        if self then
            self:Recall()
            if hardmode then
                if not self.death2hm then
                    self.death2hm = true
                    if self.bondlevel == self.maxbondlevel then self:SetBondLevel(self.maxbondlevel - 1, self.bondlevelmaxtime) end
                end
            else
                self:PauseBonding()
            end
        end
    end
    local function newrespawnedfromghost(inst)
        local self = inst.components.ghostlybond
        if self then
            if hardmode then
                if self.death2hm then
                    self.death2hm = nil
                    if self.bondlevel == 1 then
                        self.bondleveltimer = self.bondleveltimer or 0
                        inst:StartUpdatingComponent(self)
                    end
                end
            else
                self:ResumeBonding()
            end
        end
    end
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim then return end
        local src = "scripts/prefabs/wendy.lua"
        for i, func in ipairs(inst.event_listeners.death[inst]) do
            if debug.getinfo(func, "S").source == src then
                inst.event_listeners.death[inst][i] = newondeath
                break
            end
        end
        for i, func in ipairs(inst.event_listeners.ms_becameghost[inst]) do
            if debug.getinfo(func, "S").source == src then
                inst.event_listeners.ms_becameghost[inst][i] = newondeath
                break
            end
        end
        for i, func in ipairs(inst.event_listeners.ms_respawnedfromghost[inst]) do
            if debug.getinfo(func, "S").source == src then
                inst.event_listeners.ms_respawnedfromghost[inst][i] = newrespawnedfromghost
                break
            end
        end
    end)
    local function _ghost_death(self)
        if self.bondlevel > 1 then
            self:SetBondLevel(self.bondlevel - 1, self.bondleveltimer)
        else
            self.bondleveltimer = (self.bondleveltimer or 0) - self.bondlevelmaxtime
        end
        self:Recall(true)
    end
    AddComponentPostInit("ghostlybond", function(self, ...)
        self._ghost_death = function(ghost) _ghost_death(self, ghost) end
        if hardmode then
            local Onupdate = self.Onupdate
            self.Onupdate = function(self, dt, ...)
                if self.death2hm then
                    if self.bondlevel == 1 and (self.bondleveltimer or 0) <= 0 then
                        self.inst:StopUpdatingComponent(self)
                        return
                    end
                    self.bondleveltimer = (self.bondleveltimer or 0) - dt * 4
                    if self.bondleveltimer <= 0 and self.bondlevel > 1 then
                        self:SetBondLevel(self.bondlevel - 1, self.bondlevelmaxtime + self.bondleveltimer)
                    end
                else
                    Onupdate(self, ...)
                end
            end
            self.PauseBonding = nilfn
            self.ResumeBonding = nilfn
        end
    end)
end

-- 温蒂共享阿比盖尔光源和防护BUFF
if GetModConfigData("Wendy Share Light From Abigail") then
    local function OnAttacked(inst, data)
        local ghost = inst.components.ghostlybond and inst.components.ghostlybond.ghost
        local level = inst.components.ghostlybond and inst.components.ghostlybond.bondlevel
        if ghost and ghost:IsValid() and ghost:IsInLimbo() and level > 1 then
            if inst:HasDebuff("forcefield") then
				if hardmode then consumeghostlybondtime(inst.components.ghostlybond, 3) end
                if data.attacker ~= nil and data.attacker ~= inst and data.attacker.components.combat ~= nil then
                    local elixir_buff = ghost:GetDebuff("elixir_buff")
                    if elixir_buff ~= nil and elixir_buff.prefab == "ghostlyelixir_retaliation_buff" then
                        local retaliation = SpawnPrefab("abigail_retaliation")
                        retaliation:SetRetaliationTarget(data.attacker)
                        inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
                    else
                        inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
                    end
                end
            elseif (inst.components.health == nil or not inst.components.health:IsDead()) then
                local elixir_buff = ghost:GetDebuff("elixir_buff")
                if hardmode then consumeghostlybondtime(inst.components.ghostlybond, 3) end
                inst:AddDebuff("forcefield", elixir_buff ~= nil and elixir_buff.potion_tunings.shield_prefab or "abigailforcefield")
            end
        end
    end
    local function on_ghostlybond_level_change(inst)
        if inst.components.ghostlybond and not (inst:HasTag("playerghost") or inst.sg:HasStateTag("ghostbuild")) then
            local light_vals = TUNING.ABIGAIL_LIGHTING[inst.components.ghostlybond.bondlevel] or TUNING.ABIGAIL_LIGHTING[1]
            if light_vals.r ~= 0 and inst.components.ghostlybond.summoned == true and inst.components.ghostlybond.notsummoned == false then
                if not (inst._abigaillight2hm and inst._abigaillight2hm:IsValid()) then inst._abigaillight2hm = SpawnPrefab("deathcurselight2hm") end
                inst._abigaillight2hm.entity:SetParent(inst.entity)
                inst._abigaillight2hm.Light:Enable(true)
                inst._abigaillight2hm.Light:SetRadius(light_vals.r)
                inst._abigaillight2hm.Light:SetIntensity(light_vals.i)
                inst._abigaillight2hm.Light:SetFalloff(light_vals.f)
                inst._abigaillight2hm.Light:SetColour(180 / 255, 195 / 255, 225 / 255)
            elseif inst._abigaillight2hm and inst._abigaillight2hm:IsValid() then
                inst._abigaillight2hm:Remove()
                inst._abigaillight2hm = nil
            end
        end
    end
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim or not inst.components.ghostlybond then return inst end
        --inst:ListenForEvent("attacked", OnAttacked)
        inst:DoTaskInTime(0, on_ghostlybond_level_change)
        inst:ListenForEvent("ghostlybond_level_change", on_ghostlybond_level_change)
        local oldonsummoncompletefn = inst.components.ghostlybond.onsummoncompletefn
        local oldonrecallcompletefn = inst.components.ghostlybond.onrecallcompletefn
        inst.components.ghostlybond.onsummoncompletefn = function(inst, ...)
            if oldonsummoncompletefn then oldonsummoncompletefn(inst, ...) end
            on_ghostlybond_level_change(inst)
        end
        inst.components.ghostlybond.onrecallcompletefn = function(inst, ...)
            if oldonrecallcompletefn then oldonrecallcompletefn(inst, ...) end
            on_ghostlybond_level_change(inst)
        end
    end)
    local containers = require("containers")
    if containers.params.sisturn.itemtestfn then
        local olditemtestfn = containers.params.sisturn.itemtestfn
        containers.params.sisturn.itemtestfn = function(container, item, slot)
            return olditemtestfn(container, item, slot) or item.prefab == "ghostflower"
        end
    end
end

-- 温蒂共享阿比盖尔攻击BUFF和移速BUFF,阿比盖尔所有药剂同时生效
if GetModConfigData("Wendy Share Debuff From Abigail") then
	-- 处理不屈药剂和蒸馏复仇buff效果函数
	local ischarge
	local NO_TAGS_NO_PLAYERS =	{ "INLIMBO", "notarget", "noattack", "wall", "player", "companion", "playerghost" }
	local COMBAT_TARGET_TAGS = { "_combat" }
	local lasttime = -999
	local taskp
	local newonattacked_shield = function(inst, data)
		local currenttime = GetTime()
		if currenttime - lasttime >= 10 then
			ischarge = true
		end
		if ischarge == true then
			if data.redirected then
				return
			end

			ischarge = false
			lasttime = GetTime()

			local fx = SpawnPrefab("elixir_player_forcefield")
			inst:AddChild(fx)
			inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")

			inst.components.health.externalreductionmodifiers:RemoveModifier(inst, "forcefield")
			
			taskp = inst:DoTaskInTime(10, function(inst)
				inst.components.health.externalreductionmodifiers:SetModifier(inst, TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_REDUCTION, "forcefield")
			end)

			local debuff = inst:GetDebuff("ghostlyelixir_retaliation_buff")
			if not debuff then
				return
			end

			if debuff.potion_tunings.playerreatliate then
				local hitrange = 5
				local damage = 20

					--local retaliation = SpawnPrefab("abigail_retaliation")
					--retaliation:SetRetaliationTarget(data.attacker)
			
				debuff.ignore = {}

				local x, y, z = inst.Transform:GetWorldPosition()		    

				for i, v in ipairs(TheSim:FindEntities(x, y, z, hitrange, COMBAT_TARGET_TAGS, NO_TAGS_NO_PLAYERS)) do
					if not debuff.ignore[v] and
						v:IsValid() and
						v.entity:IsVisible() and
						v.components.combat ~= nil then
						local range = hitrange + v:GetPhysicsRadius(0)
						if v:GetDistanceSqToPoint(x, y, z) < range * range then
							if inst.owner ~= nil and not inst.owner:IsValid() then
								inst.owner = nil
							end
							if inst.owner ~= nil then
								if inst.owner.components.combat ~= nil and
									inst.owner.components.combat:CanTarget(v) and
									not inst.owner.components.combat:IsAlly(v)
								then
									debuff.ignore[v] = true
									local retaliation = SpawnPrefab("abigail_retaliation")
									retaliation:SetRetaliationTarget(v)
									--V2C: wisecracks make more sense for being pricked by picking
									--v:PushEvent("thorns")
								end
							elseif v.components.combat:CanBeAttacked() then
								-- NOTES(JBK): inst.owner is nil here so this is for non worn things like the bramble trap.
								local isally = false
								if not inst.canhitplayers then
									--non-pvp, so don't hit any player followers (unless they are targeting a player!)
									local leader = v.components.follower ~= nil and v.components.follower:GetLeader() or nil
									isally = leader ~= nil and leader:HasTag("player") and
										not (v.components.combat ~= nil and
											v.components.combat.target ~= nil and
											v.components.combat.target:HasTag("player"))
								end
								if not isally then
									debuff.ignore[v] = true
									v.components.combat:GetAttacked(inst, damage, nil, nil, inst.spdmg)
									local retaliation = SpawnPrefab("abigail_retaliation")
									retaliation:SetRetaliationTarget(v)
									--v:PushEvent("thorns")
								end
							end
						end
					end
				end
			end
			
		end
		--debuff.components.debuff:Stop()
	end
    local function onhitother(inst, data)
        if data and data.target and data.target:IsValid() and inst.components.ghostlybond and inst:HasDebuff("ghostlyelixir_attack_buff") and
            not data.target:HasDebuff("abigail_vex_debuff") then
            local ghost = inst.components.ghostlybond.ghost
            if ghost and ghost:IsValid() and ghost:IsInLimbo() and inst.components.ghostlybond.bondlevel > 1 then
                if hardmode then consumeghostlybondtime(inst.components.ghostlybond, 3) end
                data.target:AddDebuff("abigail_vex_debuff", "abigail_vex_debuff")
                local debuff = data.target:GetDebuff("abigail_vex_debuff")
                local skin_build = ghost:GetSkinBuild()
                if skin_build ~= nil and debuff ~= nil then
                    debuff.AnimState:OverrideItemSkinSymbol("flower", skin_build, "flower", ghost.GUID, "abigail_attack_fx")
                end
            end
        end
    end
    local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
        return mount == nil and inst:HasDebuff("ghostlyelixir_attack_buff") and
                   (TUNING.DSTU and TUNING.DSTU.WENDY_NERF or not target:HasDebuff("abigail_vex_debuff")) and 1.25 or 1
    end
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim or not inst.components.ghostlybond then return end
        inst:ListenForEvent("onhitother", onhitother)
        if not inst.components.combat.customdamagemultfn then
            inst.components.combat.customdamagemultfn = CustomCombatDamage
        else
            local old = inst.components.combat.customdamagemultfn
            inst.components.combat.customdamagemultfn = function(...) return (old(...) or 1) * CustomCombatDamage(...) end
        end
    end)
	local function ghostlyelixirshield(inst)
		if not TheWorld.ismastersim then return end
		if inst.potion_tunings and not inst.potion_tunings.shieldprocessP then
            inst.potion_tunings.shieldprocessP = true
			local apply_player = inst.potion_tunings.ONAPPLY_PLAYER
            local detach_player = inst.potion_tunings.ONDETACH_PLAYER
			inst.potion_tunings.ONAPPLY_PLAYER = function(inst, target, ...)
                if target:HasTag("ghostlyelixirPG") and target:HasTag("player") then
					target:RemoveTag("ghostlyelixirPG")
					ischarge = true
					if target.components.health ~= nil then
						target.components.health.externalreductionmodifiers:SetModifier(target, TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_REDUCTION, "forcefield")
					end			
					target:ListenForEvent("attacked", newonattacked_shield)
                else
					apply_player(inst, target, ...)
                end
				inst.potion_tunings.ONDETACH_PLAYER = function(inst, target, ...)
					if detach_player then
						detach_player(inst, target, ...)
					end
					if taskp ~= nil then
						taskp:Cancel()
						taskp = nil
					end
					target:RemoveEventCallback("attacked", newonattacked_shield)
					if target.components.health ~= nil then
						target.components.health.externalreductionmodifiers:RemoveModifier(target, "forcefield")
					end
					ischarge = nil
				end
            end
		end
	end
	if hardmode then
		AddRecipePostInit("ghostlyelixir_attack",function(inst) -- 更改夜影万金油配方(太超标了)
			inst.ingredients = {Ingredient("wormlight_lesser", 1),
								Ingredient("stinger", 1),
								Ingredient("ghostflower", 3)
								}
		end)
		AddPrefabPostInit("ghostlyelixir_slowregen_buff", function(inst)
			if not TheWorld.ismastersim then return end
			inst.potion_tunings.TICK_FN_PLAYER = function(inst, target, ...)
				target.components.health:DoDelta(0.5, true, inst.prefab) 
				target:RemoveTag("ghostlyelixirPG")
			end
		end)
		AddPrefabPostInit("ghostlyelixir_fastregen_buff", function(inst)
			if not TheWorld.ismastersim then return end
			local tick_fn_player = inst.potion_tunings.TICK_FN_PLAYER
			local task
			inst.potion_tunings.TICK_FN_PLAYER = function(inst, target, ...)
				if hardmode and target.zhiliaozhongPG and target:HasTag("player") then
					
					target.components.health:DoDelta(2, true, inst.prefab)
					if task ~= nil then
						task:Cancel()
						task = nil
					end
					task = target:DoTaskInTime(10, function()
						target.zhiliaozhongPG = nil
					end)
				else
					target.components.health:DoDelta(4, true, inst.prefab)
				end
			end
		end)
		-- TUNING.GHOSTLYELIXIR_REVIVE_DURATION = 0.2
		-- AddPrefabPostInit("ghostlyelixir_revive_buff", function(inst)
		-- 	if not TheWorld.ismastersim then return end
		-- 	inst.potion_tunings.ONAPPLY_PLAYER = function(inst, target)
		-- 		target:RemoveTag("ghostlyelixirPG")
		-- 		target.components.talker:Say(GetString(target, "ANNOUNCE_ELIXIR_BOOSTED"))

		-- 		if target.components.sanity then
		-- 			target.components.sanity:DoDelta(TUNING.SANITY_TINY)
		-- 		end
		-- 		if target.components.hunger then
		-- 			target.components.hunger:DoDelta(TUNING.CALORIES_SMALL)
		-- 		end
		-- 	end
		-- 	inst.potion_tunings.ONAPPLY = function(inst, target)
		-- 		if target.components.follower.leader and target.components.follower.leader.components.ghostlybond then
		-- 			local ghostlybond = target.components.follower.leader.components.ghostlybond
		-- 			if ghostlybond.bondleveltimer ~= nil then
		-- 				target.components.follower.leader.components.ghostlybond:SetBondLevel(ghostlybond.bondlevel, ghostlybond.bondleveltimer + 240 )
		-- 			end
		-- 		end
		-- 	end
		-- end)
	end
	AddPrefabPostInit("ghostlyelixir_retaliation_buff", ghostlyelixirshield)
	AddPrefabPostInit("ghostlyelixir_shield_buff", ghostlyelixirshield)
    AddPrefabPostInit("ghostlyelixir_speed_buff", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.potion_tunings then
            local original_apply_player = inst.potion_tunings.ONAPPLY_PLAYER
            local original_detach_player = inst.potion_tunings.ONDETACH_PLAYER
           
            inst.potion_tunings.ONAPPLY_PLAYER = function(inst, target, ...)
                if target:HasTag("ghostlyelixirPG") and target:HasTag("player") then
					target:RemoveTag("ghostlyelixirPG")
					original_apply_player(inst, target, ...)
                else
					original_apply_player(inst, target, ...)
                end
            end

            inst.potion_tunings.ONDETACH_PLAYER = function(inst, target, ...)
                if original_detach_player then
                    original_detach_player(inst, target, ...)
                end
            end
        end
    end)
	AddPrefabPostInit("ghostflowerhat", function(inst)
		if not TheWorld.ismastersim then return end
		local allbuffs = {
        "ghostlyelixir_attack_buff",
        "ghostlyelixir_speed_buff",
        "ghostlyelixir_slowregen_buff",
        "ghostlyelixir_fastregen_buff",
        "ghostlyelixir_retaliation_buff",
        "ghostlyelixir_shield_buff",
		"ghostlyelixir_revive_buff"
    }
		local oldunequip = inst.components.equippable.onunequipfn
		inst.components.equippable.onunequipfn = function(inst, owner)
			 for name, buff in pairs(allbuffs) do
				local debuff = owner:GetDebuff(buff)
				if debuff then
					debuff.components.debuff:Stop()
				end
            end
			if oldunequip ~= nil then oldunequip(inst, owner) end -- 2025.8.26 melon:加判空
		end
	end)
    AddPrefabPostInit("ghostlyelixir_attack_buff", function(inst)
        if not TheWorld.ismastersim then return end
         if inst.potion_tunings then
            local original_apply_player = inst.potion_tunings.ONAPPLY_PLAYER
            local original_detach_player = inst.potion_tunings.ONDETACH_PLAYER
           
            inst.potion_tunings.ONAPPLY_PLAYER = function(inst, target, ...)
                if target:HasTag("ghostlyelixirPG") and target:HasTag("player") then
					target:RemoveTag("ghostlyelixirPG")
					original_apply_player(inst, target, ...)
                else
					original_apply_player(inst, target, ...)
                end
            end

            inst.potion_tunings.ONDETACH_PLAYER = function(inst, target, ...)
                if original_detach_player then
                    original_detach_player(inst, target, ...)
                end
            end
        end
    end)
    local ghostlyelixirsbuffs = {
        ghostlyelixir_attack_buff = true,
        ghostlyelixir_speed_buff = true,
        ghostlyelixir_slowregen_buff = true,
        ghostlyelixir_fastregen_buff = true,
        ghostlyelixir_retaliation_buff = false,
        ghostlyelixir_shield_buff = false,
		ghostlyelixir_revive_buff = false
    }
    -- 多个BUFF需要修改循环显示特效
    TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY = 10
    local function processbufffxtime(inst)
        inst.processbufffxtimetask2hm = nil
        if inst.components.debuffable then
            local buffs = {}
            for name, buff in pairs(inst.components.debuffable.debuffs) do
                if buff and buff.inst and buff.inst:IsValid() and ghostlyelixirsbuffs[buff.inst.prefab] ~= nil and buff.inst.driptask and
                    buff.inst.potion_tunings and buff.inst.driptask.period == TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY then
                    table.insert(buffs, buff.inst)
                end
            end
            if #buffs > 0 then
                for i = 1, #buffs do
                    local fn = buffs[i].driptask.fn
                    buffs[i].driptask:Cancel()
                    buffs[i].driptask = buffs[i]:DoPeriodicTask(TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY, fn, TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY * (i - 0.5) / #buffs,
                                                                inst)
                end
            end
        end
    end
    local function processghostlyelixirbuff(inst)
        if not TheWorld.ismastersim then return end
        if inst.potion_tunings and not inst.potion_tunings.fxprocess2hm then
            inst.potion_tunings.fxprocess2hm = true
            local ONAPPLY = inst.potion_tunings.ONAPPLY
            inst.potion_tunings.ONAPPLY = function(inst, target, ...)
                if ONAPPLY then ONAPPLY(inst, target, ...) end
                if target and target:IsValid() and not target.processbufffxtimetask2hm then
                    target.processbufffxtimetask2hm = target:DoTaskInTime(0, processbufffxtime)
                end
            end
            local ONDETACH = inst.potion_tunings.ONDETACH
            inst.potion_tunings.ONDETACH = function(inst, target, ...)
                if ONDETACH then ONDETACH(inst, target, ...) end
                if target and target:IsValid() and not target.processbufffxtimetask2hm then
                    target.processbufffxtimetask2hm = target:DoTaskInTime(0, processbufffxtime)
                end
            end
        end
    end
    for ghostlyelixirbuff, buffstatus in pairs(ghostlyelixirsbuffs) do AddPrefabPostInit(ghostlyelixirbuff, processghostlyelixirbuff) end
    local playerghostlyelixirs = {
			"ghostlyelixir_speed", 
			"ghostlyelixir_attack", 
			"ghostlyelixir_retaliation", 
			"ghostlyelixir_shield", 
			"ghostlyelixir_slowregen", 
			"ghostlyelixir_fastregen", 
			"ghostlyelixir_revive"
		}
    local function processghostlyelixir(inst)
        if not TheWorld.ismastersim or not inst.components.ghostlyelixir then return end
        local DoApplyElixir = inst.components.ghostlyelixir.doapplyelixerfn
		local oldduration = inst.potion_tunings.DURATION_PLAYER
		local useskillP = false
		if inst.potion_tunings.skill_modifier_long_duration then useskillP = true end
        inst.components.ghostlyelixir.doapplyelixerfn = function(inst, giver, target, ...)
			-- 药效持续时间随技能树变化
			if useskillP and giver.components.skilltreeupdater:IsActivated("wendy_potion_duration") and not inst.buff_prefab.skill_modifier_long_duration then
				oldduration = oldduration * (hardmode and 1.5 or 2)
			end
            -- 攻击和移速药剂对姐姐和温蒂同时生效
            if table.contains(playerghostlyelixirs, inst.prefab) and target._playerlink and target._playerlink:IsValid() then
				if not target._playerlink:HasTag("ghostlyelixirPG") then target._playerlink:AddTag("ghostlyelixirPG") end
				if inst.buff_prefab == "ghostlyelixir_fastregen_buff" and not target._playerlink.zhiliaozhongPG then target._playerlink.zhiliaozhongPG = true end
                if target._playerlink:AddDebuff(inst.buff_prefab, inst.buff_prefab) then
					local newbuff = target._playerlink:GetDebuff(inst.buff_prefab)
					if newbuff and newbuff.components.timer then
						newbuff.components.timer:StopTimer("decay")
						newbuff.components.timer:StartTimer("decay", oldduration * (hardmode and 3/4 or 1))
					end
				end
            end
            -- 姐姐全部药剂叠加生效
            local cur_buff = target:GetDebuff("elixir_buff")
			-- 已有转移的此BUFF则移除转移的该BUFF
			if target:GetDebuff(inst.buff_prefab) then
				target:RemoveDebuff(inst.buff_prefab) 
            end 
            -- 已有正在生效BUFF
            if cur_buff ~= nil and cur_buff.prefab ~= inst.buff_prefab then
                if ghostlyelixirsbuffs[cur_buff.prefab] then
                    -- 已有非防御BUFF则转移非防御BUFF
                    local oldbuffprefab = cur_buff.prefab
                    local oldbufftimeleft = cur_buff.components.timer and cur_buff.components.timer:GetTimeLeft("decay") or 30
                    target:RemoveDebuff("elixir_buff")
                    if target:AddDebuff(oldbuffprefab, oldbuffprefab) then
                        local now_buff = target:GetDebuff(oldbuffprefab)
                        if now_buff and now_buff.components.timer then
                            now_buff.components.timer:StopTimer("decay")
                            now_buff.components.timer:StartTimer("decay", oldbufftimeleft)
                        end
                    end
					local buff = target:AddDebuff("elixir_buff", inst.buff_prefab)
					if buff then
						local new_buff = target:GetDebuff("elixir_buff")
						new_buff:buff_skill_modifier_fn(giver, target)
					end
					return true
                elseif ghostlyelixirsbuffs[inst.buff_prefab] then
                    -- 已有防御BUFF,施加非防御BUFF则转移非防御BUFF
					local buff = target:AddDebuff(inst.buff_prefab, inst.buff_prefab)
					if buff then
						local new_buff = target:GetDebuff(inst.buff_prefab)
						new_buff:buff_skill_modifier_fn(giver, target)
					end
					return true
                elseif cur_buff.prefab == "ghostlyelixir_retaliation_buff" and inst.buff_prefab == "ghostlyelixir_shield_buff" then
                    -- 已有高级防御BUFF施加低级防御BUFF则
                    return false
                end
			end
            return DoApplyElixir(inst, giver, target, ...)
        end
    end
    local ghostlyelixirs = {
        "ghostlyelixir_attack",
        "ghostlyelixir_speed",
        "ghostlyelixir_slowregen",
        "ghostlyelixir_fastregen",
        "ghostlyelixir_retaliation",
        "ghostlyelixir_shield",
		"ghostlyelixir_revive"
    }
    for _, ghostlyelixir in ipairs(ghostlyelixirs) do AddPrefabPostInit(ghostlyelixir, processghostlyelixir) end
    -- 阿比具有转移的攻击BUFF时强制夜间伤害
    local function UpdateDamage(inst, ...)
        local oldphase = TheWorld.state.phase
        TheWorld.state.phase = inst:HasDebuff("ghostlyelixir_attack_buff") and "night" or oldphase
        inst.oldUpdateDamage2hm(inst, ...)
        TheWorld.state.phase = oldphase
    end
    local function delayprocessbuff(inst, name, set)
        if not inst:HasTag("swc2hm") and inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil and
            inst._playerlink.components.pethealthbar.SetSymbol2hm then
            if set then
                if inst:HasDebuff(name) or (inst:GetDebuff("elixir_buff") and inst:GetDebuff("elixir_buff").prefab == name) then
                    inst._playerlink.components.pethealthbar:SetSymbol2hm(name)
                end
            elseif not (inst:HasDebuff(name) or (inst:GetDebuff("elixir_buff") and inst:GetDebuff("elixir_buff").prefab == name)) then
                inst._playerlink.components.pethealthbar:RemoveSymbol2hm(name)
            end
        end
    end
    -- 月亮阿比药剂伤害正常
    AddStategraphPostInit("abigail", function(sg)
        if sg.states.gestalt_loop_attack and sg.states.gestalt_loop_attack.onenter then
            local onenter = sg.states.gestalt_loop_attack.onenter
            sg.states.gestalt_loop_attack.onenter = function(inst, ...)
                onenter(inst, ...)
                local buff = inst:GetDebuff("ghostlyelixir_attack_buff") or inst:GetDebuff("elixir_buff")
                local phase = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or TheWorld.state.phase
                local damage = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)
                inst.components.combat:SetDefaultDamage(damage)
            end
        end
    end)

    local function ApplyGestaltAttackAtDamageMultRate(inst, tabula, key, value)
        if inst.sg.statemem.originalattackvalue == nil then
            inst.sg.statemem.originalattackvalue = {}
            inst.sg.statemem.lastattackvalue = {}
        end
    
        if inst.sg.statemem.originalattackvalue[key] == nil then
            inst.sg.statemem.originalattackvalue[key] = tabula[key]
        end
    
        if inst.sg.statemem.lastattackvalue[key] ~= nil and tabula[key] ~= inst.sg.statemem.lastattackvalue[key] then
             -- Something else changed tabula[key], consider that as our originalattackvalue...
            inst.sg.statemem.originalattackvalue[key] = tabula[key]
        end
    
        tabula[key] = (value or inst.sg.statemem.lastattackvalue[key] or tabula[key]) * TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MULT_RATE
    
        inst.sg.statemem.lastattackvalue[key] = tabula[key]
    end
    AddStategraphPostInit("abigail", function(sg) -- 2025.10.22 melon:补充这个状态的
        if sg.states.gestalt_loop_homing_attack and sg.states.gestalt_loop_homing_attack.onenter then
            local onenter = sg.states.gestalt_loop_homing_attack.onenter
            sg.states.gestalt_loop_homing_attack.onenter = function(inst, ...)
                onenter(inst, ...)
                local buff = inst:GetDebuff("ghostlyelixir_attack_buff") or inst:GetDebuff("elixir_buff")
                local phase = (buff ~= nil and buff.prefab == "ghostlyelixir_attack_buff") and "night" or TheWorld.state.phase
                local damage = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)
                -- inst.components.combat:SetDefaultDamage(damage)
                ApplyGestaltAttackAtDamageMultRate(inst, inst.components.combat, "defaultdamage", damage)
                ApplyGestaltAttackAtDamageMultRate(inst, inst.components.planardamage, "basedamage")
                ApplyGestaltAttackAtDamageMultRate(inst, inst.components.planardamage.externalbonuses, "_modifier")
            end
        end
    end)
    AddPrefabPostInit("abigail", function(inst)
        if not TheWorld.ismastersim then return end
        inst.oldUpdateDamage2hm = inst.UpdateDamage
        inst.UpdateDamage = UpdateDamage
        inst:WatchWorldState("phase", UpdateDamage)
        UpdateDamage(inst)
        if inst.components.debuffable then
            local OnDebuffAdded = inst.components.debuffable.ondebuffadded
            inst.components.debuffable.ondebuffadded = function(inst, name, debuff, ...)
                if ghostlyelixirsbuffs[debuff.prefab] ~= nil then inst:DoTaskInTime(0, delayprocessbuff, debuff.prefab, true) end
                OnDebuffAdded(inst, name, debuff, ...)
            end
            local OnDebuffRemoved = inst.components.debuffable.ondebuffremoved
            inst.components.debuffable.ondebuffremoved = function(inst, name, debuff, ...)
                if ghostlyelixirsbuffs[debuff.prefab] ~= nil then inst:DoTaskInTime(0, delayprocessbuff, debuff.prefab) end
                OnDebuffRemoved(inst, name, debuff, ...)
            end
        end
    end)
    -- 姐姐的UI只够显示4个UI，其中一个是原版的，所以只能这3个用来显示非防御BUFF了，且快速回血BUFF因此不显示
    local UIAnim = require "widgets/uianim"
    local function checkabigailbuff(inst)
        if inst and inst == ThePlayer and inst.HUD and inst.HUD.controls and inst.HUD.controls and inst.HUD.controls.status and
            inst.HUD.controls.status.pethealthbadge and inst.components.pethealthbar then
            local badge = inst.HUD.controls.status.pethealthbadge
            local self = inst.components.pethealthbar
            for buff, buffstatus in pairs(ghostlyelixirsbuffs) do
                if buff and self[buff .. "2hm"] then
                    local name = buff .. "icon2hm"
                    if badge[name] then
                        local status = self[buff .. "2hm"]:value()
                        if buff == "ghostlyelixir_shield_buff" and self.ghostlyelixir_retaliation_buff2hm:value() then status = true end
                        if status then
                            if not badge[name].enable2hm then
                                badge[name].enable2hm = true
                                badge[name]:GetAnimState():PlayAnimation("buff_activate")
                                badge[name]:GetAnimState():PushAnimation("buff_idle", false)
                            end
                        elseif badge[name] and badge[name].enable2hm then
                            badge[name].enable2hm = false
                            badge[name]:GetAnimState():PlayAnimation("buff_deactivate")
                            badge[name]:GetAnimState():PushAnimation("buff_none", false)
                        end
                    end
                end
            end
        end
    end
    AddComponentPostInit("pethealthbar", function(self)
        for buff, buffstatus in pairs(ghostlyelixirsbuffs) do
            if buff then self[buff .. "2hm"] = net_bool(self.inst.GUID, buff .. "2hm.is", "abigailbuff2hmdirty") end
        end
        if not self.ismastersim then self.inst:ListenForEvent("abigailbuff2hmdirty", checkabigailbuff) end
        self.SetSymbol2hm = function(self, buff) if self.ismastersim and buff and self[buff .. "2hm"] then self[buff .. "2hm"]:set(true) end end
        self.RemoveSymbol2hm = function(self, buff) if self.ismastersim and buff and self[buff .. "2hm"] then self[buff .. "2hm"]:set(false) end end
    end)
    AddClassPostConstruct("widgets/pethealthbadge", function(self, owner)
        for buff, buffstatus in pairs(ghostlyelixirsbuffs) do
            if buff then
                local name = buff .. "icon2hm"
                self[name] = self.underNumber:AddChild(UIAnim())
                local anim = self[name]:GetAnimState()
                anim:SetBank("status_abigail")
                anim:SetBuild("status_abigail")
                anim:OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[buff] or self.default_symbol_build, buff)
                anim:PlayAnimation("buff_none")
                anim:AnimateWhilePaused(false)
                self[name]:SetClickable(false)
                -- ghostlyelixir_shield_buff = false,
                -- ghostlyelixir_retaliation_buff = false
                if buff == "ghostlyelixir_attack_buff" then
                    -- 夜间攻击BUFF,左上角
                    self[name]:SetScale(1, -1, 1)
                elseif buff == "ghostlyelixir_speed_buff" then
                    -- 速度BUFF，右下角
                    self[name]:SetScale(-1, 1, 1)
                elseif buff == "ghostlyelixir_slowregen_buff" or buff == "ghostlyelixir_fastregen_buff" then
                    -- 慢速和快速回血BUFF，右上角
                    self[name]:SetScale(-1, -1, 1)
                    -- 防御BUFF，左下角
                end
                self[name]:MoveToFront()
            end
        end
        local ShowBuff = self.ShowBuff
        self.ShowBuff = function(self, symbol, ...)
            if symbol ~= 0 and not self.OVERRIDE_SYMBOL_BUILD[symbol] then return end
            ShowBuff(self, symbol, ...)
        end
        if owner and owner:IsValid() then owner:DoTaskInTime(3, checkabigailbuff) end
    end)
end

-- 2025.4.22 melon:温蒂野餐盒可放料理、荣耀花环、蝴蝶翅膀、月蛾翅膀，1.33倍保鲜，可选所有人都可打开
local select_elixir = GetModConfigData("wendy elixir_container")
if select_elixir == 1 or select_elixir == 2 then
    local containers = require("containers")
    if containers and containers.params and containers.params.elixir_container then
        local olditemtestfn = containers.params.elixir_container.itemtestfn
        containers.params.elixir_container.itemtestfn = function(container, item, slot)
            return olditemtestfn == nil or olditemtestfn(container, item, slot) or item and item:HasTag("preparedfood") or item and item.prefab and (item.prefab == "ghostflowerhat" or item.prefab == "butterflywings" or item.prefab == "butterfly" or item.prefab == "abigail_flower" or item.prefab == "moonbutterflywings" or item.prefab == "moonbutterfly")
        end
    end
    AddPrefabPostInit("elixir_container", function(inst) -- 野餐盒
        if not TheWorld.ismastersim then return end
        if inst.components.preserver == nil then inst:AddComponent("preserver") end
        -- 翅膀永鲜   其余1.33倍保鲜
        local function perish_rate_multiplier(inst, item) return item and item.prefab and (item.prefab == "butterflywings" or item.prefab == "moonbutterflywings") and 0 or 0.75 end
        inst.components.preserver:SetPerishRateMultiplier(perish_rate_multiplier)
        -- 所有人直接能打开:"player"  仅温蒂"ghostlyfriend"
        if inst.components.container then
            inst.components.container.restrictedtag = select_elixir == 2 and "player" or "ghostlyfriend"
        end
    end)
end  -- 2025.4.22 end

-- 显示升级时间----------------------------------------------
if GetModConfigData("Wendy SkillTree") then
    local function UpdateHoverStr(inst)
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and owner:HasTag("player") then
            if owner.components.ghostlybond then
                local bond = owner.components.ghostlybond
                if bond.externalbondtimemultipliers and bond.bondlevel then
                    local scale = bond.externalbondtimemultipliers:Get()
                    if scale > 0 then
                        if bond.maxbondlevel and bond.bondlevel < bond.maxbondlevel and bond.bondleveltimer and bond.bondlevelmaxtime then
                            local time = math.floor((bond.bondlevelmaxtime - bond.bondleveltimer) / scale)
                            inst.components.hoverer2hm.hoverStr = string.format(TUNING.util2hm.GetLanguage("等级:%s 升级剩余:%s", "Level:%s Upgrade Last:%s"),
                                tostring(bond.bondlevel), TUNING.util2hm.GetTime(time))
                        else
                            inst.components.hoverer2hm.hoverStr = string.format(TUNING.util2hm.GetLanguage("等级:%s", "Level:%s"),
                                tostring(bond.bondlevel))
                        end
                    else
                        inst.components.hoverer2hm.hoverStr = string.format(TUNING.util2hm.GetLanguage("等级:%s", "Level:%s"),
                                tostring(bond.bondlevel))
                    end
                end
            end
        end
    end

    local function ondropped(inst)
        inst.components.hoverer2hm.hoverStr = ""
        if inst.doUpdateHoverTask then
            inst.doUpdateHoverTask:Cancel()
            inst.doUpdateHoverTask = nil
        end
    end

    local function onputininventory(inst)
        ondropped(inst)
        inst.doUpdateHoverTask = inst:DoPeriodicTask(1, UpdateHoverStr)
        UpdateHoverStr(inst)
    end

    AddPrefabPostInit("abigail_flower", function(inst)
        if not TheWorld.ismastersim then return end
        inst:AddComponent("hoverer2hm")
        inst:ListenForEvent("onputininventory", onputininventory)
        inst:ListenForEvent("ondropped", ondropped)
    end)
end

-- 修复骨灰罐重载失效bug
local function IsFullOfFlowers(inst)
	return inst.components.container ~= nil and inst.components.container:IsFull()
end

local function updatesisturn(inst)
    if inst:HasTag("burnt") then return end
    local is_full = IsFullOfFlowers(inst)
    TheWorld:PushEvent("ms_updatesisturnstate", {inst = inst, is_active = is_full})
    local is_blossom = false
    if inst:getsisturnfeel() == "BLOSSOM" then
        is_blossom = true
    end
    TheWorld:PushEvent("onsisturnstatechanged", {is_active = is_full, is_blossom=is_blossom})
end

AddPrefabPostInit("sisturn", function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("ms_updatesisturnstate2hm", function(world) updatesisturn(inst) end, TheWorld)
end)

AddPrefabPostInit("wendy", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function()
        TheWorld:PushEvent("ms_updatesisturnstate2hm")
    end)
end)
