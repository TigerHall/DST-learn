require "prefabutil"
local SPICE_DATA_LIST = require("hmrmain/hmr_lists").SPICE_DATA_LIST
local cooking = require("cooking")

local assets =
{
    Asset("ANIM", "anim/honor_cookpot.zip"),
    Asset("ANIM", "anim/ui_honor_cookpot_6x6.zip"),
    Asset("ANIM", "anim/ui_honor_cookpot_widgets.zip"),
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil and inst.components.container:IsOpen() then
            inst.components.container:Close()
            --onclose will trigger sfx already
        else
            inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle_loop", true)
    end
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    end
end

local function getstatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or "COOKING"
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/cook_pot_craft")
end

local function UpdateAnim(inst)
    if inst._is_cooking:value() or inst._is_seasoning:value()  or inst.components.timer:TimerExists("cooking") or inst.components.timer:TimerExists("seasoning") then
        if not inst.AnimState:IsCurrentAnimation("cook") then
            inst.AnimState:PlayAnimation("cook_pre")
            inst.AnimState:PushAnimation("cook", true)
            inst.AnimState:SetSymbolBloom("bloom")
            inst.AnimState:SetSymbolBloom("light")
            inst.AnimState:SetSymbolLightOverride("bloom", .6)
            inst.AnimState:SetSymbolLightOverride("light", .6)

            inst.Light:Enable(true)

            inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
        end
    else
        if inst.AnimState:IsCurrentAnimation("cook") then
            inst.AnimState:PlayAnimation("cook_pst")
            inst.AnimState:PushAnimation("idle_loop", true)
            inst.AnimState:ClearSymbolBloom("bloom")
            inst.AnimState:ClearSymbolBloom("light")
            inst.AnimState:SetSymbolLightOverride("bloom", 0)
            inst.AnimState:SetSymbolLightOverride("light", 0)

            inst.Light:Enable(false)

            inst.SoundEmitter:KillSound("snd")
        end
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    data.cook_product = inst.cook_product
    data.cook_product_spoilage = inst.cook_product_spoilage
    data.cookbtn = inst._cookbtn:value()

    data.season_product = inst.season_product
    data.season_product_spoilage = inst.season_product_spoilage

    data.cook_times = inst.cook_times or 0
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
        inst.Light:Enable(false)
    end
    if data ~= nil then
        inst.cook_product = data.cook_product
        inst.cook_product_spoilage = data.cook_product_spoilage
        inst._cookbtn:set(data.cookbtn or false)

        inst.season_product = data.season_product
        inst.season_product_spoilage = data.season_product_spoilage

        inst.cook_times = data.cook_times or 0
    end
end

local function OnLoadPostPass(inst)
    UpdateAnim(inst)
end

local function SeasonOnUpdate(inst)
    inst._season_percent:set((inst.components.timer:GetTimeLeft("seasoning") or 0) / inst._season_time)
end

local function CookOnUpdate(inst)
    inst._cook_percent:set((inst.components.timer:GetTimeLeft("cooking") or 0) / inst._cooktime)
end

local function PerishRateMultiplier(inst, item)
    return math.clamp(1 - inst.cook_times * 0.01, -100, 1)
end

----------------------------------------------------------------------------
---[[烹饪]]
----------------------------------------------------------------------------
local function OnItemChanged(inst, data)
    if data ~= nil and data.slot ~= nil then
        if data.slot ~= 1 and data.slot ~= 2 and data.slot ~= 3 and data.slot ~= 4 then
            return
        end
    end

    -- 原材料满才可烹饪
    local cookslots_full = true
    for i = 1, 4 do
        if inst.components.container.slots[i] == nil then
            cookslots_full = false
            break
        end
    end

    -- 产品格未满才可烹饪
    local productslot_full = true
    local product_slot = inst.components.container.slots[5]
    if product_slot == nil or product_slot.components.stackable ~= nil and not product_slot.components.stackable:IsFull() then
        productslot_full = false
    end

    if inst._cookbtn:value() and not inst.components.timer:TimerExists("cooking") and cookslots_full and not productslot_full then
        -- 原材料表
        local ingredient_prefabs = {}
        for i = 1, 4 do
            local item = inst.components.container.slots[i]
            if item ~= nil then
                table.insert(ingredient_prefabs, item.prefab)
            end
        end

        -- 烹饪时间、腐烂时间
        local product, cooktime = cooking.CalculateRecipe("portablecookpot", ingredient_prefabs)
        if cooktime == nil or product == nil then
            return
        end
        cooktime = TUNING.BASE_COOK_TIME * cooktime * 0.75
        inst._cooktime = cooktime
        local productperishtime = cooking.GetRecipe("portablecookpot", product).perishtime or 0
        -- 计算产品腐烂程度
        if productperishtime > 0 then
            local spoilage_total = 0
            local spoilage_n = 0
            for i = 1, 4 do
                local item = inst.components.container.slots[i]
                if item.components.perishable ~= nil then
                    spoilage_n = spoilage_n + 1
                    spoilage_total = spoilage_total + item.components.perishable:GetPercent()
                end
            end
            inst.cook_product_spoilage =
                (spoilage_n <= 0 and 1) or
                (spoilage_total / spoilage_n) or
                1 - (1 - spoilage_total / spoilage_n) * .5
        end

        -- 烹饪
        inst.components.timer:StartTimer("cooking", cooktime)
        inst.components.updatelooper:AddOnUpdateFn(CookOnUpdate)

        inst.cook_product = product
        -- 消耗原材料
        for i = 1, 4 do
            local item = inst.components.container.slots[i]
            if item ~= nil then
                if item.components.stackable ~= nil and item.components.stackable:IsStack() then
                    item.components.stackable:Get()
                else
                    item:Remove()
                end
            end
        end

        inst._is_cooking:set(true)
    else
        inst._is_cooking:set(false)
    end

    UpdateAnim(inst)
end

local function OnTimerDone(inst, data)
    if data.name == "cooking" then
        if inst.cook_product ~= nil then
            local product = SpawnPrefab(inst.cook_product)
            if product ~= nil then
                local stacksize = cooking.GetRecipe("portablecookpot", inst.cook_product) and cooking.GetRecipe("portablecookpot", inst.cook_product).stacksize or 1
                if stacksize > 1 then
                    product.components.stackable:SetStackSize(stacksize)
                end

                if inst.cook_product_spoilage ~= nil and product.components.perishable ~= nil then
                    product.components.perishable:SetPercent(inst.cook_product_spoilage)
                    product.components.perishable:StartPerishing()
                end
            end

            if inst.components.container ~= nil then
                inst.components.container:GiveItem(product, 5)
            end
        end
        inst.cook_product = nil
        inst.cook_product_spoilage = nil

        OnItemChanged(inst)

        inst.cook_times = (inst.cook_times or 0) + 1
    elseif data.name == "seasoning" then
        if inst.season_product ~= nil then
            local product = SpawnPrefab(inst.season_product)
            if product ~= nil then
                local stacksize = cooking.GetRecipe("portablespicer", inst.season_product) and cooking.GetRecipe("portablespicer", inst.season_product).stacksize or 1
                if stacksize > 1 then
                    product.components.stackable:SetStackSize(stacksize)
                end

                if inst.season_product_spoilage ~= nil and product.components.perishable ~= nil then
                    product.components.perishable:SetPercent(inst.season_product_spoilage)
                    product.components.perishable:StartPerishing()
                end
            end

            if inst.components.container ~= nil then
                inst.components.container:GiveItem(product, 8)
            end
        end
        inst.season_product = nil
        inst.season_product_spoilage = nil

        inst._is_seasoning:set(false)

        inst.cook_times = (inst.cook_times or 0) + 1
    end

    UpdateAnim(inst)
end

----------------------------------------------------------------------------
---[[研磨]]
----------------------------------------------------------------------------
local function OnGrind(inst, player)
    local numtogive = player ~= nil and
            (player:HasTag("expertchef") and 3 or
            player:HasTag("professionalchef") and math.random(2, 3) or
            player:HasTag("masterchef") and 2) or
            math.random(1, 2)

    if inst.components.container ~= nil and inst.components.container.slots[6] ~= nil then
        local item = inst.components.container.slots[6]
        local spice_data = SPICE_DATA_LIST[item.prefab]
        if spice_data ~= nil then
            local spice = spice_data.product
            numtogive = spice_data.numtogive or numtogive
            if spice ~= nil then
                local spice_prefab = SpawnPrefab(spice)

                if spice_prefab ~= nil then
                    if spice_prefab.components.stackable ~= nil then
                        spice_prefab.components.stackable:SetStackSize(numtogive)
                    end
                    inst.components.container:GiveItem(spice_prefab, 7)

                    if item.components.stackable ~= nil and item.components.stackable:IsStack() then
                        item.components.stackable:Get()
                    else
                        item:Remove()
                    end

                    inst.cook_times = (inst.cook_times or 0) + 1
                end
            end
        end
    end
end

----------------------------------------------------------------------------
---[[调味]]
----------------------------------------------------------------------------
local function OnSeason(inst, player)
    if not inst.components.timer:TimerExists("seasoning") then
        -- 原材料表
        if inst.components.container.slots[5] == nil or inst.components.container.slots[7] == nil then
            return
        end
        local ingredient_prefabs = {inst.components.container.slots[5].prefab, inst.components.container.slots[7].prefab}

        -- 烹饪时间、腐烂时间
        local product, cooktime = cooking.CalculateRecipe("portablespicer", ingredient_prefabs)
        if cooktime == nil or product == nil then
            return
        end
        inst.season_product = product
        cooktime = TUNING.BASE_COOK_TIME * cooktime * 0.75
        inst._season_time = cooktime
        local productperishtime = cooking.GetRecipe("portablespicer", product).perishtime or 0
        -- 计算产品腐烂程度
        if productperishtime > 0 then
            local item = inst.components.container.slots[5]
            inst.season_product_spoilage = item and item.components.perishable and item.components.perishable:GetPercent() or 1
        end

        -- 烹饪
        inst.components.timer:StartTimer("seasoning", cooktime)
        inst.components.updatelooper:AddOnUpdateFn(SeasonOnUpdate)

        -- 消耗原材料
        for i = 5, 7, 2 do
            local item = inst.components.container.slots[i]
            if item ~= nil then
                if item.components.stackable ~= nil and item.components.stackable:IsStack() then
                    item.components.stackable:Get()
                else
                    item:Remove()
                end
            end
        end

        inst._is_seasoning:set(true)

        UpdateAnim(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:SetDeploySmartRadius(1) --recipe min_spacing/2
    MakeObstaclePhysics(inst, .5)

    inst.Light:Enable(false)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235/255,62/255,12/255)
    --inst.Light:SetColour(1,0,0)

    inst:AddTag("structure")

    inst.AnimState:SetBank("honor_cookpot")
    inst.AnimState:SetBuild("honor_cookpot")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.MiniMapEntity:SetIcon("honor_cookpot_icon.tex")

    MakeSnowCoveredPristine(inst)

    inst._cookbtn = net_bool(inst.GUID, "net_cookbtn", "net_cookbtn_dirty")
    inst._cook_percent = net_float(inst.GUID, "net_cook_percent", "net_cook_percent_dirty")
    inst._season_percent = net_float(inst.GUID, "net_season_percent", "net_season_percent_dirty")
    inst._is_cooking = net_bool(inst.GUID, "net_is_cooking", "net_is_cooking_dirty")
    inst._is_seasoning = net_bool(inst.GUID, "net_is_seasoning", "net_is_seasoning_dirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.cook_times = 0

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("honor_cookpot")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(PerishRateMultiplier)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("timer")

    inst:AddComponent("updatelooper")

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("itemget", OnItemChanged)
    inst:ListenForEvent("itemlose", OnItemChanged)
    inst:ListenForEvent("net_cookbtn_dirty", OnItemChanged)
    inst:ListenForEvent("timerdone", OnTimerDone)

    MakeSnowCovered(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)

    inst.OnGrind = OnGrind
    inst.OnSeason = OnSeason
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return  Prefab("honor_cookpot", fn, assets),
        MakePlacer("honor_cookpot_placer", "honor_cookpot", "honor_cookpot", "idle")