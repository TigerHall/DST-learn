--------------------------------
--[[ 拿起物品的动作组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-10]]
--[[ @updateTime: 2021-12-10]]
--[[ @email: x7430657@163.com]]
--------------------------------

-- canuse demo
local function canuse(inst, doer, target, actions, right)
   return false
end

local function onuse(act)
    return false
end

local DoraemonClickUseItem = Class(function(self, inst)
    self.inst = inst
    self.type = nil
    --self._ischarged = net_bool(inst.GUID, "doraemon_click_useritem._ischarged")
    --self._ischarged:set_local(true)
    self.canuse = canuse -- 能否使用
    self.onuse = onuse -- 使用
    self.deststate = nil
end
)

function DoraemonClickUseItem:GetType()
    if self.type then
        return string.upper(self.type)
    end
    return self.type
end


return DoraemonClickUseItem