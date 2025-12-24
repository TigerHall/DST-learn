--------------------------------
--[[ Logger: 用于打印日志 ]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-04]]
--[[ @updateTime: 2021-12-24]]
--[[ @email: x7430657@163.com]]
--------------------------------
-- 使用(暂未实现多个模块同时引用下的使用)
-- 1.在modmain中require(<logger模块>)
-- 2.在modmain中调用Logger:Init(modname,level)
-- 3.然后就可以使用Logger:Debug(...)或
--   其它几种打印方法
--------------------------------
local Table = require("util/table")
--local Table = require("02/scripts/util/table") --该行我只是用于本地测试用到

--[[日志等级,外部调用时,直接使用"Debug"字符串即可,大小写均无所谓]]
local LOG_LEVELS = {-- 日志等级
    ERROR = 1, -- 只打印Error信息
    WARN = 2,  -- 打印Warn及Error信息
    INFO = 3,  -- 打印Info及Warn等信息
    DEBUG = 4, -- 打印Debug及Info等信息
}

--[[最重要的logger对象,默认打印等级:INFO]]
Logger = {
    level = LOG_LEVELS.INFO, -- 默认: INFO
    modname = "", -- mod名称
    -- Meta information
    _COPYRIGHT = "Copyright (C) 2021-2021 谅直",
    _DESCRIPTION = "日志打印模块",
    _VERSION = "1.0.0",
}

----------------------------------------------------
--[[ 设置日志等级]]
--[[ @param level: 可以是LOG_LEVELS中的字符串key]]
--[[               或对应数值]]
----------------------------------------------------
function Logger:Init(modname,level)
    if type(modname) == "string" then
        self.modname = "  ["..modname.."]" --前面增加两个空格与时间隔开
    end
    if type(level) == "number" then -- 数值
        self.level = level
        if self.level < LOG_LEVELS.ERROR then
            self.level = LOG_LEVELS.ERROR
        end
        if self.level > LOG_LEVELS.DEBUG then
            self.level = LOG_LEVELS.DEBUG
        end
    else
        if level and LOG_LEVELS[string.upper(level)] ~= nil then
            self.level = LOG_LEVELS[string.upper(level)]
        end
    end
end
--[[复制自饥荒源码stacktrace.lua]]
local function getFilterSource(src)
    if not src then return "[?]" end
    if src:sub(1, 1) == "@" then
        src = src:sub(2)
    end
    return src
end
--[[复制自饥荒源码stacktrace.lua]]
local function saveToString(v)
    local status, retval = xpcall(function() return tostring(v) end, function() return "*** failed to evaluate ***" end)
    local maxlen = 1024
    if retval:len() > maxlen then
        retval = retval:sub(1,maxlen).." [**truncated**]"
    end
    return retval
end
--[[复制自饥荒源码stacktrace.lua]]
local function getFormatInfo(info)
    if not info then return "**error**" end
    local source = getFilterSource(info.source)
    if info.currentline then
        source = source..":"..info.currentline
    end
    return ("@%s in (%s) %s (%s) <%d-%d>"):format(source, info.namewhat, info.name or "?", info.what, info.linedefined, info.lastlinedefined)
