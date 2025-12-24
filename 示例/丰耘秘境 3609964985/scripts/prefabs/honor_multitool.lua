local assets =
{
    Asset("ANIM", "anim/honor_multitool.zip"),
}

local SWAP_DATA_BROKEN = { sym_build = "honor_multitool", sym_name = "swap_object_broken_float", bank = "honor_multitool", anim = "idle_broken" }
local SWAP_DATA = { sym_build = "honor_multitool", sym_name = "swap_object", bank = "honor_multitool", anim = "idle" }

local function OnFinished(inst)
    inst.components.hmrrepairable:SetIsBroken(true)
    inst.components.floater:SetBankSwapOnFloat(true, 0, SWAP_DATA_BROKEN)
end

local function OnRepaired(inst)
    inst.components.floater:SetBankSwapOnFloat(true, 2, SWAP_DATA)
end

local function MakeTill1(self,pt,doer,...)
    if TheWorld.Map:CanTillSoilAtPoint(pt.x, 0, pt.z, false) then
		TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
        local item = SpawnPrefab("farm_soil")
        item.Transform:SetPosition(pt:Get())
		if doer ~= nil then
			doer:PushEvent("tilling")
		end
        item:DoTaskInTime(math.random()*0.4, function()
            local dirt_fx = SpawnPrefab("small_puff")  -- small_puff带有声音，dirt_puff没有声音
            dirt_fx.Transform:SetPosition(pt:Get())
        end)
        local leaves_fx = SpawnPrefab("green_leaves")
        leaves_fx.Transform:SetPosition(pt:Get())
        return true
    end
    return false
end

-- 一田9坑
local function MakeTill9(self,pt,doer,...)
    local x1, y1, z1 = TheWorld.Map:GetTileCenterPoint(pt.x,pt.y,pt.z)
    local spacing=4/3
    for x2 = 0,2 do
        for y2 = 0,2 do
            local x3 = x1+spacing * x2-spacing
            local y3 = z1+spacing * y2-spacing
            if TheWorld.Map:CanTillSoilAtPoint(x3, 0, y3, false) then
                TheWorld.Map:CollapseSoilAtPoint(x3, 0, y3)
                local item = SpawnPrefab("farm_soil")
                item.Transform:SetPosition(x3, 0, y3)
                item:AddTag("quickplant")
                if doer ~= nil then
                    doer:PushEvent("tilling")
                end
                item:DoTaskInTime(math.random()*0.4, function()
                    local dirt_fx = SpawnPrefab("small_puff")  -- small_puff带有声音，dirt_puff没有声音
                    dirt_fx.Transform:SetPosition(x3, 0, y3)
                end)
            end
        end
    end
    local leaves_fx = SpawnPrefab("yellow_leaves")
    leaves_fx.Transform:SetPosition(x1, 0, z1)
    return true
end

-- 一田10坑
local function MakeTill10(self,pt,doer,...)
    local x1, y1, z1 = TheWorld.Map:GetTileCenterPoint(pt.x,pt.y,pt.z)
    local positions = {}
    if (z1 + 2) / 4 % 2 == 0 then  -- 一格地皮为4
        positions = {
            {x1 - 1.5, z1 - 1.6},
            {x1 + 0.5, z1 - 1.6},
            {x1 - 0.5, z1 - 0.8},
            {x1 + 1.5, z1 - 0.8},
            {x1 - 1.5, z1},
            {x1 + 0.5, z1},
            {x1 - 0.5, z1 + 0.8},
            {x1 + 1.5, z1 + 0.8},
            {x1 - 1.5, z1 + 1.6},
            {x1 + 0.5, z1 + 1.6}
        }
    else
        positions = {
            {x1 - 0.5, z1 - 1.6},
            {x1 + 1.5, z1 - 1.6},
            {x1 - 1.5, z1 - 0.8},
            {x1 + 0.5, z1 - 0.8},
            {x1 - 0.5, z1},
            {x1 + 1.5, z1},
            {x1 - 1.5, z1 + 0.8},
            {x1 + 0.5, z1 + 0.8},
            {x1 - 0.5, z1 + 1.6},
            {x1 + 1.5, z1 + 1.6}
        }
    end
    for _,pos in ipairs(positions) do
        local x2, z2 = pos[1], pos[2]
        if TheWorld.Map:CanTillSoilAtPoint(x2, 0, z2, false) then
            TheWorld.Map:CollapseSoilAtPoint(x2, 0, z2)
            local item = SpawnPrefab("farm_soil")
            item.Transform:SetPosition(x2, 0, z2)
            if doer ~= nil then
                doer:PushEvent("tilling")
            end
            item:DoTaskInTime(math.random()*0.4, function() 
                local dirt_fx = SpawnPrefab("small_puff")  -- small_puff带有声音，dirt_puff没有声音
                dirt_fx.Transform:SetPosition(x2, 0, z2)
            end)
        end
    end
    local leaves_fx = SpawnPrefab("red_leaves")
    leaves_fx.Transform:SetPosition(x1, 0, z1)
    return true
