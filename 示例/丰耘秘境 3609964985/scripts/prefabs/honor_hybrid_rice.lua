local prefs = {}

local CANOPY_SHADOW_DATA = require("prefabs/canopyshadows")

local NEW_VINES_SPAWN_RADIUS_MIN = 6
local MIN = TUNING.SHADE_CANOPY_RANGE_SMALL
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER

SetSharedLootTable("honor_hybrid_rice_stage1",
{
    {'honor_hybrid_rice_seed',  1.00},
})

SetSharedLootTable("honor_hybrid_rice_stage2",
{
    {'honor_hybrid_rice_seed',  1.00},
    {'honor_greenjuice',        1.00},
    {'honor_greenjuice',        1.00},
    {'honor_greenjuice',        0.50},
})

SetSharedLootTable("honor_hybrid_rice_stage3",
{
    {'honor_hybrid_rice_seed',  1.00},
    {'honor_plantfibre',        1.00},
    {'honor_plantfibre',        1.00},
    {'honor_plantfibre',        1.00},
    {'honor_plantfibre',        0.50},
    {'honor_rice',              1.00},
    {'honor_rice',              0.50},
    {'honor_rice_seeds',        1.00},
    {'honor_rice_seeds',        0.50},
})

SetSharedLootTable("honor_hybrid_rice_stage4",
{
    {'honor_hybrid_rice_seed',  1.00},
    {'honor_hybrid_rice_seed',  1.00},
    {'honor_hybrid_rice_seed',  0.30},
    {'honor_splendor',          1.00},
    {'honor_splendor',          0.50},
    {'honor_rice_prime',        0.40},
    {'honor_rice_prime',        0.10},
})

local function SetShort(inst)
    inst:AddTag("shelter")
end

local function SetSmall(inst)
    inst:AddTag("shelter")
end

local function GrowSmall(inst)
    local new = ReplacePrefab(inst, "honor_hybrid_rice_stage2")
    new.SoundEmitter:PlaySound("dontstarve/creatures/pengull/splash")
    new.AnimState:PlayAnimation("2_turn")
    new.AnimState:PushAnimation("2_stop", true)
end

local function SetMed(inst)
    inst:AddTag("shelter")
end

local function GrowMed(inst)
    local new = ReplacePrefab(inst, "honor_hybrid_rice_stage3")
    new.SoundEmitter:PlaySound("dontstarve/creatures/pengull/splash")
    new.AnimState:PlayAnimation("3_turn")
    new.AnimState:PushAnimation("3_stop", true)
end

local function SetTall(inst)
    inst:AddTag("shelter")
end

local function GrowTall(inst)
    local new = ReplacePrefab(inst, "honor_hybrid_rice_stage4")
    new.splendor_num = inst.splendor_num or 0
    new.SoundEmitter:PlaySound("dontstarve/creatures/pengull/splash")
    new.AnimState:PlayAnimation("turn")
    new.AnimState:PushAnimation("tree")
end

local growth_stages =
{
    {
        name = "honor_hybrid_rice_stage1",
        time = function(inst) return 16*30 end,
        fn = SetShort
    },
    {
        name = "honor_hybrid_rice_stage2",
        time = function(inst) return 8*30 end,
        fn = SetSmall,
        growfn = GrowSmall,
    },
    {
        name = "honor_hybrid_rice_stage3",
        time = function(inst) return 20*30 end,
        fn = SetMed,
        growfn = GrowMed,
    },
    {
        name = "honor_hybrid_rice_stage4",
        fn = SetTall,
        growfn = GrowTall,
    },
}

