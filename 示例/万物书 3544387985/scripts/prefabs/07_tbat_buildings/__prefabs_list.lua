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

    "00_01_tbat_the_tree_of_all_things__ground_fx",       --- 地面的云特效
    "00_02_tbat_the_tree_of_all_things__area_fx",       --- 区域特效
    "00_03_tbat_the_tree_of_all_things",       --- 核心树木    
    "00_04_tbat_the_vines",       --- 树藤    

    "01_01_piano_rabbit",       --- 星琴小兔
    "02_sunflower_hamster",       --- 向日葵仓鼠灯
    "03_stump_table",       --- 软木餐桌
    "04_01_magic_potion_cabinet",       --- 魔法药剂柜
    "05_plum_blossom_table",       --- 梅花餐桌
    "06_plum_blossom_hearth",       --- 梅花灶台
    -- "07_cherry_blossom_rabbit_swing",       --- 樱花兔兔秋千
    -- "08_red_spider_lily_rocking_chair",       --- 彼岸花摇椅
    "09_rough_cut_wood_sofa",       --- 原木沙发
    "10_whisper_tome",          --- 物语集
    "11_woodland_lamp",       --- 森林矮灯

    "12_conch_shell_decoration",       --- 海螺贝壳装饰
    "13_star_and_cloud_decoration",       --- 星星云朵装饰
    "14_snowflake_decoration",       --- 雪花雪人装饰
    "15_cute_pet_stone_figurines",       --- 萌宠小石雕
    "16_cute_animal_decorative_figurines",       --- 萌宠装饰雕像
    "17_cute_animal_wooden_figurines",       --- 萌宠装饰木桩
    "18_carved_stone_tiles",       --- 石雕台阶

    "19_00_walls",       --- 墙

    "20_01_recruitment_notice_board",       --- 告示招募栏
    "21_01_trade_notice_board",       --- 告示交易栏

    "22_01_snow_plum_pet_house",       --- 梅花木屋
    "22_02_osmanthus_cat_pet_house",       --- 桂猫石屋
    "22_03_maple_squirrel_pet_house",       --- 秋枫树屋

    "23_fantasy_shop",       --- 瑶瑶奶悉的设计屋

    "24_info_slot",       --- 各种木牌的文字层
    "25_cloud_wooden_sign", -- 云朵小木牌
    "26_kitty_wooden_sign", -- 喵喵小木牌
    "27_bunny_wooden_sign", -- 兔兔小木牌
    "28_time_fireplace", -- 时光壁炉
    "29_chesspiece_display_stand", -- 雕像展示台
    "30_green_campanula_with_cat", -- 发光的路灯花
    "31_twin_goslings", -- 双生小鹅灯
    "32_lamp_moon_with_clouds", -- 花语云梦灯
    "33_pot_animals_with_flowers", -- 萌宠装饰盆栽

    "34_01_forest_mushroom_cottage", -- 森林蘑菇小窝

    "35_01_four_leaves_clover_crane_lv1", -- 四叶草鹤雕像 LV-1
    "35_02_four_leaves_clover_crane_lv2", -- 四叶草鹤雕像 LV-2

    "36_01_lavender_flower_house_wild", -- 野外的薰衣草花房
    "36_02_lavender_flower_house_wild_container", -- 野外的薰衣草花房[容器]
    "36_03_lavender_flower_house", -- 薰衣草花房(自建)
    "36_04_lavender_flower_house_visual_container", -- 薰衣草花房(自建的虚拟容器)

    "37_01_reef_lighthouse_wild", -- 野外的礁石灯塔
    "37_02_reef_lighthouse",        -- 礁石灯塔
    "37_03_reef_lighthouse_visual_container",        -- 礁石灯塔(容器)

    "atbook_chefwolf",       --- 小狼做饭
    "atbook_ordermachine",       --- 小狼做饭

    "atbook_swing",  --- 樱花兔兔秋千 彼岸花摇椅
    "atbook_wiki",  --- 万物书本书
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