local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local WEED_DEFS = require("prefabs/weed_defs").WEED_DEFS
local TOOLS_L = require("tools_legion")
local prefs = {}
local defs = {}

--Tip：mod里再次加载农场作物的动画会导致官方的作物动画不显示。因为官方作物动画有加载顺序限制，一旦mod里引用会导致顺序变化

local function SetDeploySmartRadius(inst, radkey)
    --反正就是种植半径的一半
    inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[radkey or DEPLOYSPACING.LESS] / 2)
end

--------------------------------------------------------------------------
--[[ 合并所有作物数据，并加入个性化数据 ]]
--------------------------------------------------------------------------

local flowerMaps = {
	corn = 			{ sprout = true, small = true, medium = true 			   					 },
	dragonfruit = 	{ 				 small = true, medium = true, grown = true 					 },
	durian = 		{ 				 small = true, medium = true 			   					 },
	eggplant = 		{ 				 small = true, medium = true 			   					 },
	onion = 		{ 				 small = true 							   					 },
	pepper = 		{ 				 small = true, medium = true 			   					 },
	pomegranate = 	{ 				 small = true, medium = true, grown = true, oversized = true },
	potato = 		{ 				 small = true, medium = true 			   					 },
	pumpkin = 		{ 				 small = true, medium = true, grown = true, oversized = true },
	tomato = 		{ 							   medium = true 			   					 },
	watermelon = 	{ 							   medium = true 			   					 },

	weed_forgetmelots = { 			 small = true, medium = true, grown = true 					 },
	weed_ivy = 			{ 						   medium = true, grown = true 					 },
	weed_tillweed = 	{ 			 small = true, medium = true, grown = true 					 },

	pineananas = 	{ 							   medium = true 			   					 },
	gourd =			{ 							   medium = true 			   					 }
}
local regrowMaps = {
	asparagus = 2,
	garlic = 2,
	pumpkin = 3,
	corn = 3,
	onion = 3,
	potato = 3,
	dragonfruit = 3,
	pomegranate = 3,
	eggplant = 3,
	tomato = 3,
	watermelon = 3,
	pepper = 3,
	durian = 3,
	carrot = 2,

	weed_forgetmelots = 1,
	weed_tillweed = 1,
	weed_firenettle = 1,
	weed_ivy = 1,

	pineananas = 3,
	gourd = 3
}

local function Fn_researchstage(self)
	local stage
	if self.isrotten then
		if self.ishuge then --枯萎巨型：5+3
			stage = self.stage_max + 3
		else --枯萎：5+2
			stage = self.stage_max + 2
		end
	else
		if self.ishuge then --巨型：5+1
			stage = self.stage_max + 1
		else
			stage = self.stage
		end
	end
	self.inst._research_stage:set(stage - 1) -- to make it a 0 a based range
