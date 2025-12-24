-- -- -- 这个文件是给 modmain.lua 调用的总入口
-- -- -- 本lua 和 modmain.lua 平级
-- -- -- 子分类里有各自的入口
-- -- -- 注意文件路径


modimport("imports_of_tbat/00_load_assets.lua")
-- 加载资源

modimport("imports_of_tbat/01_mod_config.lua")
-- mod配置

modimport("imports_of_tbat/02_01_strings_ch.lua")
-- 文本库（中文）

modimport("imports_of_tbat/02_02_strings_en.lua")
-- 文本库（英文）

modimport("imports_of_tbat/03_strings_pre_init.lua")
-- 文本库初始化匹配官方的格式

modimport("imports_of_tbat/04_inventoryimages_icon_register.lua")
-- 物品图标注册

modimport("imports_of_tbat/05_minimap_icon_register.lua")
-- 小地图图标注册

modimport("imports_of_tbat/06_load_sounds.lua")
-- 声音素材加载

modimport("imports_of_tbat/tuning_mz.lua")
-- 全局变量

modimport("imports_of_tbat/ui_mz.lua")
-- UI相关

modimport("imports_of_tbat/hook_mz.lua")
-- 钩子相关

