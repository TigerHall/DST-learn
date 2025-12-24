local TOOLS_L = require("tools_legion")
local TOOLS_P_L = require("tools_plant_legion")

local GeneTrans = Class(function(self, inst)
	self.inst = inst

	self.energynum = 60 --当前能量点数。可以为负数，代表欠多少能量
	self.energynum_max = 500 --最大能量点数
	self.seed = nil --播下的种子的prefab名
	self.seednum = 0 --已放入的种子数量
	self.seeddata = nil --该异种的配置参数
	self.fruitnum = 0 --转化完成的异种数量
	self.genepool = { --基因池
		--种子名 = true
	}

	self.task_grow = nil
	self.pause_reason = nil --暂停转化的原因。为 nil 代表没有暂停
	self.time_mult = nil --当前转化速度。为 nil 或 0 代表停止转化
	self.time_grow = nil --已经转化的时间
	self.time_all = nil --单个转化的总时间
	self.time_start = nil --本次 task_grow 周期开始的时间
	self.cg_fast_reason = nil
	-- self.fast_reason = { --影响转化速度的因素
	-- 	xx = {
	-- 		mult = 1.5, --对转化速度的影响系数
	-- 		time = 0, --剩余影响点数，如果为 nil 代表无时间限制
	-- 	}
	-- }

	self.fxdata = {
		prefab = "siving_turn_fruit", symbol = "followed", x = 0, y = 0, z = 0,
		build = nil, bloom = true, unlockfx = "siving_turn_unlock_fx"
	}
	self.fx = nil
	self.fn_setanim = nil
end)

local function SpawnFx(self)
	self.fx = SpawnPrefab(self.fxdata.prefab)
	if self.fxdata.build ~= nil then
		self.fx.AnimState:SetBank(self.fxdata.build)
        self.fx.AnimState:SetBuild(self.fxdata.build)
	end
	self.fx.entity:SetParent(self.inst.entity)
	-- self.fx.entity:AddFollower()
	self.fx.Follower:FollowSymbol(
		self.inst.GUID, self.fxdata.symbol, --TIP: 跟随通道时，默认跟随通道文件夹里ID=0的
		self.fxdata.x, self.fxdata.y, self.fxdata.z
	)
	self.fx.components.highlightchild:SetOwner(self.inst)
end
local function SpawnLootFruit(self, doer, loot)
	if self.fruitnum > 0 then
		local num = 0
		if self.seeddata.fruitnum_min ~= nil then
			if self.seeddata.fruitnum_min >= self.seeddata.fruitnum_max then
				num = num + self.fruitnum*self.seeddata.fruitnum_min
			else
				for i = 1, self.fruitnum, 1 do
					num = num + math.random(self.seeddata.fruitnum_min, self.seeddata.fruitnum_max)
				end
			end
		else
			for i = 1, self.fruitnum, 1 do
				num = num + math.random(1, 2)
			end
		end
		TOOLS_L.SpawnStackDrop(self.seeddata.fruit, num, self.inst:GetPosition(), doer, loot, { dropper = self.inst })
	end
end
local function SetPushAnim(inst, anim, animpush, isloop)
	if not (inst.AnimState:IsCurrentAnimation(animpush) or inst.AnimState:IsCurrentAnimation(anim)) then
		if inst:IsAsleep() then
			inst.AnimState:PlayAnimation(animpush, isloop)
		else
			inst.AnimState:PlayAnimation(anim)
			inst.AnimState:PushAnimation(animpush, isloop)
		end
	end