end
local function Fn_researchstage_weed(self)
	local stage
	local def = WEED_DEFS[self.inst.plantregistrykey]
	if self.isrotten then --枯萎：3+1为实际的枯萎状态、3+2为被采摘等待重生的状态
		stage = (#def.plantregistryinfo) - self.stage_max
		if stage == 1 then
			stage = self.stage_max + 1
		elseif stage > 1 then
			stage = self.stage_max + math.random(stage) --随机设置一个官方阶段，这样就能兼容了
		else
			stage = self.stage
		end
	else
		stage = self.stage
	end
	self.inst._research_stage:set(stage - 1)
end

for k, v in pairs(PLANT_DEFS) do
	if k ~= "randomseed" then
		local data = {
			tags = v.tags,
			build = v.build, bank = v.bank,
			fireproof = v.fireproof, --是否防火
			nomagicgrow = v.nomagicgrow, --是否不能催熟（原创）
			nosick = v.nosick, --是否不产生病虫害（原创）
			cangrowindrak = v.cangrowindrak, --是否能在黑暗中生长（原创）
			sounds = v.sounds, --音效
			prefab = v.prefab.."_legion", --作物 代码名称
			prefab_old = v.prefab, --作物 原代码名称（目前是展示名字时使用）
			product = v.product, --产物 代码名称
			product_huge = v.product_oversized, --巨型产物 代码名称
			seed = v.seed, --种子 代码名称
			loot_huge_rot = v.loot_oversized_rot, --巨型产物腐烂后的收获物
			cost_moisture = 1, --需水量
			cost_nutrient = 2, --需肥量(这里只需要一个量即可，不需要关注肥料类型)
			stages = {}, --该植物生长有几个阶段，每个阶段的动画，以及是否处在花期（原创）
			stages_other = { huge = nil, huge_rot = nil, rot = nil }, --巨大化阶段、巨大化枯萎、枯萎等阶段的数据（原创）
			regrowstage = 1, --枯萎或者采摘后重新开始生长的阶段（原创）
			goodseasons = v.good_seasons, --喜好季节：{autumn = true, winter = true, spring = true, summer = true}
			killjoystolerance = v.max_killjoys_tolerance, --扫兴容忍度：一般都为0
			fn_common = v.fn_common, --额外设定函数（通用）：fn(inst)
			fn_server = v.fn_server, --额外设定函数（主机）：fn(inst)
			fn_defend = v.fn_defend, --作物被采集/破坏时会寻求庇护的函数：fn(inst, target)
			fn_stage = v.fn_stage, --每次设定生长阶段时额外触发的函数：fn(inst, isfull)
			fn_researchstage = v.fn_researchstage or Fn_researchstage,
			stage_netvar = v.stage_netvar
		}

		--确定花期map（其他mod想要增加花期，可仿造目前格式写在PLANT_DEFS中即可）
		local flowermap = v.flowermap or flowerMaps[k]

		--重新改生长阶段数据
		for _, v2 in pairs(v.plantregistryinfo) do
			local stage = {
				name = v2.text, --该阶段的名字
				anim = v2.anim,
				anim_grow = v2.grow_anim,
				isflower = (flowermap ~= nil and flowermap[v2.text]) or nil,
				time = nil --生长时间、或枯萎时间、或重生时间
			}
			if v2.text == "oversized" then
				stage.name = "huge"
				stage.time = 6 * TUNING.TOTAL_DAY_TIME --巨型作物，6天后枯萎
				data.stages_other.huge = stage
			elseif v2.text == "rotting" then
				stage.name = "rot"
				stage.time = 4 * TUNING.TOTAL_DAY_TIME --枯萎作物，4天后重新开始生长
				data.stages_other.rot = stage
			elseif v2.text == "oversized_rotting" then
				stage.name = "huge_rot"
				stage.time = 5 * TUNING.TOTAL_DAY_TIME --巨型枯萎作物，5天后重新开始生长
				data.stages_other.huge_rot = stage
			else
				table.insert(data.stages, stage)
			end
		end

		local countstage = #data.stages
		if countstage >= 3 then
			--确定生长时间
			local averagetime = 7*TUNING.TOTAL_DAY_TIME / (countstage-2) --不算发芽时间，总共7天成熟
			data.stages[1].time = 14 * TUNING.SEG_TIME --14/16天发芽
			data.stages[countstage].time = 4 * TUNING.TOTAL_DAY_TIME --成熟作物，4天后枯萎
			for _, v3 in pairs(data.stages) do
				if v3.time == nil then
					v3.time = averagetime
				end
			end

			--重新改需水量
			if v.cost_moisture ~= nil then --获取自定义的需水量
				data.cost_moisture = v.cost_moisture
			elseif v.moisture.drink_rate == TUNING.FARM_PLANT_DRINK_LOW then
				data.cost_moisture = 1
			elseif v.moisture.drink_rate == TUNING.FARM_PLANT_DRINK_MED then
				data.cost_moisture = 2
			elseif v.moisture.drink_rate == TUNING.FARM_PLANT_DRINK_HIGH then
				data.cost_moisture = 4
			end

			--重新改需肥量
			for _,v3 in pairs(v.nutrient_consumption) do
				if v3 ~= nil and data.cost_nutrient < v3 then
					data.cost_nutrient = v3
				end
			end
			if data.cost_nutrient > 2 and data.cost_nutrient <= 4 then
				data.cost_nutrient = 3
			elseif data.cost_nutrient > 4 then
				data.cost_nutrient = 4
			end

			--确定再生的阶段
			if v.regrowstage ~= nil then
				data.regrowstage = v.regrowstage
			elseif regrowMaps[k] ~= nil then
				data.regrowstage = regrowMaps[k]
			end
			if data.regrowstage >= countstage then
				data.regrowstage = 1
			end

			defs[k] = data
		end
	end
end

for k, v in pairs(WEED_DEFS) do
	local data = {
		tags = v.tags or v.extra_tags,
		build = v.build, bank = v.bank,
		fireproof = v.fireproof, --是否防火
		nomagicgrow = v.nomagicgrow, --是否不能催熟（原创）
		nosick = v.nosick, --是否不产生病虫害（原创）
		cangrowindrak = v.cangrowindrak, --是否能在黑暗中生长（原创）
		sounds = v.sounds, --音效
		prefab = v.prefab.."_legion", --作物 代码名称
		prefab_old = v.prefab, --作物 原代码名称（目前是展示名字时使用）
		product = v.product, --产物 代码名称（对于杂草，是可能为空的）
		product_huge = v.product_oversized, --巨型产物 代码名称
		seed = v.seed, --种子 代码名称
		loot_huge_rot = v.loot_oversized_rot, --巨型产物腐烂后的收获物
		cost_moisture = 1, --需水量
		cost_nutrient = 2, --需肥量(这里只需要一个量即可，不需要关注肥料类型)
		stages = {}, --该植物生长有几个阶段，每个阶段的动画，以及是否处在花期（原创）
		stages_other = { rot = nil }, --枯萎等阶段的数据（原创）
		regrowstage = 1, --枯萎或者采摘后重新开始生长的阶段（原创）
		goodseasons = v.good_seasons or {}, --喜好季节：{autumn = true, winter = true, spring = true, summer = true}
		killjoystolerance = v.killjoystolerance or 1, --扫兴容忍度：杂草为1，容忍度比作物高
		fn_common = v.fn_common, --额外设定函数（通用）：fn(inst)
		fn_server = v.fn_server or v.masterpostinit, --额外设定函数（主机）：fn(inst)
		fn_defend = v.fn_defend, --作物被采集/破坏时会寻求庇护的函数：fn(inst, target)
		-- fn_stage = v.fn_stage or v.OnMakeFullFn, --每次设定生长阶段时额外触发的函数：fn(inst, isfull)
		fn_researchstage = v.fn_researchstage or Fn_researchstage_weed,
		stage_netvar = v.stage_netvar
	}

	--确定花期map（其他mod想要增加花期，可仿造目前格式写在PLANT_DEFS中即可）
	local flowermap = v.flowermap or flowerMaps[k]

	--重新改生长阶段数据
	for _, v2 in pairs(v.plantregistryinfo) do
		if v2.text ~= "bolting" then --bolting相当于是杂草的枯萎，但我觉得用picked来当枯萎更好
			local stage = {
				name = v2.text, --该阶段的名字
				anim = v2.anim,
				anim_grow = v2.grow_anim,
				isflower = (flowermap ~= nil and flowermap[v2.text]) or nil,
				time = nil --生长时间、或枯萎时间、或重生时间
			}
			if v2.text == "picked" then
				stage.name = "rot"
				stage.time = 4 * TUNING.TOTAL_DAY_TIME --枯萎作物，4天后重新开始生长
				data.stages_other.rot = stage
			else
				table.insert(data.stages, stage)
			end
		end
	end

	local countstage = #data.stages
	if countstage >= 2 then
		--确定生长时间
		local averagetime = 4*TUNING.TOTAL_DAY_TIME / (countstage-1) --总共4天成熟
		data.stages[countstage].time = 2 * TUNING.TOTAL_DAY_TIME --成熟作物，2天后枯萎
		for _, v3 in pairs(data.stages) do
			if v3.time == nil then
				v3.time = averagetime
			end
		end

		--重新改需水量
		if v.cost_moisture ~= nil then --获取自定义的需水量
			data.cost_moisture = v.cost_moisture
		elseif v.moisture.drink_rate == TUNING.FARM_PLANT_DRINK_LOW then
			data.cost_moisture = 1
		elseif v.moisture.drink_rate == TUNING.FARM_PLANT_DRINK_MED then
			data.cost_moisture = 2
		elseif v.moisture.drink_rate == TUNING.FARM_PLANT_DRINK_HIGH then
			data.cost_moisture = 4
		end

		--重新改需肥量
		for _,v3 in pairs(v.nutrient_consumption) do
			if v3 ~= nil and data.cost_nutrient < v3 then
				data.cost_nutrient = v3
			end
		end
		if data.cost_nutrient > 2 and data.cost_nutrient <= 4 then
			data.cost_nutrient = 3
		elseif data.cost_nutrient > 4 then
			data.cost_nutrient = 4
		end

		--确定再生的阶段
		if v.regrowstage ~= nil then
			data.regrowstage = v.regrowstage
		elseif regrowMaps[k] ~= nil then
			data.regrowstage = regrowMaps[k]
		end
		if data.regrowstage >= countstage then
			data.regrowstage = 1
		end

		--设置其他
		if k == "weed_tillweed" then --不能设置犁地草的犁地效果
			data.fn_stage = v.fn_stage
		elseif k == "weed_ivy" then --针刺旋花：官方代码写错了，所以这里修正一下（Klei码师看我看我！！！）
			if v.fn_stage == nil then
				data.fn_stage = function(inst, isfull)
					local has_tag = inst:HasTag("farm_plant_defender")
					if isfull and not has_tag then
						inst:AddTag("farm_plant_defender")
					elseif not isfull and has_tag then
						inst:RemoveTag("farm_plant_defender") --修改：Remove()改为RemoveTag()！！！
					end
				end
			else
				data.fn_stage = v.fn_stage
			end
		else
			data.fn_stage = v.fn_stage or v.OnMakeFullFn
		end

		defs[k] = data
	end
end

--勋章的作物，目前都是不腐烂的设定
local dd = defs["immortal_fruit"]
if dd ~= nil then
	dd.stages[#dd.stages].time = nil
	dd.stages_other.huge.time = nil
	dd.stages_other.rot = nil
	dd.stages_other.huge_rot = nil

	if CONFIGS_LEGION.SIVSOLTOMEDAL then
		dd = defs["weed_ivy"]
		if dd ~= nil and dd.product == nil then
			dd.product = "medal_ivy" --旋花藤：勋章的针刺旋花特殊产物
		end
	end
end
dd = defs["medal_gift_fruit"]
if dd ~= nil then
	dd.stages[#dd.stages].time = nil
	dd.stages_other.huge.time = nil
	dd.stages_other.rot = nil
	dd.stages_other.huge_rot = nil
	dd = nil
end

--------------------------------------------------------------------------
--[[ 子圭·垄的多年生植物 ]]
--------------------------------------------------------------------------

local function GetStatusFn_p(inst)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		return "BURNING"
	end
	local crop = inst.components.perennialcrop
	if crop.stagedata.name == "seed" then
		return "SEED"
	elseif crop.isrotten then
		return crop.ishuge and "ROTTEN_OVERSIZED" or "ROTTEN"
	elseif crop.stage == crop.stage_max then
		return crop.ishuge and "FULL_OVERSIZED" or "FULL"
	else
		return "GROWING"
	end
end
local function OnWorkedFinish_p(inst, worker)
	local crop = inst.components.perennialcrop

	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("dirt_puff").Transform:SetPosition(x, y, z)

	if crop.fn_defend ~= nil then
		crop.fn_defend(inst, worker)
	end
	crop:GenerateLoot(worker, false, false)
	inst:Remove()
end
local function UpdateSoilType_p(inst, soiltype)
	if soiltype ~= nil then
		inst.soiltype_l = soiltype
	end
	inst.AnimState:OverrideSymbol("soil01", inst.soilskin_l or "siving_soil", "soil0"..inst.soiltype_l)
end
local function GetPlantRegistryKey(inst)
    return inst.plantregistrykey
end
local function GetResearchStage(inst)
    return inst._research_stage:value() + 1	-- +1 to make it 1 a based rage
end
local function OnPlantResearch(inst)
    return inst:GetPlantRegistryKey(), inst:GetResearchStage()
end
local function GetDisplayName_p(inst)
	local stagename
	local basename = STRINGS.NAMES[string.upper(inst.prefab_l)]
	if inst.mouseinfo_l ~= nil then
		stagename = inst.mouseinfo_l.dd and inst.mouseinfo_l.dd.name or nil
	end
	if stagename == nil then
		return basename
	elseif STRINGS.CROP_LEGION[string.upper(stagename)] ~= nil then
		return subfmt(STRINGS.CROP_LEGION[string.upper(stagename)], {crop = basename})
	else
		return subfmt(STRINGS.CROP_LEGION.GROWING, {crop = basename})
	end
end
local function Fn_dealdata_p(inst, data)
    local dd = {
        st = tostring(data.st or 1), stmax = tostring(data.stmax or 5),
        -- name = data.name,
        n1 = tostring(data.n1 or 0), nmax = tostring(data.nmax or 50),
		n2 = tostring(data.n2 or 0),
		n3 = tostring(data.n3 or 0),
		mo = tostring(data.mo or 0), momax = tostring(data.momax or 20),
		sk = tostring(data.sk or 0),
		gr = tostring(data.gr or 100),
		pl = tostring(data.pl or 0), plmax = tostring(data.plmax or 3),
		it = tostring(data.it or 0), itmax = tostring(data.itmax or 10),
		des = "",
		li = tostring(data.li or 0), limax = tostring(data.limax or 0),
    }
	if inst:HasTag("flower") then
		dd.des = "("..STRINGS.NAMEDETAIL_L.BLOOMY..")"
	end
	if dd.st == dd.stmax then
		-- dd.huge = data.huge
		dd.np = tostring(data.np or 0)
		return subfmt(STRINGS.NAMEDETAIL_L.SIVPLANT, dd)
	else
		dd.nn = tostring(data.nn or 0)
		dd.nm = tostring(data.nm or 0)
		dd.nt = tostring(data.nt or 0)
		return subfmt(STRINGS.NAMEDETAIL_L.SIVPLANT2, dd)
	end
end
local function Fn_getdata_p(inst)
    local data = {}
	local crop = inst.components.perennialcrop
	if crop.stage ~= 1 then
		data.st = crop.stage
	end
	if crop.stage_max ~= 5 then
		data.stmax = crop.stage_max
	end
	if crop.stagedata ~= nil then
		if crop.stagedata.name ~= nil then
			data.name = crop.stagedata.name
		end
		if crop.stagedata.time ~= nil and crop.stagedata.time > 0 then
			data.limax = TOOLS_L.ODPoint(crop.stagedata.time/TUNING.TOTAL_DAY_TIME, 100)
		end
	end
	if crop.time_grow ~= nil and crop.time_grow > 0 then
		data.li = TOOLS_L.ODPoint(crop.time_grow/TUNING.TOTAL_DAY_TIME, 100)
	end
	if crop.nutrient1 ~= 0 then
		data.n1 = TOOLS_L.ODPoint(crop.nutrient1, 10)
	end
	if crop.nutrient2 ~= 0 then
		data.n2 = TOOLS_L.ODPoint(crop.nutrient2, 10)
	end
	if crop.nutrient3 ~= 0 then
		data.n3 = TOOLS_L.ODPoint(crop.nutrient3, 10)
	end
	if crop.nutrient_max ~= 50 then
		data.nmax = crop.nutrient_max
	end
	if crop.moisture ~= 0 then
		data.mo = TOOLS_L.ODPoint(crop.moisture, 10)
	end
	if crop.moisture_max ~= 20 then
		data.momax = crop.moisture_max
	end
	if crop.sickness ~= 0 then
		data.sk = TOOLS_L.Floor_s(crop.sickness*100)
	end
	if crop.pause_reason ~= nil or crop.time_mult == nil or crop.time_mult <= 0 then
		data.gr = 0
	elseif crop.time_mult ~= 1 then
		data.gr = TOOLS_L.Floor_s(crop.time_mult*100)
	end
	if crop.pollinated ~= 0 then
		data.pl = crop.pollinated
	end
	if crop.pollinated_max ~= 3 then
		data.plmax = crop.pollinated_max
	end
	if crop.infested ~= 0 then
		data.it = crop.infested
	end
	if crop.infested_max ~= 10 then
		data.itmax = crop.infested_max
	end
	if crop.stage == crop.stage_max then
		-- if crop.ishuge then
		-- 	data.huge = true
		-- end
		if crop.num_perfect ~= nil then
			data.np = crop.num_perfect
		end
	else
		if crop.num_nutrient ~= 0 then
			data.nn = crop.num_nutrient
		end
		if crop.num_moisture ~= 0 then
			data.nm = crop.num_moisture
		end
		if crop.num_tended ~= 0 then
			data.nt = crop.num_tended
		end
	end
    return data
end

local function MakePlant(defkey, data)
	return Prefab(data.prefab, function()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(data.bank)
		inst.AnimState:SetBuild(data.build)
		inst.AnimState:OverrideSymbol("soil01", "siving_soil", "soil01")

		SetDeploySmartRadius(inst, nil)
		inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)

		inst:AddTag("plant")
		inst:AddTag("crop_legion")
		inst:AddTag("tendable_farmplant") -- for farmplanttendable component
		inst:AddTag("tornado_nosucky") --mod兼容：永不妥协。不会被龙卷风刮走
		if data.tags ~= nil then
			for k, v in pairs(data.tags) do
				inst:AddTag(v)
			end
		end

		inst:AddTag("plantresearchable") --可研究标签
		inst._research_stage = (data.stage_netvar or net_tinybyte)(inst.GUID, "sivplant.research_stage")
		inst.prefab_l = data.prefab_old
		inst.plantregistrykey = defkey
        inst.GetPlantRegistryKey = GetPlantRegistryKey
        inst.GetResearchStage = GetResearchStage

		TOOLS_L.InitMouseInfo(inst, Fn_dealdata_p, Fn_getdata_p, 3.5)
		inst.displaynamefn = GetDisplayName_p

		if data.fn_common ~= nil then
			data.fn_common(inst)
		end

		LS_C_Init(inst, "siving_soil_item", false, "data_plant")

		inst.entity:SetPristine()
		if not TheWorld.ismastersim then return inst end

		inst.soiltype_l = "1"
		-- inst.soilskin_l = nil
		inst.legiontag_nopost_pickable = true --子圭垄植物不要做对pickable组件的修改

		inst:AddComponent("inspectable")
		inst.components.inspectable.nameoverride = "FARM_PLANT"
		-- inst.components.inspectable.descriptionfn = DescriptionFn_p
		inst.components.inspectable.getstatus = GetStatusFn_p

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.DIG)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnFinishCallback(OnWorkedFinish_p)

		inst:AddComponent("perennialcrop")
		inst.components.perennialcrop:SetUp(data)
		inst.components.perennialcrop:SetStage(1, false, false)

		inst:AddComponent("plantresearchable")
        inst.components.plantresearchable:SetResearchFn(OnPlantResearch)

		inst.fn_soiltype = UpdateSoilType_p

		if data.fn_server ~= nil then
			data.fn_server(inst)
		end

		return inst
	end, nil, nil)
end

--------------------------------------------------------------------------
--[[ 异种植物 ]]
--------------------------------------------------------------------------

local skinedplant = {
	cactus_meat = true, carrot = true, lightbulb = true, berries = true
}
local checkedplant = {
	berries = true, plantmeat = true, cactus_meat = true, carrot = true
}

local function GetStatus_p2(inst)
	local crop = inst.components.perennialcrop2
	return (crop == nil and "GROWING")
		or (crop.isrotten and "WITHERED")
		or (crop.isflower and "BLOOMY")
		or (crop.stage == crop.stage_max and "READY")
		or (crop.level.pickable == 1 and "READY")
		or "GROWING"
end
local function OnHaunt_p2(inst, haunter)
	if inst:HasTag("fertableall_l") and math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
		inst.components.perennialcrop2:Fertilize(nil, haunter)
		return true
	end
	return false
end
local function OnWorkedFinish_p2(inst, worker)
	local crop = inst.components.perennialcrop2
	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("dirt_puff").Transform:SetPosition(x, y, z)

	if crop.fn_defend ~= nil then
		crop.fn_defend(inst, worker)
	end
	crop:GenerateLoot(worker, false, false)
	inst:Remove()
end
local function Fn_dealdata_p2(inst, data)
	local str, strpst
	local def = CROPS_DATA_LEGION[inst.xeedkey]
    local dd = {
        st = tostring(data.st or 1), stmax = tostring(#def.leveldata),
		c = tostring(data.c or 0), cmax = tostring(data.cmax or 99),
		li = tostring(data.li or 0), limax = tostring(data.limax or 0),
		gr = tostring(data.gr or 100),
		pl = tostring(data.pl or 0), plmax = tostring(data.plmax or 3),
		it = tostring(data.it or 0), itmax = tostring(data.itmax or 10),
		des = ""
    }
	if data.wt then
		dd.des = "("..STRINGS.NAMEDETAIL_L.WITHERED..")"
	elseif inst:HasTag("flower") then
		dd.des = "("..STRINGS.NAMEDETAIL_L.BLOOMY..")"
	end
	if dd.st ~= dd.stmax then
		if inst:HasTag("moisable_l") then
			if strpst == nil then
				strpst = STRINGS.NAMEDETAIL_L.THIRSTY
			else
				strpst = strpst..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.THIRSTY
			end
		end
		if inst:HasTag("fertableall_l") then
			if strpst == nil then
				strpst = STRINGS.NAMEDETAIL_L.FEEBLE
			else
				strpst = strpst..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.FEEBLE
			end
		end
		if inst:HasTag("tendable_farmplant") then
			if strpst == nil then
				strpst = STRINGS.NAMEDETAIL_L.UNHAPPY
			else
				strpst = strpst..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.UNHAPPY
			end
		end
	end
	str = subfmt(STRINGS.NAMEDETAIL_L.XPLANT, dd)
	if strpst == nil then
		return str
	else
		return str.."\n"..strpst
	end
end
local function Fn_getdata_p2(inst)
    local data = {}
	local crop = inst.components.perennialcrop2
	if crop.stage ~= 1 then
		data.st = crop.stage
	end
	if crop.isrotten then
		data.wt = true
	end
	if crop.pollinated ~= 0 then
		data.pl = crop.pollinated
	end
	if crop.pollinated_max ~= 3 then
		data.plmax = crop.pollinated_max
	end
	if crop.infested ~= 0 then
		data.it = crop.infested
	end
	if crop.infested_max ~= 10 then
		data.itmax = crop.infested_max
	end
	if crop.pause_reason ~= nil or crop.time_mult == nil or crop.time_mult <= 0 then
		data.gr = 0
	elseif crop.time_mult ~= 1 then
		data.gr = TOOLS_L.Floor_s(crop.time_mult*100)
	end
	if crop.cluster ~= 0 then
		data.c = crop.cluster
	end
	if crop.cluster_max ~= 99 then
		data.cmax = crop.cluster_max
	end
	local time = crop:GetGrowTime()
	if time ~= nil and time > 0 then
		data.limax = TOOLS_L.ODPoint(time/TUNING.TOTAL_DAY_TIME, 100)
	end
	if crop.time_grow ~= nil and crop.time_grow > 0 then
		data.li = TOOLS_L.ODPoint(crop.time_grow/TUNING.TOTAL_DAY_TIME, 100)
	end
    return data
end
local function Wax_xeed(inst, doer, waxitem, right)
	local sets = CROPS_DATA_LEGION[inst.xeedkey]
	if sets == nil then
		return
	end
	local cpt = inst.components.perennialcrop2
	local dd = { stage = cpt.stage, lvl = cpt.cluster }
	if cpt.isrotten then
		dd.state = "1" --枯萎
	elseif sets.leveldata[cpt.stage] ~= nil then
		local lvldd = sets.leveldata[cpt.stage]
		if type(lvldd.anim) == 'table' then
			dd.form = 1
            for i, anim in ipairs(lvldd.anim) do
				if inst.AnimState:IsCurrentAnimation(anim) then
					dd.form = i --形态i
					break
				end
			end
		end
	end
	if sets.fnwax_dofix ~= nil then --部分异种需要对打蜡数据进行修正
        sets.fnwax_dofix(inst, sets, cpt, dd)
    end
    if right then
        return TOOLS_L.WaxObject(inst, doer, waxitem, "plant_"..inst.xeedkey.."_l_waxed", dd, true)
    else
        return TOOLS_L.WaxObject(inst, doer, waxitem, "plant_"..inst.xeedkey.."_l_item_waxed", dd, nil)
    end
end

local function Fn_common_p2(inst, sets) --异种的通用设置
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	SetDeploySmartRadius(inst, nil)

	inst.AnimState:SetBank(sets.bank)
	inst.AnimState:SetBuild(sets.build)
	-- inst.AnimState:PlayAnimation(sets.leveldata[1].anim, true) --组件里会设置动画的

	inst.Transform:SetTwoFaced() --两个面，这样就可以左右不同（再多貌似有问题，因为动画不兼容）
	inst:AddTag("rotatableobject") --能让栅栏击剑起作用
	inst:AddTag("flatrotated_l") --棱镜标签：旋转时旋转180度
	inst:AddTag("crop2_legion")
	inst:AddTag("tornado_nosucky") --mod兼容：永不妥协。不会被龙卷风刮走
	inst:AddTag("waxable_l")
end
local function Fn_server_p2(inst) --异种的通用设置
	inst.legiontag_nopost_pickable = true --异种不要做对pickable组件的修改
	inst:AddComponent("savedrotation")
	inst:AddComponent("inspectable")
	inst:AddComponent("perennialcrop2")
	TOOLS_L.SetSprayWaxable(inst, nil, Wax_xeed)
end

local function MakePlant2(cropprefab, sets)
	local assets = sets.assets or {}
	table.insert(assets, Asset("ANIM", "anim/"..sets.bank..".zip"))
	if sets.bank ~= sets.build then
		table.insert(assets, Asset("ANIM", "anim/"..sets.build..".zip"))
	end
	table.insert(assets, Asset("ANIM", "anim/crop_soil_legion.zip"))

	return Prefab("plant_"..cropprefab.."_l", function()
		local inst = CreateEntity()
		Fn_common_p2(inst, sets)
		inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)
		inst.MiniMapEntity:SetIcon("plant_crop_l.tex")

		if sets.bank == "plant_normal_legion" then
			-- inst.AnimState:OverrideSymbol("dirt", "crop_soil_legion", "dirt")
		else
			inst.AnimState:OverrideSymbol("soil", "crop_soil_legion", "soil")
		end

		inst:AddTag("plant")

		inst.xeedkey = cropprefab
		TOOLS_L.InitMouseInfo(inst, Fn_dealdata_p2, Fn_getdata_p2, 3)

		if skinedplant[cropprefab] then
			LS_C_Init(inst, "plant_"..cropprefab.."_l", false)
		end

		if sets.fn_common ~= nil then
			sets.fn_common(inst)
		end

		inst.entity:SetPristine()
		if not TheWorld.ismastersim then return inst end

		Fn_server_p2(inst)

		if not checkedplant[cropprefab] then
			inst.components.inspectable.nameoverride = "PLANT_CROP_L" --用来统一描述，懒得每种作物都搞个描述了
		end
		inst.components.inspectable.getstatus = GetStatus_p2

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
		inst.components.hauntable:SetOnHauntFn(OnHaunt_p2)

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.DIG)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnFinishCallback(OnWorkedFinish_p2)

		inst.components.perennialcrop2:SetUp(cropprefab, sets, {
			moisture = true, nutrient = true, tendable = true, seasonlisten = true,
			nomagicgrow = sets.nomagicgrow, fireproof = sets.fireproof,
			cangrowindrak = sets.cangrowindrak, nogrowinlight = sets.nogrowinlight,
			nosivctl = sets.nosivctl
		})
		inst.components.perennialcrop2:SetStage(1, false)

		if sets.fn_server ~= nil then
			sets.fn_server(inst)
		end

		return inst
	end, assets, sets.prefabs)
