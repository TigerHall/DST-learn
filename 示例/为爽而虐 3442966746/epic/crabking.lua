
--------------------------------------------------------------------------------
-- 帝王蟹增强
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 常量和调整

-- 血量翻倍
TUNING.CRABKING_HEALTH = TUNING.CRABKING_HEALTH * 2

-- 给捕鱼器加可移动属性
AddPrefabPostInit("ocean_trawler", function(inst)
    if not TheWorld.ismastersim then return end
    inst.Physics:ClearCollisionMask()
end)

--------------------------------------------------------------------------------
-- 蟹钳和炮塔生成函数
--------------------------------------------------------------------------------

-- 蟹钳和炮塔能重生
local BOAT_MUST_TAGS = { "boat" }

local function IsValidArmSpawnPoint(x, z)
    if TheWorld.Map:IsVisualGroundAtPoint(x, 0, z) then
        return false
    end

    local self_radius = 0.7
    local check_radius = self_radius + (MAX_PHYSICS_RADIUS + 0.18)
    local boats = TheSim:FindEntities(x, 0, z, check_radius, BOAT_MUST_TAGS)

    for _, boat in ipairs(boats) do
        local boat_radius = boat.GetSafePhysicsRadius and boat:GetSafePhysicsRadius() or 
                           (boat.components.hull ~= nil and boat.components.hull:GetRadius() or TUNING.BOAT.RADIUS) + 0.18
        local bx, by, bz = boat.Transform:GetWorldPosition()
        local dx, dz = bx - x, bz - z
        local dist = math.sqrt(dx * dx + dz * dz)

        if dist - boat_radius <= self_radius then
            return false
        end
    end

    return true
end

local function TrySpawningArm(inst, armpos, numclaws)
    if inst.arms == nil then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local wedge = TWOPI/numclaws
    local theta = armpos*wedge + (math.random() * wedge - wedge/2)
    local radius = 4 + 8*math.random()

    x, z = x + radius * math.cos(theta), z - radius * math.sin(theta)

    if IsValidArmSpawnPoint(x, z) then
        local arm = SpawnPrefab("crabking_claw")
        arm.Transform:SetPosition(x, 0, z)

        if inst.arms[armpos].task ~= nil then
            inst.arms[armpos].task:Cancel()
            inst.arms[armpos].task = nil
        end

        inst.arms[armpos] = arm

        -- 计算血量
        local health = TUNING.CRABKING_CLAW_HEALTH
        if inst.gemcount.green > 4 then 
            health = health + TUNING.CRABKING_CLAW_HEALTH_BOOST 
        end
        if inst.gemcount.green > 7 then 
            health = health + TUNING.CRABKING_CLAW_HEALTH_BOOST 
        end
        if inst.gemcount.green >= 11 then 
            health = health + TUNING.CRABKING_CLAW_HEALTH_BOOST_MAXGEM 
        end

        arm.components.health:SetMaxHealth(health)
        arm.components.combat:SetDefaultDamage(
            TUNING.CRABKING_CLAW_PLAYER_DAMAGE + 
            (math.floor(inst.gemcount.green/2) * TUNING.CRABKING_CLAW_DAMAGE_BOOST)
        )
        
        arm.armpos = armpos
        arm.crabking = inst

        arm:PushEvent("emerge")
        arm:ListenForEvent("attacked", arm.crabkingattacked, inst)
        inst:ListenForEvent("onremove", inst.onarmremoved, arm)

        return arm
    end
end

local function SpawnCannons2hm(inst)
    if inst.cannontowers == nil then return end
    
    local firsttower
    local numcannons = TUNING.CRABKING_BASE_CANNONS + inst.gemcount.yellow
    for i=1, numcannons do
        if not inst.cannontowers[i] and not firsttower then
            firsttower = 1
            inst:SpawnCannonTower(i, nil, numcannons)
        end
    end
end

local LEAK_MUST_TAGS = { "boatleak" }

