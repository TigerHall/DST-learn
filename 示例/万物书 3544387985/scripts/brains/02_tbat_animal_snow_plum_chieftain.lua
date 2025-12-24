require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"
require "behaviours/runaway"
require "behaviours/leash"
require "behaviours/doaction"
require "behaviours/chaseandattack"

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 12
local TARGET_FOLLOW_DIST = 6
local FOLLOWPLAYER_DIST = 30

local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 20
local BARK_AT_FRIEND_DIST = 12

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6

local LEASH_RETURN_DIST = 15
local LEASH_MAX_DIST = 30

local MAX_CHASE_TIME = 4
local MAX_CHASE_DIST = 10

local AVOID_DIST = 3
local AVOID_STOP = 10

local POG_SEE_FOOD = 30
local POG_EAT_DELAY = 0.5

local NO_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "stump", "burnt"}
local PLAY_TAGS = {"cattoy", "cattoyairborne", "catfood"}

local PogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


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

local function need_to_protect_player(inst)
    local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
    if not following_player == nil then
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
    local flag,target = need_to_protect_player(inst)
    if target then
        -- print("玩家正在被攻击",target)
        inst.components.combat:SuggestTarget(target)
        return BufferedAction(inst, target, ACTIONS.ATTACK)
    else
        -- print("玩家不需要保护")
    end
end

local function Need2FindFoods(inst)
    local current_target_food = inst.__brain_eating_food
    if current_target_food and current_target_food:IsValid()
        and current_target_food.components.inventoryitem and current_target_food.components.inventoryitem.owner == nil
        then
        return true
    end
    if inst.components.combat.target then
        return false
    end
    return true
end

local function EatFoodAction(inst)
    local target = nil

    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
    end
    if not target then
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local mid_inst = leader and leader:IsValid() and leader or inst

        local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic","nosteal","poisonous"}    
        target = FindEntity(mid_inst, POG_SEE_FOOD, function(item)
            if inst.components.eater:CanEat(item)
                and item:IsOnValidGround() 
                and item:GetTimeAlive() > POG_EAT_DELAY
                and item.components.inventoryitem
                and item.components.inventoryitem.owner == nil
                and item.sg == nil
                and item.brainfn == nil
                and not TBAT.DEFINITION:IsImportantItem(item)
                then
                    return true
                end
        end, nil, notags)    
        
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, POG_SEE_FOOD, {"tbat_animal_snow_plum_chieftain"})
        for i,ent in ipairs(ents)do

            -- if another nearby pog is already going to this food, maybe go after it?
            if ((ent.components.locomotor.bufferedaction and ent.components.locomotor.bufferedaction.target and ent.components.locomotor.bufferedaction.target == target) or 
                (inst.bufferedaction and inst.bufferedaction.target and inst.bufferedaction.target == target) )            
                and ent ~= inst then            
                if math.random() < 0.9 then
                    return nil
                end
            end
        end
    end
    if target and target.components.inventoryitem and target.components.inventoryitem.owner == nil then
        -- print("++ 吃东西：",target)
        inst.__brain_eating_food = target
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function GetLeader(inst)
    if not CheckNeed2GoHome(inst) then
        return inst.components.follower.leader 
    end
end

local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function GetWanderDistFn(inst)
    if TheWorld.state.isday then
        return WANDER_DIST_NIGHT
    else
        return WANDER_DIST_DAY
    end
end

local function barkatfriend(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    local mid_inst = leader and leader:IsValid() and leader or inst
    local target = FindEntity(mid_inst, BARK_AT_FRIEND_DIST, function(item) return item.sg:HasStateTag("idle") end, {"tbat_animal_snow_plum_chieftain"}) --  item:HasTag("pog") and 
    if target and math.random() < 0.01 then
        return BufferedAction(inst, target, ACTIONS.TBAT_POG_BARK)
    end
end

local function can_steal_item(inst,item)
    local call_back_table = {
        item = item,
        flag = false,
    }
    inst:PushEvent("can_steal_item",call_back_table)
    return call_back_table.flag
end

local function ransack(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, POG_SEE_FOOD, {"structure"})
    local containers = {}
    for i, ent in ipairs(ents) do
        if ent.components.container
            and ent.components.container.canbeopened
            and not ent:HasTag("nosteal")
            then
            table.insert(containers,ent)
        end
    end

    if #containers > 0 then
        local container = containers[math.random(1,#containers)]

        local items = container.components.container:FindItems(function(item)            
            return can_steal_item(inst,item)
        end)
        if #items > 0 then
            return BufferedAction(inst, container, ACTIONS.TBAT_POG_RANSACK)
        end
    end
end

local function harassPlayer(inst)
    local target = GetClosestInstWithTag("player", inst, 30)
	if target then
    local item = nil

    local p_pt = Vector3(target.Transform:GetWorldPosition())
    local m_pt = Vector3(inst.Transform:GetWorldPosition())

    if target then
        item = target.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end )
    end

    if item and distsq(p_pt, m_pt) < FOLLOWPLAYER_DIST * FOLLOWPLAYER_DIST then --  and not (target and target.components.driver and target.components.driver:GetIsDriving()) then
        return target
    end
	end
end

local function SuggestTarget(inst)
    local player = GetClosestInstWithTag("player", inst, 15)
    if player then
        inst.components.combat:SuggestTarget(player)
    end
end

function PogBrain:OnInitializationComplete()
    if self.inst.components.knownlocations:GetLocation("herd") == nil then
        self.inst.components.knownlocations:RememberLocation("herd", self.inst:GetPosition(), true)
    end
end

function PogBrain:OnStart()
    local root = 
    PriorityNode(
    {
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),

        WhileNode(function() return CheckNeed2GoHome(self.inst) end, "need ot go home",
            DoAction(self.inst, GoHomeAction, "go home", true )),
            
        DoAction(self.inst, function() return ProtectPlayer(self.inst) end, "protect player", true),

        IfNode ( function() return Need2FindFoods(self.inst) end, "AporkalypseActive",
            DoAction(self.inst, function() return EatFoodAction(self.inst) end, "Eat", true) ),

        -- DoAction(self.inst, function() return EatFoodAction(self.inst) end, "Eat", true),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

        -- DoAction(self.inst, function() return ransack(self.inst) end, "ransack", true), --- 翻找箱子，并丢出东西
        IfNode(function() return TBAT.PET_MODULES:Need2RunClosePlayer(self.inst) end, "Need2RunClosePlayer",
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST,true)),

        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),        
        
        DoAction(self.inst, function() return barkatfriend(self.inst) end, "Bark at friend", true),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("herd") end, GetWanderDistFn),

        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Follow(self.inst, function() return harassPlayer(self.inst) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),
        

    }, .25)
    self.bt = BT(self.inst, root)
end

return PogBrain