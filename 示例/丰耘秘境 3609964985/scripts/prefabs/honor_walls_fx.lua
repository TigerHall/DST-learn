local assets = {
    Asset("ANIM", "anim/lifeplant_fx.zip")
}

local function RunTo_life(inst)
    if inst.movingTarget == nil or not inst.movingTarget:IsValid() then
        if inst.taskMove ~= nil then
            inst.taskMove:Cancel()
            inst.taskMove = nil
        end
        inst:Remove()
    elseif inst._count >= 100 or inst:GetDistanceSqToInst(inst.movingTarget) <= inst.minDistanceSq then
        if inst.OnReachTarget ~= nil then
            inst.OnReachTarget()
        end
        if inst.taskMove ~= nil then
            inst.taskMove:Cancel()
            inst.taskMove = nil
        end
        inst:Remove()
    else --更新目标地点
        inst:ForceFacePoint(inst.movingTarget.Transform:GetWorldPosition())
        inst._count = inst._count + 1
    end
end

local function OnEntitySleep_life(inst)
    if inst.OnReachTarget ~= nil then
        inst.OnReachTarget()
    end
    if inst.taskMove ~= nil then
        inst.taskMove:Cancel()
        inst.taskMove = nil
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeGhostPhysics(inst, 1, 0.15)
    RemovePhysicsColliders(inst)

    inst:AddTag("flying")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBank("lifeplant_fx")
    inst.AnimState:SetBuild("lifeplant_fx")
    inst.AnimState:PlayAnimation("single"..math.random(1,3), true)
    inst.AnimState:SetMultColour(15/255, 180/255, 132/255, 1)
    inst.AnimState:SetScale(0.6, 0.6)
    inst.AnimState:SetLightOverride(0.8)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false
    inst.taskMove = nil
    inst.movingTarget = nil
    inst.OnReachTarget = nil
    inst.minDistanceSq = 1 --1.8*1.8+0.06
    inst._count = 0

    -- 添加移动组件
    inst:AddComponent("locomotor")
    -- 设置行走速度为2
    inst.components.locomotor.walkspeed = 20
    -- 设置奔跑速度为2
    inst.components.locomotor.runspeed = 20
    -- 禁用在爬行时触发的机制
    inst.components.locomotor:SetTriggersCreep(false)
    -- 禁用地面速度的倍增
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    -- 设置路径特性：可以忽略墙壁，允许在海洋中移动
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }

    inst:DoTaskInTime(0, function(inst)
        if inst.movingTarget == nil or not inst.movingTarget:IsValid() then
            inst:Remove()
        else
            inst:ForceFacePoint(inst.movingTarget.Transform:GetWorldPosition())
            inst.components.locomotor:WalkForward()
            inst.taskMove = inst:DoPeriodicTask(0.1, RunTo_life)
        end
    end)
    inst.OnEntitySleep = OnEntitySleep_life

    return inst
end

return Prefab("honor_walls_fx", fn, assets)