local FLOWERPOT_DATA_LIST = require("hmrmain/hmr_lists").FLOWERPOT_DATA_LIST

local prefs = {}

local function MakeFlowerPot(name, data)
    local assets = {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    --------------------------------------------------------------------------
    --[[花盆物品]]
    --------------------------------------------------------------------------
    local function OnDeploy(inst, pt, deployer, rot)
        inst.components.hmrtransplanter:DeployPot(deployer, pt, rot)
    end

    local function SpawnPlantFx(inst, pot_data)
        local fx = SpawnPrefab("hmr_cherry_flowerpot_fx")
        if fx ~= nil and pot_data ~= nil then
            fx.entity:SetParent(inst.entity)
            fx.Follower:FollowSymbol(inst.GUID, "swap_plant", 0, 0, 0, true)
            fx.Transform:SetRotation(inst.Transform:GetRotation())
            fx.AnimState:SetBank(pot_data.bank)
            fx.AnimState:SetBuild(pot_data.build)
            if pot_data.animdata.grow_anim ~= nil then
                fx.AnimState:PlayAnimation(pot_data.animdata.grow_anim)
                fx.AnimState:PushAnimation(pot_data.animdata.anim, true)
            else
                fx.AnimState:PlayAnimation(pot_data.animdata.anim, true)
            end
            local s = pot_data.scale or 1
            fx.AnimState:SetScale(s, s, s)

            if pot_data.prefab ~= nil then
                if pot_data.prefab == "lureplant" then
                    fx.components.inventory = {inst = fx, maxslots = 0}
                end

                local extra_pot_data = FLOWERPOT_DATA_LIST[pot_data.prefab]
                local init_fn = extra_pot_data and extra_pot_data.init_fn
                if init_fn ~= nil then
                    init_fn(fx, pot_data)
                end
            end
            fx:SetPrefabName(pot_data.prefab)
            if pot_data.skindata.name ~= nil then
                TheSim:ReskinEntity(fx.GUID, nil, pot_data.skindata.name, pot_data.skindata.id)
            -- else
            --     TheSim:ReskinEntity(fx.GUID)
            end

            if pot_data.animdata.hide_layers ~= nil then
                for _, layer in pairs(pot_data.animdata.hide_layers) do
                    fx.AnimState:Hide(layer)
                end
            end
            if pot_data.animdata.show_layers ~= nil then
                for _, layer in pairs(pot_data.animdata.show_layers) do
                    fx.AnimState:Show(layer)
                end
            end
            if pot_data.animdata.hide_symbols ~= nil then
                for _, symbol in pairs(pot_data.animdata.hide_symbols) do
                    fx.AnimState:HideSymbol(symbol)
                end
            end
            if pot_data.animdata.show_symbols ~= nil then
                for _, symbol in pairs(pot_data.animdata.show_symbols) do
                    fx.AnimState:ShowSymbol(symbol)
                end
            end
            if pot_data.animdata.override_symbols ~= nil then
                for _, override_data in pairs(pot_data.animdata.override_symbols) do
                    fx.AnimState:OverrideSymbol(override_data[1], override_data[2], override_data[3])
                end
            end

            return fx
        end
    end

    -- 这个函数不仅用于移栽时，还用于数据恢复时，数据恢复时plant、doer都为nil
    local function TransplantOnTransplant(inst, pot_data, plant, doer)
        if pot_data ~= nil then
            SpawnPlantFx(inst, pot_data)
        end

        if doer ~= nil and doer.components.inventory ~= nil and plant ~= nil then
            local item = doer.components.inventory:RemoveItem(inst)
            doer.components.inventory:GiveItem(item, nil, plant:GetPosition())
        end

        if plant ~= nil then
            local fx = SpawnPrefab("collapse_small")
            fx.Transform:SetPosition(plant.Transform:GetWorldPosition())
            fx:SetMaterial("wood")

            plant:Remove()
        end
    end

    local function TransplantOnDeploy(inst, pot, deployer, pt)
        pot.AnimState:PlayAnimation("place")
        pot.AnimState:PushAnimation("idle", true)
        pot._name:set(inst.replica.hmrtransplanter:GetName())
        pot.SoundEmitter:PlaySound("dontstarve/common/together/succulent_craft")

        inst:Remove()
    end

    local function item_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        MakeInventoryFloatable(inst, data.float.size, .1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name.."_item.xml"

        -- inst:AddComponent("stackable")
        -- inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
        inst.components.deployable.ondeploy = OnDeploy

        inst:AddComponent("hmrtransplanter")
        inst.components.hmrtransplanter:SetPotPrefab(name)
        inst.components.hmrtransplanter:SetOnTransplant(TransplantOnTransplant)
        inst.components.hmrtransplanter:SetOnDeploy(TransplantOnDeploy)
        inst.components.hmrtransplanter:SetTransplantModes(data.modes)

        MakeHauntableLaunch(inst)

        return inst
    end
    table.insert(prefs, Prefab(name.."_item", item_fn, assets))

    --------------------------------------------------------------------------
    --[[花盆放置提示器]]
    --------------------------------------------------------------------------
    -- 现在这个方法的浆果丛放置器没有皮肤
    local function OnBuilderSet(inst)
        local invobject = inst.components.placer.invobject
        if invobject ~= nil then
            local pot_data = invobject.replica.hmrtransplanter:GetPotData()
            if pot_data ~= nil then
                local placer_fx = SpawnPlantFx(inst, pot_data)

                inst.components.placer:LinkEntity(placer_fx)
            end
        end
    end

    local function placer_fn()
        local inst = CreateEntity()

        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        inst:AddTag("placer")
        --[[Non-networked entity]]
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.Transform:SetTwoFaced()

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetLightOverride(1)

        inst:AddComponent("placer")
        inst.components.placer.onbuilderset = OnBuilderSet

        return inst
    end
    table.insert(prefs, Prefab(name.."_item_placer", placer_fn))

    --------------------------------------------------------------------------
    --[[部署的花盆]]
    --------------------------------------------------------------------------
    local function DisplayNameFn(inst)
        local _name = inst._name:value()
        if _name ~= nil and _name ~= "" then
            return _name
        end
        return inst.name or inst.prefab
    end

    local function OnDismantle(inst, doer)
        local item = SpawnPrefab(name.."_item")
        if item ~= nil then
            item.components.hmrtransplanter:SetPotData(inst.pot_data)
            item.components.hmrtransplanter:SetName(inst._name:value())

            SpawnPlantFx(item, inst.pot_data)

            if doer ~= nil and doer.components.inventory ~= nil then
                doer.components.inventory:GiveItem(item, nil, inst:GetPosition())
                if doer.SoundEmitter ~= nil then
                    doer.SoundEmitter:PlaySound("dontstarve/common/together/succulent_craft")
                end
            else
                item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst:Remove()
        end
    end

    local function OnHammered(inst, worker)
        inst.components.lootdropper:DropLoot()

        local plant_prefab = inst.pot_data and inst.pot_data.prefab
        if plant_prefab then
            local pos = inst:GetPosition()
            -- 尝试掉落农作物种子
            local seed_name = string.sub(plant_prefab, string.len("farm_plant_") + 1).."_seeds"
            inst.components.lootdropper:SpawnLootPrefab(seed_name, pos)

            -- 尝试掉落可移栽作物丛
            local dug_name = "dug_"..plant_prefab
            inst.components.lootdropper:SpawnLootPrefab(dug_name, pos)

            local data = FLOWERPOT_DATA_LIST[string.lower(seed_name)]
            if data ~= nil and data.loots ~= nil then
                for _, loot in pairs(data.loots) do
                    inst.components.lootdropper:SpawnLootPrefab(loot, pos)
                end
            end
        end

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("pot")
        inst:Remove()
    end

    local function OnHit(inst, worker)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
    end

    local function OnLoad(inst, _data)
        if _data ~= nil then
            if _data.pot_data then
                inst.pot_data = _data.pot_data
                inst:SpawnPlantFx(_data.pot_data)
            end
            if _data.name then
                inst._name:set(_data.name)
            end
        end
    end

    local function OnSave(inst, _data)
        if inst.pot_data then
            _data.pot_data = inst.pot_data
        end
        local _name = inst._name:value()
        if _name ~= nil and _name ~= "" then
            _data.name = _name
        end
    end

    local function SetOrientation(inst)
        local angle = inst.Transform:GetRotation()
        inst.Transform:SetRotation(angle + 180)
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()

        inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2)
        inst:SetPhysicsRadiusOverride(.16)
        MakeObstaclePhysics(inst, inst.physicsradiusoverride)
        MakeInventoryPhysics(inst)

        inst.Transform:SetTwoFaced()

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("structure")
        inst:AddTag("rotatableobject")

        MakeInventoryFloatable(inst, "small", .1)

        inst._name = net_string(inst.GUID, name.."_name")
        inst.displaynamefn = DisplayNameFn

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("portablestructure")
        inst.components.portablestructure:SetOnDismantleFn(OnDismantle)

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(OnHammered)
        inst.components.workable:SetOnWorkCallback(OnHit)

        inst:AddComponent("savedrotation")
        inst.SetOrientation = SetOrientation

        MakeHauntable(inst)

        inst.SpawnPlantFx = SpawnPlantFx
        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        return inst
    end
    table.insert(prefs, Prefab(name, fn, assets))
end

--------------------------------------------------------------------------
--[[植株FX]]
--------------------------------------------------------------------------
local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddFollower()

    inst.Transform:SetTwoFaced()

    inst.persists = false

    inst:AddTag("decor")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    return inst
end
table.insert(prefs, Prefab("hmr_cherry_flowerpot_fx", fx_fn))

MakeFlowerPot("hmr_cherry_flowerpot", {
    float = {size = "small"},
    modes = {"farm_plant", "weed_plant", "small_plantable", "small_plant"},
})

MakeFlowerPot("hmr_cherry_flowerpot_large", {
    float = {size = "med"},
    modes = {"farm_plant", "weed_plant", "plantable", "small_plant"},
})

return unpack(prefs)