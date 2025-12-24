--------------------------------
--[[ Table: table扩展方法 ]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-20]]
--[[ @updateTime: 2022-02-14]]
--[[ @email: x7430657@163.com]]
--------------------------------

local Table = {}
-------------------------------------------------------------------------------
--[[判断t中是否包含该value]]
--[[该方法科雷已扩展:table.contains(t,value)]]
--[[@param t: table对象]]
--[[@param value: 值]]
--[[@return true/false]]
-------------------------------------------------------------------------------
function Table:HasValue(t,value)
    if type(t) == "table" then
        for _,v in pairs(t) do
            if v == value then
                return true
            end
        end
    end
    return false
end

-------------------------------------------------------------------------------
--[[从t中删除key]]
--[[@param t: table对象]]
--[[@param value: 值]]
--[[@return ]]
-------------------------------------------------------------------------------
function Table:RemoveKey(t,key)
    if type(t) == "table" then
        for k,v in pairs(t) do
            if k == key  then
                t[k] = nil
                --if type(k) == "number" then
                --    table.remove(t,k)
                --else
                --    t[k] = nil
                --end
            end
        end
    end
end

-------------------------------------------------------------------------------
--[[从t中删除value]]
--[[@param t: table对象]]
--[[@param value: 值]]
--[[@return ]]
-------------------------------------------------------------------------------
function Table:RemoveValue(t,value)
    if type(t) == "table" then
        --local backCount = 0
        for k,v in pairs(t) do
            if v == value  then
                -- 如果索引是number会有问题,统一采用 这个方式删除
                -- 这样删除不会改变索引
                t[k] = nil
                --if type(k) == "number" then
                --    -- 删除后,索引会往前一步
                --    table.remove(t,k -backCount)
                --    --backCount = backCount +1
                --else
                --    t[k] = nil
                --end
            end
        end
    end
end

-------------------------------------------------------------------------------
--[[获取table中key对应的value]]
--[[@param t: table对象]]
--[[@param key: 索引]]
--[[@return key对应的value]]
-------------------------------------------------------------------------------
function Table:Get(t,key)
    if type(t) == "table" and key ~= nil then
        for k,v in pairs(t) do
            if k == key then
                return v
            end
        end
    end
    return nil
end
-------------------------------------------------------------------------------
--[[获取table中value对应的key,返回第一个匹配到的key]]
--[[@param t: table对象]]
--[[@param key: 索引]]
--[[@return key对应的value]]
-------------------------------------------------------------------------------
function Table:GetKey(t,value)
    if type(t) == "table" then
        for k,v in pairs(t) do
            if v == value then
                return k
            end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
--[[获取table的长度,由于#或者table.getn都会在索引中断时停止计数,所以只能遍历获取]]
--[[@param t: table对象]]
--[[@return table长度]]
-------------------------------------------------------------------------------
function Table:Size(t)
    local len = 0
    if type(t) == "table" then
        for _,v in pairs(t) do
            len=len+1
        end
    end
    return len;
end
-------------------------------------------------------------------------------
--[[判断table是否为空]]
--[[@param t: table对象]]
--[[@return true/false]]
-------------------------------------------------------------------------------
function Table:IsEmpty(t)
    if type(t) == "table" then
        for _,v in pairs(t) do -- 存在超过1个说明不为空
            return false
        end
    end
    return true;
end
-------------------------------------------------------------------------------
--[[将string转换成table]]
--[[@param str: 字符串]]
--[[@return table]]
-------------------------------------------------------------------------------
function Table:ToTable(str)
    if str == nil or type(str) ~= "string" then
        return nil
    end
    if loadstring then -- lua 5.1
        return loadstring("return " .. str)()
    elseif load then -- lua 5.2
        return load("return " .. str)()
    else
        return nil
    end
end

-------------------------------------------------------------------------------
--[[将table转换成string]]
--[[@param t: 字符串]]
--[[@return table]]
-------------------------------------------------------------------------------
local function ToStringEx(util,value)
    if type(value)=='table' then
        return util:ToString(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
        return tostring(value)
    end
end
function Table:ToString(t)
    if t == nil or type(t) ~= "table" then
        return "" -- 空字符串
    end
    local retstr= "{"
    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
            signal = ""
        end
        if key == i then
            retstr = retstr..signal..ToStringEx(self,value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(self,key).."]="..ToStringEx(self,value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..self:ToString(getmetatable(key)).."*e".."="..ToStringEx(self,value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(self,value)
                end
            end
        end
        i = i+1
    end
    retstr = retstr.."}"
    return retstr
end

return Table