local function SpawnCannonTower(inst, i, pt, numcannons)
    pt = pt or inst:FindCannonPositions(numcannons, i)

    if pt == nil then
        inst.cannontowers[i] = false
        return
    end

    local tower = SpawnPrefab("crabking_cannontower")
    tower.Transform:SetPosition(pt.x, 0, pt.z)

    -- 计算炮塔血量
    local health = TUNING.CRABKING_CANNONTOWER_HEALTH
    if inst.gemcount.yellow ~= nil and inst.gemcount.yellow > 4 then 
        health = health + TUNING.CRABKING_CANNONTOWER_HEALTH 
    end
    if inst.gemcount.yellow ~= nil and inst.gemcount.yellow > 7 then 
        health = health + TUNING.CRABKING_CANNONTOWER_HEALTH 
    end
    if inst.gemcount.yellow ~= nil and inst.gemcount.yellow >= 11 then
        health = health + TUNING.CRABKING_CANNONTOWER_HEALTH
    end

    tower.components.health:SetMaxHealth(health)
    tower.components.health:SetPercent(1)
    tower.redgemcount = inst.gemcount.red
    tower.yellowgemcount = inst.gemcount.yellow

    inst:ListenForEvent("onremove", inst.oncannontowerremoved, tower)
    inst.cannontowers[i] = tower

    local platform = tower:GetBoatIntersectingPhysics()
    local max_dist = platform ~= nil and math.max(0, platform:GetSafePhysicsRadius() - 2.5) or nil

    -- 调整炮塔位置到平台边界内
    if max_dist ~= nil and not tower:IsNear(platform, max_dist) then
        pt = tower:GetPositionAdjacentTo(platform, max_dist)
        tower.Transform:SetPosition(pt.x, 0, pt.z)
        platform = tower:GetBoatIntersectingPhysics()
    end

    if platform == nil or platform.components.health == nil then
        tower:PushEvent("ck_spawn")
        return tower
    end

    -- 防漏平台立即摧毁
    if platform ~= nil and platform.components.hullhealth.leakproof then
        platform:InstantlyBreakBoat()
        tower:PushEvent("ck_spawn")
        return tower
    end

    local destruction_radius = tower.Physics:GetRadius() + 0.8
    local leaks = TheSim:FindEntities(pt.x, 0, pt.z, destruction_radius, LEAK_MUST_TAGS)

    for i, leak in pairs(leaks) do
        leak:Remove()
    end

    platform.components.health:DoDelta(-TUNING.CRABKING_CANNONTOWER_HULL_SMASH_DAMAGE)
    platform.components.boatphysics:AddEmergencyBrakeSource("crabking_cannontower"..tower.GUID)

    if platform.leak_build_override ~= nil then
        tower.AnimState:AddOverrideBuild(platform.leak_build_override)
    end

    tower:PushEvent("ck_breach")

    tower:ListenForEvent("onremove", function()
        if platform:IsValid() then
            platform.components.boatphysics:RemoveEmergencyBrakeSource("crabking_cannontower"..tower.GUID)
        end
    end)

    return tower
end

--------------------------------------------------------------------------------
-- 攻击碎冰函数
--------------------------------------------------------------------------------

-- 冰面存在时攻击者脚下的冰会裂开
local function oniceattacked2hm(inst, data)
    if inst.shouldremoveice2hm ~= nil then return end
    
    if data and data.attacker and data.attacker:IsValid() and data.attacker:HasTag("player") then
        local attacker = data.attacker
        inst.shouldremoveice2hm = inst:DoTaskInTime(2, function(inst, attacker)
            if TheWorld.components.oceanicemanager then
                local pt = attacker:GetPosition()
                TheWorld.components.oceanicemanager:QueueDestroyForIceAtPoint(pt.x, 0, pt.z)
                inst.shouldremoveice2hm = nil
            end
        end, attacker)
    end
end

--------------------------------------------------------------------------------
-- 帝王蟹初始化处理
--------------------------------------------------------------------------------

