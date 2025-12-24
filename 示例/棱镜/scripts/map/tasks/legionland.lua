
------雨硫岛

AddTask("L_RainIsland_Main", {
	locks = {},
	keys_given = {},
	region_id = "island_l_rain",
	level_set_piece_blocker = true,
	room_tags = { "RoadPoison", "nohasslers", "not_mainland" }, --nohasslers 代表熊大巨鹿不会以待在这个区域的玩家为生成目标
    room_choices = {
        ["L_HotSpringPot"] = 1,
		["L_SmallHotSpringPot"] = function() return math.random(1, 2) end,
		["L_SpringBeach"] = 1
    },
    room_bg = WORLD_TILES.MONKEY_GROUND, --月亮码头海滩地皮
    background_room = "Empty_Cove",
	cove_room_name = "Empty_Cove",
	-- crosslink_factor = 1,
	cove_room_chance = 1,
	cove_room_max_edges = 2,
    colour = {r=0.6,g=0.6,b=0.0,a=1}
})
