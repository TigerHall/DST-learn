local TOOLS_L = require("tools_legion")
local TOOLS_P_L = require("tools_plant_legion")

local function onflower(self)
    if self.isflower then
        self.inst:AddTag("flower")
    else
        self.inst:RemoveTag("flower")
    end
end
local function onrotten(self)
    if self.isrotten then
        self.inst:AddTag("nognatinfest")
    else
        self.inst:RemoveTag("nognatinfest")
    end
end
local function onmoisture(self)
    if self.donemoisture then
        self.inst:RemoveTag("moisable_l")
    else
        self.inst:AddTag("moisable_l")
    end
end
local function onnutrient(self)
    if self.donenutrient then
        self.inst:RemoveTag("fertableall_l")
    else
        self.inst:AddTag("fertableall_l")
    end
end

local PerennialCrop2 = Class(function(self, inst)
	self.inst = inst

	self.cropprefab = "corn" --果实名字，也是数据的key
	self.stage_max = 3 --最大生长阶段
	self.regrowstage = 1 --采摘后重新开始生长的阶段（枯萎后采摘必定从第1阶段开始）
	self.growthmults = { 1, 1, 1, 0 } --四个季节的生长速度(大于1为快，小于1为慢)
	self.leveldata = nil --该植物生长有几个阶段，每个阶段的动画，以及是否处在花期、是否能采集

	self.pollinated_max = 3 --被授粉次数大于等于该值就能增加产量
	self.infested_max = 10 --被侵扰次数大于等于该值就会立即进入枯萎阶段
	self.getsickchance = CONFIGS_LEGION.X_PESTRISK or 0.007 --产生病虫害几率
	-- self.cangrowindrak = nil --能否在黑暗中生长
	-- self.notmoisture = nil --是否不要浇水机制
	-- self.notnutrient = nil --是否不要施肥机制
	-- self.nottendable = nil --是否不要照顾机制
	-- self.overripe_restore = nil --过熟时返还的肥料、水分系数。为空则代表只返还肥料。{ nut = 1, moi = 1 }

	self.stage = 1 --当前生长阶段
	self.isflower = false --当前阶段是否开花
	self.isrotten = false --当前阶段是否枯萎
	self.donemoisture = false --当前阶段是否已经浇水
	self.donenutrient = false --当前阶段是否已经施肥
	self.donetendable = false --当前阶段是否已经照顾
	self.level = nil --当前阶段的数据

	self.numfruit = nil --随机果实数量
	self.pollinated = 0 --被授粉次数
	self.infested = 0 --被侵扰次数

	-- self.task_grow = nil
	-- self.pause_reason = nil --暂停生长的原因。为 nil 代表没有暂停
	-- self.time_mult = nil --当前生长速度。为 nil 或 0 代表停止生长
	-- self.time_grow = nil --已经生长的时间
	-- self.time_start = nil --本次 task_grow 周期开始的时间

	self.cluster_size = { 1, 1.8 } --体型变化范围
	self.cluster_max = 99 --最大簇栽等级
	self.cluster = 0 --簇栽等级
	self.lootothers = nil --{ { israndom=false, factor=0.02, name="log", name_rot="xxx" } } 副产物表

	-- self.units = {} --插件

	-- self.fn_growth = nil --成长时触发：fn(self, nextstagedata)
	-- self.fn_overripe = nil --过熟时触发，用以替换原本的过熟机制：fn(self, fruitnum)
	-- self.fn_loot = nil --计算收获物时触发：fn(self, doer, ispicked, isburnt, lootprefabs)
	-- self.fn_pick = nil --收获时触发：fn(self, doer, loot)
	-- self.fn_stage = nil --每次设定生长阶段时额外触发的函数：fn(self)
	-- self.fn_timemult = nil --生长速度额外修正：fn(self, multnew)

	-- self.fn_defend = nil --作物被采集/破坏时会寻求庇护的函数：fn(inst, target)
	-- self.fn_cluster = nil --簇栽等级变化时触发：fn(self, nowvalue)
	-- self.fn_season = nil --季节变化时触发：fn(self)
end,
nil,
{
    isflower = onflower,
	isrotten = onrotten,
	donemoisture = onmoisture,
	donenutrient = onnutrient
})

local function OnMoiWater(self, num, ...)
	if num > 0 then
		self.inst.components.perennialcrop2:PourWater(num)
	end
end
local function OnIsRaining(inst)
	inst.components.perennialcrop2:PourWater(1)
end
local function OnTendTo(inst, doer)
	inst.components.perennialcrop2:TendTo(doer, true)
	return true
end
local function TryMagicGrowth(inst, doer, time)
	inst.magic_growth_delay = nil --官方加的数据，用不到，还是清理了吧
	--着火时无法被催熟
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return false
	end
	local self = inst.components.perennialcrop2
	--暂停生长时无法被催熟
	if self.time_mult == nil or self.time_mult <= 0 or self.time_start == nil then
		return false
	end
	--成熟状态是无法被催熟的（枯萎时可以催熟，加快重生）
	if not self.isrotten and self.stage == self.stage_max then
		return false
	end
	if time == nil or type(time) ~= "number" or time <= 0 then
		time = 6 * TUNING.TOTAL_DAY_TIME --默认6天	
	end
	time = time * Remap(self.cluster, 0, self.cluster_max, 1, 1/6) --簇栽等级会削弱催熟效果
	self:TimePassed(time, inst:IsAsleep())
	return true
end
local function SetCallDefender(self, fn)
	if fn == nil then
		self.fn_defend = function(inst, target)
			TOOLS_L.CallPlantDefender(inst, target)
		end
	else
		self.fn_defend = function(inst, target)
			TOOLS_L.CallPlantDefender(inst, target)
			fn(inst, target)
		end
	end
end
local function OnSeasonChange(inst, season)
	if not POPULATING then --生长速度在 SetStage() 时会自己更新的
		inst.components.perennialcrop2:UpdateTimeMult()
	end
    if inst.components.perennialcrop2.fn_season ~= nil then
		inst.components.perennialcrop2:fn_season()
	end
end

