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

    "01_01_pear_cat",      --- 梨花猫猫
    "02_01_cherry_blossom_rabbit_mini",      --- 樱花兔兔mini
    "03_01_cheery_blossom_rabbit",      --- 樱花兔兔
    "04_01_emerald_feathered_bird_collection_chest",      --- 翠羽鸟收集箱
    "05_squirrel_stash_box",      --- 鼠鼠囤货箱
    "06_01_mushroom_snail_cauldron",      --- 蘑菇小蜗埚
    "07_01_lavender_kitty",      --- 薰衣草小猫
    "08_01_little_crane_bird",      --- 小小鹤草箱
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