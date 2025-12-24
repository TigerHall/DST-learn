-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
    压缩JSON数据
    通过密码表来替换压缩字符串。
    【注意】压缩和解压要同一个密码表。
    更新密码表使用 的示例：
            -- local data = TBAT.ClientSideData:PlayerGet("unlocked_skins") or {}
            -- -- print(json_compressor.generate_common_strings(data))
]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local json_compressor = {}
    -- 常用字符串列表，可通过generate_common_strings函数自动生成建议
    local common_strings = {	
        "tbat_",	
        "bat_",	
        "tbat",	
        "tbat_eq_",	
        "tbat_eq_universal_baton",	
        "tbat_building_",
    }	
    --------------------------------------------------
    -- 根据物品图标文件名、小地图图标文件名来压缩索引
        for i, str in ipairs(TBAT:GetAllInventoryImageFileNames()) do
            table.insert(common_strings, str)
        end
        for i, str in ipairs(TBAT:GetAllMapIconFileNames()) do
            table.insert(common_strings, str)
        end
    --------------------------------------------------
    -- 创建字符串到ID的映射
    local str_to_id = {}
    for i, str in ipairs(common_strings) do
        str_to_id[str] = i
    end

    -- 辅助函数：递归收集table中的所有字符串
    local function collect_strings(t, strings)
        strings = strings or {}
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "string" then
                    table.insert(strings, k)
                end
                collect_strings(v, strings)
            end
        elseif type(t) == "string" then
            table.insert(strings, t)
        end
        return strings
    end

    -- 新API：生成建议的常用字符串列表（基于完整字符串出现频率）
    function json_compressor.generate_common_strings(data, max_count)
        max_count = max_count or 20
        local all_strings = collect_strings(data)
        local string_count = {}
        
        -- 统计每个字符串的出现次数
        for _, str in ipairs(all_strings) do
            if #str >= 4 then  -- 只统计长度≥4的字符串（避免替换后变长）
                string_count[str] = (string_count[str] or 0) + 1
            end
        end

        -- 转换为数组并按出现次数排序
        local sorted = {}
        for str, count in pairs(string_count) do
            table.insert(sorted, {str = str, count = count})
        end
        table.sort(sorted, function(a, b) return a.count > b.count end)

        -- 提取前max_count个字符串
        local result = {}
        for i = 1, math.min(max_count, #sorted) do
            table.insert(result, sorted[i].str)
        end

        -- 打印结果
        print("建议的common_strings列表：")
        print("local common_strings = {")
        for _, str in ipairs(result) do
            print(string.format('    "%s",', str))
        end
        print("}")
        return result
    end

    -- 优化后的压缩函数
    function json_compressor.compress(str)
        -- 第一步：替换true/false（缩短操作）
        local temp = string.gsub(str, "true", "@")
        temp = string.gsub(temp, "false", "%%")  -- 用%%转义%符号

        -- 第二步：只替换长度大于替换标记的字符串（避免变长）
        local sorted_strings = {}
        for _, s in ipairs(common_strings) do
            table.insert(sorted_strings, s)
        end
        table.sort(sorted_strings, function(a, b) return #a > #b end)
        
        for _, s in ipairs(sorted_strings) do
            local id = str_to_id[s]
            local marker = "⌂" .. id .. "⌂"
            -- 仅当原字符串长度 > 替换标记长度时才替换
            if #s > #marker then
                temp = string.gsub(temp, s, marker)
            end
        end

        -- 第三步：处理JSON引号
        return string.gsub(temp, "\"", "¦")
    end

    -- 优化后的解压函数
    function json_compressor.decompress(str)
        -- 第一步：还原引号
        local temp = string.gsub(str, "¦", "\"")
        
        -- 第二步：还原常用字符串
        temp = string.gsub(temp, "⌂(%d+)⌂", function(id)
            local s = common_strings[tonumber(id)]
            return s and s or ("⌂" .. id .. "⌂")  -- 保留无法识别的标记
        end)
        
        -- 第三步：还原true/false
        return string.gsub(string.gsub(temp, "@", "true"), "%%", "false")
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 调试函数（保持不变）
function TBAT.FNS:ZipDebugUpdate(input_data)
    local data = input_data or TBAT.ClientSideData:PlayerGet("unlocked_skins") or {}
    print(json_compressor.generate_common_strings(data))
end

function TBAT.FNS:ZipPrintDictionary()
    for k, v in pairs(str_to_id) do
        print(k, v)
    end
end

function TBAT.FNS:ZipJsonStr(str)
    local origin_length = #str
    local new_str = json_compressor.compress(str)
    local new_length = #new_str
    -- if TBAT.DEBUGGING and origin_length > 0 and new_length > 0 then
    --     print("TBAT.FNS:ZipJsonStr origin", origin_length, "new", new_length, "compress", new_length / origin_length)
    --     print("++ origin", str)
    --     print("++    new", new_str)
    -- end
    return new_str
end

function TBAT.FNS:UnzipJsonStr(str)
    local unzip_str = json_compressor.decompress(str)
    -- if TBAT.DEBUGGING then
    --     print("TBAT.FNS:UnzipJsonStr :")
    --     print("-- origin  ", str)
    --     print("-- unzipped", unzip_str)
    -- end
    return unzip_str
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------