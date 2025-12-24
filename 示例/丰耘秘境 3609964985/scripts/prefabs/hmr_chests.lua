local prefs = {}

local SOUNDS = {
    open  = "dontstarve/wilson/chest_open",
    close = "dontstarve/wilson/chest_close",
    built = "dontstarve/common/chest_craft",
}

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("preopen")
        inst.AnimState:PushAnimation("open")

        if inst.skin_open_sound then
            inst.SoundEmitter:PlaySound(inst.skin_open_sound)
        else
            inst.SoundEmitter:PlaySound(inst.sounds.open)
        end
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("pstopen")
        inst.AnimState:PushAnimation("idle")

        if inst.skin_close_sound then
            inst.SoundEmitter:PlaySound(inst.skin_close_sound)
        else
            inst.SoundEmitter:PlaySound(inst.sounds.close)
        end
    end
end

local function onhammered(inst, worker)
    if inst.components.harray ~= nil and inst.components.harray:IsInArray() then
        inst.components.harray:RemoveFromArray()
    end
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:Close()
            inst.components.container:DropEverything()
        end
        if inst.components.container_proxy ~= nil then
            for player, _ in pairs(inst.components.container_proxy.openlist) do
                inst.components.container_proxy:Close(player)
            end
        end
        if inst.components.entitytracker ~= nil then
            local slot = inst.components.entitytracker:GetEntity("slot")
            if slot ~= nil and slot.components.container ~= nil then
                slot.components.container:Close()
                slot.components.container:DropEverything()
            end
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
    if inst.skin_place_sound then
        inst.SoundEmitter:PlaySound(inst.skin_place_sound)
    else
        inst.SoundEmitter:PlaySound(inst.sounds.built)
    end
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function MakeChest(name, data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }
    if data.assets ~= nil then
        for _, asset in pairs(data.assets) do
            table.insert(assets, asset)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        -- inst.MiniMapEntity:SetIcon(name..".tex")

        inst:AddTag("structure")
        inst:AddTag("chest")
        inst:AddTag("hmr_chest")

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetFrame(math.random(0, inst.AnimState:GetCurrentAnimationNumFrames()))

        inst:SetDeploySmartRadius(0.1)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        if data.deployhelper ~= nil then
            HMR_UTIL.AddDeployHelper(inst, data.deployhelper.radius, data.deployhelper.color, data.deployhelper.type)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.sounds = SOUNDS

        inst:AddComponent("inspectable")
        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)
        inst.components.container.onopenfn = onopen
        inst.components.container.onclosefn = onclose
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        inst:AddComponent("hshowinvitem")
        inst.components.hshowinvitem:SetShowSlot({{slot = 1, symbol = "slot", bgsymbol = "slotbg"}})

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(6)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        MakeSmallBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)

        inst:ListenForEvent("onbuilt", onbuilt)

        inst.OnSave = onsave
        inst.OnLoad = onload

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
    if data.deployhelper ~= nil then
        table.insert(prefs, HMR_UTIL.MakePlacerWithRange(name.."_placer", name, name, "idle", data.deployhelper.radius, {type = data.deployhelper.type}))
    else
        table.insert(prefs, MakePlacer(name.."_placer", name, name, "idle"))
    end
end

--------------------------------------------------------------------------
--[[伴生虚拟宝箱]]
--------------------------------------------------------------------------
local function MakeVirtualChest(name, data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("chest")
        inst:AddTag("hmr_chest")
        -- inst:AddTag("NOCLICK") -- 为了让薇机人能找到
        inst:AddTag("NOBLOCK")

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn))
end

--------------------------------------------------------------------------
--[[阵列解散掉落物]]
--------------------------------------------------------------------------
local function MakePack(name, data)
    local assets =
    {
        Asset("ANIM", "anim/hmr_chest_pack.zip"),
    }

    if data.assets ~= nil then
        for _, asset in pairs(data.assets) do
            table.insert(assets, asset)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst.AnimState:SetBank("hmr_chest_pack")
        inst.AnimState:SetBuild("hmr_chest_pack")
        inst.AnimState:PlayAnimation(data.anim, true)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.sounds = SOUNDS

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        local function OnTimerDone(inst, data)
            if data.name == "disappear" then
                if inst.components.container then
                    inst.components.container:DropEverything()
                end
                inst:Remove()
            end
        end
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        local function Disappear(inst)
            if not inst.components.timer:TimerExists("disappear") then
                inst.components.timer:StartTimer("disappear", data.disappear_time)
            end
        end
        inst:DoTaskInTime(0, Disappear)

        MakeHauntableLaunch(inst)

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    table.insert(prefs, Prefab(name, fn, assets))
end


