--------让小鸭子变旋风时，大小不会被重置，前置准备。
AddPrefabPostInit("mossling", function(inst)
    if inst.components.sizetweener then
        local sizetweener = inst.components.sizetweener
        sizetweener.OnUpdate = function(self, dt)
            local my_size = self.inst.myscale or 1
            self.timepassed = self.timepassed + dt
            if self.timepassed >= self.time then
                self:EndTween()
            elseif self.t_size ~= nil and self.i_size ~= nil then
                local s = Lerp(self.i_size, self.t_size, self.timepassed / self.time)
                self.inst.Transform:SetScale(s * my_size, s * my_size, s * my_size)
            end
        end
        local old = sizetweener.EndTween
        sizetweener.EndTween = function(self)
            old(self)
            if self.inst.myscale ~= nil then
                local Scale = self.inst.Transform:GetScale()
                self.inst.Transform:SetScale(Scale * self.inst.myscale, Scale * self.inst.myscale, Scale * self.inst.myscale)
            end
        end
    end
end)
-- -----------修改组件，重置大小时应该加什么属性
-- AddComponentPostInit("scaler", function(self)
--     local old_ApplyScale = self.ApplyScale
--     function self:ApplyScale()
--         old_ApplyScale(self)
--         local inst = self.inst
--         if inst.myscale ~= nil then
--             local Rand = inst.myscale
--             local Scale = inst.Transform:GetScale()
--             inst.Transform:SetScale(Scale * Rand, Scale * Rand, Scale * Rand)

--             if inst.components.health ~= nil then
--                 local percent = inst.components.health:GetPercent()
--                 inst.components.health:SetMaxHealth(math.ceil(inst.components.health.maxhealth * Rand))
--                 inst.components.health:SetPercent(percent)
--             end

--             if inst.components.combat then inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * Rand) end

--         end
--     end
-- end)
------修改小牛的判断
local tendencies =
			{
				DEFAULT =
				{
				},

				ORNERY =
				{
					build = "beefalo_personality_ornery",
					build_short = "_ornery",
				},

				RIDER =
				{
					build = "beefalo_personality_docile",
					build_short = "_docile",
				},

				PUDGY =
				{
					build = "beefalo_personality_pudgy",
					build_short = "_pudgy",
					customactivatefn = function(inst)
						inst:AddComponent("sanityaura")
						inst.components.sanityaura.aura = TUNING.SANITYAURA_TINY
					end,
					customdeactivatefn = function(inst)
						inst:RemoveComponent("sanityaura")
					end,
				},
			}
AddPrefabPostInit("beefalo", function(inst)
	if not TheWorld.ismastersim then return end
	inst:ListenForEvent("resetdamagePG", function() -- 更新牛牛数据
		if inst.myscale and inst.components.combat and inst.tendency then
			inst.components.combat.defaultdamage = TUNING.BEEFALO_DAMAGE[inst.tendency]
			if inst.myscale < 1 and inst.myscale > 0 then
				inst.myscale = math.min(inst.myscale, 2)
				inst.components.combat.defaultdamage = math.ceil(TUNING.BEEFALO_DAMAGE[inst.tendency] * inst.myscale)
			end
		end
	end)
	inst.SetTendency = function(inst, changedomestication, ...) -- 给官方设置牛攻击力函数新加条件
		local tendencychanged = false
		local oldtendency = inst.tendency
		if not inst.components.domesticatable:IsDomesticated() then
			local tendencysum = 0
			local maxtendency = nil
			local maxtendencyval = 0
			for k, v in pairs(inst.components.domesticatable.tendencies) do
				tendencysum = tendencysum + v
				if v > maxtendencyval then
					maxtendencyval = v
					maxtendency = k
				end
			end
			inst.tendency = (tendencysum < .1 or maxtendencyval * 2 < tendencysum) and TENDENCY.DEFAULT or maxtendency
			tendencychanged = inst.tendency ~= oldtendency
		end

		if changedomestication == "domestication" then
			if tendencies[inst.tendency].customactivatefn ~= nil then
				tendencies[inst.tendency].customactivatefn(inst)
			end
		elseif changedomestication == "feral"
			and tendencies[oldtendency].customdeactivatefn ~= nil then
			tendencies[oldtendency].customdeactivatefn(inst)
		end

		if tendencychanged or changedomestication ~= nil then
			if inst.components.domesticatable:IsDomesticated() then
				inst.components.domesticatable:SetMinObedience(TUNING.BEEFALO_MIN_DOMESTICATED_OBEDIENCE[inst.tendency])
				inst:PushEvent("resetdamagePG")
				if inst.qianghuayici == nil then --  随机大小属性给牛牛强化过则不覆盖原版伤害
					inst.components.combat:SetDefaultDamage(TUNING.BEEFALO_DAMAGE[inst.tendency])
				end
				inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED[inst.tendency]
			else
				inst.components.domesticatable:SetMinObedience(0)

				if  inst.qianghuayici == nil then  --  随机大小属性给牛牛强化过则不覆盖原版伤害
					inst.components.combat:SetDefaultDamage(TUNING.BEEFALO_DAMAGE.DEFAULT)
				end
				inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT
			end

			inst:ApplyBuildOverrides(inst.AnimState)
			if inst.components.rideable and inst.components.rideable:GetRider() ~= nil then
				inst:ApplyBuildOverrides(inst.components.rideable:GetRider().AnimState)
			end
		end
	end
end)

