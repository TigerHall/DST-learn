local TOOLS_L = require("tools_legion")
local TOOLS_P_L = require("tools_plant_legion")

local function onflower(self)
    if self.isflower then
        self.inst:AddTag("flower")
    else
        self.inst:RemoveTag("flower")
    end
end
local function onsick(self)
	if self.sickness <= 0 then
		self.inst.AnimState:SetMultColour(1, 1, 1, 1)
	elseif self.sickness >= 0.3 then
		self.inst.AnimState:SetMultColour(0.6, 0.6, 0.6, 1)
	else
		local color = 1 - self.sickness/0.3 * 0.4
		self.inst.AnimState:SetMultColour(color, color, color, 1)
	end
end
local function onrotten(self)
    if self.isrotten then
        self.inst:AddTag("nognatinfest")
    else
        self.inst:RemoveTag("nognatinfest")
    end
end

local PerennialCrop = Class(function(self, inst)
	self.inst = inst

	self.moisture = 0 --当前水量
	self.nutrient1 = 0 --当前肥量（加速生长）
	self.nutrient2 = 0 --当前肥量（减少疾病）
	self.nutrient3 = 0 --当前肥量（生长必需）
	self.sickness = 0 --当前病害程度
	self.stage = 1	--当前生长阶段
	self.stagedata = {} --当前阶段的数据
	self.isflower = false --当前阶段是否开花
	self.isrotten = false --当前阶段是否腐烂/枯萎
	self.ishuge = false --是否是巨型成熟
	self.tended = false --当前阶段是否已经照顾过了

	self.infested = 0 --被骚扰次数
	self.pollinated = 0 --被授粉次数
	self.num_nutrient = 0 --吸收肥料次数
	self.num_moisture = 0 --吸收水分次数
	self.num_tended = 0 --被照顾次数
	self.num_perfect = nil --成熟时结算出的：完美指数（决定果实数量或者是否巨型）

	self.task_grow = nil
	self.pause_reason = nil --暂停生长的原因。为 nil 代表没有暂停
	self.time_mult = nil --当前生长速度。为 nil 或 0 代表停止生长
	self.time_grow = nil --已经生长的时间
	self.time_start = nil --本次 task_grow 周期开始的时间

	self.moisture_max = 20 --最大蓄水量
	self.nutrient_max = 50 --最大蓄肥量
	self.stage_max = 2 --最大生长阶段
	self.pollinated_max = 3 --被授粉次数大于等于该值就能增加产量
	self.infested_max = 10 --被骚扰次数大于等于该值就会立即进入枯萎状态
	self.ctltypes_l = {}

	self.product = nil
	self.product_huge = nil
	self.seed = nil
	self.loot_huge_rot = nil
	self.cost_moisture = 1 --需水量
	self.cost_nutrient = 2 --需肥量(这里只需要一个量即可，不需要关注肥料类型)
	self.nosick = nil --是否不产生病虫害（原创）
	self.cangrowindrak = nil --是否能在黑暗中生长（原创）
	self.stages = nil --该植物生长有几个阶段，每个阶段的动画，以及是否处在花期（原创）
	self.stages_other = nil --巨大化阶段、巨大化枯萎、枯萎等阶段的数据
	self.regrowstage = 1 --枯萎或者采摘后重新开始生长的阶段（原创）
	self.goodseasons = {} --喜好季节：{autumn = true, winter = true, spring = true, summer = true}
	self.killjoystolerance = 0 --扫兴容忍度：一般都为0
	self.sounds = {
		grow_full = "farming/common/farm/grow_full",
		grow_rot = "farming/common/farm/rot"
	}

	self.fn_stage = nil --每次设定生长阶段时额外触发的函数：fn(inst, isfull)
	self.fn_defend = nil --作物被采集/破坏时会寻求庇护的函数：fn(inst, target)
end,
nil,
{
    isflower = onflower,
	sickness = onsick,
	isrotten = onrotten,
})

local function EmptyCptFn(self, ...)
	--nothing
end
local function OnTendTo(inst, doer)
	inst.components.perennialcrop:TendTo(doer, true)
	return true
end
local function OnMoiWater(self, num, ...)
	if num > 0 then
		self.inst.components.perennialcrop:SetMoisture(num)
	end
end
local function OnIsRaining(inst)
	--不管雨始还是雨停，增加一半的蓄水量(反正一场雨结束，总共只加最大蓄水量的数值)
	inst.components.perennialcrop:SetMoisture(inst.components.perennialcrop.moisture_max/2)
