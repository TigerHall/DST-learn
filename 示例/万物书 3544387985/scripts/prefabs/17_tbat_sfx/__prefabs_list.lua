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

    "01_dotted_circle"  ,   --- 虚线圈圈指示器
    "02_tile_outline",      --- 方框指示器
    "03_dotted_arrow",      --- 箭头指示器
    "04_knowledge_flash",      --- 特效
    "05_flame",             --- 火焰 特效
    "06_ground_fireflies",             --- 地面萤火虫

    "07_01_effect_butterfly",             --- 粒子特效 - 蝴蝶
    "07_02_effect_cherry_blossom_petals",             --- 粒子特效 - 樱花瓣
    "07_03_effect_cherry_blossom",             --- 粒子特效 - 樱花

    "08_crab_king_icefx",             --- 
    "09_maple_leaves_and_flames",             --- 
    "10_butterflies_explode",             --- 

    "11_01_yellow_star",                ---  【药剂】【粒子】星星
    "11_02_blue_flower",                ---  【药剂】【粒子】蓝色花朵
    "11_03_rose",                       ---  【药剂】【粒子】玫瑰
    "11_04_clover",                     ---  【药剂】【粒子】四叶草
    "11_05_pink_flower",                ---  【药剂】【粒子】粉色花朵

    "12_ground_four_leaves_clover",                ---  在地面的四叶草特效

    "13_snow_cap_rabbit_ice_cream",                 ---  雪顶兔兔冰激凌 粒子特效
    "14_baton_bunny_scepter",                       ---  芙蕾雅的小兔权杖 粒子特效
    "15_cheese_heart_phantom_butterfly_dining_fork",    ---  芝心幻蝶餐叉 粒子特效

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