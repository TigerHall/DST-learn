local WAXED_PLANTS = require "prefabs/waxed_plant_common"

local prefs = {}

local function MakeGrass(name, data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    if data.shared_loot_able then
        SetSharedLootTable(name, data.shared_loot_able)
    end

    ---------------------------------------------------------------------------
    ---[[种子/丛]]
    ---------------------------------------------------------------------------
    if data.dug_prefabs ~= nil then
        for _, prefab in pairs(data.dug_prefabs) do
            local dug_assets = {
                Asset("ANIM", "anim/"..(prefab.build or prefab.name)..".zip"),
            }
            local function OnDeploy(inst, pt, deployer)
                local tree = SpawnPrefab(name)
                if tree ~= nil then
                    tree.Transform:SetPosition(pt:Get())
                    inst.components.stackable:Get():Remove()

                    if inst.from_seeds == true then
                        if tree.components.witherable ~= nil then
                            tree.components.witherable:Enable(false)
                        end
                        tree.from_seeds = true
                        if tree.components.pickable ~= nil then
                            tree.components.pickable.transplanted = false
                        end
                        tree.AnimState:PlayAnimation("grow")
                    else
                        if tree.components.pickable ~= nil then
                            tree.components.pickable:OnTransplant()
                        end
                    end
                    if tree.components.pickable ~= nil then
                        tree.components.pickable:MakeEmpty()
                    end

                    if deployer ~= nil and deployer.SoundEmitter ~= nil then
                        deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
                    end

                    if TheWorld.components.lunarthrall_plantspawner and tree:HasTag("lunarplant_target") then
                        TheWorld.components.lunarthrall_plantspawner:setHerdsOnPlantable(tree)
                    end
                end
            end

            local function dug_fn()
                local inst = CreateEntity()

                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddSoundEmitter()
                inst.entity:AddNetwork()

                MakeInventoryPhysics(inst)

                inst:AddTag("deployedplant")

                inst.AnimState:SetBank(prefab.bank)
                inst.AnimState:SetBuild(prefab.build)
                inst.AnimState:PlayAnimation(prefab.anim)

                MakeInventoryFloatable(inst)

                inst.entity:SetPristine()

                if not TheWorld.ismastersim then
                    return inst
                end

                inst:AddComponent("stackable")
                inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

                inst:AddComponent("inspectable")

                inst:AddComponent("inventoryitem")
                inst.components.inventoryitem.imagename = prefab.name
                inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab.name..".xml"

                inst:AddComponent("fuel")
                inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

                MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
                MakeSmallPropagator(inst)

                MakeHauntableLaunchAndIgnite(inst)

                inst.from_seeds = prefab.from_seeds
                inst:AddComponent("deployable")
                --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
                inst.components.deployable.ondeploy = OnDeploy
                inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
                -- inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)

                return inst
            end

            table.insert(prefs, Prefab(prefab.name, dug_fn, dug_assets))
            table.insert(prefs, MakePlacer(prefab.name.."_placer", name, name, "idle"))
        end
    end

    ---------------------------------------------------------------------------
    ---[[产物]]
    ---------------------------------------------------------------------------
    if data.products ~= nil then
        for _, product in ipairs(data.products) do
            local product_assets = {
                Asset("ANIM", "anim/"..(product.build or product.name)..".zip"),
            }
            local function product_fn()
                local inst = CreateEntity()

                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddSoundEmitter()
                inst.entity:AddNetwork()

                inst:AddTag("product")

                inst.AnimState:SetBank(product.bank or product.name)
                inst.AnimState:SetBuild(product.build or product.name)
                inst.AnimState:PlayAnimation(product.anim or "idle", true)

                if product.common_postinit ~= nil then
                    product.common_postinit(inst)
                end

                MakeInventoryPhysics(inst)
                MakeInventoryFloatable(inst, "small", 0.05, 1.0)

                inst.entity:SetPristine()

                if not TheWorld.ismastersim then
                    return inst
                end

                inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
                local color = 0.75 + math.random() * 0.25
                inst.AnimState:SetMultColour(color, color, color, 1)

                inst:AddComponent("inspectable")

                inst:AddComponent("inventoryitem")
                inst.components.inventoryitem.imagename = product.name
                inst.components.inventoryitem.atlasname = "images/inventoryimages/"..product.name..".xml"

                inst:AddComponent("stackable")
                inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

                inst:AddComponent("fuel")
                inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

                MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
                MakeSmallPropagator(inst)

                MakeHauntableIgnite(inst)

                if product.master_postinit ~= nil then
                    product.master_postinit(inst)
                end

                return inst
            end

            table.insert(prefs, Prefab(product.name, product_fn, product_assets))
        end
    end

    ---------------------------------------------------------------------------
    ---[[植物]]
    ---------------------------------------------------------------------------
    local function dig_up(inst, worker)
        if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
            local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()

            if inst.components.pickable:CanBePicked() then
                inst.components.lootdropper:DropLoot()
            end

            inst.components.lootdropper:SpawnLootPrefab(withered and data.withered_product or inst.from_seeds and name.."_seeds" or name.."_dug")
        end
        inst.AnimState:PlayAnimation("dug")
        local frame = inst.AnimState:GetCurrentAnimationNumFrames()
        inst:DoTaskInTime(frame * FRAMES, inst.Remove)
    end

    local function onregenfn(inst)
        inst.AnimState:PlayAnimation("grow")
        inst.AnimState:PushAnimation("idle", true)
    end

    local function makeemptyfn(inst)
        if not POPULATING and
            (   inst.components.witherable ~= nil and
                inst.components.witherable:IsWithered() or
                inst.AnimState:IsCurrentAnimation("idle_dead")
            ) then
            inst.AnimState:PlayAnimation("dead_to_empty")
            inst.AnimState:PushAnimation("picked", false)
        else
            inst.AnimState:PlayAnimation("picked")
        end
    end

    local function makebarrenfn(inst, wasempty)
        if not POPULATING and
            (   inst.components.witherable ~= nil and
                inst.components.witherable:IsWithered()
            ) then
            inst.AnimState:PlayAnimation(wasempty and "empty_to_dead" or "full_to_dead")
            inst.AnimState:PushAnimation("idle_dead", false)
        else
            inst.AnimState:PlayAnimation("idle_dead")
        end
    end

    local function onpickedfn(inst, picker)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
        inst.AnimState:PlayAnimation("picking")

        if inst.components.pickable:IsBarren() then
            inst.AnimState:PushAnimation("empty_to_dead")
            inst.AnimState:PushAnimation("idle_dead", false)
        else
            inst.AnimState:PushAnimation("picked", false)
        end

        -- HMR_UTIL.DropLoot(picker, nil, inst)
    end

    local function ontransplantfn(inst)
        inst.components.pickable:MakeBarren()
    end

    local function OnLoad(inst, data)
        if data then
            -- data[组件名字]是该组件保存的数据！！不可覆盖！！
            inst.from_seeds = data.from_seeds
            if inst.from_seeds == true then
                if inst.components.witherable ~= nil then
                    inst.components.witherable:Enable(false)
                end
            end
        end
    end

    local function OnSave(inst, data)
        data.from_seeds = inst.from_seeds
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(name..".tex")

        inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.MEDIUM] / 2) --plantables deployspacing/2

        inst:AddTag("hmr_cherry")
        inst:AddTag("hmr_cherry_grass")
        inst:AddTag("plant")
        inst:AddTag("silviculture") -- for silviculture book
        inst:AddTag("witherable")   --witherable (from witherable component) added to pristine state for optimization

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)

        inst.scrapbook_specialinfo = "NEEDFERTILIZER"

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
        local color = 0.9 + math.random() * 0.1
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(nil, TUNING.HMR_CHERRY_GRASS_PICK_RENGE)--total_day_time*3
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
        inst.components.pickable.onregenfn = onregenfn
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
        inst.components.pickable.makebarrenfn = makebarrenfn
        inst.components.pickable.max_cycles = TUNING.HMR_CHERRY_GRASS_MAX_CYCLES
        inst.components.pickable.cycles_left = TUNING.HMR_CHERRY_GRASS_MAX_CYCLES
        inst.components.pickable.ontransplantfn = ontransplantfn
        inst.components.pickable.use_lootdropper_for_product = true

        inst:AddComponent("witherable")

        inst:AddComponent("lootdropper")
        if data.shared_loot_able then
            inst.components.lootdropper:SetChanceLootTable(name)
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL


        if not GetGameModeProperty("disable_transplanting") then
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up)
            inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_GRASS_DIGS)
        end

        MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
        MakeSmallPropagator(inst)

        MakeNoGrowInWinter(inst)

        MakeWaxablePlant(inst)

        MakeHauntableIgnite(inst)

        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        return inst
    end
    table.insert(prefs, Prefab(name, fn, assets))
    table.insert(prefs, WAXED_PLANTS.CreateDugWaxedPlant({name = name.."_dug", bank = name, build = name, anim = "dropped"}))
    table.insert(prefs, WAXED_PLANTS.CreateWaxedPlant({
        prefab=name,
        bank=name,
        build=name,
        minimapicon=name,
        anim = "idle",
        action = "DIG",
        physics = {MakeSmallObstaclePhysics, 0.1},
        animset = {
            idle         = { anim = "idle", hidesymbols = {}},
            picked       = { anim = "idle", hidesymbols = {}},
            dead         = { anim = "dead" },
        },
        getanim_fn = function(inst)
            if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
                return "idle"
            end
            if (
                inst.components.pickable ~= nil and
                inst.components.pickable:IsBarren()
            ) or (
                inst.components.witherable ~= nil and
                inst.components.witherable:IsWithered()
            ) then
                return "dead"
            end

            return "picked"
        end,
        assets = {Asset("SCRIPT", "scripts/prefabs/waxed_plant_common.lua")},
    }))
