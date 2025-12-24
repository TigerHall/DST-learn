local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

local assets =
{
    Asset("ANIM", "anim/honor_tower.zip"),
    Asset("ANIM", "anim/honor_tower_ui_6x12.zip"),
}

local RANGE = 20

local PERISH_MULT = {
    [3] = 0.75,
    [8] = 0.5,
    [10] = 0,
    [15] = -0.5,
    [20] = -1,
    [32] = -5,
    [50] = -10,
}

local function onbuiltsound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_craft")
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0.15, onbuiltsound)
end

local function onopen(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_open")
end

local function onclose(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_close")
end

local function CanUse(remote, amount)
    if remote == nil or not remote:IsValid() or remote.components.finiteuses == nil then
        return false
    end

    local MAX_USE_PER = HMR_CONFIGS.HONOR_STOWER_MAX_CONSUME
    if MAX_USE_PER == 0 then
        return remote.components.finiteuses:GetUses() > amount
    else
        if remote._init_uses == nil then
            remote._init_uses = remote.components.finiteuses:GetUses()
        end
        if remote._init_uses - remote.components.finiteuses:GetUses() - amount >= MAX_USE_PER * remote.components.finiteuses.total then
            remote._init_uses = nil
            return false
        else
            return true
        end
    end
end

local function UseRemote(inst, remote, amount)
    if remote then
        if not CanUse(remote, amount) then
            return false
        end
        if remote.components.finiteuses then
            if remote.components.finiteuses:GetUses() <= 0 then
                return false
            end
            remote.components.finiteuses:Use(amount or 1)
            return true
        end
    end
    return false
end

----------------------------------------------------------------------------
-- 照料
----------------------------------------------------------------------------
local function SetReleaseFx(x, y, z)
    local fx = SpawnPrefab("farm_plant_happy")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
    end
end

local function CareNext(inst, remote, doer)
    while #inst._care_targets > 0 do
        local target = table.remove(inst._care_targets, 1)
        local success = false

        -- 照料
        if target.components.farmplanttendable ~= nil and target.components.farmplanttendable.tendable then
            if UseRemote(inst, remote, 1) then
                target.components.farmplanttendable:TendTo(inst)
                success = true
            else
                break
            end
        end

        -- 浇水
        if target.components.witherable ~= nil then
            -- 如果植物可以枯萎或复苏，保护植物并减少自身湿度
            if not target.components.witherable:IsProtected() and (target.components.witherable:CanWither() or target.components.witherable:CanRejuvenate()) then
                if UseRemote(inst, remote, 1) then
                    target.components.witherable:Protect(TUNING.FIRESUPPRESSOR_PROTECTION_TIME)
                    success = true
                else
                    break
                end
            end
        elseif target.components.moisture ~= nil then
            -- 如果植物有湿度组件，增加其湿度并减少自身湿度
            local moisture = target.components.moisture
            local need = moisture:GetMaxMoisture() - moisture:GetMoisture()
            if need > 0 then
                if UseRemote(inst, remote, 1) then
                    moisture:DoDelta(need, true)
                    success = true
                else
                    break
                end
            end
        end

        -- 施肥
        if target.components.pickable ~= nil and target.components.pickable:CanBeFertilized() then
            -- 如果植物可以施肥，施肥
            if UseRemote(inst, remote, 3) then
                local poop = SpawnPrefab("poop")
                if poop ~= nil then
                    target.components.pickable:Fertilize(poop, nil)
                    poop:Remove()
                    success = true
                end
            else
                break
            end
        end

        if success then
            SetReleaseFx(target.Transform:GetWorldPosition())
        end
        inst:DoTaskInTime(FRAMES, function() CareNext(inst, remote, doer) end)
        break
    end
end

local function SortTiles(a, b)
    if a and b then
        return a[3] + a[4] + a[5] > b[3] + b[4] + b[5]
    end
end

local function CareNextTile(inst, remote, doer)
    while #inst._care_tiles > 0 do
        if UseRemote(inst, remote, 1) then
            local tile = table.remove(inst._care_tiles, 1)
            local min_n = math.max(tile[3], tile[4], tile[5])
            -- print("最小值", min_n, "剩余", tile[3], tile[4], tile[5])
            local add_1, add_2, add_3 = 0, 0, 0
            if tile[3] == min_n then
                add_1 = 10
                tile[3] = math.max(0, tile[3] - 10)
            elseif tile[4] == min_n then
                add_2 = 10
                tile[4] = math.max(0, tile[4] - 10)
            else
                add_3 = 10
                tile[5] = math.max(0, tile[5] - 10)
            end
            local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(tile[1], 0, tile[2])
            TheWorld.components.farming_manager:AddTileNutrients(tile_x, tile_z, add_1, add_2, add_3)
            SetReleaseFx(tile[1], 0, tile[2])

            if tile[3] + tile[4] + tile[5] > 0 then
                table.insert(inst._care_tiles, tile)
                table.sort(inst._care_tiles, SortTiles)
            end

            inst:DoTaskInTime(FRAMES / 5, function() CareNextTile(inst, remote, doer) end)
            break
        end
        break
    end
end

local function DoTakecare(inst, remote, doer)
    local x, y, z = inst.Transform:GetWorldPosition()
    local takecare_fx = SpawnPrefab("ghostlyelixir_shield_fx")
    takecare_fx.Transform:SetPosition(x, y, z)

    -- 实体
    inst._care_targets = TheSim:FindEntities(x, y, z, RANGE, nil, { "INLIMBO", "NOCLICK" }, {"farm_plant", "plant", "tendable_farmplant", "farmplantstress", "bush"})
    CareNext(inst, remote, doer)

    -- 地面
    inst._care_tiles = {}
    for k1 = -RANGE, RANGE, 4 do
        for k2 = -RANGE, RANGE, 4 do
            local tile = TheWorld.Map:GetTileAtPoint(x + k1, 0, z + k2)
            if tile == GROUND.FARMING_SOIL then
                if UseRemote(inst, remote, 1) then
                    TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x + k1, 0, z + k2, 100)
                else
                    inst._care_tiles = {}
                    return
                end
                local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x + k1, 0, z + k2)
                local n1, n2, n3 = TheWorld.components.farming_manager:GetTileNutrients(tile_x, tile_z)
                if n1 < 100 or n2 < 100 or n3 < 100 then
                    table.insert(inst._care_tiles, {x + k1, z + k2, 100 - n1, 100 - n2, 100 - n3, })
                end
            end
        end
    end

    if remote and remote:IsValid() and remote.components.finiteuses and #inst._care_tiles > 0 then
        table.sort(inst._care_tiles, SortTiles)
        CareNextTile(inst, remote, doer)
    end
