require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/avoidlight"
require "behaviours/panic"
require "behaviours/attackwall"
require "behaviours/useshield"

--local BrainCommon = require "brains/braincommon"

local RETURN_HOME_DELAY_MIN = 15
local RETURN_HOME_DELAY_MAX = 25

local MAX_WANDER_DIST = 50
-- local MAX_CHASE_DIST = 20--追击距离(直接一个无限追击)
local MAX_CHASE_TIME = 20--追击时间

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 5


local DAMAGE_UNTIL_SHIELD = 100--每受到多少伤害遁地
local SHIELD_TIME = 3--遁地时间
local AVOID_PROJECTILE_ATTACKS = false--受到投掷伤害的时候是否立即土遁

local GO_HOME_DIST = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE*1.3--离家最远距离
local GO_HOME_RETURN_DIST = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE--到这个距离后停止

--获取"老家"坐标
local function GetHomePos(inst)
    if inst.components.knownlocations then
        --优先以本源之树为家，否则就以出生点为家
        return inst.components.knownlocations:GetLocation("homepoint") or inst.components.knownlocations:GetLocation("spawnpoint")
    end
    return inst:GetPosition()
end

local MedalOriginBeetleBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MedalOriginBeetleBrain:OnStart()
    local root = PriorityNode(
    {
		WhileNode(function() return not self.inst.sg:HasStateTag("jumping") end, "AttackAndWander",
			PriorityNode(
			{
                --受到一定伤害后遁地暂避锋芒
				UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS),
                --不能离开本源之树范围太远了
				Leash(self.inst, GetHomePos, GO_HOME_DIST, GO_HOME_RETURN_DIST, true),
				--技能冷却了？追击！
				WhileNode( function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily", 
					ChaseAndAttack(self.inst, MAX_CHASE_TIME) ),
				--技能没冷却？跑路！
				WhileNode( function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end, "Dodge", 
					RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) ),
				Wander(self.inst, GetHomePos, MAX_WANDER_DIST, { minwalktime = .5, randwalktime = math.random() < 0.5 and .5 or 1, minwaittime = math.random() < 0.5 and 0 or 1, randwaittime = .2, }),
			}, .25)
		)
	}, .25)

    self.bt = BT(self.inst, root)
end

--初始化记录坐标
function MedalOriginBeetleBrain:OnInitializationComplete()
    --本源之树坐标点
    if TheWorld and TheWorld.medal_origin_tree ~= nil then
        self.inst.components.knownlocations:RememberLocation("homepoint", TheWorld.medal_origin_tree:GetPosition(), true)
    end
    --自己生成的坐标点
    local pos = self.inst:GetPosition()
    pos.y = 0
    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return MedalOriginBeetleBrain