local function OnDestroyed(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function MakeTree(name, data)
    local assets = {
        Asset("ANIM", "anim/honor_hybrid_rice_stages.zip"),
        Asset("ANIM", "anim/honor_hybrid_rice_tree.zip"),
        -- Asset("ANIM", "anim/honor_hybird_rice_spike.zip"),
    }
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("oceantree_tall.png")
        inst.MiniMapEntity:SetPriority(-1)

        MakeObstaclePhysics(inst, data.stage == 4 and 0.7 or 0.4)

        inst.AnimState:SetBank(data.stage == 4 and "honor_hybrid_rice_tree" or "honor_hybrid_rice_stages")
        inst.AnimState:SetBuild(data.stage == 4 and "honor_hybrid_rice_tree" or "honor_hybrid_rice_stages")
        inst.AnimState:PlayAnimation(data.anim, true)

        inst:AddTag("antlion_sinkhole_blocker")
        inst:AddTag("birdblocker")
        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("shelter")

        if data.common_postinit then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(data.stage)
        inst.components.growable.loopstages = false
        inst.components.growable.magicgrowable = false
        inst.components.growable:StopGrowing()

        if data.max_work then
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(name == "honor_hybrid_rice_stage1" and ACTIONS.DIG or ACTIONS.CHOP)
            inst.components.workable:SetWorkLeft(data.max_work)
            inst.components.workable:SetOnFinishCallback(OnDestroyed)
        end

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable(name)

        MakeHauntable(inst)

        if data.master_postinit then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end

-- 阶段1（种下）
MakeTree("honor_hybrid_rice_stage1", {
    anim = "1_stop",
    stage = 1,
    max_work = 1,
    common_postinit = function(inst)
        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:SetDeploySmartRadius(3)
    end,
    master_postinit = function(inst)
        inst.greenjuice_num = 0

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        local function AcceptTest(inst, item)
            if item ~= nil and item.prefab == "honor_greenjuice"then
                return true
            end
            return false
        end

        local function OnAccept(inst, giver, item)
            inst.greenjuice_num = inst.greenjuice_num + 1
            if inst.greenjuice_num >= 10  then
                if inst.components.growable then
                    inst.components.growable:StartGrowing()
                end
                inst.AnimState:PlayAnimation("1_turn_grow")
                inst.AnimState:PushAnimation("1_growing", true)

                if inst.components.trader ~= nil then
                    inst:RemoveComponent("trader")
                end
            end
        end

        inst:AddComponent("trader")
        inst.components.trader:SetOnAccept(OnAccept)
        inst.components.trader:SetAcceptTest(AcceptTest)

        local function OnSave(inst, data)
            data.greenjuice_num = inst.greenjuice_num or 0
        end

        local function OnLoad(inst, data)
            if data ~= nil then
                inst.greenjuice_num = data.greenjuice_num or 0
                if inst.greenjuice_num >= 10 then
                    if inst.components.trader ~= nil then
                        inst:RemoveComponent("trader")
                    end
                    inst.AnimState:PlayAnimation("1_growing", true)
                else
                    inst.AnimState:PlayAnimation("1_stop", true)
                end
            end
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
    end
})

-- 阶段2（成长）
MakeTree("honor_hybrid_rice_stage2", {
    anim = "2_stop",
    stage = 2,
    max_work = 8,
    common_postinit = function(inst)
        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)
    end,
    master_postinit = function(inst)
        inst.plantfibre_num = 0

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        local function AcceptTest(inst, item)
            if item ~= nil and item.prefab == "honor_plantfibre"then
                return true
            end
            return false
        end

        local function OnAccept(inst, giver, item)
            inst.plantfibre_num = inst.plantfibre_num + 1
            if inst.plantfibre_num >= 12  then
                if inst.components.growable then
                    inst.components.growable:StartGrowing()
                end
                inst.AnimState:PlayAnimation("2_turn_grow")
                inst.AnimState:PushAnimation("2_growing", true)

                if inst.components.trader then
                    inst:RemoveComponent("trader")
                end
            end
        end

        inst:AddComponent("trader")
        inst.components.trader:SetOnAccept(OnAccept)
        inst.components.trader:SetAcceptTest(AcceptTest)

        local function OnSave(inst, data)
            data.plantfibre_num = inst.plantfibre_num or 0
        end

        local function OnLoad(inst, data)
            if data ~= nil then
                inst.plantfibre_num = data.plantfibre_num or 0
                if inst.plantfibre_num >= 12 then
                    if inst.components.trader ~= nil then
                        inst:RemoveComponent("trader")
                    end
                    inst.AnimState:PlayAnimation("2_growing", true)
                else
                    inst.AnimState:PlayAnimation("2_stop", true)
                end
            end
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
    end
})

