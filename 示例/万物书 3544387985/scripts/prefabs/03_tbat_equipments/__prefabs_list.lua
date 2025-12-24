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

    "01_fantasy_tool",      -- 幻想工具
    "02_01_universal_baton",      -- 万物指挥棒
    "02_03_universal_baton_mark",      -- 万物指挥棒mark
    "03_shake_cup",      -- 摇摇杯
    "04_world_skipper",      -- 万物穿梭
    "05_01_furrycat_circlet",      -- 猫猫花环
    "06_01_ray_fish_hat",      -- 鳐鱼帽子
    "06_04_ray_fish_hat_fx",      -- 鳐鱼帽子(特效件)
    "07_01_snail_shell_of_mushroom",      -- 小蜗护甲
    "08_jumbo_ice_cream_tub",      -- 吨吨桶
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