-----主代码，用来随机生物大小
local function getrandomscale(inst)
    if inst.myscale then return inst.myscale end
    -- 为爽改动:有一个明显的大小过度来辨别双倍掉落了;0.5625~1.26;1.145
    -- 血量单位4.3%概率在1.35~2倍,95.6%的概率在0.75~1.3倍;大于1.35倍双倍掉落
    -- 没有血量单位10%概率1.5倍,90%概率在0.75~1.2倍;大于1.3倍双倍掉落
    if inst:HasTag("_health") then
        local chance = math.random(1150)
        if chance > 1100 then return 1.4 + (chance - 1100) / 50 * 0.6 end
        return chance / 2000 + 0.75
    else
        local chance = math.random()
        return chance > 0.9 and 1.5 or (chance * 0.5 + 0.75)
    end
end
local function qianghua(inst, myscale, loot)
    if inst ~= nil and inst.qianghuayici == nil and inst.ray_busuijidaxiao and inst.ray_busuijidaxiao == 1 then
        inst.qianghuayici = 1 ---不允许在不重载的情况下，执行两次。
        local Rand = inst.myscale or myscale
        local sx, sy, sz = inst.Transform:GetScale()
        if not (sx and sy and sz) then return end -------无法获取就无法缩小，代码终止。
        local scaleRand = Rand > 1 and ((Rand - 1) / 2 + 1) or Rand
        inst.Transform:SetScale(sx * scaleRand, sy * scaleRand, sz * scaleRand)
        -- Scale+Scale*0.1*Rand
        ------下面则更改属性。
        if inst.components.aura and Rand > 1 then inst.components.aura.radius = inst.components.aura.radius * Rand end
        -------更改血量
        if inst.components.health ~= nil and not inst.myscalehealth2hm then
            local percent = inst.components.health:GetPercent()
            inst.components.health:SetMaxHealth(math.ceil(inst.components.health.maxhealth * Rand))
            inst.components.health:SetPercent(percent)
            inst.myscalehealth2hm = true
        end
        if inst.components.combat then
            -- -- 看不懂这段代码
            -- inst.components.combat.hitrange = inst.components.combat.hitrange + 0.1 * Rand * inst.components.combat.hitrange
            -- inst.components.combat.attackrange = inst.components.combat.attackrange + 0.1 * Rand * inst.components.combat.attackrange
            inst.components.combat.hitrange = inst.components.combat.hitrange * Rand
            inst.components.combat.attackrange = inst.components.combat.attackrange * Rand
            -----更改攻击力
            if inst.components.domesticatable ~= nil and inst.components.domesticatable:IsDomesticated() then Rand = math.min(Rand, 2) end
			if inst.prefab == "beefalo" and inst.components.domesticatable ~= nil and inst.components.domesticatable:IsDomesticated() then Rand = math.min(Rand, 2)  --处理已经被驯化的牛改变毛发的牛的攻击倍率
				if inst.tendency then
					inst.components.combat.defaultdamage = TUNING.BEEFALO_DAMAGE[inst.tendency]
					if Rand < 1 and Rand > 0 then  -- 小体型则保留倍率
					   inst.components.combat.defaultdamage = math.ceil(TUNING.BEEFALO_DAMAGE[inst.tendency] * Rand)
					end
				end
			elseif inst.prefab == "beefalo" and inst.components.domesticatable ~= nil and not inst.components.domesticatable:IsDomesticated() then Rand = math.min(Rand, 2) --处理野生的牛群攻击力
				if inst.components.domesticatable.domestication and inst.components.domesticatable.domestication >= 0.1 then -- 削弱玩家正在驯化的牛牛攻击倍率
					if Rand > 0 and Rand < 1 then -- 小体型则保留倍率
					   inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * Rand)
					end
				else --野生牛牛则保留原有攻击倍率
					inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * Rand)
				end
			else -- 其他生物正常执行倍率加伤
			inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * Rand)
			end
        end
        -- 更改掉落
        if Rand > 1.3 then
            if loot and not inst:HasTag("structure") and not inst:HasTag("swc2hm") then ----更改目标战利品
                -- 为爽改动:大于1.35/1.25倍大的生物才双倍掉落,便于明显区分
                if inst.components.lootdropper ~= nil then
                    local DropLoot = inst.components.lootdropper.DropLoot
                    inst.components.lootdropper.DropLoot = function(self, ...)
                        DropLoot(self, ...)
                        return DropLoot(self, ...)
                    end
                    if inst.prefab == "rock_ice" then
                        local SpawnLootPrefab = inst.components.lootdropper.SpawnLootPrefab
                        inst.components.lootdropper.SpawnLootPrefab = function(self, ...)
                            SpawnLootPrefab(self, ...)
                            return SpawnLootPrefab(self, ...)
                        end
                    end
                end
                if inst.prefab == "tumbleweed" and inst.loot ~= nil and next(inst.loot) then
                    local newloot = {}
                    for i, v in ipairs(inst.loot) do table.insert(newloot, v) end
                    for i, v in ipairs(newloot) do table.insert(inst.loot, v) end
                end
            end

            -- 为爽改动:有trader组件的单位采集倍率不能改变
            if inst.components.pickable and not inst.components.trader then ----更改目标采集组件
                inst.components.pickable.numtoharvest = inst.components.pickable.numtoharvest * 2
            end
        end
        inst.myscale = Rand
    end
