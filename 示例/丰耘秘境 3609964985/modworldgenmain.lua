GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

local CHERRY_ISLAND_GENERATION = GetModConfigData("CHERRY_ISLAND_GENERATION") or 52

---------------------------------------------------------------------------
---[[添加地皮]]
---------------------------------------------------------------------------
local function HMRAddTile(id, name, data)
	local TileRanges =
	{
		LAND = "LAND",      --陆地
		NOISE = "NOISE",    --噪波
		OCEAN = "OCEAN",    --海
		IMPASSABLE = "IMPASSABLE",  --不可逾越
	}
	-- AddTile的具体定义可以去看游戏文件 /scripts/modutil.lua 第356~425行 和 /scripts/tilemanager.lua
	AddTile(
		string.upper(id),  --地皮名称  注意这个是唯一的，不要和其他的重复 必须为大写
		TileRanges[data.ranges or "LAND"],    --地皮类型 
		{
			ground_name = name, --自定义名字，随便填
			-- old_static_id = GROUND.MOSAIC_BLUE,  --旧版地皮编号 由于旧版地皮范围只能在0~255，已经不用了容易冲突，现在会自动给地皮分配编号，而且最大可以到8448。
		},
		{
			name = data.edge or "carpet",      --边缘样式 比如 牛毛地毯carpet 棋盘blocky 也可以自己做。这里设置为我们文件里的

			noise_texture = data.tex,     --这里是图片

			--定义在地皮上行走的声音
			runsound = data.runsound or "dontstarve/movement/run_marble",
			walksound = data.walksound or "dontstarve/movement/walk_marble",
			snowsound = data.snowsound or "dontstarve/movement/run_ice",
			mudsound = data.mudsound or "dontstarve/movement/run_mud",

			flooring = data.flooring or false,    	--标记为true则上面不能生长植物
			hard = data.hard or false,        	--标记为true则上面不可种植植物
			roadways = data.roadways or false,     	--标记为true则玩家在上面可以加速，类似于卵石路
			cannotbedug = data.cannotbedug,  	--标记为true则不能挖掉

			-- 海洋部分
			colors = data.colors or nil,
			ocean_depth = data.ocean_depth or nil,
			is_shoreline = data.is_shoreline or nil,
			wavetint = data.wavetint or nil,
		},
		{
			name = "map_edge",
			noise_texture = data.mini_tex,    --小地图图片
		},
		--挖掉的定义，如果这个表为空则挖掉之后不掉地皮
		data.item_prefab ~= nil and {
			name = data.item_prefab, -- 掉落物的代码
			anim = data.item_anim, -- Ground item
			bank_build = "hmr_turfs",
			invicon_override = data.item_prefab.."_turf",
			pickupsound = data.pickupsound or "vegetation_grassy",
		} or nil
	)
	-- 设置地皮层级关系(前者在后者之下)
	local tile_over = data.tile_over or WORLD_TILES.FARMING_SOIL
	ChangeTileRenderOrder(WORLD_TILES[string.upper(id)], tile_over)
	ChangeMiniMapTileRenderOrder(WORLD_TILES[string.upper(id)], tile_over)
end

local TURF_LIST = require("hmrmain/hmr_lists").TURF_LIST
for _, data in pairs(TURF_LIST) do
	HMRAddTile(string.upper(data.id), data.name, data)
end

--------------------------------------------------------------------------
---[[新地形相关]]
--------------------------------------------------------------------------
local LAYOUTS = require("map/layouts").Layouts
local STATICLAYOUT = require("map/static_layout")

-- 樱海岛
LAYOUTS["hmr_cherry_island"] = STATICLAYOUT.Get("map/static_layouts/hmr_cherry_island",{
	start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
	fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
	layout_position = LAYOUT_POSITION.CENTER,
	disable_transform = true,--ground_noise_monkeyisland
	add_topology = {room_id = "StaticLayoutIsland:HMRCherryIsland", tags = {"hmr_cherry", "RoadPoison", "nohunt", "nohasslers", "not_mainland"}}
})
LAYOUTS["hmr_cherry_island"]["ground_types"] = {
	[1] = WORLD_TILES.OCEAN_COASTAL_SHORE,		-- 1
	[2] = WORLD_TILES.OCEAN_COASTAL,			-- 2
    [3] = WORLD_TILES.HMR_CHERRY_GRASS,			-- 3
    [4] = WORLD_TILES.HMR_CHERRY_FLOWER,		-- 4
	[5] = WORLD_TILES.HMR_CHERRY_MYSTERY,		-- 5
	[6] = WORLD_TILES.HMR_CHERRY_ROAD,			-- 6
}

AddLevelPreInitAny(function(level)
	if level.location == "forest" then
		if level.ocean_prefill_setpieces ~= nil then
			level.ocean_prefill_setpieces["hmr_cherry_island"] = {count = 1}
		end
	end
end)

---------------------------------------------------------------------------
---[[补偿岛屿]]
---------------------------------------------------------------------------
local function ShouldRetrofit(island, savedata)
	for prefab, ents in pairs(savedata.ents) do
		if prefab == island.."_center" then
			print(string.format("【丰耘秘境】发现岛屿 %s ，跳过补偿", island))
			return false
		end
	end
	print(string.format("【丰耘秘境】未发现岛屿 %s ，尝试补偿", island))
	return true
end

local HMRRetrofitIsland = require("map/hmr_retrofit_island")
local RetrofitSaveData = require("map/retrofit_savedata")
local oldDoRetrofitting = RetrofitSaveData.DoRetrofitting
RetrofitSaveData.DoRetrofitting = function(savedata, world_map)
	-- 补偿樱海岛
	if ShouldRetrofit("hmr_cherry_island", savedata) then
		HMRRetrofitIsland.RetrofittingCherryIsland(world_map, savedata, 1, CHERRY_ISLAND_GENERATION)
	end

	if oldDoRetrofitting ~= nil then
		oldDoRetrofitting(savedata, world_map)
	end
end
