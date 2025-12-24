

local function extract_tags(text)
    -- 匹配 "Tags:" 行的内容
    local tags_line = text:match("Tags:[^\n]*")
    if not tags_line then return {} end

    -- 去除 "Tags:" 和前导/中间空格
    local tags_str = tags_line:match("Tags:(.*)")

    local tags = {}
    for tag in tags_str:gmatch("%S+") do
        table.insert(tags, tag)
    end

    return tags
end

local function get(target)
        -----------------------------------------------------------------------------------------------------
        --- debug 文本
            local debugstring = target:GetDebugString()
        -----------------------------------------------------------------------------------------------------
        ---
            return extract_tags(debugstring)
        -----------------------------------------------------------------------------------------------------
end

function TBAT.FNS:GetAllTags(target)
    local all_tags = get(target) or {}
    local all_tags_idx = {}
    for i, tag in ipairs(all_tags) do
        all_tags_idx[tag] = i
    end
    return all_tags, all_tags_idx
end