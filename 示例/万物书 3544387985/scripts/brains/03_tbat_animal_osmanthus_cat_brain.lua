require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/runaway"
require "behaviours/leash"

local BrainCommon = require "brains/braincommon"

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 18
local TARGET_FOLLOW_DIST = 6
local MAX_WANDER_DIST = 10

local LEASH_RETURN_DIST = 5
local LEASH_MAX_DIST = 10

local MAX_CHASE_TIME = 4
local MAX_CHASE_DIST = 20

local AVOID_DIST = 3
local AVOID_STOP = 10

local NO_TAGS = {"nosteal","FX", "NOCLICK", "DECOR","INLIMBO", "stump", "burnt", "notarget", "flight", "fire", "irreplaceable"}
local PLAY_TAGS = {"cattoy", "cattoyairborne", "catfood"}

local CatcoonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function restore_toy_tag(targ, tag)
	targ:AddTag(tag)
end

local function PlayAction(inst) --- 玩玩具（拾取东西）
    if inst.sg:HasStateTag("busy") or (inst.hairball_friend_interval and inst.hairball_friend_interval <= 5) then 
		return
	end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    local mid_inst = leader and leader:IsValid() and leader or inst
    local target = FindEntity(mid_inst, TUNING.CATCOON_TARGET_DIST, function(item) return item:IsOnPassablePoint() end, nil, NO_TAGS, PLAY_TAGS)
	if target ~= nil then
		local action = nil
		local cattoyairborne = target:HasTag("cattoyairborne")
		local tag = cattoyairborne and "cattoyairborne" 
					or target:HasTag("cattoy") and "cattoy" 
					or "catfood"

		if cattoyairborne and not (target.sg and (target.sg:HasStateTag("landing") or target.sg:HasStateTag("landed"))) then
			if inst.last_play_air_time and (GetTime() - inst.last_play_air_time) < 15 then
				return 
			end
			action = BufferedAction(inst, target, ACTIONS.CATPLAYAIR)
		else
			action = BufferedAction(inst, target, ACTIONS.CATPLAYGROUND)
		end

		target:RemoveTag(tag)
		target:DoTaskInTime(30, restore_toy_tag, tag)
		return action
	end
end

local function HasValidHome(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    return home ~= nil
        and home:IsValid()
        and not (home.components.burnable ~= nil and home.components.burnable:IsBurning())
        and not home:HasTag("burnt")
end

local function IsFollowingPlayer(inst)
    local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
    return following_player ~= nil
end

local function GetNoLeaderHomePos(inst)
    if IsFollowingPlayer(inst) then
        return
    end
    if inst.GetPetHouse and inst:GetPetHouse() then
        return
    end
    if inst.components.follower and inst.components.follower.leader then
        return Vector3(inst.components.follower.leader.Transform:GetWorldPosition())
    end
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local function CheckNeed2GoHome(inst)
    if inst.need_to_go_home then
        return inst.need_to_go_home(inst)
    end
    return false
end

local function GoHomeAction(inst)
    if inst.components.homeseeker and inst.components.homeseeker.home and
       inst.components.homeseeker.home:IsValid() and
	   inst.sg:HasStateTag("trapped") == false then
        -- print("brain go home +++ ",math.random(100))
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function ShouldHairball(inst)
    if inst.components.follower and inst.components.follower.leader then
        if GetTime() - inst.last_hairball_time >= inst.hairball_friend_interval then
            inst.hairball_friend_interval = math.random(TUNING.MIN_HAIRBALL_FRIEND_INTERVAL, TUNING.MAX_HAIRBALL_FRIEND_INTERVAL)
            return true
        end
    else
        if GetTime() - inst.last_hairball_time >= inst.hairball_neutral_interval then
            inst.hairball_neutral_interval = math.random(TUNING.MIN_HAIRBALL_NEUTRAL_INTERVAL, TUNING.MAX_HAIRBALL_NEUTRAL_INTERVAL)
            return true
        end
    end
end

local function HairballAction(inst)
    if inst.sg:HasStateTag("busy") then return end
    if inst.components.follower and inst.components.follower.leader then
        return BufferedAction(inst, inst.components.follower.leader, ACTIONS.HAIRBALL)
    else
        return BufferedAction(inst, nil, ACTIONS.HAIRBALL)
    end
end

local function WhineAction(inst)
    if inst.sg:HasStateTag("busy") then return end
    if inst.components.follower and inst.components.follower.leader and inst.components.follower:GetLoyaltyPercent() < .03 then
        return BufferedAction(inst, inst.components.follower.leader, ACTIONS.CATPLAYGROUND)
    end
end



local function need_to_protect_player(inst)
    local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
    if following_player == nil then
        return false
    end
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,0, z, 15, {"_combat"})
    local nearest_target = nil
    local nearest_dist_sq = 400
    for k, tempInst in pairs(ents) do
        local target = tempInst.components.combat.target
        local temp_dis_sg = inst:GetDistanceSqToInst(tempInst)
        if (target == following_player or target == inst) and temp_dis_sg < nearest_dist_sq then
            nearest_target = tempInst
            nearest_dist_sq = temp_dis_sg
        end
    end
    if nearest_target ~= nil then
        return true,nearest_target
    end
    return false
