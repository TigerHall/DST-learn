require "behaviours/standandattack"
require "behaviours/standstill"
require "behaviours/wander"
local BrainCommon = require("brains/braincommon")

local GO_HOME_DIST = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE*1.5--离家最远距离
local GO_HOME_RETURN_DIST = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE--到这个距离后停止

local MedalOriginMushGnomeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

--获取"老家"坐标
local function GetHomePos(inst)
    if inst.components.knownlocations then
        --优先以本源之树为家，否则就以出生点为家
        return inst.components.knownlocations:GetLocation("homepoint") or inst.components.knownlocations:GetLocation("spawnpoint")
    end
    return inst:GetPosition()
end

local THREAT_PARAMS =
{
    --远离自己的攻击目标以及所有攻击目标是自己的生物
    fn = function(candidate, inst)
        return candidate.components.combat:TargetIs(inst) or
                inst.components.combat:TargetIs(candidate)
    end,
    tags =
    {
        "_combat",
    },
    notags =
    {
        "DECOR",
        "FX",
        "INLIMBO",
    },
}

local function false_func(inst)
    return false
end

function MedalOriginMushGnomeBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(function() return self.inst.components.combat:HasTarget() and
                    not self.inst.components.combat:InCooldown() end, "Spray Spores",
                PriorityNode({
                    StandStill(self.inst, nil, false_func),    -- This is a dirty way to stop the locomotor before attacking...
                    StandAndAttack(self.inst, nil, 7)
                }, 1.0)
            ),
            --不能离开本源之树范围太远了
			Leash(self.inst, GetHomePos, GO_HOME_DIST, GO_HOME_RETURN_DIST, true),
			BrainCommon.PanicTrigger(self.inst),
            RunAway(self.inst, THREAT_PARAMS, 5, 10),
            Wander(self.inst),
        }, 1)

    self.bt = BT(self.inst, root)
end

--初始化记录坐标
function MedalOriginMushGnomeBrain:OnInitializationComplete()
    --本源之树坐标点
    if TheWorld and TheWorld.medal_origin_tree ~= nil then
        self.inst.components.knownlocations:RememberLocation("homepoint", TheWorld.medal_origin_tree:GetPosition(), true)
    end
    --自己生成的坐标点
    local pos = self.inst:GetPosition()
    pos.y = 0
    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return MedalOriginMushGnomeBrain