end

-- 樱绒草
MakeGrass("hmr_cherry_grass", {
    withered_product = "twigs",                     -- 枯萎后的产品
    shared_loot_able = {
        {"hmr_cherry_fluffy_ball",  1.00},
        {"hmr_cherry_fluffy_ball",  0.50},
        {"hmr_cherry_fluffy_ball",  0.10},
        {"cutgrass",                0.50},
        {"hmr_cherry_grass_seeds",  0.05},
    },
    dug_prefabs = {
        {
            name = "hmr_cherry_grass_seeds",
            build = "hmr_cherry_grass_seeds",
            bank = "hmr_cherry_grass_seeds",
            anim = "idle",
            from_seeds = true,
        },
        {
            name = "hmr_cherry_grass_dug",
            build = "hmr_cherry_grass",
            bank = "hmr_cherry_grass",
            anim = "dropped",
            from_seeds = false,
        }
    },
    products = {
        {
            name = "hmr_cherry_fluffy_ball",
            common_postinit = function(inst)
            end,
            master_postinit = function(inst)
            end,
        },
        -- {
        --     name = "hmr_cherry_grass_seeds",
        --     common_postinit = function(inst)
        --     end,
        --     master_postinit = function(inst)
        --     end,
        -- },
    }
})

return unpack(prefs)