--这个文件运行在modmain之前！
local _G = GLOBAL
local require = _G.require
local isChinese = GetModConfigData("Language") == "chinese"
local WORLD_TILES = _G.WORLD_TILES

--------------------------------------------------------------------------
--[[ 新地形相关 ]]
--------------------------------------------------------------------------

-- require("constants")
require("map/tasks")
local LAYOUTS = require("map/layouts").Layouts
local STATICLAYOUT = require("map/static_layout")
local NoiseTileFunctions = require("noisetilefunctions")

------增加一种混合地皮类型
AddTile(
    "SPRINGBEACH_L_NOISE", --地皮key
    "NOISE", --地皮类型 NOISE 代表一种混合地皮，会根据逻辑随机选择地皮
    {}
)
NoiseTileFunctions[WORLD_TILES.SPRINGBEACH_L_NOISE] = function(noise)
    if noise < 0.1 then
		return WORLD_TILES.IMPASSABLE
    elseif noise < 0.4 then
		return WORLD_TILES.DIRT
    -- elseif noise < 0.35 then
	-- 	return WORLD_TILES.MONKEY_GROUND
	end
	return WORLD_TILES.PEBBLEBEACH
end

------固定不变的静态地形
LAYOUTS["RoseGarden"] = STATICLAYOUT.Get("map/static_layouts/rosegarden")
LAYOUTS["OrchidGrave"] = STATICLAYOUT.Get("map/static_layouts/orchidgrave"..(isChinese and "_zh" or ""))
LAYOUTS["LilyPond"] = STATICLAYOUT.Get("map/static_layouts/lilypond")
LAYOUTS["OrchidForest"] = STATICLAYOUT.Get("map/static_layouts/orchidforest")
LAYOUTS["SpartacussGrave"] = STATICLAYOUT.Get("map/static_layouts/spartacussgrave"..(isChinese and "_zh" or ""))
LAYOUTS["MoonDungeon"] = STATICLAYOUT.Get("map/static_layouts/moondungeon")
LAYOUTS["TourmalineBase"] = STATICLAYOUT.Get("map/static_layouts/tourmalinebase")
LAYOUTS["HelperCemetery"] = STATICLAYOUT.Get("map/static_layouts/helpercemetery"..(isChinese and "_zh" or ""), {
    start_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = _G.LAYOUT_POSITION.CENTER,
    disable_transform = true
})
LAYOUTS["SivingCenter"] = STATICLAYOUT.Get("map/static_layouts/sivingcenter", {
    start_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = _G.LAYOUT_POSITION.CENTER,
    disable_transform = true
})
LAYOUTS["L_HotSpring"] = STATICLAYOUT.Get("map/static_layouts/l_hotspring", {
    start_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = _G.LAYOUT_POSITION.CENTER,
    disable_transform = true
})
LAYOUTS["L_SmallHotSpring"] = STATICLAYOUT.Get("map/static_layouts/l_smallhotspring", {
    start_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = _G.LAYOUT_POSITION.CENTER,
    disable_transform = true
})
LAYOUTS["L_BeWithFirenettle"] = STATICLAYOUT.Get("map/static_layouts/l_bewithfirenettle")

------随机多变的rooms小地形
require("map/rooms/forest/rooms_flowerspower")
require("map/rooms/forest/rooms_prayforrain")
require("map/rooms/forest/rooms_flashandcrush")
require("map/rooms/forest/rooms_desertsecret")
require("map/rooms/forest/rooms_legendoffall")

------由几种rooms组合形成的task区域
require("map/tasks/legionland")

-------------------------------
--static_layouts、rooms相关，主要是引用mod地形、向目前世界加入mod地形
-------------------------------

------
--花香四溢
------

AddTaskPreInit("Speak to the king", function(task) --“蔷薇花丛区域”会出现在猪王村附近
    task.room_choices["RosePatch"] = 1
end)
AddTaskPreInit("Speak to the king classic", function(task) --“蔷薇花丛区域”会出现在猪王村附近
    task.room_choices["RosePatch"] = 1
end)
AddTaskPreInit("Forest hunters", function(task) --“兰草花丛区域”会出现在海象巢森林
    task.room_choices["OrchidPatch"] = 1
end)
AddTaskPreInit("Make a pick", function(task) --“蹄莲花丛区域”会出现在绚丽大门附近
    task.room_choices["LilyPatch"] = 1
end)

------
--祈雨祭
------

AddTaskPreInit("Squeltch", function(task) --“雨竹区域”会出现在沼泽
    task.room_choices["MonsteraPatch"] = 1
end)
AddTaskPreInit("MoonIsland_Mine", function(task) --“月的地下城区域”会出现在月岛矿区
    task.room_choices["MoonDungeonPosition"] = 1
end)

------
--电闪雷鸣
------

AddTaskPreInit("Forest hunters", function(task) --“电气矿区”会出现在月石底座森林
    task.room_choices["TourmalineField"] = 1
end)

------
--尘世蜃楼
------

AddTaskPreInit("Lightning Bluff", function(task) --“颤栗树林”会出现在蚁狮沙漠
    task.room_choices["ShyerryForest"] = 1
end)
AddTaskPreInit("BigBatCave", function(task) --“协助者墓园”会出现在蝙蝠地形
    task.room_choices["HelperSquare"] = 1
end)

------
--丰饶传说
------

AddTaskPreInit("GreenForest", function(task) --“子圭之源”会出现在绿蘑菇森林
    task.room_choices["SivingSource"] = 1
end)

-------------------------------
--taskset相关，主要是设置静态地形随机在世界产生
-------------------------------

AddTaskSetPreInit("default", function(taskset)
    local tasks_all = {"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king",
        "Forest hunters", "Befriend the pigs", "For a nice walk", "Kill the spiders", "Killer bees!", "Make a Beehat",
        "The hunters", "Magic meadow", "Frogs and bugs", "Badlands"
    }
    taskset.set_pieces["RoseGarden"] = { count = 1, tasks = tasks_all }
    taskset.set_pieces["OrchidGrave"] = { count = 1, tasks = tasks_all }
    taskset.set_pieces["LilyPond"] = { count = 1, tasks = tasks_all }
    taskset.set_pieces["OrchidForest"] = { count = 1, tasks = tasks_all }

    table.insert(taskset.tasks, "L_RainIsland_Main")
end)

AddTaskSetPreInit("classic", function(taskset)
    local tasks_all = {"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king classic",
        "Forest hunters", "Befriend the pigs", "For a nice walk", "Kill the spiders", "Killer bees!", "Make a Beehat",
        "The hunters", "Magic meadow", "Frogs and bugs"
    }
    taskset.set_pieces["RoseGarden"] = { count = 1, tasks = tasks_all }
    taskset.set_pieces["OrchidGrave"] = { count = 1, tasks = tasks_all }
    taskset.set_pieces["LilyPond"] = { count = 1, tasks = tasks_all }
    taskset.set_pieces["OrchidForest"] = { count = 1, tasks = tasks_all }

    table.insert(taskset.tasks, "L_RainIsland_Main")
end)

AddTaskSetPreInit("cave_default", function(taskset)
    taskset.set_pieces["SpartacussGrave"] = { count = 1, tasks = {"MudLights", "RedForest", "GreenForest", "BlueForest",
        "ToadStoolTask1", "ToadStoolTask2", "ToadStoolTask3"}
    }
end)