-- 阶段3（成熟）
MakeTree("honor_hybrid_rice_stage3", {
    anim = "3_stop",
    stage = 3,
    max_work = 12,
    common_postinit = function(inst)
        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)
    end,
    master_postinit = function(inst)
        inst.splendor_num = 0

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        local function AcceptTest(inst, item)
            if item ~= nil and item.prefab == "honor_splendor"then
                return true
            end
            return false
        end

        local function OnAccept(inst, giver, item)
            inst.splendor_num = inst.splendor_num + 1
            if inst.splendor_num == 5  then
                if inst.components.growable then
                    inst.components.growable:StartGrowing()
                end
                inst.AnimState:PlayAnimation("3_turn_grow")
                inst.AnimState:PushAnimation("3_growing", true)
            end

            if inst.splendor_num >= 8 and inst.components.trader ~= nil then
                inst:RemoveComponent("trader")
            end
        end
        inst:AddComponent("trader")
        inst.components.trader:SetOnAccept(OnAccept)
        inst.components.trader:SetAcceptTest(AcceptTest)

        local function OnSave(inst, data)
            data.splendor_num = inst.splendor_num or 0
        end

        local function OnLoad(inst, data)
            if data ~= nil then
                inst.splendor_num = data.splendor_num or 0
                if inst.splendor_num >= 5 then
                    inst.AnimState:PlayAnimation("3_growing", true)
                else
                    inst.AnimState:PlayAnimation("3_stop", true)
                end

                if inst.splendor_num >= 8 and inst.components.trader ~= nil then
                    inst:RemoveComponent("trader")
                end
            end
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
    end
})

