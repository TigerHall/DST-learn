--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    解决图鉴不显示的方法：
    
        PLANT_DEFS["tbat_farm_plant_fantasy_apple"]    = {
            --农作物代码
            prefab = "tbat_farm_plant_fantasy_apple",            --farm_plant_tbat_fantasy_apple
            --果实
            product = "tbat_food_fantasy_apple",                --tbat_fantasy_apple
            --巨型果实
            product_oversized = "tbat_eq_fantasy_apple_oversized",        --tbat_fantasy_apple_oversized
            --种子
            seed = "tbat_food_fantasy_apple_seeds",                --tbat_fantasy_apple_seeds
        }

        把这些代码名字统一一下格式就行了，
        农作物代码：farm_plant_ ..**
        果实：**
        巨型果实：**.._oversized
        种子：**.._seeds

        【重要】  PLANT_DEFS 的index 为果实名字。
        【重要】  PLANT_DEFS 的index 为果实名字。
        【重要】  PLANT_DEFS 的index 为果实名字。
        【重要】  PLANT_DEFS 的index 为果实名字。

        因为植物图鉴页面的记录索引是用的果实名称，如果要保留原来的代码名字的话就要hook一下plantregistrydata这个文件里的函数了

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 和图鉴有关的 侵入操作
    modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/note_book/00_hook_plants_page.lua")
    --- 图册主页面侵入替换
    modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/note_book/01_all_book_widgets_hook.lua")
    --- 处理图册格子替换封装
    modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/note_book/02_unknownplantpage.lua")
    --- 未解锁任何阶段的显示界面
    modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/note_book/03_farmplantpage.lua")
    --- 解锁任意阶段后的显示界面
    modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/note_book/04_unlock_book_notes.lua")
    --- 解锁控制事件
    modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/00_01_plantregistryupdater_hooker.lua")
    --- 处理图册录入解锁
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/00_02_legin_data_controller.lua")
--- 棱镜-子圭育 数据进入
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/01_fantasy_apple.lua")
--- 幻想苹果
modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/02_fantasy_apple_mutated.lua")
--- 幻想苹果(异变)

modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/03_fantasy_peach.lua")
--- 幻想小桃
modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/04_fantasy_peach_mutated.lua")
--- 幻想小桃(异变)

modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/05_fantasy_potato.lua")
--- 幻想土豆
modimport("scripts/_key_modules_of_tbat/17_farm_plant_defs/06_fantasy_potato_mutated.lua")
--- 幻想土豆(异变)
