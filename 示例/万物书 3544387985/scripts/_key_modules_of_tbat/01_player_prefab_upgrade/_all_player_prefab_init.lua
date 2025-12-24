-- -- -- 这个文件是给 modmain.lua 调用的总入口
-- -- -- 本lua 和 modmain.lua 平级
-- -- -- 子分类里有各自的入口
-- -- -- 注意文件路径

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/00_player_common_init.lua") 
-- 所有玩家都该有的模块

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/01_tbat_classified_install.lua") 
-- tbat专属的classified安装模块

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/02_custom_tag_sys.lua") 
-- 客制化 tag 系统

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/03_new_enter_gifts.lua") 
-- 新入存档礼物

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/04_pet_eyebone_backpack.lua") 
-- 宠物骨眼背包

modimport("scripts/_key_modules_of_tbat/01_player_prefab_upgrade/05_talker_event.lua") 
-- talker event ： 说话触发某些事件



