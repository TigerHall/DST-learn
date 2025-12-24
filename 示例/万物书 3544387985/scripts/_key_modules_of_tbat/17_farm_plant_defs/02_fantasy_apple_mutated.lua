local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

local function MakeGrowTimes(germination_min, germination_max, full_grow_min, full_grow_max)
	local grow_time = {}

	-- 发芽时间
	grow_time.seed		= {germination_min, germination_max}

	-- 生长时间
	grow_time.sprout	= {full_grow_min * 0.5, full_grow_max * 0.5}
	grow_time.small		= {full_grow_min * 0.3, full_grow_max * 0.3}
	grow_time.med		= {full_grow_min * 0.2, full_grow_max * 0.2}

	-- 收获后腐烂时间
	grow_time.full		= 4 * TUNING.TOTAL_DAY_TIME
	grow_time.oversized	= 6 * TUNING.TOTAL_DAY_TIME
	grow_time.regrow	= {4 * TUNING.TOTAL_DAY_TIME, 5 * TUNING.TOTAL_DAY_TIME} -- min, max

	return grow_time
end

--潮湿度需求
local drink_low = TUNING.FARM_PLANT_DRINK_LOW
local drink_med = TUNING.FARM_PLANT_DRINK_MED
local drink_high = TUNING.FARM_PLANT_DRINK_HIGH

--肥料需求
local S = TUNING.FARM_PLANT_CONSUME_NUTRIENT_LOW
local M = TUNING.FARM_PLANT_CONSUME_NUTRIENT_MED
local L = TUNING.FARM_PLANT_CONSUME_NUTRIENT_HIGH

PLANT_DEFS["tbat_farm_plant_fantasy_apple_mutated"]	= {
	build = "tbat_farm_plant_fantasy_apple_mutated", 			--这是作物的动画文件，也就是你需要改的地方
	bank = "tbat_farm_plant_fantasy_apple_mutated",				--这是bank文件，直接用土豆的就行
	--生长时间
	grow_time = MakeGrowTimes(12 * TUNING.SEG_TIME, 16 * TUNING.SEG_TIME, 4 * TUNING.TOTAL_DAY_TIME, 7 * TUNING.TOTAL_DAY_TIME),
	--潮湿度
	moisture = {drink_rate = drink_med,	min_percent = TUNING.FARM_PLANT_DROUGHT_TOLERANCE},
	--肥料需求
	nutrient_consumption = {0, 0, M},
	--肥料产出
	nutrient_restoration = {true, true, nil},
	--杂草容忍度
	max_killjoys_tolerance = TUNING.FARM_PLANT_KILLJOY_TOLERANCE,
	--生长季节(春、秋)
	good_seasons	= { autumn = true, spring = true,winter = true},
	--重量数据		min	 	max		sigmoid%
	weight_data = { 384.59, 662.77, .18 },
	--音效
	sounds = {
		grow_oversized = "farming/common/farm/potato/grow_oversized",
		grow_full = "farming/common/farm/grow_full",
		grow_rot = "farming/common/farm/rot",
	},
	--农作物代码
	prefab = "tbat_farm_plant_fantasy_apple_mutated",			--记得改
	--果实
	product = "tbat_food_fantasy_apple",				--记得改
	--巨型果实
	product_oversized = "tbat_eq_fantasy_apple_mutated_oversized",		--记得改
	--种子
	seed = "tbat_food_fantasy_apple_mutated_seed",				--记得改
	--作物标签
	plant_type_tag = "tbat_farm_plant_apple",			--记得改
	--巨型腐烂果实产出					
	loot_oversized_rot = {"spoiled_food", "spoiled_food", "spoiled_food", "tbat_food_fantasy_apple_seeds"},	--记得改
	--同种植物需求数量
	family_min_count = TUNING.FARM_PLANT_SAME_FAMILY_MIN,
	--同种植物检索距离
	family_check_dist = TUNING.FARM_PLANT_SAME_FAMILY_RADIUS,
	--农作物状态标签对应网络变量类型
	stage_netvar = net_tinybyte,
	--生长状态信息(注意，以下动画名不能修改！！被官方锁死这些动画名字了！！)
	plantregistryinfo = {
		{-- 种子阶段 - _seed
			text = "seed",
			anim = "crop_seed",
			grow_anim = "grow_seed",
			learnseed = true,
			growing = true,
		},
		{-- 发芽阶段 _sprout
			text = "sprout",
			anim = "crop_sprout",
			grow_anim = "grow_sprout",
			growing = true,
		},
		{-- 生长阶段 _small
			text = "small",
			anim = "crop_small",
			grow_anim = "grow_small",
			growing = true,
		},
		{-- 出果阶段 _med
			text = "medium",
			anim = "crop_med",
			grow_anim = "grow_med",
			growing = true,
		},
		{-- 可采摘阶段 _full
			text = "grown",
			anim = "crop_full",
			grow_anim = "grow_full",
			revealplantname = true,
			fullgrown = true,
		},
		{--  巨型果实阶段 _oversized
			text = "oversized",
			anim = "crop_oversized",
			grow_anim = "grow_oversized",
			revealplantname = true,
			fullgrown = true,
			hidden = true,
		},
		{-- 成熟->腐烂 _rot
			text = "rotting",
			anim = "crop_rot",
			grow_anim = "grow_rot",
			stagepriority = -100,
			is_rotten = true,
			hidden = true,
		},
		{-- 巨大果实->腐烂
			text = "oversized_rotting",
			anim = "crop_rot_oversized",
			grow_anim = "grow_rot_oversized",
			stagepriority = -100,
			is_rotten = true,
			hidden = true,
		},
	},
	-- plantregistrywidget = "widgets/redux/farmplantpage",
	plantregistrywidget = "_key_modules_of_tbat/17_farm_plant_defs/note_book/03_farmplantpage",
	-- plantregistrysummarywidget = "widgets/redux/farmplantsummarywidget",  -- 使用官方缺省页面
	-- plantregistrysummarywidget = "_key_modules_of_tbat/17_farm_plant_defs/note_book/01_farmplantsummarywidget", --- 没啥子用
	unknownwidget = "_key_modules_of_tbat/17_farm_plant_defs/note_book/02_unknownplantpage",
	--合影动画
	pictureframeanim = {anim = "emoteXL_loop_dance0", time = 7*FRAMES},
}


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

	变异切换

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
	local function oversize_replace(inst,target)
		local x,y,z = target.Transform:GetWorldPosition()
		target:Remove()
		inst.Transform:SetPosition(x,y,z)
		inst.force_oversized = true
        inst.components.growable:SetStage(4)
        inst.components.growable:DoGrowth()
		target:Remove()
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
	AddPrefabPostInit("tbat_farm_plant_fantasy_apple_mutated",function(inst)
		if not TheWorld.ismastersim then
			return
		end
		inst:ListenForEvent("normal_switched",oversize_replace)
	end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------