end

local function saveandload(inst) ----保存与载入，主要是保存生物的各种数据已贴图
    local oldsave = inst.OnSave
    inst.OnSave = function(inst, data)
        if oldsave ~= nil then oldsave(inst, data) end
        data.ray_busuijidaxiao = inst.ray_busuijidaxiao
        data.ray_nars2hm = inst.ray_nars2hm
        if inst.myscale ~= nil then data.myscale = inst.myscale end
    end

    local oldload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if oldload ~= nil then oldload(inst, data) end
        if data and data.ray_busuijidaxiao ~= nil then inst.ray_busuijidaxiao = data.ray_busuijidaxiao end
        -- 为爽改动:感染性继承
        if data and data.ray_nars2hm ~= nil then
            inst.ray_nars2hm = data.ray_nars2hm
            if inst.ray_nars2hm then inst:AddTag("ray_nars2hm") end
        end
        if data and data.myscale ~= nil then inst.myscale = data.myscale end
    end
    local old_OnPreLoad = inst.OnPreLoad
    inst.OnPreLoad = function(inst, data)
        if old_OnPreLoad ~= nil then old_OnPreLoad(inst, data) end
        if data and data.myscale and inst.components.health ~= nil then
            if not (data.health and data.health.maxhealth) then
                inst.components.health.maxhealth = math.ceil(inst.components.health.maxhealth * data.myscale)
                if data.health and data.health.health then inst.components.health:SetCurrentHealth(data.health.health) end
                inst.components.health:DoDelta(0)
            end
            inst.myscalehealth2hm = true
        end
    end