end
local function OnPickedFn(inst, doer)
	local cpt = inst.components.genetrans
	local loot = {}
	SpawnLootFruit(cpt, doer, loot)
	if doer ~= nil then
		doer:PushEvent("picksomething", { object = inst, loot = loot })
	end
	cpt.fruitnum = 0
	if cpt.seednum <= 0 then --没有在转化的了
		cpt.seed = nil
		cpt.seeddata = nil
		cpt.seednum = 0
		cpt.time_start = nil
		cpt.time_all = nil
		cpt.time_grow = nil
		if cpt.fx ~= nil then
			cpt.fx:Remove()
			cpt.fx = nil
		end
		if cpt.fn_setanim ~= nil then
			cpt.fn_setanim(cpt, false)
		end
		SetPushAnim(inst, "on_to_idle", "idle", false)
		cpt:SetLight(false)
	else
		cpt:UpdateFxProgress()
	end
	cpt:TriggerPickable(false)
end

function GeneTrans:SetLight(ison) --设置光源
	if ison then
		self.inst.Light:Enable(true)
		if self.fxdata.bloom then
			self.inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		end
		-- if self.fx ~= nil then --太亮了，还是别弄这个
		-- 	self.fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		-- end
	else
		self.inst.Light:Enable(false)
		self.inst.AnimState:ClearBloomEffectHandle()
		-- if self.fx ~= nil then
		-- 	self.fx.AnimState:ClearBloomEffectHandle()
		-- end
	end
end
function GeneTrans:InitAnims() --初始化各种动画
	--设置本体的动画
	if self.energynum > 0 then
		if self.inst:IsAsleep() then
			self.inst.AnimState:PlayAnimation("on", true)
		else
			self.inst.AnimState:PlayAnimation("idle_to_on")
			self.inst.AnimState:PushAnimation("on", true)
		end
	else
		self.inst.AnimState:PlayAnimation("idle", false)
	end

	--设置果实的动画
	if self.fx == nil or not self.fx:IsValid() then
		SpawnFx(self)
	end
	self.fx.AnimState:OverrideSymbol("swap", self.seeddata.swap.build, self.seeddata.swap.file)
	if self.seeddata.swap.symboltype == "3" then
		self.fx.AnimState:Show("SWAPFRUIT-3")
		self.fx.AnimState:Hide("SWAPFRUIT-2")
		self.fx.AnimState:Hide("SWAPFRUIT-1")
	elseif self.seeddata.swap.symboltype == "2" then
		self.fx.AnimState:Hide("SWAPFRUIT-3")
		self.fx.AnimState:Show("SWAPFRUIT-2")
		self.fx.AnimState:Hide("SWAPFRUIT-1")
	else
		self.fx.AnimState:Hide("SWAPFRUIT-3")
		self.fx.AnimState:Hide("SWAPFRUIT-2")
		self.fx.AnimState:Show("SWAPFRUIT-1")
	end
	if self.fn_setanim ~= nil then
		self.fn_setanim(self, true)
	end
end
function GeneTrans:UpdateFxProgress() --更新果实进度动画
	if self.fx == nil then
		return
	end

	local percent = 1
	if self.seednum > 0 then --如果未转化的没有了，则必定是已100%完成了
		if self.time_all ~= nil then
			local alltime = (self.fruitnum + self.seednum) * self.time_all
			if alltime > 0 then
				percent = ( self.fruitnum*self.time_all + (self.time_grow or 0) ) / alltime
			end
		end
	end
	if percent >= 1 then
		self.fx.AnimState:PlayAnimation(self.energynum <= 0 and "fruit_max" or "fruit_max_on", false)
	else --无语子，动画末尾的呈现状态总是不对，缺了最后一块，怎么调都不行，只能单独做个满的动画
		self.fx.AnimState:SetPercent(self.energynum <= 0 and "fruit" or "fruit_on", percent)
	end
end

function GeneTrans:SetTransTime() --设置单个的转化总时间
	self.time_all = (self.seeddata.time or 1) * TUNING.TOTAL_DAY_TIME
	if self.seeddata.genekey ~= nil then --特殊植物
		self.time_all = self.time_all * (CONFIGS_LEGION.TRANSTIMESPEC or 1)
	else --普通作物
		self.time_all = self.time_all * (CONFIGS_LEGION.TRANSTIMECROP or 1)
	end
