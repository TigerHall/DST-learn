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

    "01_snow_plum_chieftain" , -- 梅雪族长
    "02_osmanthus_cat" , -- 桂花猫猫
    "03_maple_squirrel" , -- 枫叶松鼠
    "04_ephemeral_butterfly" , -- 昙花蝴蝶
    "05_mushroom_snail" , -- 蘑菇蜗牛
    "06_01_four_leaves_clover_crane" , -- 四叶草鹤
    "06_03_four_leaves_clover_crane_lucky_controller" , -- 四叶草鹤(好运相关的控制buff)
    "06_04_four_leaves_clover_crane_watcher" , -- 四叶草鹤(处理洞穴跟随的BUFF)
    "07_01_lavender_kitty" , -- 薰衣草猫猫
    "08_01_stinkray" ,                  -- 鳐鱼
    "08_02_stinkray_poison_debuff" ,    -- 鳐鱼的毒debuff

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