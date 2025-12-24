local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 芜猴开局可选
if GetModConfigData("Start With Wonkey Disable Transform") then
    TUNING.WONKEY_SANITY = TUNING.WILSON_SANITY
    -- 修复开局选择芜猴但角色会被服务器直接变为威尔逊的问题
    if SEAMLESSSWAP_CHARACTERLIST and table.contains(SEAMLESSSWAP_CHARACTERLIST, "wonkey") then
        for i, v in ipairs(SEAMLESSSWAP_CHARACTERLIST) do
            if v == "wonkey" then
                table.remove(SEAMLESSSWAP_CHARACTERLIST, i)
                break
            end
        end
    end
    -- 禁止诅咒饰品变身，但获得或失去诅咒饰品时仍会有僵直动作
    local curse_monkey = require("curse_monkey_util")
    curse_monkey.docurse = function(owner, num) owner:PushEvent("monkeycursehit", {uncurse = false}) end
    curse_monkey.uncurse = function(owner, num) owner:PushEvent("monkeycursehit", {uncurse = true}) end
    -- 修复芜猴死亡时变成威尔逊的问题
    AddStategraphPostInit("wilson", function(sg)
        -- 芜猴死亡时不变身回去
        local oldfn = sg.states.death.events.animover.fn
        sg.states.death.events.animover.fn = function(inst)
            local wonkeydeath = false
            if inst.prefab == "wonkey" then
                wonkeydeath = true
                inst:RemoveTag("wonkey")
            end
            oldfn(inst)
            if wonkeydeath then inst:AddTag("wonkey") end
        end
    end)
    -- 修复猴子女王不给芜猴图纸的问题
    AddStategraphPostInit("monkeyqueen", function(sg)
        local oldfn = sg.states.getitem.events.animover.fn
        sg.states.getitem.events.animover.fn = function(inst)
            local wonkeygiveitem = false
            local giver = inst.sg.statemem.giver
            if giver and giver.prefab == "wonkey" then
                wonkeygiveitem = true
                giver:RemoveTag("wonkey")
            end
            oldfn(inst)
            if wonkeygiveitem then giver:AddTag("wonkey") end
        end
    end)
end

-- 芜猴助跑时间缩短
local wonkeyrunwaittime = GetModConfigData("Wonkey Run Wait Time")
if wonkeyrunwaittime then
    TUNING.WONKEY_RUN_HUNGER_RATE_MULT = 0.5
    TUNING.WONKEY_TIME_TO_RUN = wonkeyrunwaittime
end

-- 芜猴攻击偷取物品
if GetModConfigData("Wonkey Attack Steal Item") then
    local function OnHitOther(inst, other, damage) inst.components.thief:StealItem(other) end
    AddPrefabPostInit("wonkey", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.thief then inst:AddComponent("thief") end
        if not inst.components.combat.onhitotherfn then inst.components.combat.onhitotherfn = OnHitOther end
    end)
    AddPrefabPostInit("boat_item", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.deployable then
            local ondeploy = inst.components.deployable.ondeploy
            inst.components.deployable.ondeploy = function(inst, pt, deployer, ...)
                if deployer and deployer.prefab == "wonkey" and inst.deploy_product == "boat" and inst.linked_skinname == nil and math.random() < 0.5 then
                    inst.deploy_product = "boat_pirate"
                end
                ondeploy(inst, pt, deployer, ...)
            end
        end
    end)
end

