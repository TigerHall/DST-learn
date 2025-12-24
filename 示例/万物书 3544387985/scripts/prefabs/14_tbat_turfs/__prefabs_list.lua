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

    "01_water_lily_cat",        -- 睡莲猫猫
    "01_water_lily_cat_seed",        -- 睡莲猫猫 - 种子

    "02_01_three_carpets",        -- 3种地毯

    "03_turfs_pack_ocean",        -- 地皮制作栏叠包
    "04_turfs_pack_chesspieces",        -- 地皮制作栏叠包

    
}

---------------------------------------------------------------------------
---- 正在测试的物品
if TBAT.DEBUGGING == true then
    local debugging_name_list = {

        "01_water_lily_cat_debug_seed",        -- 睡莲猫猫 - 种子
        

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