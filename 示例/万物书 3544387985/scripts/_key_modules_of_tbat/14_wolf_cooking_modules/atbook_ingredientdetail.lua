--------------------------------------------------------------------------
--[[ Tool ]]--[[ 工具 ]]
--------------------------------------------------------------------------
require("util")
local cooking = require "cooking"

local function GetMixTags()
	local diary_mixtags = {}
    local mixtags_name = {}
    for name, ingdata in pairs(cooking.ingredients) do
        local class_name = ""
        local cnt_tag = 0
        for tagname, tagval in pairs(ingdata.tags) do
            if tagname ~= "precook" and tagname ~= "dried" then
                class_name = class_name..tagname..(tagval*4)  --生成class_name备用
                cnt_tag = cnt_tag + 1
            end
        end
        class_name = cnt_tag .. class_name
        --mixname的形式为"1meat1"(对应meat)、"2meat1monster1"(对应monstermeat)
        --第1个数字为tag数量，后面为tagname和tagval
        local contain = false  --是否存在该name对应的class_name的标记
        for mixname, _ in pairs(mixtags_name) do
            --先判断第一个数字匹配上
            if cnt_tag == tonumber(string.match(mixname, "%d+")) then
                --再判断剩下的tagname和tagval
                local hit = true
                for tname, tamt in string.gmatch(mixname, '([%a_]+)(%d+)') do
                    if ingdata.tags[tname] == nil or ingdata.tags[tname] ~= tonumber(tamt)*0.25 then
                        hit = false
                        break
                    end
                end
                --完全匹配，则name属于该mixname
                if hit == true then
                    contain = true
                    table.insert(mixtags_name[mixname], name)
                    -- mixtags_name[mixname][name]=1
                    break
                end
            end
        end
        if not contain then
            mixtags_name[class_name] = {name}
            -- mixtags_name[class_name][name]=1
        end
    end

    for mixnames, mixt in pairs(mixtags_name) do
        for _, ingname in ipairs(mixt) do
            diary_mixtags[ingname] = mixnames
        end
    end
    return diary_mixtags
end

return {GetMixTags=GetMixTags}