end
local function TryMagicGrowth(inst, doer, time)
	inst.magic_growth_delay = nil --官方加的数据，用不到，还是清理了吧
	--着火时无法被催熟
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return false
	end
	local self = inst.components.perennialcrop
	--暂停生长时无法被催熟
	if self.time_mult == nil or self.time_mult <= 0 or self.time_start == nil then
		return false
	end
	--成熟状态是无法被催熟的（枯萎时可以催熟，加快重生）
	if not self.isrotten and self.stage == self.stage_max then
		return false
	end
	if time ~= nil and type(time) == "number" and time > 0 then
		self:TimePassed(time, inst:IsAsleep())
	else
		self:TimePassed(2*TUNING.TOTAL_DAY_TIME, inst:IsAsleep()) --默认2天
	end
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
	inst.components.perennialcrop:UpdateTimeMult()
end

local function OnIgnite(inst, source, doer)
	inst.components.perennialcrop:SetPauseReason("burning", true)
end
local function OnExtinguish(inst)
	inst.components.perennialcrop:SetPauseReason("burning", nil)
end
local function OnBurnt(inst)
	inst.components.perennialcrop:GenerateLoot(nil, false, true)
	inst:Remove()
end

local function UpdateGrowing(inst)
	if not inst.components.perennialcrop:CanGrowInDark() and TOOLS_L.IsTooDarkToGrow(inst) then
		inst.components.perennialcrop:SetPauseReason("indark", true)
	else
		inst.components.perennialcrop:SetPauseReason("indark", nil)
	end
end
local function OnIsDark(inst, isit)
	UpdateGrowing(inst)
	if isit then
		if inst.task_l_testgrow == nil then
			inst.task_l_testgrow = inst:DoPeriodicTask(5, UpdateGrowing, 1+5*math.random())
		end
	else
		if inst.task_l_testgrow ~= nil then
			inst.task_l_testgrow:Cancel()
			inst.task_l_testgrow = nil
		end
	end
end

local function DoMagicGrowth_on(self, doer, time)
	return TryMagicGrowth(self.inst, doer, time)
end
local function DoMagicGrowth_off(self, doer, time)
	return false
end
PerennialCrop.DoMagicGrowth = DoMagicGrowth_off --需要一个默认值，防止别的模组调用时出错

