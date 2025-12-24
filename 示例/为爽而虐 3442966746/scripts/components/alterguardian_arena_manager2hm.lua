-- 管理竞技场状态的组件，联合floor_helper调动arenawall和collsion生成竞技场

--------------------------------------------------------------------------
-- 竞技场状态
--------------------------------------------------------------------------

local STATES = {
    INACTIVE = 0,       -- 未激活
    PHASE1 = 1,         -- 一阶段战斗
    PHASE2 = 2,         -- 二阶段战斗
    PHASE3 = 3,         -- 三阶段战斗
    DEFEATED = 4,       -- 击败
}

return Class(function(self, inst)

local _world = TheWorld
local _map = _world.Map

self.inst = inst

--------------------------------------------------------------------------
-- 组件状态
--------------------------------------------------------------------------

self.state = STATES.INACTIVE
self.STATES = STATES
self.WALLSPOTS = deepcopy(ALTERGUARDIAN_ARENA_COLLISION_DATA)

self.boss = nil                     -- 当前boss实例
self.marker = nil                   -- 竞技场标记（boss本身）
self.collision_barrier = nil        -- 碰撞墙
self.oneway_barrier = nil           -- 单向墙

self.barrier_up = false             -- 结界是否激活

--------------------------------------------------------------------------
-- 状态管理
--------------------------------------------------------------------------

function self:SetState(new_state)
    if not TheWorld.ismastersim then
        return
    end
    
    if self.state == new_state then
        return
    end
    
    local old_state = self.state
    self.state = new_state

    -- 发送状态改变事件
    self.inst:PushEvent("arena_state_changed", {old_state = old_state, new_state = new_state})
    
    self:UpdateFloorHelper()
end

function self:GetState()
    return self.state
end

function self:IsInBattle()
    return self.state == STATES.PHASE1 or self.state == STATES.PHASE2 or self.state == STATES.PHASE3
end

function self:GetPhase()
    if self.state == STATES.PHASE1 then return 1
    elseif self.state == STATES.PHASE2 then return 2
    elseif self.state == STATES.PHASE3 then return 3
    else return 0 end
end

function self:SetPhase(phase)
    if phase == 1 then
        self:SetState(STATES.PHASE1)
    elseif phase == 2 then
        self:SetState(STATES.PHASE2)
    elseif phase == 3 then
        self:SetState(STATES.PHASE3)
    end
end

function self:GetStateString()
    for name, id in pairs(self.STATES) do
        if self.state == id then
            return name
        end
    end
    return "UNKNOWN"
end

--------------------------------------------------------------------------
-- Floor Helper 集成
--------------------------------------------------------------------------

function self:UpdateFloorHelper()
    -- 通过TheWorld.net访问网络组件
    local helper = _world.net and _world.net.components.alterguardian_floor_helper2hm
    
    if not helper then
       -- 网络组件可能未就绪,延迟重试
        if not self.updatehelperscheduled then
            self.updatehelperscheduled = true
            self.inst:DoTaskInTime(0.1, function()
                self.updatehelperscheduled = nil
                self:UpdateFloorHelper()
            end)
        end
        return
    end
    
    -- 更新结界状态
    if self.barrier_up ~= helper:IsBarrierUp() then
        helper:SetBarrierActive(self.barrier_up)
    end
end

function self:GetFloorHelper()
    return _world.net and _world.net.components.alterguardian_floor_helper2hm
end

--------------------------------------------------------------------------
-- 标记管理
--------------------------------------------------------------------------

self.OnRemove_Marker = function(marker, data)
    self.marker = nil
    if not self.boss_defeat_processing then
        self:OnMarkerRemoved()
    end
end

function self:OnMarkerRemoved()
    self:CleanupArena()
end

function self:TryToSetMarker(marker_inst)
    if self.marker then
        if self.marker == marker_inst then
            return true
        end
        if marker_inst ~= self.boss then 
            marker_inst:Remove()
        end
        return false
    end
    
    self.marker = marker_inst
    if marker_inst ~= self.boss then
        marker_inst:ListenForEvent("onremove", self.OnRemove_Marker)
    end
    
    local helper = self:GetFloorHelper()
    if helper then
        if marker_inst.Transform then
            local x, y, z = marker_inst.Transform:GetWorldPosition()
            helper.arena_active:set(true)
            helper.arena_origin_x:set(x)
            helper.arena_origin_z:set(z)
        end
    end
    
    return true
end

function self:GetMarker()
    return self.marker
end

function self:GetArenaCenter()
    if self.marker and self.marker:IsValid() then
        return self.marker.Transform:GetWorldPosition()
    end
    
    local helper = self:GetFloorHelper()
    if helper and helper.GetArenaOrigin then
        local x, z = helper:GetArenaOrigin()
        if x and z then
            return x, 0, z
        end
    end
    
    return nil, nil, nil
end

--------------------------------------------------------------------------
-- Boss 管理
--------------------------------------------------------------------------

self.OnRemove_Boss = function(boss, data)
    -- 忽略暗影分身的移除事件
    if boss:HasTag("swc2hm") or boss:HasTag("skill_shadow2hm") then
        return
    end
    
    local boss_prefab = boss and boss.prefab
    
    -- 只有当移除的是当前追踪的Boss时才清空引用
    if self.boss == boss then
        self.boss = nil
        self:OnBossRemoved(boss_prefab)
    end
end

function self:OnBossRemoved(boss_prefab)
    -- 只在三阶段Boss被移除且不是因为战斗胜利时触发
    if self.state == STATES.PHASE3 and boss_prefab == "alterguardian_phase3" then
        -- 检查是否有真正的三阶段Boss存活
        local real_boss_exists = false
        local x, y, z = 0, 0, 0
        if self.marker and self.marker:IsValid() then
            x, y, z = self.marker.Transform:GetWorldPosition()
        end
        
        local ents = TheSim:FindEntities(x, y, z, 100, {"alterguardian_phase3"}, {"swc2hm", "skill_shadow2hm"})
        for _, ent in ipairs(ents) do
            if ent:IsValid() and not ent:HasTag("swc2hm") and not ent:HasTag("skill_shadow2hm") then
                real_boss_exists = true
                -- 重新追踪这个Boss
                self:TrackBoss(ent)
                break
            end
        end
        
        if not real_boss_exists then
            self:OnBossDefeated()
        end
    end
end

function self:TrackBoss(boss)
    if not TheWorld.ismastersim then return end
    
    -- 不追踪暗影分身
    if boss:HasTag("swc2hm") or boss:HasTag("skill_shadow2hm") then
        return
    end
    
    if self.boss then
        self.boss:RemoveEventCallback("onremove", self.OnRemove_Boss)
    end
    
    self.boss = boss
    boss:ListenForEvent("onremove", self.OnRemove_Boss)
end

function self:UntrackBoss()
    if not TheWorld.ismastersim then
        return
    end
    
    if self.boss then
        self.boss:RemoveEventCallback("onremove", self.OnRemove_Boss)
        self.boss = nil
    end
end

function self:GetBoss()
    return self.boss
end

function self:IsBossActive()
    return self.boss ~= nil and self.boss:IsValid() and 
           self.boss.components.health and not self.boss.components.health:IsDead()
end

function self:OnBossDefeated()
    if not TheWorld.ismastersim then return end

    if self.boss_defeat_processing then return end

    self.boss_defeat_processing = true
    
    if self.marker and self.marker == self.boss then
        self.marker = nil
    end

    self:LowerBarrier()
    
    -- 清除竞技场冰面
    self:DestroyArenaIceTiles()
    
    self:SetState(STATES.DEFEATED)
 
    self.inst:DoTaskInTime(0, function() 
        self.boss_defeat_processing = nil  -- 重置标记
    end)
end

--------------------------------------------------------------------------
-- 竞技场冰面管理
--------------------------------------------------------------------------

-- 设置冰面数据（由 alterguardian.lua 调用）
function self:SetArenaIceTiles(tiles)
    self.arena_ice_tiles = tiles
end

-- 获取冰面数据
function self:GetArenaIceTiles()
    return self.arena_ice_tiles
end

-- 检查是否已有冰面
function self:HasArenaIceTiles()
    return self.arena_ice_tiles ~= nil and #self.arena_ice_tiles > 0
end

-- 清除竞技场冰面（从外圈到内圈分批移除，避免卡顿）
function self:DestroyArenaIceTiles()
    if not self.arena_ice_tiles then return end
    
    local oceanicemanager = _world.components.oceanicemanager
    if not oceanicemanager then 
        self.arena_ice_tiles = nil
        return 
    end
    
    -- 获取竞技场中心瓦片坐标
    local cx, _, cz = self:GetArenaCenter()
    if not cx then 
        -- 无法获取中心，直接静默移除所有冰面
        for _, pos in ipairs(self.arena_ice_tiles) do
            if pos and pos.x and pos.y then
                local dx, _, dz = _map:GetTileCenterPoint(pos.x, pos.y)
                if dx then
                    oceanicemanager:DestroyIceAtPoint(dx, 0, dz, {silent = true})
                end
            end
        end
        self.arena_ice_tiles = nil
        return
    end
    
    local center_tile_x, center_tile_y = _map:GetTileCoordsAtPoint(cx, 0, cz)
    
    -- 按到中心距离分组（从远到近）
    local tiles_by_distance = {}
    local max_dist = 0
    
    for _, pos in ipairs(self.arena_ice_tiles) do
        if pos and pos.x and pos.y then
            local dx = pos.x - center_tile_x
            local dy = pos.y - center_tile_y
            local dist = math.floor(math.sqrt(dx * dx + dy * dy))
            max_dist = math.max(max_dist, dist)
            
            tiles_by_distance[dist] = tiles_by_distance[dist] or {}
            table.insert(tiles_by_distance[dist], pos)
        end
    end
    
    -- 从外圈到内圈移除，每圈间隔一定时间
    local delay_per_ring = 2 * FRAMES  -- 每圈间隔2帧
    local tiles_per_batch = 8  -- 每批最多处理8个瓦片
    
    local batch_delay = 0
    for dist = max_dist, 0, -1 do
        local tiles = tiles_by_distance[dist]
        if tiles and #tiles > 0 then
            -- 将同一距离的瓦片分成多批
            for batch_start = 1, #tiles, tiles_per_batch do
                local batch_end = math.min(batch_start + tiles_per_batch - 1, #tiles)
                local current_delay = batch_delay
                
                inst:DoTaskInTime(current_delay, function()
                    if oceanicemanager then
                        for i = batch_start, batch_end do
                            local pos = tiles[i]
                            if pos then
                                local dx, _, dz = _map:GetTileCenterPoint(pos.x, pos.y)
                                if dx then
                                    -- silent = true 防止生成冰船和掉落物
                                    oceanicemanager:DestroyIceAtPoint(dx, 0, dz, {silent = true})
                                end
                            end
                        end
                    end
                end)
                
                batch_delay = batch_delay + FRAMES
            end
            batch_delay = batch_delay + delay_per_ring
        end
    end
    
    self.arena_ice_tiles = nil
end

--------------------------------------------------------------------------
-- 重置Boss血量
function self:DoResetBossHealth()
    if not self.boss or not self.boss:IsValid() then
        return
    end
    
    if self.boss.components.health and not self.boss.components.health:IsDead() then
        self.boss.components.health:SetPercent(1)
        self.boss:PushEvent("alterguardian_health_reset")
        _world:PushEvent("alterguardian_arena_reset")
    end
end

-- 扫描竞技场内是否有存活玩家
function self:ScanAlivePlayers()
    local cx, _, cz = self:GetArenaCenter()
    if not cx then return 0 end
    
    local alive_count = 0
    for _, player in ipairs(AllPlayers) do
        local x, _, z = player.Transform:GetWorldPosition()
        local inarena = _map:IsPointInAlterguardianArena(x, 0, z)
        
        if inarena then
            local isalive = not player:HasTag("playerghost") and 
                           player.components.health and 
                           not player.components.health:IsDead()
            if isalive then
                alive_count = alive_count + 1
            end
        end
    end
    
    return alive_count
end

-- 定时扫描任务
function self:DoPlayerScan()
    if not self.barrier_up or not self:IsInBattle() then
        self.no_player_timer = nil  
        return
    end
    
    local alive_count = self:ScanAlivePlayers()
    
    if alive_count == 0 then
        if not self.no_player_timer then
            self.no_player_timer = GetTime()
        elseif GetTime() - self.no_player_timer >= 3 then
            -- 3秒内持续没有玩家，回满血
            self:DoResetBossHealth()
            self.no_player_timer = nil
        end
    else
        self.no_player_timer = nil
    end
end

-- 启动玩家扫描
function self:StartPlayerScan()
    self:StopPlayerScan()  
    
    self.player_scan_task = self.inst:DoPeriodicTask(3, function()
        self:DoPlayerScan()
    end)
end

-- 停止玩家扫描（结界降下时调用）
function self:StopPlayerScan()
    if self.player_scan_task then
        self.player_scan_task:Cancel()
        self.player_scan_task = nil
    end
end

--------------------------------------------------------------------------
-- 竞技场清理
--------------------------------------------------------------------------

function self:DestroyEntitiesInBarrier()
    local cx, cy, cz = self:GetArenaCenter()
    if not cx then
        return
    end
    
    local radius = 28
    local DESTROY_TAGS = {"structure"}
    local NO_DESTROY_TAGS = {"player", "irreplaceable", "INLIMBO", "FX", "NOCLICK"}
    
    local ents = TheSim:FindEntities(cx, cy, cz, radius, DESTROY_TAGS, NO_DESTROY_TAGS)
    
    for _, ent in ipairs(ents) do
        if ent:IsValid() and ent ~= self.marker then
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            
            local dx = ex - cx
            local dz = ez - cz
            if (dx * dx + dz * dz) <= radius * radius then
                SpawnPrefab("collapse_small").Transform:SetPosition(ex, ey, ez)

                if ent.components.workable and ent.components.workable:CanBeWorked() then
                    ent.components.workable:Destroy(self.inst)
                end
            end
        end
    end
end

-- 清理竞技场状态
function self:CleanupArena()
    self:LowerBarrier()
    self:UntrackBoss()

    if self.boss and self.boss:IsValid() then 
        self.boss:Remove() 
    end
    
    self:SetState(STATES.INACTIVE)
end

--------------------------------------------------------------------------
-- 激活战斗
--------------------------------------------------------------------------

function self:CanActivateBattle()
    if self:IsInBattle() then
        return false, "战斗已在进行中"
    end
    
    if not self:IsBossActive() then
        return false, "Boss不存在或已死亡"
    end
    
    return true
end

function self:ActivateBattle(phase)
    if not TheWorld.ismastersim then return false end
    
    local can_activate, reason = self:CanActivateBattle()
    if not can_activate then return false, reason end
    
    -- 设置boss为marker
    if self.boss then
        self:TryToSetMarker(self.boss)
    end
    
    self:RaiseBarrier()
    
    self:SetPhase(phase or 1)
    
    self.inst:PushEvent("battle_activated", {boss = self.boss, phase = phase or 1})
    
    return true
end

--------------------------------------------------------------------------
-- 调试
--------------------------------------------------------------------------

function self:DebugString()
    return string.format(
        "State: %s | Boss: %s | Barrier: %s",
        self:GetStateString(),
        self.boss and self.boss.prefab or "nil",
        tostring(self.barrier_up)
    )
end

--------------------------------------------------------------------------
-- 结界管理
--------------------------------------------------------------------------

function self:RaiseBarrier()
    if not TheWorld.ismastersim then return end
    
    if self.barrier_up then return end

    self.barrier_up = true
    
    -- 更新floor_helper网络状态,确保在生成wall前客户端已知道竞技场激活
    self:UpdateFloorHelper()
    
    -- 等待一帧确保网络变量同步到客户端
    self.inst:DoTaskInTime(0, function()
        if not self.inst:IsValid() or not self.barrier_up then
            return
        end
        
        self:SpawnBarriers()

        self:DestroyEntitiesInBarrier()

        self:StartPlayerScan()
        
        self.inst:PushEvent("barrier_raised")
    end)
end

function self:LowerBarrier()
    if not TheWorld.ismastersim then
        return
    end
    
    if not self.barrier_up then
        return
    end

    self.barrier_up = false
    
    self:StopPlayerScan()
    
    self:RemoveBarriers()
    
    self:UpdateFloorHelper()
    
    self.inst:PushEvent("barrier_lowered")
end

function self:IsBarrierUp()
    return self.barrier_up
end

--------------------------------------------------------------------------
-- 结界生成和移除，BuildWagpunkArenaMesh
local function BuildCircleCollisionData(radius, segments)
    local data = {}
    local angle_step = (2 * math.pi) / segments
    
    -- 生成圆周上的点
    for i = 0, segments - 1 do
        local angle = i * angle_step
        local x = radius * math.cos(angle)
        local z = radius * math.sin(angle)
        table.insert(data, {x, 0, z})
    end
    
    return data
end

function self:SpawnBarriers()
    if not TheWorld.ismastersim then
        return
    end
    
    local cx, cy, cz = self:GetArenaCenter()
    if not cx then
        return
    end
    -- 内层碰撞墙
    if not self.collision_barrier or not self.collision_barrier:IsValid() then
        self.collision_barrier = SpawnPrefab("alterguardian_arena_collision")
        if self.collision_barrier then
            self.collision_barrier.Transform:SetPosition(cx, cy, cz)
        end
    end
    
    -- 单向墙
    if not self.oneway_barrier or not self.oneway_barrier:IsValid() then
        self.oneway_barrier = SpawnPrefab("alterguardian_arena_collision_oneway")
        if self.oneway_barrier then
            self.oneway_barrier.Transform:SetPosition(cx, cy, cz)
            self.oneway_barrier._guardian = self.boss
        end
    end
    
    -- 墙体节点
    self:SpawnCageWalls(cx, cy, cz)
end

-- 墙体生成函数
function self:SpawnCageWalls(cx, cy, cz)
    if not TheWorld.ismastersim then return end
    
    if self.arena_walls and #self.arena_walls > 0 then return end
    
    self.arena_walls = {}
    
    local wallspots = self.WALLSPOTS
    local segments = #wallspots
    local start_index = math.random(1, segments)  -- 随机起点
    
    -- 成对生成：从起点开始，交替往顺时针和逆时针方向生成
    for i = 0, segments - 1 do
        self.inst:DoTaskInTime(i * 0.4, function()
            if not self.inst:IsValid() or not self.barrier_up then
                return
            end
            
            local index
            if i == 0 then
                index = start_index
            elseif i % 2 == 1 then
                index = start_index + math.ceil(i / 2)
            else
                index = start_index - (i / 2)
            end
            
            -- 确保索引在有效范围内
            index = ((index - 1) % segments) + 1
            
            local spot = wallspots[index]
            local wx = cx + spot[1]
            local wz = cz + spot[2]
            local rotation = math.floor(spot[3] / 90) * 90  -- 对齐到90度
            local sfxlooper = spot[4]                       -- 4个音效循环
            
            -- 生成墙体
            local wall = SpawnPrefab("alterguardian_arenawall")
            if wall then
                wall.Transform:SetPosition(wx, 0, wz)
                wall.Transform:SetRotation(rotation)
                wall.AnimState:SetScale(1.5, 1.5)
                wall.persists = false
                wall._arena_guardian = self.boss
                if sfxlooper then wall.sfxlooper = true end

                wall:DoTaskInTime(0.5, function()
                    if wall:IsValid() and self.barrier_up then
                        if wall.ExtendWall then
                            wall:ExtendWall()
                        end
                    end
                end)
                
                table.insert(self.arena_walls, wall)
            end
        end)
    end
end

function self:RemoveBarriers()
    if not TheWorld.ismastersim then
        return
    end
    
    -- 移除视觉墙体 
    local total_walls = self.arena_walls and #self.arena_walls or 0
    local wall_remove_time = 0.5  -- meteor_pst动画大约0.5秒
    local barrier_remove_delay = total_walls * 0.15 + wall_remove_time + 0.2
    
    -- 延迟移除碰撞墙，等视觉墙体收起后移除
    self.inst:DoTaskInTime(barrier_remove_delay, function()
        -- 移除碰撞墙
        if self.collision_barrier and self.collision_barrier:IsValid() then
            self.collision_barrier:Remove()
        end
        self.collision_barrier = nil
        
        -- 移除单向墙
        if self.oneway_barrier and self.oneway_barrier:IsValid() then
            self.oneway_barrier:Remove()
        end
        self.oneway_barrier = nil
    end)
    
    -- 移除视觉墙体
    if self.arena_walls then
        local walls = self.arena_walls
        
        for i, wall in ipairs(walls) do
            if wall and wall:IsValid() then
                -- 逐个收缩
                local retract_delay = (i - 1) * 0.15
                wall:DoTaskInTime(retract_delay, function()
                    if wall:IsValid() then
                        if wall.RetractWall then
                            wall:RetractWall()
                        end
                        wall:ListenForEvent("animover", wall.Remove)
                    end
                end)
            end
        end
        self.arena_walls = nil
    end
end

--------------------------------------------------------------------------
-- 竞技场清理
--------------------------------------------------------------------------

function self:DestroyEntitiesInBarrier()
    local cx, cy, cz = self:GetArenaCenter()
    if not cx then
        return
    end
    
    local radius = 28
    local DESTROY_TAGS = {"structure"}
    local NO_DESTROY_TAGS = {"player", "irreplaceable", "INLIMBO", "FX", "NOCLICK"}
    
    local ents = TheSim:FindEntities(cx, cy, cz, radius, DESTROY_TAGS, NO_DESTROY_TAGS)
    
    for _, ent in ipairs(ents) do
        if ent:IsValid() and ent ~= self.marker then
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            
            local dx = ex - cx
            local dz = ez - cz
            if (dx * dx + dz * dz) <= radius * radius then
                SpawnPrefab("collapse_small").Transform:SetPosition(ex, ey, ez)

                if ent.components.workable and ent.components.workable:CanBeWorked() then
                    ent.components.workable:Destroy(self.inst)
                end
            end
        end
    end
end

-- 清理竞技场状态
function self:CleanupArena()
    self:LowerBarrier()
    self:UntrackBoss()

    if self.boss and self.boss:IsValid() then 
        self.boss:Remove() 
    end
    
    self:SetState(STATES.INACTIVE)
end

--------------------------------------------------------------------------
-- 激活战斗
--------------------------------------------------------------------------

function self:CanActivateBattle()
    if self:IsInBattle() then
        return false, "战斗已在进行中"
    end
    
    if not self:IsBossActive() then
        return false, "Boss不存在或已死亡"
    end
    
    return true
end

function self:ActivateBattle(phase)
    if not TheWorld.ismastersim then return false end
    
    local can_activate, reason = self:CanActivateBattle()
    if not can_activate then return false, reason end
    
    -- 设置boss为marker
    if self.boss then
        self:TryToSetMarker(self.boss)
    end
    
    self:RaiseBarrier()
    
    self:SetPhase(phase or 1)
    
    self.inst:PushEvent("battle_activated", {boss = self.boss, phase = phase or 1})
    
    return true
end

--------------------------------------------------------------------------
-- 保存和加载
--------------------------------------------------------------------------

function self:OnSave()
    local data = {
        state = self.state,
        barrier_up = self.barrier_up,
        arena_ice_tiles = self.arena_ice_tiles,  -- 保存冰面坐标数据
    }
    local ents = {}
    
    -- 保存 marker 实体的 GUID
    if self.marker and self.marker:IsValid() then
        data.marker = self.marker.GUID
        table.insert(ents, self.marker.GUID)
        
        -- 同步战斗阶段到 marker
        if self.marker._battle_phase ~= nil then
            self.marker._battle_phase = self:GetPhase()
        end
    end

    -- 保存 Boss 的 GUID,用于LoadPostPass恢复追踪
    if self.boss and self.boss:IsValid() then 
        data.boss = self.boss.GUID
        data.boss_prefab = self.boss.prefab
        table.insert(ents, self.boss.GUID)
    end
    
    -- 墙体在 LoadPostPass 中重新生成
    
    return data, ents
end

function self:OnLoad(data)
    if data then
        self.state = data.state or STATES.INACTIVE
        self.barrier_up = data.barrier_up == true
        self._saved_boss_prefab = data.boss_prefab
        self._saved_ice_tiles = data.arena_ice_tiles  -- 临时存储，在LoadPostPass中恢复
        
        -- 标记为从存档恢复
        self._restored_from_save = true
    end
end

function self:LoadPostPass(newents, data)
    if not data then
        return
    end
    
    -- 通过 GUID 恢复 marker 引用
    local marker_restored = false
    if data.marker and newents and newents[data.marker] then
        local marker = newents[data.marker].entity
        if marker and marker:IsValid() then
            self.marker = marker
            marker:ListenForEvent("onremove", self.OnRemove_Marker)
            marker_restored = true
        end
    end
    
    -- 如果 GUID 恢复失败，搜索世界中的 marker 实体
    if not marker_restored then
        local markers = TheSim:FindEntities(0, 0, 0, 99999, {"alterguardian_arena_marker"})
        if markers and #markers > 0 then
            local marker = markers[1]
            if marker and marker:IsValid() then
                self.marker = marker
                marker:ListenForEvent("onremove", self.OnRemove_Marker)
                marker_restored = true
            end
        end
    end
    
    -- 同步更新 floor_helper 的网络变量
    if marker_restored and self.marker then
        local helper = self:GetFloorHelper()
        if helper then
            local x, y, z = self.marker.Transform:GetWorldPosition()
            helper.arena_active:set(true)
            helper.arena_origin_x:set(x)
            helper.arena_origin_z:set(z)
            helper.marker = self.marker
            if self.marker._arena_radius then
                helper.arena_radius:set(self.marker._arena_radius)
            end
        end
    end
    
    -- 通过 GUID 恢复 Boss 引用
    local boss_restored = nil
    if data.boss and newents and newents[data.boss] then
        local boss = newents[data.boss].entity
        if boss and boss:IsValid() and not boss:HasTag("swc2hm") and not boss:HasTag("skill_shadow2hm") then
            self:TrackBoss(boss)
            boss._arena_manager = self
            boss_restored = boss
        end
    end
    
    -- 清理临时数据
    self._saved_boss_prefab = nil
    
    self.inst:DoTaskInTime(0.5, function()
        if not self.inst:IsValid() then return end
        
        -- 如果在战斗中,恢复冰面数据引用
        if self:IsInBattle() and self._saved_ice_tiles and #self._saved_ice_tiles > 0 then
            self.arena_ice_tiles = self._saved_ice_tiles
            self._saved_ice_tiles = nil
        end
        
        -- 如果 Boss 存在但 marker 丢失,重新创建 marker
        if self:IsInBattle() and not marker_restored and self.boss and self.boss:IsValid() then
            local bx, by, bz = self.boss.Transform:GetWorldPosition()
            self:SpawnArenaMarker(bx, by, bz)
        end
        
        -- 如果结界在战斗中,重新生成墙体(碰撞墙不保存,需要重新生成)
        if self.barrier_up and self:IsInBattle() then
            -- 再次确保 helper 的网络变量已正确设置
            local helper = self:GetFloorHelper()
            if helper and self.marker and self.marker:IsValid() then
                local x, y, z = self.marker.Transform:GetWorldPosition()
                helper.arena_active:set(true)
                helper.arena_origin_x:set(x)
                helper.arena_origin_z:set(z)
                helper:SetBarrierActive(true)
            end
            
            -- 重新生成墙体(因为碰撞墙 persists = false)
            self:SpawnBarriers()
            self:StartPlayerScan()
        end
    end)
    
    -- 延迟清除恢复标记，让 Boss PostInit 有机会检测到
    self.inst:DoTaskInTime(2, function()
        self._restored_from_save = nil
    end)
end

-- 尝试恢复与现有Boss的连接（由 Boss PostInit 调用，仅用于存档恢复）
-- 返回 true 表示成功恢复了存档连接，false 表示这是新生成的 Boss
function self:TryRestoreConnection(boss)
    if not TheWorld.ismastersim then return false end
    
    -- 不追踪分身
    if boss:HasTag("swc2hm") or boss:HasTag("skill_shadow2hm") then
        return false
    end
    
    -- 如果不是从存档恢复，返回 false 让调用者处理新生成逻辑
    if not self._restored_from_save then
        return false
    end
    
    -- 检查是否已经在追踪这个 Boss
    if self.boss == boss then
        return true
    end
    
    -- 如果当前没有追踪 Boss，则追踪这个
    if not self.boss or not self.boss:IsValid() then
        self:TrackBoss(boss)
        boss._arena_manager = self
        
        -- 如果没有 marker，创建一个
        if not self.marker or not self.marker:IsValid() then
            local bx, by, bz = boss.Transform:GetWorldPosition()
            self:SpawnArenaMarker(bx, by, bz)
        end
        
        -- 根据 Boss 类型设置阶段
        if boss.prefab == "alterguardian_phase1" then
            if self.state ~= STATES.PHASE1 then
                self:SetPhase(1)
            end
        elseif boss.prefab == "alterguardian_phase2" then
            if self.state ~= STATES.PHASE2 then
                self:SetPhase(2)
            end
        elseif boss.prefab == "alterguardian_phase3" then
            if self.state ~= STATES.PHASE3 then
                self:SetPhase(3)
            end
        end
        
        -- 如果存档时结界是激活状态，恢复结界
        if self.barrier_up and not self.collision_barrier then
            self:SpawnBarriers()
            self:StartPlayerScan()
        end
        
        return true
    end
    
    return false
end

-- 检查是否从存档恢复
function self:IsRestoredFromSave()
    return self._restored_from_save == true
end

-- 生成竞技场 marker（由 Boss 召唤逻辑调用）
function self:SpawnArenaMarker(x, y, z)
    if not TheWorld.ismastersim then return nil end
    
    -- 如果已经有 marker 了，不重复生成
    if self.marker and self.marker:IsValid() then
        return self.marker
    end
    
    local marker = SpawnPrefab("alterguardian_arena_marker")
    if marker then
        marker.Transform:SetPosition(x, y, z)
        marker._arena_radius = 28
        marker._battle_phase = self:GetPhase()
        
        -- 设置引用和监听
        self.marker = marker
        marker:ListenForEvent("onremove", self.OnRemove_Marker)
        
        -- 立即设置 floor_helper 的网络变量（不等待 marker 的 UpdateNetvars）
        local helper = self:GetFloorHelper()
        if helper then
            helper.arena_active:set(true)
            helper.arena_origin_x:set(x)
            helper.arena_origin_z:set(z)
            helper.arena_radius:set(28)
            helper.marker = marker
        end
    end
    
    return marker
end

-- 移除竞技场 marker（Boss 击败后调用）
function self:RemoveArenaMarker()
    if self.marker and self.marker:IsValid() then
        self.marker:Remove()
    end
    self.marker = nil
end

end)