-- 青衢纳宝箱
MakeChest("hmr_chest_store", {
    assets = {
        Asset("ANIM", "anim/hmr_chest_store_ui_18x9.zip"),
        Asset("ANIM", "anim/hmr_chest_store_ui_1x3.zip"),
    },
    common_postinit = function(inst)
        inst:AddTag("hmr_chest_store")

        inst:AddComponent("container_proxy")
    end,
    master_postinit = function(inst)
        inst.components.container:EnableInfiniteStackSize(true)

        -- 阵列相关
        inst:AddComponent("harray")
        inst.components.harray:SetRadius(6)
        inst.components.harray:SetMode("hmr_chest_store")
        inst.components.harray:SetRadius(TUNING.HMR_CHEST_STORE_ARRAY_DIST)
        inst.components.harray:SetMinMemberNum(9)
        inst.components.harray:SetMaxMemberNum(12)
        inst.components.harray:SetChangeWidget(true)
        inst.components.harray:SetDisableBurningInArray(true)

        inst:AddComponent("entitytracker")

        local function OnBuiltStore(inst)
            if not inst.components.harray:IsInArray() then
                inst.components.harray:TryToAddToArray("hmr_chest_store")
            end
        end
        inst:DoTaskInTime(0, OnBuiltStore)
        inst:ListenForEvent("onbuilt", OnBuiltStore)

        inst:ListenForEvent("onremove", function()
            if inst.components.harray:IsInArray() then
                inst.components.harray:RemoveFromArray()
            end
        end)
    end,
    deployhelper = {
        radius = TUNING.HMR_CHEST_STORE_ARRAY_DIST,
        color = {0/255, 105/255, 148/255, 1},
        type = "filled"
    }
})
MakeVirtualChest("hmr_chest_store_array", {
    common_postinit = function(inst)
        inst:AddTag("hmr_array_container") -- 处理阵列打开时的自动关闭
        inst:AddTag("hmr_chest_store_array")
        inst:AddTag("hmr_chest_store")
    end,
    master_postinit = function(inst)
        inst:AddComponent("hmrcontainermanager")
        inst.components.hmrcontainermanager:SetOnSlotDisplay()

        local function CreateSlotTable(num)
            local list = {}
            for i = 162, 162 - num + 1, -1 do
                table.insert(list, i)
            end
            return list
        end

        local HIDE_SLOTS = {
            [9] =   CreateSlotTable(54),
            [10] =  CreateSlotTable(36),
            [11] =  CreateSlotTable(18),
            [12] =  {},
        }
        local function OnMemberNumChanged(inst, membernum, old_membernum)
            if membernum < 9 and old_membernum >= 9 then
                -- 解体
                local items = inst.components.container:RemoveAllItems()
                table.sort(items, function(a, b) return a.prefab < b.prefab end)
                for _, member in pairs(inst.components.harrayparent.member) do
                    while not member.components.container:IsFull() and #items > 0 do
                        member.components.container:GiveItem(items[1])
                        table.remove(items, 1)
                    end
                end

                if #items > 0 then
                    local pack = SpawnPrefab("hmr_chest_store_pack_big")
                    for _, item in pairs(items) do
                        print("给大包裹物品", item)
                        pack.components.container:GiveItem(item)
                    end
                    HMR_UTIL.DropLoot(nil, {pack}, nil, inst.components.harrayparent:GetArrayPosition())
                end
            elseif membernum >= 9 and old_membernum > membernum then
                -- 降级
                local items = {}
                for _, i in pairs(HIDE_SLOTS[membernum]) do
                    local item = inst.components.container:RemoveItemBySlot(i)
                    table.insert(items, item)
                end

                if #items > 0 then
                    table.sort(items, function(a, b) return a.prefab < b.prefab end)

                    if #items > 0 then
                        local pack = SpawnPrefab("hmr_chest_store_pack_small")
                        for _, item in pairs(items) do
                            pack.components.container:GiveItem(item)
                        end
                        HMR_UTIL.DropLoot(nil, {pack}, nil, inst.components.harrayparent:GetArrayPosition())
                    end
                end
            end

            inst.components.hmrcontainermanager:SetSlotDisplay(HIDE_SLOTS[membernum])
        end
        inst:AddComponent("harrayparent")
        inst.components.harrayparent:SetMode("hmr_chest_store_array")
        inst.components.harrayparent:SetMinMemberNum(9)
        inst.components.harrayparent:SetMaxMemberNum(12)
        inst.components.harrayparent:SetOnMemberNumChanged(OnMemberNumChanged)

        inst.components.container:EnableInfiniteStackSize(true)
        inst.components.container.skipautoclose = true  -- 其他容器用container_proxy打开时，父容器应取消自动关闭
    end,
})
MakePack("hmr_chest_store_pack_big", {
    anim = "idle_b",
    disappear_time = TUNING.HMR_CHEST_STORE_BREAKPACK_TIMING,
})
MakePack("hmr_chest_store_pack_small", {
    anim = "idle_s",
    assets = {
        Asset("ANIM", "anim/hmr_chest_store_ui_3x6.zip"),
    },
    disappear_time = TUNING.HMR_CHEST_STORE_DEGRADEPACK_TIMING,
})

