local function OnAttackOther(inst, data)
    local target = data and data.target
    if target and target:IsValid()
        and (target.components.health == nil or not target.components.health:IsDead() and not target:HasTag("structure") and not target:HasTag("wall"))
    then
        -- In combat, this is when we're just launching a projectile, so don't spawn a gestalt yet
        if data.weapon ~= nil and data.projectile == nil
            and (data.weapon.components.projectile ~= nil
                or data.weapon.components.complexprojectile ~= nil
                or data.weapon.components.weapon:CanRangedAttack()) then
            return
        end

        local x, y, z = target.Transform:GetWorldPosition()

        local gestalt = SpawnPrefab("alterguardianhat_projectile")
        local r = GetRandomMinMax(3, 5)
        local delta_angle = GetRandomMinMax(-90, 90)
        local angle = (inst:GetAngleToPoint(x, y, z) + delta_angle) * DEGREES
        gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
        gestalt:ForceFacePoint(x, y, z)
        gestalt:SetTargetPosition(Vector3(x, y, z))
        gestalt.components.follower:SetLeader(inst)
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onattackother", OnAttackOther)
end)
