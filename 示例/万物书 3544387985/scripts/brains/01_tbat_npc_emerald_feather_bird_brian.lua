
require "behaviours/faceentity"
require "behaviours/wander"
require "behaviours/approach"
require "behaviours/leash"


local CarnivalHostBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local MAX_WANDER_DIST = 15

local function GetHomePos(inst)
    return inst.components.knownlocations:GetLocation("home")
end

local function GetWanderLines(inst)
    -- return "欢迎来到游乐园！" -- 替换为你的实际对话内容
    local call_back = {}
	inst:PushEvent("get_random_wander_talk",call_back)
	return call_back[1] or "欢迎来到幻想岛！"
end

function CarnivalHostBrain:OnStart()
    -- 简化后的行为树
    local root = PriorityNode({
        ChattyNode(
            self.inst,
            GetWanderLines,
            Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
            5, 6 -- 说话间隔时间（最小 5 秒，最大 6 秒）
        ),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return CarnivalHostBrain