end
function GeneTrans:SetUp(seeds, doer) --放入转化材料
	if doer ~= nil and self.inst.components.pickable ~= nil then --先把已完成的拿下来
        self.inst.components.pickable:Pick(doer)
    end

	if TRANS_DATA_LEGION[seeds.prefab] == nil then --不能转化
		return false, "WRONGITEM"
	end
	if TRANS_DATA_LEGION[seeds.prefab].genekey ~= nil and not self.genepool[seeds.prefab] then --基因池未解锁
		return false, "NOGENE"
	end
	if self.energynum <= 0 then --没能量了
		return false, "ENERGYOUT"
	end
	if self.seed ~= nil then --已有种子
		if self.seednum > 0 then --还有在转化的
			if self.seed ~= seeds.prefab then --正在转化的和要放入的不一样
				return false, "GROWING"
			end
		end
	end

	--基础数据
	self.seeddata = TRANS_DATA_LEGION[seeds.prefab]
	self.seed = seeds.prefab
	if seeds.components.stackable ~= nil then
		self.seednum = self.seednum + seeds.components.stackable:StackSize()
	else
		self.seednum = self.seednum + 1
	end

	--删除种子实体
	seeds:Remove()

	--寻找周围的相同实体，一并放上去
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 18, { "_inventoryitem" }, { "INLIMBO", "NOCLICK" })
	for _, ent in ipairs(ents) do
		if ent.prefab == self.seed then
			if ent.components.stackable ~= nil then
				self.seednum = self.seednum + ent.components.stackable:StackSize()
			else
				self.seednum = self.seednum + 1
			end
			ent:Remove()
		end
	end

	--开始基因转化
	self:SetTransTime()
	self:UpdateTimeMult()
	self:StartTransing()
	self:InitAnims()
	self:UpdateFxProgress()
	if self.energynum > 0 then
		self:SetLight(true)
	end

    return true
end
function GeneTrans:ClearAll(doer) --恢复未转化状态
	--原始物品
	if self.seednum > 0 then
		TOOLS_L.SpawnStackDrop(self.seed, self.seednum, self.inst:GetPosition(), doer, nil, { dropper = self.inst })
	end
	--转化产物
	SpawnLootFruit(self, doer, nil)

	--数据初始化
	self:StopTransing()
	self.time_all = nil
	self.seed = nil
	self.seeddata = nil
	self.seednum = 0
	self.fruitnum = 0
	self:SetLight(false)
	self:TriggerPickable(false)

	if self.fx ~= nil then
		self.fx:Remove()
		self.fx = nil
	end
	if self.fn_setanim ~= nil then
		self.fn_setanim(self, false)
	end
end
function GeneTrans:TriggerPickable(can)
	if can == nil then
		can = self.fruitnum > 0
	end
    if can then
		TOOLS_P_L.TriggerPickableOn(self.inst, OnPickedFn, "dontstarve/common/destroy_magic")
	elseif self.inst.components.pickable ~= nil then
		self.inst:RemoveComponent("pickable")
	end
end

function GeneTrans:TryDoTransing() --循环转化
	if self.time_grow == nil then
		return
	end
	if self.time_grow <= 0 then
		self.time_grow = nil
		return
	end
	if self.time_all == nil or self.time_all <= 0 or self.seednum <= 0 then
		self:StopTransing()
		return
	end
	if self.time_grow >= self.time_all then
		self.time_grow = self.time_grow - self.time_all

		self.seednum = self.seednum - 1
		self.fruitnum = self.fruitnum + 1
		self:TriggerPickable()

		local cost = self.seeddata.time or 1
		self.energynum = self.energynum - cost
		if self.fast_reason ~= nil then
			for k, v in pairs(self.fast_reason) do
				if v.time ~= nil then
					v.time = v.time - cost
					if v.time <= 0 then
						self.fast_reason[k] = nil --Tip：table.remove() 会导致循环的下标混乱，不按逻辑运行
						self.cg_fast_reason = true
					end
				end
			end
		end

		if self.seednum <= 0 then --全部完成。即使时间还有剩的，但转化完成了，多的就不管了
			self:StopTransing()
			self.time_all = nil
			return
		elseif self.energynum <= 0 then --没能量了。即使时间还有剩的，但没法继续了，多的就不管了
			self.time_grow = nil
			return
		end
		self:TryDoTransing()
	end