end

AddPrefabPostInitAny(function(inst)

    if inst ~= nil and inst.Transform and not inst:HasTag("player") and ---非玩家
    not inst:HasTag("structure") and ---非建筑
    not inst:HasTag("wall") and ---非墙
    not inst:HasTag("shadow") and ---非暗影
    not inst:HasTag("groundtile") and ---非地砖
    not inst:HasTag("molebait") and ---非分子
    not inst:HasTag("FX") and ---非特效
    not inst:HasTag("shadowminion") and ---非暗影生物
    not inst:HasTag("shadowcreature") and ---非暗影生物
    not inst:HasTag("epic") and ----非史诗生物。
    not inst:HasTag("shadowchesspiece") and ----非史诗生物。
    not inst:HasTag("crabking") and ----非史诗生物。
    not inst:HasTag("companion") and ----非同伴。
    not inst:HasTag("boat") and ----非船。
    -- not inst:HasTag("character") and ----非角色。
    not inst:HasTag("ghost") and ----非幽灵。
    not inst:HasTag("abigail") and ----非阿比盖尔。
    not inst.components.scaler and ----非石虾
    (inst:HasTag("_health") or inst:HasTag("boulder") or inst:HasTag("tree") or inst:HasTag("plant")) ---有生命值或石头或树木或植物。
    then

        if not TheWorld.ismastersim then ---接下来服务器执行
            return inst
        end

        inst:DoTaskInTime(0, function(inst, ...)

            -- if  not POPULATING then
            -- 为爽改动开头:玩家周围的单位不会改变大小,该单位周围的单位也不会改变大小
            if inst.ray_busuijidaxiao == nil then
                -- local f, g, b = inst.Transform:GetWorldPosition()
                -- local buyua = TheSim:FindEntities(f, g, b, 4, { "player" })
                -- 	if  #buyua < 1 and math.random(1,100) <= 80 then
                -- 		inst.ray_busuijidaxiao = 1
                -- 		else
                -- 		inst.ray_busuijidaxiao = 0
                -- 	end
                for i, v in ipairs(AllPlayers) do
                    if v:IsValid() and inst:IsNear(v, 4) then
                        inst.ray_busuijidaxiao = 0
                        inst.ray_nars2hm = true
                        inst:AddTag("ray_nars2hm")
                        break
                    end
                end
                if inst.ray_busuijidaxiao ~= 0 then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local norandomsizeitem = TheSim:FindEntities(x, y, z, 4, {"ray_nars2hm"})
                    if #norandomsizeitem < 1 and math.random() < 0.8 then
                        inst.ray_busuijidaxiao = 1
                    else
                        inst.ray_busuijidaxiao = 0
                    end
                end
                -- 为爽改动末尾
            end
            -- end

            if inst.ray_busuijidaxiao and inst.ray_busuijidaxiao == 1 then qianghua(inst, getrandomscale(inst), true) end

        end)
        saveandload(inst)
    end

end)

----------细节优化
AddPrefabPostInit("pigman", function(inst)
    if inst.components.werebeast then
        local old_onsetwerefn = inst.components.werebeast.onsetwerefn or function(...) end
        inst.components.werebeast.onsetwerefn = function(inst)
            old_onsetwerefn(inst)
            if inst.myscale ~= nil then

                if inst.components.health ~= nil then
                    if inst.components.health then
                        inst.components.health:SetMaxHealth(math.ceil(inst.components.health.maxhealth * inst.myscale))
                    end
                end

                if inst.components.combat then
                    inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * inst.myscale)
                end

            end
        end
        local old_onsetnormalfn = inst.components.werebeast.onsetnormalfn or function(...) end
        inst.components.werebeast.onsetnormalfn = function(inst)
            old_onsetnormalfn(inst)
            if inst.myscale ~= nil then

                if inst.components.health ~= nil then
                    if inst.components.health then
                        inst.components.health:SetMaxHealth(math.ceil(inst.components.health.maxhealth * inst.myscale))
                    end
                end

                if inst.components.combat then
                    inst.components.combat.defaultdamage = math.ceil(inst.components.combat.defaultdamage * inst.myscale)
                end

            end
        end
    end