local function OnIgnite(inst, source, doer)
	inst.components.perennialcrop2:SetPauseReason("burning", true)
end
local function OnExtinguish(inst)
	inst.components.perennialcrop2:SetPauseReason("burning", nil)
end
local function OnBurnt(inst)
	inst.components.perennialcrop2:GenerateLoot(nil, false, true)
	inst:Remove()
end

local function UpdateGrow_dark(inst)
	if not inst.components.perennialcrop2:CanGrowInDark() and TOOLS_L.IsTooDarkToGrow(inst) then
		inst.components.perennialcrop2:SetPauseReason("indark", true)
	else
		inst.components.perennialcrop2:SetPauseReason("indark", nil)
	end
end
local function OnIsDark(inst, isit)
	UpdateGrow_dark(inst)
	if isit then --黑暗时判定是否有光源来帮助生长
		if inst.task_l_testgrow == nil then
			inst.task_l_testgrow = inst:DoPeriodicTask(10, UpdateGrow_dark, 1+5*math.random())
		end
	else --非夜晚肯定能生长，所以取消监听
		if inst.task_l_testgrow ~= nil then
			inst.task_l_testgrow:Cancel()
			inst.task_l_testgrow = nil
		end
	end
end
local function UpdateGrow_light(inst)
	if not inst.components.perennialcrop2:CanGrowInLight() and TOOLS_L.IsTooBrightToGrow(inst) then
		inst.components.perennialcrop2:SetPauseReason("inlight", true)
	else
		inst.components.perennialcrop2:SetPauseReason("inlight", nil)
	end
end
local function OnIsDay(inst, isit)
	UpdateGrow_light(inst)
    if isit then --白天必定无法生长，所以直接取消监听
        if inst.task_l_testgrow2 ~= nil then
			inst.task_l_testgrow2:Cancel()
			inst.task_l_testgrow2 = nil
		end
    else --非白天判定是否有光源来阻碍生长
        if inst.task_l_testgrow2 == nil then
			inst.task_l_testgrow2 = inst:DoPeriodicTask(10, UpdateGrow_light, 1+5*math.random())
		end
    end
end

local function DoMagicGrowth_on(self, doer, time)
	return TryMagicGrowth(self.inst, doer, time)
end
local function DoMagicGrowth_off(self, doer, time)
	return false
end
PerennialCrop2.DoMagicGrowth = DoMagicGrowth_off --需要一个默认值，防止别的模组调用时出错

function PerennialCrop2:SetUp(cropprefab, data, data2)
	self.cropprefab = cropprefab
	self.stage_max = #data.leveldata
	self.leveldata = data.leveldata
	if data.growthmults then
		self.growthmults = data.growthmults
	end
	if data.regrowstage then
		self.regrowstage = data.regrowstage
	end
	self.overripe_restore = data.overripe_restore
	self.fn_growth = data.fn_growth
	self.fn_overripe = data.fn_overripe
	self.fn_loot = data.fn_loot
	self.fn_lootset = data.fn_lootset
	self.fn_pick = data.fn_pick
	self.fn_stage = data.fn_stage
	self.fn_season = data.fn_season
	SetCallDefender(self, data.fn_defend)

	if data.cluster_max then
		self.cluster_max = data.cluster_max
	end
	if data.cluster_size then
		self.cluster_size = data.cluster_size
	end
	self:OnClusterChange() --这里写是为了动态更新大小
	self.lootothers = data.lootothers

	--不知道为啥getsickchance会是字符串，暂不清楚原因。多半是被别的模组改动了
	if type(data.getsickchance) == "number" and self.getsickchance > 0 then
		self.getsickchance = data.getsickchance
	end

	self:TriggerMoisture(data2.moisture)
	self:TriggerNutrient(data2.nutrient)
	self:TriggerTendable(data2.tendable)
	if data2.seasonlisten then
		self:TriggerSeasonListen(true)
	end
	if not data2.nomagicgrow then
		self:TriggerGrowable(true)
	end
	if not data2.fireproof then
		self:TriggerBurnable(true)
	end
	if data2.cangrowindrak then
		self.cangrowindrak = true
	end
	if data2.nogrowinlight then
		self.nogrowinlight = true
	end
	if not self.cangrowindrak or self.nogrowinlight then
		self.inst:DoTaskInTime(math.random(), function(inst)
			if not self.cangrowindrak then
				self:TriggerGrowInDark(false)
			end
			if self.nogrowinlight then
				self:TriggerGrowInLight(false)
			end
		end)
	end
	if not data2.nosivctl then
		TOOLS_P_L.FindSivCtls(self.inst, self, nil, true, POPULATING) --养分重要，需及时吸取来加速生长
	end
end
function PerennialCrop2:TriggerMoisture(isadd) --控制浇水机制
	if isadd then
		self.notmoisture = nil
		self.donemoisture = false
		TOOLS_P_L.TriggerMoistureOn(self.inst, OnMoiWater, OnIsRaining)
	else
		self.notmoisture = true
		self.donemoisture = true
		TOOLS_P_L.TriggerMoistureOff(self.inst)
	end
end
function PerennialCrop2:TriggerNutrient(isadd) --控制施肥机制
	-- local inst = self.inst
	if isadd then
		self.notnutrient = nil
		self.donenutrient = false
	else
		self.notnutrient = true
		self.donenutrient = true
	end
end
function PerennialCrop2:TriggerTendable(isadd) --控制照顾机制
	local inst = self.inst
	if isadd then
		self.nottendable = nil
		self.donetendable = false

		local function EmptyCptFn(self, ...)end

		inst:AddComponent("farmplanttendable")
		-- inst.components.farmplanttendable.TendTo = TendTo
		inst.components.farmplanttendable.ontendtofn = OnTendTo
		inst.components.farmplanttendable.OnSave = EmptyCptFn --照顾组件的数据不能保存下来，否则会影响 perennialcrop2
		inst.components.farmplanttendable.OnLoad = EmptyCptFn
		inst.components.farmplanttendable:SetTendable(true)
		inst:AddTag("tendable_farmplant")
	else
		self.nottendable = true
		self.donetendable = true

		if inst.components.farmplanttendable ~= nil then
			inst:RemoveComponent("farmplanttendable")
			inst:RemoveTag("tendable_farmplant")
		end
	end