end
function GeneTrans:TimePassed(time, nogrow)
	if time > 0 and self.time_mult ~= nil and self.time_mult > 0 then
		self.time_grow = (self.time_grow or 0) + time*self.time_mult
		if not nogrow then
			self:TryDoTransing()
			if self.energynum <= 0 then --能执行到这里，按理来说之前的能量是大于0的，所以这里只判断是否没能量
				self:OnEnergyChange()
			end
			if self.cg_fast_reason then --需要主动更新 time_mult
				self:UpdateTimeMult()
			end
		end
		self:UpdateFxProgress()
	end
end
local function TaskGrow(inst, self)
	if self.time_start ~= nil then
		local dt = GetTime() - self.time_start
		self.time_start = GetTime()
		self:TimePassed(dt)
	else --和 time_start 同步
		self.task_grow:Cancel()
		self.task_grow = nil
	end
end
function GeneTrans:StartTransing() --尝试转化
	if self.seednum <= 0 or self.seed == nil then
		self:StopTransing()
		return
	end
	if self.pause_reason ~= nil then
		return
	end
	if self.time_start == nil then
		self.time_start = GetTime()
	end
	if self.task_grow == nil and not self.inst:IsAsleep() then
		self.task_grow = self.inst:DoPeriodicTask(15+math.random()*10, TaskGrow, 5+math.random()*10, self)
	end
end
function GeneTrans:StopTransing() --停止转化
	if self.task_grow ~= nil then
		self.task_grow:Cancel()
		self.task_grow = nil
	end
	self.time_start = nil
	self.time_grow = nil
end
function GeneTrans:Pause() --暂停转化
	if self.time_start ~= nil then
		if self.task_grow ~= nil then
			self.task_grow:Cancel()
			self.task_grow = nil
		end
		local dt = GetTime() - self.time_start
		self.time_start = nil --停止
		self:TimePassed(dt, true) --只增加 time_grow，这里不管转化
	end
end
function GeneTrans:Resume() --继续转化
	if self.time_start == nil then
		self:StartTransing() --不管 time_grow 已有进度，让 task_grow 自己之后执行，反正只有几十秒
	end
end

function GeneTrans:SetPauseReason(key, value) --设置暂停转化原因
	if value == nil then --减
		if self.pause_reason ~= nil then
			self.pause_reason[key] = nil
			for k, hasit in pairs(self.pause_reason) do
				if hasit then
					self:Pause()
					return --还有原因，就继续暂停
				end
			end
			self.pause_reason = nil
		end
		self:Resume()
	else --增
		if self.pause_reason == nil then
			self.pause_reason = {}
		end
		self.pause_reason[key] = value
		self:Pause()
	end
end
function GeneTrans:UpdateTimeMult() --更新转化速度
	local multnew = 1
	if self.fast_reason ~= nil then
		for k, v in pairs(self.fast_reason) do
			if v.mult ~= nil then
				multnew = multnew * v.mult
			end
		end
	end
	self.cg_fast_reason = nil
	if multnew ~= self.time_mult then
		local dt = GetTime()
		if self.time_start ~= nil and dt > self.time_start then --变化前，需要将之前的时间总结起来
			if self.task_grow ~= nil then
				self.task_grow:Cancel()
				self.task_grow = nil
			end
			dt = dt - self.time_start
			self.time_start = nil
			self:StartTransing()
			self:TimePassed(dt, true) --只增加 time_grow，这里不管转化
		end
		self.time_mult = multnew
	end
