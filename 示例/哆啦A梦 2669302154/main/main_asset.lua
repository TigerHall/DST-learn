--------------------------------
--[[ prefab和asset,minimap]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------

PrefabFiles = {
    --注意以下都是对应sripts/prefabs文件夹下的文件名称
    TUNING.DORAEMON_TECH.DAEMON_ENTITY_PREFAB,-- 守护实体
    TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_PREFAB,--竹蜻蜓
    TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB,--还原光线
    TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB,--恶魔护照
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB,--感觉监视器等
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB,--感觉监视器替身
    TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB,--感觉监视器摄像头等
    TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB,--记忆面包
    TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB,-- 秘密垃圾桶/洞
}
Assets = {
    --科技栏的
    Asset("ATLAS", "images/tab/doraemon_tab.xml"),
    Asset("IMAGE", "images/tab/doraemon_tab.tex"),

    Asset("ANIM", "anim/doraemon_fly.zip"),--动画
    Asset("ANIM", "anim/act_jumpboat.zip"),--动画
}


--下面留着备用
 local minimaps = {
     "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_PREFAB,
     "images/inventoryimages/"..TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB,
     "images/inventoryimages/"..TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB,
 }
 for _,v in pairs( minimaps ) do
     if v and v ~= "" then
         --table.insert(Assets,Asset("ATLAS", "images/"..v..".xml"))--小地图，容易炸的，留着备用
         --table.insert(Assets,Asset("IMAGE", "images/"..v..".tex"))--小地图，容易炸的，留着备用
         AddMinimapAtlas(v..".xml")
     end
 end