end

----------------------------------------------------------------------------
-- 收获
----------------------------------------------------------------------------
local function HarvestNext(inst, remote, doer)
    while #inst._harvest_targets > 0 do
        local target = table.remove(inst._harvest_targets, 1)
        local target_pos = target and target:IsValid() and target:GetPosition() or nil
        local pt = target_pos or inst and inst:IsValid() and inst:GetPosition() or doer and doer:IsValid() and doer:GetPosition() or Vector3(0, 0, 0)
        local success = false
        local loots = {}
        if target.components.pickable ~= nil and target.components.pickable:CanBePicked() then
            if UseRemote(inst, remote, 1) then
                success, loots = target.components.pickable:Pick(TheWorld)
            else
                break
            end
        elseif target.components.crop ~= nil and target.components.crop:IsReadyForHarvest() then
            if UseRemote(inst, remote, 1) then
                success, loots = target.components.crop:Harvest()
            else
                break
            end
        end
        if success then
            local fx = SpawnPrefab("shadow_puff")
            local ex, ey, ez = target.Transform:GetWorldPosition()
            fx.Transform:SetPosition(ex, ey, ez)

            if loots and #loots > 0 then
                for _, loot in pairs(loots) do
                    if loot and loot:IsValid() then
                        if inst:CanStore(loot) then
                            Launch(loot, doer, 1.5)
                            loot:DoTaskInTime(0.5 + math.random() * 0.5, function()
                                if loot and loot:IsValid() and loot.components.inventoryitem and loot.components.inventoryitem.owner == nil then
                                    local fx2 = SpawnPrefab("shadow_puff")
                                    local ex2, ey2, ez2 = loot.Transform:GetWorldPosition()
                                    fx2.Transform:SetPosition(ex2, ey2, ez2)
                                    inst.components.container:GiveItem(loot)
                                end
                            end)
                        elseif doer and doer:IsValid() and doer.components.inventory and doer.components.inventory:CanAcceptCount(loot) then
                            doer.components.inventory:GiveItem(loot, nil, target_pos)
                        elseif pt then -- pt应该一定会有的
                            HMR_UTIL.DropLoot(nil, loot, nil, pt)
                        end
                    end
                end
            end
        end
        inst:DoTaskInTime(FRAMES, function() HarvestNext(inst, remote, doer) end)
        break
    end
