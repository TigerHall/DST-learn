local TOOLS_L = require("tools_legion")
local prefs = {}

local function GetAssets(name, other)
    local sets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
local function GetAssets2(name, build, other)
    local sets = {
        Asset("ANIM", "anim/"..build..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end

local function Fn_common(inst, bank, build, anim, isloop, foleysound)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim or "idle", isloop)

    if foleysound ~= nil then
        inst.foleysound = foleysound
    end

    inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制
end
local function Fn_server(inst, img, equipslot, OnEquip, OnUnequip)
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = img
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..img..".xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = equipslot or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end

local function SetBackpack_common(inst, icon, fn_onreplicated)
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon(icon..".tex")

    inst:AddTag("backpack")
    inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = fn_onreplicated
    end
end
local function SetBackpack_server(inst, widget)
    inst.components.inventoryitem.cangoincontainer = false

    inst:AddComponent("container")
    inst.components.container:WidgetSetup(widget)
end
local function SetBonus(inst, name, OnSetBonusOn, OnSetBonusOff)
    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES[name])
    inst.components.setbonus:SetOnEnabledFn(OnSetBonusOn)
    inst.components.setbonus:SetOnDisabledFn(OnSetBonusOff)
end
local function SetKeepOnFinished(inst)
    if inst.components.armor.SetKeepOnFinished == nil then --有的mod替换了这个组件，导致没兼容官方的新函数
        inst.components.armor.keeponfinished = true
    else
        inst.components.armor:SetKeepOnFinished(true) --耐久为0不消失
    end
end
local function EmptyCptFn(self, ...)end

--------------------------------------------------------------------------
--[[ 靠背熊 ]]
--------------------------------------------------------------------------

local cycle_backcub = 10
local hunger_max_backcub = 300
local hungerrate_backcub = 50*cycle_backcub/TUNING.TOTAL_DAY_TIME
local stage_full_backcub = 0.9
local stage_3_backcub = 0.5
local stage_2_backcub = 0.2

local function SetHunger_backcub(inst, value)
    value = value + inst.hunger_l
    if value < 0 then
        value = 0
    elseif value > hunger_max_backcub then
        value = hunger_max_backcub
    end
    local percent = value/hunger_max_backcub
    if percent >= stage_3_backcub then
        inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
    elseif percent >= stage_2_backcub then
        inst.components.insulator:SetInsulation(TUNING.INSULATION_MED_LARGE)
    elseif percent > 0 then
        inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
    else
        inst.components.insulator:SetInsulation(TUNING.INSULATION_TINY)
    end
    inst:PushEvent("percentusedchange", { percent = percent }) --界面需要一个百分比
    inst.hunger_l = value
    return percent
end
local function SetHungerCount_backcub(inst, value)
    value = value + inst.count_hunger_l
    if value < 0 then
        value = 0
    elseif value >= 100 then
        value = value - 100
        local owner = inst.components.inventoryitem.owner --它是背包，只判断一级就行
        if owner ~= nil then
            TOOLS_L.SpawnStackDrop("furtuft", math.random(2), owner:GetPosition(), owner, nil, { dropper = inst })
        else
            local items = {}
            TOOLS_L.SpawnStackDrop("furtuft", math.random(2), inst:GetPosition(), nil, items, { dropper = inst })
            if items[1] ~= nil then
                inst.components.container:GiveItem(items[1])
            end
        end
    end
    inst.count_hunger_l = value
end
local function IsFull_backcub(inst)
    if not inst.legiontag_bestappetite and inst.hunger_l/hunger_max_backcub > stage_full_backcub then
        return true
    end
    return false
end
local function GetEaterAbsorption(inst, key)
    local va = inst.components.eater[key] or 1
    if va < 1 and va > 0 then
        if inst.legiontag_bestappetite then
            return 1
        end
    end
    return va
end
local function OnEat_backcub(inst, food)
    local v = food.components.edible:GetHunger(inst) * GetEaterAbsorption(inst, "hungerabsorption")
                + food.components.edible:GetSanity(inst) * GetEaterAbsorption(inst, "sanityabsorption")
                + food.components.edible:GetHealth(inst) * GetEaterAbsorption(inst, "healthabsorption")
    if v > 0 then
        if food:HasTag("honeyed") then --蜜类料理加成
            v = v * 1.2
        end
        if not IsFull_backcub(inst) then
            local tempcpt = inst.components.inventoryitem.owner
            if tempcpt ~= nil and
                tempcpt.components.temperature ~= nil and
                (tempcpt.components.health == nil or
                    not (tempcpt.components.health:IsDead() or tempcpt:HasTag("playerghost"))
                )
            then
                tempcpt = tempcpt.components.temperature
                if
                    tempcpt:GetCurrent() <= 10 or
                    (inst.dotemphelp_l and tempcpt:GetCurrent() < (tempcpt.overheattemp-5.1)) --太接近高温的话会有界面提示的
                then
                    tempcpt:SetTemperature( math.min(tempcpt:GetCurrent()+v*0.4, tempcpt.overheattemp-5.1) )
                    v = v * 0.6
                end
            end
        end
    end
    inst.dotemphelp_l = nil
    SetHunger_backcub(inst, v)
    if not inst:IsAsleep() then
        inst.SoundEmitter:PlaySound("dontstarve/HUD/feed")
    end
