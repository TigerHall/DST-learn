-----------------------------------------------------------------------
--              天体后裔（Yefeng版本）影子系统 必须加强！最终boss！
--              alterguardian_phase4_lunarrift Shadow System
-----------------------------------------------------------------------
-- 天体后裔四阶段影子系统（独立AI + 实时技能同步）
local brainYf = require("brains/alterguardian_phase4_lunarriftbrainYf")
local Upvaluehelper = require("upvaluehacker2hm")

-----------------------------------------------------------------------
-- 修复：天体后裔裂隙崩溃问题
-----------------------------------------------------------------------
if TheNet:GetIsServer() then
	local WagBossUtil = require("prefabs/wagboss_util")
	local old_OnRemoveFissure = Upvaluehelper.GetUpvalue(WagBossUtil.DespawnFissure, "OnRemoveFissure")
	if old_OnRemoveFissure then
		local OnRemoveFissure = function(fissure, ...)
			local FISSURES =  Upvaluehelper.GetLocal(1, "FISSURES")-- 直接这样好像就行了  -- 之前这么写有点蠢 Upvaluehelper.GetUpvalue(WagBossUtil.DespawnFissure, "OnRemoveFissure", "FISSURES")
			if not FISSURES then return end
			old_OnRemoveFissure(fissure, ...)
		end
		Upvaluehelper.SetUpvalue(WagBossUtil.DespawnFissure, OnRemoveFissure, "OnRemoveFissure")
	end
end

-- 天体后裔电网特效自动清除
AddPrefabPostInit("alterguardian_lunar_fissures", function(inst)
	if not TheWorld.ismastersim then return end
	inst:DoTaskInTime(10, function(inst)
		if inst:IsValid() then
			inst:KillFx()
		end
	end)
end)

-----------------------------------------------------------------------
-- 影子专用状态图修改
----------------------------------------------------------------------
local function IsShadow(inst)
	return inst:HasTag("swc2hm")
end

-- 修改死亡状态：影子直接消失
AddStategraphPostInit("SGalterguardian_phase4_lunarrift", function(sg)
	if sg.states.death then
		local original_death_onenter = sg.states.death.onenter
		sg.states.death.onenter = function(inst, ...)
			if IsShadow(inst) then
				inst:Remove()
				return
			end
			if original_death_onenter then
				original_death_onenter(inst, ...)
			end
		end
	end
end)

-- 技能阶段设置（仅设置解锁参数，不重置计数器）
local function SetPhaseSkillsUnlock(target, healthpct)
	if healthpct <= 0.65 then
		target.dashcombo, target.dashrnd, target.dashcenter = 2, true, true
		target.slamcombo, target.slamrnd, target.cansupernova = 2, true, true
	elseif healthpct <= 0.75 then
		target.dashcombo, target.dashcenter = 2, false
		target.slamcombo, target.slamrnd, target.cansupernova = 1, false, false
	elseif healthpct <= 0.95 then
		target.dashcombo, target.dashrnd, target.dashcenter = 2, false, false
		target.slamcombo, target.slamrnd, target.cansupernova = 1, false, false
	else
		target.dashcombo, target.dashrnd, target.dashcenter = 1, false, false
		target.slamcombo, target.slamrnd, target.cansupernova = nil, false, false
	end
	
	if target.dashcount == nil then target.dashcount = 0 end
	if target.slamcombo and target.slamcount == nil then target.slamcount = 0 end
end

-- 同步所有影子的技能解锁参数
local function SyncAllShadowsPhase(inst)
	if not (inst.components.childspawner2hm and inst.components.health) then return end
	
	local healthpct = inst.components.health:GetPercent()
	if inst.components.childspawner2hm.childrenoutside then
		for k, child in pairs(inst.components.childspawner2hm.childrenoutside) do
			if child and child:IsValid() and child:HasTag("swc2hm") then
				SetPhaseSkillsUnlock(child, healthpct)
			end
		end
	end
end

