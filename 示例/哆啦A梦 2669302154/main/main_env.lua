--------------------------------
--[[ 环境]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-12]]
--[[ @updateTime: 2021-12-12]]
--[[ @email: x7430657@163.com]]
--------------------------------

--[[用以创建环境,且统一内部数据结构]]
local function newEnvironment(log_level)
    return {log_level = log_level}
end
--[[环境枚举]]
local ENVIRONMENT_ENUM = {
    PRO = newEnvironment("Warn"),
    TEST = newEnvironment("Debug"),
}
-- 当前环境
Environment = {}

function Environment:SetPro()
    setmetatable(self,{
        __index =ENVIRONMENT_ENUM["PRO"],
    })
end

function Environment:SetTest()
    setmetatable(self,{
        __index =ENVIRONMENT_ENUM["TEST"],
    })
end
function Environment:IsPro()
    local table = getmetatable(self)
    return table.__index == ENVIRONMENT_ENUM["PRO"]
end
function Environment:IsTest()
    local table = getmetatable(self)
    return table.__index == ENVIRONMENT_ENUM["TEST"]
end