end

--------------------------------------------------------------------------
--[[ 巨食草 三阶段 ]]
--------------------------------------------------------------------------

local DIST_SWALLOW = { 2, 6 } --吞食半径 极限值
local NUM_SWALLOW = { 1, 10 } --吞食对象数量 极限值
local TIME_SWALLOW = { 33, 3 } --吞食消化时间 极限值
local DIST_LURE = { 6, 24 } --引诱半径 极限值
local sounds_nep = {
    lick = "dontstarve/creatures/chester/lick",
	hurt = "dontstarve/creatures/chester/hurt",
	death = "dontstarve/creatures/chester/death",
    open = "dontstarve/creatures/chester/open",
    close = "dontstarve/creatures/chester/close",
	leaf = "dontstarve/wilson/pickup_reeds",
	rumble = "dontstarve/creatures/slurper/rumble"
}
local TAGS_CANT_NEP = TOOLS_L.TagsCombat3({ "player", "nodigest_l" })
local ITEMS_NODIGEST = {
	insectshell_l = true, boneshard = true, ahandfulofwings = true,
	seeds_plantmeat_l = true, --不吃自己的异种
	plantmeat = true, plantmeat_cooked = true, --这是巨食草主产物，不能吃掉
	medal_fishbones = true --【能力勋章】鱼骨
}

