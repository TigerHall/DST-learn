require "behaviours/wander"
require "behaviours/runaway"
-- require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE
local GO_HOME_DIST = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE--离家距离
local SEE_DIST = 20--可视距离
local RUN_AWAY_DIST = 2--逃跑距离
local STOP_RUN_AWAY_DIST = 4--停止逃跑距离

--获取"老家"坐标
local function GetHomePos(inst)
    if inst.components.knownlocations then
        --优先以本源之树为家，否则就以出生点为家
        return inst.components.knownlocations:GetLocation("homepoint") or inst.components.knownlocations:GetLocation("spawnpoint")
    end
    return inst:GetPosition()
end
--执行回家动作
local function GoHomeAction(inst)
    if inst.components.combat.target ~= nil then
        return
    end
    local homePos = GetHomePos(inst)
    return homePos ~= nil
        and BufferedAction(inst, nil, ACTIONS.WALKTO, nil, homePos, nil, .2)
        or nil
end
--该回家了
local function ShouldGoHome(inst)
    local homePos = GetHomePos(inst)
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) > GO_HOME_DIST * GO_HOME_DIST
end

--是否可以开始化茧
local function canStartCocooning(inst)
    return not (inst.components.timer:TimerExists("wantstococoon") or inst.sg:HasStateTag("busy") or inst:IsOnOcean())
end
--开始化茧
local function startCocooning(inst)
    inst:PushEvent("cocoon") 
end

local MedalOriginGlowFlyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MedalOriginGlowFlyBrain:OnStart()
    local brain =
    {
		--受惊乱窜
        BrainCommon.PanicTrigger(self.inst),
        --化茧
        WhileNode( function() return canStartCocooning(self.inst) end, "do cocoon", 
            ActionNode(function() startCocooning(self.inst)  end)),
        --闪避
        WhileNode(function() return self.inst.components.combat.target ~= nil and self.inst.components.combat:InCooldown() end, "Dodge",
            RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),
        --回家
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, GoHomeAction, "Go Home", true )),
        --闲逛
        Wander(self.inst, GetHomePos, MAX_WANDER_DIST),
    }
    local root = PriorityNode(brain, .25)
    self.bt = BT(self.inst, root)
end

--初始化记录坐标
function MedalOriginGlowFlyBrain:OnInitializationComplete()
    --本源之树坐标点
    if TheWorld and TheWorld.medal_origin_tree ~= nil then
        self.inst.components.knownlocations:RememberLocation("homepoint", TheWorld.medal_origin_tree:GetPosition(), true)
    end
    --自己生成的坐标点
    local pos = self.inst:GetPosition()
    pos.y = 0
    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return MedalOriginGlowFlyBrain