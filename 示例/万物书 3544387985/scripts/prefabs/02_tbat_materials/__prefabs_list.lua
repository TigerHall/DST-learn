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

    "01_miragewood",            -- 幻源木
    "02_dandelion_umbrella",            -- 蒲公英伞
    "03_dandycat",            -- 蒲公英猫猫
    "04_wish_token",            -- 祈愿牌
    "05_white_plum_blossom",            -- 白梅花
    "06_snow_plum_wolf_hair",            -- 狼毛
    "07_snow_plum_wolf_heart",            -- 狼心
    "08_osmanthus_ball",            -- 桂花球
    "09_osmanthus_wine",            -- 桂花酒
    "10_emerald_feather",            -- 翠羽鸟的羽毛
    "11_liquid_of_maple_leaves",            -- 枫液
    "12_squirrel_incisors",            -- 松鼠牙
    "13_sunflower_seeds",            -- 葵瓜子
    "14_starshard_dust",            -- 星辰
    "15_four_leaves_clover_feather",            -- 四叶草鹤羽毛
    "16_lavender_laundry_detergent",            -- 薰衣草洗衣液
    -- "17_green_leaf_mushroom",            -- 森伞小菇
    "18_memory_crystal",            -- 记忆水晶

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