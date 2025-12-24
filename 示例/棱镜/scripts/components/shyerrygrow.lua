local TOOLS_P_L = require("tools_plant_legion")
local ShyerryGrow = Class(function(self, inst)
    self.inst = inst
    self.stage_max = 3 --最大生长阶段
    self.growth_max = 48 --生长进度达到该值就进入下一阶段。48点最快需30天才能到最高阶段，80点则是最快50天(=160点/2次*5分/8分)
    self.moisture_max = 500 --最大蓄水量
	self.nutrient_max = 500 --最大蓄肥量
    self.leveldata = {} --所有的阶段数据

    self.stage = 1 --当前生长阶段
    self.growth = 0 --当前积累的生长进度
    self.level = {} --当前阶段的数据
    self.fruit = 0 --当前积累的果储进度
    self.nutrient1 = 0 --当前肥量（加快再生频率）
	self.nutrient2 = 0 --当前肥量（颤栗果积累更快）
	self.nutrient3 = 0 --当前肥量（大树几率更高）
    self.moisture = 0 --当前水量（再生数量更多）

    self.numline = 1 --当前线路条数
    self.linedata = { --所有线路数据
        -- {
        --     theta = math.random() * TWOPI, --当前线路的基础角度
        --     posoff = { --当前线路的所有生长位置点的偏移量(因为树可能会被转移，所以用偏移量更好)
        --         { x = x1, z = z1, badtile = true } }, --badtile 代表当前位置的地皮无法长树
        --     trees = {} --当前线路的树
        -- }
    }

    -- self.task_grow = nil
    -- self.time_start = nil
    -- self.time_grow = nil
end)

local spawnRadius = 2.5 --生成与检测的间隔距离
local spawnTagsCant = { "NOBLOCK", "FX", "INLIMBO", "DECOR", "_inventoryitem", "_health" }
local bigTreeChance = { 0.3, 0.4, 0.5 }
local fruitPoint = 16
local costNutrient = 4 --肥料消耗
local costMoisture = 10 --水分消耗
local aFruitPoint = CONFIGS_LEGION.SHYCOREFRUITS or 1
local aGrowthPoint = CONFIGS_LEGION.SHYCOREGROWTH or 1

local function OnMoiWater(self, num, ...)
	if num > 0 then
		self.inst.components.shyerrygrow:SetMoisture(num)
	end
end
local function OnIsRaining(inst)
	inst.components.shyerrygrow:SetMoisture(100)
end