-- 芜猴右键自身召唤海棠小分队作战
if GetModConfigData("Wonkey Right Self summon the powder_monkey") then
	local cd1 = 120  -- 初始化cd
	local cd --技能使用后冷却的cd
	local HASSLER_SPAWN_DIST = PLAYER_CAMERA_SEE_DISTANCE

	local function GetSpawnPoint(pt)
		if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
			pt = FindNearbyLand(pt, 1) or pt
		end
		local offset = FindWalkableOffset(pt, math.random() * TWOPI, HASSLER_SPAWN_DIST, 12, true)
		if offset ~= nil then
			offset.x = offset.x + pt.x
			offset.z = offset.z + pt.z
			return offset
		end
	end
	
	local function on_ignite_over(inst)
    local fx, fy, fz = inst.Transform:GetWorldPosition()

    -------------------------------------------------------------
    -- Find talkers to say speech.
    for _, player in ipairs(AllPlayers) do
        if player._miniflareannouncedelay == nil and math.random() > TUNING.MINIFLARE.CHANCE_TO_NOTICE then
            local px, py, pz = player.Transform:GetWorldPosition()
            local sq_dist_to_flare = distsq(fx, fz, px, pz)
            if sq_dist_to_flare > TUNING.MINIFLARE.SPEECH_MIN_DISTANCE_SQ then
				player._miniflareannouncedelay = player:DoTaskInTime(TUNING.MINIFLARE.NEXT_NOTICE_DELAY, function(i) i._miniflareannouncedelay = nil end) -- so gross, if this logic gets any more complicated then make a component
                player.components.talker:Say(GetString(player, "ANNOUNCE_FLARE_SEEN"))
            end
        end
    end

    -------------------------------------------------------------
    -- Create an entity to cover the close-up minimap icon; the 'globalmapicon' doesn't cover this.
    local minimap = SpawnPrefab("miniflare_minimap")
    minimap.Transform:SetPosition(fx, fy, fz)
    minimap:DoTaskInTime(10, function()
        minimap:Remove()
    end)

    inst:Remove()
 end
	
	AddRightSelfAction("wonkey", 480, "dolongaction", nil, function(act)
		local fx, fy, fz = act.doer.Transform:GetWorldPosition()
		local newleader = act.doer
		local hunger = act.doer.components.hunger.current
		local spawn_pt = GetSpawnPoint(act.doer:GetPosition())
		
		if act.doer and act.doer.prefab == "wonkey"  and spawn_pt ~= nil and hunger >= 100 and act.doer.components.leader:CountFollowers("monkey") < 4 then
			local oldhunger = act.doer.components.hunger.current
			act.doer.components.hunger:SetCurrent(oldhunger - 90) -- 减少自身90饥饿值
			
			local miniflare = SpawnPrefab("miniflare") -- 发射一枚信号弹
			miniflare.Transform:SetPosition(fx, fy, fz)
			
			miniflare.persists = false
			miniflare.entity:SetCanSleep(false)

			miniflare.AnimState:PlayAnimation("fire")
			miniflare:ListenForEvent("animover", on_ignite_over)
			

			miniflare.SoundEmitter:PlaySound("turnoftides/common/together/miniflare/launch")
			
			act.doer:DoTaskInTime(15, function()
				spawn_pt = GetSpawnPoint(act.doer:GetPosition())
				for i = 1, 4, 1 do -- 生成火药猴
					local haitang1 = SpawnPrefab("powder_monkey_p")
					haitang1.components.inventory:Equip(SpawnPrefab("oar_monkey")) -- 给小分队成员战浆
					haitang1.Physics:Teleport(spawn_pt:Get())  -- 生成位置

					haitang1.components.follower:SetLeader(newleader) -- 设置跟随者
				end

				local haitang2 = SpawnPrefab("prime_mate_p")  -- 生成一只大副
				haitang2.Physics:Teleport(spawn_pt:Get())  -- 生成位置
				haitang2.components.inventory:Equip(SpawnPrefab("oar_monkey")) -- 给大副战浆
				
				haitang2.components.follower:SetLeader(newleader)  -- 设置跟随者
			end)
			return true
		elseif hunger < 100 or act.doer.components.leader:CountFollowers("monkey") >= 4 or spawn_pt == nil then
			return false
		end
	end, STRINGS.NAMES.MINIFLARE, nil, nil, function(act)
		if cd then
			return ( cd and cd <= 0 and TheWorld.has_ocean)
		end
	end)
	
	AddPrefabPostInit("wonkey", function(inst) 
			if not cd and cd1 then -- 初始化冷却(防止上下洞刷新技能)
			local task
				task = inst:DoPeriodicTask(1, function()
					cd1 = cd1 - 1
					
					if cd1 <= 0 then
						cd1 = 0
						cd = 0
						task:Cancel()
					end
				end)
			end

		local _OnDespawn = inst.OnDespawn
		inst.HTfollowers = {}

		inst.OnDespawn = function(inst, migrationdata, ...) -- 随从下洞以及带下线代码
			for k, v in pairs(inst.components.leader.followers) do
				if k:HasTag("monkey") then 
					local savedata = k:GetSaveRecord()
					table.insert(inst.HTfollowers, savedata)
					-- remove followers
					k:AddTag("notarget")
					k:AddTag("NOCLICK")
					k.persists = false
					if k.components.health then
						k.components.health:SetInvincible(true)
					end
					k:DoTaskInTime(math.random() * 0.2, function(k)
						local fx = SpawnPrefab("spawn_fx_small")
						fx.Transform:SetPosition(k.Transform:GetWorldPosition())
						if not k.components.colourtweener then
							k:AddComponent("colourtweener")
						end
						k.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * FRAMES, k.Remove)
					end)
				end
			end

			return _OnDespawn(inst, migrationdata, ...)
		end

		local _OnSave = inst.OnSave

		--[[inst.OnSave = function(inst, data, ...)
			data.HTfollowers = inst.HTfollowers
			data.cd = cd  -- 记录技能cd

			if _OnSave ~= nil then
				return _OnSave(inst, data, ...)
			end
		end--]]

		local _OnLoad = inst.OnLoad

		inst.OnLoad = function(inst, data, ...)
			if data and data.HTfollowers then
				for k, v in pairs(data.HTfollowers) do
					inst:DoTaskInTime(0.2 * math.random(), function(inst)
						local follower = SpawnSaveRecord(v)
						inst.components.leader:AddFollower(follower)
						follower:DoTaskInTime(0, function(follower)
							if inst:IsValid() and not follower:IsNear(inst, 8) then
								follower.Transform:SetPosition(
									inst.Transform:GetWorldPosition())
								follower.sg:GoToState("idle")
							end
						end)
						local fx = SpawnPrefab("spawn_fx_small")
						fx.Transform:SetPosition(
							follower.Transform:GetWorldPosition())
					end)
				end
			end
			--[[if data and data.cd then
				cd = data.cd
				cd1 = data.cd
				if cd and cd ~= 0 then -- 重新加载cd
					local task
					task = inst:DoPeriodicTask(1, function()
						cd = cd - 1
						
						if cd <= 0 then
							cd = 0
							task:Cancel()
						end
					end)
				end
			end--]]
			if _OnLoad ~= nil then 
				return _OnLoad(inst, data, ...) 
			end
		end
	end)
