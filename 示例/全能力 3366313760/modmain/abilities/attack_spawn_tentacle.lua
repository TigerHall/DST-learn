local ATTACK_SPAWN_TENTACLE = GetModConfigData("attack_spawn_tentacle") / 100

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function OnAttackOther(inst, data)
    if math.random() < ATTACK_SPAWN_TENTACLE and data and data.target then
        local target = data.target
        local pt
        if target ~= nil and target:IsValid() then
            pt = target:GetPosition()
        else
            pt = inst:GetPosition()
            target = nil
        end
        local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, NoHoles, false, true)
        if offset ~= nil then
            if inst.SoundEmitter then
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
            end
            local tentacle = SpawnPrefab("shadowtentacle")
            if tentacle ~= nil then
                tentacle.owner = inst
                tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                tentacle.components.combat:SetTarget(target)
            end
        end
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onattackother", OnAttackOther)
end)
