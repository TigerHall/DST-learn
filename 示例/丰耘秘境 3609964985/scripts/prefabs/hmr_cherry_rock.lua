local prefs = {}

SetSharedLootTable("hmr_cherry_rock_short",
{
    {'rocks',                   1.00},
})

SetSharedLootTable("hmr_cherry_rock_med",
{
    {'rocks',                   1.00},
    {'rocks',                   1.00},
    {'hmr_cherry_rock_item',    0.50},
})

SetSharedLootTable("hmr_cherry_rock_tall",
{
    {'rocks',                   1.00},
    {'rocks',                   1.00},
    {'hmr_cherry_rock_item',    1.00},
    {'hmr_cherry_rock_item',    1.00},
    {'hmr_cherry_rock_item',    0.50},
    {'ice',                     1.00},
    {'ice',                     0.20},
})

local function SetShort(inst)
    inst.AnimState:PlayAnimation("short_idle")
    inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_ROCK_SHORT_MINES)
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_rock_short")
end

local function SetMed(inst)
    inst.AnimState:PlayAnimation("med_idle")
    inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_ROCK_MED_MINES)
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_rock_med")
end

local function GrowMed(inst)
    local new = ReplacePrefab(inst, "hmr_cherry_rock_med")
    new.SoundEmitter:PlaySound("dontstarve/creatures/pengull/splash")
    new.AnimState:PlayAnimation("short_to_med")
    new.AnimState:PushAnimation("med_idle", true)
end

local function SetTall(inst)
    inst.AnimState:PlayAnimation("tall_idle")
    inst.components.workable:SetWorkLeft(TUNING.HMR_CHERRY_ROCK_TALL_MINES)
    inst.components.lootdropper:SetChanceLootTable("hmr_cherry_rock_tall")
end

local function GrowTall(inst)
    local new = ReplacePrefab(inst, "hmr_cherry_rock_tall")
    new.SoundEmitter:PlaySound("dontstarve/creatures/pengull/splash")
    new.AnimState:PlayAnimation("med_to_tall")
    new.AnimState:PushAnimation("tall_idle", true)
end

local STAGES =
{
    {
        name = "hmr_cherry_rock_short",
        time = function(inst) return TUNING.HMR_CHERRY_ROCK_SHORT_GROW_TIME end,
        fn = SetShort
    },
    {
        name = "hmr_cherry_rock_med",
        time = function(inst) return TUNING.HMR_CHERRY_ROCK_MED_GROW_TIME end,
        fn = SetMed,
        growfn = GrowMed,
    },
    {
        name = "hmr_cherry_rock_tall",
        time = function(inst) return TUNING.HMR_CHERRY_ROCK_TALL_GROW_TIME end,
        fn = SetTall,
        growfn = GrowTall,
    },
}

local function MakeRock(name, data)
    local assets =
    {
        Asset("ANIM", "anim/hmr_cherry_rock.zip"),
    }

    local function OnWorked(inst, worker, workleft, numworks)
        inst.AnimState:PlayAnimation(data.stagename.."_hit")
        inst.AnimState:PushAnimation(data.stagename.."_idle", false)
    end

    local function OnFinished(inst, worker)
        inst.components.lootdropper:DropLoot()

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if data.material ~= nil then
            fx:SetMaterial(data.material)
        end

        local rock_prefab = (data.stagename == "tall" and "hmr_cherry_rock_med") or
                           (data.stagename == "med" and "hmr_cherry_rock_short") or nil
        if rock_prefab then
            local rock = SpawnPrefab(rock_prefab)
            rock.Transform:SetPosition(inst.Transform:GetWorldPosition())
            rock.AnimState:PlayAnimation(data.stagename == "tall" and "tall_to_med" or "med_to_short")
            rock.AnimState:PushAnimation(data.stagename == "tall" and "med_idle" or "short_idle", false)
        end

        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
        inst.entity:AddAnimState()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("hmr_cherry_rock.tex")

        inst.AnimState:SetBank("hmr_cherry_rock")
        inst.AnimState:SetBuild("hmr_cherry_rock")
        inst.AnimState:PlayAnimation(string.gsub(name, "^hmr_cherry_rock_", "").."_idle")

        inst:AddTag("antlion_sinkhole_blocker")
        inst:AddTag("hmr_cherry")
        inst:AddTag("hmr_cherry_rock")

        MakeObstaclePhysics(inst, .2 + data.stage * 0.2)

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        local colour = math.random() * 0.2 + 0.9
        inst.AnimState:SetMultColour(colour, colour, colour, 0.8)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable(name)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(data.workleft)
        inst.components.workable:SetOnWorkCallback(OnWorked)
        inst.components.workable:SetOnFinishCallback(OnFinished)

        inst:AddComponent("growable")
        inst.components.growable.stages = STAGES
        inst.components.growable:SetStage(data.stage)
        inst.components.growable.loopstages = false
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        MakeSnowCovered(inst)

        MakeHauntableWork(inst)

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

MakeRock("hmr_cherry_rock_short", {
    stage = 1,
    stagename = "short",
    workleft = TUNING.HMR_CHERRY_ROCK_SHORT_MINES,
})
MakeRock("hmr_cherry_rock_med", {
    stage = 2,
    stagename = "med",
    workleft = TUNING.HMR_CHERRY_ROCK_MED_MINES,
})
MakeRock("hmr_cherry_rock_tall", {
    stage = 3,
    stagename = "tall",
    workleft = TUNING.HMR_CHERRY_ROCK_TALL_MINES,
})

local function MakeRockItem(name, data)
    local assets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
    }
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("product")
        inst:AddTag("hmr_cherry_rock_item")

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
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
        inst.components.inventoryitem.imagename = name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
        MakeSmallPropagator(inst)

        MakeHauntableIgnite(inst)

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

MakeRockItem("hmr_cherry_rock_item", {
})

return unpack(prefs)
