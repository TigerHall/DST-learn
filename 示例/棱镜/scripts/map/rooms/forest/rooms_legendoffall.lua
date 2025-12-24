AddRoom("SivingSource", {
	colour = {r=0.1,g=0.1,b=0.8,a=0.9},
	value = WORLD_TILES.FUNGUSGREEN, --绿孢子地皮
	tags = { "Hutch_Fishbowl" },
	contents = {
		countstaticlayouts={["SivingCenter"] = 1}, --使用这个方式来强制静态地形处在room地形中心区域
		countprefabs = {
			siving_derivant = function () return math.random(0, 1) end,
			siving_derivant_lvl1 = function () return math.random(0, 2) end,
			siving_derivant_lvl2 = function () return math.random(1, 2) end,
			siving_derivant_lvl3 = function () return math.random(2, 3) end,
			siving_rocks = function () return math.random(0, 3) end
		},
		distributepercent = 0.4,
		distributeprefabs = {
			mushtree_tall = 0.1, --蓝蘑菇树
			mushtree_small = 0.1, --绿蘑菇树
            blue_mushroom = 0.5,
            green_mushroom = 0.5,

			rock_petrified_tree_old = 0.5,
			rock_petrified_tree_tall = 2.0,
			rock_petrified_tree_med = 1.0,
			rock_petrified_tree_short = 1.0,

            grass = 0.1,
            sapling = 0.1,
            berrybush = 1.5,
            berrybush_juicy = 0.8,
            boneshard = 0.05,
            houndbone = 0.05,

			rabbithouse = 0.01,
            slurper = 0.001
		}
	}
})
