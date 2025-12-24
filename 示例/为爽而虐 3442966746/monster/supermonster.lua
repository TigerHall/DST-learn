-- =================================================================================
-- 精英概率配置 -- 默认7.5%
local chance = GetModConfigData and GetModConfigData("supermonster") or 0.075

-- 可否成为精英
local function CanBeElite(inst)
	return inst.AnimState
		and inst.components
		and inst.components.health ~= nil
		and inst.components.health.maxhealth > 1
		and inst.components.combat ~= nil
		and inst.components.combat.defaultdamage > 0
		and not (
			inst:HasTag("player")
			or inst:HasTag("shadow")
			or inst:HasTag("companion")
			or inst:HasTag("shadowminion")
			or inst:HasTag("shadowcreature")
			or inst:HasTag("nightmarecreature")
			or inst:HasTag("shadowchesspiece")
			or inst:HasTag("abigail")
			or inst:HasTag("swc2hm")  -- 排除暗影分身
		)
		and (
			not (inst:HasTag("epic") or inst:HasTag("shadowchesspiece") or inst:HasTag("crabking"))
			or inst.components.health.maxhealth < 3500
		)
end

-- =================================================================================
-- 属性精英

-- 黑名单
BLACKNAMELIST_2HM_ATTR = {
	ivy_snare = true,
	winona_catapult = true,
	crabking_claw = true,
	gestalt_guard = true,
	wagdrone_rolling = true,  -- 螨地爬
}

-- 红：命中点燃
local function Attr_Red_OnHit(inst, data)
	local t = data and data.target
	if t ~= nil and t:IsValid() and t.components and t.components.burnable ~= nil then
		-- 乘骑中不触发
		if not (inst.components.rideable and inst.components.rideable:IsBeingRidden()) then
			t.components.burnable:Ignite(nil, inst)
		end
	end
end

-- 蓝：命中冰冻，冷却12s
local function _BlueCooldown(inst) inst._attrblue_cd = nil end
local function Attr_Blue_OnHit(inst, data)
	local t = data and data.target
	if t ~= nil and t:IsValid() and t.components and t.components.freezable ~= nil and inst._attrblue_cd == nil then
		if not (inst.components.rideable and inst.components.rideable:IsBeingRidden()) then
			inst._attrblue_cd = inst:DoTaskInTime(12, _BlueCooldown)
			t.components.freezable:AddColdness(4)
			t.components.freezable:SpawnShatterFX()
		end
	end
end

-- 紫：命中减速并添加特效fx，12s移除
local function _Purple_EndSlow(target)
	target._attrpurple_task = nil
	if target._attrpurple_fx ~= nil then
		target._attrpurple_fx:KillFX()
		target._attrpurple_fx = nil
	end
	if target.components and target.components.locomotor ~= nil then
		target.components.locomotor:RemoveExternalSpeedMultiplier(target, "attrpurple")
	end
end
local function Attr_Purple_OnHit(inst, data)
	local t = data and data.target
	if t ~= nil and t:IsValid() and t.components and t.components.locomotor ~= nil and t.entity then
		if not (inst.components.rideable and inst.components.rideable:IsBeingRidden()) then
			if t._attrpurple_task ~= nil then
				t._attrpurple_task:Cancel()
			else
				local fx = SpawnPrefab("shadow_trap_debuff_fx")
				if fx ~= nil then
					fx.entity:SetParent(t.entity)
					fx:OnSetTarget(t)
				end
				t._attrpurple_fx = fx
			end
			t._attrpurple_task = t:DoTaskInTime(12, _Purple_EndSlow)
			t.components.locomotor:SetExternalSpeedMultiplier(t, "attrpurple", 0.5)
		end
	end
end

-- 黄：电击（与WX78电击逻辑一致），短CD
local function _YellowCooldown(inst) inst._attryellow_cd = nil end
local function Attr_Yellow_OnHit(inst, data)
	if (data ~= nil and data.target ~= nil and not data.redirected) and inst._attryellow_cd == nil then
		if not (inst.components.rideable and inst.components.rideable:IsBeingRidden()) then
			inst._attryellow_cd = inst:DoTaskInTime(0.3, _YellowCooldown)
			local tgt = data.target
			if tgt.components.combat ~= nil and (tgt.components.health ~= nil and not tgt.components.health:IsDead()) and
				(tgt.components.inventory == nil or not tgt.components.inventory:IsInsulated()) and
				(data.weapon == nil or (data.weapon.components.projectile == nil and (data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil))) then
				SpawnPrefab("electrichitsparks"):AlignToTarget(tgt, inst, true)
				local damage_mult = 1
				if not (tgt:HasTag("electricdamageimmune") or (tgt.components.inventory ~= nil and tgt.components.inventory:IsInsulated())) then
					damage_mult = TUNING.ELECTRIC_DAMAGE_MULT
					local wetness_mult = (tgt.components.moisture ~= nil and tgt.components.moisture:GetMoisturePercent()) or (tgt:GetIsWet() and 1) or 0
					damage_mult = damage_mult + wetness_mult
				end
				tgt.components.combat:GetAttacked(inst, damage_mult * TUNING.WX78_TASERDAMAGE, nil, "electric")
			elseif tgt.components.inventory and tgt.components.inventory.equipslots then
				for _, v in pairs(tgt.components.inventory.equipslots) do
					if v and v.components.equippable:IsInsulated() then
						if v.components.fueled then v.components.fueled:DoDelta(-60, inst) end
						if v.components.finiteuses then v.components.finiteuses:Use(1) end
						if v.components.armor then v.components.armor:TakeDamage(10) end
						break
					end
				end
			end
		end
	end
