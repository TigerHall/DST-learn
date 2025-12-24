--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    常用物品功能统一封装模块群。

    多个prefab拥有相同的功能，进行统一的封装维护。方便修BUG一起修。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    TBAT.MODULES = Class()
    TBAT.PET_MODULES = Class()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/01_building_swing_key_code.lua") 
-- 秋千用的核心模块

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/02_offical_workable_destroy.lua") 
-- 官方的拆除模块

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/03_notes_of_adventurer__ui.lua") 
-- 冒险家笔记UI相关

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/04_pet_house.lua") 
-- 宠物房子相关

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/05_sign_with_text_anim_layer.lua") 
-- 各种木牌的文字层

modimport("scripts/_key_modules_of_tbat/13_unified_functionality_modules/06_anim_hat_creater.lua") 
-- 动画类型的帽子API封装