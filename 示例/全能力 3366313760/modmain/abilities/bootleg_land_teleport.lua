local Utils = require("aab_utils/utils")
local Shapes = require("aab_utils/shapes")

--原方法扔到地上不会生成旋涡，这里删除相关逻辑就行，不修改内容
local function OnHit(inst, attacker, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    -- TODO 计算小地图落点，只允许海上通海上，陆地通陆地
    -- if not TheWorld.Map:IsOceanAtPoint(x, y, z) then
    --     inst:RemoveTag("NOCLICK")
    --     inst.persists = true
    --     MakeInventoryPhysics(inst)
    --     inst.AnimState:PlayAnimation("idle")
    --     inst._oceanwhirlportal_spawnpos = nil
    --     inst.SoundEmitter:PlaySound("dontstarve/common/together/infection_burst")
    --     SpawnPrefab("dirt_puff").Transform:SetPosition(x, y, z)
    --     return
    -- end

    inst:CreateOceanWhirlportal(Vector3(x, 0, z), inst._oceanwhirlportal_spawnpos)
    inst.Physics:Teleport(x, 0, z)
    inst.persists = false
    inst.AnimState:PlayAnimation("used")
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/submerge/large")
    inst:ListenForEvent("animqueueover", inst.Remove)
end

-- 破鞋子
AddPrefabPostInit("bootleg", function(inst)
    -- 这两个函数客户端也有
    inst.CanTossInWorld = Utils.TrueFn
    inst.CanTossOnMap = Utils.TrueFn

    if not TheWorld.ismastersim then return end

    inst.components.complexprojectile:SetOnHit(OnHit)
end)

----------------------------------------------------------------------------------------------------

local BOAT_INTERACT_DISTANCE = 6.0
local BOAT_INTERACT_DISTANCE_LEAVE_SQ = (BOAT_INTERACT_DISTANCE + MAX_PHYSICS_RADIUS) *
    (BOAT_INTERACT_DISTANCE + MAX_PHYSICS_RADIUS)

local function CheckForBoatsTickAfter(retTab, inst)
    if retTab[1] then return retTab end

    local selfblocker = inst.components.entitytracker:GetEntity("blocker")
    local exit = inst.components.entitytracker:GetEntity("exit")
    if exit == nil then
        return { false }
    end

    -- 不知道原方法为什么要判断这个
    -- if exit.components.entitytracker:GetEntity("blocker") ~= nil then
    --     return
    -- end

    -- 出口和入口都在陆地，并且上一次传送的不是船，由此排除原方法传送船只
    if not inst:IsOnValidGround() or not exit:IsOnValidGround() or (selfblocker and selfblocker:HasTag("boat")) then
        return { false }
    end

    if selfblocker ~= nil then
        if inst:GetDistanceSqToInst(selfblocker) < BOAT_INTERACT_DISTANCE_LEAVE_SQ then
            return { false }
        end
        inst.components.entitytracker:ForgetEntity("blocker")
    end

    local sx, sy, sz = inst.Transform:GetWorldPosition()
    local ex, ey, ez = exit.Transform:GetWorldPosition()
    local player
    local players = TheSim:FindEntities(sx, sy, sz, BOAT_INTERACT_DISTANCE, { "player" })
    for _, testplayer in ipairs(players) do
        if not testplayer._avoid_whirlportals_hack then
            player = testplayer
            break
        end
    end
    if player == nil then
        return { false }
    end

    -- 标记，好在原方法里并没有判断标记是不是船只，让我也能添加玩家
    inst.components.entitytracker:TrackEntity("blocker", player)
    exit.components.entitytracker:TrackEntity("blocker", player)

    SpawnPrefab("oceanwhirlportal_splash").Transform:SetPosition(sx, sy, sz)
    SpawnPrefab("oceanwhirlportal_splash").Transform:SetPosition(ex, ey, ez)

    player.Physics:Teleport(ex, ey, ez)
    -- 随从也一块儿传送
    if player.components.leader then
        for k, v in pairs(player.components.leader.followers) do
            local ep = Shapes.GetRandomLocation(exit:GetPosition(), 1, 4) --因为没检测落点，距离还是小点好，我怕传到海里去了
            k.Physics:Teleport(ep:Get())
        end
    end

    -- exit.components.wateryprotection:SpreadProtectionAtPoint(ex, ey, ez, MAX_PHYSICS_RADIUS * 2) --出口在陆地，不需要保护
    player:SnapCamera()
    player:ScreenFade(false)
    player:ScreenFade(true, 1)

    return { true }
end

-- 破鞋子的漩涡
AddPrefabPostInit("oceanwhirlportal", function(inst)
    if not TheWorld.ismastersim then return end

    -- 原方法已经实现了船的传送，我只需要实现从陆地到陆地的就行

    inst._check_for_boats_task:Cancel() --需要先把任务停止

    Utils.FnDecorator(inst, "CheckForBoatsTick", nil, CheckForBoatsTickAfter)

    inst._check_for_boats_task = inst:DoPeriodicTask(0.5, inst.CheckForBoatsTick, 0.5 * math.random())
end)

----------------------------------------------------------------------
-- 对鞋子施法的判定，拷贝一大段代码只是为了删除三行代码真是让我痛心

local function ActionCanMapToss(act)
    if act.doer ~= nil and act.invobject ~= nil and act.invobject.CanTossOnMap ~= nil then
        return act.invobject:CanTossOnMap(act.doer)
    end
    return false
end

ACTIONS_MAP_REMAP[ACTIONS.TOSS.code] = function(act, targetpos)
    if act.doer == nil or act.invobject == nil then
        return nil
    end

    local min_dist = act.invobject.map_remap_min_dist
    local max_dist = act.invobject.map_remap_max_dist
    if min_dist or max_dist then
        local x, y, z = act.doer.Transform:GetWorldPosition()
        local dx, dz = targetpos.x - x, targetpos.z - z
        if dx == 0 and dz == 0 then
            dx = 1
        end
        local dist = math.sqrt(dx * dx + dz * dz)
        if min_dist and dist <= min_dist then
            targetpos.x = x + dx * (min_dist / dist)
            targetpos.z = z + dz * (min_dist / dist)
        elseif max_dist and dist >= max_dist then
            targetpos.x = x + dx * (max_dist / dist)
            targetpos.z = z + dz * (max_dist / dist)
        end
    end

    -- ### 允许向陆地施法
    -- if not TheWorld.Map:IsOceanTileAtPoint(targetpos.x, targetpos.y, targetpos.z) then
    --     return nil
    -- end

    local act_remap = BufferedAction(act.doer, nil, ACTIONS.TOSS_MAP, act.invobject, targetpos)
    if not ActionCanMapToss(act_remap) then
        return nil
    end
    return act_remap
end