end
--[[复制自饥荒源码stacktrace.lua]]
local function getDebugLocals (res, level)
    local t = {}
    local index = 1
    while true do
        local name, value = debug.getlocal(level + 1, index)
        if not name then
            break
        end
        -- skip compiler generated variables
        if name:sub(1, 1) ~= "(" then
            if name == "self" and type(value)=="table" then
                if value.IsValid and type(value.IsValid) == "function" then
                    res[#res+1] = string.format("   self (valid:"..tostring(value:IsValid())..") =")
                else
                    res[#res+1] = string.format("   self =")
                end
                for i,v in pairs(value) do
                    if type(v) == "function" then
                        -- if it's a function show where we defined it
                        local info = debug.getinfo(v,"LnS")
                        res[#res+1]=string.format("      %s = function - %s", i, info.source..":"..tostring(info.linedefined))
                    else
                        if v and type(v)=="table" and v.IsValid and type (v.IsValid) == "function" then
                            res[#res+1] = string.format("      %s = %s (valid:%s)", i, saveToString(v),tostring(v:IsValid()))
                        else
                            res[#res+1] = string.format("      %s = %s", i, saveToString(v))
                        end
                    end
                end
            else
                if type(value) == "function" then
                    local info = debug.getinfo(value,"LnS")
                    res[#res+1]=string.format("   %s = function - %s", name, info.source..":"..tostring(info.linedefined))
                else
                    if value and type(value) == "table" and value.IsValid and type(value.IsValid) == "function" then
                        res[#res+1] = string.format("   %s = %s (valid:%s)", name, saveToString(value),tostring(value:IsValid()))
                    else
                        res[#res+1] = string.format("   %s = %s", name, saveToString(value))
                    end
                end
            end
        end
        index = index + 1
    end
    local res = table.concat(t, "\n")
    return res
end
--[[复制自饥荒源码stacktrace.lua]]
local function getDebugStack(res, start, top, bottom,trace_params)
    -- disable strict. We may hit G -- 此处我做了修改,原版这里重置了_G,
                                    -- 这里我防止数据混乱(影响其它mod),注释了这行
    --setmetatable(_G,{})
    if not bottom then bottom = 10 end
    if not top then top = 12 end
    start = (start or 1) + 1
    local count = start
    local info  = debug.getinfo(count)
    while info and info.linedefined >= 0  do
        count = count + 1
        info =  debug.getinfo(count+1)
    end
    count = count - start
    if top + bottom >= count then
        top = count
        bottom = nil
    end
    for i = 1, top, 1 do
        local s = getFormatInfo(debug.getinfo(start + i - 1))
        res[#res+1] = s
        if trace_params then
            getDebugLocals(res, start + i - 1)
        end
    end
    return res
end
--[[复制自饥荒源码stacktrace.lua]]
local function doLoggerStackTrace(title,trace_params)
    local res = {title}
    res = getDebugStack(res,4,nil,nil,trace_params)
    local retval = table.concat(res, "\n")
    return retval
end




---------------------------------------
--[[获取日志前缀]]
--[[@param suffix: 前缀中结尾部分]]
--[[@return prefix: 日志的前缀]]
---------------------------------------
local function getLogPrefix(logger,suffix)
    local date = os.date("%Y-%m-%d %H:%M:%S");
    local name =  logger.modname
    local currentEnv = "  UNKNOWN  ";
    if TheWorld then
        currentEnv = TheWorld.ismastersim and "  SERVER  " or "  CLIENT  "
    end
    local info = debug.getinfo(3)
    local prefix =   date..name..currentEnv..info.source..":"..tostring(info.currentline).."  "..string.upper(suffix)
    return prefix
end







local newline = "\n" -- 换行符号(回到行首),主要在获取完整打印语句中用到

----------------------------------------------------
--[[获取完整的打印语句,要注意的是如果table过大,会导致信息不全或者直接提示堆栈溢出]]
--[[@param prefix: string,前缀]]
--[[@param rootTable: table,要打印的表(可变参数)]]
--[[@param dataStartPos: 开始打印位置]]
--[[@param dataEndPos: 打印结束位置]]
--[[@param level: table的递归层次,table本身level为0,table其下属性level为1,以此类推]]
--[[@return 最终的打印字符串]]
----------------------------------------------------
local function getPrintString ( prefix,rootTable ,dataStartPos,dataEndPos,level)
    local print_r_cache={} --记录是否打印过该对象,避免重复打印
    local print_out={} -- 输出打印语句的table
    local function sub_print_r(t,indent,startPos,endPos,level)
        if print_r_cache[tostring(t)] then--之前已打印过
            --print(indent.."*"..tostring(t))
            table.insert(print_out,indent)
            table.insert(print_out,"*")
            table.insert(print_out,tostring(t))
            table.insert(print_out,newline)
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") and not Table:IsEmpty(t)
                and ( level == nil or level > 0)
            then
                local index = 0; -- 索引
                for pos,val in pairs(t) do
                    index = index +1
                    if  (startPos == nil or endPos == nil)
                            or (index >= startPos and index <= endPos)
                    then
                        if (type(val)=="table") then
                            table.insert(print_out,indent)
                            table.insert(print_out,"[")
                            table.insert(print_out,tostring(index)..":")
                            table.insert(print_out,tostring(pos))
                            table.insert(print_out,"] => ")
                            table.insert(print_out,tostring(val))
                            table.insert(print_out," len:"..tostring(Table:Size(val)))
                            table.insert(print_out," {")
                            table.insert(print_out,newline)
                            sub_print_r(val,indent..string.rep(" ",string.len(index)+8),nil,nil,level ~= nil and level-1 or nil)
                            table.insert(print_out,indent)
                            --table.insert(print_out,string.rep(" ",string.len(index)+6))
                            table.insert(print_out,"}")
                            table.insert(print_out,newline)
                        elseif (type(val)=="string") then
                            table.insert(print_out,indent)
                            table.insert(print_out,"[")
                            table.insert(print_out,tostring(index)..":")
                            table.insert(print_out,tostring(pos))
                            table.insert(print_out,'] => "')
                            table.insert(print_out,val)
                            table.insert(print_out,'"')
                            table.insert(print_out,newline)
                        else
                            table.insert(print_out,indent)
                            table.insert(print_out,"[")
                            table.insert(print_out,tostring(index)..":")
                            table.insert(print_out,tostring(pos))
                            table.insert(print_out,"] => ")
                            table.insert(print_out,tostring(val))
                            table.insert(print_out,newline)
                        end
                    end
                end
            elseif ( level == nil or level > 0) then
                table.insert(print_out,indent)
                table.insert(print_out,tostring(t))
                table.insert(print_out,newline)
            end
        end
    end
    table.insert(print_out,prefix ~= nil and prefix or "")
    if (type(rootTable)=="table") then
        table.insert(print_out,tostring(rootTable))
        table.insert(print_out," len:"..tostring(Table:Size(rootTable)))
        table.insert(print_out," {")
        table.insert(print_out,newline)
        sub_print_r(rootTable,"  ",dataStartPos,dataEndPos,level)
        table.insert(print_out,"}")
        table.insert(print_out,newline)
    else
        if rootTable == nil then
            rootTable = "未打印任何信息"
        end
        sub_print_r(rootTable,"  ",dataStartPos,dataEndPos)
    end
    --print_out最后一个字段必是换行符号,但结尾时不需要,下一次print自动会换行
    local print_str = table.concat(print_out,"",1,#print_out -1)
    return print_str;
end



-------------------------------------------------
--[[打印方法,输出相关信息]]
--[[@param prefix: string , 前缀]]
--[[@param 其它同Logger:Debug方法]]
-------------------------------------------------
local function print_r(prefix,data,dataStartPos,dataEndPos,level,traceback,trace_params)
    local out_str = getPrintString(prefix,data,dataStartPos,dataEndPos,level)
    print(out_str)
    if traceback then
        local title = "#LOGGER Stack Traceback:"
        local trace  = doLoggerStackTrace(title,trace_params)
        print(trace)
    end
end

-------------------------------------
--[[打印Debug信息]]
--[[可以灵活使用data的坐标,!!!特别data数据过长时容易栈溢出或导致打印信息缺斤少两]]
--[[@param data: 任意类型]]
--[[@param level: data要递归的层次,可为空,默认无限递归.data本身level为0,data的属性level为1,以此类推]]
--[[@param dataStartPos: data开始坐标,可为空,默认1]]
--[[@param dataEndPos: data结束坐标,可为空,默认data的长度]]
--[[@param traceback: 函数调用信息]]
--[[@param trace_params: 是否打印函数内局部变量参数]]
--[[                     !!!!该参数请谨慎使用,会遍历栈中所有信息]]
-------------------------------------
function Logger:Debug(data,level,dataStartPos,dataEndPos,traceback,trace_params)
    if self.level >= LOG_LEVELS.DEBUG then
        local prefix = getLogPrefix(self,"DEBUG: ");
        print_r(prefix,data,dataStartPos,dataEndPos,level,traceback,trace_params)
    end
end

-------------------------------------
--[[打印Info信息]]
--[[@param 同Logger:Debug方法]]
-------------------------------------
function Logger:Info(data,level,dataStartPos,dataEndPos,traceback,trace_params)
    if self.level >= LOG_LEVELS.INFO then
        local prefix = getLogPrefix(self,"INFO: ");
        print_r(prefix,data,dataStartPos,dataEndPos,level,traceback,trace_params)
    end
end
-------------------------------------
--[[打印Warn信息]]
--[[@param 同Logger:Debug方法]]
-------------------------------------
function Logger:Warn(data,level,dataStartPos,dataEndPos,traceback,trace_params)
    if self.level >= LOG_LEVELS.WARN then
        local prefix = getLogPrefix(self,"WARN: ");
        print_r(prefix,data,dataStartPos,dataEndPos,level,traceback,trace_params)
    end
end
-------------------------------------
--[[打印Error信息]]
--[[@param 同Logger:Debug方法]]
-------------------------------------
function Logger:Error(data,level,dataStartPos,dataEndPos,traceback,trace_params)
    if self.level >= LOG_LEVELS.ERROR then
        local prefix = getLogPrefix(self,"ERROR: ");
        print_r(prefix,data,dataStartPos,dataEndPos,level,traceback,trace_params)
    end
end

return Logger