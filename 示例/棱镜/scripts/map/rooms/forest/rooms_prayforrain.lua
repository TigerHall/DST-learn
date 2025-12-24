AddRoom("MonsteraPatch", {
	colour = {r=.8,g=1,b=.8,a=.50},
	value = WORLD_TILES.MARSH, --沼泽地皮
	contents = {
		countprefabs = { --必定会出现对应数量的物品的表
			monstrain = function() return 2 + math.random(4) end,
			pond_mos = 1
		},
		distributepercent = 0.2, --distributeprefabs中物品的区域密集程度
		distributeprefabs = { --物品的数量分布比例
            fireflies = 0.2,
			flower = 0.1,
			mermhouse = 0.03,
			pond_mos = 0.2,
			reeds = .02,
			tentacle = 0.1
		}
	}
})

AddRoom("MoonDungeonPosition", {
	colour = {r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.METEORMINE_NOISE,
	contents = {
		countstaticlayouts = { ["MoonDungeon"] = 1 }, --使用这个方式来强制静态地形处在room地形中心区域
		distributepercent = 0.12,
		distributeprefabs = {
			rock_ice = 2,
			moonglass_rock = 0.2, --月晶矿
			rock_moon = 0.2, --月石矿
			moon_fissure = 1.5, --天体裂隙
			moonglass = 0.2
		}
	}
})

AddRoom("L_HotSpringPot", {
	colour = {r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.MONKEY_GROUND,
	contents = {
		countstaticlayouts = { ["L_HotSpring"] = 1 }, --使用这个方式来强制静态地形处在room地形中心区域
		countprefabs = {
			tumbleweedspawner = 1,
			messagebottleempty = 2,
			nitre = 5,
			batcave = function() return math.random(1, 2) end,
			scorched_skeleton = function() return 4 + math.random(4) end,
			oasis_cactus = function() return 3 + math.random(2) end --之后替换成新生物
		},
		distributepercent = 0.5,
		distributeprefabs = {
			rock_l_nitre = 2.0,
			fern_l = 1.5,
			flower_withered = 0.5,
			palmconetree_tall = 0.5,
			palmconetree_normal = 0.9,
			palmconetree_short = 0.3
		}
	}
})
AddRoom("L_SmallHotSpringPot", {
	colour = {r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.MONKEY_GROUND,
	contents = {
		countstaticlayouts = { ["L_SmallHotSpring"] = 1 },
		countprefabs = {
			tumbleweedspawner = 1,
			messagebottleempty = 1,
			nitre = 3,
			scorched_skeleton = function() return 3 + math.random(3) end,
			oasis_cactus = function() return 1 + math.random(2) end --之后替换成新生物
		},
		distributepercent = 0.5,
		distributeprefabs = {
			rock_l_nitre = 1.75,
			fern_l = 1.0,
			flower_withered = 0.5,
			flower = 0.1,
			palmconetree_tall = 0.9,
			palmconetree_normal = 0.9,
			palmconetree_short = 0.3
		}
	}
})
AddRoom("L_SpringBeach", {
	colour = {r=0.3,g=0.2,b=0.1,a=0.3},
	value = WORLD_TILES.SPRINGBEACH_L_NOISE,
	contents = {
		countstaticlayouts = { ["L_BeWithFirenettle"] = 1 },
		countprefabs = {
			trap_starfish = function() return 4 + math.random(4) end,
			messagebottle = 1
		},
		distributepercent = 0.3,
		distributeprefabs = {
			fern_l = 2.0,
			flower_withered = 0.5,
			dead_sea_bones = 1.0,
			driftwood_small1 = 2.5,
			driftwood_small2 = 2.5,
			driftwood_tall = 3.0
		}
	}
})
