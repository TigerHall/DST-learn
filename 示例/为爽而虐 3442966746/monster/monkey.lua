-- local cooking = require "cooking"
-- local ingredients = cooking.ingredients
-- local function isfood(item)
--     if item.components.edible and (item.components.edible.foodtype == FOODTYPE.VEGGIE or item.components.edible.foodtype == FOODTYPE.BERRY) then return true end
--     local recipe = ingredients[item.prefab]
--     if recipe and recipe.tags and (recipe.tags.fruit or recipe.tags.veggie) then return true end
-- end

TUNING.MONKEY_RANGED_DAMAGE = TUNING.MONKEY_MELEE_DAMAGE / 2

-- local function OnCooldown(inst) inst._cdtask2hm = nil end
-- local MONKEY_TAGS = {"monkey"}
-- local function NotBlocked(pt) return not TheWorld.Map:IsGroundTargetBlocked(pt) end
-- local function OnBlocked(inst, data)
--     if inst._cdtask2hm == nil and inst:HasTag("nightmare") and data and data.attacker and data.attacker:IsValid() then
--         inst._cdtask2hm = inst:DoTaskInTime(.3, OnCooldown)
--         local pos = inst:GetPosition()
--         pos.y = 0
--         local x, y, z = inst.Transform:GetWorldPosition()
--         local attackerpos = data.attacker:GetPosition()
--         local monkeys = TheSim:FindEntities(x, y, z, 3, MONKEY_TAGS)
--         local teleport = false
--         for i, v in ipairs(monkeys) do
--             if not v:HasTag("player") and v.components.health and not v.components.health:IsDead() then
--                 if v.components.combat and not data.attacker:HasTag("monkey") then v.components.combat:SetTarget(data.attacker) end
--                 local theta = attackerpos ~= nil and v:GetAngleToPoint(attackerpos) or v.Transform:GetRotation()
--                 theta = (theta + 150 + math.random() * 60) * DEGREES
--                 local offs = FindWalkableOffset(pos, theta, math.random(8, 16), 8, false, true, NotBlocked, false, true) or
--                                  FindWalkableOffset(pos, theta, math.random(4, 8), 6, false, true, NotBlocked, false, true)
--                 if offs ~= nil then
--                     pos.x = pos.x + offs.x
--                     pos.z = pos.z + offs.z
--                 end
--                 v.Physics:Teleport(pos:Get())
--                 if v._cdtask2hm == nil then v._cdtask2hm = v:DoTaskInTime(.3, OnCooldown) end
--                 if attackerpos ~= nil then v:ForceFacePoint(attackerpos) end
--                 teleport = true
--             end
--         end
--         if teleport then SpawnPrefab("shadow_puff").Transform:SetPosition(x, y, z) end
--     end
-- end

local function OnCooldown(inst) inst._cdtask2hm = nil end
local MONKEY_TAGS = {"monkey"}
local function NotBlocked(pt) return not TheWorld.Map:IsGroundTargetBlocked(pt) end
local function OnBlocked(inst, data)
    if inst._cdtask2hm == nil and inst:HasTag("nightmare") and data and data.attacker and data.attacker:IsValid() then
        inst._cdtask2hm = inst:DoTaskInTime(.3, OnCooldown)
        local pos = inst:GetPosition()
        pos.y = 0
        local attackerpos = data.attacker:GetPosition()
        local teleport = false

        if inst.components.health and not inst.components.health:IsDead() and not (inst.sg and inst.sg:HasStateTag("attack")) then
            if inst.components.combat and not data.attacker:HasTag("monkey") then
                inst.components.combat:SetTarget(data.attacker)
            end
            local theta = attackerpos ~= nil and inst:GetAngleToPoint(attackerpos) or inst.Transform:GetRotation()
            theta = (theta + 150 + math.random() * 60) * DEGREES
            local offs = FindWalkableOffset(pos, theta, math.random(8, 16), 8, false, true, NotBlocked, false, true) or
                         FindWalkableOffset(pos, theta, math.random(4, 8), 6, false, true, NotBlocked, false, true)
            if offs ~= nil then
                pos.x = pos.x + offs.x
                pos.z = pos.z + offs.z
            end
            inst.Physics:Teleport(pos:Get())
            if attackerpos ~= nil then
                inst:ForceFacePoint(attackerpos)
            end
            teleport = true
        end

        if teleport then
            SpawnPrefab("shadow_puff").Transform:SetPosition(pos:Get())
        end
    end
