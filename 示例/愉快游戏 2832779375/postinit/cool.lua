local portable_foods = require("preparedfoods_warly")
local FISH_DATA = require("prefabs/oceanfishdef")
local stackable_replica = require("components/stackable_replica")
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("super_attack_speed") then
    TUNING.WILSON_ATTACK_PERIOD = 0.2
    AddStategraphPostInit("wilson", function(sg)
        local _attack_onenter = sg.states["attack"].onenter
        sg.states["attack"].onenter = function(inst)
            _attack_onenter(inst)

            inst.sg:SetTimeout(0.2 + 0.5 * FRAMES)
        end

        table.insert(sg.states["attack"].timeline, 1, TimeEvent(4 * FRAMES, function(inst)
            if not (inst.sg.statemem.isbeaver or
                    inst.sg.statemem.ismoose or
                    -- inst.sg.statemem.iswhip or
                    -- inst.sg.statemem.ispocketwatch or
                    inst.sg.statemem.isbook) and
                inst.sg.statemem.projectiledelay == nil then
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end
        end))

        --------------------------------------------------------------------------

        local _slingshot_shoot_onenter = sg.states["slingshot_shoot"].onenter
        sg.states["slingshot_shoot"].onenter = function(inst)
            _slingshot_shoot_onenter(inst)

            inst.sg:SetTimeout(0.2 + 0.5 * FRAMES)
        end
        table.insert(sg.states["slingshot_shoot"].timeline, 1, TimeEvent(2 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                if not (target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target)) then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                end
            end
        end))
        table.insert(sg.states["slingshot_shoot"].timeline, 2, TimeEvent(3 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/stretch")
            end
        end))
        table.insert(sg.states["slingshot_shoot"].timeline, 3, TimeEvent(4 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                local buffaction = inst:GetBufferedAction()
                local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.projectile ~= nil then
                    local target = buffaction ~= nil and buffaction.target or nil
                    if target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target) then
                        inst.sg.statemem.abouttoattack = false
                        inst:PerformBufferedAction()
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shoot")
                    else
                        inst:ClearBufferedAction()
                        inst.sg:GoToState("idle")
                    end
                else -- out of ammo
                    inst:ClearBufferedAction()
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_SLINGHSOT_OUT_OF_AMMO"))
                    inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
                end
            end
        end))
    end)
    AddStategraphPostInit("wilson_client", function(sg)
        local _attack_onenter = sg.states["attack"].onenter
        sg.states["attack"].onenter = function(inst)
            _attack_onenter(inst)

            inst.sg:SetTimeout(0.2 + 0.5 * FRAMES)
        end

        table.insert(sg.states["attack"].timeline, 1, TimeEvent(4 * FRAMES, function(inst)
            if not (inst.sg.statemem.isbeaver or
                    inst.sg.statemem.ismoose or
                    -- inst.sg.statemem.iswhip or
                    -- inst.sg.statemem.ispocketwatch or
                    inst.sg.statemem.isbook) and
                inst.sg.statemem.projectiledelay == nil then
                inst:ClearBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end
        end))
    end)
end

