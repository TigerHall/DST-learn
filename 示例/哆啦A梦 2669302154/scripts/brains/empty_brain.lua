--------------------------------
--[[ SensoryMonitorBrain: 感觉监视器大脑 ,废弃]]
--[[ 原来是用来给sensory_monitor_body设置一个脑子，以解决一碰就开始滑的问题]]
--[[ 后续将该实体重量设置0，已解决]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-06]]
--[[ @updateTime: 2022-03-08]]
--[[ @email: x7430657@163.com]]
--------------------------------

require("util/logger")
local EmptyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function EmptyBrain:OnStart()
    local root = PriorityNode(
            nil, nil)
    self.bt = BT(self.inst, root)
end

return EmptyBrain