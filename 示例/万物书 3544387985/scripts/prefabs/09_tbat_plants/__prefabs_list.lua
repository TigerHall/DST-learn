----------------------------------------------------
--- 本文件单纯返还路径
----------------------------------------------------
--------------------------------------------------------------------------
local addr_test = debug.getinfo(1).source           ---- 找到绝对路径

local temp_str_index = string.find(addr_test, "scripts/prefabs/")
local temp_addr = string.sub(addr_test,temp_str_index,-1)
-- print("fake error 6666666666666:",temp_addr)    ---- 找到本文件所处的相对路径

local temp_str_index2 = string.find(temp_addr,"/__prefabs_list.lua")

local Prefabs_addr_base = string.sub(temp_addr,1,temp_str_index2) .. "/"    --- 得到最终文件夹路径

---------------------------------------------------------------------------
-- local Prefabs_addr_base = "scripts/prefabs/00_tbat_others/"               --- 文件夹路径
local prefabs_name_list = {

    "01_wild_hedgehog_cactus",          --- 野生刺猬小仙
    "02_hedgehog_cactus_pot",           --- 刺猬盆子
    "03_hedgehog_cactus",               --- 刺猬小仙
    "04_01_coconut_tree",                  --- 椰子树
    "04_02_coconut_tree_seed",                  --- 椰子树种子
    "04_03_coconut_cat_fruit",                  --- 清甜椰子
    "04_04_coconut_cat_kit",                  --- 椰子猫猫
    "04_05_coconut_cat",                  --- 椰子猫猫
    "05_three_kind_of_trees",                  --- 梨花树+樱花树
    "06_01_many_bushes",                  --- 多种 类 浆果灌木
    "07_01_dandycat",                  --- 蒲公英猫猫
    "07_03_dandelion_umbrella",                  --- 蒲公英花伞
    "07_04_jellyfish",                  --- 伴生水母
    "08_kitty_cattail",                  --- 喵蒲装饰草丛
    "09_kitty_bush",                  --- 猫猫草墩
    "10_water_plants_of_pond",                  --- 池边水草
    "11_01_plum_blossom_bush",                  --- 梅影装饰花丛
    "11_02_plum_blossom_bush_rose_skin_fx",     --- 梅影装饰花丛(皮肤特效件)
    "12_ephemeral_flower",                  --- 识之昙花
    "13_fluorescent_moss",                  --- 荧光苔藓
    "14_fluorescent_mushroom",              --- 荧光蘑菇

    "15_01_01_fantasy_apple",               --- 幻想苹果(种子、巨大物品、打蜡巨大、巨大枯萎)
    "15_01_02_fantasy_apple_mutated",       --- 幻想苹果【异变】
    "15_01_03_apple_legin_mutated",               --- 幻想苹果【棱镜异变】

    "15_02_01_fantasy_peach",               --- 幻想桃子(种子、巨大物品、打蜡巨大、巨大枯萎)
    "15_02_02_fantasy_peach_mutated",       --- 幻想桃子【异变】
    "15_02_03_peach_legin_mutated",         --- 幻想桃子【棱镜异变】

    "15_03_01_fantasy_potato",               --- 幻想土豆(种子、巨大物品、打蜡巨大、巨大枯萎)
    "15_03_02_fantasy_potato_mutated",       --- 幻想土豆【异变】
    "15_03_03_potato_legin_mutated",         --- 幻想土豆【棱镜异变】
}

---------------------------------------------------------------------------
---- 正在测试的物品
if TBAT.DEBUGGING == true then
    local debugging_name_list = {

        

    }
    for k, temp in pairs(debugging_name_list) do
        table.insert(prefabs_name_list,temp)
    end
end
---------------------------------------------------------------------------












local ret_addrs = {}
for i, v in ipairs(prefabs_name_list) do
    table.insert(ret_addrs,Prefabs_addr_base..v..".lua")
end
return ret_addrs