--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("ice_salt_box_no_spoiled") then
    TUNING.PERISH_FRIDGE_MULT = 0
    TUNING.PERISH_SALTBOX_MULT = 0
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("no_pick_eater") then
    local _eater_characters = {"wathgrithr", "wurt", "warly"}
    for _, v in pairs(_eater_characters) do
        AddPrefabPostInit(v, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end
            if inst.components.eater then
                inst:RemoveComponent("eater")
                inst:AddComponent("eater")
            end
        end)
    end

    AddPrefabPostInit("warly", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.eater then
            table.removearrayvalue(inst.components.eater.preferseating, "preparedfood")
            table.removearrayvalue(inst.components.eater.preferseating, "pre-preparedfood")
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("cookpot_enhance") then
    for k,recipe in pairs (portable_foods) do
        AddCookerRecipe("cookpot", recipe)
        AddCookerRecipe("archive_cookpot", recipe)
    end
    local IsModCookingProduct_old = GLOBAL.IsModCookingProduct
    GLOBAL.IsModCookingProduct = function(cooker, name)
        if portable_foods[name] ~= nil then
            return false
        end
        if IsModCookingProduct_old ~= nil then
            return IsModCookingProduct_old(cooker, name)
        end
        return false
    end
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("krampus_sack") then
    AddPrefabPostInit("krampus", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'krampus',
        {
            {'monstermeat',  1.0},
            {'charcoal',     1.0},
            {'charcoal',     1.0},
            {'krampus_sack', 1.0},
        })
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("koalefant_tooth") then
    local function dropTooth(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.lootdropper then
            inst.components.lootdropper:AddChanceLoot("walrus_tusk", 1)
        end
    end
    AddPrefabPostInit("koalefant_summer", dropTooth)
    AddPrefabPostInit("koalefant_winter", dropTooth)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("lightninggoathorn") then
    AddPrefabPostInit("lightninggoat", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'lightninggoat',
        {
            {'meat',              1.00},
            {'meat',              1.00},
            {'lightninggoathorn', 1.00},
        })
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("onday_beefalo") then
    TUNING.BEEFALO_MIN_DOMESTICATED_OBEDIENCE.ORNERY = 0.9
    TUNING.BEEFALO_DOMESTICATION_LOSE_DOMESTICATION = 0

    -- TUNING.BEEFALO_DOMESTICATION_OVERFEED_DOMESTICATION = 0
    -- TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_DOMESTICATION = 0
    -- TUNING.BEEFALO_DOMESTICATION_ATTACKED_DOMESTICATION = 1
    TUNING.BEEFALO_DOMESTICATION_BRUSHED_DOMESTICATION = 0.99

end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("niubility_wolfgang") then
    AddClassPostConstruct("components/mightiness", function(self, inst)
        function self:DoDec(...)
            return
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("niubility_hambat") then
    AddPrefabPostInit("hambat", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.equippable then
            local _onequip = inst.components.equippable.onequipfn
            inst.components.equippable:SetOnEquip(function(inst, owner)
                _onequip(inst, owner)
                if inst.components.weapon then
                    inst.components.weapon:SetDamage(TUNING.HAMBAT_DAMAGE)
                end
            end)

            local _onunequip = inst.components.equippable.onunequipfn
            inst.components.equippable:SetOnUnequip(function(inst, owner)
                _onunequip(inst, owner)
                if inst.components.weapon then
                    inst.components.weapon:SetDamage(TUNING.HAMBAT_DAMAGE)
                end
            end)
        end

        if inst.components.weapon then
            inst.components.weapon:SetOnAttack(function() end)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("notafraid_cold") then
    local notafraid_cold_plants = {"grass", "sapling", "berrybush", "berrybush2", "berrybush_juicy"}
    for _,v in pairs(notafraid_cold_plants) do
        AddPrefabPostInit(v, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end

            if inst.components.pickable then
                inst:DoTaskInTime(1, function(inst)
                    if inst.components.pickable.paused then
                        inst.components.pickable:Resume()
                    end
                end)
            end
            if inst.components.witherable then
                inst.components.witherable.wither_temp = 110
            end
        end)
    end
    AddClassPostConstruct("components/pickable", function(self)
        local old_Pause = self.Pause
        function self:Pause()
            old_Pause(self)
            if table.contains(notafraid_cold_plants, self.inst.prefab) then
                self:Resume()
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("drop_stack") then
    local STACK_RADIUS = 20
    local function FindEntities(x, y, z)
        return TheSim:FindEntities(x, y, z, STACK_RADIUS, {"_stackable"},
        {"INLIMBO", "NOCLICK", "lootpump_oncatch", "lootpump_onflight"})
    end
    local function Put(inst, item)
        if item ~= inst and item.prefab == inst.prefab and item.skinname == inst.skinname then
            SpawnPrefab("sand_puff").Transform:SetPosition(item.Transform:GetWorldPosition())
            inst.components.stackable:Put(item)
        end
    end
    AddComponentPostInit("stackable", function(Stackable)
        local Get = Stackable.Get
        function Stackable:Get(...)
            local instance = Get(self, ...)
            if instance.xt_stack_task then
                instance.xt_stack_task:Cancel()
                instance.xt_stack_task = nil
            end
            return instance
        end
    end)
    AddPrefabPostInitAny(function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst:HasTag("smallcreature") or inst:HasTag("heavy") or inst:HasTag("trap") or inst:HasTag("NET_workable") then
            return
        end
        if inst.components.stackable == nil or inst:IsInLimbo() or inst:HasTag("NOCLICK") then return end
        inst.xt_stack_task = inst:DoTaskInTime(.5, function()
            if inst.components.stackable == nil or inst:IsInLimbo() or inst:HasTag("NOCLICK") then return end
            if inst:IsValid() and not inst.components.stackable:IsFull() then
                for _, item in ipairs(FindEntities(inst.Transform:GetWorldPosition())) do
                    if item:IsValid() and not item.components.stackable:IsFull() then Put(inst, item) end
                end
            end
        end)
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("_99stack") then
    local _no_stackable = {"shadowheart", "minotaurhorn", "eyeturret_item", "tallbirdegg", "tallbirdegg_cracked", "lavae_egg", "lavae_egg_cracked"}
    for k, v in pairs(FISH_DATA.fish) do
        table.insert(_no_stackable, k.."_inv")
    end

    table.insert(_no_stackable, "spider")
    table.insert(_no_stackable, "spider_warrior")
    table.insert(_no_stackable, "spider_hider")
    table.insert(_no_stackable, "spider_spitter")
    table.insert(_no_stackable, "spider_dropper")
    table.insert(_no_stackable, "spider_moon")
    table.insert(_no_stackable, "spider_healer")
    table.insert(_no_stackable, "spider_water")

    table.insert(_no_stackable, "pondeel")
    table.insert(_no_stackable, "pondfish")

    table.insert(_no_stackable, "deer_antler1")
    table.insert(_no_stackable, "deer_antler2")
    table.insert(_no_stackable, "deer_antler3")

    -- table.insert(_no_stackable, "glommerflower")
    table.insert(_no_stackable, "glommerwings")

    for _, v in pairs(_no_stackable) do
        AddPrefabPostInit(v, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end

            if not inst.components.stackable then
                inst:AddComponent("stackable")
            end
        end)
    end
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("_99stack1") then
    local _MAX_STACKSIZE = 99

    TUNING.STACK_SIZE_LARGEITEM = _MAX_STACKSIZE
    TUNING.STACK_SIZE_MEDITEM = _MAX_STACKSIZE
    TUNING.STACK_SIZE_SMALLITEM = _MAX_STACKSIZE
    TUNING.STACK_SIZE_TINYITEM = _MAX_STACKSIZE

    TUNING.WORTOX_MAX_SOULS = _MAX_STACKSIZE

    local function _OnStackSizeDirty(inst)
        local self = inst.replica.stackable
        if not self then
            return --stackable removed?
        end

        self:ClearPreviewStackSize()

        --instead of inventoryitem_classified listening for "stacksizedirty" as well
        --forward a new event to guarantee order
        inst:PushEvent("inventoryitem_stacksizedirty")
    end

    stackable_replica._ctor = function(self, inst)
        self.inst = inst
        self._stacksize = net_byte(inst.GUID, "stackable._stacksize", "stacksizedirty")
        self._stacksizeupper = net_byte(inst.GUID, "stackable._stacksizeupper", "stacksizedirty")
        self._ignoremaxsize = net_bool(inst.GUID, "stackable._ignoremaxsize")
        self._maxsize = net_tinybyte(inst.GUID, "stackable._maxsize")

        if not TheWorld.ismastersim then
            --self._previewstacksize = nil
            --self._previewtimeouttask = nil
            inst:ListenForEvent("stacksizedirty", _OnStackSizeDirty)
        end
    end
    function stackable_replica:SetMaxSize(maxsize)
        self._maxsize:set(0)
    end
    function stackable_replica:MaxSize()
        return self._ignoremaxsize:value() and math.huge or _MAX_STACKSIZE
    end
    function stackable_replica:OriginalMaxSize()
        return _MAX_STACKSIZE
    end
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("krampus_sack_fresh") then
    AddPrefabPostInit("krampus_sack", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if not inst.components.preserver then
            inst:AddComponent("preserver")
	        inst.components.preserver:SetPerishRateMultiplier(0)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
--[[
if GetModConfigData("explode_rockavocade") then
    AddPrefabPostInit("gunpowder", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.explosive then
	        local old_onexplodefn = inst.components.explosive.onexplodefn
            inst.components.explosive.onexplodefn = function(inst)
                old_onexplodefn(inst)

                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, inst.components.explosive.explosiverange, nil, {"INLIMBO"})
                for k, v in pairs(ents) do
                    if v.prefab == "rock_avocado_fruit" then
                        if v.components.workable ~= nil and v.components.workable:CanBeWorked() then
                            for i = 1, math.ceil(v.components.stackable.stacksize/10) do
                                v.components.workable:WorkedBy(inst, 10)
                            end
                        end
                    end
                end
            end
        end
    end)
end
]]
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("cane_projectile") then
    AddPrefabPostInit("cane", function(inst)
        local function onattack(inst, attacker, target, skipsanity)
            if not target:IsValid() then
                --target killed or removed in combat damage phase
                return
            end

            if target.components.combat ~= nil then
                target.components.combat:SuggestTarget(attacker)
            end
        end

        inst:AddTag("fishingrod")
        inst:AddTag("tool")
        inst:AddTag("weapon")
        inst:AddTag("rangedweapon")

        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.weapon then
            inst.components.weapon:SetDamage(TUNING.CANE_DAMAGE)
            inst.components.weapon:SetRange(8, 10)
            inst.components.weapon:SetOnAttack(onattack)
            inst.components.weapon:SetProjectile("ice_projectile")
        end

        inst:AddComponent("tool")
        inst.components.tool:SetAction(ACTIONS.CHOP, 1)
        inst.components.tool:SetAction(ACTIONS.MINE, 1)
        -- inst.components.tool:SetAction(ACTIONS.DIG, 1)
        inst.components.tool:SetAction(ACTIONS.NET)

        inst.components.equippable.walkspeedmult = 1.4

        if not inst.components.fishingrod then
            inst:AddComponent("fishingrod")
            inst.components.fishingrod:SetWaitTimes(0, 0)
            inst.components.fishingrod:SetStrainTimes(0, 5)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("hambat_aoe") then
    AddPrefabPostInit("hambat", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.weapon then
            local exclude_tags = { "INLIMBO", "companion", "wall", "abigail", "shadowminion" }
            inst.components.weapon.onattack = function(inst, attacker, target)
                local x2, y2, z2 = target.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x2, y2, z2, 4, { "_combat" }, exclude_tags)
                for i, ent in ipairs(ents) do
                    if ent ~= target and ent ~= attacker and attacker.components.combat:IsValidTarget(ent) and
                        (attacker.components.leader ~= nil and not attacker.components.leader:IsFollower(ent)) then
                            attacker:PushEvent("onareaattackother", { target = ent, weapon = inst, stimuli = nil })
                            ent.components.combat:GetAttacked(attacker, TUNING.HAMBAT_DAMAGE, inst, nil)
                    end
                end
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
-- if GetModConfigData("origin_healthbar") then
--     AddPrefabPostInitAny(function(inst)
--         if not TheWorld.ismastersim then
--             return inst
--         end
--         if inst.components.health and (inst:HasTag("epic") or inst:HasTag("monster")) then
--             if not inst.components.healthbar and not inst:HasTag("player") then
--                 inst:AddComponent("healthbar")
--                 inst.components.healthbar:Enable(false)
--             end
--         end
--     end)

--     AddClassPostConstruct("components/combat", function(self)
--         local old_SetTarget = self.SetTarget
--         function self:SetTarget(target)
--             if self.inst.components.healthbar then
--                 if target == nil then
--                     self.inst.components.healthbar:Enable(false)
--                 else
--                     self.inst.components.healthbar:Enable(true)
--                 end
--             end
--             return old_SetTarget(self, target)
--         end

--         local old_DropTarget = self.DropTarget
--         function self:DropTarget(hasnexttarget)
--             if self.target and self.inst.components.healthbar then
--                 self.inst.components.healthbar:Enable(false)
--             end
--             return old_DropTarget(self, hasnexttarget)
--         end
--     end)
-- end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("niubility_abigail") then
    TUNING.ABIGAIL_DAMAGE =
    {
        day = 40,
        dusk = 40,
        night = 40,
    }
    TUNING.ABIGAIL_SPEED = 5 * 2
    AddPrefabPostInit("abigail", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.health then
            inst.components.health.regen.amount = 30
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("niubility_wanda") then

    TUNING.WANDA_SHADOW_DAMAGE_NORMAL = TUNING.WANDA_SHADOW_DAMAGE_OLD
    TUNING.WANDA_SHADOW_DAMAGE_YOUNG = TUNING.WANDA_SHADOW_DAMAGE_OLD

    AddPrefabPostInit("wanda", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.health then
            inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH)
            inst.components.health.redirect = nil
            inst.components.health.canheal = true
        end

        if inst.components.combat then
            inst.components.combat.onhitotherfn = function(inst, target, damage, stimuli, weapon, damageresolved)
                if weapon ~= nil and target ~= nil and target:IsValid() and weapon:IsValid() and weapon:HasTag("shadow_item") then
                    local fx_prefab = weapon:HasTag("pocketwatch") and "wanda_attack_pocketwatch_old_fx" or "wanda_attack_shadowweapon_old_fx"
                            or nil

                    if fx_prefab ~= nil then
                        local fx = SpawnPrefab(fx_prefab)

                        local x, y, z = target.Transform:GetWorldPosition()
                        local radius = target:GetPhysicsRadius(.5)
                        local angle = (inst.Transform:GetRotation() - 90) * DEGREES
                        fx.Transform:SetPosition(x + math.sin(angle) * radius, 0, z + math.cos(angle) * radius)
                    end
                end
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("wormwood_foodhealth") then
    AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.eater ~= nil then
            inst.components.eater:SetAbsorptionModifiers(1, 1, 1)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("wortox_nofooddebuff") then
    AddPrefabPostInit("wortox", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.eater ~= nil then
            inst.components.eater:SetAbsorptionModifiers(1, 1, 1)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("auto_fuel") then
    local _auto_fuel = {
        pocketwatch_weapon = {type = "equippable", threshold = 0.75, fuel = "nightmarefuel"},
        yellowamulet = {type = "equippable", threshold = 0.6, fuel = "nightmarefuel"},
        armorskeleton = {type = "equippable", threshold = 0.7, fuel = "nightmarefuel", timeout = 0.5},
        minerhat = {type = "equippable", threshold = 0.7, fuel = "lightbulb"},
        molehat = {type = "equippable", threshold = 0.8, fuel = "lightbulb"},
    }

    AddPrefabPostInit("molehat", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.fueled then
            inst.components.fueled.fueltype = FUELTYPE.CAVE
        end
    end)

    for k, v in pairs(_auto_fuel) do
        AddPrefabPostInit(k, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end

            if inst.components.fueled then
                inst:ListenForEvent("percentusedchange", function(inst, data)
                    local percent = data.percent
                    if percent < v.threshold then
                        if v.type == "equippable" then
                            local owner = inst.components.inventoryitem.owner
                            if owner then
                                local fuel = owner.components.inventory:FindItem(function(item)
                                    return item.prefab == v.fuel
                                end)
                                if fuel then
                                    if v.timeout then
                                        inst:DoTaskInTime(v.timeout, function(inst)
                                        end)
                                    else
                                        inst.components.fueled:TakeFuelItem(fuel.components.stackable:Get(), owner)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("oceantreenut_landplant") then
    AddPrefabPostInit("oceantreenut", function(inst)
        local function ondeploy(inst, pt, deployer)
            local sapling = SpawnPrefab("oceantree")
            sapling.Transform:SetPosition(pt.x, pt.y, pt.z)
            sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
            inst:Remove()
        end

        if not TheWorld.ismastersim then
            return inst
        end

        inst:RemoveTag("heavy")

        if inst.components.inventoryitem then
            inst.components.inventoryitem.cangoincontainer = true
        end
        if inst.components.equippable then
            inst:RemoveComponent("equippable")
        end

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        inst.components.deployable.ondeploy = ondeploy
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("stronggrip") then
    AddPlayerPostInit(function(inst)
        inst:AddTag("stronggrip")
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("hermitcrab_refuse_nobody") then
    TUNING.HERMITCRAB.HEAVY_FISH_THRESHHOLD = 0
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("more_fossil_piece") then
    AddPrefabPostInit("stalagmite_full", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'full_rock',
        {
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'goldnugget',  1.00},
            {'flint',       1.00},
            {'fossil_piece',1.00},
            {'goldnugget',  0.25},
            {'flint',       0.60},
            {'bluegem',     0.05},
            {'redgem',      0.05},
        })
    end)
    AddPrefabPostInit("stalagmite_med", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'med_rock',
        {
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'flint',       1.00},
            {'goldnugget',  0.50},
            {'fossil_piece',1.00},
            {'flint',       0.60},
        })
    end)
    AddPrefabPostInit("stalagmite_low", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'low_rock',
        {
            {'rocks',       1.00},
            {'flint',       1.00},
            {'goldnugget',  0.50},
            {'fossil_piece',1.00},
            {'flint',       0.30},
        })
    end)
    AddPrefabPostInit("stalagmite", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'full_rock',
        {
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'goldnugget',  1.00},
            {'flint',       1.00},
            {'fossil_piece',1.00},
            {'goldnugget',  0.25},
            {'flint',       0.60},
            {'bluegem',     0.05},
            {'redgem',      0.05},
        })
    end)

    AddPrefabPostInit("stalagmite_tall_full", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable('stalagmite_tall_full_rock',
        {
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'goldnugget',  1.00},
            {'flint',       1.00},
            {'fossil_piece',1.00},
            {'goldnugget',  0.25},
            {'flint',       0.60},
            {'redgem',      0.05},
            {'log',         0.05},
        })
    end)
    AddPrefabPostInit("stalagmite_tall_med", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'stalagmite_tall_med_rock',
        {
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'flint',       1.00},
            {'fossil_piece',1.00},
            {'goldnugget',  0.15},
            {'flint',       0.60},
        })
    end)
    AddPrefabPostInit("stalagmite_tall_low", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'stalagmite_tall_low_rock',
        {
            {'rocks',       1.00},
            {'flint',       1.00},
            {'fossil_piece',1.00},
            {'goldnugget',  0.15},
            {'flint',       0.30},
        })
    end)
    AddPrefabPostInit("stalagmite_tall", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        SetSharedLootTable( 'stalagmite_tall_full_rock',
        {
            {'rocks',       1.00},
            {'rocks',       1.00},
            {'goldnugget',  1.00},
            {'flint',       1.00},
            {'fossil_piece',1.00},
            {'goldnugget',  0.25},
            {'flint',       0.60},
            {'redgem',      0.05},
            {'log',         0.05},
        })
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("reasonable_bundle") then
    AddPrefabPostInit("bundle", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.unwrappable then
            local old_onunwrappedfn = inst.components.unwrappable.onunwrappedfn
            inst.components.unwrappable.onunwrappedfn = function(inst, pos, doer)
                if old_onunwrappedfn~=nil then
                    old_onunwrappedfn(inst, pos, doer)
                end
                SpawnPrefab("rope").Transform:SetPosition(pos:Get())
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("deepocean_deploy_dockkit") then
    AddPrefabPostInit("dock_kit", function(inst)
        local function New_CLIENT_CanDeployDockKit(inst, pt, mouseover, deployer, rotation)
            local tile = TheWorld.Map:GetTileAtPoint(pt.x, 0, pt.z)
            -- if (tile == WORLD_TILES.OCEAN_COASTAL_SHORE or tile == WORLD_TILES.OCEAN_COASTAL) then
            if (tile >= 201 and tile <= 247) then
                local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(pt.x, 0, pt.z)
                local found_adjacent_safetile = false
                for x_off = -1, 1, 1 do
                    for y_off = -1, 1, 1 do
                        if (x_off ~= 0 or y_off ~= 0) and IsLandTile(TheWorld.Map:GetTile(tx + x_off, ty + y_off)) then
                            found_adjacent_safetile = true
                            break
                        end
                    end

                    if found_adjacent_safetile then break end
                end

                if found_adjacent_safetile then
                    local center_pt = Vector3(TheWorld.Map:GetTileCenterPoint(tx, ty))
                    return found_adjacent_safetile and TheWorld.Map:CanDeployDockAtPoint(center_pt, inst, mouseover)
                end
            end

            return false
        end
        -- local old_custom_candeploy_fn = inst._custom_candeploy_fn
        inst._custom_candeploy_fn = New_CLIENT_CanDeployDockKit
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("merm_pigking_gold") then
    AddPrefabPostInit("pigking", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.trader then
            local old_test = inst.components.trader.test
            inst.components.trader.test = function(inst, item, giver)
                local hat = giver.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if giver:HasTag("merm") and hat and hat.prefab == "footballhat" then
                    local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0
                    return item.components.tradable.goldvalue > 0 or is_event_item or item.prefab == "pig_token"
                else
                    if old_test ~= nil then
                        return old_test(inst, item, giver)
                    end
                end
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("dumbbells_autopickup") then
    AddClassPostConstruct("components/complexprojectile", function(self)
        local old_Hit = self.Hit
        function self:Hit(target)
            if old_Hit then
                old_Hit(self, target)
            end

            if self.inst:HasTag("dumbbell") and self.attacker then
                self.inst:DoTaskInTime(0.2, function(inst)
                    if self.attacker.components.inventory then
                        if self.attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil then
                            self.attacker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
                        else
                            self.attacker.components.inventory:Equip(inst)
                        end
                    end
                end)
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("wall_can_heal") then
    local walls = {"stone", "stone_2", "wood", "hay", "ruins", "ruins_2", "moonrock", "dreadstone"}
    for _, v in pairs(walls) do
        AddPrefabPostInit("wall_"..v, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end

            if inst.components.health then
                inst.components.health:StartRegen(2, 1)
            end
        end)
    end
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("mushroom_light_with_fireflies") then
    AddPrefabPostInit("fireflies", function(inst)
        inst:AddTag("lightcontainer")
        inst:AddTag("fulllighter")
        if not TheWorld.ismastersim then
            return inst
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("stinger_blowpipeammo") then
    AddPrefabPostInit("stinger", function(inst)
        inst:AddTag("blowpipeammo")
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("gentle_wolfgang") then
    AddClassPostConstruct("components/mightiness", function(self)
        local old_BecomeState = self.BecomeState
        function self:BecomeState(state, silent, ...)
            silent = true
            old_BecomeState(self, state, silent, ...)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------













