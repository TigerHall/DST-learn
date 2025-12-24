--------------------------------
--[[ 全局参数]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------
TUNING.DORAEMON_TECH ={}
TUNING.DORAEMON_TECH.MODNAME = modname
TUNING.DORAEMON_TECH.CONFIG = {}
------------------prefab 相关
---------------------------------------全局实体
TUNING.DORAEMON_TECH.DAEMON_ENTITY_PREFAB = "daemon_entity"
---------------------------------------竹蜻蜓
TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB = "bamboo_dragonfly"
---------------------------------------飞行相关
TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_TAG = "bamboo_dragonfly_tag"
TUNING.DORAEMON_TECH.DORAEMON_FLY_COOLER = -10 -- 空中比较冷,目标温度
TUNING.DORAEMON_TECH.DORAEMON_FLY_OFF_MIN_HUNGER = 10 -- 起飞最小饥饿值
TUNING.DORAEMON_TECH.DORAEMON_FLY_COOLDOWN = 5 -- 5秒冷却
TUNING.DORAEMON_TECH.DORAEMON_FLY_HEIGHT = 2 -- 高度
TUNING.DORAEMON_TECH.DORAEMON_FLY_HUNGER_MODIFIER = 3 -- 额外饥饿速率
TUNING.DORAEMON_TECH.DORAEMON_FLY_SPEED = 9 -- 飞行速度

---------------------------------------还原光线
TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB = "magic_flashlight"
TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USES = 5
TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_SANITY = -20
TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_TAG = "magic_flashlight_use_tag"
TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_RANGE = 2.7
---------------------------------------恶魔护照
TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB = "evil_passport"
TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG = "evil_passport_tag"
TUNING.DORAEMON_TECH.EVIL_PASSPORT_FUEL_TOTAL = 30 * 16 * 3 -- 完整的三天
---------------------------------------感觉监视器
TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB = "sensory_monitor"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_ITEM_PREFAB = "sensory_monitor_item"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB = "sensory_monitor_body"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG = "sensory_monitor_tag"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_PLAYER = "player"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_CAMERA = "camera"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY = {} -- table,key为用户,value为临时body
TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER = {} -- table,key为用户,value为监视的对象
TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS = {} -- table,key为用户,value为监视其的对象list
---------------------------------------感觉监视器 摄像头
TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB = "sensory_monitor_camera"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_ITEM_PREFAB = "sensory_monitor_camera_item"
TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS = {} -- table,摄像头集合
---------------------------------------记忆面包
TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB = "memory_bread"
TUNING.DORAEMON_TECH.MEMORY_BREAD_UNMEMORY = "memory_bread_unmemory"
---------------------------------------秘密垃圾桶
TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB = "secret_garbage_can"
TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_BONUS_LIMIT = 100 --奖励物品临界值
TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_BIG_BONUS_PER_COUNT = 5 -- 大奖励,每5个一次
-- limixi 大佬测试得出，1024px图片相当于1.7块地皮，1块地皮的长宽是4。其它图片大小对应游戏多大做除法就得到了
-- 当前图片宽度420px 高度128px     1.7 * 4 = 6.8   1024/6.8 = 0.006640625宽度/每像素
-- 420 * 0.006640625 = 2.78
-- 经过实践，采用2作为range，但需要注意即使如此，也超过了秘密垃圾洞贴图宽度的范围
-- 所以以上原理不通，可能哪里出了问题
TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_RANGE = 2