end
function PerennialCrop2:TriggerGrowable(isadd) --控制是否能魔法催熟
	if isadd then
		TOOLS_P_L.TriggerGrowableOn(self.inst, TryMagicGrowth)
		self.DoMagicGrowth = DoMagicGrowth_on
	else
		if self.inst.components.growable ~= nil then
			self.inst:RemoveComponent("growable")
		end
		self.DoMagicGrowth = DoMagicGrowth_off
	end
end
function PerennialCrop2:TriggerBurnable(isadd) --控制是否能燃烧
	local inst = self.inst
	if isadd then
		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		inst.components.burnable:SetOnIgniteFn(OnIgnite)
		inst.components.burnable:SetOnExtinguishFn(OnExtinguish)
		inst.components.burnable:SetOnBurntFn(OnBurnt)
	else
		if inst.components.burnable ~= nil then
			inst:RemoveComponent("burnable")
			inst:RemoveComponent("propagator")
		end
	end
end
function PerennialCrop2:TriggerGrowInDark(isadd) --控制是否能在黑暗中生长
	local inst = self.inst
	if isadd then
		self.cangrowindrak = true
		inst:StopWatchingWorldState("isnight", OnIsDark)
		OnIsDark(inst, false)
	else
		self.cangrowindrak = nil
		inst:WatchWorldState("isnight", OnIsDark) --虽然洞穴里 isnight 必定是true，但要是哪天会改了呢，所以还是监听上
		OnIsDark(inst, TheWorld.state.isnight)
	end
end
function PerennialCrop2:TriggerGrowInLight(isadd) --控制是否能在阳光下生长
	local inst = self.inst
	if isadd then
		self.nogrowinlight = nil
		inst:StopWatchingWorldState("isday", OnIsDay)
		OnIsDay(inst, true)
	else
		self.nogrowinlight = true
		inst:WatchWorldState("isday", OnIsDay) --虽然洞穴里 isday 必定是false，但要是哪天会改了呢，所以还是监听上
		OnIsDay(inst, TheWorld.state.isday)
	end
