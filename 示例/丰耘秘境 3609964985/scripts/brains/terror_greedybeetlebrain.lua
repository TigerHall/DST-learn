require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/standstill"
require "behaviours/chaseandattack"

local MAX_WANDER_DIST = 15 -- 最大流浪距离
local GO_HOME_DIST = 80 -- 回家距离
local SEE_DIST = 20 -- 视野距离
local RUN_AWAY_DIST = 2 -- 逃跑距离
local STOP_RUN_AWAY_DIST = 4 -- 停止逃跑距离
local EAT_PERIOD = 8 -- 每次吃植物的概率

local EAT_MUSTTAGS = {}
local EAT_NOTAGS = {}
local EAT_ONEOFTAGS = {"oversized_veggie", "farm_plant"}
local function FindOversizedFarmPlant(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local plants = TheSim:FindEntities(x, y, z, SEE_DIST, EAT_MUSTTAGS, EAT_NOTAGS, EAT_ONEOFTAGS)
    local oversized_plants = {}
    if #plants > 0 then
        for _, plant in pairs(plants) do
            if plant:HasTag("farm_plant") and plant.is_oversized then
                table.insert(oversized_plants, plant)
            elseif plant:HasTag("oversized_veggie") then
                table.insert(oversized_plants, plant)
            end
        end
    end
    return oversized_plants
end

local function ShouldAttack(inst)
    return inst.components.combat.target ~= nil and not inst.components.combat:InCooldown()
end

local function GetFollowPos(inst)
    if inst.components.knownlocations then
        return inst.components.knownlocations:GetLocation("home") or inst:GetPosition()
    end
    return inst:GetPosition()
end

local function GoHomeAction(inst)
    if inst.components.combat.target ~= nil then
        return
    end
    local homePos = GetFollowPos(inst)
    return homePos ~= nil
        and BufferedAction(inst, nil, ACTIONS.WALKTO, nil, homePos, nil, .2)
        or nil
end

local function ShouldGoHome(inst)
    local homePos = GetFollowPos(inst)
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) > GO_HOME_DIST * GO_HOME_DIST
end

local TerrorGreedyWormBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.eat_cooldown = false
end)

function TerrorGreedyWormBrain:OnStart()
    local root = PriorityNode(
    {
        -- 回家
        WhileNode(function() return ShouldGoHome(self.inst) end, "GoHome",
            DoAction(self.inst, GoHomeAction, "Go Home", true )),

        -- 偷吃
        WhileNode(function()
                local oversized_plants = FindOversizedFarmPlant(self.inst)
                if #oversized_plants > 0 and not ShouldAttack(self.inst) then
                    return true
                end
                return false
            end,
            "FindOversizedFarmPlant",
            ActionNode(function()
                local oversized_plants = FindOversizedFarmPlant(self.inst)
                if #oversized_plants > 0 then
                    for _, plant in pairs(oversized_plants) do
                        if not plant.being_eaten then
                            self.inst.planttarget = plant
                            plant.being_eaten = true
                            break
                        end
                    end
                end

                if self.inst.planttarget and not self.inst.components.timer:TimerExists("EAT") then
                    local action = BufferedAction(self.inst, self.inst.planttarget, ACTIONS.HEATPLANT, nil, nil, nil, 0.1)
                    self.inst.components.locomotor:PushAction(action, true)
                end
            end, "EatOversizedFarmPlant")
        ),

        -- 攻击
        WhileNode(function()
            return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown()
        end, "Attack", ChaseAndAttack(self.inst)),

        -- 走位
        WhileNode(function()
            return self.inst.components.combat.target ~= nil and self.inst.components.combat:InCooldown()
        end, "Dodge", RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),

        -- 踱步
        Wander(self.inst, GetFollowPos, MAX_WANDER_DIST),

        -- StandStill(self.inst)

    }, .25)

    self.bt = BT(self.inst, root)
end

return TerrorGreedyWormBrain