end

-- 芜猴夜视微光
if GetModConfigData("Wonkey Night Version") then
    local function enableplayervision(inst)
        inst:DoTaskInTime(0.25, function()
            if TheWorld:HasTag("cave") or TheWorld.state.isnight or TheWorld.state.isdusk then
                if TheWorld.ismastersim then
                    if not (inst._wonkeylight2hm and inst._wonkeylight2hm:IsValid()) then
                        inst._wonkeylight2hm = SpawnPrefab("deathcurselight2hm")
                    end
                    inst._wonkeylight2hm.entity:SetParent(inst.entity)
                    inst._wonkeylight2hm.Light:SetFalloff(0.4)
                    inst._wonkeylight2hm.Light:SetIntensity(.7)
                    inst._wonkeylight2hm.Light:SetRadius(0.5)
                    inst._wonkeylight2hm.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
                    inst._wonkeylight2hm.Light:Enable(true)
                end
                inst.components.playervision:ForceNightVision(true)
                inst.components.playervision:SetCustomCCTable(nil)
            else
                inst.components.playervision:ForceNightVision(false)
                inst.components.playervision:SetCustomCCTable(nil)
            end
        end)
    end
    AddPrefabPostInit("wonkey", function(inst)
        inst:AddTag("nightvision")
        if not inst.components.playervision then inst:AddComponent("playervision") end
        local oldOnLoad = inst.OnLoad or nilfn
        inst.OnLoad = function(...)
            oldOnLoad(...)
            enableplayervision(...)
        end
        local oldOnNewSpawn = inst.OnNewSpawn or nilfn
        inst.OnNewSpawn = function(...)
            oldOnNewSpawn(...)
            enableplayervision(...)
        end
        enableplayervision(inst)
        inst:WatchWorldState("phase", enableplayervision)
        inst:ListenForEvent("ms_respawnedfromghost", enableplayervision)
        if not TheWorld.ismastersim then return end
        inst.components.sanity.night_drain_mult = 0
    end)
