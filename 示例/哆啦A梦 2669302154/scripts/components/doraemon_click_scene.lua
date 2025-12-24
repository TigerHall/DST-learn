--------------------------------
--[[ 场景动作组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-11]]
--[[ @updateTime: 2021-12-11]]
--[[ @email: x7430657@163.com]]
--------------------------------

-- canuse demo
local function canuse(inst, doer, actions, right)
   return false
end

local function onuse(act)
    return false
end
local DoraemonClickScene = Class(function(self, inst)
    self.inst = inst
    self.type = nil
    self._ischarged = net_bool(inst.GUID, "doraemon_click_scene._ischarged")
    self._ischarged:set_local(true)
    self.canuse = canuse -- 能否使用
    self.onuse = onuse -- 使用
    self.deststate = nil
end
)
function DoraemonClickScene:GetType()
    if self.type then
        return string.upper(self.type)
    end
    return self.type
end

return DoraemonClickScene