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

    "01_01_butterfly_wrapping_paper",       --- 蝴蝶打包纸
    "01_03_packed_box",                     --- 蝴蝶打包后的盒子

    "02_01_holo_maple_leaf",                --- 留影枫叶
    "02_02_holo_maple_leaf_packed",                --- 留影枫叶
    "03_jellyfish_in_bottle",                --- 瓶中水母
    "04_maple_squirrel",                --- 枫叶松鼠
    "05_snow_plum_wolf",                --- 梅雪小狼
    "06_trans_core",                --- 传送核心
    "07_blueprint",                --- 蓝图
    "08_01_notes_of_adventurer",                --- 冒险家笔记
    
    "09_01_item_crystal_bubble",                --- 水晶气泡
    "09_02_crystal_bubble_box",                 --- 水晶气泡(容器)
    -- "09_03_bubble_debuff",                 --- 水晶气泡(debuff)

    "10_00_debug_unlocker",                 --- 调试解锁配方用
    -- "10_01_failed_potion",                  --- 【药剂】 失败的药剂 （模板）
    -- "10_02_wish_note_potion",               --- 【药剂】 愿望之笺
    -- "10_03_veil_of_knowledge_potion",       --- 【药剂】 知识之纱
    -- "10_04_oath_of_courage_potion",         --- 【药剂】 勇气之誓
    -- "10_05_lucky_words_potion",             --- 【药剂】 幸运之语
    -- "10_06_peach_blossom_pact_potion",      --- 【药剂】 桃花之约
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