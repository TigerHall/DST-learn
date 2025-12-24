require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
--require "behaviours/choptree"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local BrainCommon = require "brains/braincommon"

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local START_RUN_DIST = 3
local STOP_RUN_DIST = 5
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_LIGHT_DIST = 20
local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_FOOD_DIST = 10

local COMFORT_LIGHT_LEVEL = 0.3

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

local function ShouldRunAway(inst, target)
    return not inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GetTraderFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, TRADE_DIST, true)
    for _, player in ipairs(players) do
        if inst.components.trader:IsTryingToTradeWithMe(player) then
            return player
        end
    end
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local FINDFOOD_CANT_TAGS = { "outofreach" }
local function FindFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    if inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end

    if inst.components.minigame_spectator ~= nil then
        return
    end

    local time_since_eat = inst.components.eater:TimeSinceLastEating()
    if time_since_eat ~= nil and time_since_eat <= TUNING.PIG_MIN_POOP_PERIOD * 2 then
        return
    end

    local noveggie = time_since_eat ~= nil and time_since_eat < TUNING.PIG_MIN_POOP_PERIOD * 4

    local target = FindEntity(inst,
        SEE_FOOD_DIST,
        function(item)
            return item:GetTimeAlive() >= 8
                and item.prefab ~= "mandrake"
                and item.components.edible ~= nil
                and (not noveggie or item.components.edible.foodtype == FOODTYPE.MEAT)
                and item:IsOnPassablePoint()
                and inst.components.eater:CanEat(item)
        end,
        nil,
        FINDFOOD_CANT_TAGS
    )
    if target ~= nil then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end

    target = FindEntity(inst,
        SEE_FOOD_DIST,
        function(item)
            return item.components.shelf ~= nil
                and item.components.shelf.itemonshelf ~= nil
                and item.components.shelf.cantakeitem
                and item.components.shelf.itemonshelf.components.edible ~= nil
                and (not noveggie or item.components.shelf.itemonshelf.components.edible.foodtype == FOODTYPE.MEAT)
                and item:IsOnPassablePoint()
                and inst.components.eater:CanEat(item.components.shelf.itemonshelf)
        end,
        nil,
        FINDFOOD_CANT_TAGS
    )
    if target ~= nil then
        return BufferedAction(inst, target, ACTIONS.TAKEITEM)
    end
end

local function IsDeciduousTreeMonster(guy)
    return guy.monster and guy.prefab == "deciduoustree"
end

local CHOP_MUST_TAGS = { "CHOP_workable" }
local function FindDeciduousTreeMonster(inst)
    return FindEntity(inst, SEE_TREE_DIST / 3, IsDeciduousTreeMonster, CHOP_MUST_TAGS)
end

local function KeepChoppingAction(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, KEEP_CHOPPING_DIST))
        or FindDeciduousTreeMonster(inst) ~= nil
end

local function StartChoppingCondition(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst.components.follower.leader.sg ~= nil and
            inst.components.follower.leader.sg:HasStateTag("chopping"))
        or FindDeciduousTreeMonster(inst) ~= nil
end

local function FindTreeToChopAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, nil, CHOP_MUST_TAGS)
    if target ~= nil then
        if inst.tree_target ~= nil then
            target = inst.tree_target
            inst.tree_target = nil
        else
            target = FindDeciduousTreeMonster(inst) or target
        end
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local LIGHTSOURCE_TAGS = { "lightsource" }
local function GetNearestLightPos(inst)
    local light = GetClosestInstWithTag(LIGHTSOURCE_TAGS, inst, SEE_LIGHT_DIST)
    return (light ~= nil and light:GetPosition()) or nil
end

local function GetNearestLightRadius(inst)
    local light = GetClosestInstWithTag(LIGHTSOURCE_TAGS, inst, SEE_LIGHT_DIST)
    return (light ~= nil and light.Light:GetCalculatedRadius()) or 1
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local function GetFaceTargetNearestPlayerFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return FindClosestPlayerInRange(x, y, z, START_RUN_DIST + 1, true)
end

local function KeepFaceTargetNearestPlayerFn(inst, target)
    return GetFaceTargetNearestPlayerFn(inst) == target
end