-- 云梭递运箱
MakeChest("hmr_chest_transmit", {
    assets = {
        Asset("ANIM", "anim/hmr_chest_transmit_ui_1x3.zip"),
    },
    common_postinit = function(inst)
        inst:AddTag("hmr_chest_transmit")
    end,
    master_postinit = function(inst)
        local function SpawnFX(_inst, fx)
            local fxprefab = SpawnPrefab(fx)
            if fxprefab then
                fxprefab.Transform:SetPosition(_inst.Transform:GetWorldPosition())
            end
        end

        local function GetItem(inst, prefab)
            if inst.components.container ~= nil then
                for _, item in pairs(inst.components.container.slots) do
                    if prefab ~= nil and (item.prefab == prefab or item.name == prefab) then
                        return inst.components.container:RemoveItem(item, true, nil, false)
                    end
                end
            end
            return nil
        end

        local function TransmitItem(inst, prefab, doer)
            if prefab == nil or doer == nil then
                return false
            end

            local found_item = nil
            local from_transmit_chest = false

            -- 先在当前箱子里找
            found_item = GetItem(inst, prefab)

            -- 如果没找到，再搜索附近的仓库
            if found_item ~= nil then
                from_transmit_chest = true
            else
                local cx, cy, cz = inst.Transform:GetWorldPosition()
                local store_chest = TheSim:FindEntities(cx, cy, cz, TUNING.HMR_CHEST_TRANSMIT_SEARCH_DIST, {"hmr_chest_store"})
                if store_chest ~= nil then
                    for _, chest in pairs(store_chest) do
                        found_item = GetItem(chest, prefab) or found_item
                        if found_item ~= nil then
                            break
                        end
                    end
                end
            end

            if found_item ~= nil then
                SpawnFX(inst, "dr_warm_loop_1")
                SpawnFX(doer, "lightning_rod_fx")

                local distance = math.sqrt(doer:GetDistanceSqToInst(inst))
                local speed = TUNING.HMR_CHEST_TRANSMIT_SPEED -- 100
                local time = string.format("%.2f", distance / speed)
                if doer.components.talker then
                    doer.components.talker:Say(string.format(STRINGS.HMR.TRANSMIT_CHEST.TRANSMIT_TIME_ANNOUNCE, found_item.name, time))
                end

                local save_record = found_item:GetSaveRecord()
                found_item:Remove()
                inst:DoTaskInTime(tonumber(time), function()
                    SpawnFX(inst, tostring("halloween_firepuff_cold_"..math.random(1, 3)))
                    -- 给予物品
                    HMR_UTIL.DropLoot(doer, {SpawnSaveRecord(save_record)})

                    -- 消耗三维
                    if not from_transmit_chest and doer and doer.components.hunger ~= nil then
                        doer.components.hunger:DoDelta(- math.clamp(TUNING.HMR_CHEST_TRANSMIT_CONSUME_MULT * distance, 0, 50))
                    end
                end)

                return true
            end

            return false
        end
        inst.TransmitItem = TransmitItem
    end,
    deployhelper = {
        radius = TUNING.HMR_CHEST_TRANSMIT_SEARCH_DIST,
        color = {255/255, 69/255, 0/255, 1},
    },
})