end

-- 橙：击退（利用knockback事件）并降低受击伤害
local function _OrangeCooldown(inst) inst._attrorange_cd = nil end
local function Attr_Orange_OnHit(inst, data)
	local tgt = data and data.target
	if tgt ~= nil and tgt:IsValid() and inst._attrorange_cd == nil then
		if not (inst.components.rideable and inst.components.rideable:IsBeingRidden()) then
			inst._attrorange_cd = inst:DoTaskInTime(0.3, _OrangeCooldown)
			tgt:PushEvent("knockback", {
				knocker = inst,
				radius = 3,
				strengthmult = (tgt.components.inventory ~= nil and tgt.components.inventory:ArmorHasTag("heavyarmor") or tgt:HasTag("heavybody")) and 0.35 or 0.7,
				forcelanded = false,
			})
		end
	end
end

-- 彩虹：隐身/显形
local function _Iridescent_Hide(inst)
	if not inst:IsValid() then return end
	if not inst._attririd_hidden then
		local fx = SpawnPrefab("crab_king_shine")
		if fx ~= nil then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
		inst:Hide()
		if inst.DynamicShadow then inst.DynamicShadow:Enable(false) end
		inst._attririd_hidden = true
	end
	if inst._attririd_delayhide then inst._attririd_delayhide:Cancel() end
	inst._attririd_delayhide = nil
end
local function _Iridescent_Show(inst)
	if inst._attririd_hidden then
		inst:Show()
		if inst.DynamicShadow then inst.DynamicShadow:Enable(true) end
		inst._attririd_hidden = nil
	end
	if inst._attririd_delayhide then inst._attririd_delayhide:Cancel() end
	if inst._attririd_delayshow then inst._attririd_delayshow:Cancel() end
	inst._attririd_delayhide, inst._attririd_delayshow = nil, nil
end
local function _Iridescent_DelayHide(inst, t)
	if inst._attririd_delayhide then inst._attririd_delayhide:Cancel() end
	inst._attririd_delayhide = inst:DoTaskInTime(t, _Iridescent_Hide)
end
local function _Iridescent_DelayShow(inst, t)
	if inst._attririd_delayshow then inst._attririd_delayshow:Cancel() end
	inst._attririd_delayshow = inst:DoTaskInTime(t, _Iridescent_Show)
end
local function _Iridescent_OnNewTarget(inst, data)
	if not inst._attririd_hidden and not (data and data.oldtarget) then
		_Iridescent_DelayHide(inst, 0.75)
		_Iridescent_DelayShow(inst, 3.75)
	end
end
local function _Iridescent_OnAttack(inst)
	_Iridescent_Show(inst)
	_Iridescent_DelayHide(inst, 3)
	_Iridescent_DelayShow(inst, 6)
end
local function _Iridescent_OnAttacked(inst)
	if inst._attririd_cd == nil then
		inst._attririd_cd = inst:DoTaskInTime(3, function() inst._attririd_cd = nil end)
		_Iridescent_DelayHide(inst, 0.15)
		_Iridescent_DelayShow(inst, 3.15)
	end
end

-- 绿色：持续掉血（带特效），死亡时孢子云
local function _Green_ShowFx(inst)
	local fx = SpawnPrefab("ghostlyelixir_speed_dripfx")
	if fx ~= nil then
		fx.Transform:SetScale(.5, .5, .5)
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end
local function _Green_Tick(inst, src)
	if inst.components.health and not inst.components.health:IsDead() then
		local delta = -math.clamp(inst.components.health.maxhealth / 100, 1, 10)
		inst.components.health:DoDelta(delta, nil, src)
		_Green_ShowFx(inst)
	end
	inst._attrgreen_idx = (inst._attrgreen_idx or 0) + 1
	if inst._attrgreen_idx >= 10 and inst._attrgreen_task then
		inst._attrgreen_task:Cancel(); inst._attrgreen_task = nil; inst._attrgreen_idx = nil
	end
end
local function Attr_Green_OnHit(inst, data)
	local t = data and data.target
	if t and t.components and t.components.health then
		t._attrgreen_idx = 0
		if t._attrgreen_task == nil then
			t._attrgreen_task = t:DoPeriodicTask(1, _Green_Tick, 0.25, inst.nameoverride or inst.prefab or "NIL")
		end
	end
end
local function Attr_Green_OnDeath(inst)
	local fx = SpawnPrefab("sporecloud")
	if fx ~= nil then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
end

-- 猴子特殊：取消噩梦变身并复原贴图
local function _Monkey_Tweak(inst)
	if inst.has_nightmare_state then inst.has_nightmare_state = false end
	if inst.prefab == "monkey" then
		if type(SetOnSave) == "function" then
			SetOnSave(inst, function(_inst, data) data.nightmare = nil end)
		end
		if inst.components.timer then inst.components.timer:StartTimer("forcenightmare", 1000, true) end
		if inst:HasTag("nightmare") and inst.AnimState then
			inst.AnimState:SetBuild("kiki_basic")
			inst.soundtype = ""
			inst.AnimState:SetMultColour(1, 1, 1, 1)
		end
	end
