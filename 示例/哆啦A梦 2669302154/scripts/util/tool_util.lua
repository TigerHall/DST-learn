--------------------------------
--[[ ToolUtil: 杂七杂八的工具]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-15]]
--[[ @updateTime: 2022-01-15]]
--[[ @email: x7430657@163.com]]
--------------------------------
--[[通过函数创建某个对象]]
function New(fn)
    local inst = nil
    if type(fn) == "function" then
        inst = fn()
    end
    return inst
end