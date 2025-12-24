local GIFT_LIST = {
    ["hutao"] = {
        password = "sakura最可爱",
        gifts = {
            ["jellybean"] = 1,
            ["torch"] = 1,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["suming"] = {
        password = "素冥老仙，法力无边",
        gifts = {
            ["redgem"] = 3,
            ["bluegem"] = 3,
            ["greengem"] = 3,
            ["yellowgem"] = 3,
            ["purplegem"] = 3,
            ["orangegem"] = 3,
            ["opalpreciousgem"] = 3,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["beixiang"] = {
        password = "我要粉悲象一辈子",
        gifts = {
            ["honor_armor"] = 1,
            ["lantern"] = 1,
            ["poop"] = 100,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["nuonuo"] = {
        password = "诺诺助我一臂之力",
        gifts = {
            ["meatballs"] = 5,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["huolongguopai"] = {
        password = "火龙果湃真棒啊",
        gifts = {
            ["dragonfruit"] = 1,
            ["twigs"] = 3,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["shijiu"] = {
        password = "拾玖真是帅啊",
        gifts = {
            ["poop"] = 100,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["lengyue"] = {
        password = "冷月姐姐威武",
        gifts = {
            ["ft_e_repair"] = 2,
            ["ft_e_anvil"] = 2,
            ["ft_b_level"] = 4,
            ["aupgradelevel"] = 1,
            ["aupgradelevel0"] = 1,
            ["gupgradelevel1"] = 3,
            ["honor_backpack"] = 1,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["qingjiao"] = {
        password = "青椒没有PC被抓",
        gifts = {
            ["amulet"] = 1,
        },
        gift_override = function(player)
            if player and player:HasTag("playerghost") then
                player:PushEvent("respawnfromghost", {source = player})
            end
        end,
        start_date = "2025-11-22",
        duration = 30,
    },
    ["heima"] = {
        password = "黑马哥哥带你玩饥荒",
        gifts = {
            ["honor_backpack"] = 1,
            ["cane"] = 1,
        },
        start_date = "2025-11-22",
        duration = 30,
    },
    ["zhaosir"] = {
        password = "赵sir",
        gifts = {
            ["cane"] = 1,
        },
        start_date = "2025-11-22",
        duration = 30,
    }
}

local Gift = {
    gift_list = GIFT_LIST,
    recived_gifts = HMR_UTIL.DecodeData(HMR_UTIL.GetPersistentString("HMR_GIFT_RECEIVED_DATA")) or {},
}

local function IsInSpecifiedPeriod(start_date_str, duration_days, current_date_str)
    -- 1. 默认当前日期（用户指定的 "2025-11-22"）
    current_date_str = current_date_str or "2025-11-22"

    -- 2. 日期解析辅助函数：将 "YYYY-MM-DD" 转为时间戳（Lua 5.1 兼容）
    local function dateToTimestamp(date_str)
        -- 提取年、月、日（严格匹配格式）
        local year, month, day = string.match(date_str, "^(%d%d%d%d)-(%d%d)-(%d%d)$")
        if not year or not month or not day then
            print("[错误] 日期格式错误，需为 YYYY-MM-DD（如 2025-11-22）")
            return nil
        end
        -- 转换为数字并构造 os.time 所需的 table（Lua 日期table：month 1-12，day 1-31）
        local date_table = {
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = 0, -- 固定为 0 点（避免时间部分干扰日期判断）
            min = 0,
            sec = 0
        }
        -- 转换为时间戳（秒数）
        return os.time(date_table)
    end

    -- 3. 转换所有日期为时间戳
    local start_ts = dateToTimestamp(start_date_str)
    local current_ts = dateToTimestamp(current_date_str)
    local duration_sec = duration_days * 86400 -- 天数转秒数（1天=86400秒）

    -- 4. 校验参数有效性
    if not start_ts or not current_ts or duration_days <= 0 then
        return false
    end

    -- 5. 计算结束时间戳（起始时间 + 持续天数，左闭右开区间）
    local end_ts = start_ts + duration_sec

    -- 6. 判断当前时间是否在 [start_ts, end_ts) 内
    return current_ts >= start_ts and current_ts < end_ts
end

function Gift:IsValidDate(id)
    local gift_data = self.gift_list[id]
    if gift_data ~= nil then
        local start_date = gift_data.start_date
        local duration = gift_data.duration
        if start_date ~= nil and duration ~= nil then
            if IsInSpecifiedPeriod(start_date, duration, nil) then
                return true
            end
        else
            return true
        end
    end
    return false
end

function Gift:GetGiftList()
    return self.gift_list
end

function Gift:IsValidGiftPassword(password)
    for _, v in pairs(self.gift_list) do
        if v.password == password then
            return true
        end
    end
    return false
end

function Gift:GetIdByPassword(password)
    for k, v in pairs(self.gift_list) do
        if v.password == password then
            return k
        end
    end
    return nil
end

function Gift:GetGiftDataById(id)
    return self.gift_list[id]
end

function Gift:GenerateGifList(id)
    local gifts = self.gift_list[id] and self.gift_list[id].gifts
    if gifts ~= nil then
        local items = {}
        for k, v in pairs(gifts) do
            for i = 1, v do
                if PrefabExists(k) then
                    table.insert(items, k)
                end
            end
        end
        return items
    end
    return {}
end

function Gift:ReciveGift(player, id)
    if self.recived_gifts[player.userid] == nil then
        self.recived_gifts[player.userid] = {}
    end
    self.recived_gifts[player.userid][id] = true
    HMR_UTIL.SetPersistentString("HMR_GIFT_RECEIVED", HMR_UTIL.EncodeData(self.recived_gifts))
end

function Gift:CanReciveGift(player, id)
    if not self:IsValidDate(id) then
        return false
    end
    if self.recived_gifts == nil then
        self.recived_gifts = HMR_UTIL.GetPersistentString("HMR_GIFT_RECEIVED")
    end
    return self.recived_gifts[player.userid] == nil or self.recived_gifts[player.userid][id] ~= true
end

function Gift:GiveGift(player, id)
    if self:CanReciveGift(player, id) then
        local gift_data = Gift:GetGiftDataById(id)
        if gift_data ~= nil then
            local success = false
            if gift_data.gift_override ~= nil then
                success = gift_data.gift_override(player) or false
            end

            if not success then
                local gift_list = Gift:GenerateGifList(id)
                if #gift_list > 0 then
                    local gift = SpawnPrefab("gift")
                    gift.components.unwrappable:WrapItems(gift_list, player)
                    HMR_UTIL.DropLoot(player, gift)
                    success = true
                end
            end

            if success then
                Gift:ReciveGift(player, id)
            end
        end
    end
end

AddModRPCHandler("HMR", "GIVE_GIFT", function(player, id)
    Gift:GiveGift(player, id)
end)

return Gift