end

-- 应用属性颜色函数映射
local ATTR_APPLIERS = {
	red = function(inst)
		SetAnimColor2hm(inst, "red")
		inst:ListenForEvent("onhitother", Attr_Red_OnHit)
	end,
	blue = function(inst)
		SetAnimColor2hm(inst, "blue")
		inst:ListenForEvent("onhitother", Attr_Blue_OnHit)
	end,
	green = function(inst)
		SetAnimColor2hm(inst, "green")
		inst:ListenForEvent("onhitother", Attr_Green_OnHit)
		inst:ListenForEvent("death", Attr_Green_OnDeath)
	end,
	yellow = function(inst)
		SetAnimColor2hm(inst, "yellow")
		inst:ListenForEvent("onhitother", Attr_Yellow_OnHit)
	end,
	orange = function(inst)
		SetAnimColor2hm(inst, "orange")
		inst:ListenForEvent("onhitother", Attr_Orange_OnHit)
		if inst.components and inst.components.combat then
			inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.33, "attr_orange")
		end
	end,
	purple = function(inst)
		SetAnimColor2hm(inst, "purple")
		inst:ListenForEvent("onhitother", Attr_Purple_OnHit)
	end,
	iridescent = function(inst)
		SetAnimColor2hm(inst, "iridescent")
		inst:ListenForEvent("newcombattarget", _Iridescent_OnNewTarget)
		inst:ListenForEvent("doattack", _Iridescent_OnAttack)
		inst:ListenForEvent("attacked", _Iridescent_OnAttacked)
		inst:ListenForEvent("death", _Iridescent_Show)
		if inst.components and inst.components.combat then
			inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.75, "attr_iridescent")
		end
		if inst.components and inst.components.locomotor then
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "attr_iridescent", 1.5)
		end
	end,
}

-- 颜色键集合
local ATTR_KEYS = { "red", "blue", "green", "yellow", "orange", "purple", "iridescent" }