end

local function ProtectPlayer(inst)
    if not (inst.GetFollowingPlayer and inst:GetFollowingPlayer()) then
        return
    end
    local flag,target = need_to_protect_player(inst)
    if target then
        -- print("玩家正在被攻击",target)
        inst.components.combat:SuggestTarget(target)
        -- return BufferedAction(inst, target, ACTIONS.ATTACK)
        return target
    else
        -- print("玩家不需要保护")
        inst.components.combat:DropTarget()
    end
end

local function IsFollowingEyeBoneHouse(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader.components.inventoryitem then
        local owner = leader.components.inventoryitem:GetGrandOwner()
        if owner and owner.components.container then
            return true
        end
    end
    return false
end

local function InventoryFull(inst)
    local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
    if following_player and not following_player:HasTag("playerghost") then
        inst.components.inventory:ForEachItem(function(item)
            if item then
                inst.components.inventory:DropItem(item)
                following_player.components.inventory:GiveItem(item)
            end
        end)
    else
        inst.components.inventory:ForEachItem(function(item)
            if item then
                item:Remove()
            end
        end)
    end
    if inst.components.health then
        inst.components.health:SetPercent(1)
    end
end

function CatcoonBrain:OnStart()
    local root =
    PriorityNode(
    {
        BrainCommon.PanicWhenScared(self.inst, 1),
		BrainCommon.PanicTrigger(self.inst),
        -- IfNode(function() return ShouldHairball(self.inst) end, "hairball",
        --     DoAction(self.inst, HairballAction, "hairballact", true)),
        -- ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

        WhileNode(function() return CheckNeed2GoHome(self.inst) end, "need ot go home",
            DoAction(self.inst, GoHomeAction, "go home", true )),

        -- DoAction(self.inst, function() return ProtectPlayer(self.inst) end, "protect player", true),
        IfNode(function() return ProtectPlayer(self.inst) ~= nil end, "protect player",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

        IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

        IfNode(function() return IsFollowingEyeBoneHouse(self.inst) end, "in pet house",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

        IfNode(function() return self.inst.components.inventory:IsFull() end, "DepositInv",
            DoAction(self.inst, InventoryFull, "DepositInv", false)),

        IfNode(function() return IsFollowingPlayer(self.inst) and TBAT.PET_MODULES:Need2RunClosePlayer(self.inst) end,"following player run" ,        
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST,true)),

        IfNode(function() return IsFollowingPlayer(self.inst) end,"following player" ,        
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),

                -- WhileNode(function() return self.inst.raining end, "GoingHome",
                --     DoAction(self.inst, GoHomeAction, "go home", true )),
                -- WhileNode(function() return self.inst.components.inventory:IsFull() end, "DepositInv",
                --     DoAction(self.inst, GoHomeAction, "go home", false)),

        -- DoAction(self.inst, PlayAction, "play", true),--- 捡取周围东西。

                -- IfNode(function() return GetLeader(self.inst) end, "has leader",
                --     FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn )),
        Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),
        RunAway(self.inst, "player", AVOID_DIST, AVOID_STOP, nil, nil, NO_TAGS),
        Wander(self.inst, function() return self.inst:GetPosition() end, MAX_WANDER_DIST,nil,nil,nil,nil,{
                            should_run = TBAT.PET_MODULES:Need2RunClosePlayer(self.inst)
                        }),

        DoAction(self.inst, WhineAction, "whine", true),

    }, .25)
    self.bt = BT(self.inst, root)
end

return CatcoonBrain