end

if GetModConfigData("Wonkey Toss Poop") then
	local function SplashOceanPoop(poop)
		if not poop.components.inventoryitem:IsHeld() then
			local x, y, z = poop.Transform:GetWorldPosition()
			if not poop:IsOnValidGround() or TheWorld.Map:IsPointNearHole(Vector3(x, 0, z)) then
				SpawnPrefab("splash_ocean").Transform:SetPosition(x, y, z)
				poop:Remove()
			end
		end
	end
	local function SpawnPoop(inst, owner, target)
		local poop = SpawnPrefab("poop")
		poop.SoundEmitter:PlaySound("dontstarve/creatures/monkey/poopsplat")
		if target ~= nil and target:IsValid() then
			LaunchAt(poop, target, owner ~= nil and owner:IsValid() and owner or inst)
		else
			poop.Transform:SetPosition(inst.Transform:GetWorldPosition())
			if poop:IsAsleep() then
				SplashOceanPoop(poop)
			else
				poop:DoTaskInTime(8 * FRAMES, SplashOceanPoop)
			end
		end
	end
	AddPrefabPostInit("monkeyprojectile", function(inst)
		if not TheWorld.ismastersim then return end
		inst:DoTaskInTime(0, function() -- 延迟注册确保生效
			inst.components.projectile.onhit = function(inst, owner, target)
				 if target.components.sanity ~= nil then
					target.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
				end
				local chance = math.random()
				if chance < 0.3 then -- 0.3概率返还便便
				SpawnPoop(inst, owner, target)
				end
				target:PushEvent("attacked", { attacker = owner, damage = 0 })
				inst:Remove()
			end
		end)
	end)
    local function OnThrown(inst, attacker, target, proj)
        if proj and proj.components.projectile then proj.components.projectile.has_damage_set = true end
        if attacker and attacker.components.sanity ~= nil then attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY) end
        local item = inst
        if item.components.inventoryitem then item = item.components.inventoryitem:RemoveFromOwner() or item end
        item:RemoveFromScene()
        item.persists = false
        item:DoTaskInTime(3, item.Remove)
    end
    AddPrefabPostInit("poop", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.equippable and not inst.components.weapon then
            inst:AddTag("weapon")
            inst:AddTag("rangedweapon")
            inst:AddComponent("weapon")
            inst.components.weapon:SetDamage(34)
            inst.components.weapon:SetRange(TUNING.MONKEY_RANGED_RANGE)
            inst.components.weapon:SetProjectile("monkeyprojectile")
            inst.components.weapon:SetOnProjectileLaunched(OnThrown)
            inst:AddComponent("equippable")
            inst.components.equippable.equipstack = true
            inst.components.equippable.restrictedtag = "wonkey"
        end
        -- 便便不算鼠巢分
        if TUNING.DSTU then inst:AddTag("NORATCHECK") end
    end)
end

