-- 天体竞技场结界
local assets = {
    Asset("ANIM", "anim/wagpunk_shield_fx.zip"),
}

local prefabs = {
    "alterguardian_arena_collision_oneway",
}

ALTERGUARDIAN_ARENA_COLLISION_DATA = {}
local radius = 28
local segments = 24  
local angle_step = (2 * math.pi) / segments

for i = 0, segments - 1 do
    local angle = i * angle_step
    local x = radius * math.cos(angle)
    local z = radius * math.sin(angle)
    local rotation = math.deg(angle) + 90
    -- 墙体设置4个音效器
    local sfxlooper = (i % 6 == 0)
    
    table.insert(ALTERGUARDIAN_ARENA_COLLISION_DATA, {x, z, rotation, sfxlooper})
end

local function AddPlane(triangles, x0, y0, z0, x1, y1, z1)
    table.insert(triangles, x0)
    table.insert(triangles, y0)
    table.insert(triangles, z0)

    table.insert(triangles, x0)
    table.insert(triangles, y1)
    table.insert(triangles, z0)

    table.insert(triangles, x1)
    table.insert(triangles, y0)
    table.insert(triangles, z1)

    table.insert(triangles, x1)
    table.insert(triangles, y0)
    table.insert(triangles, z1)

    table.insert(triangles, x0)
    table.insert(triangles, y1)
    table.insert(triangles, z0)

    table.insert(triangles, x1)
    table.insert(triangles, y1)
    table.insert(triangles, z1)
end

local function ApplyOffset(value, offset)
    if value < 0 then
        value = value - offset
    elseif value > 0 then
        value = value + offset
    end
    return value
end

local function BuildAlterguardianArenaMesh(offset)
    local triangles = {}
    local index_total = #ALTERGUARDIAN_ARENA_COLLISION_DATA
    local v0 = ALTERGUARDIAN_ARENA_COLLISION_DATA[index_total]
    for index = 1, index_total do
        local v1 = ALTERGUARDIAN_ARENA_COLLISION_DATA[index]
        local x0, z0 = v0[1], v0[2]
        local x1, z1 = v1[1], v1[2]
        if offset then
            x0 = ApplyOffset(x0, offset)
            z0 = ApplyOffset(z0, offset)
            x1 = ApplyOffset(x1, offset)
            z1 = ApplyOffset(z1, offset)
        end
        AddPlane(triangles, x0, 0, z0, x1, 7, z1)
        v0 = v1
    end
    return triangles
end

local function CreateFX()
    local inst = CreateEntity()

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity - CLIENT ONLY FX]]

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX") 

    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("wagpunk_shield_fx")
    inst.AnimState:SetBuild("wagpunk_shield_fx")
    inst.AnimState:SetMultColour(0.5 + 0.5 * math.random(), 0.25 + 0.5 * math.random(), 0.5 + 0.5 * math.random(), 0.5 + math.random() * 0.5)

    return inst
end

local function CreateFX_TooClose(inst, closestindex)
    local fx = CreateFX()

    fx.AnimState:PlayAnimation("hit_loop")
    fx.AnimState:PushAnimation("hit_pst", false)
    fx:ListenForEvent("animqueueover", fx.Remove)
    fx:ListenForEvent("onremove", function()
        inst.clientbarrierfx = nil
    end)
    return fx
end

local function CreateFX_Oneshot(inst, closestindex, bias, index_total)
    local current_index = math.random(-bias, bias + 1)
    current_index = current_index + closestindex
    if current_index < 1 then
        current_index = current_index + index_total
    elseif current_index > index_total then
        current_index = current_index - index_total
    end

    local previous_index = current_index - 1
    if previous_index < 1 then
        previous_index = index_total
    end
    local v0 = ALTERGUARDIAN_ARENA_COLLISION_DATA[previous_index]
    local v1 = ALTERGUARDIAN_ARENA_COLLISION_DATA[current_index]

    local x0, z0 = v0[1], v0[2]
    local x1, z1 = v1[1], v1[2]
    local dz, dx = z1 - z0, x1 - x0
    local angle = math.atan2(-dz, dx)
    local fx = CreateFX()
    fx.Transform:SetRotation(angle * RADIANS - 90)
    fx.AnimState:PlayAnimation(tostring(math.random(3)))
    fx:ListenForEvent("animover", fx.Remove)

    local t = math.random()
    local height = (1 - math.sqrt(math.random())) * 8
    fx.Transform:SetPosition(Lerp(x0, x1, t), height, Lerp(z0, z1, t))
    
    fx.entity:SetParent(inst.entity)
    