AddPrefabPostInit("crabking", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 没苏醒时不受伤害
    if inst.components.health then
        local oldDoDelta = inst.components.health.DoDelta
        inst.components.health.DoDelta = function(self, amount, ...)
            if amount < 0 and not self.inst:HasTag("hostile") then return end
            oldDoDelta(self, amount, ...)
        end
    end
    
    -- 添加冰冻抗性
    if inst.SocketItem then
        oldSocketItem = inst.SocketItem
        inst.SocketItem = function(inst, item, ...)
            oldSocketItem(inst, item, ...)
            if inst.components.freezable then
                inst.components.freezable.diminishingreturns = true
            end
        end
    end
    
    -- 冰面攻击处理
    inst.oniceattacked2hm = oniceattacked2hm   
    local oldDoSpawnIceTile = inst.DoSpawnIceTile
    inst.DoSpawnIceTile = function(inst, ...)
        oldDoSpawnIceTile(inst, ...)
        inst:ListenForEvent("attacked", inst.oniceattacked2hm)
        if inst.freezefx2hm then inst.freezefx2hm:Remove() end
    end
    
    local oldEndIceStage = inst.EndIceStage
    inst.EndIceStage = function(inst, ...)
        oldEndIceStage(inst, ...)
        inst:RemoveEventCallback("attacked", inst.oniceattacked2hm)
    end
    
    -- 蟹钳生成
    inst.TrySpawningArm = TrySpawningArm
    local oldDoSpawnArm = inst.DoSpawnArm
    inst.DoSpawnArm = function(inst, armpos, ...)
        oldDoSpawnArm(inst, armpos, ...)
        if inst.arms and inst.arms[armpos] and inst.arms[armpos].task then
            inst.arms[armpos].task.fn = inst.TrySpawningArm
        end
    end
    
    -- 蟹钳移除事件处理
    local oldonarmremoved = inst.onarmremoved
    inst.onarmremoved = function(arm, ...)
        local numclaws = TUNING.CRABKING_BASE_CLAWS + (math.floor(inst.gemcount.green/2))
        if inst.arms and inst.arms[arm.armpos] then
            oldonarmremoved(arm, ...)
            if inst.arms[arm.armpos].task ~= nil then
                inst.arms[arm.armpos].task:Cancel()
                inst.arms[arm.armpos].task = inst:DoTaskInTime(45, inst.TrySpawningArm, arm.armpos, numclaws)
            end
        end
        
        if inst.arms2hm ~= nil then
            for i, claw in pairs(inst.arms2hm) do
                if arm == claw then
                    table.remove(inst.arms2hm, i)
                    break
                end
            end
        end
    end
    
    -- 施法时移除额外蟹钳
    local oldStartCastSpell = inst.StartCastSpell
    inst.StartCastSpell = function(inst, ...)
        oldStartCastSpell(inst, ...)
        if inst.arms2hm == nil then
            return
        end

        for i, arm in ipairs(inst.arms2hm) do
            arm:PushEvent("submerge")
        end
        inst.arms2hm = nil
    end
    
    -- 炮塔移除事件处理
    local oldoncannontowerremoved = inst.oncannontowerremoved
    inst.oncannontowerremoved = function(tower, ...)
        oldoncannontowerremoved(tower, ...)
        if inst.cannontowers2hm ~= nil then
            for i, cannon in pairs(inst.cannontowers2hm) do
                if tower == cannon then
                    table.remove(inst.cannontowers2hm, i)
                    break
                end
            end
        end
    end
    
    local oldspawncannontower = inst.SpawnCannonTower
    inst.SpawnCannonTower = function(inst, ...)
        local tower = oldspawncannontower(inst, ...)
        if tower then
            tower.crabking2hm = inst
            tower.greengemcout = inst.gemcount.green
        end
        return tower
    end
    
    -- 清理竞技场
    local oldCleanUpArena = inst.CleanUpArena
    inst.CleanUpArena = function(inst, remove, ...)
        oldCleanUpArena(inst, remove, ...)
        
        if inst.arms2hm ~= nil then
            for i, arm in pairs(inst.arms2hm) do
                inst:RemoveEventCallback("onremove", inst.onarmremoved, arm)
                if remove then
                    arm:Remove()
                elseif arm.components.health ~= nil then
                    arm.components.health:Kill()
                end
            end
            inst.arms2hm = nil
        end
        
        if inst.cannontowers2hm ~= nil then
            for i, tower in pairs(inst.cannontowers2hm) do
                if tower then
                    inst:RemoveEventCallback("onremove", inst.oncannontowerremoved, tower)

                    if remove then
                        tower:Remove()
                    elseif tower.components.health ~= nil then
                        tower.components.health:Kill()
                    end
                end
            end
            inst.cannontowers2hm = nil
        end
    end
    
    -- 保存/加载数据处理
    local _OnSave = inst.OnSave
    inst.OnSave = function(inst, data, ...)
        local ents
        if _OnSave then ents = _OnSave(inst, data, ...) end
        if ents == nil then ents = {} end
        
        if inst.cannontowers2hm ~= nil then
            data.cannontowers2hm = {}
            for i, tower in pairs(inst.cannontowers2hm) do
                if tower and tower:IsValid() then
                    data.cannontowers2hm[i] = tower.GUID
                    table.insert(ents, tower.GUID)
                end
            end
        end
        
        if inst.arms2hm ~= nil then
            data.arms2hm = {}
            for i, arm in pairs(inst.arms2hm) do
                if arm.prefab ~= nil and arm:IsValid() then
                    data.arms2hm[i] = arm.GUID
                    table.insert(ents, arm.GUID)
                end
            end
        end
        
        return ents
    end
    
    local _OnLoadPostPass = inst.OnLoadPostPass
    inst.OnLoadPostPass = function(inst, newents, data, ...)
        if _OnLoadPostPass then _OnLoadPostPass(inst, newents, data, ...) end
        
        if data.arms2hm ~= nil then
            inst.arms2hm = {}
            for i, arm in pairs(data.arms2hm) do
                if newents[arm] ~= nil then
                    inst.arms2hm[i] = newents[arm].entity
                    inst:RemoveEventCallback("onremove", inst.onarmremoved, inst.arms2hm[i])
                end
            end
        end
        
        if data.cannontowers2hm ~= nil then
            inst.cannontowers2hm = {}
            for i, tower in pairs(data.cannontowers2hm) do
                if newents[tower] ~= nil then
                    local cannontower = newents[tower].entity

                    inst.cannontowers2hm[i] = cannontower
                    inst:ListenForEvent("onremove", inst.oncannontowerremoved, cannontower)

                    local platform = cannontower:GetCurrentPlatform()

                    if platform ~= nil and platform.components.boatphysics ~= nil then
                        cannontower.sg:GoToState("breach")
                        platform.components.boatphysics:AddEmergencyBrakeSource("crabking_cannontower"..cannontower.GUID)

                        if platform.leak_build_override ~= nil then
                            tower.AnimState:AddOverrideBuild(platform.leak_build_override)
                        end

                        cannontower:ListenForEvent("onremove", function()
                            if platform:IsValid() then
                                platform.components.boatphysics:RemoveEmergencyBrakeSource("crabking_cannontower"..cannontower.GUID)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 炮塔初始化处理
--------------------------------------------------------------------------------

AddPrefabPostInit("crabking_cannontower", function(inst)
    if not TheWorld.ismastersim then return end
    
    local _onsave = inst.OnSave
    inst.OnSave = function(inst, data, ...)
        local ents
        if _onsave then ents = _onsave(inst, data, ...) end
        if ents == nil then ents = {} end
        
        if inst.crabking2hm ~= nil and inst.crabking2hm:IsValid() then
            data.crabking2hm = inst.crabking2hm.GUID
            table.insert(ents, inst.crabking2hm.GUID)
        end
        
        data.greengemcout = inst.greengemcout
        return ents
    end
    
    local _onload = inst.OnLoad
    inst.OnLoadPostPass = function(inst, newents, data, ...)
        if _onload then _onload(inst, data, ...) end
        
        if data and data.crabking2hm ~= nil and newents[data.crabking2hm] ~= nil then
            local crabking = newents[data.crabking2hm].entity
            inst.crabking2hm = crabking
        end
        
        inst.greengemcout = data ~= nil and data.greengemcout or nil
    end
    
    inst.OnLoad = nilfn
    
    local oldlaunchprojectile = inst.LaunchProjectile
    inst.LaunchProjectile = function(inst, ...)
        local proj = oldlaunchprojectile(inst, ...)
        proj.yellowgemcount = inst.yellowgemcount
        proj.greengemcout = inst.greengemcout
        proj.crabking2hm = inst.crabking2hm
        return proj
    end
end)

--------------------------------------------------------------------------------
-- 弹射物击中生成蟹卫和蟹钳
--------------------------------------------------------------------------------

local function onhitspawn(inst)
    local chance = math.random()
    chance = chance + ((inst.redgemcount or 3 + inst.yellowgemcount or 3) * 0.02)
    local x, y, z = inst.Transform:GetWorldPosition()
    local island = TheWorld.Map:IsVisualGroundAtPoint(x, 0, z)
    local platform = TheWorld.Map:GetPlatformAtPoint(x, z)
    
    -- 击中地面或船上生成蟹卫
    if chance > 0.8 and (platform or island) then
        local spawnclaws = SpawnPrefab("crabking_mob")
        spawnclaws.Transform:SetPosition(x, 0, z)
        
        local platform2 = spawnclaws:GetBoatIntersectingPhysics()
        local max_dist = platform2 ~= nil and math.max(0, platform2:GetSafePhysicsRadius() - 2.5) or nil
        
        if max_dist ~= nil and not spawnclaws:IsNear(platform2, max_dist) then
            local pt = spawnclaws:GetPositionAdjacentTo(platform2, max_dist)
            spawnclaws.Transform:SetPosition(pt.x, 0, pt.z)
        end
        
        -- 击中海面生成炮塔或蟹钳
    elseif chance > 0.9 and not island and not platform and inst.crabking2hm ~= nil and inst.crabking2hm:IsValid() then
        -- 在帝王蟹附近生成蟹钳
        if inst:GetDistanceSqToPoint(inst.crabking2hm.Transform:GetWorldPosition()) <= 20 * 20 then
            if inst.crabking2hm.arms2hm == nil then
                inst.crabking2hm.arms2hm = {}
            end
            if #inst.crabking2hm.arms2hm > 10 then return end
            
            local spawnarm = SpawnPrefab("crabking_claw")
            spawnarm.Transform:SetPosition(x, 0, z)
            
            local health = TUNING.CRABKING_CLAW_HEALTH
            if inst.greengemcout ~= nil and inst.greengemcout > 4 then 
                health = health + TUNING.CRABKING_CLAW_HEALTH_BOOST 
            end
            if inst.greengemcout ~= nil and inst.greengemcout > 7 then 
                health = health + TUNING.CRABKING_CLAW_HEALTH_BOOST 
            end
            if inst.greengemcout ~= nil and inst.greengemcout >= 11 then 
                health = health + TUNING.CRABKING_CLAW_HEALTH_BOOST_MAXGEM 
            end

            spawnarm.components.health:SetMaxHealth(health)
            spawnarm.components.combat:SetDefaultDamage(
                TUNING.CRABKING_CLAW_PLAYER_DAMAGE + 
                (math.floor((inst.greengemcout or 3) / 2) * TUNING.CRABKING_CLAW_DAMAGE_BOOST)
            )
            spawnarm.crabking = inst.crabking2hm
            spawnarm:PushEvent("emerge")
            spawnarm:ListenForEvent("attacked", spawnarm.crabkingattacked, inst.crabking2hm)
            inst.crabking2hm:ListenForEvent("onremove", inst.crabking2hm.onarmremoved, spawnarm)
            table.insert(inst.crabking2hm.arms2hm, spawnarm)
            return
        end
        
        -- 生成炮塔
        if inst.crabking2hm.cannontowers2hm == nil then
            inst.crabking2hm.cannontowers2hm = {}
        end
        if #inst.crabking2hm.cannontowers2hm > 10 then return end
        
        local spawncannontower = SpawnPrefab("crabking_cannontower")
        spawncannontower.Transform:SetPosition(x, 0, z)
        spawncannontower.redgemcount = inst.redgemcount or 3
        spawncannontower.yellowgemcount = inst.yellowgemcount or 3
        spawncannontower.crabking2hm = inst.crabking2hm

        local pt = Vector3(x, 0, z)
        local health = TUNING.CRABKING_CANNONTOWER_HEALTH
        if inst.yellowgemcount ~= nil and inst.yellowgemcount > 4 then 
            health = health + TUNING.CRABKING_CANNONTOWER_HEALTH 
        end
        if inst.yellowgemcount ~= nil and inst.yellowgemcount > 7 then 
            health = health + TUNING.CRABKING_CANNONTOWER_HEALTH 
        end
        if inst.yellowgemcount ~= nil and inst.yellowgemcount >= 11 then
            health = health + TUNING.CRABKING_CANNONTOWER_HEALTH
        end

        spawncannontower.components.health:SetMaxHealth(health)
        spawncannontower.components.health:SetPercent(1)
        inst.crabking2hm:ListenForEvent("onremove", inst.crabking2hm.oncannontowerremoved, spawncannontower)

        local platform = spawncannontower:GetBoatIntersectingPhysics()
        local max_dist = platform ~= nil and math.max(0, platform:GetSafePhysicsRadius() - 2.5) or nil

        if max_dist ~= nil and not spawncannontower:IsNear(platform, max_dist) then
            pt = spawncannontower:GetPositionAdjacentTo(platform, max_dist)
            spawncannontower.Transform:SetPosition(pt.x, 0, pt.z)
            platform = spawncannontower:GetBoatIntersectingPhysics()
        end

        if platform == nil or platform.components.health == nil then
            spawncannontower:PushEvent("ck_spawn")
            table.insert(inst.crabking2hm.cannontowers2hm, spawncannontower)
            return
        end

        if platform ~= nil and platform.components.hullhealth.leakproof then
            platform:InstantlyBreakBoat()
            spawncannontower:PushEvent("ck_spawn")
            table.insert(inst.crabking2hm.cannontowers2hm, spawncannontower)
            return
        end

        local destruction_radius = spawncannontower.Physics:GetRadius() + 0.8
        local leaks = TheSim:FindEntities(pt.x, 0, pt.z, destruction_radius, LEAK_MUST_TAGS)

        for i, leak in pairs(leaks) do
            leak:Remove()
        end

        platform.components.health:DoDelta(-TUNING.CRABKING_CANNONTOWER_HULL_SMASH_DAMAGE)
        platform.components.boatphysics:AddEmergencyBrakeSource("crabking_cannontower"..spawncannontower.GUID)

        if platform.leak_build_override ~= nil then
            spawncannontower.AnimState:AddOverrideBuild(platform.leak_build_override)
        end

        spawncannontower:PushEvent("ck_breach")

        spawncannontower:ListenForEvent("onremove", function()
            if platform:IsValid() then
                platform.components.boatphysics:RemoveEmergencyBrakeSource("crabking_cannontower"..spawncannontower.GUID)
            end
        end)
        
        table.insert(inst.crabking2hm.cannontowers2hm, spawncannontower)
    end
end

AddPrefabPostInit("mortarball", function(inst)
    if not TheWorld.ismastersim then return end
    inst.onhitspawn = onhitspawn
    
    if inst.components.complexprojectile then
        local oldonhit = inst.components.complexprojectile.onhitfn
        inst.components.complexprojectile.onhitfn = function(inst, ...)
            oldonhit(inst, ...)
            inst.onhitspawn(inst)
        end
    end
end)

--------------------------------------------------------------------------------
-- 蟹钳守护帝王蟹
--------------------------------------------------------------------------------

-- 判断是否需要传送
local function shouldteleport(inst, target)
    return not inst:IsNear(target, 20) or 
           (inst.crabking and inst.crabking:IsValid() and target:IsNear(inst.crabking, 10) and not inst:IsNear(target, 10))
end

-- 帝王蟹被攻击时的响应
local function crabkingattacked(inst, crabking, data)
    if inst.shouldretarget then return end
    
    if crabking and crabking:IsValid() and data and data.attacker and data.attacker:IsValid() and 
       data.attacker.components.combat and data.attacker.components.health then
        local attacker = data.attacker
        if inst.components.combat and not inst.components.combat:TargetIs(attacker) then
            inst.shouldretarget = true
            inst.sg:GoToState("submergePG", attacker)
            inst.components.combat:SetTarget(attacker)
            inst:DoTaskInTime(10, function()
                inst.shouldretarget = nil
            end)
        end
    end
end

-- 新的重新定位函数（可攻击飞行生物）
local TARGET_DIST = TUNING.CRABKING_ATTACK_TARGETRANGE
local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "playerghost", "crabking_ally"}
local RETARGET_ONEOF_TAGS = { "flying"}

local function newRetarget(inst)
    local gx, gy, gz = inst.Transform:GetWorldPosition()
    local potential_targets = TheSim:FindEntities(
        gx, gy, gz, TARGET_DIST,
        RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS
    )

    for _, target in ipairs(potential_targets) do
        local pos = Vector3(target.Transform:GetWorldPosition())
        if target ~= inst and target.entity:IsVisible() and
           inst.components.combat:CanTarget(target) and
           TheWorld.Map:IsOceanAtPoint(pos.x, 0, pos.z, true) then
            return target, true
        end
    end

    return nil
end

AddPrefabPostInit("crabking_claw", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst.crabkingattacked = function(crabking, data) 
        crabkingattacked(inst, crabking, data) 
    end
    
    local oldOnLoadPostPass = inst.OnLoadPostPass
    inst.OnLoadPostPass = function(inst, newents, data, ...)
        oldOnLoadPostPass(inst, newents, data, ...)
        if inst.crabking ~= nil and inst.crabking:IsValid() then
            local crabking = inst.crabking
            inst:ListenForEvent("attacked", inst.crabkingattacked, crabking)
        end
    end
    
    inst.teleport2hm = nil
    
    if inst.components.combat then
        local oldkeeptargetfn = inst.components.combat.keeptargetfn
        inst.components.combat.keeptargetfn = function(inst, target, ...)
            local keep = oldkeeptargetfn(inst, target, ...)
            if inst.sg:HasStateTag("busy") or inst.teleport2hm == true then 
                return keep 
            end
            if keep and target and target:IsValid() and target:IsOnOcean(true) and shouldteleport(inst, target) then
                inst.sg:GoToState("submergePG", target)
            end
            return keep
        end
        
        local oldtargetfn = inst.components.combat.targetfn
        inst.components.combat.targetfn = function(inst, ...)
            local newtarget, retarget = oldtargetfn(inst, ...)
            if newtarget ~= nil then return newtarget, retarget end
            
            newtarget, retarget = newRetarget(inst, ...)
            if newtarget ~= nil and newtarget ~= inst.components.combat.target then
                return newtarget, true
            else
                return nil
            end
        end
    end
end)

-- 蟹钳掉落削弱
AddPrefabPostInit("crabking_claw", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.lootdropper then
        local oldfn = inst.components.lootdropper.SpawnLootPrefab
        inst.components.lootdropper.SpawnLootPrefab = function(self, lootprefab, ...)
            if lootprefab == "meat" and math.random() > 0.5 then return end
            oldfn(self, lootprefab, ...)
        end
    end
end)
--------------------------------------------------------------------------------
-- 状态图扩展
--------------------------------------------------------------------------------

local function play_shadow_animation(inst, anim, loop)
    inst.AnimState:PlayAnimation(anim, loop)
    if inst.shadow then
        inst.shadow.AnimState:PlayAnimation(anim, loop)
    end
end

AddStategraphState("crabkingclaw", State{
    name = "submergePG",
    tags = { "busy", "canrotate" },

    onenter = function(inst, target)
        play_shadow_animation(inst, "submerge")
        inst.SoundEmitter:PlaySound("turnoftides/common/together/water/emerge/medium")

        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        inst.sg.statemem.target = target
        if not inst.teleport2hm then
            inst.teleport2hm = true
        end
    end,

    events = {
        EventHandler("animover", function(inst)
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                local target = inst.sg.statemem.target
                local x, y, z = target.Transform:GetWorldPosition()
                local radius = 4
                local arc = math.random() * TWOPI
                local pt = Vector3(x + radius * math.cos(arc), 0, z - radius * math.sin(arc))
                
                local targetplatform = target:GetBoatIntersectingPhysics()
                if targetplatform then
                    inst.Transform:SetPosition(pt.x, 0, pt.z)
                    pt = inst:GetPositionAdjacentTo(targetplatform, 7)
                    inst.Transform:SetPosition(pt.x, 0, pt.z)
                else
                    inst.Transform:SetPosition(pt.x, 0, pt.z)
                end
                inst.sg:GoToState("emergePG")
            end
        end),
    },
})

AddStategraphState("crabkingclaw", State{
    name = "emergePG",
    tags = { "busy", "canrotate" },

    onenter = function(inst, pushanim)
        play_shadow_animation(inst, "emerge")
        inst.SoundEmitter:PlaySound("turnoftides/common/together/water/emerge/medium")
        inst.AnimState:SetDeltaTimeMultiplier(1.7)
    end,

    onexit = function(inst)
        inst.AnimState:SetDeltaTimeMultiplier(1)
    end,

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
            if inst.teleport2hm == true then
                inst:DoTaskInTime(3, function() 
                    inst.teleport2hm = nil 
                end)
            end
        end),
    },
})

