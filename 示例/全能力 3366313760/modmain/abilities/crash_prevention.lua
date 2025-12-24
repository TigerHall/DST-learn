--[[
由于科雷“我不崩就不修”的原则，所以我自己需要做一些hook，来保证某些功能之间不要冲突，还有避免一些粗心大意mod引起的游戏崩溃。

]]

local Utils = require("aab_utils/utils")
local KEY = modname .. "提示："

-- 解决伍迪和沃特能力不兼容的问题，RemoveRegenSource在执行时只判断了source对应的表存不存在，而没有判断对应的key存不存在，不存在时会崩溃。
local Health = require("components/health")
Utils.FnDecorator(Health, "RemoveRegenSource", function(self, source, key)
    local src_params = self.regensources ~= nil and self.regensources[source] or nil
    return nil, src_params and key and not src_params.tasks[key]
end)

----------------------------------------------------------------------------------------------------

-- 当玩家装备aoetargeting可施法武器的时候，会导致不管是施法还是这个动作都无法执行，我希望最少有一个能执行
AddComponentPostInit("playeractionpicker", function(self)
    Utils.FnDecorator(self, "GetPointSpecialActions", function(self)
        local item = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        return { {} }, item and item.components.aoetargeting and item.components.aoetargeting:IsEnabled() and not self.inst.checkingmapactions
    end)
end)

----------------------------------------------------------------------------------------------------
-- 对于推送常见事件data的补充，避免科雷或mod有些地方没有判断data是否存在导致崩溃

-- 一些常见的含有data的事件
local NEED_DATA_EVENTS = {
    death = true,
    onattackother = true,
    onmissother = true,
    attacked = true,
    itemget = true,
    itemlose = true,
    timerdone = true,
    picked = true,
    worked = true,
    equip = true,
    unequip = true,
    onbuilt = true,
    healthdelta = true,
    sanitydelta = true,
    hungerdelta = true,
    equipped = true,
    unequipped = true,
}

-- Utils.FnDecorator(EntityScript, "PushEvent", function(inst, event, data, ...)
--     if event and NEED_DATA_EVENTS[event] and not data then
--         return nil, false, { inst, event, {}, ... }
--     end
-- end)

-- 覆盖科雷推送事件代码，我不希望对象被移除时继续执行回调
function EntityScript:PushEvent(event, data)
    if event and NEED_DATA_EVENTS[event] and not data then
        data = {}
    end

    if self.event_listeners then
        local listeners = self.event_listeners[event]
        if listeners then
            --make a copy list of all callbacks first in case
            --listener tables become altered in some handlers
            local tocall = {}
            for entity, fns in pairs(listeners) do
                for i, fn in ipairs(fns) do
                    table.insert(tocall, fn)
                end
            end
            local len = #tocall
            for i, fn in ipairs(tocall) do
                if not self:IsValid() then
                    -- if i < len then --如果不是最后一个事件就打印
                    --     print(KEY .. "对象在事件" .. event .. "时被移除，将禁止后续回调执行")
                    -- end
                    return
                end
                fn(self, data)
            end
        end
    end

    if self.sg and
        self:IsValid() and
        self.sg:IsListeningForEvent(event) and
        SGManager:OnPushEvent(self.sg) then
        self.sg:PushEvent(event, data)
    end

    if self.brain and self:IsValid() then
        self.brain:PushEvent(event, data)
    end
end

----------------------------------------------------------------------------------------------------
--针对一些粗心大意的mod
--对于忘记写STRINGS.NAMES.XXX的配方，在prefabs/blueprint.lua生成蓝图时会崩溃

local function CanBlueprintRandomRecipe(recipe)
    if recipe.nounlock or recipe.builder_tag ~= nil then
        --Exclude crafting station and character specific
        return false
    end
    local hastech = false
    for k, v in pairs(recipe.level) do
        if v >= 10 then
            --Exclude TECH.LOST
            return false
        elseif v > 0 then
            hastech = true
        end
    end
    --Exclude TECH.NONE
    return hastech
end

AddRecipePostInitAny(function(v)
    if (v.require_special_event == nil or IsSpecialEventActive(v.require_special_event))
        and CanBlueprintRandomRecipe(v)
    then
        --不要直接崩溃，要是别人的mod没写结果你的mod崩溃了，玩家还以为是你的mod的问题，不过也可能变量之后再赋值
        -- assert(STRINGS.NAMES[string.upper(recipe.name)], "配方" .. recipe.name .. "有自己的蓝图，STRINGS.NAMES." .. string.upper(recipe.name) .. "没定义")
        local uppername = string.upper(v.name)
        if not STRINGS.NAMES[uppername] then
            STRINGS.NAMES[uppername] = "STRINGS.NAMES." .. uppername .. "未赋值"
            print(KEY .. "STRINGS.NAMES." .. uppername .. "未赋值，生成蓝图时会报错")
        end
    end
end)

----------------------------------------------------------------------------------------------------

-- local old_DoTaskInTime = EntityScript.DoTaskInTime
-- function EntityScript:DoTaskInTime(...)
--     if self.IsValid and not self:IsValid() then --本来想着预防崩溃的，没想到还有mod能把IsValid都干掉
--         print(KEY, self, "对象在移除后仍然执行DoTaskInTime，这可能导致游戏崩溃")
--         return
--     end
--     return old_DoTaskInTime(self, ...)
-- end

-- local old_DoPeriodicTask = EntityScript.DoPeriodicTask
-- function EntityScript:DoPeriodicTask(...)
--     if self.IsValid and not self:IsValid() then
--         print(KEY, self, "对象在移除后仍然执行DoPeriodicTask，这可能导致游戏崩溃")
--         return
--     end
--     return old_DoPeriodicTask(self, ...)
-- end
