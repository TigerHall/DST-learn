--------------------------------
--[[ StringUtil: 字符串工具方法]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-06]]
--[[ @updateTime: 2022-01-06]]
--[[ @email: x7430657@163.com]]
--------------------------------

local StringUtil = {}
--[[字符串不为空]]
--[[@return boolean]]
function StringUtil:IsNotBlank(str)
    return str ~= nil and string.len(str) > 0
end
--[[字符串为空]]
--[[@return boolean]]
function StringUtil:IsBlank(str)
    return str == nil or string.len(str) == 0
end

return StringUtil