local function SafeLightDist(inst, target)
    return (target:HasTag("player") or target:HasTag("playerlight")
            or (target.inventoryitem and target.inventoryitem:GetGrandOwner() and target.inventoryitem:GetGrandOwner():HasTag("player")))
        and 4
        or target.Light:GetCalculatedRadius() / 3
end

local PigBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function PigBrain:OnStart()
    local day = WhileNode(function() return not TheWorld.state.isnight end, "IsDay",
        PriorityNode {
            ChattyNode(self.inst, "PIG_TALK_FIND_MEAT",
                DoAction(self.inst, FindFoodAction)),
            IfThenDoWhileNode(function() return StartChoppingCondition(self.inst) end, function() return KeepChoppingAction(self.inst) end, "chop",
                LoopNode {
                    ChattyNode(self.inst, "PIG_TALK_HELP_CHOP_WOOD",
                        DoAction(self.inst, FindTreeToChopAction)) }),
            ChattyNode(self.inst, "PIG_TALK_FOLLOWWILSON",
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),
            IfNode(function() return GetLeader(self.inst) end, "has leader",
                ChattyNode(self.inst, "PIG_TALK_FOLLOWWILSON",
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn))),

            ChattyNode(self.inst, "PIG_TALK_RUNAWAY_WILSON",
                RunAway(self.inst, "player", START_RUN_DIST, STOP_RUN_DIST)),
            ChattyNode(self.inst, "PIG_TALK_LOOKATWILSON",
                FaceEntity(self.inst, GetFaceTargetNearestPlayerFn, KeepFaceTargetNearestPlayerFn)),
            Wander(self.inst, nil, MAX_WANDER_DIST)
        }, .5)

    local night = WhileNode(function() return TheWorld.state.isnight end, "IsNight", --黄昏就不算了，不然就没用了
        PriorityNode {
            ChattyNode(self.inst, "PIG_TALK_RUN_FROM_SPIDER", RunAway(self.inst, "spider", 4, 8)),
            ChattyNode(self.inst, "PIG_TALK_FIND_MEAT", DoAction(self.inst, FindFoodAction)),
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
            WhileNode(function() return TheWorld.state.isnight and self.inst:IsLightGreaterThan(COMFORT_LIGHT_LEVEL) end, "IsInLight", -- wants slightly brighter light for this
                Wander(self.inst, GetNearestLightPos, GetNearestLightRadius, {
                    minwalktime = 0.6,
                    randwalktime = 0.2,
                    minwaittime = 5,
                    randwaittime = 5
                })
            ),
            ChattyNode(self.inst, "PIG_TALK_FIND_LIGHT", FindLight(self.inst, SEE_LIGHT_DIST, SafeLightDist)),
            ChattyNode(self.inst, "PIG_TALK_PANIC", Panic(self.inst)),
        }, 1)

    local root =
        PriorityNode(
            {
                BrainCommon.PanicWhenScared(self.inst, .25, "PIG_TALK_PANICBOSS"),
                WhileNode(function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted",
                    ChattyNode(self.inst, "PIG_TALK_PANICHAUNT", Panic(self.inst))),
                WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
                    ChattyNode(self.inst, "PIG_TALK_PANICFIRE", Panic(self.inst))),
                BrainCommon.IpecacsyrupPanicTrigger(self.inst),
                --救玩家
                ChattyNode(self.inst, "PIG_TALK_RESCUE",
                    WhileNode(function() return GetLeader(self.inst) and GetLeader(self.inst).components.pinnable and GetLeader(self.inst).components.pinnable:IsStuck() end,
                        "Leader Phlegmed",
                        DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true))),
                --打架
                ChattyNode(self.inst, "PIG_TALK_FIGHT", ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),
                RunAway(self.inst, function(guy) return guy:HasTag("pig") and guy.components.combat and guy.components.combat.target == self.inst end, RUN_AWAY_DIST,
                    STOP_RUN_AWAY_DIST),
                ChattyNode(self.inst, "PIG_TALK_ATTEMPT_TRADE", FaceEntity(self.inst, GetTraderFn, KeepTraderFn)),
                day,
                night,
            }, .5)

    self.bt = BT(self.inst, root)
end

return PigBrain
