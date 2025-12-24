AddRoom("RosePatch", {
	colour = {r=.8,g=1,b=.8,a=.50},
	value = WORLD_TILES.DECIDUOUS, --季节性地皮
	contents = {
		countprefabs = {
			rosebush = function () return 2 + math.random(3) end
		},
		distributepercent = 0.2,
		distributeprefabs =	{
            fireflies = 0.1,
			flower = 0.35,
			flower_rose = 0.35,
			deciduoustree = 0.52,
			catcoonden = 0.05,
			red_mushroom = 0.21,
			sapling = 0.2
		}
	}
})

AddRoom("LilyPatch", {
	colour = {r=.8,g=1,b=.8,a=.50},
	value = WORLD_TILES.GRASS, --青草地皮
	contents = {
		countprefabs = {
			lilybush = function () return 2 + math.random(3) end
		},
		distributepercent = 0.2,
		distributeprefabs = {
            fireflies = 0.1,
            pond = 0.04,
			flower = 0.7,
			twiggytree = 0.52,
			evergreen = 0.22,
			berrybush = 0.2,
			green_mushroom = 0.21
		}
	}
})

AddRoom("OrchidPatch", {
	colour = {r=.8,g=1,b=.8,a=.50},
	value = WORLD_TILES.FOREST,	--森林地皮
	contents = {
		countprefabs = {
			orchidbush = function () return 2 + math.random(3) end
		},
		distributepercent = 0.2,
		distributeprefabs = {
            fireflies = 0.1,
			flower_evil = 0.35,
			flower = 0.35,
			evergreen = 0.52,
			blue_mushroom = 0.21,
			rock2 = 0.15,
			rock1 = 0.15
		}
	}
})