end
local function OnGround_backcub(inst)
    if inst.task_l_sound == nil then
        inst.task_l_sound = inst:DoPeriodicTask(4, function()
            inst.SoundEmitter:KillSound("sleep")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/sleep", "sleep")
        end, 3+17*math.random())
    end
end
local function ConsumeHunger_backcub(inst, value)
    --积累消耗值
    if inst.hunger_l >= value then
        SetHungerCount_backcub(inst, value)
    elseif inst.hunger_l > 0 then
        SetHungerCount_backcub(inst, inst.hunger_l)
    end

    local percent = SetHunger_backcub(inst, -value)
    local tempcpt = nil
    --装备者是否需要回温
    if not IsFull_backcub(inst) then
        tempcpt = inst.components.inventoryitem.owner
        if
            tempcpt ~= nil and
            tempcpt.components.temperature ~= nil and tempcpt.components.temperature:GetCurrent() <= 10 and
            (tempcpt.components.health == nil or
                not (tempcpt.components.health:IsDead() or tempcpt:HasTag("playerghost"))
            )
        then
            tempcpt = tempcpt.components.temperature
        else
            tempcpt = nil
        end
    end
    --偷吃食物
    if tempcpt ~= nil or percent < stage_2_backcub then --太饿了或者装备者需要回温
        local container = inst.components.container
        for i = container.numslots-1, container.numslots do --一次只吃最后两格的东西
            local item = container.slots[i]
            if item and inst.components.eater:CanEat(item) then
                inst.dotemphelp_l = tempcpt ~= nil
                inst.components.eater:Eat(item, nil)
                if tempcpt ~= nil and tempcpt:GetCurrent() < (tempcpt.overheattemp-5.1) then --尽量温度补满
                    if IsFull_backcub(inst) then --太饱了就不吃了
                        break
                    end
                elseif inst.hunger_l/hunger_max_backcub >= stage_2_backcub then --不饿了就不吃了
                    break
                end
            end
        end
    end
end
local function HungerCycle_backcub(inst)
    ConsumeHunger_backcub(inst, hungerrate_backcub)
end
local function OnEquip_backcub(inst, owner)
    local symbol = owner.prefab == "webber" and "swap_body_tall" or "swap_body"
    if inst._dd ~= nil then
        owner.AnimState:OverrideSymbol(symbol, inst._dd.build, inst._dd.file)
    else
        owner.AnimState:OverrideSymbol(symbol, "swap_backcub", "swap_body")
    end
    if inst.task_l_sound ~= nil then
        inst.task_l_sound:Cancel()
        inst.task_l_sound = nil
    end
    inst.SoundEmitter:KillSound("sleep")

    if owner:HasTag("equipmentmodel") then return end --假人

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
    inst:DoTaskInTime(0, function() --需要主动更新一下，不然没反应
        inst:PushEvent("percentusedchange", { percent = inst.hunger_l/hunger_max_backcub })
    end)
end
local function OnUnequip_backcub(inst, owner)
    if owner.prefab == "webber" then
        owner.AnimState:ClearOverrideSymbol("swap_body_tall")
    else
        owner.AnimState:ClearOverrideSymbol("swap_body")
    end
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

local function OnBurnt_backcub(inst)
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end
    SpawnPrefab("cookedsmallmeat").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end