end

-- 一田16坑
local function MakeTill16(self,pt,doer,...)
    local x1, y1, z1 = TheWorld.Map:GetTileCenterPoint(pt.x,pt.y,pt.z)
    local positions = {
        {x1 - 1.99950, z1 - 1.99950},
        {x1 - 0.66649, z1 - 1.99950},
        {x1 + 0.66651, z1 - 1.99950},
        {x1 + 1.99952, z1 - 1.99950},
        {x1 - 1.99950, z1 - 0.66649},
        {x1 - 0.66649, z1 - 0.66649},
        {x1 + 0.66651, z1 - 0.66649},
        {x1 + 1.99952, z1 - 0.66649},
        {x1 - 1.99950, z1 + 0.66651},
        {x1 - 0.66649, z1 + 0.66651},
        {x1 + 0.66651, z1 + 0.66651},
        {x1 + 1.99952, z1 + 0.66651},
        {x1 - 1.99950, z1 + 1.99952},
        {x1 - 0.66649, z1 + 1.99952},
        {x1 + 0.66651, z1 + 1.99952},
        {x1 + 1.99952, z1 + 1.99952}
    }
    for _,pos in ipairs(positions) do
        local x2, y2 = pos[1], pos[2]
        if TheWorld.Map:CanTillSoilAtPoint(x2, 0, y2, false) then
            TheWorld.Map:CollapseSoilAtPoint(x2, 0, y2)
            local item = SpawnPrefab("farm_soil")
            item.Transform:SetPosition(x2, 0, y2)
            if doer ~= nil then
                doer:PushEvent("tilling")
            end
            item:DoTaskInTime(math.random()*0.4, function()
                local dirt_fx = SpawnPrefab("small_puff")  -- small_puff带有声音，dirt_puff没有声音
                dirt_fx.Transform:SetPosition(x2, 0, y2)
            end)
        end
    end
    local leaves_fx = SpawnPrefab("purple_leaves")
    leaves_fx.Transform:SetPosition(x1, 0, z1)
    return true
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_object", inst.GUID, "honor_multitool")
    else
        owner.AnimState:OverrideSymbol("swap_object", "honor_multitool", "swap_object")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnModeChanged(inst, player)
    inst.mode = (inst.mode + 1) % 4
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if inst.mode == 0 then                                          -- 1格
        owner.net_honormultitoolmode:set(1)         -- 兼容一田十格
        inst.components.farmtiller.Till = MakeTill1
        inst.components.finiteuses:SetConsumption(ACTIONS.TILL, TUNING.HMR_HONOR_MULTITOOL_TILL1_CONSUMPTION)
    elseif inst.mode == 1 then                                      -- 9格
        owner.net_honormultitoolmode:set(1)
        inst.components.farmtiller.Till = MakeTill9
        inst.components.finiteuses:SetConsumption(ACTIONS.TILL, TUNING.HMR_HONOR_MULTITOOL_TILL9_CONSUMPTION)
    elseif inst.mode == 2 then                                      -- 10格
        owner.net_honormultitoolmode:set(5)
        inst.components.farmtiller.Till = MakeTill10
        inst.components.finiteuses:SetConsumption(ACTIONS.TILL, TUNING.HMR_HONOR_MULTITOOL_TILL10_CONSUMPTION)
    elseif inst.mode == 3 then                                      -- 16格
        owner.net_honormultitoolmode:set(2)
        inst.components.farmtiller.Till = MakeTill16
        inst.components.finiteuses:SetConsumption(ACTIONS.TILL, TUNING.HMR_HONOR_MULTITOOL_TILL16_CONSUMPTION)
    end
    if owner.components.talker then
        owner.components.talker:Say(STRINGS.HMR.HONOR_MULTITOOL["MODE"..inst.mode])
    end
end