end
function GeneTrans:SetFastReason(key, value) --设置影响转化速度的因素
	if value == nil then --减
		if self.fast_reason ~= nil and self.fast_reason[key] ~= nil then
			self.fast_reason[key] = nil
			for k, v in pairs(self.fast_reason) do
				if v then --还有因素
					value = true
					break
				end
			end
			if not value then
				self.fast_reason = nil
			end
			self:UpdateTimeMult()
		end
	else --增
		if self.fast_reason == nil then
			self.fast_reason = {}
		end
		self.fast_reason[key] = value
		self:UpdateTimeMult()
	end
end

function GeneTrans:OnEnergyChange() --能量变化时
	if self.energynum <= 0 then --没有能量
		self:SetPauseReason("noenergy", true)
		self:SetLight(false)
		SetPushAnim(self.inst, "on_to_idle", "idle", false)
	else
		self:SetPauseReason("noenergy", nil)
		if self.seed ~= nil then
			self:SetLight(true)
			SetPushAnim(self.inst, "idle_to_on", "on", true)
		else
			self:SetLight(false)
			self.inst.AnimState:PlayAnimation("idle", false)
		end
	end
end
function GeneTrans:DropLoot(needrecipe) --生成掉落物
	local lootmap = {}
	local pos = self.inst:GetPosition()
	--原始物品
	if self.seednum > 0 then
		lootmap[self.seed] = self.seednum
	end
	--转化产物
	SpawnLootFruit(self, nil, nil)
	--建筑材料
	if needrecipe then
		local recipe = AllRecipes[self.inst.prefab]
		if recipe then
			local recipeloot = self.inst.components.lootdropper:GetRecipeLoot(recipe)
			for _,v in ipairs(recipeloot) do
				lootmap[v] = (lootmap[v] or 0) + 1
			end
		end
	end
	--基因池物品
	for seedname, isfull in pairs(self.genepool) do
		if isfull then
			local keyname = TRANS_DATA_LEGION[seedname].genekey
			if keyname ~= nil then
				lootmap[keyname] = 1 --由于一个key可能对应多个转化材料，所以只能掉落一个
			end
		end
	end
	--最终产生
	for name, num in pairs(lootmap) do
		TOOLS_L.SpawnStackDrop(name, num, pos, nil, nil, { dropper = self.inst })
	end
end
function GeneTrans:Charge(items, doer) --充能
    if self.energynum >= self.energynum_max then
		return false, "ENERGYMAX"
	end

	local value = items.sivturnenergy or 1.5
	local need = TOOLS_L.ComputCost(self.energynum, self.energynum_max, value, items)
    self.energynum = math.min(self.energynum + value*need, self.energynum_max)
	self:OnEnergyChange()
	self:UpdateFxProgress()

	return true
end
function GeneTrans:UnlockGene(items, doer) --基因解锁
	local seed = nil
    for seedname, data in pairs(TRANS_DATA_LEGION) do
		if items.prefab == data.genekey then
			seed = seedname
			break
		end
	end
	if seed == nil then
		return false, "WRONGKEY"
	elseif self.genepool[seed] then
		return false, "HASKEY"
	else
		for seedname, data in pairs(TRANS_DATA_LEGION) do --由于一个key可能对应多个转化材料，所以这里要全循环
			if items.prefab == data.genekey then
				self.genepool[seedname] = true
			end
		end

		if items.components.stackable ~= nil then
			items.components.stackable:Get(1):Remove()
		else
			items:Remove()
		end

		local fx = SpawnPrefab(self.fxdata.unlockfx)
		if fx ~= nil then
			fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
		end
		self.inst.SoundEmitter:PlaySound("wintersfeast2019/winters_feast/table/fx")
	end
	return true
end

function GeneTrans:LongUpdate(dt)
	if self.time_start ~= nil then --没有暂停转化
		self.time_start = GetTime() --得更新标记时间
		self:TimePassed(dt, self.inst:IsAsleep()) --休眠时，只增加 time_grow
	end