-- 华樽耀勋箱
MakeChest("hmr_chest_display", {
    assets = {
        Asset("ANIM", "anim/hmr_chest_display_ui_1x3.zip")
    },
    common_postinit = function(inst)
        inst.entity:AddLight()
        inst.Light:SetRadius(4)
        inst.Light:SetIntensity(.8)
        inst.Light:SetFalloff(.9)
        inst.Light:SetColour(253 / 255, 184 / 255, 19 / 255)
        inst.Light:Enable(false)

        inst:AddTag("hmr_chest_display")

        inst.AnimState:SetSymbolExchange("slot", "swap_body")
    end,
    master_postinit = function(inst)
        inst:AddComponent("lootdropper")

        local function OnDisplay(inst)
            inst.components.container.canbeopened = false
            if inst.components.container:IsOpen() then
                inst.components.container:Close()
            end
            inst.AnimState:PlayAnimation("predisplay")
            inst.AnimState:PushAnimation("display", true)

            inst.Light:Enable(true)
        end
        local function OnUnDisplay(inst)
            inst.components.container.canbeopened = true
            inst.AnimState:PlayAnimation("pstdisplay")
            inst.AnimState:PushAnimation("idle", true)

            inst.Light:Enable(false)
        end
        inst:AddComponent("hmrstatuedisplayer")
        inst.components.hmrstatuedisplayer:SetOverrideSymbolName("swap_body")
        inst.components.hmrstatuedisplayer:SetOnDisplay(OnDisplay)
        inst.components.hmrstatuedisplayer:SetOnUnDisplay(OnUnDisplay)

        local function SanityAuraFn(inst, observer)
            if inst.components.hmrstatuedisplayer:IsOccupied() then
                return TUNING.SANITYAURA_LARGE
            end
            return 0
        end
        inst:AddComponent("sanityaura")
        inst.components.sanityaura.max_distsq = TUNING.HMR_CHEST_DISPLAY_SANITYAURA_DIST * TUNING.HMR_CHEST_DISPLAY_SANITYAURA_DIST
        inst.components.sanityaura.aurafn = SanityAuraFn
    end,
    deployhelper = {
        radius = TUNING.HMR_CHEST_DISPLAY_SANITYAURA_DIST,
        color = {204/255, 174/255, 11/255, 1},
    }
})

-- 灵枢织造箱
MakeChest("hmr_chest_factory", {
    assets = {
        Asset("ANIM", "anim/hmr_chest_factory_ui_r5.zip"),
    },
    common_postinit = function(inst)
        inst:AddTag("hmr_chest_factory")
    end,
    master_postinit = function(inst)
        local function GiveCore(inst)
            if inst.already_give_core then
                return
            end

            local PROBABILITY_LIST = {1, 0.5, 0.5, 0.05, 0.005}
            for i = 1, 5 do
                local rand = math.random()
                if rand <= PROBABILITY_LIST[i] then
                    local core = SpawnPrefab("hmr_chest_factory_core_item")
                    core.components.entitytracker:TrackEntity("factory", inst)
                    inst.components.container:GiveItem(core)
                end
            end

            inst.already_give_core = true
        end

        local function FactoryOnItemChanged(inst, data)
            -- 满了之后转移物品
            if inst.components.container:IsFull() and not inst:HasTag("isbusy") then
                inst:AddTag("isbusy")

                local transmit_chests = {}
                for _, ent in pairs(Ents) do
                    if ent.prefab == "hmr_chest_transmit" or ent:HasTag("hmr_chest_transmit") then
                        table.insert(transmit_chests, ent)
                    end
                end

                if #transmit_chests > 0 then
                    for _, chest1 in pairs(transmit_chests) do
                        for _, chest2 in pairs(transmit_chests) do
                            -- chest1：接收；chest2：发送
                            local x1, y1, z1 = chest1.Transform:GetWorldPosition()
                            local chests = TheSim:FindEntities(x1, y1, z1, TUNING.HMR_CHEST_TRANSMIT_SEARCH_DIST, {"chest"}, {"hmr_chest_transmit", "hmr_inarray"})
                            local chest2_dist = math.sqrt(chest2:GetDistanceSqToInst(inst))

                            -- chests:接收方传送宝箱搜索范围内的箱子
                            if chests ~= nil and chest2_dist < TUNING.HMR_CHEST_TRANSMIT_SEARCH_DIST then
                                for _, chest in pairs(chests) do
                                    if chest ~= chest1 and chest ~= chest2 and chest ~= inst and not chest.components.container:IsFull() then
                                        for _, slot in pairs(inst.components.container.slots) do
                                            local accept_num = chest.components.container:CanAcceptCount(slot)
                                            if accept_num > 0 then
                                                local item
                                                if slot.components.stackable then
                                                    if slot.components.stackable:StackSize() <= accept_num then
                                                        -- item, wholestack, _checkallcontainers_, keepoverstacked
                                                        item = inst.components.container:RemoveItem(slot, true, nil, true)
                                                    else
                                                        item = slot.components.stackable:Get(accept_num)
                                                    end
                                                else
                                                    item = inst.components.container:RemoveItem(slot)
                                                end

                                                if item ~= nil then
                                                    chest.components.container:GiveItem(item)
                                                end
                                            end
                                        end
                                    end

                                    -- 灵枢织造箱空后停止
                                    if inst.components.container:IsEmpty() then
                                        inst:RemoveTag("isbusy")
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end

            inst:DoTaskInTime(5, function()
                if inst:HasTag("isbusy") then
                    inst:RemoveTag("isbusy")
                end
            end)
        end

        local function RelateCore(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, TUNING.HMR_CHEST_FACTORY_RELATE_DIST, {"hmr_chest_factory_core"})
            for k, v in pairs(ents) do
                if v and v:IsValid() and v.components.hmrfactory and v.components.hmrfactory.storage == nil then
                    v.components.hmrfactory:SetStorage(inst)
                end
            end
        end

        local function FactoryOnSave(inst, data)
            data.already_give_core = inst.already_give_core
        end

        local function FactoryOnLoad(inst, data)
            if data ~= nil and data.already_give_core then
                inst.already_give_core = data.already_give_core
            end
        end
        inst:AddComponent("uniqueid")

        inst:ListenForEvent("onbuilt", GiveCore)
        -- T出来的也给吧
        inst:DoTaskInTime(0, GiveCore)
        inst:DoTaskInTime(0.1 + math.random(), RelateCore)

        inst:ListenForEvent("itemget", FactoryOnItemChanged)
        inst:ListenForEvent("itemlose", FactoryOnItemChanged)

        inst.OnSave = FactoryOnSave
        inst.OnLoad = FactoryOnLoad
    end,
    deployhelper = {
        radius = TUNING.HMR_CHEST_FACTORY_RELATE_DIST,
        color = {16/255, 78/255, 50/255, 1},
    }
})