-- 影子初始化
local function swc2hmfn(child)
	local inst = child.swp2hm
	child:SetBrain(brainYf)
	
	-- 延迟设置血量和可攻击性（确保shadowworld初始化完成）
	child:DoTaskInTime(0.1, function(child)
		local parent = child.swp2hm
		if not child:IsValid() or not parent or not parent:IsValid() then return end
		
		if child.components.health and parent.components.health then
			if child.components.health.invincible then
				child.components.health:SetInvincible(false)
			end
			
			local max_health = parent.components.health.maxhealth
			if max_health and max_health > 0 then
				child.components.health:SetMaxHealth(max_health)
				child.components.health:SetPercent(1.0)
			end
			
			if child:HasTag("notarget") then child:RemoveTag("notarget") end
			if child:HasTag("NOCLICK") then child:RemoveTag("NOCLICK") end
		end
	end)
	
	-- 移除影子自己的healthtrigger（技能由本体血量控制）
	if child.components.healthtrigger then
		child:RemoveComponent("healthtrigger")
	end

	-- 初始化技能参数
	if inst and inst:IsValid() and inst.components.health then
		local healthpct = inst.components.health:GetPercent()
		SetPhaseSkillsUnlock(child, healthpct)
		child.dashcount = 0
		if child.slamcombo then child.slamcount = 0 end
	end
	
	-- 裂隙生成所需
	if not child._temptbl1 then child._temptbl1 = {} end
	if not child._temptbl2 then child._temptbl2 = {} end
	
	-- 必要组件
	if not child.components.timer then child:AddComponent("timer") end
	if not child.components.grouptargeter and inst and inst.components.grouptargeter then
		child:AddComponent("grouptargeter")
	end
	
	-- 复制本体技能函数
	if inst and inst:IsValid() then
		if not child.ResetCombo and inst.ResetCombo then child.ResetCombo = inst.ResetCombo end
		if not child.IsSlamNext and inst.IsSlamNext then child.IsSlamNext = inst.IsSlamNext end
		if not child.SwitchToEightFaced and inst.SwitchToEightFaced then child.SwitchToEightFaced = inst.SwitchToEightFaced end
		if not child.SwitchToFourFaced and inst.SwitchToFourFaced then child.SwitchToFourFaced = inst.SwitchToFourFaced end
		if not child.SwitchToNoFaced and inst.SwitchToNoFaced then child.SwitchToNoFaced = inst.SwitchToNoFaced end
		if not child.SwitchToTwoFaced and inst.SwitchToTwoFaced then child.SwitchToTwoFaced = inst.SwitchToTwoFaced end
		if child.aggrodist == nil and inst.aggrodist then child.aggrodist = inst.aggrodist end
	end
	
	if child.threatlevel == nil then child.threatlevel = 1 end
	if child.SetEngaged then child:SetEngaged(true) end
	child.engaged = true
	child.persists = false
end

-- 本体配置
AddPrefabPostInit("alterguardian_phase4_lunarrift", function(inst)
	if not TheWorld.ismastersim then return end
	
	inst.swc2hmfn = swc2hmfn
	
	-- 监听血量变化并同步影子
	local last_synced_health = nil
	inst:ListenForEvent("healthdelta", function(inst, data)
		if not inst.components.health then return end
		
		local current_health = inst.components.health:GetPercent()
		local health_thresholds = {0.95, 0.75, 0.65}
		local should_sync = last_synced_health == nil
		
		if not should_sync then
			for _, threshold in ipairs(health_thresholds) do
				if (last_synced_health > threshold and current_health <= threshold) or
				   (last_synced_health <= threshold and current_health > threshold) then
					should_sync = true
					break
				end
			end
		end
		
		if should_sync then
			inst:DoTaskInTime(0.1, function(inst)
				if inst:IsValid() and inst.components.health then
					SyncAllShadowsPhase(inst)
					last_synced_health = inst.components.health:GetPercent()
				end
			end)
		end
	end)
	
	-- 初始化同步
	inst:DoTaskInTime(0, function(inst)
		if inst:IsValid() and inst.components.health then
			last_synced_health = inst.components.health:GetPercent()
			SyncAllShadowsPhase(inst)
		end
	end)
	
	-- 影子生成时同步
	if inst.components.childspawner2hm then
		local old_onspawn = inst.components.childspawner2hm.onspawnfn
		inst.components.childspawner2hm.onspawnfn = function(inst, child, ...)
			if old_onspawn then old_onspawn(inst, child, ...) end
			if child and child:IsValid() and child:HasTag("swc2hm") and inst.components.health then
				local healthpct = inst.components.health:GetPercent()
				SetPhaseSkillsUnlock(child, healthpct)
				if child.dashcount == nil then child.dashcount = 0 end
				if child.slamcombo and child.slamcount == nil then child.slamcount = 0 end
			end
		end
	end
end)