local function ComputStackNum(value, item, mult)
	return (value or 0) + (item.components.stackable and item.components.stackable.stacksize or 1)*(mult or 1)
end
local function ComputStackHealth(inst, item)
	if item.components.health == nil or item.components.health:IsDead() then
		return
	end
	local v = math.max(1, item.components.health.currenthealth/80)
	if v > 1 then --由于 namemap 本身就要计算一次叠加数，所以这里的基础增加量得减少1点
		inst.count_digest = inst.count_digest + (v-1)*(item.components.stackable and item.components.stackable.stacksize or 1)
	end
end
local function IsDigestible(item)
	if item.prefab == "fruitflyfruit" then
        return not item:HasTag("fruitflyfruit") --没有 fruitflyfruit 就代表是枯萎了
	elseif item.prefab == "glommerflower" then
		return not item:HasTag("glommerflower") --没有 glommerflower 就代表是枯萎了
    end
	return not ITEMS_NODIGEST[item.prefab] and not item:HasAnyTag("irreplaceable", "nobundling", "nodigest_l")
end
local function GetItemDesc(item, namemap, txt)
	local name = nil
	if item.displaynamefn ~= nil then
		name = item.displaynamefn(item)
	end
	if name == nil then
		name = item.nameoverride or
			(item.components.inspectable ~= nil and item.components.inspectable.nameoverride) or nil
		if name ~= nil then
			name = STRINGS.NAMES[string.upper(name)]
		end
		if name == nil then
			name = STRINGS.NAMES[string.upper(item.prefab)] or "MISSING NAME"
		end
	end

	txt = txt..", "..tostring(namemap[item.prefab]).." "..name
	namemap[item.prefab] = nil
	return txt
end
local function IsValid(inst)
	return inst ~= nil and inst:IsValid()
end
local function ScreeningItems(eater, item, items_digest, items_free, namemap)
	local owner = item.components.inventoryitem and item.components.inventoryitem.owner or nil
	if IsDigestible(item) then --可以消化的：需要从各自容器里拿出来，再统一删除
		if owner ~= nil then
			local cpt = owner.components.container or owner.components.inventory
			if cpt ~= nil then
				item = cpt:RemoveItem(item, true)
			end
		end
		if item ~= nil then
			table.insert(items_digest, item)
			ComputStackHealth(eater, item)
			--弹弓弹药需要削弱一下
			namemap[item.prefab] = ComputStackNum(namemap[item.prefab], item, item:HasTag("slingshotammo") and 0.2 or 1)
			--递归判定容器物品中的物品
			local cpt = item.components.container or item.components.inventory
			if cpt ~= nil then
				local cptitems = cpt:FindItems(IsValid)
				for _, v in pairs(cptitems) do
					ScreeningItems(eater, v, items_digest, items_free, namemap)
				end
			end
		end
	else --无法消化的：需要从非巨食草的容器里拿出来，再统一放进巨食草
		if owner ~= nil then
			if eater == owner then --如果本来就在巨食草里，就不用做什么操作啦
				return
			end
			local cpt = owner.components.container or owner.components.inventory
			if cpt ~= nil then
				item = cpt:RemoveItem(item, true)
			end
		end
		if item ~= nil then
			table.insert(items_free, item)
		end
	end
end
local function ComputDigest(inst, namemap, items_free)
	local numprefab = {}
	local numall = inst.count_digest
	local pos = inst:GetPosition()
	for name, number in pairs(namemap) do
		if DIGEST_DATA_LEGION[name] ~= nil then
			local dd = DIGEST_DATA_LEGION[name]
			if dd.loot ~= nil then
				for k, v in pairs(dd.loot) do
					numprefab[k] = (numprefab[k] or 0) + number*v
				end
			end
			if dd.stackmult ~= nil then
				numall = numall + number*dd.stackmult
			else
				numall = numall + number
			end
		else
			numall = numall + number
		end
	end
	for name, number in pairs(numprefab) do
		number = number*0.25
		local number2 = math.floor(number) --整数部分
		number = number - number2 --小数部分
		if number > 0 then --小数部分则随机
			if math.random() < number then
				number2 = number2 + 1
			end
		end
		if number2 >= 1 then
			TOOLS_L.SpawnStackDrop(name, number2, pos, nil, items_free, nil)
		end
	end

	------簇栽升级
	local cpt2 = inst.components.perennialcrop2
	if numall >= 80 then
		local need
		local level = math.floor(numall/80)
		if cpt2.cluster < cpt2.cluster_max then
			need = cpt2.cluster_max - cpt2.cluster
			if level > need then
				level = level - need
			else
				need = level
				level = 0
			end
			cpt2:DoCluster(need)
			numall = numall - need*80
		end
		if level > 0 then --满级后每次营养点大于80，都会额外产生叶肉；每升一级也能
			need = (need or 0) + level*8
			numall = numall - level*80
		end
		if need ~= nil then
			TOOLS_L.SpawnStackDrop("plantmeat", need, pos, nil, items_free, nil)
		end
	end
	inst.count_digest = numall
