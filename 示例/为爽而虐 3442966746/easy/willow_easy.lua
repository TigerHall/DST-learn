local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 薇洛攻击干燥和燃烧的敌人伤害提升
if GetModConfigData("Willow Attack Dry/Burning Enemy") then
    local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
        if inst:HasTag("firefrenzy") then
            -- 移除了自动刷新buff的逻辑，改为手动控制
            -- inst:AddDebuff("buff_firefrenzy", "buff_firefrenzy")
            if mount or not (target and target:IsValid()) or target:GetIsWet() or (target.components.freezable and target.components.freezable:IsFrozen()) then
                return (target and target:IsValid() and target.components.burnable and target.components.burnable:IsBurning()) and (hardmode and 0.8 or 1) or
                           (hardmode and 1 or 1.25)
            end
            if target:HasTag("fire") or target:HasTag("burnt") or (target.components.burnable and target.components.burnable:IsBurning()) then
                return (target.components.burnable and target.components.burnable:IsBurning()) and (hardmode and 1.2 or 2) or (hardmode and 1.5 or 2.5)
            end
            return (target.components.burnable and target.components.burnable:IsBurning()) and (hardmode and 1 or 1.2) or (hardmode and 1.25 or 1.5)
        else
            if mount or not (target and target:IsValid()) or target:GetIsWet() or (target.components.freezable and target.components.freezable:IsFrozen()) then
                return 1
            end
            if target:HasTag("fire") or target:HasTag("burnt") or (target.components.burnable and target.components.burnable:IsBurning()) then
                return hardmode and 1.25 or 2.5
            end
            return hardmode and 1 or 1.5
        end
    end

    AddPrefabPostInit("willow", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.combat.customdamagemultfn then
            inst.components.combat.customdamagemultfn = CustomCombatDamage
        else
            local old = inst.components.combat.customdamagemultfn
            inst.components.combat.customdamagemultfn = function(...) return (old(...) or 1) * CustomCombatDamage(...) end
        end
    end)

    local function RefreshDebuff(inst)
        if inst.fire_thorns_task then
            local fn = inst.fire_thorns_task.fn
            inst.fire_thorns_task:Cancel()
            inst.fire_thorns_task = inst:DoTaskInTime(20, fn)
        end
    end

    AddPrefabPostInit("bernie_big", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("onhitother", RefreshDebuff)
    end)

    AddPrefabPostInit("willow_frenzy", function(inst)
        if not TheWorld.ismastersim then return end
        inst.light2hm = SpawnPrefab("firefx_light")
        inst.light2hm.entity:SetParent(inst.entity)
        inst.light2hm.Light:SetRadius(1)
        inst.light2hm.Light:SetIntensity(.8)
        inst.light2hm.Light:SetFalloff(.33)
        inst.light2hm.Light:SetColour(253 / 255, 179 / 255, 179 / 255)
    end)
end

-- 薇洛右键自身施放意念灭火术
if GetModConfigData("Willow Right Self Pyrokinetics Explained") then
    local cd = GetModConfigData("Willow Right Self Pyrokinetics Explained")
    cd = cd == true and 3 or cd
    AddReadBookRightSelfAction("willow", "book_fire", cd, STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.ACTIVATE.LOCKED_GATE,
                               STRINGS.ACTIONS.START_CHANNELCAST.LIGHTER .. "/")
    local SNUFF_ONEOF_TAGS = {"smolder", "fire", "willow_ember"}
    local SNUFF_NO_TAGS = {"INLIMBO", "snuffed"}
    local ABSORB_RANGE = TUNING.BOOK_FIRE_RADIUS
    local function rightselfaction2hm_replacefn(action)
        local owner = action and action.doer
        if owner and owner.components and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("willow_embers") then
            local x, y, z = owner.Transform:GetWorldPosition()
            local ExtinguishFire = false
            local ents = TheSim:FindEntities(x, 0, z, ABSORB_RANGE, nil, SNUFF_NO_TAGS, SNUFF_ONEOF_TAGS)
            for i, v in ipairs(ents) do
                if v:IsValid() and not v:IsInLimbo() and v:HasTag("willow_ember") then
                    ExtinguishFire = true
                    break
                end
            end
            if ExtinguishFire then
                for i, v in ipairs(ents) do
                    if v:IsValid() and not v:IsInLimbo() then
                        local fx = nil
                        local giveember = nil
                        if v:HasTag("willow_ember") then
                            v:AddTag("snuffed")
                            fx = "channel_absorb_embers"
                            giveember = true
                        elseif v.components.burnable then
                            if v.components.burnable:IsBurning() then
                                v.components.burnable:Extinguish()
                                fx = "channel_absorb_fire"
                            elseif v.components.burnable:IsSmoldering() then
                                v.components.burnable:SmotherSmolder()
                                fx = "channel_absorb_smoulder"
                            end
                        end
                        if fx then
                            owner.SoundEmitter:PlaySound("meta3/willow_lighter/ember_absorb")
                            local fxprefab = SpawnPrefab(fx)
                            fxprefab.Follower:FollowSymbol(owner.GUID, "swap_object", 56, -40, 0)
                            if giveember then
                                v.AnimState:PlayAnimation("idle_pst")
                                v:DoTaskInTime(10 * FRAMES, function()
                                    if not owner.components.health:IsDead() then
                                        owner.components.inventory:GiveItem(v, nil, owner:GetPosition())
                                    end
                                    v:RemoveTag("snuffed")
                                    v.AnimState:PlayAnimation("idle_pre")
                                    v.AnimState:PushAnimation("idle_loop", true)
                                end)
                            end
                        end
                    end
                end
                return true
            end
        end
    end
    AddPrefabPostInit("willow", function(inst)
        if not TheWorld.ismastersim then return end
        inst.rightselfaction2hm_replacefn = rightselfaction2hm_replacefn
    end)
    AddPrefabPostInit("willow_ember", function(inst)
        MakeUnlimitStackSize(inst)
        if inst.components.inventoryitem then
            inst.components.inventoryitem.keepondeath = true
            inst.components.inventoryitem.keepondrown = true
        end
        if inst.components.stackable then inst.components.stackable.forcedropsingle = true end
    end)