function ShyerryGrow:InitLineData()
    local starttheta = math.random() * TWOPI
    local numline = self.leveldata[self.stage_max].numline
    local linemax = numline + 2 --增加随机条数，不然就是个正边形了
    local linekey = {}
    for i = 1, linemax, 1 do
        linekey[i] = i
    end
    for i = 1, numline, 1 do
        local idx = table.remove(linekey, math.random(#linekey)) --一开始就是随机
        self.linedata[i] = {
            theta = starttheta + TWOPI/linemax*idx + TWOPI/12*(math.random()-0.5), --在-15到15度之间随机偏移
            trees = {}, posoff = {}
        }
    end
end
function ShyerryGrow:SetUp(leveldata)
    self.leveldata = leveldata
    self.stage_max = #leveldata
    self:SetStage(1)
    TOOLS_P_L.TriggerMoistureOn(self.inst, OnMoiWater, OnIsRaining)
    self:StartGrowing()
    self:SetTagNutrient1()
    self:SetTagNutrient2()
    self:SetTagNutrient3()
    self:SetTagMoisture()
    TOOLS_P_L.FindSivCtls(self.inst, self, nil, true, POPULATING) --1号肥重要，需及时吸取来加速生长
end
function ShyerryGrow:SetStage(stage)
    if stage == nil or stage < 1 then
		stage = 1
	elseif stage > self.stage_max then
		stage = self.stage_max
	end

    self.stage = stage
    self.level = self.leveldata[stage]
    self.numline = self.level.numline
    if self.level.fn_stage ~= nil then
        self.level.fn_stage(self.inst, self)
    end
end

ShyerryGrow.SetTagMoisture = TOOLS_P_L.SetTagMoisture
ShyerryGrow.SetTagNutrient1 = TOOLS_P_L.SetTagNutrient1
ShyerryGrow.SetTagNutrient2 = TOOLS_P_L.SetTagNutrient2
ShyerryGrow.SetTagNutrient3 = TOOLS_P_L.SetTagNutrient3
ShyerryGrow.SetMoisture = TOOLS_P_L.SetMoisture --含水量提高生长量
function ShyerryGrow:SetNutrient1(value, notag) --1号肥加快生长频率
    if value > 0 then
        if self.nutrient1 < self.nutrient_max then
            local oldv = self.nutrient1
            self.nutrient1 = math.min(self.nutrient_max, self.nutrient1+value)
            if (oldv > 0 and self.nutrient1 <= 0) or (oldv <= 0 and self.nutrient1 > 0) then --发生了临界变化
                self:StartGrowing()
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
                self:StartGrowing()
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
ShyerryGrow.SetNutrient2 = TOOLS_P_L.SetNutrient2 --2号肥提高果实产量
ShyerryGrow.SetNutrient3 = TOOLS_P_L.SetNutrient3 --3号肥提升颤栗树体型
function ShyerryGrow:Fertilize(item, doer, nutsover, moiover) --用肥料施肥
    local dd = TOOLS_P_L.CostFertilizer(self.inst, item, doer, {
                    self.nutrient_max - self.nutrient1,
                    self.nutrient_max - self.nutrient2,
                    self.nutrient_max - self.nutrient3
                }, self.moisture_max-self.moisture, nutsover, moiover, nil)
    if dd ~= nil then
        if dd.mo ~= nil then
            self:SetMoisture(dd.mo)
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
        return true
    end
end
function ShyerryGrow:CostNutrition(actlcpt, dosoil) --从 水肥照料机、耕地 索取养料、水分、照顾
    local dd, tend = TOOLS_P_L.CostNutrition(self.inst, self.sivctls, actlcpt, {
                        self.nutrient_max - self.nutrient1,
                        self.nutrient_max - self.nutrient2,
                        self.nutrient_max - self.nutrient3
                    }, self.moisture_max-self.moisture, true, dosoil, costMoisture*2)
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
end

function ShyerryGrow:IsValidTile(x, z) --判断再生点所属地皮是否有效
    local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
    if tile ~= nil and TileGroupManager:IsLandTile(tile) then --是大陆地皮
        if tile == GROUND.DESERT_DIRT or not GROUND_HARD[tile] then --可种植植物的地皮，沙漠地皮也可以的
            return true
        end
    end
    return false
end
function ShyerryGrow:CanSpawnHere(x, z) --判断再生点附近有没有阻碍物
    local ents = TheSim:FindEntities(x, 0, z, spawnRadius-0.3, nil, spawnTagsCant, nil)
    for _, v in ipairs(ents) do
        if v ~= self.inst and v.entity:IsVisible() then
            return false
        end
    end
    return true
end
function ShyerryGrow:DoGrowth() --开始生长
    local notzeron1 = self.nutrient1 > 0
    if --加个限制，不想它每次都去索取
        self.nutrient1 <= costNutrient or --1号肥影响生长频率，所以得多关照点
        self.nutrient2 <= 0 or self.nutrient3 <= 0 or self.moisture <= 0
    then
        self:CostNutrition(nil, true) --生长前，如果某些养料空了，就补充一下养料
    end
    local growbonus = (self.nutrient1 > 0 and 1 or 0) + (self.nutrient2 > 0 and 1 or 0) +
                        (self.nutrient3 > 0 and 1 or 0) + (self.moisture > 0 and 1 or 0)
    if self.linedata[1] == nil then
        self:InitLineData()
    end
    local x1, y1, z1 = self.inst.Transform:GetWorldPosition()
    local numfruit = 0
    local numtree = self.numline
    local numtree2
    if self.moisture > 0 then --含水量增加50%的再生数量
        numtree2 = numtree*1.5
        numtree = math.floor(numtree2) --整数部分
        if numtree2 > numtree and math.random() < (numtree2-numtree) then --小数部分
            numtree = numtree + 1
        end
    end
    numtree2 = numtree

    local hasfruit = self.level.fruitchance or 0.02
    if self.nutrient2 > 0 then --2号肥能增加长果实几率
        hasfruit = hasfruit + 0.02
    end
    if math.random() < hasfruit then
        hasfruit = true
    else
        hasfruit = false
        if self.nutrient2 > 0 then --2号肥能在没开花时增加保底的果储进度
            numfruit = numfruit + aFruitPoint
        end
    end

    local numlinetree = (self.level.numlinetree or 2) + growbonus
    for i = 1, self.numline, 1 do
        local line = self.linedata[i]
        local xx = x1
        local zz = z1
        if line == nil then --补充线路数据（防止以后增加生长线路数量，得兼容这个）
            line = {
                theta = math.random() * TWOPI, --只能用随机角度了
                posoff = {}, trees = {}
            }
            self.linedata[i] = line
        end
        for j = 1, numlinetree, 1 do
            local tree = line.trees[j]
            local posoff = line.posoff[j]
            if posoff == nil then --补充位置数据
                local theta = line.theta + TWOPI/4*(math.random()-0.5) --在-45到45度之间随机偏移
                if j ~= 1 then
                    xx = xx + spawnRadius*math.cos(theta)
                    zz = zz - spawnRadius*math.sin(theta)
                else --第一个位置需要离母树远一点，不然就太挤了
                    xx = xx + (spawnRadius+1)*math.cos(theta)
                    zz = zz - (spawnRadius+1)*math.sin(theta)
                end
                posoff = { x = xx - x1, z = zz - z1 }
                line.posoff[j] = posoff
            else
                xx = x1 + posoff.x
                zz = z1 + posoff.z
            end
            if tree == nil or not tree:IsValid() then
                if self:IsValidTile(xx, zz) then
                    posoff.badtile = nil
                else
                    posoff.badtile = true
                    break --一旦这个位置地皮没法生长，就会阻断这条线路接下来的生长，只能去判断别的线路了
                end
                if self:CanSpawnHere(xx, zz) then --终于可以长树了
                    local prefab
                    if hasfruit then
                        prefab = "shyerryflower"
                        hasfruit = false
                    else
                        prefab = "shyerrytree"..tostring(math.random(4))
                        local chance = bigTreeChance[self.stage] or 0.5
                        if self.nutrient3 > 0 then --3号肥能增加长出大树的几率
                            chance = chance + 0.35
                        end
                        if math.random() >= chance then
                            prefab = prefab.."_s"
                        end
                    end
                    tree = SpawnPrefab(prefab)
                    if tree ~= nil then
                        tree.AnimState:PlayAnimation("grow")
                        tree.AnimState:PushAnimation("idle", true)
                        tree.Transform:SetPosition(xx, 0, zz)
                    end
                    line.trees[j] = tree
                    numtree = numtree - 1
                    if numtree <= 0 then --长完了，结束吧
                        break
                    end
                end
            end
        end
        if numtree <= 0 then --长完了，结束吧
            break
        end
    end

    if numtree ~= numtree2 then --说明成功长了树
        self:SetNutrient3(-costNutrient) --3号肥只在长出树时才消耗
        if not TheWorld.state.israining and not TheWorld.state.issnowing then --下雨/雪时不会消耗。含水量只在长出树时才消耗
            self:SetMoisture(-costMoisture)
        end
    else
        if hasfruit then --颤栗花没法长出时，由母树自己长颤栗果
            numfruit = numfruit + fruitPoint
        end
    end
    self:SetNutrient2(-costNutrient)
    if notzeron1 then --只有一开始有的才消耗，不然都没有发挥作用就得消耗掉了！
        self:SetNutrient1(-costNutrient)
    end
    if self.stage < self.stage_max then --只有最高阶段才能积累果储进度
        numfruit = 0
    elseif self.nutrient2 > 0 and numtree/numtree2 >= 0.6 then --2号肥能在60%的树没法长出时增加果储进度
        numfruit = numfruit + aFruitPoint
    end

	local growth = self.growth + (growbonus > 0 and 2*aGrowthPoint or aGrowthPoint)
    if growth >= self.growth_max then --生长结算
        if self.stage >= self.stage_max then --已经是最高阶段了，那就果实+1
            self.growth = growth - self.growth_max
            numfruit = numfruit + fruitPoint
        elseif self.stage == (self.stage_max-1) then
            if growbonus >= 4 then --肥料和水分都得有，才能长到最高阶段
                self.growth = growth - self.growth_max
                self:SetStage(self.stage + 1)
            end
        else
            self.growth = growth - self.growth_max
            self:SetStage(self.stage + 1)
        end
    else
        self.growth = growth
    end
    if numfruit > 0 then
        self:SetFruit(self.fruit + numfruit)
    end
end

function ShyerryGrow:TryDoGrowth() --循环生长
	if self.time_grow == nil then
		return
	end
	if self.time_grow <= 0 then
		self.time_grow = nil
		return
	end
	local growtime = self:GetGrowTime()
	if self.time_grow >= growtime then
		self.time_grow = self.time_grow - growtime
		self:DoGrowth()
		self:TryDoGrowth() --继续循环判断
	end
end
function ShyerryGrow:TimePassed(time, nogrow)
	self.time_grow = (self.time_grow or 0) + time
    if not nogrow then
        self:TryDoGrowth()
    end
end
function ShyerryGrow:GetGrowTime()
    if self.nutrient1 > 0 then --1号肥加快再生频率。从8分钟加快到5分钟
        return 300
    else
        return TUNING.TOTAL_DAY_TIME
    end
end
function ShyerryGrow:SetFruit(newv) --因为果实数量影响贴图，所以单独写个函数管理这个
    if self.stage < self.stage_max then --最高阶段才能有果储进度
        self.fruit = 0
        return
    end
    local vmax = self.level.fruitmax * fruitPoint
    if newv >= vmax then
        newv = vmax
    elseif newv < 0 then
        newv = 0
    end
    if newv ~= self.fruit then
        if self.level.fn_fruit ~= nil then --本质上就是为了改贴图，没这个函数干脆不用算了
            local oldnum = math.floor(self.fruit/fruitPoint)
            local newnum = math.floor(newv/fruitPoint)
            if oldnum ~= newnum then
                self.level.fn_fruit(self.inst, self, newnum)
            end
        end
        self.fruit = newv
    end
end
function ShyerryGrow:StartGrowing()
    if self.task_grow ~= nil then
        self.task_grow:Cancel()
        self.task_grow = nil
    end
    if self.time_start == nil then
		self.time_start = GetTime()
	end

    local time = self:GetGrowTime()
    local timedelay
    if self.time_grow ~= nil then
        timedelay = math.max(2, time - self.time_grow)
    else
        timedelay = time
    end
    self.task_grow = self.inst:DoPeriodicTask(time, function(inst, self)
        if self.time_start ~= nil then
            local dt = GetTime() - self.time_start
            self.time_start = GetTime()
            self:TimePassed(dt)
        else --和 time_start 同步
            self.task_grow:Cancel()
            self.task_grow = nil
        end
    end, timedelay+5*math.random(), self)
end

ShyerryGrow.LongUpdate = TOOLS_P_L.LongUpdate

function ShyerryGrow:OnSave()
    local data = {
        stage = self.stage > 1 and self.stage or nil,
        nutrient1 = self.nutrient1 ~= 0 and self.nutrient1 or nil,
        nutrient2 = self.nutrient2 ~= 0 and self.nutrient2 or nil,
        nutrient3 = self.nutrient3 ~= 0 and self.nutrient3 or nil,
        moisture = self.moisture ~= 0 and self.moisture or nil,
        growth = self.growth > 0 and self.growth or nil,
        fruit = self.fruit > 0 and self.fruit or nil
    }
	local dt = self.time_grow
	if self.time_start ~= nil then
		dt = (dt or 0) + GetTime() - self.time_start
	end
	if dt ~= nil and dt > 0 then
		data.time_grow = dt
	end

    ------记下线路所有数据
    local linemax = self.leveldata[self.stage_max].numline
    local numlinetree = (self.level.numlinetree or 2) + 4 --一条线路的最大数量都得算进去
    local linedata = {}
    for i = 1, linemax, 1 do
        local line = self.linedata[i]
        if line ~= nil then
            local dd_line = { theta = line.theta, trees = {}, posoff = line.posoff } --角度数据必须记下来
            if i <= self.numline then --未开始启用的线路不用记录树的数据
                for j = 1, numlinetree, 1 do
                    local tree = line.trees[j]
                    if tree ~= nil and tree:IsValid() and tree.persists then
                        dd_line.trees[j] = tree.GUID --记住树的实体id即可
                    end
                end
            end
            linedata[i] = dd_line
        end
    end
    data.linedata = linedata

    return data
end
function ShyerryGrow:OnLoad(data)
    if data == nil then
        return
    end
    if data.nutrient2 ~= nil then
        self.nutrient2 = math.min(data.nutrient2, self.nutrient_max)
        self:SetTagNutrient2()
    end
    if data.nutrient3 ~= nil then
        self.nutrient3 = math.min(data.nutrient3, self.nutrient_max)
        self:SetTagNutrient3()
    end
    if data.moisture ~= nil then
        self.moisture = math.min(data.moisture, self.moisture_max)
        self:SetTagMoisture()
    end
    if data.growth ~= nil then self.growth = data.growth end
    if data.time_grow ~= nil then self.time_grow = data.time_grow end
    if data.stage ~= nil then
		self:SetStage(data.stage)
	end
    if data.fruit ~= nil then
        self:SetFruit(data.fruit)
    end
    if data.nutrient1 ~= nil then
        if data.nutrient1 > 0 then
            self.nutrient1 = math.min(data.nutrient1, self.nutrient_max)
            self.inst.legiontag_sivctl_timely = nil
            self:SetTagNutrient1()
            self:StartGrowing() --1号肥增加生长频率，所以这里得重新设定生长的周期函数
        else
            self.nutrient1 = data.nutrient1
            self.inst.legiontag_sivctl_timely = true
        end
    end
    if data.linedata ~= nil then
        local linemax = self.leveldata[self.stage_max].numline
        local linedata = {}
        for i = 1, linemax, 1 do
            local line = data.linedata[i]
            if line ~= nil then
                linedata[i] = { theta = line.theta, trees = {}, posoff = line.posoff or {} }
            end
        end
        self.linedata = linedata
    end
end
function ShyerryGrow:LoadPostPass(newents, data)
    if data == nil then
        return
    end
    if data.linedata ~= nil then
        local numlinetree = (self.level.numlinetree or 2) + 4 --一条线路的最大数量都得算进去
        for i = 1, self.numline, 1 do --未开始启用的线路不用找树
            local line = data.linedata[i]
            local linenow = self.linedata[i]
            if linenow ~= nil and line ~= nil and line.trees ~= nil then
                line = line.trees
                for j = 1, numlinetree, 1 do
                    if line[j] ~= nil then
                        local tree = newents[line[j]]
                        if tree ~= nil then
                            linenow.trees[j] = tree.entity
                        end
                    end
                end
            end
        end
    end
end

return ShyerryGrow