-- 阶段4（巨型）
MakeTree("honor_hybrid_rice_stage4", {
    anim = "tree",
    stage = 4,
    common_postinit = function(inst)
        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:AddTag("shadecanopy")

        inst.AnimState:SetScale(2, 2)

        inst._hascanopy = net_bool(inst.GUID, "hybridrice._hascanopy", "hascanopydirty")
        inst._hascanopy:set(true)

        inst:DoTaskInTime(0, function()
            inst.canopy_data = CANOPY_SHADOW_DATA.spawnshadow(inst, 4)
        end)

        if not TheNet:IsDedicated() then
            inst:AddComponent("distancefade")
            inst.components.distancefade:Setup(15, 25)

            inst:AddComponent("canopyshadows")
            inst.components.canopyshadows.range = math.floor(TUNING.SHADE_CANOPY_RANGE_SMALL/4)


            inst:ListenForEvent("hascanopydirty", function()
                if not inst._hascanopy:value() then
                    inst:RemoveComponent("canopyshadows")
                end
            end)
        end
    end,
    master_postinit = function(inst)
        inst.prime_num = 0  -- 记录给予精华的数量
        inst.vines = {}     -- 记录藤蔓
        inst.players = {}
        inst.splendor_num = 0

        local function OnFar(inst, player)
            if player.under_hybridrice_count then
                player.under_hybridrice_count = player.under_hybridrice_count - 1
                player:PushEvent("onchangehybridricezone", player.under_hybridrice_count > 0)
            end
            inst.players[player] = nil
        end
        local function OnNear(inst, player)
            inst.players[player] = true
            player.under_hybridrice_count = (player.under_hybridrice_count or 0) + 1
            player:PushEvent("onchangehybridricezone", player.under_hybridrice_count > 0)
        end
        inst:AddComponent("playerprox")
        inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
        inst.components.playerprox:SetDist(16, 16)
        inst.components.playerprox:SetOnPlayerFar(OnFar)
        inst.components.playerprox:SetOnPlayerNear(OnNear)

        inst:AddComponent("lightningblocker")--避雷
        inst.components.lightningblocker:SetBlockRange(16)

        local function AcceptTest(inst, item)
            if item ~= nil and item.prefab == "honor_rice_prime" then
                return true
            end
            return false
        end
        local function OnAccept(inst, giver, item)
            inst.prime_num = inst.prime_num + 1
            inst.AnimState:PlayAnimation("give")
            if inst.prime_num >= 3  then
                inst.AnimState:PlayAnimation("disappear")

                inst.components.lootdropper:SpawnLootPrefab("honor_hybrid_rice")
                inst.components.lootdropper:SpawnLootPrefab("honor_hybrid_rice")
                inst.components.lootdropper:SpawnLootPrefab("honor_splendor")

                inst:OnRemoveEntity()
                inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() - FRAMES, inst.Remove)
            end
        end
        inst:AddComponent("trader")
        inst.components.trader:SetOnAccept(OnAccept)
        inst.components.trader:SetAcceptTest(AcceptTest)

        local function removecanopyshadow(inst)
            if inst.canopy_data ~= nil then
                for _, shadetile_key in ipairs(inst.canopy_data.shadetile_keys) do
                    if TheWorld.shadetiles[shadetile_key] ~= nil then
                        TheWorld.shadetiles[shadetile_key] = TheWorld.shadetiles[shadetile_key] - 1
                        if TheWorld.shadetiles[shadetile_key] <= 0 then
                            if TheWorld.shadetile_key_to_leaf_canopy_id[shadetile_key] ~= nil then
                                DespawnLeafCanopy(TheWorld.shadetile_key_to_leaf_canopy_id[shadetile_key])
                                TheWorld.shadetile_key_to_leaf_canopy_id[shadetile_key] = nil
                            end
                        end
                    end
                end
                for _, ray in ipairs(inst.canopy_data.lightrays) do
                    ray:Remove()
                end
            end
        end
        local function removecanopy(inst)
            for _,v in ipairs(inst.vines) do
                if v.fall then
                    v:fall()
                end
            end
            for player in pairs(inst.players) do
                if player:IsValid() then
                    if player.under_hybridrice_count then
                        player.under_hybridrice_count = player.under_hybridrice_count - 1
                        player:PushEvent("onchangehybridricezone", player.under_hybridrice_count > 0)
                    end
                end
            end
            inst._hascanopy:set(false)
        end
        local function OnRemove(inst)
            removecanopy(inst)
            removecanopyshadow(inst)
            for k, v in ipairs(inst.vines) do
                if v ~= nil and v:IsValid() and v.fall then
                    v:fall()
                end
            end
            inst:OnRemoveEntity()
        end
        inst:ListenForEvent("onremove", OnRemove)

        local function spawnvine(inst)
            local x, _, z = inst.Transform:GetWorldPosition()
            local radius_variance = MAX - NEW_VINES_SPAWN_RADIUS_MIN
            local vine = SpawnPrefab("honor_hybrid_rice_vine")
            vine.components.pickable:MakeEmpty()
            local theta = math.random() * TWOPI
            local offset = NEW_VINES_SPAWN_RADIUS_MIN + radius_variance * math.random()
            vine.Transform:SetPosition(x + math.cos(theta) * offset, 0, z + math.sin(theta) * offset)
            vine:fall_down_fn()
            vine.SoundEmitter:PlaySound("dontstarve/movement/foley/hidebush")
            inst.vines = inst.vines or {}
            vine.components.entitytracker:TrackEntity("tree", inst)
            table.insert(inst.vines, vine)
        end
        local function CheckVines(inst)
            if inst.droppedvines then return end
            inst:DoTaskInTime(2 + math.random(),function() spawnvine(inst) end)
            inst:DoTaskInTime(2.5 + math.random(),function() spawnvine(inst) end)
            inst:DoTaskInTime(2.5 + math.random(),function() spawnvine(inst) end)
            if inst.splendor_num > 5 then
                for i = 1, inst.splendor_num - 5 do
                    inst:DoTaskInTime(3 + math.random(),function() spawnvine(inst) end)
                end
            end
            inst.droppedvines = true
        end
        inst:DoTaskInTime(0, CheckVines)

        local function OnIsDay(inst)
            if TheWorld.state.isday then
                local target_vine_num = 3 + math.clamp(inst.splendor_num - 5, 0, 5)
                if inst.vines and #inst.vines < target_vine_num then
                    for i = 1, target_vine_num - #inst.vines do
                        spawnvine(inst)
                    end
                end
            end
        end
        inst:WatchWorldState("isday", OnIsDay)

        local OCEANVINES_MUST_TAGS = {"oceanvine"}
        local SHADECANOPY_ONEOF_TAGS = { "shadecanopy", "shadecanopysmall" }
        local function OnRemoveEntity(inst)
            for player in pairs(inst.players) do
                if player:IsValid() then
                    if player.canopytrees then
                        OnFar(inst, player)
                    end
                end
            end

            local x, y, z = inst.Transform:GetWorldPosition()
            local oceanvines = TheSim:FindEntities(x, 0, z, MAX+1, OCEANVINES_MUST_TAGS)

            local oceanvines_count = #oceanvines

            if oceanvines_count <= 0 then
                inst._hascanopy:set(false)
                return
            end

            -- First remove all vines that are not in range of other oceantree_pillars.
            for i = oceanvines_count, 1, -1 do
                local ent = oceanvines[i]

                if ent ~= nil then
                    x, y, z = ent.Transform:GetWorldPosition()

                    local should_fall = TheSim:CountEntities(x, 0, z, MAX-5, nil, nil, SHADECANOPY_ONEOF_TAGS) <= 1 -- 1 because of us.

                    if should_fall then
                        ent.fall(ent)
                        table.remove(oceanvines, i)
                    end
                end
            end

            -- Then check if we've removed at least 3, if not, remove them.
            local num_to_remove = 3 - (oceanvines_count - #oceanvines)

            if num_to_remove > 0 then
                for i = num_to_remove, 1, -1 do
                    local ent = oceanvines[i]
                    if ent ~= nil then
                        ent.fall(ent)
                    end
                end
            end

            inst._hascanopy:set(false)
        end
        inst.OnRemoveEntity = OnRemoveEntity

        local function OnSave(inst, data)
            data.splendor_num = inst.splendor_num or 0
            data.prime_num = inst.prime_num or 0
            data.droppedvines = inst.droppedvines or false
        end
        local function OnLoad(inst, data)
            inst.splendor_num = data and data.splendor_num or 0
            inst.prime_num = data and data.prime_num or 0
            inst.droppedvines = data and data.droppedvines or false
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
    end
})