-- 龙龛探秘箱
MakeChest("hmr_chest_recycle", {
    assets = {
        Asset("ANIM", "anim/hmr_chest_recycle_ui_5p4.zip"),
    },
    common_postinit = function(inst)
        inst:AddTag("hmr_chest_recycle")
    end,
    master_postinit = function(inst)
        local RECYCLE_CHEST_LIST = require("hmrmain/hmr_lists").RECYCLE_CHEST_LIST
        local function OnItemChanged(inst, data)
            local container = inst.components.container
            local timer = inst.components.timer

            for i = 1, container.numslots do
                local item = container.slots[i]
                if item == nil or timer:TimerExists("slot"..i) then
                    timer:StopTimer("slot"..i)
                elseif item ~= nil then
                    local spawncycle
                    if i <= 6 then
                        spawncycle = 0.8
                    elseif i <= 14 then
                        spawncycle = 1.5
                    else
                        spawncycle = 2
                    end
                    timer:StartTimer("slot"..i, TUNING.HMR_CHEST_RECYCLE_ITEM_TIME * spawncycle)
                end
            end
        end

        -- 寻找生成点
        local function FindRandomPointForPrefab(junk, center_x, center_z, radius, max_tries)
            while max_tries > 0 do
                max_tries = max_tries - 1
                local theta = math.random() * TWOPI
                local r = math.random() * radius
                local x = center_x + r * math.cos(theta)
                local z = center_z + r * math.sin(theta)
                local pt = Vector3(x, 0, z)
                if TheWorld.Map:IsPassableAtPointWithPlatformRadiusBias(x, 0, z, false, false, TUNING.BOAT.NO_BUILD_BORDER_RADIUS, true)
                        and TheWorld.Map:IsDeployPointClear(pt, nil, junk and junk.Physics:GetRadius() * TUNING.HMR_CHEST_RECYCLE_SPAWN_DENSITY or 1) then
                    return pt
                end
            end
        end

        local function SpawnJunkPile(inst, name)
            local x, y, z = inst.Transform:GetWorldPosition()
            local spawn_item = SpawnPrefab(name)
            local spawn_pt = FindRandomPointForPrefab(spawn_item, x, z, TUNING.HMR_CHEST_RECYCLE_SPAWN_DIST, 50)
            if spawn_item and spawn_pt then
                spawn_item.Transform:SetPosition(spawn_pt:Get())
                local fx = SpawnPrefab("junk_break_fx")
                fx.Transform:SetPosition(spawn_pt:Get())
            end
        end

        local function OnTimerDone(inst, data)
            local container = inst.components.container
            local numitems = container:NumItems()
            if numitems <= 2 then
                SpawnJunkPile(inst, "hmr_junkpile_low")
            elseif numitems <= 4 then
                SpawnJunkPile(inst, "hmr_junkpile_mid")
            else
                local normal_num, toy_num, wagpunk_num = 0, 0, 0
                for _, item in pairs(container.slots) do
                    if RECYCLE_CHEST_LIST[item.prefab] == "normal" then
                        normal_num = normal_num + 1
                    elseif RECYCLE_CHEST_LIST[item.prefab] == "toy" then
                        toy_num = toy_num + 1
                    elseif RECYCLE_CHEST_LIST[item.prefab] == "wagpunk_bits" then
                        wagpunk_num = wagpunk_num + 1
                    end
                end
                if wagpunk_num >= 2 then
                    SpawnJunkPile(inst, "hmr_junkpile_high_wagpunk_bits")
                elseif toy_num >= 3 then
                    SpawnJunkPile(inst, "hmr_junkpile_high_toy")
                else
                    SpawnJunkPile(inst, "hmr_junkpile_high_normal")
                end
            end
            OnItemChanged(inst)
        end

        local function CreateRandomSlot()
            local slotlist = {}
            for i = 1, 28 do
                table.insert(slotlist, i)
            end
            for i = 1, 5 do
                local index = math.random(1, #slotlist)
                table.remove(slotlist, index)
            end
            return slotlist
        end
        local function SetSlotDisplay(inst)
            if not inst.components.hmrcontainermanager:HasDisplaySet() then
                inst.components.hmrcontainermanager:SetSlotDisplay(CreateRandomSlot())
            end
        end
        inst:AddComponent("hmrcontainermanager")
        inst:DoTaskInTime(0, SetSlotDisplay)

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        inst:ListenForEvent("itemget", OnItemChanged)
        inst:ListenForEvent("itemlose", OnItemChanged)

        inst:AddComponent("entitytracker")

        local function SpawnRecycleSlot(parent)
            local slot = parent.components.entitytracker:GetEntity("slot")
            if slot == nil then
                slot = SpawnPrefab("hmr_chest_recycle_virtual")
                slot.Transform:SetPosition(parent.Transform:GetWorldPosition())
                parent.components.entitytracker:TrackEntity("slot", slot)
            end
            if slot ~= nil then
                local function OnParentRemove()
                    if slot.components.container ~= nil then
                        slot.components.container:DropEverything()
                        slot:Remove()
                    end
                end
                slot:ListenForEvent("onremove", OnParentRemove, parent)
            end
        end
        inst:DoTaskInTime(0, SpawnRecycleSlot)

        inst.SpawnRecycleSlot = SpawnRecycleSlot
        inst.OnLoadPostPass = SpawnRecycleSlot
    end,
    deployhelper = {
        radius = TUNING.HMR_CHEST_RECYCLE_SPAWN_DIST,
        color = {222/255, 165/255, 37/255, 1},
    }
})
MakeVirtualChest("hmr_chest_recycle_virtual", {
    common_postinit = function(inst)
        inst.entity:AddSoundEmitter()
        inst:AddTag("hmr_chest_recycle_virtual")
    end,
    master_postinit = function(inst)
        local function OnIncinerateItems(inst)
            inst.SoundEmitter:PlaySound("qol1/dragonfly_furnace/incinerate")
        end
        local function ShouldIncinerateItem(inst, item)
            local incinerate = true

            -- NOTES(JBK): Fruitcake hack. You think you can escape this so easily?
            if item.prefab == "winter_food4" then
                incinerate = false
            elseif item:HasTag("irreplaceable") then
                incinerate = false
            elseif item.components.container ~= nil and not item.components.container:IsEmpty() then
                incinerate = false
            end

            return incinerate
        end
        inst:AddComponent("incinerator")
        inst.components.incinerator:SetOnIncinerateFn(OnIncinerateItems)-- 设置焚烧物品时的回调函数
        inst.components.incinerator:SetShouldIncinerateItemFn(ShouldIncinerateItem)-- 设置是否应该焚烧物品的判断函数
    end
})

return unpack(prefs)