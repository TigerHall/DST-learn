--------------------------------
--[[ modmain,加载mod的所有信息]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
-- 在env中设置元表,并增加__index元方法,
--   即:从env中获取相关值,如果env中不存在就直接从GLOBAL中获取,且不通过GLOBAL的元表
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local require = GLOBAL.require
-----------------------------------------------------------------------------------
-- 本mod代码和结构参考身在不知福mod,
-- 另外飞行组件等很多功能实现均参照了神话mod
-- 在此特别鸣谢
-----------------------------------------------------------------------------------
---------------------环境
modimport "main/main_env.lua"
---------------------设置环境
Environment:SetPro()
--Environment:SetTest()
---------------------初始化日志组件
require("util/logger")
Logger:Init(modname,Environment.log_level)
---------------------全局参数
modimport "main/main_tuning.lua"
modimport "main/main_global.lua"
---------------------设置
TUNING.DORAEMON_TECH.CONFIG.LANGUAGE = GetModConfigData("language")
TUNING.DORAEMON_TECH.CONFIG.CAMERA_SHARE = GetModConfigData("camera_share")
TUNING.DORAEMON_TECH.CONFIG.DESTROY_BONUS = GetModConfigData("destroy_bonus")
TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_BACKPACK = GetModConfigData("destroy_ground_backpack")
TUNING.DORAEMON_TECH.CONFIG.DESTROY_GROUND_HEAVY = GetModConfigData("destroy_ground_heavy")
---------------------语言
require("languages/"..TUNING.DORAEMON_TECH.CONFIG.LANGUAGE)
---------------------replica
modimport "main/main_replica.lua"
---------------------prefabs文件和asset
modimport "main/main_asset.lua"
---------------------科技树插入
modimport "main/main_tech.lua" --哆啦A梦科技
---------------------初始化
modimport "main/main_init.lua"
---------------------有关飞行的全局处理
modimport "main/main_fly.lua"
---------------------有关还原光线的全局处理
modimport "main/main_magic_flashlight.lua"
---------------------有关恶魔护照的全局处理
modimport "main/main_evil_passport.lua"
---------------------有关感觉监视器的全局处理
modimport "main/main_sensory_monitor.lua"
---------------------有关秘密垃圾桶/洞的全局处理
modimport "main/main_secret_garbage_can.lua"
---------------------配方，科技，动作，state
modimport "scripts/modframework.lua"