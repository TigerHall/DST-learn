--------------------------------
--[[ SensoryMonitorBrain: 感觉监视器大脑]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-06]]
--[[ @updateTime: 2022-01-06]]
--[[ @email: x7430657@163.com]]
--------------------------------
require "behaviours/monitor"
require("util/logger")
local SensoryMonitorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function SensoryMonitorBrain:OnStart()
    Logger:Debug({"SensoryMonitorBrain:OnStart",self.inst},2)
    local root = PriorityNode(
            {
                Monitor(self.inst, 0, 15),
            }, .25)
    self.bt = BT(self.inst, root)
end

return SensoryMonitorBrain