-- 芜湖消除诅咒
if GetModConfigData("Wonkey Remove Curse") then
    local function OnPickup(inst, data)
        local thing = data.item
        if inst:HasTag("wonkey") then
            if thing ~= nil and thing.prefab == "cursed_monkey_token" then
                inst.components.cursable:RemoveCurse("MONKEY", 9)
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.talker:Say(TUNING.isCh2hm and "不怕这个！哦咦" or "Not afraid of this! Oyiike")
                end)
            end
        end
    end
    
    -- local foodchance = {
    --     wormlight = 1.25, -- 发光浆果
    --     cave_banana = 1, -- 香蕉
    --     cave_banana_cooked = 0.75, -- 烤香蕉
    --     wormlight_lesser = 0.5, -- 小发光浆果
    --     berries = 0.5, -- 浆果
    --     berries_juicy = 0.5, -- 多汁浆果
    --     berries_cooked = 0.35, -- 烤浆果
    --     berries_juicy_cooked = 0.35 -- 烤多汁浆果
    --     -- carrot = 0.35, -- 胡萝卜
    --     -- red_cap = 0.35, -- 三色蘑菇
    --     -- blue_cap = 0.35,
    --     -- green_cap = 0.35
    -- }
    -- local function OnEat(inst, data)
    --     if data and data.food and data.food:IsValid() and not data.food:HasTag("spoiled") and foodchance[data.food.prefab] and math.random() <
    --         (data.food:HasTag("stale") and foodchance[data.food.prefab] * 2 / 3 or foodchance[data.food.prefab]) then
    --         local giver = data.feeder or inst
    --         if giver and giver:IsValid() and giver.components.inventory and giver.components.cursable and giver.components.cursable.curses and
    --             ((giver.components.cursable.curses.MONKEY or 0) > 0 or
    --                 giver.components.inventory:FindItem(function(item)
    --                     return item and item:IsValid() and item.prefab == "cursed_monkey_token"
    --                 end)) then
    --             giver.components.cursable:RemoveCurse("MONKEY", 1)
    --             local curseprop = SpawnPrefab("cursed_monkey_token_prop")
    --             curseprop:RemoveComponent("inventoryitem")
    --             curseprop:RemoveComponent("curseditem")
    --             curseprop.Transform:SetPosition(giver.Transform:GetWorldPosition())
    --             curseprop.target = giver
    --             if inst.SoundEmitter then inst.SoundEmitter:PlaySound("monkeyisland/monkeyqueen/remove_curse_success") end
    --             -- local item = SpawnPrefab("cursed_monkey_token")
    --             -- inst.components.inventory:GiveItem(item, nil, true)
    --         end
    --     end
    -- end
    AddPrefabPostInit("wonkey", function(inst)
        if not TheWorld.ismastersim then return end
        -- inst:ListenForEvent("oneat", OnEat)
        inst:ListenForEvent("itemget", OnPickup)
    end)
end

-- 沃托姆增强
if TUNING.DSTU and GetModConfigData("Wathom upgrade") then
    -- 禁用护甲伤害相关机制
    TUNING.DSTU.WATHOM_ARMOR_DAMAGE = false
    -- 激活状态受伤倍率降低
    TUNING.DSTU.WATHOM_AMPED_VULNERABILITY = TUNING.DSTU.WATHOM_AMPED_VULNERABILITY * 0.4
    -- 任何攻击都能额外获得肾上腺素
    AddPrefabPostInit("wathom", function(inst)
        local function OnAttackOther(inst, data)
            if inst.components.adrenaline then
                inst.components.adrenaline:DoDelta(1)
            end 
        end
        inst:ListenForEvent("onattackother", OnAttackOther)
    end)
end