end
local function GetItemLoots(item, lootmap)
	if item.components.lootdropper ~= nil and math.random() >= 0.75 then --25%几率，能获取完整掉落物
		local loots = item.components.lootdropper:GenerateLoot()
		for _,lootname in pairs(loots) do --这个表里的数据都是单个的
			lootmap[lootname] = ComputStackNum(lootmap[lootname], item)
		end
	end
end
local function DoDigest(inst, doer)
	inst.task_digest = nil

	if inst.components.health:IsDead() then
		return
	end
	inst.components.health:SetPercent(1)
	inst.components.perennialcrop2:Cure()

	------先登记所有的物品
	local items_digest = {}
	local items_free = {}
	local namemap = {}
	local cpt = inst.components.container
	local cptitems = cpt:FindItems(IsValid)
	for _, v in pairs(cptitems) do
		ScreeningItems(inst, v, items_digest, items_free, namemap)
	end

	------生成消化后产物，结算，簇栽升级
	ComputDigest(inst, namemap, items_free)

	------发送全服通告
	if CONFIGS_LEGION.DIGESTEDITEMMSG then
		local itemtxt = ""
		for _, item in pairs(items_digest) do
			if namemap[item.prefab] ~= nil then --不为空说明还没被记录进去
				itemtxt = GetItemDesc(item, namemap, itemtxt)
			end
		end
		if doer ~= nil then
			itemtxt = subfmt(STRINGS.NAMEDETAIL_L.DIGEST,
				{ doer = tostring(doer.name), eater = STRINGS.NAMES[string.upper(inst.prefab)], items = itemtxt })
		else
			itemtxt = subfmt(STRINGS.NAMEDETAIL_L.DIGESTSELF,
				{ eater = STRINGS.NAMES[string.upper(inst.prefab)], items = itemtxt })
		end
		TheNet:Announce(itemtxt)
	end

	------整理物品
	local lootmap = {}
	local dd = nil
	for _, item in pairs(items_digest) do --现在才删除，是因为全服通告需要实体来判定名字
		GetItemLoots(item, lootmap) --有几率进行一次死亡掉落物判定
		dd = DIGEST_DATA_LEGION[item.prefab]
		if dd ~= nil and dd.fn_digest ~= nil then
			dd.fn_digest(item, inst, items_free)
		end
		item:Remove()
	end
	for name, number in pairs(lootmap) do --生成被吞生物的掉落物
		TOOLS_L.SpawnStackDrop(name, number, inst:GetPosition(), nil, items_free, nil)
	end
	for _, item in pairs(items_free) do --将无法消化物品和消化产物都放回巨食草里
		if item:IsValid() and item.components.inventoryitem ~= nil then
			cpt:GiveItem(item)
		end
	end
end
local function StopTask(inst, key)
	if inst[key] ~= nil then
		inst[key]:Cancel()
		inst[key] = nil
	end
end
local function TryDigest(inst, doer)
	StopTask(inst, "task_digest")
	for k,v in pairs(inst.components.container.slots) do
        if IsDigestible(v) then
			inst.task_digest = inst:DoTaskInTime(5, function(inst)
				DoDigest(inst, doer)
			end)
			return
		end
    end
end