end

-- 薇洛的火焰武器
if GetModConfigData("Willow Fire Weapon Attack") then
    -- 当火把切换到其他武器后会继续火焰，且攻击会仍然点燃目标
    local function checknewequip(inst)
        if inst.fires2hm and inst.firessource2hm then
            local equip = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip == nil or not equip:IsValid() or equip == inst.firessource2hm or equip.prefab == "torch" or equip.prefab == "lighter" or
                not inst.firessource2hm:IsValid() or (inst.firessource2hm.components.fueled and inst.firessource2hm.components.fueled.currentfuel <= 0) or
                (inst.firessource2hm.components.inventoryitem and inst.firessource2hm.components.inventoryitem:GetGrandOwner() ~= inst) then
                if equip ~= inst.firessource2hm and inst.firessource2hm:IsValid() and inst.firessource2hm.components.burnable and
                    inst.firessource2hm.components.burnable.burning then inst.firessource2hm.components.burnable:Extinguish() end
                for i, fx in ipairs(inst.fires2hm) do fx:Remove() end
                inst.fires2hm = nil
                inst.firessource2hm.bindwillow2hm = nil
                inst.firessource2hm = nil
                if inst.checkfirestask2hm then
                    inst.checkfirestask2hm:Cancel()
                    inst.checkfirestask2hm = nil
                end
            elseif not inst.firessource2hm.bindwillow2hm then
                inst.firessource2hm.bindwillow2hm = inst
                if inst.firessource2hm.components.burnable and not inst.firessource2hm.components.burnable.burning then
                    inst.firessource2hm.components.burnable:Ignite()
                end
            elseif inst.firessource2hm.components.burnable and not inst.firessource2hm.components.burnable.burning then
                inst.firessource2hm.components.burnable:Ignite()
            end
        end
    end
    local function onunequip(inst, data)
        inst:DoTaskInTime(0, checknewequip)
        if data and data.item and data.item:IsValid() then
            if data.item.components.weapon and data.item.components.weapon.projectile == "torchfireprojectile2hm" then
                data.item.components.weapon.projectile = "fire_projectile"
                data.item.components.weapon:SetDamage(data.item.olddamage2hm or 0)
                data.item.olddamage2hm = nil
                -- if hardmode then data.item.components.weapon.attackwearmultipliers:RemoveModifier(inst, "willow2hm") end
            end
        end
    end
    local function onequip(inst, data)
        checknewequip(inst)
        if data and data.item and data.item:IsValid() then
            if data.item.components.weapon and data.item.components.weapon.projectile == "fire_projectile" then
                data.item.components.weapon.projectile = "torchfireprojectile2hm"
                data.item.olddamage2hm = data.item.components.weapon.damage
                data.item.components.weapon:SetDamage(34)
                -- if hardmode then data.item.components.weapon.attackwearmultipliers:SetModifier(inst, 1, "willow2hm") end
            end
        end
    end
    local function onhitother(inst, data)
        if data and data.target and data.target:IsValid() and data.target.components.burnable and not data.target:GetIsWet() and
            not data.target.flamethrowerdamagetask2hm and not (data.target.components.freezable and data.target.components.freezable:IsFrozen()) and
            ((inst.fires2hm and inst.firessource2hm and inst.firessource2hm:IsValid()) or inst:HasTag("firefrenzy")) and
            not (inst.components.rider and inst.components.rider.riding) and
            ((inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("willow_controlled_burn_1")) or math.random() <
                data.target.components.burnable.flammability) then data.target.components.burnable:Ignite(nil, inst) end
    end
    AddPrefabPostInit("willow", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("equip", onequip)
        inst:ListenForEvent("unequip", onunequip)
        inst:ListenForEvent("onhitother", onhitother)
    end)
    local fireweapons = {"torch", "lighter"}
    for index, item in ipairs(fireweapons) do
        AddPrefabPostInit(item, function(inst)
            if not TheWorld.ismastersim then return end
            if inst.components.equippable then
                local onunequipfn = inst.components.equippable.onunequipfn
                inst.components.equippable.onunequipfn = function(inst, owner, ...)
                    if inst:IsValid() and owner and owner:IsValid() and owner.prefab == "willow" and inst.components.fueled and
                        inst.components.fueled.currentfuel > 0 and inst.fires then
                        if owner.firessource2hm and owner.firessource2hm:IsValid() then
                            if owner.firessource2hm.components.burnable and owner.firessource2hm.components.burnable.burning then
                                owner.firessource2hm.components.burnable:Extinguish()
                            end
                            owner.firessource2hm.bindwillow2hm = nil
                        end
                        if owner.fires2hm then for i, fx in ipairs(owner.fires2hm) do fx:Remove() end end
                        if not owner.checkfirestask2hm then owner.checkfirestask2hm = owner:DoPeriodicTask(1, checknewequip) end
                        owner.fires2hm = inst.fires
                        owner.firessource2hm = inst
                        inst.fires = nil
                    end
                    return onunequipfn(inst, owner, ...)
                end
            end
        end)
    end