local function OnIgnite_backcub(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = false
    end
end
local function OnExtinguish_backcub(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = true
    end
end
local function OnLongUpdate_backcub(inst, dt)
    if dt == nil or dt <= 0 then
        return
    end
    ConsumeHunger_backcub(inst, dt*50/TUNING.TOTAL_DAY_TIME) --将经过时间换算成所需消耗的饱食度
    if inst:IsAsleep() then
        inst.hungertime_l = GetTime()
    else
        inst.hungertime_l = nil
    end
end
local function OnSave_backcub(inst, data)
	if inst.hunger_l > 0 then
		data.hunger_l = inst.hunger_l
	end
    if inst.count_hunger_l > 0 then
		data.count_hunger_l = inst.count_hunger_l
	end
    if inst.hungertime_l ~= nil then
        data.hungertime_l = GetTime() - inst.hungertime_l
    end
end
local function OnLoad_backcub(inst, data)
	if data ~= nil then
		if data.hunger_l ~= nil then
			SetHunger_backcub(inst, data.hunger_l)
		end
        if data.count_hunger_l ~= nil then
			inst.count_hunger_l = data.count_hunger_l --这个就不初始化了
		end
        if data.hungertime_l ~= nil then
			local hungertime = data.hungertime_l --缓存一下，因为下一帧data就没有数据了
            inst:DoTaskInTime(1+math.random(), function(inst)
                OnLongUpdate_backcub(inst, hungertime)
            end)
		end
	end
end
local function OnEntityWake_backcub(inst)
    if inst.hungertime_l ~= nil then
        OnLongUpdate_backcub(inst, GetTime() - inst.hungertime_l)
        inst.hungertime_l = nil
    end
    if inst.task_l_hunger == nil then
        inst.task_l_hunger = inst:DoPeriodicTask(cycle_backcub, HungerCycle_backcub, cycle_backcub+10*math.random())
    end
end
local function OnEntitySleep_backcub(inst)
    if inst.task_l_hunger ~= nil then
        inst.task_l_hunger:Cancel()
        inst.task_l_hunger = nil
    end
    inst.hungertime_l = GetTime()
end
local function OnEntityReplicated_backcub(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("backcub")
    end
end

table.insert(prefs, Prefab("backcub", function()
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    Fn_common(inst, "backcub", nil, "anim", true, nil)
    SetBackpack_common(inst, "backcub", OnEntityReplicated_backcub)
    -- inst.Transform:SetScale(0.5, 0.5, 0.5) --一旦这里改变动画大小，会导致火焰燃烧特效也跟着变化

    inst:AddTag("handfed") --能在被携带时被喂食
    inst:AddTag("fedbyall") --使得能被所有玩家喂食(不然就只能局限于跟随者)
    inst:AddTag("eatsrawmeat")
    inst:AddTag("strongstomach")

    LS_C_Init(inst, "backcub", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.hunger_l = 0
    inst.count_hunger_l = 0
    -- inst.hungertime_l = nil
    -- inst.dotemphelp_l = nil

    Fn_server(inst, "backcub", EQUIPSLOTS.BACK, OnEquip_backcub, OnUnequip_backcub)
    SetBackpack_server(inst, "backcub")

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_TINY)

    inst:AddComponent("eater")
    inst.components.eater:SetOnEatFn(OnEat_backcub)
    -- inst.components.eater:SetAbsorptionModifiers(1, 1, 1)
    inst.components.eater:SetCanEatRawMeat(true)
    inst.components.eater:SetStrongStomach(true)
    inst.components.eater:SetCanEatHorrible(true)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt_backcub)
    inst.components.burnable:SetOnIgniteFn(OnIgnite_backcub)
    inst.components.burnable:SetOnExtinguishFn(OnExtinguish_backcub)

    inst:ListenForEvent("ondropped", OnGround_backcub)
    OnGround_backcub(inst)
    inst.task_l_hunger = inst:DoPeriodicTask(cycle_backcub, HungerCycle_backcub, cycle_backcub+10*math.random())

    -- MakeHauntableLaunchAndDropFirstItem(inst) --不能被作祟

    inst.OnSave = OnSave_backcub
    inst.OnLoad = OnLoad_backcub
    inst.OnLongUpdate = OnLongUpdate_backcub
    inst.OnEntitySleep = OnEntitySleep_backcub
    inst.OnEntityWake = OnEntityWake_backcub

    return inst
end, GetAssets("backcub", {
    Asset("ANIM", "anim/swap_backcub.zip"),
    Asset("ANIM", "anim/ui_piggyback_2x6.zip")
}), { "cookedsmallmeat", "furtuft" }))

--------------------------------------------------------------------------
--[[ 香包 ]]
--------------------------------------------------------------------------

local tags_cant_sachet = { "INLIMBO", "NOCLICK" }

local function ButterflyCycle_sachet(inst)
    if inst.owner_l == nil or not inst.owner_l:IsValid() then
        if inst.task_l_flower ~= nil then
            inst.task_l_flower:Cancel()
            inst.task_l_flower = nil
        end
        inst.owner_l = nil
        return
    end

    local mult = 1
    if TheWorld.state.isnight or TheWorld.state.iscavenight then
        mult = 0.4
    elseif TheWorld.state.isdusk or TheWorld.state.iscavedusk then
        mult = 0.8
    end
    if TheWorld.state.iswinter then
        mult = mult * 0.2
    elseif TheWorld.state.isspring then
        mult = mult * 1.3
    end
    mult = mult * 0.1 --基础概率10%

    local x, y, z = inst.owner_l.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 8, { "flower" }, tags_cant_sachet)
    for _, v in ipairs(ents) do
        if math.random() < mult then
            local fly = SpawnPrefab("butterfly")
            if fly.components.pollinator ~= nil then
                fly.components.pollinator:Pollinate(v)
            end
            -- fly.components.homeseeker:SetHome(inst.owner_l)
            fly.Physics:Teleport(v.Transform:GetWorldPosition())
        end
    end
end
local function OnEquip_sachet(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "sachet", "swap_body")

    if owner:HasTag("equipmentmodel") then return end --假人

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end

    -- owner:AddComponent("sanityaura")
    -- if owner.sanityaura_l_sachet == nil then
    --     owner.sanityaura_l_sachet = CreateSanityAura_sachet()
	--     owner.sanityaura_l_sachet.entity:SetParent(owner.entity) --这样弄了之后 sanityaura组件 就失效了，所以干脆不弄了
    -- end
    TOOLS_L.AddEntValue(owner, "legiontag_fragrantbody", inst.prefab, nil, 1)

    if inst.task_l_flower ~= nil then
        inst.task_l_flower:Cancel()
    end
    inst.owner_l = owner
    inst.task_l_flower = inst:DoPeriodicTask(5, ButterflyCycle_sachet, 2.5+3*math.random())
end
local function FnOff_sachet(inst, owner)
    if inst.task_l_flower ~= nil then
        inst.task_l_flower:Cancel()
        inst.task_l_flower = nil
    end
    inst.owner_l = nil

    if owner == nil then
        owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner == nil then
            return
        end
    end
    -- owner:RemoveComponent("sanityaura")
    -- if owner.sanityaura_l_sachet ~= nil and owner.sanityaura_l_sachet:IsValid() then
    --     owner.sanityaura_l_sachet:Remove()
    --     owner.sanityaura_l_sachet = nil
    -- end
    TOOLS_L.RemoveEntValue(owner, "legiontag_fragrantbody", inst.prefab, nil)
end
local function OnUnequip_sachet(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
    FnOff_sachet(inst, owner)
end
local function OnDepleted_sachet(inst)
    FnOff_sachet(inst, nil)
    inst:Remove()
end

table.insert(prefs, Prefab("sachet", function()
    local inst = CreateEntity()
    Fn_common(inst, "sachet", nil, "anim", nil, nil)

    MakeInventoryFloatable(inst, "small", 0.2, 0.8)
    local OnLandedClient_old = inst.components.floater.OnLandedClient
    inst.components.floater.OnLandedClient = function(self)
        OnLandedClient_old(self)
        self.inst.AnimState:SetFloatParams(0.03, 1, self.bob_percent)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst.owner_l = nil
    -- inst.task_l_flower = nil

    Fn_server(inst, "sachet", nil, OnEquip_sachet, OnUnequip_sachet)

    inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE -- +6.66精神/分钟

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.SEG_TIME*12) --6分钟的佩戴时间
    inst.components.fueled:SetDepletedFn(OnDepleted_sachet)
    -- inst.components.fueled.no_sewing = true --不可修复

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end, GetAssets("sachet"), { "butterfly" }))

--------------------------------------------------------------------------
--[[ 犀金护甲 ]]
--------------------------------------------------------------------------

local function OnSetBonusOn_beetlearmor(inst)
	inst.components.armor:SetAbsorption(0.95)
    inst.components.armor.conditionlossmultipliers:SetModifier(inst, 0.6, "setbonus")
end
local function OnSetBonusOff_beetlearmor(inst)
	inst.components.armor:SetAbsorption(0.9)
    inst.components.armor.conditionlossmultipliers:RemoveModifier(inst, "setbonus")
end
local function OnEquip_beetlearmor(inst, owner)
    if inst._dd ~= nil then
        owner.AnimState:OverrideSymbol("swap_body", inst._dd.build, inst._dd.file)
    else
        owner.AnimState:OverrideSymbol("swap_body", "armor_elepheetle", "swap_body")
    end
    if owner:HasTag("equipmentmodel") then return end --假人

    TOOLS_L.AddEntValue(owner, "legiontag_stable", inst.prefab, nil, 1) --无硬直
    TOOLS_L.AddEntValue(owner, "legiontag_sedate", inst.prefab, nil, 1) --免疫麻痹
end
local function OnUnequip_beetlearmor(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    if owner:HasTag("equipmentmodel") then return end --假人

    TOOLS_L.RemoveEntValue(owner, "legiontag_stable", inst.prefab, nil)
    TOOLS_L.RemoveEntValue(owner, "legiontag_sedate", inst.prefab, nil)
end
local function SetupEquippable_beetlearmor(inst)
	inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(OnEquip_beetlearmor)
    inst.components.equippable:SetOnUnequip(OnUnequip_beetlearmor)
    inst.components.equippable.insulated = true --防电
    inst.components.equippable.walkspeedmult = 0.15
end
local foreverequip_beetlearmor = {
    -- anim = nil, anim_broken = "broken", fn_broken = nil, fn_repaired = nil,
    fn_setequippable = SetupEquippable_beetlearmor
}

table.insert(prefs, Prefab("armor_elepheetle", function()
    local inst = CreateEntity()
    Fn_common(inst, "armor_elepheetle", nil, nil, nil, "dontstarve/movement/foley/shellarmour")
    inst:AddTag("heavyarmor") --减轻击退效果 官方tag
    inst:AddTag("rp_bugshell_l")
    inst:AddTag("show_broken_ui") --装备损坏后展示特殊物品栏ui
    LS_C_Init(inst, "armor_elepheetle", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "armor_elepheetle"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armor_elepheetle.xml"

    SetupEquippable_beetlearmor(inst)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(1260, 0.9)

    SetBonus(inst, "ELEPHEETLE", OnSetBonusOn_beetlearmor, OnSetBonusOff_beetlearmor)

    MakeHauntableLaunch(inst)

    TOOLS_L.MakeNoLossRepairableEquipment(inst, foreverequip_beetlearmor)

    return inst
end, GetAssets("armor_elepheetle"), nil))

--------------------------------------------------------------------------
--[[ 羽化后的壳 ]]
--------------------------------------------------------------------------

local tags_cant_shuck = TOOLS_L.TagsCombat3({ "player" })

local function AttractEnemies_shuck(inst)
    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 8, { "_combat" }, tags_cant_shuck)
    for _, v in ipairs(ents) do
        if
            v ~= inst and v.entity:IsVisible() and
            TOOLS_L.MaybeEnemy_player(inst, v, true) and
            v.components.combat:CanTarget(inst)
        then
            v.components.combat:SetTarget(inst)
        end
    end
end
local function OnInit_shuck(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_grow")

    inst.AnimState:PlayAnimation("grow_sac_to_small")
    inst.AnimState:PushAnimation("cocoon_small", true)

    AttractEnemies_shuck(inst)
end

local function OnFreeze_shuck(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
    inst.AnimState:PlayAnimation("frozen_small", true)
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end
local function OnThaw_shuck(inst) --快要解冻时的抖动
    inst.AnimState:PlayAnimation("frozen_loop_pst_small", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end
local function OnUnFreeze_shuck(inst)
    inst.AnimState:PlayAnimation("cocoon_small", true)
    inst.SoundEmitter:KillSound("thawing")
    inst.AnimState:ClearOverrideSymbol("swap_frozen")
end

local function OnHit_shuck(inst, attacker)
    if not inst.components.health:IsDead() then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
        inst.AnimState:PlayAnimation("cocoon_small_hit")
        inst.AnimState:PushAnimation("cocoon_small", true)
    end
end
local function OnKilled_shuck(inst)
    inst.AnimState:PlayAnimation("cocoon_dead")

    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")

    if inst.task_remove ~= nil then
        inst.task_remove:Cancel()
        inst.task_remove = nil
    end
end

local function OnEntityWake_shuck(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spidernest_LP", "loop")
end
local function OnEntitySleep_shuck(inst)
    inst.SoundEmitter:KillSound("loop")
    if inst.task_remove ~= nil then
        inst.task_remove:Cancel()
        inst.task_remove = nil
    end

    inst:Remove()
end
local function OnHaunt_shuck(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        OnHit_shuck(inst)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_COOLDOWN_MEDIUM

        if inst.task_remove ~= nil then
            AttractEnemies_shuck(inst) --再次吸引敌人，应该有特殊的作用吧
        end
        return true
    end
    return false
end

table.insert(prefs, Prefab("boltwingout_shuck", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- MakeObstaclePhysics(inst, .5) --为了防止用来卡海，设置为无物理体积

    inst.AnimState:SetBank("spider_cocoon")
    inst.AnimState:SetBuild("boltwingout_shuck")
    inst.AnimState:PlayAnimation("cocoon_small", true)

    inst:AddTag("chewable") -- by werebeaver
    inst:AddTag("companion") --加companion和character标签是为了让大多数怪物能主动攻击自己，并且玩家攻击时不会主动以自己为目标
    -- inst:AddTag("character") --暗影触手会识别这个标签。而暗影触手的 retargetfn 里不对sg提前做判断，导致崩溃
    inst:AddTag("notraptrigger") --不会触发狗牙陷阱
    inst:AddTag("soulless") --为了不产生灵魂

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(20)

    MakeMediumBurnable(inst)
    MakeMediumPropagator(inst)

    MakeMediumFreezableCharacter(inst)
    inst:ListenForEvent("freeze", OnFreeze_shuck)
    inst:ListenForEvent("onthaw", OnThaw_shuck)
    inst:ListenForEvent("unfreeze", OnUnFreeze_shuck)

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit_shuck)
    inst:ListenForEvent("death", OnKilled_shuck)

    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_MEDIUM
    inst.components.hauntable:SetOnHauntFn(OnHaunt_shuck)

    MakeSnowCovered(inst)

    inst:DoTaskInTime(0, OnInit_shuck)
    inst.task_remove = inst:DoTaskInTime(15+math.random()*3, function(inst)
        inst.task_remove = nil
        inst.components.health:Kill() --该函数自带当前生命的判断
    end)

    inst.persists = false

    inst.OnEntitySleep = OnEntitySleep_shuck
    inst.OnEntityWake = OnEntityWake_shuck

    return inst
end, {
    Asset("ANIM", "anim/spider_cocoon.zip"), --官方蜘蛛巢动画
    Asset("ANIM", "anim/boltwingout_shuck.zip")
}, nil))

--------------------------------------------------------------------------
--[[ 脱壳之翅 ]]
--------------------------------------------------------------------------

local function OnEquip_boltout(inst, owner)
    if inst._dd ~= nil then
        owner.AnimState:OverrideSymbol("swap_body", inst._dd.build, inst._dd.file)
        owner.bolt_skin_l = inst._dd.boltdata
    else
        owner.AnimState:OverrideSymbol("swap_body", "swap_boltwingout", "swap_body")
        owner.bolt_skin_l = nil
    end

    if owner:HasTag("equipmentmodel") then return end --假人

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
    owner.bolt_l = inst
end
local function OnUnequip_boltout(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.bolt_skin_l = nil

    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
    owner.bolt_l = nil
end
local function OnBurnt_boltout(inst)
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end
    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end
local function OnIgnite_boltout(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = false
    end
end
local function OnExtinguish_boltout(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = true
    end
end
local function OnEntityReplicated_boltout(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("boltwingout")
    end
end

table.insert(prefs, Prefab("boltwingout", function()
    local inst = CreateEntity()
    Fn_common(inst, "swap_boltwingout", nil, nil, nil, "dontstarve/movement/foley/grassarmour")
    SetBackpack_common(inst, "boltwingout", OnEntityReplicated_boltout)
    LS_C_Init(inst, "boltwingout", true)
    -- inst.foleysound = "legion/foleysound/insect"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    Fn_server(inst, "boltwingout", EQUIPSLOTS.BACK, OnEquip_boltout, OnUnequip_boltout)
    SetBackpack_server(inst, "boltwingout")

    inst.components.equippable.walkspeedmult = 1.1

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt_boltout)
    inst.components.burnable:SetOnIgniteFn(OnIgnite_boltout)
    inst.components.burnable:SetOnExtinguishFn(OnExtinguish_boltout)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end, GetAssets2("boltwingout", "swap_boltwingout", { Asset("ANIM", "anim/ui_piggyback_2x6.zip") }), {
    "boltwingout_fx",
    "boltwingout_shuck"
}))

--------------------------------------------------------------------------
--[[ 子圭·庇 ]]
--------------------------------------------------------------------------

local prefabs_sivsuit = { "sivsuitatk_fx" }

local function SetSymbols_sivsuit(inst, owner)
    if inst._dd ~= nil then
        owner.AnimState:OverrideSymbol("swap_body", inst._dd.build, inst._dd.file)
    else
        owner.AnimState:OverrideSymbol("swap_body", inst.prefab, "swap_body")
    end
end
local function ClearSymbols_sivsuit(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end
local function OnHitOther_bloodarmor(owner, data, armor)
    if armor == nil or not armor:IsValid() then
        return
    end
    if not armor.components.armor:IsDamaged() then
        return
    end
    local value = data.damageresolved or data.damage
    if value ~= nil and value > 0 then --造成了伤害才行
        armor.components.armor:Repair(value*(armor.bloodclotmult_l or 0.2))
    end
end
local function OnCooldown_suit(inst)
    inst._cdtask = nil
end
local function OnAttacked_bloodarmor(owner, data, armor)
    if
        data == nil or data.redirected or --redirected 代表是骑牛等牛帮玩家抵挡伤害的情况
        (owner.components.oldager == nil and --旺达你可真厉害
            (data.damageresolved == nil or data.damageresolved <= 0) --damageresolved 就是指本次受击的血量损失值
        )
    then
        return
    end
    if armor._cdtask ~= nil or armor.components.armor.condition <= 0 then
        return
    end
    armor._cdtask = armor:DoTaskInTime(0.3, OnCooldown_suit)
    if owner.SoundEmitter ~= nil then
        owner.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike")
    end

    local fx = SpawnPrefab(armor.suitfxoverride_l or "sivsuitatk_fx") --这个不是单纯的特效，反伤逻辑也在里面
    if fx ~= nil then
        fx.InitCounterAtk(fx, owner, armor, data.attacker)
    end
end

local function OnSetBonusOn_sivsuit(inst)
	inst.bloodclotmult_l = 0.25
    inst.counteratkmax_l = 100
end
local function OnSetBonusOff_sivsuit(inst)
	inst.bloodclotmult_l = 0.2 --凝血系数
    inst.counteratkmax_l = 80 --反伤上限
end
local function OnRepaired_sivsuit(inst, amount)
    if amount > 0 and inst._broken then
        inst._broken = nil
        inst.components.armor:SetAbsorption(0.7)
    end
end
local function OnBroken_sivsuit(inst)
    if not inst._broken then
        inst._broken = true
        inst.components.armor:SetAbsorption(0.05)
        inst:PushEvent("percentusedchange", { percent = 0 }) --界面需要更新百分比
    end
end
local function OnHitOther_sivsuit(owner, data)
    OnHitOther_bloodarmor(owner, data, owner._bloodarmor_l)
end
local function OnAttacked_sivsuit(owner, data)
    local armor = owner._bloodarmor_l
    if armor == nil or not armor:IsValid() then
        return
    end
    OnAttacked_bloodarmor(owner, data, armor)
end
local function OnEquip_sivsuit(inst, owner)
    SetSymbols_sivsuit(inst, owner)
    if owner:HasTag("equipmentmodel") then return end --假人
    TOOLS_L.AddEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1, 0.25)
    owner._bloodarmor_l = inst
    owner:ListenForEvent("onhitother", OnHitOther_sivsuit)
    -- owner:ListenForEvent("blocked", OnAttacked_sivsuit)
    owner:ListenForEvent("attacked", OnAttacked_sivsuit)
end
local function OnUnequip_sivsuit(inst, owner)
    ClearSymbols_sivsuit(inst, owner)
    TOOLS_L.RemoveEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1)
    owner._bloodarmor_l = nil
    owner:RemoveEventCallback("onhitother", OnHitOther_sivsuit)
    -- owner:RemoveEventCallback("blocked", OnAttacked_sivsuit)
    owner:RemoveEventCallback("attacked", OnAttacked_sivsuit)
end

local function Fn_dealdata_sivsuit(inst, data)
    local dd = {
        cmax = tostring(data.cmax or 80),
        bc = tostring((data.bc or 0.2)*100),
        ac = "100"
    }
    return subfmt(STRINGS.NAMEDETAIL_L.SIVSUIT, dd)
end
local function Fn_getdata_sivsuit(inst)
    local data = {}
    if inst.counteratkmax_l ~= 80 then
        data.cmax = inst.counteratkmax_l
    end
    if inst.bloodclotmult_l ~= 0.2 then
        data.bc = inst.bloodclotmult_l
    end
    return data
end

table.insert(prefs, Prefab("siving_suit", function()
    local inst = CreateEntity()
    Fn_common(inst, "siving_suit", nil, nil, nil, "dontstarve/movement/foley/marblearmour")
    TOOLS_L.InitMouseInfo(inst, Fn_dealdata_sivsuit, Fn_getdata_sivsuit)
    LS_C_Init(inst, "siving_suit", false)

    inst:AddTag("nobrokesg_l")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst._broken = nil
    -- inst._cdtask = nil
    -- inst.armorcostmult_l = 1
    OnSetBonusOff_sivsuit(inst)

    Fn_server(inst, "siving_suit", nil, OnEquip_sivsuit, OnUnequip_sivsuit)

    inst.components.inventoryitem:SetSinks(true) --它是石头做的，不可漂浮

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(525, 0.7)
    SetKeepOnFinished(inst)
    inst.components.armor:SetOnFinished(OnBroken_sivsuit)
    inst.components.armor.onrepair = OnRepaired_sivsuit
    inst.components.armor.TakeDamage = EmptyCptFn --不会因为吸收战斗伤害而损失耐久

    SetBonus(inst, "SIVING", OnSetBonusOn_sivsuit, OnSetBonusOff_sivsuit)

    MakeHauntableLaunch(inst)

    return inst
end, GetAssets("siving_suit"), prefabs_sivsuit))

--------------------------------------------------------------------------
--[[ 子圭·釜 ]]
--------------------------------------------------------------------------

local function OnSetBonusOn_sivsuit2(inst)
	inst.bloodclotmult_l = 0.45
    inst.counteratkmax_l = 200
    inst.armorcostmult_l = 0.85
end
local function OnSetBonusOff_sivsuit2(inst)
	inst.bloodclotmult_l = 0.35 --凝血系数
    inst.counteratkmax_l = 150 --反伤上限
    inst.armorcostmult_l = 1 --损耗系数
end
local function OnRepaired_sivsuit2(inst, amount)
    if amount > 0 and inst._broken then
        inst._broken = nil
        inst.components.armor:SetAbsorption(0.75)
    end
end
local function OnBroken_sivsuit2(inst)
    if not inst._broken then
        inst._broken = true
        inst.components.armor:SetAbsorption(0.1)
        inst:PushEvent("percentusedchange", { percent = 0 }) --界面需要更新百分比
    end
end
local function OnHitOther_sivsuit2(owner, data)
    OnHitOther_bloodarmor(owner, data, owner._bloodarmor2_l)
end
local function OnAttacked_sivsuit2(owner, data)
    local armor = owner._bloodarmor2_l
    if armor == nil or not armor:IsValid() or armor.components.modelegion.now == 3 then
        return
    end
    OnAttacked_bloodarmor(owner, data, armor)
end
local function SetMode_sivsuit2(inst, newmode, doer)
    if doer ~= nil then
        if doer.SoundEmitter ~= nil then
            doer.SoundEmitter:PlaySound("dontstarve/characters/wendy/small_ghost/howl", nil, 0.5)
            doer.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, 0.3)
        end
        TOOLS_L.SendMouseInfoRPC(doer, inst, { mo = newmode }, true, false)
    end
end
local function OnEquip_sivsuit2(inst, owner)
    SetSymbols_sivsuit(inst, owner)
    inst:RemoveTag("cansetmode_l")
    if owner:HasTag("equipmentmodel") then return end --假人
    TOOLS_L.AddEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1, 0.5)
    owner._bloodarmor2_l = inst --本来继续用 _bloodarmor_l 变量名就行的，但是多格装备栏mod会导致有两种护甲都能穿上的情况
    owner:ListenForEvent("onhitother", OnHitOther_sivsuit2)
    -- owner:ListenForEvent("blocked", OnAttacked_sivsuit2)
    owner:ListenForEvent("attacked", OnAttacked_sivsuit2)
    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end
local function OnUnequip_sivsuit2(inst, owner)
    ClearSymbols_sivsuit(inst, owner)
    inst:AddTag("cansetmode_l")
    TOOLS_L.RemoveEntValue(owner, "siv_blood_l_reducer", inst.prefab, 1)
    owner._bloodarmor2_l = nil
    owner:RemoveEventCallback("onhitother", OnHitOther_sivsuit2)
    -- owner:RemoveEventCallback("blocked", OnAttacked_sivsuit2)
    owner:RemoveEventCallback("attacked", OnAttacked_sivsuit2)
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end
local function OnEntityReplicated_sivsuit2(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("siving_suit_gold")
    end
end

local function Fn_dealdata_sivsuit2(inst, data)
    local dd = {
        cmax = tostring(data.cmax or 150),
        bc = tostring((data.bc or 0.35)*100),
        ac = tostring((data.ac or 1)*100)
    }
    return subfmt(STRINGS.NAMEDETAIL_L.SIVSUIT, dd).."\n"..(STRINGS.NAMEDETAIL_L.SIVEQUIP_MODE[data.mo or 1])
end
local function Fn_getdata_sivsuit2(inst)
    local data = {}
    if inst.counteratkmax_l ~= 150 then
        data.cmax = inst.counteratkmax_l
    end
    if inst.bloodclotmult_l ~= 0.35 then
        data.bc = inst.bloodclotmult_l
    end
    if inst.armorcostmult_l ~= 1 then
        data.ac = inst.armorcostmult_l
    end
    if inst.components.modelegion.now ~= 1 then
        data.mo = inst.components.modelegion.now
    end
    return data
end

table.insert(prefs, Prefab("siving_suit_gold", function()
    local inst = CreateEntity()
    Fn_common(inst, "siving_suit_gold", nil, nil, nil, "dontstarve/movement/foley/marblearmour")
    SetBackpack_common(inst, "siving_suit_gold", OnEntityReplicated_sivsuit2)
    TOOLS_L.InitMouseInfo(inst, Fn_dealdata_sivsuit2, Fn_getdata_sivsuit2)
    LS_C_Init(inst, "siving_suit_gold", false)

    inst:AddTag("cansetmode_l")
    inst:AddTag("modemystery_l")
    inst:AddTag("nobrokesg_l")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst._broken = nil
    -- inst._cdtask = nil
    OnSetBonusOff_sivsuit2(inst)

    Fn_server(inst, "siving_suit_gold", EQUIPSLOTS.BACK, OnEquip_sivsuit2, OnUnequip_sivsuit2)
    SetBackpack_server(inst, "siving_suit_gold")

    inst.components.inventoryitem:SetSinks(true) --它是石头做的，不可漂浮

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(945, 0.75)
    SetKeepOnFinished(inst)
    inst.components.armor:SetOnFinished(OnBroken_sivsuit2)
    inst.components.armor.onrepair = OnRepaired_sivsuit2
    inst.components.armor.TakeDamage = EmptyCptFn --不会因为吸收战斗伤害而损失耐久

    SetBonus(inst, "SIVING2", OnSetBonusOn_sivsuit2, OnSetBonusOff_sivsuit2)

    inst:AddComponent("modelegion")
    inst.components.modelegion:Init(1, 3, nil, SetMode_sivsuit2)

    MakeHauntableLaunch(inst)

    return inst
end, GetAssets("siving_suit_gold", { Asset("ANIM", "anim/ui_piggyback_2x6.zip") }), prefabs_sivsuit))

--------------------
--------------------

return unpack(prefs)
