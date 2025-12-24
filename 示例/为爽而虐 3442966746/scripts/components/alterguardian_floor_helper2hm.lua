
-- 负责竞技场区域判定和网络同步的组件

return Class(function(self, inst)

local _world = TheWorld
self.inst = inst

--------------------------------------------------------------------------
-- 网络变量，用于客户端同步
--------------------------------------------------------------------------

self.arena_active = net_bool(self.inst.GUID, "alterguardian_floor_helper2hm.arena_active")
self.barrier_active = net_bool(self.inst.GUID, "alterguardian_floor_helper2hm.barrier_active")
self.arena_origin_x = net_float(self.inst.GUID, "alterguardian_floor_helper2hm.arena_origin_x")
self.arena_origin_z = net_float(self.inst.GUID, "alterguardian_floor_helper2hm.arena_origin_z")
self.arena_radius = net_float(self.inst.GUID, "alterguardian_floor_helper2hm.arena_radius")

self.arena_active:set(false)
self.barrier_active:set(false)
self.arena_origin_x:set(0)
self.arena_origin_z:set(0)
self.arena_radius:set(28)

self.marker = nil

--------------------------------------------------------------------------
-- 客户端和服务器端通用函数
--------------------------------------------------------------------------

-- 检查点是否在竞技场内（圆形区域）
function self:IsPointInArena_Calculation(x, z, thickness)
    local ax, az = self.arena_origin_x:value(), self.arena_origin_z:value()
    local radius = self.arena_radius:value()
    
    local dx = x - ax
    local dz = z - az
    local dist_sq = dx * dx + dz * dz

    local radius_with_thickness = radius + thickness
    return dist_sq <= (radius_with_thickness * radius_with_thickness)
end

function self:IsPointInArena(x, y, z)
    if not self.arena_active:value() then
        return false
    end
    return self:IsPointInArena_Calculation(x, z, 0)
end

-- 获取中心坐标
function self:GetArenaOrigin()
    if not self.arena_active:value() then
        return nil, nil
    end
    return self.arena_origin_x:value(), self.arena_origin_z:value()
end

-- 获取半径
function self:GetArenaRadius()
    if not self.arena_active:value() then
        return nil
    end
    return self.arena_radius:value()
end

function self:IsBarrierUp()
    return self.barrier_active:value()
end

function self:IsArenaActive()
    return self.arena_active:value()
end

--------------------------------------------------------------------------
-- 服务器端函数
--------------------------------------------------------------------------

self.OnRemove_Marker = function(ent, data)
    self.marker = nil
    self.arena_active:set(false)
    self.barrier_active:set(false)
    self.arena_origin_x:set(0)
    self.arena_origin_z:set(0)
end

-- 尝试设置竞技场标记，由 marker prefab 的 UpdateNetvars 调用
-- 这是主要的注册入口，marker 实体加载后会自动调用这个函数
function self:TryToSetMarker(marker_inst)
    if not TheWorld.ismastersim then
        return false
    end
    
    if self.marker then
        if self.marker ~= marker_inst then
            marker_inst:Remove()
        end
        return false
    end
    
    self.marker = marker_inst
    local x, y, z = marker_inst.Transform:GetWorldPosition()
    
    -- 激活竞技场
    self.arena_active:set(true)
    self.arena_origin_x:set(x)
    self.arena_origin_z:set(z)
    
    -- 从 marker 获取半径
    if marker_inst._arena_radius then
        self.arena_radius:set(marker_inst._arena_radius)
    end
    
    marker_inst:ListenForEvent("onremove", self.OnRemove_Marker)
    
    return true
end

-- 设置半径
function self:SetArenaRadius(radius)
    if not TheWorld.ismastersim then
        return
    end
    self.arena_radius:set(radius or 28)
    -- 同步到 marker
    if self.marker and self.marker:IsValid() then
        self.marker._arena_radius = radius or 28
    end
end

-- 激活/关闭结界
function self:SetBarrierActive(active)
    if not TheWorld.ismastersim then
        return
    end
    self.barrier_active:set(active == true)
end

function self:GetMarker()
    return self.marker
end


end)
