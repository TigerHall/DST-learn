require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/chaseandattack"

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5

local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_STOP = 6

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 20
local TARGET_FOLLOW_DIST = 3

local SEE_BAIT_DIST = 20
local MAX_WANDER_DIST = 20
local SEE_STOLEN_ITEM_DIST = 10

local MAX_CHASE_TIME = 8
local MAX_CHASE_DIST = 20


local PikoBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


local function EatFoodAction(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    local mid_inst = leader and leader:IsValid() and leader or inst
    local target = FindEntity(mid_inst, SEE_BAIT_DIST,
        function(item)
            if inst.components.eater:CanEat(item)
            and item.components.bait
            and not TBAT.DEFINITION:IsImportantItem(item)
            and not (item.components.inventoryitem and item.components.inventoryitem:IsHeld() and item.components.inventoryitem.owner == nil)
            then
                return true
            end
        end,nil,{"nosteal","planted"})
    if target then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function() return not (target.components.inventoryitem and target.components.inventoryitem:IsHeld()) end
        return act
    end
end

local function PickupAction(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    local mid_inst = leader and leader:IsValid() and leader or inst
    if inst.components.inventory:NumItems() < 1 then
        local target = FindEntity(mid_inst, SEE_STOLEN_ITEM_DIST,
            function(item)
                local x,y,z = item.Transform:GetWorldPosition()
                local isValidPosition = x and y and z
                local isValidPickupItem =
                    isValidPosition and
                    item.components.inventoryitem and
                    not item.components.inventoryitem:IsHeld()
                    and item.components.inventoryitem.owner == nil
                    and item.components.inventoryitem.canbepickedup
                    and item:IsOnValidGround()
                    and item.sg == nil
                    and item.brainfn == nil
                return isValidPickupItem
            end,nil,{"trap","irreplaceable","nonpotatable","nosteal"})
        if target then
            inst.__brain_pickup_action_item = target
            return BufferedAction(inst, target, ACTIONS.PICKUP)
        end
    end
end


local function findhome(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 30, {"teatree"},{"stump","burnt"})
    local home = nil
    for i, ent in ipairs(ents)do
        if not ent.components.spawner or not ent.components.spawner.child then
            home = ent
            break
        end
    end

    if home then
        if not home.components.spawner then
            home:AddComponent( "spawner" )
            home.setupspawner(home)
            home.components.spawner:CancelSpawning()
            home.components.spawner:TakeOwnership(inst)
            inst.findhometask:Cancel()
            inst.findhometask = nil
        end
    end
end

local function CheckForHome(inst)
    if not inst.components.homeseeker then
        if not inst.findhometask then
            inst.findhometask = inst:DoPeriodicTask(10,function() findhome(inst) end)            
        end
        return true
    end
end
--------------------------------------------------------------------------------------------------------
--- 野生松鼠
    local function is_free_animal(inst)
        local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
        local pet_house = inst.GetPetHouse and inst:GetPetHouse()
        if following_player or pet_house then
            return false
        end
        return true
    end

    local function wild_animal_need_to_go_home(inst)
        if TheWorld.state.isday then
            return false
        else
            return true
        end
    end
    local function pet_animal_need_to_go_home(inst)
        local following_player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
        if following_player then
            return false
        end
        return wild_animal_need_to_go_home(inst)
    end

    local function get_home_wild(inst)
        local home = inst.components.homeseeker and inst.components.homeseeker.home
        if not(home and home:IsValid()) then
            home = inst.components.follower and inst.components.follower:GetLeader()
        end
        if home and home:IsValid() then
            return home
        end
    end

    local function get_home_pos_wild(inst)
        local home = get_home_wild(inst)
        if home then
            return Vector3(home.Transform:GetWorldPosition())
        end
        return nil
    end

    local function GoHomeAction_Wild(inst)
        local home = get_home_wild(inst)
        if home and not inst.sg:HasStateTag("trapped") then
            return BufferedAction(inst, home, ACTIONS.GOHOME)
        end
    end
--------------------------------------------------------------------------------------------------------
--- 家养松鼠
    local function is_in_pet_house(inst)
        if inst.GetFollowingPlayer and inst:GetFollowingPlayer() then
            return false
        end
        local house = inst.GetPetHouse and inst:GetPetHouse()
        local ret =  house ~= nil
        if ret then
            -- print("松鼠正在宠物房子里")
        end
        return ret
    end

    local function get_home_pos_in_pet_house(inst)
        local house = inst.GetPetHouse and inst:GetPetHouse()
        if house then
            return Vector3(house.Transform:GetWorldPosition())
        end
    end
    ---- 寻找房子附近的空箱子。
    local function get_box_nearby(inst)
        local house_pt = get_home_pos_in_pet_house(inst)
        if house_pt == nil then
            return
        end
        local ents = TheSim:FindEntities(house_pt.x,0,house_pt.z,10, {"tbat_container_squirrel_stash_box"})
        for i,v in ipairs(ents) do
            if v and v.components.container and not v.components.container:IsFull() then
                return v
            end
        end
        return nil
    end
    local function plant_test(tempInst)
        if tempInst and tempInst:IsValid()
            and tempInst.components.pickable
            and tempInst.components.pickable:CanBePicked()
            -- and not tempInst.components.pickable.use_lootdropper_for_product   --- 保护措施
            then
                return true
            end
        return false
    end
    local function find_need_2_pick_plants(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,0,z,25, {"pickable"})
        local ret_plants = {}
        for k, tempInst in pairs(ents) do
            if plant_test(tempInst) then
                table.insert(ret_plants, tempInst)
            end
        end

        if #ret_plants > 0 then
            return ret_plants[math.random(1, #ret_plants)]
        end
        return nil
    end

    local function working_pick_plants(inst)
        local box = inst.___working_target_box or get_box_nearby(inst)
        if box and not box.components.container:IsFull() then
                inst.___working_target_box = box
                if inst.components.inventory:NumItems() > 0 then
                    -- print("身上有东西，开始返回箱子。")
                    return BufferedAction(inst, box, ACTIONS.MAPLE_SQUIRREL_BOX)
                end
                local plant = inst.___working_target_plant or find_need_2_pick_plants(inst)
                if plant and plant_test(plant) then
                    inst.___working_target_plant = plant
                    -- print("有需要采摘的植物，开始采摘。",plant)
                    return BufferedAction(inst, plant, ACTIONS.PICK)
                else
                    inst.___working_target_plant = nil
                end
        else
            inst.___working_target_box = nil
        end
    end
--------------------------------------------------------------------------------------------------------
--- 跟随玩家
    local function GetFollowingPlayer(inst)
        local player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
        if player == nil then
            player = inst.components.follower and inst.components.follower:GetLeader()
        end
        return player
    end
    local function IsFollowingPlayer(inst)
        local player = GetFollowingPlayer(inst)
        local ret = player ~= nil
        if ret then
            -- print("+++松鼠正在跟随玩家")
        end
        return ret
    end
    local function GetFollowingPlayerPos(inst)
        local player =  GetFollowingPlayer(inst)
        if player then
            return Vector3(player.Transform:GetWorldPosition())
        end
        return nil
    end
    local function GetDistance2Player(inst)
        local player = GetFollowingPlayer(inst)
        if player then
            local dis_sq = inst:GetDistanceSqToInst(player)
            local dis = math.sqrt(dis_sq)
            return dis
        end
        return 1000
    end

    local function need_2_close_player(inst)
        local dis = GetDistance2Player(inst)
        if dis <= TARGET_FOLLOW_DIST then
            inst.__need_to_close_player = false
        elseif dis > MAX_FOLLOW_DIST then
            inst.__need_to_close_player = true
        end
        return inst.__need_to_close_player
    end

    local function IsPlayerInDanger(inst)
        local player = GetFollowingPlayer(inst)
        if player == nil then
            return
        end
        local x,y,z = player.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,0, z,20, {"_combat"})
        for k,v in pairs(ents) do
            if v ~= inst and v.components.combat and v.components.combat.target == player then
                inst:PushEvent("following_player_in_danger_talk")
                return true
            end
        end
        return false
    end

--------------------------------------------------------------------------------------------------------
function PikoBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)), -- 被烧。

        IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

        --------------------------------------------------------------------------------------------------------
        --- 如果是自由野生怪物
            IfNode(function() return TBAT.PET_MODULES:ThisIsWildAnimal(self.inst) end , "wild animal",
                PriorityNode({

                    WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)), -- 被烧。

                    IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

                    WhileNode(function() return wild_animal_need_to_go_home(self.inst) end ,"go home",
                        DoAction(self.inst, GoHomeAction_Wild, "go home", true) ),

                    DoAction(self.inst, PickupAction, "searching for prize", true),

                    RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),

                    -- RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, nil, true),
                    --     EventNode(self.inst, "gohome",
                    --         DoAction(self.inst, GoHomeAction_Wild, "go home", true )),

                    DoAction(self.inst, EatFoodAction),

                    Wander(self.inst, function() return get_home_pos_wild(self.inst) end, MAX_WANDER_DIST)
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------
        --- 如果是养在窝里
            IfNode(function() return TBAT.PET_MODULES:ThisIsHouseAnimal(self.inst) and not TBAT.PET_MODULES:IsFollowingPlayer(self.inst) end, "in pet house",
                PriorityNode({

                    WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)), -- 被烧。

                    IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

                    WhileNode(function() return pet_animal_need_to_go_home(self.inst) end ,"go home",
                        DoAction(self.inst, GoHomeAction_Wild, "go home", true) ),

                    DoAction(self.inst, working_pick_plants,"pick plants",true),

                    -- DoAction(self.inst, EatFoodAction),

                    -- DoAction(self.inst, PickupAction, "searching for prize", true),

                    Wander(self.inst, function() return get_home_pos_in_pet_house(self.inst) end, MAX_WANDER_DIST)
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------
        --- 跟随玩家
            IfNode(function() return TBAT.PET_MODULES:IsFollowingPlayer(self.inst) end, "in pet house",
                PriorityNode({

                    WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)), -- 被烧。

                    IfNode(function() return self.inst.components.combat.target ~= nil end, "protect myself",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),
                    -----------------------------------------------------------------------------
                    --- Follow
                        -- Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
                        --- 【笔记】用follower模式会出现奇怪的行为动作，用其他形式替代。
                        WhileNode(function() return need_2_close_player(self.inst) and TBAT.PET_MODULES:Need2RunClosePlayer(self.inst) end, "need 2 close player (run)",
                            Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST,true)),

                        WhileNode(function() return need_2_close_player(self.inst) end, "need 2 close player",
                            Follow(self.inst, GetFollowingPlayer, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),

                        IfNode(function() return IsPlayerInDanger(self.inst) end,"player_in_danger",
                            RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP)),

                        -- DoAction(self.inst, EatFoodAction),

                        -- DoAction(self.inst, PickupAction, "searching for prize", true),

                        --
                        Wander(self.inst, function() return GetDistance2Player(self.inst) < MAX_FOLLOW_DIST and GetFollowingPlayerPos(self.inst) end, MAX_FOLLOW_DIST,nil,nil,nil,nil,{
                            should_run = TBAT.PET_MODULES:Need2RunClosePlayer(self.inst)
                        }),

                    -----------------------------------------------------------------------------
                },0.25)
            ),
        --------------------------------------------------------------------------------------------------------


        -- WhileNode(function() return self.inst.components.inventory:NumItems() > 0 and self.inst.components.homeseeker end, "run off with prize",
        --     DoAction(self.inst, GoHomeAction, "go home", true)),

        -- DoAction(self.inst, PickupAction, "searching for prize", true),

        -- RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
        -- RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, nil, true),
        --     EventNode(self.inst, "gohome",
        --         DoAction(self.inst, GoHomeAction, "go home", true )),


        -- DoAction(self.inst, EatFoodAction),
        -- WhileNode(function() return CheckForHome(self.inst) end, "wander to find home",
        --     Wander(self.inst)),
        -- Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)


    }, 0.25)
    self.bt = BT(self.inst, root)
end

return PikoBrain
