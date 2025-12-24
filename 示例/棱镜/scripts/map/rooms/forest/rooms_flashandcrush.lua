AddRoom("TourmalineField", {
	colour = {r=.66,g=.66,b=.66,a=.50},
	value = WORLD_TILES.ROCKY, --岩石地皮
	contents = {
		countstaticlayouts = { ["TourmalineBase"] = 1 }, --使用这个方式来强制静态地形处在room地形中心区域
		distributepercent = 0.2,
		distributeprefabs = {
			rocks = 0.2,
            rock1 = 1.2,
            rock2 = 1,
            rock_ice = 0.1,
            rock_flintless = 0.5,
            rock_flintless_med = 0.1,
            rock_flintless_low = 0.1,
            -- rock_petrified_tree_old = 0.3,
            tallbirdnest = 0.01
		}
	}
})
