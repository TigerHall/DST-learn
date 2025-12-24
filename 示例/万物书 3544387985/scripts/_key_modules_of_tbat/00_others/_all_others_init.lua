-- -- -- 这个文件是给 modmain.lua 调用的总入口
-- -- -- 本lua 和 modmain.lua 平级
-- -- -- 子分类里有各自的入口
-- -- -- 注意文件路径


modimport("scripts/_key_modules_of_tbat/00_others/00_debugging_hook.lua") 
-- 难以归类的杂乱东西

modimport("scripts/_key_modules_of_tbat/00_others/01_replica_register.lua") 
-- replica 注册

modimport("scripts/_key_modules_of_tbat/00_others/02_hook_thesim.lua") 
-- TheSim hook

modimport("scripts/_key_modules_of_tbat/00_others/03_anim_get_bank_api.lua") 
-- 给 AnimState 添加 GetBank 函数

modimport("scripts/_key_modules_of_tbat/00_others/04_the_input_upgrade.lua") 
-- 给 TheInput 添加 额外函数

modimport("scripts/_key_modules_of_tbat/00_others/05_componentactions_crash_fix.lua") 
-- componentactions.lua 崩溃修复

modimport("scripts/_key_modules_of_tbat/00_others/06_rpc_event_register.lua") 
-- rpc event 信道

modimport("scripts/_key_modules_of_tbat/00_others/07_anim_get_scale_api.lua") 
-- AnimState:GetScale

modimport("scripts/_key_modules_of_tbat/00_others/08_transform_get_face_api.lua") 
-- Transform:get_face

modimport("scripts/_key_modules_of_tbat/00_others/09_extra_equipment_slot.lua") 
-- 额外的装备槽

modimport("scripts/_key_modules_of_tbat/00_others/10_show_me_mod_fix.lua") 
-- 尝试兼容show me mod

modimport("scripts/_key_modules_of_tbat/00_others/11_replica_com_in_player_tag_remover.lua") 
-- 额外的来自replica的tag移除
