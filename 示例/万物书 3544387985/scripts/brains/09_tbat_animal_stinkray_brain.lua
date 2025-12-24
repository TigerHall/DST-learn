require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/wander"
require "behaviours/chaseandattack"


local StungrayBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)


local MAX_CHASE_TIME = 20   -- 追杀时间
local MAX_CHASE_DIST = 20   -- 追杀距离

local MIN_FOLLOW_DIST = 0     -- 最短距离
local MAX_FOLLOW_DIST = 16    -- 最远距离
local TARGET_FOLLOW_DIST = 7  -- 期望距离

local MAX_WANDER_DIST = 20      -- 游荡距离
--------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetWanderPos(inst)
        local player = inst:GetNearestPlayer()
        if player and player:IsValid() then
            return Vector3(player.Transform:GetWorldPosition())
        end
        return Vector3(inst.Transform:GetWorldPosition())
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetFollowingPlayer(inst)
        return inst:GetNearestPlayer()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 燃烧
    local function IsBurning(inst)
        if inst.components.health.takingfiredamage then
            return true
        end
        if inst.components.burnable:IsBurning() then
            return true
        end
    end
    local function InOceanTile(inst)
        return inst.IsInOceanTile and inst:IsInOceanTile()
    end
    local function DoSwim(inst)
        return BufferedAction(inst,nil,ACTIONS.TBAT_PET_STINKRAY_DO_SWIM_FOR_BURNING)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 吃东西
    local EATFOOD_CANT_TAGS = { "INLIMBO", "outofreach" ,"nosteal"}
    local function EatFoodAction(inst)
        if inst.__brain_eat_target then
            local target = inst.__brain_eat_target
            if target and target:IsValid() and target.components.inventoryitem.owner == nil then
                return
            end
            inst.__brain_eat_target = nil
        end
        if inst.components.inventory ~= nil and inst.components.eater ~= nil then
            local target = inst.components.inventory:FindItem(function(item)
                return inst.components.eater:CanEat(item)
            end)
            if target ~= nil then
                return BufferedAction(inst, target, ACTIONS.EAT)
            end
        end
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst

        local target = FindEntity(mid_inst,
            MAX_FOLLOW_DIST,
            function(item)
                return inst.components.eater:CanEat(item)
                    and item.components.inventoryitem and item.components.inventoryitem.owner == nil
                    and not TBAT.DEFINITION:IsImportantItem(item)
            end,
            nil,
            EATFOOD_CANT_TAGS
        )
        if target ~= nil then
            inst.__brain_eat_target = target
            -- print("搜寻到要去吃的目标",target)
            local act = BufferedAction(inst, target, ACTIONS.EAT)
            act.validfn = function() 
                if (target.components.inventoryitem and target.components.inventoryitem.owner == nil) then
                    return true
                else
                    inst.__brain_eat_target = nil
                end
            end
            return act
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 野生的
    local function GetWildWanderPos(inst)
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        if leader and leader:IsValid() then
            return Vector3(leader.Transform:GetWorldPosition())
        end
        return Vector3(inst.Transform:GetWorldPosition())
    end

    local function DoWanderAction(inst)  -- 使用自制游荡，方便动画sg的切换
        if inst.sg:HasStateTag("busy") then
            return
        end
        if type(inst.__brain_DoWanderAction_wating_num) == "number" then
            inst.__brain_DoWanderAction_wating_num = inst.__brain_DoWanderAction_wating_num - 1
            if inst.__brain_DoWanderAction_wating_num > 0 then
                return
            end
        end
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst
        local max_radius = MAX_WANDER_DIST
        if TBAT.PET_MODULES:IsFollowingPlayer(inst) then
            max_radius = MAX_FOLLOW_DIST
        end
        local radius = max_radius * math.random(10,100)/100
        local points = TBAT.FNS:GetSurroundPoints({
            target = mid_inst,
            range = radius,
            num = 10*radius
        })
        local pt = points[math.random(#points)]
        inst.__brain_DoWanderAction_wating_num = TBAT.PET_MODULES:IsFollowingPlayer(inst) and 10 or 20
        return BufferedAction(inst, nil, ACTIONS.TBAT_PET_STINKRAY_WANDER_ACTIVE,nil,pt,nil,0)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetLeaderPos(inst)
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        if leader and leader:IsValid() then
            return Vector3(leader.Transform:GetWorldPosition())
        end
        return Vector3(inst.Transform:GetWorldPosition())
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集藤壶
    local WATERPLANT_TAGS = {"waterplant","veggie"}
    local function WATERPLANT_TEST_FN(target,inst)
        if target and target:IsValid() then
            if target.components.shaveable and target.components.shaveable:CanShave(inst) then
                return true
            end
        end
        return false
    end
    local function DoWaterPlantHarvestAction(inst)
        if inst.sg:HasStateTag("busy") then
            return
        end
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst
        local max_radius = MAX_WANDER_DIST
        local target = FindEntity(mid_inst,
            MAX_FOLLOW_DIST,
            WATERPLANT_TEST_FN,
            WATERPLANT_TAGS,{"burnt"},nil
        )
        if target then
            return BufferedAction(inst, target, ACTIONS.TBAT_PET_STINKRAY_WATERPLANT_SHAVE)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集渔网 oceantrawler
    local OCEANTRAWLER_TAGS = {"oceantrawler"}
    local function OCEANTRAWLER_TEST_FN(target,inst)
        if target and target:IsValid() and target.prefab == "ocean_trawler" then
            if target.components.container and not target.components.container:IsEmpty() then
                return true
            end
        end
        return false
    end
    local function DoOceanTrawlerHarvestAction(inst)
        if inst.sg:HasStateTag("busy") then
            return
        end
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst
        local max_radius = MAX_WANDER_DIST
        local target = FindEntity(mid_inst,
            MAX_WANDER_DIST,
            OCEANTRAWLER_TEST_FN,
            OCEANTRAWLER_TAGS,{"burnt"},nil
        )
        if target then
            return BufferedAction(inst, target, ACTIONS.TBAT_PET_STINKRAY_OCEAN_TRAWLER_PICK)
        end

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------
function StungrayBrain:OnStart()
    local root = PriorityNode(
    {
        --------------------------------------------------------------------------------------------------------------------------
        ---
            -- WhileNode(function() return IsBurning(self.inst) and InOceanTile(self.inst) end, "OnFire",DoAction(self.inst, DoSwim));

            -- WhileNode(function() return IsBurning(self.inst) and not InOceanTile(self.inst) end, "OnFire",Panic(self.inst));

            -- ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

            -- DoAction(self.inst, EatFoodAction),

            -- Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

            -- Wander(self.inst, function() return GetWanderPos(self.inst) end, MAX_WANDER_DIST,nil,nil,nil,nil,{
            --     -- should_run = true
            -- }),
        --------------------------------------------------------------------------------------------------------------------------
        --- 基础通用
            WhileNode(function() return IsBurning(self.inst) and InOceanTile(self.inst) end, "OnFire",DoAction(self.inst, DoSwim));

            WhileNode(function() return IsBurning(self.inst) and not InOceanTile(self.inst) end, "OnFire",Panic(self.inst));

            IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),
        --------------------------------------------------------------------------------------------------------------------------
        --- 野生的
            IfNode(function() return TBAT.PET_MODULES:ThisIsWildAnimal(self.inst) end , "wild animal",
                PriorityNode({

                    WhileNode(function() return IsBurning(self.inst) and InOceanTile(self.inst) end, "OnFire",DoAction(self.inst, DoSwim));

                    WhileNode(function() return IsBurning(self.inst) and not InOceanTile(self.inst) end, "OnFire",Panic(self.inst));

                    IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

                    DoAction(self.inst, EatFoodAction),

                    DoAction(self.inst, DoWanderAction),

                    -- Wander(self.inst, function() return GetWildWanderPos(self.inst) end, MAX_WANDER_DIST)
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------------------------
        --- 如果是养在窝里
            IfNode(function() return TBAT.PET_MODULES:ThisIsHouseAnimal(self.inst) and not TBAT.PET_MODULES:IsFollowingPlayer(self.inst) end, "in pet house",
                PriorityNode({

                    WhileNode(function() return IsBurning(self.inst) and InOceanTile(self.inst) end, "OnFire",DoAction(self.inst, DoSwim));

                    WhileNode(function() return IsBurning(self.inst) and not InOceanTile(self.inst) end, "OnFire",Panic(self.inst));

                    IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

                    DoAction(self.inst, EatFoodAction),

                    DoAction(self.inst, DoWaterPlantHarvestAction),

                    DoAction(self.inst, DoOceanTrawlerHarvestAction),

                    DoAction(self.inst, DoWanderAction),

                    -- Wander(self.inst, function() return GetWildWanderPos(self.inst) end, MAX_WANDER_DIST)
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------------------------
        --- 跟随玩家
            IfNode(function() return TBAT.PET_MODULES:IsFollowingPlayer(self.inst) end, "in pet house",
                PriorityNode({

                    WhileNode(function() return IsBurning(self.inst) and InOceanTile(self.inst) end, "OnFire",DoAction(self.inst, DoSwim));

                    WhileNode(function() return IsBurning(self.inst) and not InOceanTile(self.inst) end, "OnFire",Panic(self.inst));

                    IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),
                    -----------------------------------------------------------------------------

                        DoAction(self.inst, EatFoodAction),

                        DoAction(self.inst, DoWaterPlantHarvestAction),
                    -----------------------------------------------------------------------------
                    --- Follow
                        WhileNode(function() return TBAT.PET_MODULES:Need2RunClosePlayer(self.inst) end, "need 2 close player (run)",
                            Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),

                        Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

                        DoAction(self.inst, DoWanderAction),

                        -- Wander(self.inst, function() return GetLeaderPos(self.inst) end, MAX_FOLLOW_DIST),
                    -----------------------------------------------------------------------------
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------------------------


    }, .25)
    self.bt = BT(self.inst, root)
end

return StungrayBrain
