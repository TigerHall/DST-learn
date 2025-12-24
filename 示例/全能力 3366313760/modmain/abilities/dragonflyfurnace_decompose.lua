local Utils = require("aab_utils/utils")

local function CheckSpawnedLoot(loot)
    if loot.components.inventoryitem ~= nil then
        loot.components.inventoryitem:TryToSink()
    else
        local lootx, looty, lootz = loot.Transform:GetWorldPosition()
        if ShouldEntitySink(loot, true) or TheWorld.Map:IsPointNearHole(Vector3(lootx, 0, lootz)) then
            SinkEntity(loot)
        end
    end
end

local function SpawnLootPrefab(inst, lootprefab)
    if lootprefab == nil then
        return
    end

    local loot = SpawnPrefab(lootprefab)
    if loot == nil then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    if loot.Physics ~= nil then
        local angle = math.random() * TWOPI
        loot.Physics:SetVel(2 * math.cos(angle), 10, 2 * math.sin(angle))

        if inst.Physics ~= nil then
            local len = loot:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0)
            x = x + math.cos(angle) * len
            z = z + math.sin(angle) * len
        end

        loot:DoTaskInTime(1, CheckSpawnedLoot)
    end

    loot.Transform:SetPosition(x, y, z)

    loot:PushEvent("on_loot_dropped", { dropper = inst })

    return loot
end

-- 拆解魔杖逻辑
local function destroystructure(inst, target)
    local recipe = AllRecipes[target.prefab]
    if recipe == nil or FunctionOrValue(recipe.no_deconstruction, target) then
        --Action filters should prevent us from reaching here normally
        return false
    end

    target.Transform:SetPosition(inst.Transform:GetWorldPosition()) --先设置到箱子的位置，如果target是容器就直接掉出来

    local ingredient_percent =
        ((target.components.finiteuses ~= nil and target.components.finiteuses:GetPercent()) or
            (target.components.fueled ~= nil and target.components.inventoryitem ~= nil and target.components.fueled:GetPercent()) or
            (target.components.armor ~= nil and target.components.inventoryitem ~= nil and target.components.armor:GetPercent()) or
            1
        ) / recipe.numtogive

    --V2C: Can't play sounds on the staff, or nobody
    --     but the user and the host will hear them!

    -- If the target is a mimic, drop nightmarefuel instead of any of the recipe loot.
    if target.components.itemmimic then
        target.components.itemmimic:TurnEvil(inst) --把箱子传入不会报错吧
    else
        for i, v in ipairs(recipe.ingredients) do
            if string.sub(v.type, -3) ~= "gem" or string.sub(v.type, -11, -4) == "precious" then
                --V2C: always at least one in case ingredient_percent is 0%
                local amt = v.amount == 0 and 0 or math.max(1, math.ceil(v.amount * ingredient_percent))
                for _ = 1, amt do
                    SpawnLootPrefab(inst, v.type)
                end
            end
        end

        if target.components.inventory ~= nil then
            target.components.inventory:DropEverything()
        end

        if target.components.container ~= nil then
            target.components.container:DropEverything(nil, true)
        end

        if target.components.spawner ~= nil and target.components.spawner:IsOccupied() then
            target.components.spawner:ReleaseChild()
        end

        if target.components.occupiable ~= nil and target.components.occupiable:IsOccupied() then
            local item = target.components.occupiable:Harvest()
            if item ~= nil then
                item.Transform:SetPosition(target.Transform:GetWorldPosition())
                item.components.inventoryitem:OnDropped()
            end
        end

        if target.components.trap ~= nil then
            target.components.trap:Harvest()
        end

        if target.components.dryer ~= nil then
            target.components.dryer:DropItem()
        end

        if target.components.harvestable ~= nil then
            target.components.harvestable:Harvest()
        end

        if target.components.stewer ~= nil then
            target.components.stewer:Harvest()
        end

        if target.components.constructionsite ~= nil then
            target.components.constructionsite:DropAllMaterials()
        end

        if target.components.inventoryitemholder ~= nil then
            target.components.inventoryitemholder:TakeItem()
        end

        target:PushEvent("ondeconstructstructure", inst)

        if not target.no_delete_on_deconstruct then
            if target.components.stackable ~= nil then
                --if it's stackable we only want to destroy one of them.
                target.components.stackable:Get():Remove()
                if target:IsValid() then
                    destroystructure(inst, target) --堆叠物品一次性也分解了
                end
            else
                target:Remove()
            end
        end
    end

    return true
end

local function IncinerateBefore(self, doer)
    if self.inst.components.container then
        self.incinerate_doer = doer
        local issuc = false
        for _, v in ipairs(self.inst.components.container:ReferenceAllItems()) do
            issuc = destroystructure(self.inst, v) or issuc
        end

        if issuc then
            if self.onincineratefn ~= nil then
                self.onincineratefn(self.inst)
            end
            self.incinerate_doer = nil
            return { true }, true --只要有能拆解的东西，这次就不执行销毁
        end
        self.incinerate_doer = nil
    end
end

AddPrefabPostInit("dragonflyfurnace", function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.incinerator, "Incinerate", IncinerateBefore)
end)