end)

AddPrefabPostInit("spiderden", function(inst)
    if inst.components.upgradeable then
        local old = inst.components.upgradeable.SetStage
        inst.components.upgradeable.SetStage = function(self, num)
            old(self, num)
            if self.inst.myscale ~= nil and self.inst.components.health ~= nil then
                self.inst.components.health:SetMaxHealth(math.ceil(self.inst.components.health.maxhealth * self.inst.myscale))
            end
        end
    end
end)

-- 骑牛前后正常体型
local function onmounted(inst, data)
    if data and data.target ~= nil then
        local sx = data.target.Transform:GetScale()
        inst:ApplyScale("mounted", sx)
    end
end
local function ondismounted(inst, data) inst:ApplyScale("mounted", 1) end
local function playerpostInit(inst)
    if not TheWorld.ismastersim then return inst end
    inst:ListenForEvent("mounted", onmounted)
    inst:ListenForEvent("dismounted", ondismounted)
end
AddPlayerPostInit(playerpostInit)

-----------驯好的牛不退化---------------------------------------------
local function OnDomesticationDelta(inst, data)
    if inst.components.domesticatable:IsDomesticated() and data and data.new < 1 then inst.components.domesticatable:DeltaDomestication(1) end
end
AddPrefabPostInit("beefalo", function(inst) if TheWorld.ismastersim then inst:ListenForEvent("domesticationdelta", OnDomesticationDelta) end end)

-- ====重写打蜡的函数
require("prefabs/veggies")
if GLOBAL.VEGGIES ~= nil then
    for k, v in pairs(GLOBAL.VEGGIES) do
        AddPrefabPostInit(k .. "_oversized", function(inst)
            if inst.components.waxable then
                inst.components.waxable.waxfn = function(inst, doer)
                    local waxedveggie = SpawnPrefab(inst.prefab .. "_waxed")
                    if inst.myscale ~= nil then waxedveggie.myscale = inst.myscale end
                    if doer.components.inventory and doer.components.inventory:IsHeavyLifting() and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) ==
                        inst then
                        doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
                        doer.components.inventory:Equip(waxedveggie)
                    else
                        waxedveggie.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        waxedveggie.AnimState:PlayAnimation("wax_oversized", false)
                        waxedveggie.AnimState:PushAnimation("idle_oversized")
                    end
                    inst:Remove()
                    return true
                end
            end
            if inst.components.perishable then
                inst.components.perishable.perishfn = function(inst)
                    if inst.components.inventoryitem:GetGrandOwner() ~= nil then
                        local loots = {}
                        for i = 1, #inst.components.lootdropper.loot do table.insert(loots, "spoiled_food") end
                        inst.components.lootdropper:SetLoot(loots)
                        inst.components.lootdropper:DropLoot()
                    else
                        local rotten = SpawnPrefab(inst.prefab .. "_rotten")
                        if inst.myscale ~= nil then rotten.myscale = inst.myscale end
                        rotten.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                    inst:Remove()
                end
            end

        end)
    end
end

---给洞穴添加一个猎人组件，让洞穴会生成脚印
AddPrefabPostInit("cave", function(inst) if inst.ismastersim and inst.components.hunter == nil then inst:AddComponent("hunter") end end)

---让座狼和蠕虫 不会互相攻击
local function processworm(inst) if TheWorld.ismastersim and TheWorld:HasTag("cave") then inst:AddTag("warg") end end
AddPrefabPostInit("worm", processworm)
if TUNING.DSTU then
    AddPrefabPostInit("gatorsnake", processworm)
    AddPrefabPostInit("shockworm", processworm)
    AddPrefabPostInit("viperling", processworm)
    AddPrefabPostInit("viperworm", processworm)
end
AddPrefabPostInit("warg", function(inst) if TheWorld.ismastersim and TheWorld:HasTag("cave") then inst:AddTag("worm") end end)