--------------------------------------------------------------------------------
-- 帝王蟹状态图扩展
--------------------------------------------------------------------------------

local NEARBY_PLATFORM_MUST_TAGS = { "boat", "walkableplatform" }
local NEARBY_PLATFORM_CANT_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }
local NEARBY_PLATFORM_TEST_RADIUS = 3 + TUNING.MAX_WALKABLE_PLATFORM_RADIUS

-- 苏醒时推走附近的船
local function push_nearby_boats(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local radius = inst:GetPhysicsRadius(1)
    local min_range_sq = math.max(0, radius - NEARBY_PLATFORM_TEST_RADIUS)
    min_range_sq = min_range_sq * min_range_sq

    local platform_ents = TheSim:FindEntities(ix, 0, iz, radius + NEARBY_PLATFORM_TEST_RADIUS, NEARBY_PLATFORM_MUST_TAGS, NEARBY_PLATFORM_CANT_TAGS)
    
    local i0
    for i, platform_entity in ipairs(platform_ents) do
        if platform_entity:GetDistanceSqToPoint(ix, 0, iz) >= min_range_sq then
            i0 = i
            break
        end
    end
    
    if i0 then
        for i = i0, #platform_ents do
            local platform_entity = platform_ents[i]
            if platform_entity ~= inst and platform_entity.Transform and platform_entity.components.boatphysics then
                local v2x, v2y, v2z = platform_entity.Transform:GetWorldPosition()
                local mx, mz = v2x - ix, v2z - iz
                if mx ~= 0 or mz ~= 0 then
                    local normalx, normalz = VecUtil_Normalize(mx, mz)
                    local count = 0
                    for _, _ in pairs(platform_entity.components.boatphysics.boatdraginstances) do 
                        count = count + 1 
                    end
                    local force = 2 + (count * 2)
                    platform_entity.components.boatphysics:ApplyForce(normalx, normalz, force)
                end
            end
        end
    end
end

-- 施法期间释放冰冻
local function startfeeze2(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("crabking_feeze2hm")
    fx.crab = inst
    fx.Transform:SetPosition(x, y, z)
    local scale = 0.75 + Remap(inst.gemcount.blue or 3, 0, 9, 0, 1.55)
    fx.Transform:SetScale(scale, scale, scale)
    inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/magic_LP", "crabmagic")
    inst.freezefx2hm = fx
end

AddStategraphPostInit("crabking", function(sg)
    if sg.states.inert_pst then
        local oldonenter = sg.states.inert_pst.onenter
        sg.states.inert_pst.onenter = function(inst, ...)
            oldonenter(inst, ...)
            push_nearby_boats(inst)
            SpawnAttackWaves(inst:GetPosition(), nil, 2.2, 8, nil, 2.25, nil, 2, true)
        end
    end
    
    if sg.states.cast_loop then
        local oldonenter = sg.states.cast_loop.onenter
        sg.states.cast_loop.onenter = function(inst, wavetime, ...)
            oldonenter(inst, wavetime, ...)
            if not inst.freeze2hm then
                inst.freeze2hm = true
                startfeeze2(inst)
                inst:DoTaskInTime(12, function()
                    inst.freeze2hm = nil
                end)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 妥协兼容处理
--------------------------------------------------------------------------------

if not ModManager:GetMod("workshop-2039181790") then return end

-- 驱散附近的蒸腾海域
local function clearboilingwater(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 16, {"CLASSIFIED"})
    for index, ent in ipairs(ents) do 
        if ent and ent:IsValid() and ent.prefab == "boiling_water_spawner" then 
            ent:DoTaskInTime(0, ent.Remove) 
        end 
    end
end

-- 释放冰冻效果
local function startfeeze(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("crabking_feeze2hm")
    fx.crab = inst
    fx.Transform:SetPosition(x, y, z)
    local scale = 0.75 + Remap(inst.gemcount.blue or 0, 0, 9, 0, 1.55)
    fx.Transform:SetScale(scale, scale, scale)
    inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/magic_LP", "crabmagic")
    clearboilingwater(inst)
end

-- 检查帝王蟹冰冻条件
local function checkcrabkingfreeze(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 16, nil, nil, {"crabking_spellgenerator", "CLASSIFIED", "crabking"})
    
    for index, ent in ipairs(ents) do
        if ent and ent:IsValid() then
            if ent.prefab == "crabking_feeze2hm" or (ent.prefab == "boiling_water_spawner" and ent ~= inst) then
                inst:Remove()
            end
        end
    end
end

AddPrefabPostInit("boiling_water_spawner", function(inst)
    if not TheWorld.ismastersim then return end
    
    if not inst.components.inventoryitem then
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem.pushlandedevents = false
    end
    
    inst:DoTaskInTime(0, checkcrabkingfreeze)
end)



