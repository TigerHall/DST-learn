--------------------------------
--[[ Upvalue: 用于获取upvalue ]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-15]]
--[[ @updateTime: 2021-12-24]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Upvalue = {}
-- 默认的最大查询变量数和最大递归层数限制
local maxDefault = 100
local maxLevelDefault = 5


--[[ 获取upvalue variable的值,注意该方法会递归查询]]
--[[ 优先返回当前递归中当前层中符合要求的变量]]
--[[ 注意递归是按照upvalue顺序进行查找的,且每个递归中最大变量数是单独计算的]]
--[[ 抄自神话myth_upvaluehelper.lua,该函数又由风铃草大佬提供]]
--[[ 感谢以上大佬们]]
--[[ @param fn : 要查询的函数.必选]]
--[[ @param variable : 要查询upvalue变量名称，字符串.必选]]
--[[ @param max : 每个递归中最多查询变量个数.默认100个.可选]]
--[[ @param maxLevel : 最多递归层次.可选]]
--[[ @param file : 限定文件,防止取错.可选]]
--[[               mod文件demo: ../mods/doraemon_tech/scripts/util/table.lua]]
--[[               源码文件demo: scripts/prefabs/spiderden.lua]]
--[[ @param level : 请勿传该参数,该参数用于函数内使用]]
--[[ @return variable对应的值]]
function Upvalue:Get(fn,variable,max,maxLevel,file,level)
    if type(fn) ~= "function" or type(variable) ~= "string" then
        return nil
    end
    max = max or maxDefault -- 查询变量的个数
    maxLevel = maxLevel or maxLevelDefault
    level = level or 0
    local upname,upvalue,fninfo
    local nextRecursion -- 递归,需要进行递归的upvalue先存到此处
    for i = 1,max,1 do -- 遍历,有钱返回当前层次的符合变量
        --[[debug.getupvalue (f, up)
              --此函数返回函数 f 的第 up 个上值的名字和值。 如果该函数没有那个上值，返回 nil 。
              --以 '(' （开括号）打头的变量名表示没有名字的变量 （去除了调试信息的代码块）。
        ]]
        upname,upvalue = debug.getupvalue(fn,i)
        if upname == nil then -- 不存在说明upname已经到头了,节约时间直接跳出循环
            break
        end
        if upname == variable then
            if file and type(file) == "string" then	--限定文件 防止取错,取到其它文件
                fninfo = debug.getinfo(fn)
                if fninfo.source and   fninfo.source == file then
                    return upvalue
                end
            else
                return upvalue
            end
        end
        if level < maxLevel and upvalue and type(upvalue) == "function" then
            if nextRecursion == nil then
                nextRecursion = {}
            end
            table.insert(nextRecursion,upvalue)
        end
    end
    if nextRecursion and  #nextRecursion > 0 then
        for _,v in pairs(nextRecursion) do
            upvalue  = self:Get(v ,variable ,max,maxLevel,file,level+1) --找不到就递归查找
            if upvalue then return upvalue end
        end
    end
    return nil
end
--[[ 设置upvalue中名称为variable的值,注意该方法会递归查询]]
--[[ 优先设置当前递归中当前层中符合要求的变量]]
--[[ 注意递归是按照upvalue顺序进行查找的,且每个递归中最大变量数是单独计算的]]
--[[ 抄自神话myth_upvaluehelper.lua,该函数又由风铃草大佬提供]]
--[[ 感谢以上大佬们]]
--[[ @param fn : 要查询的函数.必选]]
--[[ @param variable : 要查询upvalue变量名称，字符串.必选]]
--[[ @param max : 每个递归中最多查询变量个数.默认100个.可选]]
--[[ @param maxLevel : 最多递归层次.可选]]
--[[ @param file : 限定文件,防止取错.可选]]
--[[               mod文件demo: ../mods/doraemon_tech/scripts/util/table.lua]]
--[[               源码文件demo: scripts/prefabs/spiderden.lua]]
--[[ @param level : 请勿传该参数,该参数用于函数内使用]]
--[[ @return 成功返回variable,否则nil]]
function Upvalue:Set(fn,variable,value,max,maxLevel,file,level)
    if type(fn) ~= "function" or type(variable) ~= "string" then
        return nil
    end
    max = max or maxDefault -- 查询变量的个数
    maxLevel = maxLevel or maxLevelDefault
    level = level or 0
    local upname,upvalue,fninfo
    local nextRecursion
    for i=1,max,1 do
        upname,upvalue = debug.getupvalue(fn,i)
        if upname == nil then -- 不存在说明upname已经到头了,节约时间直接跳出循环
            break
        end
        if upname == variable then
            if file and type(file) == "string" then--限定文件
                fninfo = debug.getinfo(fn)
                if fninfo.source and  fninfo.source == file then
                    return debug.setupvalue(fn,i,value)
                end
            else
                return debug.setupvalue(fn,i,value)
            end
        end
        if level < maxLevel and upvalue and type(upvalue) == "function" then
            if nextRecursion == nil then
                nextRecursion = {}
            end
            table.insert(nextRecursion,upvalue)
        end
    end
    if nextRecursion and  #nextRecursion > 0 then
        for _,v in pairs(nextRecursion) do
            upvalue  = self:Set(v ,variable,value ,max,maxLevel,file,level+1)
            if upvalue then return upvalue end
        end
    end
    return nil
end

return Upvalue