-- 怪物角色获得夜视
if GetModConfigData("Monster_characters_night_vision") then
    local function enableplayervision(inst)
        inst:DoTaskInTime(0.25, function()
            if TheWorld:HasTag("cave") or TheWorld.state.isnight or TheWorld.state.isdusk then
                -- 使用 PushForcedNightVision 确保客户端也能正确同步夜视状态
                inst.components.playervision:PushForcedNightVision(inst)
            else
                -- 移除夜视效果
                inst.components.playervision:PopForcedNightVision(inst)
            end
        end)
    end
    
    -- 沃托姆仅在洞穴的远古区域才能获得夜视
    local function enablewathomvision(inst)
        inst:DoTaskInTime(0.25, function()
            -- 检查是否装备了夜视物品
            local hasNightVisionEquip = false
            if inst.replica and inst.replica.inventory then
                hasNightVisionEquip = inst.replica.inventory:EquipHasTag("nightvision")
            end
            
            -- 检查是否在洞穴世界
            if not TheWorld:HasTag("cave") then
                -- 不在洞穴时，只有在没有装备夜视物品的情况下才移除效果
                if not hasNightVisionEquip then
                    inst.components.playervision:PopForcedNightVision(inst)
                    inst:RemoveTag("nightvision")
                    -- 触发nightvision事件来移除查理攻击免疫
                    inst:PushEvent("nightvision", false)
                end
                return
            end
            
            local isInRuins = false
            if inst.components.areaaware then
                isInRuins = inst.components.areaaware:CurrentlyInTag("Nightmare")
            end
            
            if isInRuins then
                -- 没有装备夜视物品，使用强制夜视
                if not hasNightVisionEquip then
                    inst.components.playervision:PushForcedNightVision(inst)
                    inst:AddTag("nightvision")
                    inst:PushEvent("nightvision", true)
                end
            else
                -- 不在远古区域时，只有在没有装备夜视物品的情况下才移除效果  
                if not hasNightVisionEquip then
                    inst.components.playervision:PopForcedNightVision(inst)
                    inst:RemoveTag("nightvision")
                    inst:PushEvent("nightvision", false)
                end
            end
        end)
    end
    
    local function AddNightVisionToCharacter(prefab)
        AddPrefabPostInit(prefab, function(inst)
            inst:AddTag("nightvision")
            if not inst.components.playervision then 
                inst:AddComponent("playervision") 
            end
            
            local oldOnLoad = inst.OnLoad or function() end
            inst.OnLoad = function(inst, data, ...)
                oldOnLoad(inst, data, ...)
                enableplayervision(inst)
            end
            
            local oldOnNewSpawn = inst.OnNewSpawn or function() end
            inst.OnNewSpawn = function(inst, ...)
                oldOnNewSpawn(inst, ...)
                enableplayervision(inst)
            end
            
            enableplayervision(inst)
            inst:WatchWorldState("phase", enableplayervision)
            inst:ListenForEvent("ms_respawnedfromghost", enableplayervision)
            
            if not TheWorld.ismastersim then return end
            
            -- 夜视角色白天掉理智，夜晚不掉理智
            if inst.components.sanity then
                inst.components.sanity.night_drain_mult = 0
                
                -- 白天在地面时持续掉理智
                inst.components.sanity.custom_rate_fn = function(inst, dt)
                    
                    if TheWorld.state.isday and not TheWorld:HasTag("cave") and not inst.components.sanity.light_drain_immune then
                        return TUNING.SANITY_NIGHT_MID  -- 返回理智变化率，负值表示损失
                    end
                    return 0  -- 其他时间不额外影响理智
                end
            end
        end)
    end
    
    if TUNING.DSTU then    
        -- 沃托姆仅在洞穴的远古区域才能获得夜视
        AddPrefabPostInit("wathom", function(inst)
            if not inst.components.playervision then inst:AddComponent("playervision") end
            if not inst.components.areaaware then inst:AddComponent("areaaware") end
            
            -- 妥协特殊处理，禁用原本的光照检测以绕过妥协的监测
            inst.IsInLight = function(...) return true end
            inst.updatewathomvisiontask = 1 -- 覆盖妥协检测
            
            -- 重写grue组件的CheckForStart函数来实现区域性保护
            if inst.components.grue then
                local originalCheckForStart = inst.components.grue.CheckForStart
                inst.components.grue.CheckForStart = function(self)
                    local isInRuins = false
                    if inst.components.areaaware then
                        isInRuins = inst.components.areaaware:CurrentlyInTag("Nightmare")
                    end
                    
                    if TheWorld:HasTag("cave") and isInRuins then
                        return originalCheckForStart(self)
                    else
                        -- 在非远古区域时，强制返回true让查理可以攻击
                        return not (self.inst.components.health:IsInvincible() or
                                   self.inst.components.health:IsDead())
                    end
                end
            end
            
            local oldOnLoad = inst.OnLoad or function() end
            inst.OnLoad = function(inst, data, ...)
                oldOnLoad(inst, data, ...)
                enablewathomvision(inst)
            end
            
            local oldOnNewSpawn = inst.OnNewSpawn or function() end
            inst.OnNewSpawn = function(inst, ...)
                oldOnNewSpawn(inst, ...)
                enablewathomvision(inst)
            end
            
            enablewathomvision(inst)
            inst:WatchWorldState("phase", enablewathomvision)
            inst:ListenForEvent("ms_respawnedfromghost", enablewathomvision)
            inst:ListenForEvent("changearea", enablewathomvision) -- 监听区域变化
            
        end)
        
        -- 闪闪
        AddNightVisionToCharacter("winky")
    end
    
    -- 韦伯
    AddNightVisionToCharacter("webber")
    
    -- 沃特
    AddNightVisionToCharacter("wurt")

end