-- 应用属性精英
local function ApplyColorElite(inst)
	if inst == nil or not inst:IsValid() then return end
	if not CanBeElite(inst) then return end
	if BLACKNAMELIST_2HM_ATTR[inst.prefab] then return end

	if not (inst.components and inst.components.persistent2hm) then
		inst:AddComponent("persistent2hm")
	end
	local pdata = inst.components.persistent2hm.data

	-- 无法成为精英
	if pdata.notsupermonster then return end

	-- 若未决定是否成为属性精英，按概率决定
	if pdata.supermonster == nil then
		if not inst:IsInLimbo() and math.random() < chance then
			pdata.supermonster = true
		else
			pdata.notsupermonster = true
			return
		end
	end

	-- 若未选择颜色，随机一种
	if pdata.super == nil then
		pdata.super = ATTR_KEYS[math.random(#ATTR_KEYS)]
	end

	-- 避免重复应用
	if pdata.attr_applied2hm then return end

	local applier = ATTR_APPLIERS[pdata.super]
	if applier then
		_Monkey_Tweak(inst)
		applier(inst)
		pdata.attr_applied2hm = true
	end
end


-- =================================================================================
-- 远程精英

-- AOE弹药优化，过滤同类/友军
local SpDamageUtil = require("components/spdamageutil")
local AOE_TARGET_MUST_TAGS  = { "_combat", "_health" }
local AOE_TARGET_CANT_TAGS  = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "companion", "wall" }
local AOE_TARGET_CANT_TAGS_PVP = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost" }

local function DoAOEDamage_Safe(inst, attacker, target, damage, radius)
	local combat = attacker ~= nil and attacker.components and attacker.components.combat or nil
	if combat == nil or target == nil or not target:IsValid() then return end

	local x, y, z = target.Transform:GetWorldPosition()
	local old_ignore = combat.ignorehitrange
	combat.ignorehitrange = true

	for _, v in ipairs(TheSim:FindEntities(x, y, z, radius + 4, AOE_TARGET_MUST_TAGS, TheNet:GetPVPEnabled() and AOE_TARGET_CANT_TAGS_PVP or AOE_TARGET_CANT_TAGS)) do
		if v ~= target
			and v.prefab ~= attacker.prefab
			and combat:CanTarget(v)
			and v.components.combat ~= nil
			and v.components.combat:CanBeAttacked(attacker)
			and not combat:IsAlly(v)
			and not (
				(v:HasTag("merm") and attacker:HasTag("merm"))
				or (v:HasTag("pig") and attacker:HasTag("pig"))
				or (v:HasTag("beefalo") and attacker:HasTag("beefalo"))
				or ((v:HasTag("spider") or v:HasTag("spiderden")) and attacker:HasTag("spider"))
				or ((v:HasTag("bee") or v:HasTag("beehive")) and attacker:HasTag("bee"))
				or ((v:HasTag("otter") or v:HasTag("wet")) and attacker:HasTag("otter"))
				or (v:HasTag("chess") and attacker:HasTag("chess"))
				or ((v:HasTag("hound") or v:HasTag("houndmound")) and attacker:HasTag("hound"))
				or (v:HasTag("koalefant") and attacker:HasTag("koalefant"))
				or (v:HasTag("explosive") and attacker:HasTag("explosive"))
				or (v:HasTag("pirate") and attacker:HasTag("pirate"))
				or (v:HasTag("crabking_ally") and attacker:HasTag("crabking_ally"))
				or (v:HasTag("walrus") and attacker:HasTag("walrus"))
				or (v:HasTag("frog") and attacker:HasTag("frog"))
				or (v:HasTag("lightninggoat") and attacker:HasTag("lightninggoat"))
				or (v:HasTag("worm") and attacker:HasTag("worm"))
				or (v:HasTag("bat") and attacker:HasTag("bat"))
				or (attacker.components.follower and attacker.components.follower.leader and attacker.components.follower.leader == v)
				or (v.components.follower and v.components.follower.leader and v.components.follower.leader == attacker)
				or (attacker:HasTag("player") and v.components.follower and v.components.follower.leader and v.components.follower.leader:HasTag("player"))
				or (attacker.components.follower and attacker.components.follower.leader and attacker.components.follower.leader:HasTag("player") and v:HasTag("player"))
			) then
			local rr = radius + v:GetPhysicsRadius(0) + 1
			if v:GetDistanceSqToPoint(x, y, z) < rr * rr then
				local spdmg = SpDamageUtil.CollectSpDamage(inst)
				v.components.combat:GetAttacked(attacker, damage, inst, inst.components and inst.components.projectile and inst.components.projectile.stimuli, spdmg)
			end
		end
	end

	combat.ignorehitrange = old_ignore
end

-- 恶液弹 gelblob
local function NoAggro(attacker, target)
	local tt = target.components.combat ~= nil and target.components.combat.target or nil
	return tt ~= nil and tt:IsValid() and tt ~= attacker and attacker ~= nil and attacker:IsValid()
		and (GetTime() - target.components.combat.lastwasattackedbytargettime) < 4
		and (tt.components.health ~= nil and not tt.components.health:IsDead())
end

local function TrySpawnGelBlob(target)
	local x, y, z = target.Transform:GetWorldPosition()
	if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
		local blob = SpawnPrefab("gelblob_small_fx")
		if blob ~= nil then
			blob.Transform:SetPosition(x, 0, z)
			blob:SetLifespan(TUNING.SLINGSHOT_AMMO_GELBLOB_DURATION)
			blob:ReleaseFromAmmoAfflicted()
		end
		return blob
	elseif TheWorld.has_ocean then
		SpawnPrefab("ocean_splash_ripple"..tostring(math.random(2))).Transform:SetPosition(x, 0, z)
	end
end

local function OnRemoveTarget_GelBlob(target)
	local data = target._slingshot_gelblob
	if data and data.blob and data.blob:IsValid() then
		data.blob:KillFX()
		data.blob = nil
	end
end

local function OnUpdate_GelBlob(target)
	local data = target._slingshot_gelblob
	if data == nil then return end
	local elapsed = GetTime() - (data.t0 or 0)
	local dur = target:HasTag("player") and 5 or TUNING.SLINGSHOT_AMMO_GELBLOB_DURATION

	if elapsed < dur then
		if data.blob then
			if not data.blob:IsValid() then
				data.blob = nil
				data.wasafflicted = false
			elseif data.start or (data.wasafflicted and data.blob._targets[target] == nil) then
				data.blob:KillFX(true)
				data.blob = nil
				data.wasafflicted = false
			end
		end
		if data.blob == nil then
			data.blob = TrySpawnGelBlob(target)
		end
		if not data.wasafflicted and data.blob and data.blob._targets[target] then
			data.wasafflicted = true
		end
		data.start = nil
	else
		if data.blob then
			data.blob:KillFX(true)
			data.blob = nil
		end
		target:PushEvent("stop_gelblob_ammo_afflicted")
		if data.task then data.task:Cancel() end
		target:RemoveTag("gelblob_ammo_afflicted")
		target:RemoveEventCallback("onremove", OnRemoveTarget_GelBlob)
		target._slingshot_gelblob = nil
	end
end

local function OnHit_GelBlob(inst, attacker, target)
	if target and target:IsValid() then
		local pushstart
		if target._slingshot_gelblob then
			if target._slingshot_gelblob.task then target._slingshot_gelblob.task:Cancel() end
		else
			target._slingshot_gelblob = {}
			target:AddTag("gelblob_ammo_afflicted")
			target:ListenForEvent("onremove", OnRemoveTarget_GelBlob)
			pushstart = true
		end
		local data = target._slingshot_gelblob
		data.start = true
		data.t0 = GetTime()
		data.task = target:DoPeriodicTask(0, OnUpdate_GelBlob, 0.43)

		if not NoAggro(attacker, target) and target.components.combat then
			target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
		end

		if pushstart and target:IsValid() then
			target:PushEvent("start_gelblob_ammo_afflicted")
		end
	end
end

-- 蜂刺弹，玻璃弹 stinger、moonglass：对周围单位造成AOE
local function OnHit_Stinger(inst, attacker, target)
	DoAOEDamage_Safe(inst, attacker, target, TUNING.SLINGSHOT_AMMO_DAMAGE_STINGER_AOE, TUNING.SLINGSHOT_AMMO_RANGE_STINGER_AOE)
end

local function OnHit_MoonGlass(inst, attacker, target)
	DoAOEDamage_Safe(inst, attacker, target, TUNING.SLINGSHOT_AMMO_DAMAGE_MOONGLASS_AOE, TUNING.SLINGSHOT_AMMO_RANGE_MOONGLASS_AOE)
end

-- 火药弹 gunpowder：暴击时爆炸并AOE
local function _GunpowderTimeout(target)
	target._slingshot_gunpowder = nil
end

local function OnHit_Gunpowder(inst, attacker, target)
	if target._slingshot_gunpowder == nil then
		target._slingshot_gunpowder = {
			chance = TUNING.SLINGSHOT_AMMO_GUNPOWDER_DUST_TRIGGER_CHANCE_RATE,
			task = target:DoTaskInTime(TUNING.SLINGSHOT_AMMO_GUNPOWDER_DUST_TIMEOUT, _GunpowderTimeout),
		}
	else
		target._slingshot_gunpowder.chance = target._slingshot_gunpowder.chance + TUNING.SLINGSHOT_AMMO_GUNPOWDER_DUST_TRIGGER_CHANCE_RATE
		target._slingshot_gunpowder.task:Cancel()
		target._slingshot_gunpowder.task = target:DoTaskInTime(TUNING.SLINGSHOT_AMMO_GUNPOWDER_DUST_TIMEOUT, _GunpowderTimeout)
	end

	if inst._crithit then
		local fx = SpawnPrefab("slingshotammo_gunpowder_explode")
		if fx ~= nil then fx.Transform:SetPosition(target.Transform:GetWorldPosition()) end

		for _, v in ipairs(AllPlayers) do
			local distSq = v:GetDistanceSqToInst(target)
			local k = math.max(0, math.min(1, distSq / 400))
			local intensity = k * 0.75 * (k - 2) + 0.75
			if intensity > 0 then
				v:ShakeCamera(CAMERASHAKE.FULL, 1.05, .03, intensity / 2)
			end
		end

		local aoe_damage = (inst.ammo_def and inst.ammo_def.damage)
			or (inst.components and inst.components.weapon and inst.components.weapon.damage)
			or 10
		DoAOEDamage_Safe(inst, attacker, target, aoe_damage, TUNING.SLINGSHOT_AMMO_RANGE_GUNPOWDER_DUST_AOE)

		target._slingshot_gunpowder.task:Cancel()
		target._slingshot_gunpowder = nil
		inst.noimpactfx = true
	end
end

-- 绑定到具体弹药预制体
AddPrefabPostInit("slingshotammo_gelblob_proj", function(inst)
	if not TheWorld.ismastersim then return end
	inst.ammo_def.onhit = OnHit_GelBlob
end)

AddPrefabPostInit("slingshotammo_stinger_proj", function(inst)
	if not TheWorld.ismastersim then return end
	inst.ammo_def.onhit = OnHit_Stinger
end)

AddPrefabPostInit("slingshotammo_moonglass_proj", function(inst)
	if not TheWorld.ismastersim then return end
	inst.ammo_def.onhit = OnHit_MoonGlass
end)

AddPrefabPostInit("slingshotammo_gunpowder_proj", function(inst)
	if not TheWorld.ismastersim then return end
	inst.ammo_def.onhit = OnHit_Gunpowder
end)

-- =================================================================================
-- 远程精英，给怪物分配远程武器

-- 限制某些单位保持原攻击距离，如主教和远程狗
local RANGE_LIMIT_PREFABS = { sporehound = true, knook = true }

-- 远程武器定义表
local RANGE_WEAPON_DEFS = {
	bishop_charge = { proj = "bishop_charge", attackrange = TUNING.BISHOP_ATTACK_DIST, hitrange = TUNING.BISHOP_ATTACK_DIST + 4, size = 0.35 },
	eye_charge    = { proj = "eye_charge",    attackrange = TUNING.EYETURRET_RANGE,     hitrange = TUNING.EYETURRET_RANGE + 4,     size = 0.35 },

	spider_web_spit = { proj = "spider_web_spit", attackrange = TUNING.SPIDER_SPITTER_ATTACK_RANGE, hitrange = TUNING.SPIDER_SPITTER_ATTACK_RANGE + 4 },

	fire_projectile = { proj = "fire_projectile", attackrange = 8, hitrange = 10, onattack = true, super = "red" },
	ice_projectile  = { proj = "ice_projectile",  attackrange = 8, hitrange = 10, onattack = true },

	blowdart_walrus = { proj = "blowdart_walrus", attackrange = TUNING.WALRUS_ATTACK_DIST, hitrange = nil },
	blowdart_sleep  = { proj = "blowdart_sleep",  attackrange = 8, hitrange = 10, onattack = true },
	blowdart_fire   = { proj = "blowdart_fire",   attackrange = 8, hitrange = 10, onattack = true, super = "red" },
	blowdart_pipe   = { proj = "blowdart_pipe",   attackrange = 8, hitrange = 10 },
	blowdart_yellow = { proj = "blowdart_yellow", attackrange = 8, hitrange = 10, electric = true, onattack = true },

	-- slingshot basic rocks etc（这些在弹药 onhit 已处理特效/aoe，这里仅提供抛射）
	slingshotammo_rock_proj      = { proj = "slingshotammo_rock_proj",      attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_gold_proj      = { proj = "slingshotammo_gold_proj",      attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_marble_proj    = { proj = "slingshotammo_marble_proj",    attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_poop_proj      = { proj = "slingshotammo_poop_proj",      attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_freeze_proj    = { proj = "slingshotammo_freeze_proj",    attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_slow_proj      = { proj = "slingshotammo_slow_proj",      attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_thulecite_proj = { proj = "slingshotammo_thulecite_proj", attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_gelblob_proj   = { proj = "slingshotammo_gelblob_proj",   attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_scrapfeather_proj = { proj = "slingshotammo_scrapfeather_proj", attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX, electric = true },
	slingshotammo_gunpowder_proj = { proj = "slingshotammo_gunpowder_proj", attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_honey_proj     = { proj = "slingshotammo_honey_proj",     attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_stinger_proj   = { proj = "slingshotammo_stinger_proj",   attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
	slingshotammo_moonglass_proj = { proj = "slingshotammo_moonglass_proj", attackrange = TUNING.SLINGSHOT_DISTANCE, hitrange = TUNING.SLINGSHOT_DISTANCE_MAX },
}

-- 黑名单
BLACKNAMELIST_2HM_RANGE = {
	waterplant = true,
	ivy_snare = true,
	rook = true,
	rook_nightmare = true,
	winona_catapult = true,
	crabking_claw = true,
	sandspike_short = true,
	sandspike_med = true,
	sandspike_tall = true,
	sandblock = true,
	gestalt_guard = true,
	wagdrone_rolling = true,  -- 螨地爬
}

-- onattack补丁 ，用于部分弹丸在发射时的特效/处理
local ONATTACK_PROJ = {}
ONATTACK_PROJ.fire_projectile = function(inst, attacker, target)
	if attacker and attacker:IsValid() and attacker.SoundEmitter then
		attacker.SoundEmitter:PlaySound(inst.skin_sound or "dontstarve/wilson/fireball_explo")
	end
	if target and target:IsValid() and target.components then
		if target.components.burnable and not target.components.burnable:IsBurning() then
			if target.components.freezable and target.components.freezable:IsFrozen() then
				target.components.freezable:Unfreeze()
			elseif (not target.components.fueled)
				or (target.components.fueled.fueltype ~= FUELTYPE.BURNABLE and target.components.fueled.secondaryfueltype ~= FUELTYPE.BURNABLE) then
				if (target.components.burnable.canlight or target.components.combat) then
					target.components.burnable:Ignite(true, attacker and attacker:IsValid() and attacker or inst)
				end
			elseif target.components.fueled.accepting then
				local fuel = SpawnPrefab("cutgrass")
				if fuel ~= nil then
					if fuel.components.fuel ~= nil and fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
						target.components.fueled:TakeFuelItem(fuel)
					else
						fuel:Remove()
					end
				end
			end
		end
		if target.components.freezable then
			target.components.freezable:AddColdness(-1)
			if target.components.freezable:IsFrozen() then target.components.freezable:Unfreeze() end
		end
		if target.components.sleeper and target.components.sleeper:IsAsleep() then target.components.sleeper:WakeUp() end
	end
end

ONATTACK_PROJ.ice_projectile = function(inst, attacker, target)
	if inst.skin_sound and attacker and attacker.SoundEmitter then
		attacker.SoundEmitter:PlaySound(inst.skin_sound)
	end
	if target and target:IsValid() then
		if target.components.sleeper and target.components.sleeper:IsAsleep() then target.components.sleeper:WakeUp() end
		if target.components.burnable then
			if target.components.burnable:IsBurning() then
				target.components.burnable:Extinguish()
			elseif target.components.burnable:IsSmoldering() then
				target.components.burnable:SmotherSmolder()
			end
		end
		if target.components.freezable then
			target.components.freezable:AddColdness(target:HasTag("player") and 1 or 0.5)
			target.components.freezable:SpawnShatterFX()
		end
	end
end

ONATTACK_PROJ.blowdart_yellow = function(inst, attacker, target)
	if target and target:IsValid() then SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker or inst, true) end
end

ONATTACK_PROJ.blowdart_sleep = function(inst, attacker, target)
	if not target or not target:IsValid() then return end
	if target.SoundEmitter ~= nil then target.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_impact_sleep") end
	local mount = target.components.rider ~= nil and target.components.rider:GetMount() or nil
	if mount ~= nil then mount:PushEvent("ridersleep", {sleepiness = 4, sleeptime = 6}) end
	if target.components.sleeper ~= nil then
		target.components.sleeper:AddSleepiness(1, 6, inst)
	elseif target.components.grogginess ~= nil then
		target.components.grogginess:AddGrogginess(1, 6)
	end
end

ONATTACK_PROJ.blowdart_fire = function(inst, attacker, target)
	if not target or not target:IsValid() then return end
	if target.SoundEmitter ~= nil then target.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_impact_fire") end
	if target.components.burnable then target.components.burnable:Ignite(nil, attacker) end
	if target.components.freezable then target.components.freezable:Unfreeze() end
	if target.components.health then target.components.health:DoFireDamage(0, attacker) end
end

-- =================================================================================
-- 远程精英特效与防拾取

-- 远程精英特效管理
local function OnNearRangeMonster(inst)
	if inst.followfx2hm or inst:IsAsleep() or inst:IsInLimbo() then return end
	if inst.components.health and inst.components.health:IsDead() then return end
	local fx = SpawnPrefab(inst.rangeweapondata2hm and inst.rangeweapondata2hm.fx or "lighterfire_haunteddoll")
	if fx ~= nil then
		fx:AddTag("bluecolour2hm")
		fx.entity:SetParent(inst.entity)
		if inst.fxfollow2hm then
			fx.entity:AddFollower():FollowSymbol(inst.GUID, inst.fxfollow2hm, inst.fxfollowoffset2hm.x, inst.fxfollowoffset2hm.y, inst.fxfollowoffset2hm.z)
		else
			inst:AddChild(fx)
		end
		if fx.AttachLightTo then fx:AttachLightTo(inst) end
		inst.followfx2hm = fx
	end
end

local function OnFarRangeMonster(inst)
	if inst.followfx2hm then
		inst.followfx2hm:Remove()
		inst.followfx2hm = nil
	end
end

local function DropAndHit(inst)
	if inst.components.inventoryitem then
		local owner = inst.components.inventoryitem:GetGrandOwner()
		if owner and owner:IsValid() then
			local x, y, z = owner.Transform:GetWorldPosition()
			inst.components.inventoryitem:RemoveFromOwner(true)
			inst.components.inventoryitem:DoDropPhysics(x, y, z, true)
			if not (inst.components.follower and inst.components.follower.leader == owner) then
				owner:PushEvent("attacked", {attacker = inst, damage = 0})
			end
		end
	end
end

local function DropAndHitDelay(inst)
	inst:DoTaskInTime(0, DropAndHit)
	inst:DoTaskInTime(0.3, DropAndHit)
end

-- 给单位创建一次性远程武器
local function EnsureRangedWeapon(inst, weapondata)
	if inst.superweapon2hm and inst.superweapon2hm:IsValid() then
		return inst.superweapon2hm
	end
	local weapon = CreateEntity()
	weapon.persists = false
	weapon.entity:AddTransform()
	weapon.entity:SetParent(inst.entity)
	weapon:RemoveFromScene()
	weapon:AddComponent("inventoryitem")
	weapon.components.inventoryitem.owner = inst
	weapon:AddComponent("weapon")

	weapon.projectilemissremove2hm = true
	weapon.projectileneedstartpos2hm = true
	weapon.projectilehasdamageset2hm = 0.5
	weapon.projectilespeed2hm = weapondata.speed or 20
	weapon.projectilehoming2hm = false
	weapon.projectilephysics2hm = false
	weapon.projectilesize2hm = weapondata.size

	weapon.components.weapon:SetProjectile(weapondata.proj)
	if weapondata.onattack and ONATTACK_PROJ[weapondata.proj] then
		weapon.components.weapon:SetOnAttack(ONATTACK_PROJ[weapondata.proj])
	end
	if weapondata.electric then
		weapon.components.weapon:SetElectric()
	end

	local base = inst.components and inst.components.combat and inst.components.combat.defaultdamage or 10
	local dmg = math.max((inst.weaponitems and base * 1.5) or (base * 2/3), 10)
	weapon.components.weapon:SetDamage(dmg)

	if RANGE_LIMIT_PREFABS[inst.prefab] then
		weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.hitrange)
	else
		weapon.components.weapon:SetRange(weapondata.attackrange or inst.components.combat.attackrange,
										  weapondata.hitrange  or inst.components.combat.hitrange)
	end

	if inst.prefab == "monkey" and inst.HasAmmo then
		inst.HasAmmo = truefn
	end

	if inst.weaponitems then
		for k in pairs(inst.weaponitems) do inst.weaponitems[k] = weapon end
	end

	inst.superweapon2hm = weapon
	return weapon
end

-- 分配&应用远程武器
local function ApplyRangedElite(inst)
	if not inst or not inst:IsValid() then return end
	if not CanBeElite(inst) then return end
	if BLACKNAMELIST_2HM_RANGE[inst.prefab] then return end
	if not (inst.components and inst.components.combat) then return end

	if not (inst.components and inst.components.persistent2hm) then
		inst:AddComponent("persistent2hm")
	end
	local pdata = inst.components.persistent2hm.data
    -- 无法成为远程精英
	if pdata.notrangemonster then return end
    -- 避免重复应用
	if pdata.range_applied2hm then return end

	-- 装备/已有武器
	if (inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)) or inst.weapon or inst.weaponitems then
		pdata.notrangemonster = true
		return
	end

	-- 按概率决定是否成为远程精英
	if pdata.rangemonster == nil then
		if not inst:IsInLimbo() and math.random() < chance then
			pdata.rangemonster = true
		else
			pdata.notrangemonster = true
			return
		end
	end

	-- 选择或回用武器配置，仅存储键名
	if not pdata.rangeweapon_key then
		local keys = {}
		for k, _ in pairs(RANGE_WEAPON_DEFS) do keys[#keys+1] = k end
		pdata.rangeweapon_key = keys[math.random(#keys)]
	end
	local wdef = RANGE_WEAPON_DEFS[pdata.rangeweapon_key]
	if not wdef then return end

	-- 确保 combat:GetWeapon 返回我们的临时武器
	local combat = inst.components.combat
	if combat and combat.GetWeapon then
		local old_GetWeapon = combat.GetWeapon
		combat.GetWeapon = function(self)
			-- 若已有有效 superweapon2hm 则直接返回
			return EnsureRangedWeapon(inst, wdef)
		end
	end

	-- 保存武器数据用于特效
	inst.rangeweapondata2hm = wdef

	-- 获取特效跟随位置
	local fxfollow = combat.hiteffectsymbol
	local offset = Vector3(0, 0, 0)
	if fxfollow == "marker" then
		if inst.components.burnable and inst.components.burnable.fxdata and inst.components.burnable.fxdata[1] and inst.components.burnable.fxdata[1].follow ~= nil then
			fxfollow = inst.components.burnable.fxdata[1].follow
			offset = Vector3(inst.components.burnable.fxdata[1].x, inst.components.burnable.fxdata[1].y, inst.components.burnable.fxdata[1].z)
		elseif inst.components.freezable and inst.components.freezable.fxdata and inst.components.freezable.fxdata[1] and inst.components.freezable.fxdata[1].follow ~= nil then
			fxfollow = inst.components.freezable.fxdata[1].follow
			offset = Vector3(inst.components.freezable.fxdata[1].x, inst.components.freezable.fxdata[1].y, inst.components.freezable.fxdata[1].z)
		else
			fxfollow = nil
		end
	end
	inst.fxfollow2hm = fxfollow
	inst.fxfollowoffset2hm = offset

	-- 无法放入物品栏（slurper 例外）
	if inst.prefab ~= "slurper" then
		DropAndHitDelay(inst)
		inst:ListenForEvent("onputininventory", DropAndHitDelay)
		inst:ListenForEvent("onpickup", DropAndHitDelay)
	end

	-- 远程特效
	inst:DoTaskInTime(0, OnNearRangeMonster)
	inst:ListenForEvent("entitywake", OnNearRangeMonster)
	inst:ListenForEvent("exitlimbo", OnNearRangeMonster)

	-- 移除特效
	inst:ListenForEvent("entitysleep", OnFarRangeMonster)
	inst:ListenForEvent("enterlimbo", OnFarRangeMonster)
	inst:ListenForEvent("death", OnFarRangeMonster)
	inst:ListenForEvent("onremove", OnFarRangeMonster)

	-- 远程精英无法被虫网捕捉
	if inst.components.workable and ACTIONS and ACTIONS.NET and inst.components.workable.action == ACTIONS.NET then
		inst.components.workable.action = nil
	end

	pdata.range_applied2hm = true

	-- 若远程武器指定了属性颜色，且属性尚未应用，则同步应用颜色属性
	if wdef.super and not pdata.attr_applied2hm then
		pdata.supermonster = true
		pdata.super = wdef.super
		ApplyColorElite(inst)
	end
end

-- 发射体节奏调整
AddPrefabPostInit("bishop_charge", function(inst) if inst.AnimState then inst.AnimState:SetDeltaTimeMultiplier(.5) end end)
AddPrefabPostInit("eye_charge",    function(inst) if inst.AnimState then inst.AnimState:SetDeltaTimeMultiplier(.5) end end)

-- 远程精英特效光源颜色调整
local function UpdateFxColour(inst)
	if inst:HasTag("bluecolour2hm") and inst._light and inst._light.Light then
		inst._light.Light:SetColour(0, 183 / 255, 1)
	end
end
AddPrefabPostInit("lighterfire_haunteddoll", function(inst)
	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, UpdateFxColour)
	end
end)

-- =================================================================================
-- 统一管理所有精英怪

local function ProcessAllElites(inst)
	inst.supermonstertask2hm = nil
	ApplyRangedElite(inst)
	ApplyColorElite(inst)
end

-- 桥接陷阱捕捉的怪物数据
local function SetTrapData(inst)
	return { persistent2hm = inst.components.persistent2hm and inst.components.persistent2hm.data or nil }
end

local function RestoreDataFromTrap(inst, data)
	if data ~= nil and data.persistent2hm ~= nil then
		if not (inst.components and inst.components.persistent2hm) then
			inst:AddComponent("persistent2hm")
		end
		inst.components.persistent2hm.data = data.persistent2hm
		if inst.supermonstertask2hm then inst.supermonstertask2hm:Cancel() end
		inst.supermonstertask2hm = inst:DoTaskInTime(0, ProcessAllElites)
	end
end

-- 初始化所有精英怪物（属性精英 + 远程精英）
AddPrefabPostInitAny(function(inst)
	if not TheWorld.ismastersim then return end
	if not CanBeElite(inst) then return end

	if not (inst.components and inst.components.persistent2hm) then
		inst:AddComponent("persistent2hm")
	end

	if inst.components.inventoryitem ~= nil and inst.components.inventoryitem.trappable then
		if not inst.restoredatafromtrap then inst.restoredatafromtrap = RestoreDataFromTrap end
		if not inst.settrapdata then inst.settrapdata = SetTrapData end
	end

	local pdata = inst.components.persistent2hm and inst.components.persistent2hm.data or {}
	if not (pdata.attr_applied2hm or pdata.range_applied2hm) then
		if inst.supermonstertask2hm then inst.supermonstertask2hm:Cancel() end
		inst.supermonstertask2hm = inst:DoTaskInTime(0, ProcessAllElites)
	end
end)