function PerennialCrop:SetUp(data)
	self.product = data.product
	self.product_huge = data.product_huge
	self.seed = data.seed
	self.loot_huge_rot = data.loot_huge_rot
	self.cost_moisture = data.cost_moisture or 1
	self.cost_nutrient = data.cost_nutrient or 2
	self.nosick = data.nosick
	self.stages = data.stages
	self.stages_other = data.stages_other
	self.stage_max = #data.stages
	self.regrowstage = data.regrowstage or 1
	self.goodseasons = data.goodseasons or {}
	self.killjoystolerance = data.killjoystolerance or 0
	if data.sounds ~= nil then
		self.sounds = data.sounds
	end
	self.fn_stage = data.fn_stage
	self.fn_researchstage = data.fn_researchstage
	SetCallDefender(self, data.fn_defend)

	if not data.fireproof then
		self:TriggerBurnable(true)
	end
	if not data.nomagicgrow then
		self:TriggerGrowable(true)
	end
	if data.cangrowindrak then
		self.cangrowindrak = true
	else
		self:TriggerGrowInDark(false)
	end

	self:SetTagNutrient1()
	self:SetTagNutrient2()
	self:SetTagNutrient3()
	self:SetTagMoisture()

	local inst = self.inst

	inst:AddComponent("farmplanttendable")
	inst.components.farmplanttendable.ontendtofn = OnTendTo
	inst.components.farmplanttendable.OnSave = EmptyCptFn --照顾组件的数据不能保存下来，否则会影响 perennialcrop
	inst.components.farmplanttendable.OnLoad = EmptyCptFn

	TOOLS_P_L.TriggerMoistureOn(inst, OnMoiWater, OnIsRaining)

	--Tip：WatchWorldState("season" 触发时，不能使用 TheWorld.state.issummer 这种，因为下一帧时才会更新这个数据，
	--此时应该用 TheWorld.state.season
	inst:WatchWorldState("season", OnSeasonChange)
	-- OnSeasonChange(inst) --只是控制生长速度而已。SetStage() 时会自己更新的

	TOOLS_P_L.FindSivCtls(inst, self, nil, true, POPULATING) --1号肥重要，需及时吸取来加速生长
end
function PerennialCrop:TriggerBurnable(isadd) --控制是否能燃烧
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
function PerennialCrop:TriggerGrowable(isadd) --控制是否能魔法催熟
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
function PerennialCrop:TriggerGrowInDark(isadd) --控制是否能在黑暗中生长
	local inst = self.inst
	if inst.task_l_trytestgrow ~= nil then
		inst.task_l_trytestgrow:Cancel()
	end
	if isadd then
		self.cangrowindrak = true
		inst:StopWatchingWorldState("isnight", OnIsDark)
		inst.task_l_trytestgrow = inst:DoTaskInTime(math.random(), function(inst)
			inst.task_l_trytestgrow = nil
			OnIsDark(inst, false)
		end)
	else
		self.cangrowindrak = nil
		inst:WatchWorldState("isnight", OnIsDark)
		inst.task_l_trytestgrow = inst:DoTaskInTime(math.random(), function(inst)
			inst.task_l_trytestgrow = nil
			OnIsDark(inst, TheWorld.state.isnight)
		end)
	end
end
function PerennialCrop:CanGrowInDark() --是否能在黑暗中生长
	--枯萎、成熟时(要算过熟)，在黑暗中也要计算时间了
	return self.cangrowindrak or self.isrotten or self.stage == self.stage_max
end

function PerennialCrop:SetPauseReason(key, value) --更新暂停生长原因
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
function PerennialCrop:GetGrowTime() --获取当前阶段的总生长时间
	if self.stagedata ~= nil and self.stagedata.time ~= nil then
		return self.stagedata.time
	end
	return 0
end
function PerennialCrop:UpdateTimeMult() --更新生长速度
	if self.dogrowing then --即将生长的时候不需要更新这个，反正在SetStage()时会再来触发的
		return
	end
	local multnew = 1
	if self.isrotten then
		if self.goodseasons[TheWorld.state.season] then --枯萎恢复的话，在喜好季节是直接时间减半
			multnew = 2
		end
	elseif self.stage ~= self.stage_max then
		if self.goodseasons[TheWorld.state.season] then --喜好季节则快60%
			multnew = multnew + 0.6
		end
		if self.nutrient1 > 0 then --有加速肥则快40%
			multnew = multnew + 0.4
		end
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

function PerennialCrop:TryDoGrowth() --循环生长
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
		if self.inst:IsValid() then --某些阶段可能会删除自己
			if not self.isrotten and self.stage >= self.stage_max then --长到最终阶段后，停止循环判断，这样回到家，就有好果子吃啦
				self.time_grow = nil
			else
				self:TryDoGrowth() --继续循环判断
			end
		end
	end
end
function PerennialCrop:TimePassed(time, nogrow)
	if self.time_mult ~= nil and self.time_mult > 0 then
		self.time_grow = (self.time_grow or 0) + time*self.time_mult
		if not nogrow then
			self:TryDoGrowth()
		end
	end
end
function PerennialCrop:StartGrowing() --尝试生长
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
function PerennialCrop:StopGrowing() --停止生长
	if self.task_grow ~= nil then
		self.task_grow:Cancel()
		self.task_grow = nil
	end
	self.time_start = nil
	self.time_grow = nil
end
function PerennialCrop:Pause() --暂停生长
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
function PerennialCrop:Resume() --继续生长
	if self.time_start == nil then
		self:StartGrowing() --不管 time_grow 已有进度，让 task_grow 自己之后执行，反正只有几十秒
	end
end

function PerennialCrop:OnEntitySleep()
    if self.task_grow ~= nil then --只是 task_grow 暂停而已，time_start 不能清除
		self.task_grow:Cancel()
		self.task_grow = nil
	end
end
function PerennialCrop:OnEntityWake()
	if self.task_grow == nil then
		--刚加载时不处理什么，防止卡顿
		--不管 time_grow 已有进度，让 task_grow 自己之后执行，反正只有几十秒
		self:StartGrowing()
	end
end
PerennialCrop.LongUpdate = TOOLS_P_L.LongUpdate

function PerennialCrop:SpawnPest() --生成害虫
	if self.sickness > 0 and math.random() < (self.sickness/10) then --产生虫群（避免生成太多，这里还需要减少几率）
		local bugs = SpawnPrefab(math.random()<0.7 and "cropgnat" or "cropgnat_infester")
		if bugs ~= nil then
			bugs.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
		end
	end
end
function PerennialCrop:GetNextStage() --判定下一个阶段
	local data = {
		stage = 1,
		ishuge = false,
		isrotten = false,
		justgrown = false,
		stagedata = nil
	}
	if self.isrotten then --枯萎阶段->重生阶段
		data.stage = self.regrowstage
		data.stagedata = self.stages[data.stage]
	elseif self:GetGrowTime() <= 0 then --永恒阶段
		data.stage = self.stage
		data.stagedata = self.stages[data.stage]
		data.ishuge = self.ishuge --如果永恒的话，也得维持巨大化吧
	elseif self.stage >= self.stage_max then --成熟阶段->枯萎/巨型枯萎阶段
		if self.ishuge and self.stages_other.huge_rot ~= nil then
			data.stage = self.stage_max
			data.ishuge = true
			data.isrotten = true
			data.stagedata = self.stages_other.huge_rot
		elseif self.stages_other.rot ~= nil then
			data.stage = self.stage_max
			data.isrotten = true
			data.stagedata = self.stages_other.rot
		else --没有枯萎状态的话，只能回到重生阶段了
			data.stage = self.regrowstage
			data.stagedata = self.stages[data.stage]
		end
	else --生长阶段->下一个生长阶段（不管是否成熟）
		data.stage = self.stage + 1
		data.stagedata = self.stages[data.stage]
		data.justgrown = true
	end
	return data
end
function PerennialCrop:DoGrowth() --生长到下一阶段
	local data = self:GetNextStage()
	local soundkey = nil
	self.dogrowing = true
	if data.isrotten then
		soundkey = "grow_rot"
	elseif data.justgrown then
		local notzeron1 = self.nutrient1 > 0
		if --加个限制，不想它每次都去索取
			self.nutrient1 <= self.cost_nutrient or --1号肥影响生长速度，所以得多关照点
			self.nutrient2 <= 0 or self.nutrient3 <= 0 or self.moisture <= 0
		then
			self:CostNutrition(nil, true) --计算消耗之前，如果某些养料空了，就补充一下养料
		elseif not self.tended and self.ctltypes_l[3] then --肥料暂时不缺，但是照料是每次都得有的
			self:TendTo(nil, true)
		end
		if self.nutrient3 > 0 then --生长必需肥料的积累
			self:SetNutrient3(-self.cost_nutrient)
			self.num_nutrient = self.num_nutrient + 1
			if self.infested > 3 then --稍微减少一下侵扰值
				self.infested = self.infested - 3
			else
				self.infested = 0
			end
		end
		if notzeron1 then --只有一开始有的才消耗，不然都没有发挥作用就得消耗掉了！
			self:SetNutrient1(-self.cost_nutrient) --加速生长肥料的消耗
		end
		if not self.nosick then
			if self.nutrient2 > 0 then --预防疾病肥料的消耗
				self:SetNutrient2(-self.cost_nutrient)
				if self.sickness > 0.06 then
					self.sickness = self.sickness - 0.06
				else
					self.sickness = 0
				end
			else
				if self.sickness < 1 then
					self.sickness = math.min(1, self.sickness+0.02)
				end
			end
			self:SpawnPest()
		elseif self.sickness > 0 then
			self.sickness = 0
		end
		if self.moisture > 0 then --水分的积累
			self:SetMoisture(-self.cost_moisture)
			self.num_moisture = self.num_moisture + 1
		end
		if data.stage == self.stage_max then --如果成熟了
			local stagegrow = self.stage_max - self.regrowstage
			local countgrow = self.killjoystolerance
			if self.num_moisture >= stagegrow then --生长必需浇水
				countgrow = countgrow + 1
			end
			if self.num_nutrient >= stagegrow then --生长必需施肥
				countgrow = countgrow + 1
			end
			if self.goodseasons[TheWorld.state.season] then --在喜好的季节
				countgrow = countgrow + 1
			end
			if self.sickness <= 0.1 then --病害程度很低
				countgrow = countgrow + 1
			end
			if self.num_tended >= 1 and self.num_tended >= (stagegrow-1) then --被照顾次数至少得是生长阶段总数的-1次
				countgrow = countgrow + 1
			end

			self.num_perfect = countgrow
			if countgrow >= 5 and self.stages_other.huge ~= nil then --判断是否巨型
				data.ishuge = true
				soundkey = "grow_oversized"
			else
				soundkey = "grow_full"
			end

			--结算完成，清空某些数据
			self.num_nutrient = 0
			self.num_moisture = 0
			self.num_tended = 0
		else
			self.tended = false
		end
	elseif data.stage == self.regrowstage or data.stage == 1 then --重新开始生长时，清空某些数据
		self.num_nutrient = 0
		self.num_moisture = 0
		self.num_tended = 0
		self.infested = 0
		self.pollinated = 0
		self.num_perfect = nil
		self.tended = false
		if --加个限制，不想它每次都去索取
			self.nutrient1 <= self.cost_nutrient or --1号肥影响生长速度，所以得多关照点
			self.nutrient2 <= 0 or self.nutrient3 <= 0 or self.moisture <= 0
		then
			self:CostNutrition(nil, true) --计算消耗之前，如果某些养料空了，就补充一下养料
		end
	end
	if soundkey ~= nil and self.sounds[soundkey] ~= nil then
		self.inst.SoundEmitter:PlaySound(self.sounds[soundkey])
	end
	self.dogrowing = nil
	self:SetStage(data.stage, data.ishuge, data.isrotten)
end
local function OnPicked(inst, doer, loot)
	local crop = inst.components.perennialcrop
	if crop.fn_defend ~= nil then
		crop.fn_defend(inst, doer)
	end
	crop:GenerateLoot(doer, true, false)
	if not inst:IsValid() then --inst 在 crop:GenerateLoot() 里可能会被删除
		return
	end
	crop.num_nutrient = 0
	crop.num_moisture = 0
	crop.num_tended = 0
	crop.infested = 0
	crop.pollinated = 0
	crop.num_perfect = nil
	crop.tended = false
	crop.time_grow = nil

	crop.dogrowing = true
	crop:CostNutrition(nil, true) --采摘后得吸收养分
	crop.dogrowing = nil
	crop:SetStage(crop.regrowstage, false, false)
	if not crop.tended and crop.ctltypes_l[3] then
		crop:TendTo(nil, true)
	end
end
function PerennialCrop:SetStage(stage, ishuge, isrotten) --设置为某阶段
	if stage == nil or stage < 1 then
		stage = 1
	elseif stage > self.stage_max then
		stage = self.stage_max
	end

	--确定当前的阶段
	local rotten = false
	local huge = false
	local stage_data = nil

	if isrotten then
		if ishuge then
			if self.stages_other.huge_rot ~= nil then --腐烂、巨型状态
				stage = self.stage_max
				stage_data = self.stages_other.huge_rot
				rotten = true
				huge = true
				self.tended = true
			end
		end
		if stage_data == nil then
			if self.stages_other.rot ~= nil then --腐烂状态
				stage_data = self.stages_other.rot
				rotten = true
				self.tended = true
			else --如果没有腐烂状态就进入重新生长的阶段
				stage = self.regrowstage
				stage_data = self.stages[stage]
			end
		end
	elseif ishuge then
		stage = self.stage_max
		if self.stages_other.huge ~= nil then --巨型状态
			stage_data = self.stages_other.huge
			huge = true
		else --如果没有巨型状态就进入成熟阶段
			stage_data = self.stages[stage]
		end
		self.tended = true
	else
		stage_data = self.stages[stage]
		if stage == self.stage_max then
			self.tended = true
		end
	end

	--修改当前阶段数据
	self.stage = stage
	self.stagedata = stage_data
	self.isflower = stage_data.isflower
	self.isrotten = rotten
	self.ishuge = huge

	--设置动画
	if POPULATING or self.inst:IsAsleep() then
		self.inst.AnimState:PlayAnimation(stage_data.anim, true)
		TOOLS_L.RandomAnimFrame(self.inst)
	else
		self.inst.AnimState:PlayAnimation(stage_data.anim_grow)
		self.inst.AnimState:PushAnimation(stage_data.anim, true)
	end

	--设置是否可采摘
	if rotten or stage == self.stage_max then --腐烂、巨型、成熟阶段都是可采摘的
		TOOLS_P_L.TriggerPickableOn(self.inst, OnPicked,
			rotten and "dontstarve/wilson/harvest_berries" or "dontstarve/wilson/pickup_plants")
	elseif self.inst.components.pickable ~= nil then
		self.inst:RemoveComponent("pickable")
	end

	--设置是否可照顾
	if self.inst.components.farmplanttendable ~= nil then
		self.inst.components.farmplanttendable:SetTendable(not self.tended)
	end

	--尝试开始生长
	self:UpdateTimeMult() --更新生长速度
	if self.task_grow == nil then
		self:StartGrowing()
	end

	--额外设置
	if self.fn_stage ~= nil then
		self.fn_stage(self.inst, not self.isrotten and self.stage == self.stage_max) --第二个参数为：是否成熟/巨型成熟
	end
	if self.fn_researchstage ~= nil then
		self.fn_researchstage(self)
	end
end

local function AddLoot(loot, name, number)
	if loot[name] == nil then
		loot[name] = number
	else
		loot[name] = loot[name] + number
	end
end
function PerennialCrop:GenerateLoot(doer, ispicked, isburnt) --生成收获物
	local loot = {}
	local lootprefabs = {}
	local pos = self.inst:GetPosition()
	local product = self.product or "cutgrass"
	if self.ishuge then
		if self.isrotten then
			if self.loot_huge_rot ~= nil then
				for _, name in pairs(self.loot_huge_rot) do
					AddLoot(lootprefabs, name, 1)
				end
			else
				AddLoot(lootprefabs, "spoiled_food", 3)
				AddLoot(lootprefabs, "fruitfly", 2)
				AddLoot(lootprefabs, self.seed or "seeds", 1)
			end
			if self.pollinated >= self.pollinated_max then
				AddLoot(lootprefabs, "spoiled_food", 1)
			end
		else
			AddLoot(lootprefabs, self.product_huge or product, 1)
			if self.pollinated >= self.pollinated_max then --授粉成功，提高产量
				AddLoot(lootprefabs, product, 1)
			end
		end
	elseif self.stage < self.stage_max then
		if self.isrotten then
			AddLoot(lootprefabs, "spoiled_food", 1)
		else
			AddLoot(lootprefabs, math.random() < 0.5 and "cutgrass"or "twigs", 1)
			if self.isflower then
				AddLoot(lootprefabs, "petals", 1)
			end
		end
	else
		local numfruit = 1
		if self.num_perfect ~= nil then
			if self.num_perfect >= 5 then
				numfruit = 3
			elseif self.num_perfect >= 3 then
				numfruit = 2
			end
		end
		if self.pollinated >= self.pollinated_max then
			numfruit = numfruit + 1
		end
		AddLoot(lootprefabs, self.isrotten and "spoiled_food" or product, numfruit)
	end

	if not ispicked then --非采集时，多半是破坏
		local soil
		local skin = self.inst.components.skinedlegion:GetSkin()
		if skin == nil then
			soil = SpawnPrefab("siving_soil_item")
		else
			soil = SpawnPrefab("siving_soil_item", skin, nil, LS_C_UserID(self.inst, doer))
		end
		if soil ~= nil then
			soil.Transform:SetPosition(pos:Get())
			soil:PushEvent("l_autostack") --为了能自动叠加
		end
	end
	if isburnt then
		local lootprefabs2 = {}
		for name, num in pairs(lootprefabs) do
			if TUNING.BURNED_LOOT_OVERRIDES[name] ~= nil then
				AddLoot(lootprefabs2, TUNING.BURNED_LOOT_OVERRIDES[name], num)
			elseif PrefabExists(name.."_cooked") then
				AddLoot(lootprefabs2, name.."_cooked", num)
			elseif PrefabExists("cooked"..name) then
				AddLoot(lootprefabs2, "cooked"..name, num)
			else
				AddLoot(lootprefabs2, "ash", num)
			end
		end
		lootprefabs = lootprefabs2
	end

	for name, num in pairs(lootprefabs) do --生成实体并设置物理掉落
		if num > 0 then
			TOOLS_L.SpawnStackDrop(name, num, pos, nil, loot, { dropper = self.inst })
		end
	end
	if ispicked then
		-- if self.fn_pick ~= nil then
		-- 	self.fn_pick(self, doer, loot)
		-- end
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

function PerennialCrop:OnSave()
    local data = {
        nutrient1 = self.nutrient1 ~= 0 and self.nutrient1 or nil,
        nutrient2 = self.nutrient2 ~= 0 and self.nutrient2 or nil,
        nutrient3 = self.nutrient3 ~= 0 and self.nutrient3 or nil,
        moisture = self.moisture ~= 0 and self.moisture or nil,
		sickness = self.sickness > 0 and self.sickness or nil,
		stage = self.stage > 1 and self.stage or nil,
		isrotten = self.isrotten or nil,
		ishuge = self.ishuge or nil,
		infested = self.infested > 0 and self.infested or nil,
		pollinated = self.pollinated > 0 and self.pollinated or nil,
		num_nutrient = self.num_nutrient > 0 and self.num_nutrient or nil,
		num_moisture = self.num_moisture > 0 and self.num_moisture or nil,
		num_tended = self.num_tended > 0 and self.num_tended or nil,
		num_perfect = self.num_perfect ~= nil and self.num_perfect or nil,
		tended = self.tended or nil
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
function PerennialCrop:OnLoad(data)
    if data == nil then
        return
    end
	if data.nutrient1 ~= nil or data.nutrientgrow ~= nil then --兼容旧数据
		self.nutrient1 = math.min((data.nutrient1 or 0) + (data.nutrientgrow or 0), self.nutrient_max)
		self:SetTagNutrient1()
		if self.nutrient1 <= 0 then
			self.inst.legiontag_sivctl_timely = true
		else
			self.inst.legiontag_sivctl_timely = nil
		end
	end
	if data.nutrient2 ~= nil or data.nutrientsick ~= nil then
		self.nutrient2 = math.min((data.nutrient2 or 0) + (data.nutrientsick or 0), self.nutrient_max)
		self:SetTagNutrient2()
	end
	if data.nutrient3 ~= nil or data.nutrient ~= nil then
		self.nutrient3 = math.min((data.nutrient3 or 0) + (data.nutrient or 0), self.nutrient_max)
		self:SetTagNutrient3()
	end
    if data.moisture ~= nil then
        self.moisture = math.min(data.moisture, self.moisture_max)
		self:SetTagMoisture()
    end
	self.sickness = data.sickness or 0
	self.stage = data.stage or 1
	self.isrotten = data.isrotten and true or false
	self.ishuge = data.ishuge and true or false
	self.infested = data.infested or 0
	self.pollinated = data.pollinated or 0
	self.num_nutrient = data.num_nutrient or 0
	self.num_moisture = data.num_moisture or 0
	self.num_tended = data.num_tended or 0
	self.num_perfect = data.num_perfect
	self.tended = data.tended and true or false
	self:SetStage(self.stage, self.ishuge, self.isrotten)
	if data.time_dt ~= nil and data.time_dt > 0 then
		self.time_grow = data.time_dt
	end
end

function PerennialCrop:Pollinate(doer, value) --授粉
    if self.isrotten or self.stage == self.stage_max or self.pollinated >= self.pollinated_max then
		return
	end
	self.pollinated = self.pollinated + (value or 1)
end

function PerennialCrop:Infest(doer, value) --侵扰
	if self.isrotten then
		return false
	end

	self.infested = self.infested + (value or 1)
	if self.infested >= self.infested_max then
		self.infested = 0
		self:StopGrowing() --先清除生长进度
		self:SetStage(self.stage, self.ishuge, true) --再设置枯萎
	end

	return true
end
function PerennialCrop:Cure(doer) --治疗
	self.infested = 0
	self.sickness = 0
end

function PerennialCrop:Tendable(doer, wish) --是否能照顾
	if self.isrotten or self.stage == self.stage_max then
		return false
	end

	if wish == nil or wish then --希望是照顾
		return not self.tended
	else --希望是取消照顾
		return self.tended
	end
end
function PerennialCrop:TendTo(doer, wish) --照顾
	if not self:Tendable(doer, wish) then
		return false
	end

	if wish == nil or wish then --希望是照顾
		self.num_tended = self.num_tended + 1
		self.tended = true
	else --希望是取消照顾
		self.num_tended = self.num_tended - 1
		self.tended = false
	end
	if self.inst.components.farmplanttendable ~= nil then
		self.inst.components.farmplanttendable:SetTendable(not self.tended)
	end
	TOOLS_P_L.SpawnFxTend(self.inst, self.tended)

	return true
end
function PerennialCrop:OnSivCtlChange(newctl, oldctl, gameinit)
	if self.sivctls == nil then
		self.ctltypes_l = {}
		self.inst:fn_soiltype("1")
		return
	end
	if newctl then
		if self.ctltypes_l[newctl.type] then --新来的已经有了，那就结束
			return
		end
	elseif oldctl and oldctl.type ~= 3 and self.ctltypes_l[3] then --删除的太低级，那就结束
		self.ctltypes_l[oldctl.type] = nil
		return
	end
	local types = {}
	for ctl, ctlcpt in pairs(self.sivctls) do
		if ctl:IsValid() then
			types[ctlcpt.type] = true
		end
	end
	self.ctltypes_l = types
	if types[3] or (types[2] and types[1]) then
		self.inst:fn_soiltype("4")
	elseif types[2] then
		self.inst:fn_soiltype("3")
	elseif types[1] then
		self.inst:fn_soiltype("2")
	else
		self.inst:fn_soiltype("1")
	end
end
PerennialCrop.SetMoisture = TOOLS_P_L.SetMoisture --水分
function PerennialCrop:SetNutrient1(value, notag) --1号肥加速生长
    if value > 0 then
        if self.nutrient1 < self.nutrient_max then
            local oldv = self.nutrient1
            self.nutrient1 = math.min(self.nutrient_max, self.nutrient1+value)
            if (oldv > 0 and self.nutrient1 <= 0) or (oldv <= 0 and self.nutrient1 > 0) then --发生了临界变化
                self:UpdateTimeMult()
            end
			if self.nutrient1 <= 0 then
				self.inst.legiontag_sivctl_timely = true
			else
				self.inst.legiontag_sivctl_timely = nil
			end
			if not notag then
                self:SetTagNutrient1()
            end
        end
    elseif value < 0 then
        if self.nutrient1 > 0 then
            self.nutrient1 = self.nutrient1 + value --可以为负数
            if self.nutrient1 <= 0 then
                self:UpdateTimeMult()
				self.inst.legiontag_sivctl_timely = true
			else
				self.inst.legiontag_sivctl_timely = nil
            end
            if not notag then
                self:SetTagNutrient1()
            end
        end
    end
end
PerennialCrop.SetNutrient2 = TOOLS_P_L.SetNutrient2 --2号肥减少疾病
PerennialCrop.SetNutrient3 = TOOLS_P_L.SetNutrient3 --3号肥生长必需
PerennialCrop.SetTagMoisture = TOOLS_P_L.SetTagMoisture
PerennialCrop.SetTagNutrient1 = TOOLS_P_L.SetTagNutrient1
PerennialCrop.SetTagNutrient2 = TOOLS_P_L.SetTagNutrient2
PerennialCrop.SetTagNutrient3 = TOOLS_P_L.SetTagNutrient3
function PerennialCrop:Fertilize(item, doer, nutsover, moiover) --用肥料施肥
    local dd = TOOLS_P_L.CostFertilizer(self.inst, item, doer, {
					self.nutrient_max - self.nutrient1,
					self.nutrient_max - self.nutrient2,
					self.nutrient_max - self.nutrient3
				}, 0, nutsover, moiover, nil)
    if dd ~= nil then
        if dd.n1 ~= nil then
            self:SetNutrient1(dd.n1)
        end
        if dd.n2 ~= nil then
            self:SetNutrient2(dd.n2)
        end
        if dd.n3 ~= nil then
            self:SetNutrient3(dd.n3)
        end
        return true
    end
end
function PerennialCrop:CostNutrition(actlcpt, dosoil) --从 水肥照料机、耕地 索取养料、水分、照顾
    local dd, tend = TOOLS_P_L.CostNutrition(self.inst, self.sivctls, actlcpt, {
						self.nutrient_max - self.nutrient1,
						self.nutrient_max - self.nutrient2,
						self.nutrient_max - self.nutrient3
					}, self.moisture_max-self.moisture, self.tended, dosoil, nil)
    if dd ~= nil then
        if dd.mo ~= nil then
            self:SetMoisture(dd.mo)
			TOOLS_P_L.SpawnFxMoi(self.inst)
        end
        if dd.n1 ~= nil then
            self:SetNutrient1(dd.n1)
        end
        if dd.n2 ~= nil then
            self:SetNutrient2(dd.n2)
        end
        if dd.n3 ~= nil then
            self:SetNutrient3(dd.n3)
        end
		if dd.n1 ~= nil or dd.n2 ~= nil or dd.n3 ~= nil then
			TOOLS_P_L.SpawnFxNut(self.inst)
		end
    end
	if not self.tended and tend then
		self:TendTo(nil, true)
	end
end

function PerennialCrop:DisplayCrop(oldcrop, doer) --替换作物：把它的养料占为己有
	local oldcpt = oldcrop.components.perennialcrop
	self:SetNutrient1(oldcpt.nutrient1)
	self:SetNutrient2(oldcpt.nutrient2)
	self:SetNutrient3(oldcpt.nutrient3)
	self:SetMoisture(oldcpt.moisture)

	oldcpt:GenerateLoot(nil, true, false)
	if oldcpt.fn_defend ~= nil and doer then
		oldcpt.fn_defend(oldcrop, doer)
	end

	local x, y, z = oldcrop.Transform:GetWorldPosition()
	SpawnPrefab("dirt_puff").Transform:SetPosition(x, y, z)
end

return PerennialCrop
