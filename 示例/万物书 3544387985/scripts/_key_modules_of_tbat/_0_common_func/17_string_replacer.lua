--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    输入 str , target_str , replaced_str 。  在str这串文本里，找到 target_str ，然后替换成 replaced_str


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function replace_string(str, target_str, replaced_str)
    if target_str == "" then
        return str
    end
    local escaped = string.gsub(target_str, "([%-%.%$%(%)%*%+%?%[]])", "%%%1")
    return string.gsub(str, escaped, replaced_str)
end

function TBAT.FNS:ReplaceString(str, target_str, replaced_str)
    return replace_string(str, target_str, replaced_str)
end