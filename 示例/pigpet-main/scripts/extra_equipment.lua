-- 优化并注释版：extra_equipment.lua
-- 目的：
--   - 在 HUD 增加两个装备栏位：背包 (BACK) 和 项链 (NECK)
--   - 把部分装备（护身符/背包）默认分配到相应新槽位
--   - 修复复活（amulet）在新增槽位时的判定问题（兼容原生 resurrection 逻辑）
-- 说明：
--   - 原文件名 extraequipment.lua 建议改为 extra_equipment.lua（snake_case）
--   - 对原有函数/变量名做了小范围重命名以提高可读性，但不改变游戏 API 调用
--   - 不要删除原有的注入/Hook 行为（它们是必要的），只是增加注释与更清晰的局部名字

local GLOBAL = GLOBAL

-- 定义新的装备槽位标识（全局可用）
GLOBAL.EQUIPSLOTS.BACK = "back"   -- 背包槽
GLOBAL.EQUIPSLOTS.NECK = "neck"   -- 项链槽（amulet）

-- 在玩家 HUD 初始化时注入新的装备槽UI
-- 思路：Hook playerhud:SetMainCharacter，追加两个 EquipSlot 并尝试打开已装备背包的容器
AddClassPostConstruct("screens/playerhud", function(self)
    local old_SetMainCharacter = self.SetMainCharacter
    function self:SetMainCharacter(maincharacter, ...)
        -- 调用原实现以保持标准行为
        old_SetMainCharacter(self, maincharacter, ...)

        -- 安全检查：确认 HUD 中包含 controls.inv
        if not (self.controls and self.controls.inv) then
            print("ERROR: Can't inject extra equipment slots into screens/playerhud.")
            return
        end

        -- 增加背包与项链槽位对应的 UI 槽（需要 atlas/tex 存在）
        self.controls.inv:AddEquipSlot(GLOBAL.EQUIPSLOTS.BACK, "images/slots5.xml", "back.tex")
        self.controls.inv:AddEquipSlot(GLOBAL.EQUIPSLOTS.NECK, "images/slots5.xml", "neck.tex")

        -- 可选：放大背包栏背景以适配新增槽位
        if self.controls.inv.bg then
            self.controls.inv.bg:SetScale(1.25, 1, 1.25)
        end

        -- 如果玩家当前已经装备了背包，则把背包容器打开到玩家上（以与原背包行为一致）
        local equipped_bp = maincharacter.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BACK)
        if equipped_bp and equipped_bp.components.container then
            equipped_bp.components.container:Close()
            equipped_bp.components.container:Open(maincharacter)
        end
    end
end)

-- ====================================================================
-- 将常见的护身符 prefab 分配到 NECK 槽
-- 说明：原版护身符默认装备槽为 BODY/HEAD/其它，本处统一放到 NECK
-- ====================================================================
local amulets = {
    -- 常规护身符列表（包含 mod 扩展项）
    "amulet", "blueamulet", "purpleamulet", "orangeamulet", "greenamulet", "yellowamulet",
    "blackamulet", "pinkamulet", "whiteamulet", "endiaamulet", "grayamulet", "broken_frosthammer",
    "musha_egg", "musha_egg1", "musha_egg2", "musha_egg3", "musha_egg8", "musha_eggs1", "musha_eggs2", "musha_eggs3",
}

for _, prefab in ipairs(amulets) do
    AddPrefabPostInit(prefab, function(inst)
        if inst.components.equippable then
            inst.components.equippable.equipslot = GLOBAL.EQUIPSLOTS.NECK
        end
    end)
end

-- ====================================================================
-- 将常见的背包 prefab 分配到 BACK 槽
-- ====================================================================
local backpacks = {
    "backpack", "piggyback", "krampus_sack", "icepack", "mailpack", "thatchpack", "piratepack", "spicepack",
    "seasack", "bunnyback", "wolfyback", "sunnybackpack", "frostback", "pirateback"
}

for _, prefab in ipairs(backpacks) do
    AddPrefabPostInit(prefab, function(inst)
        if inst.components.equippable then
            inst.components.equippable.equipslot = GLOBAL.EQUIPSLOTS.BACK
        end
    end)
end

-- ====================================================================
-- 复活相关兼容修复（针对 amulet 复活判定）
-- 问题来源：
--   - 复活逻辑会在某些时机直接查询 inventory:GetEquippedItem( EQUI SLOTS )，
--     当我们新增 NECK 槽后，某些代码可能以 slot 名硬编码方式查找，
--     导致复活判定错位。这里用一次性 hook 的方式兼容原实现。
-- 实现思路：
--   - 在调用 FindClosestResurrector / CanResurrect / DoResurrect 等关键点前设置一个标志位 fix_once
--   - 在 inventory:GetEquippedItem 的被 hook 实现中，如果 fix_once 被触发，
--     优先返回 NECK 槽的 amulet，以兼容老逻辑
-- 说明：这种做法尽量保持最小侵入性，仅在需要时临时改变 GetEquippedItem 行为，然后恢复
-- ====================================================================

local comp_resurrectable = GLOBAL.require "components/resurrectable"
local comp_inventory = GLOBAL.require "components/inventory"

-- 临时标志：仅在一次调用期间生效（由复活流程触发）
local _fix_once = nil

-- 保存原始 GetEquippedItem 用于调用与恢复
local _old_GetEquippedItem = comp_inventory.GetEquippedItem
function comp_inventory:GetEquippedItem(slot, ...)
    -- 如果 _fix_once 标志位被设置，尝试先返回 NECK 槽（amulet）以兼容复活查找
    if _fix_once then
        -- 清除标志（仅一次）
        _fix_once = nil
        local neck_item = _old_GetEquippedItem(self, GLOBAL.EQUIPSLOTS.NECK, ...)
        if neck_item ~= nil and neck_item.prefab == "amulet" then
            -- 若项链槽里确实是 amulet，则返回它（模拟原版行为）
            return neck_item
        end
        -- 否则继续 fallthrough 到正常返回（按传入的 slot）
    end
    return _old_GetEquippedItem(self, slot, ...)
end

-- Hook resurrectable 的关键函数，在调用前把 _fix_once 设置为 true
local _old_FindClosestResurrector = comp_resurrectable.FindClosestResurrector
function comp_resurrectable:FindClosestResurrector(...)
    _fix_once = true
    return _old_FindClosestResurrector(self, ...)
end

local _old_CanResurrect = comp_resurrectable.CanResurrect
function comp_resurrectable:CanResurrect(...)
    _fix_once = true
    return _old_CanResurrect(self, ...)
end

local _old_DoResurrect = comp_resurrectable.DoResurrect
function comp_resurrectable:DoResurrect(...)
    _fix_once = true
    return _old_DoResurrect(self, ...)
end

-- ====================================================================
-- 修正状态机中复活状态（在 SGManager 初始化后替换状态回调）
-- 目标：当状态机在执行 amulet_rebirth 状态退出时，也触发 fix_once（与上面一致）
-- 说明：这是为了兼容在状态退出时直接触发复活流程的情况
-- ====================================================================
AddSimPostInit(function()
    for instance, _ in pairs(GLOBAL.SGManager.instances) do
        if instance.sg and instance.sg.name == "wilson" then
            for _, state in pairs(instance.sg.states) do
                if state.name == "amulet_rebirth" then
                    local old_onexit = state.onexit
                    state.onexit = function(...)
                        _fix_once = true
                        return old_onexit(...)
                    end
                    break
                end
            end
            break
        end
    end
end)