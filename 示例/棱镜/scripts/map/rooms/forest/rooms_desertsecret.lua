require "map/room_functions"

AddRoom("ShyerryForest", {
	colour = {r=.8,g=1,b=.8,a=.50},
	value = WORLD_TILES.DIRT_NOISE, --荒漠地皮
	tags = { "RoadPoison", "sandstorm" }, --sandstorm这个标签不加的话会导致无法生成沙暴
	contents = {
		countprefabs = {
			shyerrycore = 1,
			shyerrycore_planted = 1,
			shyerryflower = function() return 1 + math.random(2) end
		},
		distributepercent = 0.01,
		distributeprefabs = {
			oasis_cactus = 0.001
		}
	}
})

AddRoom("HelperSquare", {
	colour = {r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.FOREST, --森林地皮
	tags = { "Hutch_Fishbowl", "Mist" },
    type = NODE_TYPE.Room,
	contents = {
		countstaticlayouts = { ["HelperCemetery"] = 1 }, --使用这个方式来强制静态地形处在room地形中心区域
		distributepercent = 0.2,
		distributeprefabs = {
			rocks = 0.1,
            rock1 = 0.2,
            rock_flintless = 0.2,
            rock_flintless_med = 0.2,
            rock_flintless_low = 0.2,
			marsh_tree = 1.5,
			marsh_bush = 0.2,
            livingtree = 0.01
		}
	}
})