end

local function DoHarvest(inst, remote, doer)
    local x, y, z = inst.Transform:GetWorldPosition()
    local harvest_fx = SpawnPrefab("ghostlyelixir_retaliation_fx")
    harvest_fx.Transform:SetPosition(x, y, z)

    -- TODO:所有期望被采摘的都有plant标签吗？
    inst._harvest_targets = TheSim:FindEntities(x, y, z, RANGE, {"plant"}, { "INLIMBO", "NOCLICK" })
    HarvestNext(inst, remote, doer)
end

----------------------------------------------------------------------------
-- 敲碎
----------------------------------------------------------------------------
local function HarmNext(inst, remote, doer)
    while #inst._harm_targets > 0 do
        local target = table.remove(inst._harm_targets, 1)
        if target.components.workable ~= nil and target.components.workable:CanBeWorked() then
            if UseRemote(inst, remote, 1) then
                target.components.workable:WorkedBy(doer, 1)
            else
                break
            end
        end

        inst:DoTaskInTime(FRAMES, function() HarmNext(inst, remote, doer) end)
        break
    end
end

local function DoHarm(inst, remote, doer)
    local x, y, z = inst.Transform:GetWorldPosition()
    local harm_fx = SpawnPrefab("ghostlyelixir_speed_fx")
    harm_fx.Transform:SetPosition(x, y, z)

    inst._harm_targets = TheSim:FindEntities(x, y, z, RANGE, { "oversized_veggie" }, { "INLIMBO", "NOCLICK" })
    HarmNext(inst, remote, doer)
end

----------------------------------------------------------------------------
-- 收纳
----------------------------------------------------------------------------
local SPECIAL_ITEMS = {}

local function GetSlotType(slot)
    if slot >= 1 and slot <= 36 then
        return "veggies"
    elseif slot >= 37 and slot <= 72 then
        return "seeds"
    end
    return nil
end

