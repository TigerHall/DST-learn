local _G = GLOBAL
local TECH = _G.TECH
local Recipe = _G.Recipe
local STRINGS = _G.STRINGS
local Ingredient = _G.Ingredient
local RECIPETABS = _G.RECIPETABS

PrefabFiles ={
"krampus_coin",
}

AddRecipe2("book_gardening", {Ingredient("papyrus",2), Ingredient("poop",1), Ingredient("seeds", 5),Ingredient("krampus_coin",1,"images/inventoryimages/krampus_coin.xml")}, _G.TECH.BOOKCRAFT_ONE, {builder_tag = "bookbuilder"}, {"CHARACTER"})

STRINGS.NAMES.KRAMPUS_COIN = "时间法则"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.KRAMPUS_COIN = "唤醒前世今生找回迷失\n在岁月中的记忆碎片..."

AddPrefabPostInit("klaus", function(inst)
	inst.components.lootdropper:AddChanceLoot("krampus_coin",1)
end)