end
function PerennialCrop2:TriggerSeasonListen(isadd) --控制是否要监听四季变化
	if isadd then
		--Tip：WatchWorldState("season" 触发时，不能使用 TheWorld.state.issummer 这种，因为下一帧时才会更新这个数据，
		--此时应该用 TheWorld.state.season
		self.inst:WatchWorldState("season", OnSeasonChange)
		OnSeasonChange(self.inst)
	else
		self.inst:StopWatchingWorldState("season", OnSeasonChange)
		-- OnSeasonChange(self.inst)
	end
end
function PerennialCrop2:CanGrowInDark() --是否能在黑暗中生长
	--枯萎、成熟时(要算过熟)，在黑暗中也要计算时间了
	return self.cangrowindrak or self.isrotten or self.stage == self.stage_max
end
function PerennialCrop2:CanGrowInLight() --是否能在阳光下生长
	--枯萎、成熟时(要算过熟)，在阳光下也要计算时间了
	return not self.nogrowinlight or self.isrotten or self.stage == self.stage_max
end
function PerennialCrop2:SetNoFunction() --只是需要一些数值，而不是需要生长等机制
	local function EmptyCptFn(self, ...)end
	self.StartGrowing = EmptyCptFn
	self.StopGrowing = EmptyCptFn
	self.LongUpdate = EmptyCptFn
	self.OnEntityWake = EmptyCptFn
	self.OnEntitySleep = EmptyCptFn
	self.Pause = EmptyCptFn
	self.Resume = EmptyCptFn
	self.DoGrowth = EmptyCptFn
end

function PerennialCrop2:SetPauseReason(key, value) --更新暂停生长原因
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
function PerennialCrop2:GetGrowTime() --获取当前阶段的总生长时间
	if self.isrotten then --枯萎再生所需时间3天，因为可以采摘来结束该阶段，所以没有时间系数
		return 3*TUNING.TOTAL_DAY_TIME
	end
	if self.level ~= nil and self.level.time ~= nil then
		local time = self.level.time
		if self.stage >= self.stage_max then --成熟后，应用过熟时间系数
			time = time * (CONFIGS_LEGION.X_OVERRIPETIME or 1)
		else --生长时，应用生长时间系数
			time = time * (CONFIGS_LEGION.X_GROWTHTIME or 1)
		end
		return time
	end
	return 0
end
function PerennialCrop2:UpdateTimeMult() --更新生长速度
	if self.dogrowing then --即将生长的时候不需要更新这个，反正在SetStage()时会再来触发的
		return
	end
	local multnew = 1
	if self.isrotten then
		if TheWorld.state.season == "winter" then
			multnew = self.growthmults[4]
		elseif TheWorld.state.season == "summer" then
			multnew = self.growthmults[2]
		elseif TheWorld.state.season == "spring" then
			multnew = self.growthmults[1]
		else --默认为秋，其他mod的特殊季节默认都为秋季
			multnew = self.growthmults[3]
		end
		if multnew > 1 and multnew < 2 then --枯萎恢复的话，在喜好季节是直接时间减半
			multnew = 2
		else --不喜好季节还是默认速度
			multnew = 1
		end
	elseif self.stage ~= self.stage_max then
		if TheWorld.state.season == "winter" then
			multnew = self.growthmults[4]
		elseif TheWorld.state.season == "summer" then
			multnew = self.growthmults[2]
		elseif TheWorld.state.season == "spring" then
			multnew = self.growthmults[1]
		else --默认为秋，其他mod的特殊季节默认都为秋季
			multnew = self.growthmults[3]
		end
		--浇水、施肥、照顾，能加快生长
		local mulmul = 1.0
		if not self.notmoisture and self.donemoisture then
			mulmul = mulmul + 0.15
		end
		if not self.notnutrient and self.donenutrient then
			mulmul = mulmul + 0.2
		end
		if not self.nottendable and self.donetendable then
			mulmul = mulmul + 0.15
		end
		multnew = multnew * mulmul
	end
	if self.fn_timemult ~= nil then
		multnew = self.fn_timemult(self, multnew)
	end
	if multnew ~= nil and multnew <= 0 then
		multnew = nil
	end
	if multnew ~= self.time_mult then
		local dt = GetTime()
		if self.time_start ~= nil and dt > self.time_start then --变化前，需要将之前的时间总结起来
			if self.task_grow ~= nil then
				self.task_grow:Cancel()
				self.task_grow = nil
			end
			dt = dt - self.time_start
			self.time_start = nil
			self:StartGrowing()
			self:TimePassed(dt, true) --只增加 time_grow，这里不管生长
		end
		self.time_mult = multnew
	end
end

function PerennialCrop2:TryDoGrowth() --循环生长
	if self.time_grow == nil then
		return
	end
	if self.time_grow <= 0 then
		self.time_grow = nil
		return
	end
	local growtime = self:GetGrowTime()
	if growtime <= 0 then
		self:StopGrowing()
		return
	end
	if self.time_grow >= growtime then
		self.time_grow = self.time_grow - growtime
		self:DoGrowth()
		if self.inst:IsValid() then --某些异种某些阶段可能会删除自己
			if self.stage >= self.stage_max then --长到最终阶段后，停止循环判断，这样回到家，就有好果子吃啦
				self.time_grow = nil
			else
				self:TryDoGrowth() --继续循环判断
			end
		end
	end
end
function PerennialCrop2:TimePassed(time, nogrow)
	if self.time_mult ~= nil and self.time_mult > 0 then
		self.time_grow = (self.time_grow or 0) + time*self.time_mult
		if not nogrow then
			self:TryDoGrowth()
		end
	end
end
function PerennialCrop2:StartGrowing() --尝试生长
	if self:GetGrowTime() <= 0 then
		self:StopGrowing()
		return
	end
	if self.pause_reason ~= nil then
		return
	end
	if self.time_start == nil then
		self.time_start = GetTime()
	end
	if self.task_grow == nil and not self.inst:IsAsleep() then
		self.task_grow = self.inst:DoPeriodicTask(15+math.random()*10, function(inst, self)
			if self.time_start ~= nil then
				local dt = GetTime() - self.time_start
				self.time_start = GetTime()
				self:TimePassed(dt)
			else --和 time_start 同步
				self.task_grow:Cancel()
				self.task_grow = nil
			end
		end, 5+math.random()*10, self)
	end
end
function PerennialCrop2:StopGrowing() --停止生长
	if self.task_grow ~= nil then
		self.task_grow:Cancel()
		self.task_grow = nil
	end
	self.time_start = nil
	self.time_grow = nil
end
function PerennialCrop2:Pause() --暂停生长
	if self.time_start ~= nil then
		if self.task_grow ~= nil then
			self.task_grow:Cancel()
			self.task_grow = nil
		end
		local dt = GetTime() - self.time_start
		self.time_start = nil --停止
		self:TimePassed(dt, true) --只增加 time_grow，这里不管生长
	end
end
function PerennialCrop2:Resume() --继续生长
	if self.time_start == nil then
		self:StartGrowing() --不管 time_grow 已有进度，让 task_grow 自己之后执行，反正只有几十秒
	end
end

function PerennialCrop2:OnEntitySleep()
    if self.task_grow ~= nil then --只是 task_grow 暂停而已，time_start 不能清除
		self.task_grow:Cancel()
		self.task_grow = nil
	end
end
function PerennialCrop2:OnEntityWake()
	if self.task_grow == nil then
		--刚加载时不处理什么，防止卡顿
		--不管 time_grow 已有进度，让 task_grow 自己之后执行，反正只有几十秒
		self:StartGrowing()
	end
end
PerennialCrop2.LongUpdate = TOOLS_P_L.LongUpdate

local function CanAcceptNutrients(botanyctl, test)
	if test ~= nil and (botanyctl.type == 2 or botanyctl.type == 3) then
		if test[1] ~= nil and test[1] ~= 0 and botanyctl.nutrients[1] < botanyctl.nutrient_max then
			return true
		elseif test[2] ~= nil and test[2] ~= 0 and botanyctl.nutrients[2] < botanyctl.nutrient_max then
			return true
		elseif test[3] ~= nil and test[3] ~= 0 and botanyctl.nutrients[3] < botanyctl.nutrient_max then
			return true
		else
			return false
		end
	end
	return nil
end
local function IsNutEmpty(nut)
	return nut[1] <= 0 and nut[2] <= 0 and nut[3] <= 0 and nut[4] <= 0
end
function PerennialCrop2:GetNextStage() --判定下一个阶段
	local data = {
		stage = 1,
		justgrown = false, --是否是正常生长到下一阶段
		overripe = false, --是否是过熟
		level = nil
	}

	if self.isrotten then --枯萎阶段->1阶段
		data.stage = 1
	elseif self:GetGrowTime() <= 0 then --永恒阶段
		data.stage = self.stage
	elseif self.stage >= self.stage_max then --成熟阶段->再生阶段（过熟）
		data.stage = self.regrowstage
		data.overripe = true
	else --生长阶段->下一个生长阶段（不管是否成熟）
		data.stage = self.stage + 1
		data.justgrown = true
	end
	data.level = self.leveldata[data.stage]

	return data
end
function PerennialCrop2:SpawnPest() --生成害虫
	if self.getsickchance > 0 then
		local clusterplus = math.max( math.floor(self.cluster*0.1), 1 )
		if math.random() < self.getsickchance*clusterplus then
			local bugs = SpawnPrefab(math.random()<0.7 and "cropgnat" or "cropgnat_infester")
			if bugs ~= nil then
				bugs.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
			end
		end
	end
end
function PerennialCrop2:GetAddedFruitNum() --获取额外的果实数量
	if self.pollinated >= self.pollinated_max then
		return (self.numfruit or 1) + 1
	else
		return self.numfruit or 1
	end
end
function PerennialCrop2:OverripeRestore(numpoop, numloot) --返还养分与落果
	local pos = self.inst:GetPosition()
	local x = pos.x
	local y = pos.y
	local z = pos.z
	local sets = { dropper = self.inst }
	if numpoop > 0 then
		local nutzero
		local nut = { numpoop*9 }
		nut[4] = 0
		if self.overripe_restore ~= nil then
			if self.overripe_restore.nut ~= nil then
				nut[1] = nut[1] * self.overripe_restore.nut
			else
				nut[1] = 0
			end
			if self.overripe_restore.moi ~= nil then
				nut[4] = numpoop*7.5 * self.overripe_restore.moi
			end
			if nut[1] <= 0 and nut[4] <= 0 then
				nutzero = true
			end
		end
		nut[2] = nut[1]
		nut[3] = nut[1]

		------给异种返肥
		if not nutzero and self.sivctls ~= nil then
			for ctl, ctlcpt in pairs(self.sivctls) do
				if ctl:IsValid() then
					local neednut = { 0, 0, 0, 0 }
					if ctlcpt.type ~= 2 then
						if nut[4] > 0 and ctlcpt.moisture < ctlcpt.moisture_max then
							neednut[4] = math.min(ctlcpt.moisture_max-ctlcpt.moisture, nut[4])
							nut[4] = nut[4] - neednut[4]
						end
					end
					if ctlcpt.type ~= 1 then
						for i = 1, 3, 1 do
							if nut[i] > 0 and ctlcpt.nutrients[i] < ctlcpt.nutrient_max then
								neednut[i] = math.min(ctlcpt.nutrient_max-ctlcpt.nutrients[i], nut[i])
								nut[i] = nut[i] - neednut[i]
							end
						end
					end
					if not IsNutEmpty(neednut) then
						ctlcpt:SetValue(neednut[4], neednut, nil, nil)
						if IsNutEmpty(nut) then
							nutzero = true
							break
						end
					end
				else --清理不需要的照料机
					self.sivctls[ctl] = nil
				end
			end
		end
		------给耕地返肥
		if not nutzero then
			local newx, newz
			local farmmgr = TheWorld.components.farming_manager
			for k1 = -4, 4, 4 do --只影响周围半径一格的地皮，但感觉最多可涉及到3x3格地皮
				newx = x+k1
				for k2 = -4, 4, 4 do
					newz = z+k2
					local tile = TheWorld.Map:GetTileAtPoint(newx, 0, newz)
					if tile == GROUND.FARMING_SOIL then
						if nut[4] > 0 then
							local need = farmmgr:IsSoilMoistAtPoint(newx, 0, newz) and 10 or 30
							if need > nut[4] then
								need = nut[4]
								nut[4] = 0
							else
								nut[4] = nut[4] - need
							end
							farmmgr:AddSoilMoistureAtPoint(newx, 0, newz, need*3) --水分会自然减少，所以得多给点
						end
						if nut[1] > 0 or nut[2] > 0 or nut[3] > 0 then
							local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(newx, 0, newz)
                			local tn = { farmmgr:GetTileNutrients(tile_x, tile_z) }
							for i = 1, 3, 1 do
								if nut[i] > 0 and tn[i] ~= nil and tn[i] < 100 then
									tn[i] = math.min(100-tn[i], nut[i])
									nut[i] = nut[i] - tn[i]
								else
									tn[i] = 0
								end
							end
							if tn[3] > 0 or tn[2] > 0 or tn[1] > 0 then
								farmmgr:AddTileNutrients(tile_x, tile_z, tn[1], tn[2], tn[3])
							end
						end
						if IsNutEmpty(nut) then
							nutzero = true
							break
						end
					end
				end
				if nutzero then break end
			end
			------给植物施肥
			if not nutzero then
				local tagsone = { "withered", "barren" }
				if nut[4] > 0 then table.insert(tagsone, "moisable_l") end
				if nut[1] > 0 then table.insert(tagsone, "fertable1_l") end
				if nut[2] > 0 then table.insert(tagsone, "fertable2_l") end
				if nut[3] > 0 then table.insert(tagsone, "fertable3_l") end
				local ents = TheSim:FindEntities(x, y, z, 6, nil, { "INLIMBO", "NOCLICK" }, tagsone)
				for _, v in ipairs(ents) do
					local cpt = v.components.perennialcrop or v.components.shyerrygrow
					if cpt ~= nil then
						local need
						if nut[4] > 0 and cpt.moisture < cpt.moisture_max then
							need = cpt.moisture_max - cpt.moisture
							if need >= nut[4] then
								cpt:SetMoisture(nut[4])
								nut[4] = 0
							else
								cpt:SetMoisture(need)
								nut[4] = nut[4] - need
							end
						end
						for i, k in ipairs({ "nutrient1", "nutrient2", "nutrient3" }) do
							if nut[i] > 0 and cpt[k] < cpt.nutrient_max then
								need = cpt.nutrient_max - cpt[k]
								if need >= nut[i] then
									cpt["SetNutrient"..tostring(i)](cpt, nut[i])
									nut[i] = 0
								else
									cpt["SetNutrient"..tostring(i)](cpt, need)
									nut[i] = nut[i] - need
								end
							end
						end
						if need ~= nil and IsNutEmpty(nut) then
							nutzero = true
							break
						end
					elseif v.components.pickable ~= nil then
						local doit
						if v.components.witherable ~= nil and v.components.witherable:IsWithered() and nut[4] > 0 then
							nut[4] = math.max(0, nut[4]-2.5)
							doit = true
						elseif v.components.pickable:IsBarren() then
							for i = 1, 3, 1 do
								if nut[i] > 0 then
									nut[i] = math.max(0, nut[i]-8)
									doit = true
									break
								end
							end
						end
						if doit then
							if v.components.pickable:CanBeFertilized() then
								local poop = SpawnPrefab("glommerfuel")
								if poop ~= nil then
									v.components.pickable:Fertilize(poop, nil)
									poop:Remove()
								end
							end
							if IsNutEmpty(nut) then
								nutzero = true
								break
							end
						end
					end
				end
				------变成腐烂物、冰
				if not nutzero then
					numpoop = math.min(nut[1], nut[2], nut[3])
					numpoop = math.floor(numpoop/8)
					if numpoop > 0 then --总觉得lua的数学逻辑有很大误差
						TOOLS_L.SpawnStackDrop("spoiled_food", numpoop, pos, nil, nil, sets)
					end
					if nut[4] > 0 then
						numpoop = math.ceil(nut[4]/100)
						TOOLS_L.SpawnStackDrop("ice", numpoop, pos, nil, nil, sets)
					end
				end
			end
		end
	end
	if numloot > 0 then
		TOOLS_L.SpawnStackDrop(self.cropprefab, numloot, pos, nil, nil, sets)
	end
end
function PerennialCrop2:DoOverripe() --过熟（掉落果子，给周围植物、土地和子圭管理者施肥）
	local num = self.cluster + self:GetAddedFruitNum()
	if self.fn_overripe ~= nil then
		self.fn_overripe(self, num)
		return
	end
	local numpoop = math.ceil( num*(0.5 + math.random()*0.5) )
	self:OverripeRestore(numpoop, num - numpoop)
end
function PerennialCrop2:DoGrowth() --生长到下一阶段
	local data = self:GetNextStage()
	if data.justgrown or data.overripe then --生长和过熟时都会产生虫群
		self:SpawnPest()
	end
	if data.justgrown then
		if data.stage == self.stage_max or data.level.pickable == 1 then --如果能采集了，开始生成果子数量
			if self.numfruit == nil or self.numfruit <= 1 then --如果只有1个，有机会继续变多
				local num = 1
				local rand = math.random()
				if rand < 0.35 then --35%几率2果实
					num = num + 1
				elseif rand < 0.5 then --15%几率3果实
					num = num + 2
				end
				self.numfruit = num
			end
		end
	elseif data.stage == self.regrowstage or data.stage == 1 then --重新开始生长时，清空某些数据
		if data.overripe then
			self:DoOverripe()
		end
		self.infested = 0
		self.pollinated = 0
		self.numfruit = nil
	end

	if self.fn_growth ~= nil then
		self.fn_growth(self, data)
		if not self.inst:IsValid() then --某些异种某些阶段可能会删除自己
			return
		end
	end

	if data.stage ~= self.stage_max then --生长阶段，就可以三样操作
		self.donemoisture = self.notmoisture == true
		self.donenutrient = self.notnutrient == true
		self.donetendable = self.nottendable == true
		self.dogrowing = true
		self:CostNutrition(nil, true) --是生长，肯定要消耗养分
		self.dogrowing = nil
	end
	self:SetStage(data.stage)
end
local function OnPicked(inst, doer, loot)
	local crop = inst.components.perennialcrop2
	local regrowstage = crop.isrotten and 1 or crop.regrowstage

	if crop.fn_defend ~= nil then
		crop.fn_defend(inst, doer)
	end
	crop:GenerateLoot(doer, true, false)
	if not inst:IsValid() then --inst 在 crop:GenerateLoot() 里可能会被删除
		return
	end

	crop.infested = 0
	crop.pollinated = 0
	crop.numfruit = nil
	crop.donemoisture = crop.notmoisture == true
	crop.donenutrient = crop.notnutrient == true
	crop.donetendable = crop.nottendable == true
	crop.time_grow = nil

	crop.dogrowing = true
	crop:CostNutrition(nil, true) --采摘后立即索取养分
	crop.dogrowing = nil
	crop:SetStage(regrowstage, false)
end
function PerennialCrop2:SetStage(stage, isrotten) --设置为某阶段
	if stage == nil or stage < 1 then
		stage = 1
	elseif stage > self.stage_max then
		stage = self.stage_max
	end

	--确定当前的阶段
	local rotten = false
	local level = self.leveldata[stage]
	if isrotten then
		if level.deadanim == nil then --枯萎了，但是没有枯萎状态，回到第一个阶段
			level = self.leveldata[1]
			stage = 1
		else
			rotten = true
		end
	end

	--修改当前阶段数据
	self.stage = stage
	self.level = level
	self.isrotten = rotten
	self.isflower = not rotten and level.bloom == true

	--设置动画
	if rotten then
		self.inst.AnimState:PlayAnimation(level.deadanim, false)
	elseif stage == self.stage_max or level.pickable == 1 then
		if type(level.anim) == 'table' then
			local minnum = #level.anim
			minnum = math.min(minnum, self:GetAddedFruitNum())
			self.inst.AnimState:PlayAnimation(level.anim[minnum], true)
		else
			self.inst.AnimState:PlayAnimation(level.anim, true)
		end
		TOOLS_L.RandomAnimFrame(self.inst)
	else
		if type(level.anim) == 'table' then
			self.inst.AnimState:PlayAnimation(level.anim[ math.random(#level.anim) ], true)
		else
			self.inst.AnimState:PlayAnimation(level.anim, true)
		end
		TOOLS_L.RandomAnimFrame(self.inst)
	end

	--设置是否可采摘
	if
		rotten or --枯萎了，必定能采集
		level.pickable == 1 or -- 1 代表必定能采集
		(level.pickable ~= -1 and stage == self.stage_max) -- -1 代表不能采集
	then
		TOOLS_P_L.TriggerPickableOn(self.inst, OnPicked,
			rotten and "dontstarve/wilson/harvest_berries" or "dontstarve/wilson/pickup_plants")
	elseif self.inst.components.pickable ~= nil then
		self.inst:RemoveComponent("pickable")
	end

	--基础三样操作
	if rotten or stage == self.stage_max then
		self.donemoisture = true
		self.donenutrient = true
		self.donetendable = true
	end
	--设置是否可照顾
	if self.inst.components.farmplanttendable ~= nil then
		self.inst.components.farmplanttendable:SetTendable(not self.donetendable)
	end

	--尝试开始生长
	self:UpdateTimeMult() --更新生长速度
	if self.task_grow == nil then
		self:StartGrowing()
	end

	--额外设置
	if self.fn_stage ~= nil then
		self.fn_stage(self)
	end
end

function PerennialCrop2:AddLoot(loot, name, number)
	if loot[name] == nil then
		loot[name] = number
	else
		loot[name] = loot[name] + number
	end
end
function PerennialCrop2:GetBaseLoot(lootprefabs, sets) --判定基础收获物
	--先算主
	local num = self.cluster + (self.numfruit or 1)
	local ispollinated = self.pollinated >= self.pollinated_max --授粉成功，提高产量
	if ispollinated then
		num = num + math.max( math.floor(self.cluster*0.1), 1 ) --保证肯定多1个
	end
	self:AddLoot(lootprefabs, self.isrotten and (sets.crop_rot or "spoiled_food") or sets.crop, num)

	--后算副
	if sets.lootothers ~= nil then
		for _, data in pairs(sets.lootothers) do
			if data.israndom then
				if ispollinated then
					num = math.random() < (data.factor+0.2) and 1 or 0
				else
					num = math.random() < data.factor and 1 or 0
				end
			else
				num = math.floor(self.cluster*data.factor)
				if ispollinated then
					num = num + math.max( math.floor(num*0.2), 1 ) --保证肯定多1个
				end
			end
			if num > 0 then
				local name
				if self.isrotten then
					name = data.name_rot or "spoiled_food"
				else
					name = data.name
				end
				self:AddLoot(lootprefabs, name, num)
			end
		end
	end
end
function PerennialCrop2:GenerateLoot(doer, ispicked, isburnt) --生成收获物
	local loot = {}
	local lootprefabs = {}
	local pos = self.inst:GetPosition()

	if self.fn_loot ~= nil then
		self.fn_loot(self, doer, ispicked, isburnt, lootprefabs)
	elseif self.stage == self.stage_max or self.level.pickable == 1 then
		self:GetBaseLoot(lootprefabs, {
			doer = doer, ispicked = ispicked, isburnt = isburnt,
			crop = self.cropprefab, crop_rot = "spoiled_food",
			lootothers = self.lootothers
		})
	end

	if not ispicked then --非采集时，多半是破坏
		if self.level.witheredprefab then
			for _, prefab in ipairs(self.level.witheredprefab) do
				self:AddLoot(lootprefabs, prefab, 1)
			end
		end
	end

	if self.isflower and not self.isrotten then
		self:AddLoot(lootprefabs, "petals", 3)
	elseif self.stage > 1 then
		local hasprefab = false
		for _, num in pairs(lootprefabs) do
			if num > 0 then
				hasprefab = true
				break
			end
		end
		if not hasprefab then
			if self.isrotten then
				self:AddLoot(lootprefabs, "spoiled_food", 1)
			else
				self:AddLoot(lootprefabs, "cutgrass", 1)
			end
		end
	end

	if isburnt then
		local lootprefabs2 = {}
		for name, num in pairs(lootprefabs) do
			if TUNING.BURNED_LOOT_OVERRIDES[name] ~= nil then
				self:AddLoot(lootprefabs2, TUNING.BURNED_LOOT_OVERRIDES[name], num)
			elseif PrefabExists(name.."_cooked") then
				self:AddLoot(lootprefabs2, name.."_cooked", num)
			elseif PrefabExists("cooked"..name) then
				self:AddLoot(lootprefabs2, "cooked"..name, num)
			else
				self:AddLoot(lootprefabs2, "ash", num)
			end
		end
		lootprefabs = lootprefabs2
	end
	if not ispicked then --异种也要完全返还，写在后面，防止变成灰烬
		self:AddLoot(lootprefabs, "seeds_"..self.cropprefab.."_l", 1+self.cluster)
	end

	for name, num in pairs(lootprefabs) do --生成实体并设置物理掉落
		if num > 0 then
			TOOLS_L.SpawnStackDrop(name, num, pos, nil, loot, { dropper = self.inst })
		end
	end
	if self.fn_lootset ~= nil then
		self.fn_lootset(self, doer, ispicked, isburnt, loot)
	end
	if ispicked then
		if self.fn_pick ~= nil then
			self.fn_pick(self, doer, loot)
		end
		if doer ~= nil then
			doer:PushEvent("picksomething", { object = self.inst, loot = loot })
			if doer.components.inventory ~= nil then --给予采摘者
				for _, item in pairs(loot) do
					if item.components.inventoryitem ~= nil then
						doer.components.inventory:GiveItem(item, nil, pos)
					end
				end
			end
		end
	end
end

function PerennialCrop2:OnSave()
    local data = {
        donemoisture = self.donemoisture == true or nil,
        donenutrient = self.donenutrient == true or nil,
		donetendable = self.donetendable == true or nil,
        stage = self.stage > 1 and self.stage or nil,
		isrotten = self.isrotten == true or nil,
		numfruit = self.numfruit ~= nil and self.numfruit or nil,
		pollinated = self.pollinated > 0 and self.pollinated or nil,
		infested = self.infested > 0 and self.infested or nil,
		cluster = self.cluster > 0 and self.cluster or nil
    }
	local dt = self.time_grow
	if self.time_start ~= nil then
		if self.time_mult ~= nil and self.time_mult > 0 then
			dt = (dt or 0) + (GetTime() - self.time_start)*self.time_mult
		end
	end
	if dt ~= nil and dt > 0 then
		data.time_dt = dt
	end
    return data
end
function PerennialCrop2:OnLoad(data)
    if data == nil then
        return
    end
	if not self.notmoisture then
		self.donemoisture = data.donemoisture ~= nil
	end
	if not self.notnutrient then
		self.donenutrient = data.donenutrient ~= nil
	end
	if not self.nottendable then
		self.donetendable = data.donetendable ~= nil
	end
	if data.stage ~= nil then
		self.stage = data.stage
	end
	self.isrotten = data.isrotten ~= nil
	self.numfruit = data.numfruit
	self.pollinated = data.pollinated or 0
	self.infested = data.infested or 0
	if data.cluster ~= nil then
		self.cluster = math.min(data.cluster, self.cluster_max)
		self:OnClusterChange()
	end
	self:SetStage(self.stage, self.isrotten)
	if data.time_dt ~= nil and data.time_dt > 0 then
		self.time_grow = data.time_dt
	end
end

function PerennialCrop2:OnClusterChange() --簇栽等级变化时
	local now = self.cluster or 0
	if self.fn_cluster ~= nil then
		self.fn_cluster(self, now)
	end
	now = Remap(now, 0, self.cluster_max, self.cluster_size[1], self.cluster_size[2])
	self.inst.AnimState:SetScale(now, now, now)
end
function PerennialCrop2:ClusteredPlant(seeds, doer) --簇栽
	local plantable = seeds.components.plantablelegion
	if plantable == nil then
		return false
	end
	if
		plantable.plant ~= self.inst.prefab and
		(plantable.plant2 == nil or plantable.plant2 ~= self.inst.prefab)
	then
		return false, "NOTMATCH_C"
	end
	if self.cluster >= self.cluster_max then
		return false, "ISMAXED_C"
	end

	--升级前，先采摘了，防止玩家骚操作
	if doer ~= nil and self.inst.components.pickable ~= nil then
        self.inst.components.pickable:Pick(doer)
		if not self.inst:IsValid() then --采摘时可能会移除实体
			return true --如果移除实体，就只能不进行接下来的操作了
		end
    end

	if seeds.components.stackable ~= nil then
		local need = self.cluster_max - self.cluster
		local num = seeds.components.stackable:StackSize()
		if need > num then
			self.cluster = self.cluster + num
		else
			self.cluster = self.cluster_max
			seeds = seeds.components.stackable:Get(need)
		end
	else
		self.cluster = self.cluster + 1
	end
	self:OnClusterChange()
	seeds:Remove()

	if doer ~= nil and doer:HasTag("player") then
		TOOLS_L.SendMouseInfoRPC(doer, self.inst, { c = self.cluster }, true, false)
	end
	if self.inst.SoundEmitter ~= nil then
		self.inst.SoundEmitter:PlaySound("dontstarve/common/plant")
	end

	return true
end
function PerennialCrop2:DoCluster(num) --单纯的簇栽升级，也可以降级
	if self.cluster >= self.cluster_max then
		return false
	end

	local newvalue = self.cluster + (num or 1)
	if newvalue > self.cluster_max then
		newvalue = self.cluster_max
	elseif newvalue < 0 then
		newvalue = 0
	else
		newvalue = math.floor(newvalue) --保证是整数
	end
	self.cluster = newvalue
	self:OnClusterChange()

	return newvalue < self.cluster_max
end

function PerennialCrop2:Pollinate(doer, value) --授粉
    if self.isrotten or self.stage == self.stage_max or self.pollinated >= self.pollinated_max then
		return
	end
	self.pollinated = self.pollinated + (value or 1)
end

function PerennialCrop2:Infest(doer, value) --侵扰
	if self.isrotten then
		return false
	end

	self.infested = self.infested + (value or 1)
	if self.infested >= self.infested_max then
		self.infested = 0
		self:StopGrowing() --先清除生长进度
		self:SetStage(self.stage, true) --再设置枯萎
	end

	return true
end
function PerennialCrop2:Cure(doer) --治疗
	self.infested = 0
end

function PerennialCrop2:Tendable(doer, wish) --是否能照顾
	if self.nottendable or self.isrotten or self.stage == self.stage_max then
		return false
	end

	if wish == nil or wish then --希望是照顾
		return not self.donetendable
	else --希望是取消照顾
		return self.donetendable
	end
end
function PerennialCrop2:TendTo(doer, wish) --照顾
	if not self:Tendable(doer, wish) then
		return false
	end

	local tended
	if wish == nil or wish then --希望是照顾
		tended = true
	else --希望是取消照顾
		tended = false
	end
	if self.inst.components.farmplanttendable ~= nil then
		self.inst.components.farmplanttendable:SetTendable(not tended)
	end
	TOOLS_P_L.SpawnFxTend(self.inst, tended)
	self.donetendable = tended
	self:UpdateTimeMult() --更新生长速度

	return true
end
function PerennialCrop2:PourWater(value) --浇水
	if self.notmoisture or self.isrotten or self.donemoisture or self.stage == self.stage_max then
		return false
	end
	self.donemoisture = true
	self:UpdateTimeMult() --更新生长速度
	return true
end
function PerennialCrop2:Fertilize(item, doer) --用肥料施肥( item 可以为空)
	if self.notnutrient or self.isrotten or self.donenutrient or self.stage == self.stage_max then
		return false
	end
	if self.inst.components.burnable ~= nil then --快着火时能阻止着火
		self.inst.components.burnable:StopSmoldering()
	end
	if item and item.components.fertilizer ~= nil and item.components.fertilizer.fertilize_sound ~= nil then
		self.inst.SoundEmitter:PlaySound(item.components.fertilizer.fertilize_sound)
		--这里面不对肥料本身进行消耗
	end
	self.donenutrient = true
	self:UpdateTimeMult() --更新生长速度

	return true
end
function PerennialCrop2:CostNutrition(actlcpt, dosoil) --从 水肥照料机、耕地 索取养料、水分、照顾
	if self.donemoisture and self.donenutrient and self.donetendable then
		return
	end
	local cg
	local cplus = math.max( math.floor(self.cluster*0.5), 1 )
	local mo = self.donemoisture
	if not mo and (TheWorld.state.israining or TheWorld.state.issnowing) then --如果此时在下雨/雪
		mo = true
		self.donemoisture = true
		cg = true
	end
	local dd, tend = TOOLS_P_L.CostNutritionAny(self.inst, self.sivctls, actlcpt, self.donenutrient and 0 or 3*cplus,
                    mo and 0 or 2.5*cplus, self.donetendable, dosoil, nil)
    if dd ~= nil then
        if dd.n ~= nil then
            self.donenutrient = true
			cg = true
			TOOLS_P_L.SpawnFxNut(self.inst)
        end
        if dd.mo ~= nil then
            self.donemoisture = true
			cg = true
			TOOLS_P_L.SpawnFxMoi(self.inst)
        end
    end
	if not self.donetendable and tend then
		self.donetendable = true
		if self.inst.components.farmplanttendable ~= nil then
			self.inst.components.farmplanttendable:SetTendable(false)
		end
		TOOLS_P_L.SpawnFxTend(self.inst, true)
		cg = true
	end
	if cg then
		self:UpdateTimeMult() --更新生长速度
	end
end

return PerennialCrop2