end

local function ClearCooldown(inst)
    inst.clientbarrierfxcooldowntask = nil
end

local function UpdateClientFX(inst)
    if ThePlayer then
        local index_total = #ALTERGUARDIAN_ARENA_COLLISION_DATA
        local x, y, z = ThePlayer.Transform:GetWorldPosition()
        local cx, cy, cz = inst.Transform:GetWorldPosition()

        local closestindex, closestdsq = 1, math.huge
        for i, v in ipairs(ALTERGUARDIAN_ARENA_COLLISION_DATA) do
            local dx, dz = (x - cx) - v[1], (z - cz) - v[2]
            local dsq = dx * dx + dz * dz
            if dsq < closestdsq then
                closestindex = i
                closestdsq = dsq
            end
        end

        -- 基于距离计算玩家焦点特效密度
        local closestdist = math.sqrt(closestdsq)
        local playerdensityamount = math.floor(Lerp(1, 4, 8 / (closestdist + 0.01)))
        for i = 1, playerdensityamount do
            inst:DoTaskInTime((i-1) * (0.1 + math.random() * 0.1), CreateFX_Oneshot, closestindex, 1, index_total) -- 玩家焦点特效
        end
        
        -- 独立环绕竞技场的特效
        local circleindex = inst.currentclientfxindex
        for i = 1, 4 do
            inst:DoTaskInTime((i-1) * (0.1 + math.random() * 0.1), CreateFX_Oneshot, circleindex, 1, index_total) -- 环绕特效
            circleindex = circleindex + math.random(1, 3)
            if circleindex > index_total then
                circleindex = circleindex - index_total
            end
        end
        inst.currentclientfxindex = circleindex

    end
end

local function UpdateClientFXTick(inst)
    if math.random() <= 0.65 then
        UpdateClientFX(inst)
    end
end

local function OnEntitySleep(inst)
    if inst.updateclientfxtask then
        inst.updateclientfxtask:Cancel()
        inst.updateclientfxtask = nil
    end
end

local function OnEntityWake(inst)
    if inst.updateclientfxtask then
        inst.updateclientfxtask:Cancel()
        inst.updateclientfxtask = nil
    end
    inst.updateclientfxtask = inst:DoPeriodicTask(0.75, UpdateClientFXTick)
end

--------------------------------------------------------------------------
-- 结界升起时清理竞技场内的建筑
local CLEARSPOT_ONEOF_TAGS = {"structure", "wall"}
local CLEARSPOT_CANT_TAGS = {"INLIMBO", "NOCLICK", "FX", "irreplaceable"}

local function DestroyEntitiesInBarrier(inst)
    local _world = TheWorld
    local _map = _world.Map
    local thickness = TUNING.WAGPUNK_ARENA_COLLISION_NOBUILD_THICKNESS or 3

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 40, nil, CLEARSPOT_CANT_TAGS, CLEARSPOT_ONEOF_TAGS)
    
    for _, ent in ipairs(ents) do
        if ent:IsValid() then
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            if _map:IsPointInAlterguardianArena(ex, ey, ez) and _map:IsAlterguardianArenaBarrierUp() then
                if _world.components.globaldestroyentities then
                    _world.components.globaldestroyentities:DestroyEntity(ent)
                else
                    SpawnPrefab("collapse_small").Transform:SetPosition(ex, ey, ez)
                    if ent.components.workable and ent.components.workable:CanBeWorked() then
                        ent.components.workable:Destroy(inst)
                    elseif ent.components.health then
                        ent.components.health:Kill()
                    else
                        ent:Remove()
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------
-- 主碰撞墙
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:AddPhysics()
    if inst.Physics then
        inst.Physics:SetMass(0)
        inst.Physics:SetCollisionGroup(COLLISION.LAND_OCEAN_LIMITS)
        inst.Physics:SetCollisionMask(
            COLLISION.ITEMS,
            COLLISION.CHARACTERS,
            COLLISION.FLYERS,
            COLLISION.GIANTS
        )
        inst.Physics:SetTriangleMesh(BuildAlterguardianArenaMesh())
    end

    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()

    if not TheNet:IsDedicated() then
        inst.currentclientfxindex = 1
        inst.UpdateClientFX = UpdateClientFX
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
    end

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.persists = false

    inst.DestroyEntitiesInBarrier = DestroyEntitiesInBarrier

    return inst

