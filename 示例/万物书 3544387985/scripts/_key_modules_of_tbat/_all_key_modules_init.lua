-- -- -- 这个文件是给 modmain.lua 调用的总入口
-- -- -- 本lua 和 modmain.lua 平级
-- -- -- 子分类里有各自的入口
-- -- -- 注意文件路径

modimport("scripts/_key_modules_of_tbat/_0_common_func/_all_func_init.lua")
-- 常用函数注册

modimport("scripts/_key_modules_of_tbat/00_others/_all_others_init.lua") 
-- 难以归类的杂乱东西

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/_all_player_prefab_init.lua") 
-- 玩家升级

modimport("scripts/_key_modules_of_tbat/02_the_world_upgrade/_all_the_world_init.lua") 
-- 世界模块

modimport("scripts/_key_modules_of_tbat/03_other_prefabs_upgrade/__all_other_prefabs_init.lua") 
-- 所有prefabs升级

modimport("scripts/_key_modules_of_tbat/04_origin_components_hook/_all_com_init.lua") 
-- 所有component升级

modimport("scripts/_key_modules_of_tbat/05_actions/_all_actions_init.lua") 
-- 所有动作（sg）、交互

modimport("scripts/_key_modules_of_tbat/06_widgets/__all_widget_init.lua") 
-- 界面所有相关

modimport("scripts/_key_modules_of_tbat/07_recipes/_all_recipes_init.lua") 
-- 所有配方相关

modimport("scripts/_key_modules_of_tbat/10_turfs/_all_turfs_init.lua") 
-- 地皮

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/_all_skins_api_init.lua") 
-- 建筑、物品皮肤系统

modimport("scripts/_key_modules_of_tbat/12_fantasy_island_creater/__fantasy_island_init.lua") 
-- 幻想岛屿  创近器

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/__all_modules_init.lua") 
-- 常用物品功能统一封装模块群。

modimport("scripts/_key_modules_of_tbat/14_wolf_cooking_modules/__all_init.lua")
-- [小狼]制作配方最大页数

modimport("scripts/_key_modules_of_tbat/15_cooking/__all_cooking_init.lua")
-- 烹饪相关

modimport("scripts/_key_modules_of_tbat/16_mushroom_snal_cauldron_sys/_all_cauldron_modules_init.lua")
-- 蘑菇小蜗埚 的配方系统

modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/__all_defs_init.lua")
-- 农场作物 定义