----------------------------------------------------------------------------
---[[稻穗（藤蔓）]]
----------------------------------------------------------------------------
local assets=
{
	Asset("ANIM", "anim/oceanvine.zip"),
    Asset("MINIMAP_IMAGE", "oceanvine"),
}

local function falldown(inst)
    inst.AnimState:PlayAnimation("spawn", false)
    inst.AnimState:PushAnimation("idle_fruit", true)
end

local function onpicked(inst, picker, loot)
    inst.AnimState:PlayAnimation("harvest", false)
    inst.AnimState:PushAnimation("idle_nofruit", true)

    if inst.components.inspectable ~= nil then
        inst:RemoveComponent("inspectable")
    end

    local pos = inst:GetPosition()
    if math.random() < 0.4 then
        for i = 1, 2 do
            local fruit = SpawnPrefab("honor_rice")
            if picker.components.inventory then
                picker.components.inventory:GiveItem(fruit, nil, pos)
            else
                fruit.Transform:SetPosition(pos:Get())
            end
        end
    else
        local fruit = SpawnPrefab("honor_splendor")
        if picker.components.inventory then
            picker.components.inventory:GiveItem(fruit, nil, pos)
        else
            fruit.Transform:SetPosition(pos:Get())
        end
    end
end

local function makeempty(inst)
    inst.AnimState:Hide("fig")
    inst.AnimState:PlayAnimation("idle_nofruit", true)

    if inst.components.inspectable ~= nil then
        inst:RemoveComponent("inspectable")
    end