end
function GeneTrans:OnEntitySleep()
    if self.task_grow ~= nil then --只是 task_grow 暂停而已，time_start 不能清除
		self.task_grow:Cancel()
		self.task_grow = nil
	end
end
function GeneTrans:OnEntityWake()
	if self.task_grow == nil then
		--刚加载时不处理什么，防止卡顿
		--不管 time_grow 已有进度，让 task_grow 自己之后执行，反正只有几十秒
		self:StartTransing()
	end
end
function GeneTrans:OnSave()
    local data = { energynum = self.energynum }
	if self.seed ~= nil then
		data.seed = self.seed
		if self.seednum > 0 then
			data.seednum = self.seednum

			local dt = self.time_grow
			if self.time_start ~= nil then
				if self.time_mult ~= nil and self.time_mult > 0 then
					dt = (dt or 0) + (GetTime() - self.time_start)*self.time_mult
				end
			end
			if dt ~= nil and dt > 0 then
				data.time_dt = dt
			end
		end
		if self.fruitnum > 0 then
			data.fruitnum = self.fruitnum
		end
	end
	if self.fast_reason ~= nil then
		for k, v in pairs(self.fast_reason) do
			if v.mult ~= nil and v.mult >= 0 then
				if data.fast_reason == nil then
					data.fast_reason = {}
				end
				data.fast_reason[k] = { mult = v.mult, time = v.time }
			end
		end
	end

	local genepool = nil
	for seedname, isfull in pairs(self.genepool) do
		if isfull then
			if genepool == nil then
				genepool = {}
			end
			table.insert(genepool, seedname)
		end
	end
	if genepool ~= nil then
		data.genepool = genepool
	end

    return data
end
function GeneTrans:OnLoad(data, newents)
	if data == nil then
        return
    end

	local energy
	if data.energytime ~= nil and data.energytime > 0 then --兼容旧数据
		energy = data.energytime / TUNING.TOTAL_DAY_TIME
	end
	if data.energynum ~= nil then
		energy = (energy or 0) + data.energynum
	end
	if energy ~= nil then
		self.energynum = math.min(energy, self.energynum_max)
		if self.energynum <= 0 then
			self:SetPauseReason("noenergy", true)
		end
	end

	if data.genepool ~= nil then
		for _, value in ipairs(data.genepool) do
			if TRANS_DATA_LEGION[value] ~= nil then
				self.genepool[value] = true
			end
		end
	end
	if data.fast_reason ~= nil then
		self.fast_reason = {}
		for k, v in pairs(data.fast_reason) do
			if v.mult ~= nil and v.mult >= 0 then
				self.fast_reason[k] = { mult = v.mult, time = v.time }
			end
		end
	end

	local seedname = data.seed
	if seedname ~= nil and TRANS_DATA_LEGION[seedname] ~= nil then
		self.seeddata = TRANS_DATA_LEGION[seedname]
		self.seed = seedname
		if data.seednum ~= nil and data.seednum > 0 then
			self.seednum = data.seednum
		end
		if data.fruitnum ~= nil and data.fruitnum > 0 then
			self.fruitnum = data.fruitnum
			self:TriggerPickable()
		end
		if self.fruitnum <= 0 and self.seednum <= 0 then --什么都没有？那就是默认带有1个未转化的
			self.seednum = 1
		end
		if self.seednum > 0 then --还有需要转化的，所以继续判定时间
			if data.time_dt ~= nil and data.time_dt > 0 then
				self.time_grow = data.time_dt
			end
			self:SetTransTime()
			self:UpdateTimeMult()
			self:StartTransing()
		end
		self:InitAnims()
		self:UpdateFxProgress()
		if self.energynum > 0 then
			self:SetLight(true)
		end
	else --无种子：只需要更新能量状态
		self:OnEnergyChange()
	end
end

return GeneTrans