end

local function onmonkeysleep(inst) if inst.nobanana2hm then inst.nobanana2hm = nil end end

local RETARGET_MUST_TAGS = {"_combat"}
local RETARGET_CANT_TAGS = {"playerghost"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
AddPrefabPostInit("monkey", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.FindTargetOfInterestTask then inst.FindTargetOfInterestTask:Cancel() end
    -- 猴子的便便也有伤害了
    inst:ListenForEvent("entitysleep", onmonkeysleep)
    inst.components.combat:SetDefaultDamage(10)
    -- -- 猴子仇恨携带素食的玩家
    -- local oldretargetfn = inst.components.combat.targetfn
    -- inst.components.combat:SetRetargetFunction(inst.components.combat.retargetperiod or 1, function(inst, ...)
    --     local target, f = oldretargetfn(inst, ...)
    --     if target then return target, f end
    --     if not inst:HasTag("nightmare") then
    --         local target = FindEntity(inst, TUNING.BUNNYMAN_SEE_MEAT_DIST, function(guy)
    --             return guy.components.inventory ~= nil and inst.components.combat:CanTarget(guy) and guy.components.inventory:FindItem(isfood) ~= nil
    --         end, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
    --         if target then return target, false end
    --     end
    -- end)
    -- 正常猴子没有便便时会消耗身上的掉落物香蕉来生成一个便便
    local HasAmmo = inst.HasAmmo
    inst.HasAmmo = function(inst, ...)
        local result = HasAmmo(inst, ...)
        if not result and not inst:HasTag("nightmare") and not inst.nobanana2hm then
            inst.nobanana2hm = true
            if inst.components.inventory then inst.components.inventory:GiveItem(SpawnPrefab("poop")) end
            return true
        end
        return result
    end

    -- 受击会闪现
    inst:ListenForEvent("attacked", OnBlocked)
    -- 猴子暗影化时不会掉落小肉,正常时不会掉落燃料

    if inst.components.lootdropper then
        local SpawnLootPrefab = inst.components.lootdropper.SpawnLootPrefab
        inst.components.lootdropper.SpawnLootPrefab = function(self, lootprefab, ...)
            if lootprefab then
                if lootprefab == (inst:HasTag("nightmare") and "smallmeat" or "nightmarefuel") 
                        or (inst.nobanana2hm and lootprefab == "cave_banana") then
                return end
                if lootprefab == "smallmeat" or lootprefab == "cave_banana" then
                    if math.random() < 0.5 then return end      -- 小肉和香蕉的掉落率减半
                end
            end
            return SpawnLootPrefab(self, lootprefab, ...)
        end
    end
end)

-- 暗影猴也会投掷便便
local function EquipWeapon(inst, weapon) if not weapon.components.equippable:IsEquipped() then inst.components.inventory:Equip(weapon) end end
AddBrainPostInit("nightmaremonkeybrain", function(self)
    if self.bt.root.children then
        table.insert(self.bt.root.children, 2, WhileNode(function() return self.inst.components.combat.target and self.inst:HasAmmo() end, "Attack Player",
                                                        SequenceNode(
            {ActionNode(function() EquipWeapon(self.inst, self.inst.weaponitems.thrower) end, "Equip thrower"), ChaseAndAttack(self.inst, 60, 40)})))
    end
end)

-- 普通猴子会对任何目标丢便便
AddBrainPostInit("monkeybrain", function(self)
    if self.bt.root.children and self.bt.root.children[4] and self.bt.root.children[4].name == "Parallel" and self.bt.root.children[4].children and
        self.bt.root.children[4].children[1] and self.bt.root.children[4].children[1].name == "Attack Player" and self.bt.root.children[4].children[1].fn then
        self.bt.root.children[4].children[1].fn = function(...) return self.inst.components.combat.target and self.inst:HasAmmo() end
    end
end)