end

-- 薇洛打火机燃料为零时不会消失
AddPrefabPostInit("lighter", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 重写燃料变化回调函数，移除燃料为0时删除打火机的逻辑
    local function onfuelchange_new(newsection, oldsection, inst)
        if newsection <= 0 then
            --当燃料耗尽时，熄灭打火机但不删除它
            if inst.components.burnable ~= nil then
                inst.components.burnable:Extinguish()
            end
            
            local equippable = inst.components.equippable
            if equippable ~= nil and equippable:IsEquipped() then
                local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
                if owner ~= nil then
                    -- 移除火光效果
                    if inst.fires ~= nil then
                        for i, fx in ipairs(inst.fires) do
                            fx:Remove()
                        end
                        inst.fires = nil
                    end
                    
                    -- 播放熄灭声音
                    owner.SoundEmitter:PlaySound("dontstarve/wilson/lighter_off")
                    
                    local data =
                    {
                        prefab = inst.prefab,
                        equipslot = equippable.equipslot,
                        announce = "ANNOUNCE_TORCH_OUT",
                    }
                    owner:PushEvent("itemranout", data)
                    return
                end
            else
                -- 没有装备也要移除火光
                if inst.fires ~= nil then
                    for i, fx in ipairs(inst.fires) do
                        fx:Remove()
                    end
                    inst.fires = nil
                end
            end
            return
        end
    end
    
    -- 替换原有的燃料变化回调
    if inst.components.fueled then
        inst.components.fueled:SetSectionCallback(onfuelchange_new)
        -- 移除原有的自动删除函数
        inst.components.fueled:SetDepletedFn(nil)
    end
    
    -- 监听装备事件，如果燃料为零则延迟应用燃料耗尽逻辑
    inst:ListenForEvent("equipped", function(inst, data)
        inst:DoTaskInTime(0, function()
            if inst.components.fueled and inst.components.fueled:IsEmpty() then
                -- 应用燃料为零时的完整逻辑
                onfuelchange_new(0, 1, inst)
            end
        end)
    end)
    
    -- 无燃料打火机不能点燃目标
    if inst.components.weapon then

        inst.original_onattackfn = inst.components.weapon.onattack

        local function onattack_with_fuel_check(weapon, attacker, target)
            -- 只有在有燃料时才执行点燃逻辑
            if weapon.components.fueled and not weapon.components.fueled:IsEmpty() then
                --target may be killed or removed in combat damage phase
                if target and target:IsValid() and target.components.burnable and (
                    attacker.components.skilltreeupdater and attacker.components.skilltreeupdater:IsActivated("willow_controlled_burn_1") or
                    math.random() < TUNING.LIGHTER_ATTACK_IGNITE_PERCENT * target.components.burnable.flammability
                ) then
                    target.components.burnable:Ignite(nil, attacker)
                end
            end

        end

        inst.components.weapon:SetOnAttack(onattack_with_fuel_check)
    end
    
    -- 无燃料打火机不能点燃目标
    if inst.components.lighter then
        local original_light = inst.components.lighter.Light
        inst.components.lighter.Light = function(self, target, doer)
            -- 检查燃料状态
            if self.inst.components.fueled and self.inst.components.fueled:IsEmpty() then
                return
            end
            -- 有燃料时正常执行原始逻辑
            return original_light(self, target, doer)
        end
    end
end)