end

local function makefull(inst)
    inst.AnimState:Show("fig")
    if POPULATING then
        inst.AnimState:PlayAnimation("idle_fruit", true)
    else
        inst.AnimState:PlayAnimation("fruit_grow", false)
        inst.AnimState:PushAnimation("idle_fruit", true)
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
    end
end

local function onloadpostpass(inst, newents, savedata)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    local tree = inst.components.entitytracker:GetEntity("tree")
    if tree ~= nil then
        tree.vines = tree.vines or {}
        table.insert(tree.vines, inst)
    end
end

local function fall(inst)
    inst.persists = false
    local point = inst:GetPosition()
    local onland = TheWorld.Map:IsVisualGroundAtPoint(point.x,point.y,point.z) or TheWorld.Map:GetPlatformAtPoint(point.x,point.z)
    if onland then
        inst.AnimState:PlayAnimation("fall_land", false)
        inst:ListenForEvent("animover", function() ErodeAway(inst) end)
    else
        inst.AnimState:PlayAnimation("fall_ocean", false)
        inst:ListenForEvent("animover", function() inst:Remove() end)
    end
    inst:DoTaskInTime(19*FRAMES, function()
        if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
            local point = inst:GetPosition()
            inst.components.pickable:MakeEmpty()
            -- local product = SpawnPrefab(inst.components.pickable.product)
            -- product.Transform:SetPosition(point.x, 0, point.z)
        end
    end)
end

local function VineOnRemove(inst)
    local tree = inst.components.entitytracker:GetEntity("tree")
    if tree ~= nil and tree.vines ~= nil then
        for i, v in ipairs(tree.vines) do
            if v == inst then
                table.remove(tree.vines, i)
                break
            end
        end
    end
end

local function vinefn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- inst.MiniMapEntity:SetIcon("oceanvine.png")

	inst.shadow:SetSize( 1.5, .75 )

	inst.AnimState:SetBank("oceanvine")
    inst.AnimState:SetBuild("oceanvine")
	inst.AnimState:PlayAnimation("idle_fruit", true)

	inst:AddTag("hangingvine")
    inst:AddTag("flying")
    inst:AddTag("NOBLOCK")
    inst:AddTag("oceanvine")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable.onpickedfn = onpicked
    inst.components.pickable.makeemptyfn = makeempty
    inst.components.pickable.makefullfn = makefull
    inst.components.pickable.baseregentime = 16*30
    inst.components.pickable.regentime = 16*30
    -- inst.components.pickable.max_cycles = nil
    -- inst.components.pickable.cycles_left = 1

    inst:AddComponent("entitytracker")

    MakeHauntableIgnite(inst)

    inst:ListenForEvent("onremove", VineOnRemove)

    inst.fall_down_fn = falldown
    inst.fall = fall
    inst.OnLoadPostPass = onloadpostpass

	return inst
end

table.insert(prefs, Prefab("honor_hybrid_rice_vine", vinefn, assets))

-- 种子
local seedassets =
{
    Asset("ANIM", "anim/honor_hybrid_rice_seed.zip"),
}

local function OnDeploy(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab("honor_hybrid_rice_stage1")
    plant.Transform:SetPosition(pt.x, 0, pt.z)

	plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)

    inst:Remove()
end

local function seedfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("honor_hybrid_rice_seed")
    inst.AnimState:SetBuild("honor_hybrid_rice_seed")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/honor_hybrid_rice_seed.xml"

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
    inst.components.deployable.ondeploy = OnDeploy

    MakeHauntableWork(inst)
    MakeSmallBurnable(inst)

    return inst
end

table.insert(prefs, Prefab("honor_hybrid_rice_seed", seedfn, seedassets))
table.insert(prefs, MakePlacer("honor_hybrid_rice_seed_placer", "honor_hybrid_rice_stages", "honor_hybrid_rice_stages", "1_stop"))

return unpack(prefs)