end

--------------------------------------------------------------------------
-- 单向墙：将实体传送回竞技场内

-- 尝试为实体找到竞技场内的合适位置
local function TryToResolveGoodSpot(ent, map, ax, az, oneway_size)
    local x, y, z = ent.Transform:GetWorldPosition()
    local dx, dz = x - ax, z - az
    local dist = math.sqrt(dx * dx + dz * dz)
    if dist > 0 then
        dx = dx / dist
        dz = dz / dist
        local perfectdisttoinside = ent:GetPhysicsRadius(0) * 2 + oneway_size + 0.1 -- 小间隙避免触碰到主碰撞墙
        local testx, testz, disttoinside
        
        for distbonus = 0, 4, 2 do
            disttoinside = perfectdisttoinside + distbonus
            
            -- 测试NESW方向
            testx, testz = x, z + disttoinside
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x + disttoinside, z
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x, z - disttoinside
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x - disttoinside, z
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            
            -- 对角线方向（从NE开始）
            testx, testz = x + disttoinside, z + disttoinside
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x + disttoinside, z - disttoinside
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x - disttoinside, z - disttoinside
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
            testx, testz = x - disttoinside, z + disttoinside
            if map:IsPointInAlterguardianArena(testx, 0, testz) then
                return testx, testz
            end
        end
    end
    return nil, nil
end

-- 将实体推回到竞技场内
local function GetIn(ent, oneway_size)
    ent.oncollide_onewaytask = nil
 
    if ent.components.locomotor and ent.components.locomotor.pathcaps and ent.components.locomotor.pathcaps.ignoreLand then
        return
    end
    
    local map = TheWorld.Map
    local ax, az = map:GetAlterguardianArenaCenterXZ()
    if ax then
        -- 尝试找到合适的位置
        local x, z = TryToResolveGoodSpot(ent, map, ax, az, oneway_size)
        if x then
            if ent.Physics then
                ent.Physics:Teleport(x, 0, z)
            else
                ent.Transform:SetPosition(x, 0, z)
            end
        else 
        -- 找不到合适位置，弹回竞技场中心
            if ent.Physics then
                ent.Physics:Teleport(ax, 0, az)
            else
                ent.Transform:SetPosition(ax, 0, az)
            end
        end
        
        if ent.sg and ent.sg:HasStateTag("boathopping") then
            -- NOTES(JBK): Pushing an event here is out of order for timing with boathopping so we will handle the event directly as it has higher priority for this state.
            ent.sg:HandleEvent("cancelhop")
        end
    end
end

local function OnCollide_oneway(inst, other)
    if not other or not inst:IsValid() or not other:IsValid() then
        return
    end
    
    if not other.oncollide_onewaytask then 
        other.oncollide_onewaytask = other:DoTaskInTime(0, GetIn, inst.oneway_size)
    end
end

local function fn_oneway()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()
    if inst.Physics then
        inst.Physics:SetMass(0)
        inst.Physics:SetCollisionGroup(COLLISION.LAND_OCEAN_LIMITS)
        inst.Physics:SetCollisionMask(
            COLLISION.ITEMS,
            COLLISION.CHARACTERS,
            COLLISION.FLYERS,
            COLLISION.GIANTS
        )
        inst.oneway_size = 4
        inst.Physics:SetTriangleMesh(BuildAlterguardianArenaMesh(inst.oneway_size))
    else
        inst.oneway_size = 4
    end

    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false

    if inst.Physics then
        inst.Physics:SetCollisionCallback(OnCollide_oneway)
    end

    return inst
end

print("[ArenaCollision] Registering prefabs: alterguardian_arena_collision, alterguardian_arena_collision_oneway")
return Prefab("alterguardian_arena_collision", fn, assets, prefabs),
       Prefab("alterguardian_arena_collision_oneway", fn_oneway)