local function CanAcceptItem(inst, item)
    if item.prefab == nil then -- 这个怎么会是空啊...
        return false
    end
    if item.prefab == "spoiled_food" then
        -- 腐烂物
        return true, "spoiled_food"
    end
    if Prefabs[string.lower(item.prefab .. "_seeds")] ~= nil and inst:HasTag("weighable_OVERSIZEDVEGGIES") then
        -- 农作物果实
        print("1")
        return true, "veggies"
    elseif Prefabs[string.lower(string.gsub(item.prefab .. "_seeds", "_cooked", ""))] then
        -- 烤熟的农作物果实
        print("2")
        return true, "veggies"
    elseif string.find(item.prefab, "seed") and (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
        -- 种子
        return true, "seeds"
    elseif item:HasTag("hmr_product") then
        -- 丰耘秘境产品
        print("3")
        return true, "veggies"
    elseif SPECIAL_ITEMS[item.prefab] then
        -- 特殊物品
        print("4")
        return true, "veggies"
    end
end

local function CanStore(inst, item, slot)
    if item == nil then return false end
    local can_store, item_type = CanAcceptItem(inst, item)

    print("CanStore", item.prefab, can_store, item_type, slot)

    if slot == nil then
        return can_store and (not inst.replica.container:IsFull() or inst.replica.container:Has(item.prefab, 1))
    elseif can_store then
        local other_item = inst.replica.container:GetItemInSlot(slot)
        if other_item == nil or
            (other_item.replica.stackable ~= nil and
            other_item.prefab == item.prefab and
            other_item.skinname == item.skinname)
        then
            local slot_type = GetSlotType(slot)
            if item_type ~= nil then
                if item_type == "spoiled_food" then
                    return true
                elseif slot_type and item_type == slot_type then
                    return true
                end
            end
        end
    end

    return false
end

local function StoreNext(inst, remote, doer)
    while #inst._store_targets > 0 do
        local target = table.remove(inst._store_targets, 1)
        if inst:IsValid() and target:IsValid() and inst.components.container ~= nil and
            target.components.inventoryitem ~= nil and target.components.inventoryitem.owner == nil and
            CanStore(inst, target, nil)
        then
            local fx = SpawnPrefab("ghostflower_spirit1_fx")
            local ex, ey, ez = target.Transform:GetWorldPosition()
            fx.Transform:SetPosition(ex, ey, ez)

            inst.components.container:GiveItem(target)
            inst._store_count = inst._store_count + 1
        end
        if inst._store_count < 10 or UseRemote(inst, remote, 1) then
            if inst._store_count >= 10 then
                inst._store_count = 0
            end
            inst:DoTaskInTime(FRAMES / 10, function() StoreNext(inst, remote, doer) end)
            break
        end
        break
    end
end

local function DoStore(inst, remote, doer)
    local x, y, z = inst.Transform:GetWorldPosition()
    local store_fx = SpawnPrefab("ghostlyelixir_attack_fx")
    store_fx.Transform:SetPosition(x, y, z)

    inst._store_count = 0
    inst._store_targets = TheSim:FindEntities(x, y, z, RANGE, nil, {"INLIMBO", "NOCLICK", "smallcreature", "structure", "pickable"})
    StoreNext(inst, remote, doer)
end

local function onhit(inst)
    if inst.components.container ~= nil then
        inst.components.container:Close()
        inst.components.container:DropEverything()
    end
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
end

local function ondestroyed(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function PerishRateMultiplier(inst, item)
    local container = inst.components.container
    if container ~= nil then
        local prefabs = {}
        for k, v in pairs(container.slots) do
            if v and v:IsValid() and v.prefab and prefabs[v.prefab] == nil then
                prefabs[v.prefab] = true
            end
        end

        local kinds = GetTableSize(prefabs)

        local multiplier = 1.0
        local max_key = 0

        for k, v in pairs(PERISH_MULT) do
            if k <= kinds and k > max_key then
                max_key = k
                multiplier = v
            end
        end

        return multiplier
    end
    return 1.0
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:SetPhysicsRadiusOverride(.16)
    MakeObstaclePhysics(inst, 0.2)

    inst.MiniMapEntity:SetIcon("honor_tower.tex")

    inst.AnimState:SetBank("honor_tower")
    inst.AnimState:SetBuild("honor_tower")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("honor_tower")

    inst.CanStore = CanStore

    HMR_UTIL.AddDeployHelper(inst, RANGE, {88 / 255, 88 / 255, 88 / 255, 1}, "hollow2")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("honor_tower")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container:EnableInfiniteStackSize(true)
    -- inst:ListenForEvent("itemget", OnItemChanged)
    --inst:ListenForEvent("itemlose", OnItemChanged)

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst.components.workable:SetOnFinishCallback(ondestroyed)

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(PerishRateMultiplier)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.DoTakecare = DoTakecare
    inst.DoHarvest = DoHarvest
    inst.DoHarm = DoHarm
    inst.DoStore = DoStore

    return inst
end

return Prefab("honor_tower", fn, assets),
    HMR_UTIL.MakePlacerWithRange("honor_tower_placer", "honor_tower", "honor_tower", "idle", RANGE, {type = "hollow2"})