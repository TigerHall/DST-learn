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

    "01_hedgehog_cactus_meat",      -- 小鲜肉
    "02_pear_blossom_petals",      -- 梨花花瓣
    "03_cherry_blossom_petals",      -- 樱花花瓣
    "04_valorbush",      -- 勇者玫瑰
    "05_crimson_bramblefruit",      -- 绯露莓
    "06_jellyfish",      -- 水母
    "07_raw_meat",      -- 新鲜的肉
    "08_cocoanut",      -- 椰子
    "09_lavender_flower_spike",      -- 薰衣草花穗
    "10_ephemeral_flower",      -- 识之昙花
    "11_ephemeral_flower_butterfly_wings",      -- 昙花蝴蝶翅膀
    "12_fantasy_potato",      -- 幻想土豆
    "13_fantasy_potato_seed",      -- 幻想土豆种子
    "14_fantasy_peach",      -- 幻想小桃
    "15_fantasy_peach_seed",      -- 幻想小桃种子
    "16_fantasy_apple",      -- 幻想苹果
    "17_fantasy_apple_seed",      -- 幻想苹果种子
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