local function TrySwallow(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local cluster = inst.components.perennialcrop2.cluster
	local ents = TheSim:FindEntities(x, y, z, inst.dist_swallow,
		nil, TAGS_CANT_NEP, { "_combat", "_health", "_inventoryitem", "spore" }
	)
	for _, v in ipairs(ents) do
		if
			v.entity:IsVisible() and
			DIGEST_DATA_LEGION[v.prefab] ~= nil and
			(v.components.combat == nil or v:HasTag("spore") or TOOLS_L.MaybeEnemy_player(inst, v, true))
		then
			local dd = DIGEST_DATA_LEGION[v.prefab]
			if dd.lvl ~= nil and dd.lvl <= cluster then
				inst.sg:GoToState("swallow")
				return true
			end
		end
	end
	return false
end
local function DoSwallow(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local count = 0
	local namemap = {}
	local lootmap = {}
	local newitems = {}
	local cluster = inst.components.perennialcrop2.cluster
	local ents = TheSim:FindEntities(x, y, z, inst.dist_swallow,
		nil, TAGS_CANT_NEP, { "_combat", "_health", "_inventoryitem", "spore" }
	)
	for _, v in ipairs(ents) do
		if
			v.entity:IsVisible() and
			DIGEST_DATA_LEGION[v.prefab] ~= nil and
			(v.components.combat == nil or v:HasTag("spore") or TOOLS_L.MaybeEnemy_player(inst, v, true))
		then
			local dd = DIGEST_DATA_LEGION[v.prefab]
			if dd.lvl ~= nil and dd.lvl <= cluster then
				ComputStackHealth(inst, v)
				namemap[v.prefab] = ComputStackNum(namemap[v.prefab], v)
				count = count + 1
				GetItemLoots(v, lootmap)
				if dd.fn_digest ~= nil then
					dd.fn_digest(v, inst, newitems)
				elseif v.components.inventory ~= nil then
					v.components.inventory:DropEverything(false, false)
				elseif v.components.container ~= nil then
					v.components.container:DropEverything()
				end
				v:PushEvent("detachchild") --让spawner组件知道自己的child消失了，好继续刷新下一只
				v:Remove()
				if count >= inst.num_swallow then
					break
				end
			end
		end
	end

	if count <= 0 then
		return
	end

	for name, number in pairs(lootmap) do --生成被吞生物的掉落物
		TOOLS_L.SpawnStackDrop(name, number, inst:GetPosition(), nil, newitems, nil)
	end

	inst.components.health:SetPercent(1)
	inst.components.perennialcrop2:Cure()
	ComputDigest(inst, namemap, newitems)
	for _, item in pairs(newitems) do --将消化产物放到巨食草里
		if item:IsValid() and item.components.inventoryitem ~= nil then
			inst.components.container:GiveItem(item)
		end
	end

	inst.components.timer:StopTimer("digested")
	inst.components.timer:StartTimer("digested", inst.time_swallow) --开始冷却计时
end
local function DoLure(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local cluster = inst.components.perennialcrop2.cluster
	local ents = TheSim:FindEntities(x, y, z, inst.dist_lure, nil, TAGS_CANT_NEP, { "_combat", "spore" })
	for _, v in ipairs(ents) do
		if v.entity:IsVisible() and DIGEST_DATA_LEGION[v.prefab] ~= nil then
			local dd = DIGEST_DATA_LEGION[v.prefab]
			if dd.attract and dd.lvl ~= nil and dd.lvl <= cluster then
				if v:HasTag("spore") then
					if v.followobj == nil or not v.followobj:IsValid()
						or not v.followobj:HasTag("vaseherb") --不跟其他巨食草抢猎物
					then
						v.followobj = inst
					end
				elseif v:HasTag("gnat_l") then --虫群有独特的吸引方式
					if v.infesttarget == nil or not v.infesttarget:IsValid()
						or not v.infesttarget:HasTag("vaseherb") --不跟其他巨食草抢猎物
					then
						if v.infesttarget ~= nil then
							v.infesttarget.infester = nil --清除以前的标记
						end
						v.infesttarget = inst
						v.components.combat:SetTarget(inst)
					end
				elseif TOOLS_L.MaybeEnemy_player(inst, v, true) and v.components.combat:CanTarget(inst) then
					local v_target = v.components.combat.target
					if v_target == nil or not v_target:IsValid() or not v_target:HasTag("vaseherb") then
						v.components.combat:SetTarget(inst)
					end
				end
			end
		end
	end
end

local function OnOpen_nep(inst, data)
	if not inst.components.health:IsDead() then
		StopTask(inst, "task_digest")
        inst.sg:GoToState("openmouth", data)
    end
end
local function OnClose_nep(inst, doer)
    if not inst.components.health:IsDead() then
		inst.fn_tryDigest(inst, doer)
		if inst.sg:HasStateTag("open") then --从打开容器sg才会继续关闭容器的sg
			inst.sg:GoToState("closemouth", doer)
		end
    end
end
local function OnTimerDone_nep(inst, data)
	if data.name == "digested" then
		inst:PushEvent("digested")
	end
end
local function OnCluster_nep(cpt, now)
	now = math.min(now*1.25, cpt.cluster_max) --提前让数值达到最大

	local value = Remap(now, 0, cpt.cluster_max, DIST_SWALLOW[1], DIST_SWALLOW[2])
	cpt.inst.dist_swallow = TOOLS_L.ODPoint(value, 10)

	value = Remap(now, 0, cpt.cluster_max, NUM_SWALLOW[1], NUM_SWALLOW[2])
	cpt.inst.num_swallow = math.floor(value)

	value = Remap(now, 0, cpt.cluster_max, TIME_SWALLOW[1], TIME_SWALLOW[2])
	cpt.inst.time_swallow = TOOLS_L.ODPoint(value, 10)

	value = Remap(now, 0, cpt.cluster_max, DIST_LURE[1], DIST_LURE[2])
	cpt.inst.dist_lure = TOOLS_L.ODPoint(value, 10)
end

local function SwitchPlant(inst, plant) --还缺一些数据的继承，比如侵扰值、异种插件，不过之后再说啦
	local cpt = inst.components.perennialcrop2
	if plant ~= nil then --说明是植物到生物
		cpt.cluster = plant.components.perennialcrop2.cluster
		cpt:OnClusterChange()
		inst.Transform:SetPosition(plant.Transform:GetWorldPosition())
		inst.Transform:SetRotation(plant.Transform:GetRotation())
	else --生物到植物
		inst.components.container:Close()
		inst.components.container.canbeopened = false
		inst.components.container:DropEverything()

		plant = SpawnPrefab("plant_plantmeat_l")
        if plant ~= nil then
            plant.components.perennialcrop2.cluster = cpt.cluster
			plant.components.perennialcrop2:OnClusterChange()
            plant.Transform:SetPosition(inst.Transform:GetWorldPosition())
			plant.Transform:SetRotation(inst.Transform:GetRotation())
			return plant
        end
        -- inst:Remove() --现在删除还太早，生命组件会出手
	end
end
local function OnDeath_nep(inst, data)
	inst.components.perennialcrop2:GenerateLoot(nil, true, false)
	StopTask(inst, "task_digest")
	StopTask(inst, "task_lure")
	StopTask(inst, "task_swallow")
	inst.components.timer:StopTimer("digested")

	inst.fn_switch(inst)
end
local function OnEntityReplicated_nep(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("plant_nepenthes_l")
    end
end
local function OnSave_nep(inst, data)
	if inst.count_digest > 0 then
		data.count_digest = inst.count_digest
	end
end
local function OnLoad_nep(inst, data)
	if data ~= nil then
		if data.count_digest ~= nil then
			inst.count_digest = data.count_digest
		end
	end
end

local function SendSwallowEvent(inst)
	inst:PushEvent("doswallow")
end
local function DoSome_nep(inst)
	if inst.task_lure == nil then
		inst.task_lure = inst:DoPeriodicTask(10.1, inst.fn_doLure, 2+13*math.random())
	end
	if inst.task_swallow == nil then
		inst.task_swallow = inst:DoPeriodicTask(4.1, SendSwallowEvent, 1+5*math.random())
	end
end
local function SetMode_nep(inst, newmode, doer)
    if newmode == 1 then
		DoSome_nep(inst)
	else
		StopTask(inst, "task_lure")
		StopTask(inst, "task_swallow")
		inst.todo_swallow = nil
	end
	if doer ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/emote_nuzzle")
		inst.SoundEmitter:PlaySound(inst.sounds.leaf, nil, 0.4)
		inst.SoundEmitter:PlaySound(inst.sounds.rumble, nil, 0.5)
		TOOLS_L.SendMouseInfoRPC(doer, inst, { mode = newmode }, true, false)
	end
end
local function OnEntityWake_nep(inst)
    if inst.components.modelegion.now == 1 then
		DoSome_nep(inst)
		inst.todo_swallow = true
	end
end
local function OnEntitySleep_nep(inst)
    StopTask(inst, "task_lure")
	StopTask(inst, "task_swallow")
end
local function WaxRemove_nep(inst, doer)
    inst.components.perennialcrop2:GenerateLoot(nil, false, false)
	StopTask(inst, "task_digest")
	StopTask(inst, "task_lure")
	StopTask(inst, "task_swallow")
	inst.components.timer:StopTimer("digested")
    inst:Remove()
end
local function SetPerishRate_nep(inst, item)
    if item == nil then
        return 1
    end
    if item.prefab == "plantmeat" then
        return 0.3
    end
    return 1
end

local function Fn_dealdata_nep(inst, data)
	if data.c == nil then
		data.c = 0
	end
	if data.cmax == nil then
		data.cmax = 99
	end
	local dd = {
		c = tostring(data.c), cmax = tostring(data.cmax),
		ea = tostring(data.ea or 0)
		-- it = tostring(data.it or 0), itmax = tostring(data.itmax or 50)
	}
	--遵循 OnCluster_nep() 的逻辑
	local now = math.min(data.c*1.25, data.cmax)
	local value = Remap(now, 0, data.cmax, DIST_SWALLOW[1], DIST_SWALLOW[2])
	dd.d_s = tostring(TOOLS_L.ODPoint(value, 10))
	value = Remap(now, 0, data.cmax, NUM_SWALLOW[1], NUM_SWALLOW[2])
	dd.n_s = tostring(TOOLS_L.Floor_s(value))
	value = Remap(now, 0, data.cmax, TIME_SWALLOW[1], TIME_SWALLOW[2])
	dd.t_s = tostring(TOOLS_L.ODPoint(value, 10))
	value = Remap(now, 0, data.cmax, DIST_LURE[1], DIST_LURE[2])
	dd.d_l = tostring(TOOLS_L.ODPoint(value, 10))

	return subfmt(STRINGS.NAMEDETAIL_L.VASEHERB, dd).."\n"..(STRINGS.NAMEDETAIL_L.VASEHERB_MODE[data.mode or 1])
end
local function Fn_getdata_nep(inst)
	local data = {}
	local crop = inst.components.perennialcrop2
	-- if crop.infested ~= 0 then
	-- 	data.it = crop.infested
	-- end
	-- if crop.infested_max ~= 50 then
	-- 	data.itmax = crop.infested_max
	-- end
	if crop.cluster ~= 0 then
		data.c = crop.cluster
	end
	if crop.cluster_max ~= 99 then
		data.cmax = crop.cluster_max
	end
	if inst.components.modelegion.now ~= 1 then
		data.mode = inst.components.modelegion.now
	end
	if inst.count_digest ~= 0 then
		data.ea = TOOLS_L.ODPoint(inst.count_digest, 100)
	end
	return data
end

local dd_nep = CROPS_DATA_LEGION["plantmeat"]
table.insert(prefs, Prefab("plant_nepenthes_l", function()
	local inst = CreateEntity()
	Fn_common_p2(inst, dd_nep)
	inst:SetPhysicsRadiusOverride(.5)
	MakeObstaclePhysics(inst, inst.physicsradiusoverride)
	inst.MiniMapEntity:SetIcon("plant_crop_l.tex")

	inst:AddTag("veggie")
	inst:AddTag("notraptrigger")
	inst:AddTag("noauradamage")
	inst:AddTag("companion")
	inst:AddTag("vaseherb")
	inst:AddTag("cansetmode_l") --模式切换必需，没有就代表无法切换

	inst.xeedkey = "plantmeat"
	TOOLS_L.InitMouseInfo(inst, Fn_dealdata_nep, Fn_getdata_nep, 1)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = OnEntityReplicated_nep
		return inst
	end

	inst.count_digest = 0 --已消化物品的数量
	inst.dist_swallow = DIST_SWALLOW[1] --吞食半径
	inst.num_swallow = NUM_SWALLOW[1] --一次能吞下对象的最大数量
	inst.time_swallow = TIME_SWALLOW[1] --主动吞食后的消化时间
	inst.dist_lure = DIST_LURE[1] --引诱半径
	inst.sounds = sounds_nep
	-- inst.task_digest = nil
	-- inst.task_swallow = nil
	-- inst.todo_swallow = nil

	inst.fn_trySwallow = TrySwallow
	inst.fn_doSwallow = DoSwallow
	inst.fn_doLure = DoLure
	inst.fn_tryDigest = TryDigest
	inst.fn_death = OnDeath_nep
	inst.fn_switch = SwitchPlant

	Fn_server_p2(inst)
	inst.legionfn_waxremove = WaxRemove_nep

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1200)
	inst.components.health.destroytime = 0.7

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "base"

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("plant_nepenthes_l")
	inst.components.container.onopenfn = OnOpen_nep
	inst.components.container.onclosefn = OnClose_nep
	inst.components.container.skipclosesnd = true
	inst.components.container.skipopensnd = true

	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(SetPerishRate_nep)

	inst:AddComponent("timer")

	inst.components.perennialcrop2.fn_cluster = OnCluster_nep
	inst.components.perennialcrop2.infested_max = 50 --我可不想它直接被害虫干掉了
	inst.components.perennialcrop2:SetNoFunction()
	inst.components.perennialcrop2:SetUp("plantmeat", dd_nep, {
		-- moisture = nil, nutrient = nil, tendable = nil, seasonlisten = nil,
		nomagicgrow = true, fireproof = true, cangrowindrak = true, nosivctl = true
	})
	inst.components.perennialcrop2:SetStage(3, false)

	inst:AddComponent("modelegion")
    inst.components.modelegion:Init(1, 2, nil, SetMode_nep)

	inst:SetStateGraph("SGplant_nepenthes_l")

	inst:ListenForEvent("timerdone", OnTimerDone_nep)

	inst.OnSave = OnSave_nep
	inst.OnLoad = OnLoad_nep
	inst.OnEntitySleep = OnEntitySleep_nep
    inst.OnEntityWake = OnEntityWake_nep

	MakeHauntableDropFirstItem(inst)

	DoSome_nep(inst)

	return inst
end, {
	Asset("ANIM", "anim/ui_nepenthes_l_4x4.zip"),
	Asset("ANIM", "anim/crop_legion_lureplant.zip")
}, nil))

--------------------------------------------------------------------------
--[[ 云青松 ]]
--------------------------------------------------------------------------

local dd_pine = CROPS_DATA_LEGION["log"]
local function OnRemoveEntity_pine(inst)
	if TheWorld.components.boxcloudpine ~= nil then
		TheWorld.components.boxcloudpine:ManageEnt(inst, false, nil)
		TheWorld.components.boxcloudpine:UpdateBox(inst)
	end
end
local function OnWorkedFinish_pine1(inst, worker)
	inst.components.container_proxy:Close() --关掉世界容器
	inst.OnRemoveEntity = nil --防止重复触发
	OnRemoveEntity_pine(inst)
	OnWorkedFinish_p2(inst, worker)
end
local function WakeUpLeif(ent)
    ent.components.sleeper:WakeUp()
end
local function OnWorked_pine(inst, worker, workleft, numworks)
	TOOLS_L.PlayChopSound(inst, worker)

	inst.components.container_proxy:Close() --关掉世界容器

	inst.AnimState:PlayAnimation("chop")
    inst.AnimState:PushAnimation("idle", true)

	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("pine_needles_chop").Transform:SetPosition(x, y + math.random() * 2, z)

	--唤醒周围的树精守卫
	local ents = TheSim:FindEntities(x, y, z, TUNING.LEIF_REAWAKEN_RADIUS, { "leif" })
	for _, v in ipairs(ents) do
		if v.components.sleeper ~= nil and v.components.sleeper:IsAsleep() then
			v:DoTaskInTime(math.random(), WakeUpLeif)
		end
		v.components.combat:SuggestTarget(worker)
	end
end
local function ShakeAllCameras_pine(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .03,
        inst.components.perennialcrop2 ~= nil and
        inst.components.perennialcrop2.stage == 2 and .5 or .25,
        inst, 6
	)
end
local function FindLeifTree(item)
    return not item.noleif
        and item.components.growable ~= nil
        and item.components.growable.stage <= 3
end
local function OnWorkedFinish_pine2(inst, worker)
	local crop = inst.components.perennialcrop2
	-- local x, y, z = inst.Transform:GetWorldPosition()

	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	inst:DoTaskInTime(0.4, ShakeAllCameras_pine)

	if crop.fn_defend ~= nil then
		crop.fn_defend(inst, worker)
	end
	crop:GenerateLoot(nil, true, false) --不传doer，这样就会强制收获物掉地上
	crop:StopGrowing() --清除生长进度
	if crop.stage == 3 then
		crop:SetStage(2, false)
	else
		crop:SetStage(1, false)
	end

	inst.AnimState:PlayAnimation("chop")
    inst.AnimState:PushAnimation("idle", true)

	local days_survived = worker.components.age ~= nil and worker.components.age:GetAgeInDays() or TheWorld.state.cycles
	if days_survived >= TUNING.LEIF_MIN_DAY then
		local chance = TUNING.LEIF_PERCENT_CHANCE
		if worker:HasTag("beaver") then
			chance = chance * TUNING.BEAVER_LEIF_CHANCE_MOD
		elseif worker:HasTag("woodcutter") then
			chance = chance * TUNING.WOODCUTTER_LEIF_CHANCE_MOD
		end
		if math.random() < chance then
			for k = 1, (days_survived <= 30 and 1) or math.random(days_survived <= 80 and 2 or 3) do
				local target = FindEntity(inst, TUNING.LEIF_MAXSPAWNDIST,
					FindLeifTree, { "evergreens", "tree" }, { "leif", "stump", "burnt" })
				if target ~= nil then
					target:TransformIntoLeif(worker)
				end
			end
		end
	end
end
local function OnStage_pine(self)
	local inst = self.inst
	if self.stage == 1 then
		-- inst.AnimState:Show("base1")
		inst.AnimState:Hide("base2")
		inst.AnimState:Hide("base3")

		inst.components.workable:SetWorkAction(ACTIONS.DIG)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnWorkCallback(nil)
		inst.components.workable:SetOnFinishCallback(OnWorkedFinish_pine1)
	elseif self.stage == 2 then
		-- inst.AnimState:Show("base1")
		inst.AnimState:Show("base2")
		inst.AnimState:Hide("base3")

		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetWorkLeft(10)
		inst.components.workable:SetOnWorkCallback(OnWorked_pine)
		inst.components.workable:SetOnFinishCallback(OnWorkedFinish_pine2)
	else
		-- inst.AnimState:Show("base1")
		inst.AnimState:Show("base2")
		inst.AnimState:Show("base3")

		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetWorkLeft(20)
		inst.components.workable:SetOnWorkCallback(OnWorked_pine)
		inst.components.workable:SetOnFinishCallback(OnWorkedFinish_pine2)
	end
end
local function OnLoot_pine(self, doer, ispicked, isburnt, lootprefabs)
	if self.stage ~= 1 then
		self:GetBaseLoot(lootprefabs, {
			doer = doer, ispicked = ispicked, isburnt = isburnt,
			crop = self.cropprefab, crop_rot = self.cropprefab,
			lootothers = self.stage == self.stage_max and { --最终阶段才有嫩枝
				{ israndom=true, factor=0.6, name="cutted_lumpyevergreen", name_rot=nil },
				{ israndom=false, factor=0.3, name="cutted_lumpyevergreen", name_rot=nil }
			} or nil
		})
		if self.stage == self.stage_max then --由于后面两阶段都能获取，所以收获物就分成两部分
			for name, num in pairs(lootprefabs) do
				if name == "log" then
					lootprefabs[name] = math.ceil(num*2/3)
				end
			end
		else
			for name, num in pairs(lootprefabs) do
				if name == "log" then
					lootprefabs[name] = math.ceil(num/3)
				end
			end
		end
	end
end
local function OnOpen_pine(inst)
	inst.AnimState:PlayAnimation("open")
	inst.SoundEmitter:PlaySound("maxwell_rework/magician_chest/open")
end
local function OnClose_pine(inst)
	inst.AnimState:PlayAnimation("close")
	inst.AnimState:PushAnimation("idle", true)
	inst.SoundEmitter:PlaySound("maxwell_rework/magician_chest/close")
end
local function OnLoadPostPass_pine(inst) --世界启动时，向世界容器注册自己
	if TheWorld.components.boxcloudpine ~= nil then
		TheWorld.components.boxcloudpine.openers[inst] = true
	end
end
local function Fn_dealdata_pine(inst, data)
	local str, strpst
    local dd = {
        st = tostring(data.st or 1), stmax = tostring(#dd_pine.leveldata),
		c = tostring(data.c or 0), cmax = tostring(data.cmax or 99),
		it = tostring(data.it or 0), itmax = tostring(data.itmax or 10)
    }
	if dd.st == dd.stmax then
		return subfmt(STRINGS.NAMEDETAIL_L.CLOUDPINE, dd)
	else
		dd.li = tostring(data.li or 0)
		dd.limax = tostring(data.limax or 0)
		dd.gr = tostring(data.gr or 100)
		dd.pl = "0"
		dd.plmax = "3"
		dd.des = ""
		if inst:HasTag("moisable_l") then
			if strpst == nil then
				strpst = STRINGS.NAMEDETAIL_L.THIRSTY
			else
				strpst = strpst..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.THIRSTY
			end
		end
		if inst:HasTag("fertableall_l") then
			if strpst == nil then
				strpst = STRINGS.NAMEDETAIL_L.FEEBLE
			else
				strpst = strpst..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.FEEBLE
			end
		end
		if inst:HasTag("tendable_farmplant") then
			if strpst == nil then
				strpst = STRINGS.NAMEDETAIL_L.UNHAPPY
			else
				strpst = strpst..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.UNHAPPY
			end
		end
		str = subfmt(STRINGS.NAMEDETAIL_L.XPLANT, dd)
		if strpst == nil then
			return str
		else
			return str.."\n"..strpst
		end
	end
end
local function Fn_getdata_pine(inst)
	local data = {}
	local crop = inst.components.perennialcrop2
	if crop.stage ~= 1 then
		data.st = crop.stage
	end
	if crop.stage ~= crop.stage_max then
		if crop.pause_reason ~= nil or crop.time_mult == nil or crop.time_mult <= 0 then
			data.gr = 0
		elseif crop.time_mult ~= 1 then
			data.gr = TOOLS_L.Floor_s(crop.time_mult*100)
		end
		local time = crop:GetGrowTime()
		if time ~= nil and time > 0 then
			data.limax = TOOLS_L.ODPoint(time/TUNING.TOTAL_DAY_TIME, 100)
		end
		if crop.time_grow ~= nil and crop.time_grow > 0 then
			data.li = TOOLS_L.ODPoint(crop.time_grow/TUNING.TOTAL_DAY_TIME, 100)
		end
	end
	if crop.infested ~= 0 then
		data.it = crop.infested
	end
	if crop.infested_max ~= 10 then
		data.itmax = crop.infested_max
	end
	if crop.cluster ~= 0 then
		data.c = crop.cluster
	end
	if crop.cluster_max ~= 99 then
		data.cmax = crop.cluster_max
	end
    return data
end
local function OnCluster_pine(cpt, now)
	if TheWorld.components.boxcloudpine ~= nil then
		TheWorld.components.boxcloudpine:ManageEnt(cpt.inst, true, now)
		--世界启动状态时，不要做这个操作，免得物品掉坐标原点了。而且这里执行时，确实可能是没有设置好真实坐标的
		if not POPULATING then
			TheWorld.components.boxcloudpine:UpdateBox(cpt.inst)
		end
	end
end
local function WaxRemove_pine(inst, doer)
    inst.components.perennialcrop2:GenerateLoot(nil, false, false)
	inst.components.container_proxy:Close() --关掉世界容器
	inst.OnRemoveEntity = nil --防止重复触发
	OnRemoveEntity_pine(inst)
    inst:Remove()
end

table.insert(prefs, Prefab("plant_log_l", function()
	local inst = CreateEntity()
	Fn_common_p2(inst, dd_pine)
	inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)
	inst.MiniMapEntity:SetIcon("plant_crop_l.tex")

	inst:AddTag("plant")
	inst:AddTag("silviculture") --该标签会使得仅限《造林学》发挥作用

	inst:AddComponent("container_proxy")

	inst.xeedkey = "log"
	TOOLS_L.InitMouseInfo(inst, Fn_dealdata_pine, Fn_getdata_pine, 2)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then return inst end

	Fn_server_p2(inst)
	inst.legionfn_waxremove = WaxRemove_pine

	inst.components.inspectable.getstatus = GetStatus_p2

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
	inst.components.hauntable:SetOnHauntFn(OnHaunt_p2)

	inst:AddComponent("workable")

	inst.components.perennialcrop2.fn_cluster = OnCluster_pine
	inst.components.perennialcrop2:SetUp("log", dd_pine, {
		moisture = true, nutrient = true, tendable = true, seasonlisten = true,
		nomagicgrow = dd_pine.nomagicgrow, fireproof = dd_pine.fireproof,
		cangrowindrak = dd_pine.cangrowindrak, nogrowinlight = dd_pine.nogrowinlight
	})
	inst.components.perennialcrop2.fn_stage = OnStage_pine
	inst.components.perennialcrop2.fn_loot = OnLoot_pine
	inst.components.perennialcrop2:SetStage(1, false)

	inst.components.container_proxy:SetOnOpenFn(OnOpen_pine)
	inst.components.container_proxy:SetOnCloseFn(OnClose_pine)

	inst.OnRemoveEntity = OnRemoveEntity_pine
	inst.OnLoadPostPass = OnLoadPostPass_pine
	if not POPULATING then
		if TheWorld.components.boxcloudpine ~= nil then
			TheWorld.components.boxcloudpine:SetMaster(inst)
		end
	end

	return inst
end, { Asset("ANIM", "anim/crop_legion_pine.zip") }, nil))

--------------------------------------------------------------------------
--[[ 夜盏花 ]]
--------------------------------------------------------------------------

local COLOURED_LIGHTS = {
    red = {
        [MUSHTREE_SPORE_RED] = true,
        ["winter_ornament_light1"] = true,
        ["winter_ornament_light5"] = true
    },
    green = {
        [MUSHTREE_SPORE_GREEN] = true,
        ["winter_ornament_light2"] = true,
        ["winter_ornament_light6"] = true
    },
    blue = {
        [MUSHTREE_SPORE_BLUE] = true,
        ["winter_ornament_light3"] = true,
        ["winter_ornament_light7"] = true
    }
}
local colour_tint = { 0.65, 0.5, 0.35, 0.2, 0.05 }

local function UpdateLight_lightbulb(inst)
	if inst.lightmult_l == nil then --现在不是能发光的阶段
		inst.Light:Enable(false)
	else
		if inst.isday_l then --白天发光半径大幅降低，为了不影响白天的视野
			inst.Light:SetRadius(inst.lightrad_l * inst.lightmult_l * 0.2)
		else
			inst.Light:SetRadius(inst.lightrad_l * inst.lightmult_l)
		end
		inst.Light:Enable(true)
	end
end
local function OnIsDay_lightbulb(inst, isit)
	if isit then
		inst.isday_l = true
	else
		inst.isday_l = nil
	end
	UpdateLight_lightbulb(inst)
end
local function OnCluster_lightbulb(cpt, now) --发光半径随等级变化
	if now <= 30 then --前30级，发光半径随等级变化明显
		cpt.inst.lightrad_l = Remap(now, 0, 30, 2, 7.5) --0.177
	else
		cpt.inst.lightrad_l = Remap(now, 31, cpt.cluster_max, 7.536, 10) --0.036
	end
	if not POPULATING then
		UpdateLight_lightbulb(cpt.inst)
	end
end
local function IsRedSpore(item)
    if COLOURED_LIGHTS.red[item.prefab] then
        return true
    elseif item.components.container ~= nil then
        return item.components.container:FindItem(IsRedSpore) ~= nil
    else
        return false
    end
end
local function IsGreenSpore(item)
    if COLOURED_LIGHTS.green[item.prefab] then
        return true
    elseif item.components.container ~= nil then
        return item.components.container:FindItem(IsGreenSpore) ~= nil
    else
        return false
    end
end
local function IsBlueSpore(item)
    if COLOURED_LIGHTS.blue[item.prefab] then
        return true
    elseif item.components.container ~= nil then
        return item.components.container:FindItem(IsBlueSpore) ~= nil
    else
        return false
    end
end
local function ItemChange_lightbulb(inst) --根据物品改变发光颜色
	local r = #inst.components.container:FindItems(IsRedSpore)
	local g = #inst.components.container:FindItems(IsGreenSpore)
	local b = #inst.components.container:FindItems(IsBlueSpore)
	inst.Light:SetColour(colour_tint[g+b + 1] + r/9, colour_tint[r+b + 1] + g/9, colour_tint[r+g + 1] + b/9)
end
local function OnEntityReplicated_lightbulb(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("plant_lightbulb_l")
    end
end
local function OnStage_lightbulb(cpt) --非启动时初始化从这里开始
	local inst = cpt.inst
	if inst._dd_stage ~= nil then
		inst._dd_stage(inst, cpt)
	elseif inst.fn_l_stage ~= nil then
		inst.fn_l_stage(inst, cpt)
	end
	if cpt.isrotten or cpt.stage == 1 then
		inst.lightmult_l = nil
	elseif cpt.stage == cpt.stage_max then
		inst.lightmult_l = 1
	else
		inst.lightmult_l = 0.4
	end
	if not POPULATING then
		OnIsDay_lightbulb(inst, TheWorld.state.isday)
	end
end
local function OnLoadPostPass_lightbulb(inst, newents, savedata) --启动时初始化从这里开始
	inst:DoTaskInTime(math.random(), function(inst)
		OnIsDay_lightbulb(inst, TheWorld.state.isday)
	end)
end
local function OnIsDay2_lightbulb(inst, isit)
	if inst.task_l_isday ~= nil then
		inst.task_l_isday:Cancel()
		inst.task_l_isday = nil
	end
	if isit then
		inst.task_l_isday = inst:DoTaskInTime(math.random()*2+1, function()
			inst.task_l_isday = nil
			OnIsDay_lightbulb(inst, TheWorld.state.isday)
		end)
	else
		OnIsDay_lightbulb(inst, isit)
	end
end
local function OnWorkedFinish_lightbulb(inst, worker)
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
		inst.components.container:Close()
	end
	OnWorkedFinish_p2(inst, worker)
end

local dd_lightbulb = CROPS_DATA_LEGION["lightbulb"]
table.insert(prefs, Prefab("plant_lightbulb_l", function()
	local inst = CreateEntity()
	inst.entity:AddLight()
	Fn_common_p2(inst, dd_lightbulb)
	inst:SetPhysicsRadiusOverride(TUNING.FARM_PLANT_PHYSICS_RADIUS)
	inst.MiniMapEntity:SetIcon("plant_crop_l.tex")

	inst:AddTag("plant")
	inst:AddTag("not2bright_l") --棱镜专属标签

	inst.Light:SetFalloff(0.7)
	inst.Light:SetIntensity(0.7)
	inst.Light:SetColour(colour_tint[1], colour_tint[1], colour_tint[1])
	inst.Light:Enable(false)

	inst.xeedkey = "lightbulb"
	TOOLS_L.InitMouseInfo(inst, Fn_dealdata_p2, Fn_getdata_p2, 3)

	LS_C_Init(inst, "plant_lightbulb_l", false)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = OnEntityReplicated_lightbulb
		return inst
	end

	-- inst.lightmult_l = nil
	inst.lightrad_l = 2
	inst.fn_l_stage = dd_lightbulb.fn_animfix
	-- inst.isday_l = nil

	Fn_server_p2(inst)

	inst.components.inspectable.getstatus = GetStatus_p2

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
	inst.components.hauntable:SetOnHauntFn(OnHaunt_p2)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(OnWorkedFinish_lightbulb)

	inst:AddComponent("container")
    inst.components.container:WidgetSetup("plant_lightbulb_l")

	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(0)

	inst.components.perennialcrop2.fn_cluster = OnCluster_lightbulb
	inst.components.perennialcrop2:SetUp("lightbulb", dd_lightbulb, {
		moisture = true, nutrient = true, tendable = true, seasonlisten = true,
		nomagicgrow = dd_lightbulb.nomagicgrow, fireproof = dd_lightbulb.fireproof,
		cangrowindrak = dd_lightbulb.cangrowindrak, nogrowinlight = dd_lightbulb.nogrowinlight
	})
	inst.components.perennialcrop2.fn_stage = OnStage_lightbulb
	inst.components.perennialcrop2:SetStage(1, false)

	inst.OnLoadPostPass = OnLoadPostPass_lightbulb

	inst:ListenForEvent("itemget", ItemChange_lightbulb)
	inst:ListenForEvent("itemlose", ItemChange_lightbulb)
	inst:WatchWorldState("isday", OnIsDay2_lightbulb)

	return inst
end, { Asset("ANIM", "anim/crop_legion_lightbulb.zip"), Asset("ANIM", "anim/ui_lamp_1x4.zip") }, nil))

--------------------
--------------------

for k, v in pairs(defs) do
	table.insert(prefs, MakePlant(k, v))
end
for k, v in pairs(CROPS_DATA_LEGION) do
	if not v.dataonly then
		table.insert(prefs, MakePlant2(k, v))
	end
end

return unpack(prefs)
