--------------------------------
--[[ ComponentUtil: 组件工具方法]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-03]]
--[[ @updateTime: 2022-01-03]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Upvalue = require("util/upvalue")
require("util/logger")
local ComponentUtil = {}

function ComponentUtil:IsUpdating(inst,component)
    Logger:Debug({"组件util：获取组件是否更新",inst,component},1)
    if inst and inst:IsValid()
        and type(component) == "string"
        and inst.components[component] ~= nil
    then
        if inst.updatecomponents == nil then -- 该实例一次没有更新过组件
            return false
        end
        -- 该组件存在更新该组件
        local isUpdating = inst.updatecomponents[component] ~= nil and true or false
        -- 是否在停止更新列表中
        if isUpdating then
            local StopUpdatingComponents = Upvalue:Get(inst.StartUpdatingComponent,"StopUpdatingComponents")
            Logger:Debug({"组件util：StopUpdatingComponents",StopUpdatingComponents},1)
            if  StopUpdatingComponents ~= nil  then
                return StopUpdatingComponents[component] ~= nil and true or false
            else
                return true
            end
        end
    end
    return false
end

return ComponentUtil