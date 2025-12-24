local HIgniter = Class(function(self, inst)
    self.inst = inst

    self.can_ignite = true
    self.ignition_level = 0
    self.cooldown_time = 10
    self.ignition_threshold = 9
end)

function HIgniter:SetIgnitionThreshold(num)
    self.ignition_threshold = num
end

function HIgniter:SetCooldownTime(time)
    self.cooldown_time = time
end

function HIgniter:AddIgnitionLevel(num)
    self.ignition_level = self.ignition_level + num
    if self.ignition_level >= self.ignition_threshold then
        self:Ignite()
    end
end

function HIgniter:Ignite(target)
    target = target or self.inst.components.combat.target
    if self.can_ignite and target and target.components.burnable and not target.components.burnable:IsBurning() then
        target.components.burnable:Ignite(true, self.inst, self.inst)

        local x, y, z = target.Transform:GetWorldPosition()
        for i = 1, 5 + math.random(3) do
            local wheat = SpawnPrefab("hmr_igniter_item")
            if wheat ~= nil then
                wheat.Transform:SetPosition(x, 2 + math.random(2), z)

                local theta = math.random() * TWOPI
                local r = 5 + math.random() * 3
                local act_pos = Vector3(x + r * math.cos(theta), 0, z + r * math.sin(theta))
                wheat.components.complexprojectile:Launch(act_pos, self.inst)

                local spark = SpawnPrefab("hmr_igniter_fx")
                spark.entity:SetParent(wheat.entity)
                spark.entity:AddFollower()
                spark.Follower:FollowSymbol(wheat.GUID, "flames", 0, 0, 0)
            end
        end
        self.can_ignite = false
        self.inst:DoTaskInTime(self.cooldown_time, function()
            self.can_ignite = true
        end)
    end
    self.ignition_level = 0
end

return HIgniter