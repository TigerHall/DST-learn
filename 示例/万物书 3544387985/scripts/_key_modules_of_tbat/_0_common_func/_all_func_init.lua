-- -- -- 这个文件是给 modmain.lua 调用的总入口
-- -- -- 本lua 和 modmain.lua 平级
-- -- -- 子分类里有各自的入口
-- -- -- 注意文件路径

TBAT.FNS = TBAT.FNS or {}


modimport("scripts/_key_modules_of_tbat/_0_common_func/00_params.lua")
-- 参数

modimport("scripts/_key_modules_of_tbat/_0_common_func/01_client_data_api.lua")
-- 客户端数据（跨存档）

modimport("scripts/_key_modules_of_tbat/_0_common_func/02_rpc_pushevent.lua")
-- RPC EVENT API 封装

modimport("scripts/_key_modules_of_tbat/_0_common_func/03_get_surround_points.lua")
-- 环状一圈

modimport("scripts/_key_modules_of_tbat/_0_common_func/04_animstate_2_table.lua")
-- 将 AnimState 从 userdata 转换为 table 并挂载代理逻辑

modimport("scripts/_key_modules_of_tbat/_0_common_func/05_snow_shadow_init.lua")
-- 积雪、影子

modimport("scripts/_key_modules_of_tbat/_0_common_func/06_bank_build_anim_get.lua")
-- 目标的 bank、build、anim 同时获取

modimport("scripts/_key_modules_of_tbat/_0_common_func/07_get_all_tags.lua")
-- 获取目标所有tags
modimport("scripts/_key_modules_of_tbat/_0_common_func/08_blank_slate_clone.lua")
-- 白板复制目标

modimport("scripts/_key_modules_of_tbat/_0_common_func/09_get_graveyard_location.lua")
-- 获取墓地坐标。

modimport("scripts/_key_modules_of_tbat/_0_common_func/10_container_item_giver.lua")
-- 物品给予

modimport("scripts/_key_modules_of_tbat/_0_common_func/11_get_random_diff_values_from_table.lua")
-- 从table里获取随机不同值。

modimport("scripts/_key_modules_of_tbat/_0_common_func/12_modimport.lua")
-- 自制的modimport函数，用来加载MOD根目录的脚本。

modimport("scripts/_key_modules_of_tbat/_0_common_func/13_definitions_api.lua")
-- 大型通用定义库

modimport("scripts/_key_modules_of_tbat/_0_common_func/14_zip_json_data.lua")
-- 压缩json文本库。（密码表形式）

modimport("scripts/_key_modules_of_tbat/_0_common_func/16_prefab_area_searcher.lua")
-- 区域搜索器

modimport("scripts/_key_modules_of_tbat/_0_common_func/17_string_replacer.lua")
-- 文本串替换封装