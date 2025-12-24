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

    "00_00_main_pet_eyebone_backpack",          --- 储存宠物骨眼的背包。
    "01_00_eyebone",          --- 宠物骨眼(所有)

    "02_00_pet_collar_for_snow_plum_chieftain",          --- 宠物项圈debuff ( 梅雪族长 )
    "03_00_pet_collar_for_osmanthus_cat",          --- 宠物项圈debuff ( 桂花猫猫 )
    "04_00_pet_collar_for_maple_squirrel",          --- 宠物项圈debuff ( 枫叶松鼠 )
    "05_00_pet_collar_for_mushroom_snail",          --- 宠物项圈debuff ( 蘑菇蜗牛 )
    "06_00_pet_collar_for_lavender_kitty",          --- 宠物项圈debuff ( 薰衣草猫猫 )
    "07_00_pet_collar_for_stinkray",                --- 宠物项圈debuff ( 帽子鳐鱼 )

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