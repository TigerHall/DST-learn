-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 从 table 中随机选取指定数量的不重复元素
    local function getRandomElements(t, num)
        local keys = {}

        -- 收集所有数字类型的键
        for k in pairs(t) do
            if type(k) == "number" then
                table.insert(keys, k)
            end
        end

        -- 如果没有数字键，返回空表
        if #keys == 0 then
            return {}
        end

        -- 洗牌算法随机打乱键顺序
        for i = #keys, 2, -1 do
            local j = math.random(i)
            keys[i], keys[j] = keys[j], keys[i]
        end

        -- 计算实际应返回的元素数量
        local count = math.min(num, #keys)

        -- 构造结果表
        local result = {}
        for i = 1, count do
            result[i] = t[keys[i]]
        end

        return result
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    function TBAT.FNS:GetRandomDiffrenceValuesFromTable(t, num)
        return getRandomElements(t, num)
    end
