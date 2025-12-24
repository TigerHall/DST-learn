

if GetModConfigData("magic_craft_ancient") then
    AddRecipe2("slingshotammo_thulecite",		{Ingredient("thulecite_pieces", 1), Ingredient("nightmarefuel", 1)}, 							TECH.MAGIC_TWO,		{builder_tag="pebblemaker", numtogive = 10, no_deconstruction=true, nounlock=true}, {"MAGIC"})

    AddRecipe2("thulecite",						{Ingredient("thulecite_pieces", 6)},																	TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("wall_ruins_item",					{Ingredient("thulecite", 1)},																			TECH.MAGIC_TWO,			{nounlock=true, numtogive=6}, {"MAGIC"})
    AddRecipe2("nightmare_timepiece",				{Ingredient("thulecite", 2), Ingredient("nightmarefuel", 2)},											TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("orangeamulet",						{Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3), Ingredient("orangegem", 1)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("yellowamulet",						{Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3), Ingredient("yellowgem", 1)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("greenamulet",						{Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3), Ingredient("greengem", 1)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("orangestaff",						{Ingredient("nightmarefuel", 2), Ingredient("cane", 1), Ingredient("orangegem", 2)},					TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("yellowstaff",						{Ingredient("nightmarefuel", 4), Ingredient("livinglog", 2), Ingredient("yellowgem", 2)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("greenstaff",						{Ingredient("nightmarefuel", 4), Ingredient("livinglog", 2), Ingredient("greengem", 2)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("multitool_axe_pickaxe",			{Ingredient("goldenaxe", 1), Ingredient("goldenpickaxe", 1), Ingredient("thulecite", 2)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("nutrientsgoggleshat",				{Ingredient("plantregistryhat", 1), Ingredient("thulecite_pieces", 4), Ingredient("purplegem", 1)},		TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("ruinshat",							{Ingredient("thulecite", 4), Ingredient("nightmarefuel", 4)},											TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("armorruins",						{Ingredient("thulecite", 6), Ingredient("nightmarefuel", 4)},											TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("ruins_bat",						{Ingredient("livinglog", 3), Ingredient("thulecite", 4), Ingredient("nightmarefuel", 4)},				TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
    AddRecipe2("eyeturret_item",					{Ingredient("deerclops_eyeball", 1), Ingredient("minotaurhorn", 1), Ingredient("thulecite", 5)}, 		TECH.MAGIC_TWO,			{nounlock=true}, {"MAGIC"})
end
--------------------------------------------------------------------------------------------------------------------
-- if GetModConfigData("alchemy") then
--     AddRecipe2("rocks", {Ingredient("goldnugget",1)}, TECH.MAGIC_TWO, {}, {"REFINE"})
--     AddRecipe2("flint", {Ingredient("goldnugget",2)}, TECH.MAGIC_TWO, {}, {"REFINE"})
--     AddRecipe2("nitre", {Ingredient("goldnugget",4)}, TECH.MAGIC_TWO, {}, {"REFINE"})

--     AddRecipe2("moonrocknugget", {Ingredient("goldnugget",4)}, TECH.MAGIC_TWO, {}, {"REFINE"})
--     AddRecipe2("moonglass", {Ingredient("goldnugget",4)}, TECH.MAGIC_TWO, {}, {"REFINE"})

--     AddRecipe2("redgem", {Ingredient("goldnugget",10)}, TECH.MAGIC_TWO, {}, {"REFINE"})
--     AddRecipe2("bluegem", {Ingredient("goldnugget",10)}, TECH.MAGIC_TWO, {}, {"REFINE"})

--     AddRecipe2("greengem", {Ingredient("purplegem",2)}, TECH.MAGIC_TWO, {}, {"REFINE"})
--     AddRecipe2("orangegem", {Ingredient("purplegem",2)}, TECH.MAGIC_TWO, {}, {"REFINE"})
--     AddRecipe2("yellowgem", {Ingredient("purplegem",2)}, TECH.MAGIC_TWO, {}, {"REFINE"})

--     AddRecipe2("opalpreciousgem", {Ingredient("greengem",1),Ingredient("orangegem",1),Ingredient("yellowgem",1)}, TECH.MAGIC_TWO, {}, {"REFINE"})
-- end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("messagebottleempty") then
    AddRecipe2("messagebottleempty", {Ingredient("moonglass",1)}, TECH.SCIENCE_TWO, {}, {"REFINE"})
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("make_alterguardianshard") then
    AddRecipe2("alterguardianhatshard", {Ingredient("moonglass_charged", 3)}, TECH.MAGIC_TWO, {}, {"REFINE"})
end
--------------------------------------------------------------------------------------------------------------------
























