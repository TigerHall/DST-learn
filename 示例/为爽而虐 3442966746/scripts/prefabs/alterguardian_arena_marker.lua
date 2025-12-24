-- 天体竞技场持久化标记实体，用于保存竞技场的位置
local function UpdateNetvars(inst)
    if inst._updatenetvarstask ~= nil then
        inst._updatenetvarstask:Cancel()
        inst._updatenetvarstask = nil
    end

    local _world = TheWorld
    local floor_helper = _world.net and _world.net.components.alterguardian_floor_helper2hm
    if not floor_helper then
        inst._updatenetvarstask = inst:DoTaskInTime(0, UpdateNetvars)
        return
    end

    -- 向 floor_helper 注册
    floor_helper:TryToSetMarker(inst)
    
    -- 向 arena_manager 注册
    local arena_manager = _world.components.alterguardian_arena_manager2hm
    if arena_manager then
        arena_manager:TryToSetMarker(inst)
    end
end

local function OnSave(inst, data)
    -- 保存竞技场状态信息
    data.arena_radius = inst._arena_radius
    data.battle_phase = inst._battle_phase
end

local function OnLoad(inst, data)
    if data then
        inst._arena_radius = data.arena_radius or 28
        inst._battle_phase = data.battle_phase or 0
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    -- 非网络实体，但会持久化保存

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("alterguardian_arena_marker")

    if not TheWorld.ismastersim then
        -- 客户端不需要这个实体
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst._arena_radius = 28
    inst._battle_phase = 0

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, UpdateNetvars)

    return inst
end

return Prefab("alterguardian_arena_marker", fn)