local DROP_LOOT_BLACK_LIST = {
    rock_moon_shell = true,
    wagstaff_machine = true,
}
local function OnUsedAsItem(inst, action, doer, target)
    if target and target:IsValid() and
        target.prefab ~= nil and not DROP_LOOT_BLACK_LIST[target.prefab] and
        target.components.lootdropper ~= nil
    then
        local loots = target.components.lootdropper:GenerateLoot()
        if loots ~= nil then
            local rand = 0.01
            if action == ACTIONS.CHOP then rand = 0.02          -- 斧子
            elseif action == ACTIONS.MINE then rand = 0.05      -- 镐子
            elseif action == ACTIONS.DIG then rand = 0.3        -- 铲子
            elseif action == ACTIONS.HAMMER then rand = 0.08    -- 锤子
            end
            -- 锤子、斧子、镐子
            for k, v in ipairs(loots) do
                if math.random() <= rand then
                    HMR_UTIL.DropLoot(doer, v, inst)

                    local name = STRINGS.NAMES[string.upper(v)]
                    if name == nil then
                        local item = SpawnPrefab(v)
                        if item ~= nil then
                            name = item.name
                            item:Remove()
                        end
                    end
                    if name ~= nil and doer.components.talker ~= nil then
                        doer.components.talker:Say(string.format(STRINGS.HMR.HONOR_MULTITOOL.GET_EXTRA_GIFT[math.random(1, #STRINGS.HMR.HONOR_MULTITOOL.GET_EXTRA_GIFT)], name))
                    end
                end
            end
            -- 可移植作物
            if math.random() <= rand then
                -- todo: 移植作物
            end
        end
    end
end

local function SetBonusEnabled(inst)
    inst.components.finiteuses:SetOnUsedAsItem(OnUsedAsItem)
end

local function SetBonusDisabled(inst)
    inst.components.finiteuses:SetOnUsedAsItem()
end

local function OnEnableEquipableFn(inst)
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function OnSave(inst, data)
    data.mode = inst.mode
end

local function OnLoad(inst, data)
    inst.mode = data.mode or 0
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil then
        inst.mode = (data.mode or 0) -1
        inst:OnModeChanged()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("honor_multitool")
    inst.AnimState:SetBuild("honor_multitool")

    inst:AddTag("sharp")
    inst:AddTag("tool")
    inst:AddTag("weapon")
	inst:AddTag("shadowlevel")
    inst:AddTag("honor_hoe")    -- 兼容一田十格
    inst:AddTag("honor_item")
    inst:AddTag("honor_repairable")

    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, 2, SWAP_DATA)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.mode = 0

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.HMR_HONOR_MULTITOOL_DAMAGE)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.HMR_HONOR_MULTITOOL_EFFECTIVENESS)       -- 砍伐
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.HMR_HONOR_MULTITOOL_EFFECTIVENESS)       -- 开采
    inst.components.tool:SetAction(ACTIONS.DIG, TUNING.HMR_HONOR_MULTITOOL_EFFECTIVENESS)        -- 挖掘
    inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.HMR_HONOR_MULTITOOL_EFFECTIVENESS)     -- 锤击
	inst.components.tool:EnableToughWork(true)              -- 强力开采

    inst:AddComponent("farmtiller")
    inst.OnModeChanged = OnModeChanged
    inst:AddInherentAction(ACTIONS.TILL)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.HMR_HONOR_MULTITOOL_MAXUSES)
    inst.components.finiteuses:SetUses(TUNING.HMR_HONOR_MULTITOOL_MAXUSES)
    inst.components.finiteuses:SetOnFinished(OnFinished)
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, TUNING.HMR_HONOR_MULTITOOL_CHOP_CONSUMPTION)      -- 砍伐
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, TUNING.HMR_HONOR_MULTITOOL_MINE_CONSUMPTION)      -- 开采
    inst.components.finiteuses:SetConsumption(ACTIONS.DIG, TUNING.HMR_HONOR_MULTITOOL_DIG_CONSUMPTION)       -- 挖掘
    inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, TUNING.HMR_HONOR_MULTITOOL_HAMMER_CONSUMPTION)    -- 锤击
    inst.components.finiteuses:SetConsumption(ACTIONS.TILL, TUNING.HMR_HONOR_MULTITOOL_TILL1_CONSUMPTION)      -- 刨地

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("hmrrepairable")
    inst.components.hmrrepairable:SetNormalData({name = STRINGS.NAMES.HONOR_MULTITOOL, atlasname = "images/inventoryimages/honor_multitool.xml", imagename = "honor_multitool", anim = "idle"})
    inst.components.hmrrepairable:SetBrokenData({name = STRINGS.NAMES.HONOR_MULTITOOL_BROKEN, atlasname = "images/inventoryimages/honor_multitool_broken.xml", imagename = "honor_multitool_broken", anim = "idle_broken"})
    inst.components.hmrrepairable:SetOnEnableEquipableFn(OnEnableEquipableFn)
    inst.components.hmrrepairable:SetOnRepairedFn(OnRepaired)
    inst.components.hmrrepairable:Toggle()

	inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.MULTITOOL_AXE_PICKAXE_SHADOW_LEVEL)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("HONOR")
    inst.components.setbonus:SetOnEnabledFn(SetBonusEnabled)
    inst.components.setbonus:SetOnDisabledFn(SetBonusDisabled)

    MakeHauntableLaunch(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("honor_multitool", fn, assets)