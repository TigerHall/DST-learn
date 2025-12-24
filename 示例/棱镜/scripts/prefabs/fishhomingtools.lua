local TOOLS_L = require("tools_legion")

--------------------------------------------------------------------------
--[[ 打开的容器也是个实体 ]]
--------------------------------------------------------------------------

local assets_cont = {
    Asset("ANIM", "anim/ui_bundle_2x2.zip")
}

local function OnEntityReplicated_cont(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("fishhomingtool")
    end
end

local function Fn_cont()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("bundle")

    --V2C: blank string for controller action prompt
    inst.name = " "

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated_cont
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("fishhomingtool")

    inst.persists = false

    return inst
end

--------------------------------------------------------------------------
--[[ 简易打窝饵制作器 ]]
--------------------------------------------------------------------------

local assets_normal = {
    Asset("ANIM", "anim/fishhomingtool_normal.zip"),
    Asset("ATLAS", "images/inventoryimages/fishhomingtool_normal.xml"),
    Asset("IMAGE", "images/inventoryimages/fishhomingtool_normal.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/fishhomingtool_normal.xml", 256)
}

local prefabs_normal = {
    "fishhomingtool_container",
    "fishhomingbait"
}

local function Fn_normal()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fishhomingtool_normal")
    inst.AnimState:SetBuild("fishhomingtool_normal")
    inst.AnimState:PlayAnimation("idle")

    LS_C_Init(inst, "fishhomingtool_normal", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "fishhomingtool_normal"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fishhomingtool_normal.xml"
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("bundlemaker")
    inst.components.bundlemaker:SetBundlingPrefabs("fishhomingtool_container", "fishhomingbait")
    inst.components.bundlemaker:SetOnStartBundlingFn(function(inst, doer)
        inst.components.stackable:Get():Remove()
    end)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

--------------------------------------------------------------------------
--[[ 专业打窝饵制作器 ]]
--------------------------------------------------------------------------

local assets_awesome = {
    Asset("ANIM", "anim/fishhomingtool_awesome.zip"),
    Asset("ATLAS", "images/inventoryimages/fishhomingtool_awesome.xml"),
    Asset("IMAGE", "images/inventoryimages/fishhomingtool_awesome.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/fishhomingtool_awesome.xml", 256)
}

local function Fn_awesome()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fishhomingtool_awesome")
    inst.AnimState:SetBuild("fishhomingtool_awesome")
    inst.AnimState:PlayAnimation("idle")

    LS_C_Init(inst, "fishhomingtool_awesome", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "fishhomingtool_awesome"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fishhomingtool_awesome.xml"
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("bundlemaker")
    inst.components.bundlemaker:SetBundlingPrefabs("fishhomingtool_container", "fishhomingbait")
    inst.components.bundlemaker:SetOnStartBundlingFn(function(inst, doer)
        inst:Remove()
    end)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

--------------------------------------------------------------------------
--[[ 打窝饵 ]]
--------------------------------------------------------------------------

local assets_bag = {
    Asset("ANIM", "anim/chum_pouch.zip"), --官方鱼食动画
    Asset("ANIM", "anim/fishhomingbait.zip"),
    Asset("ATLAS", "images/inventoryimages/fishhomingbait1.xml"),
    Asset("IMAGE", "images/inventoryimages/fishhomingbait1.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/fishhomingbait1.xml", 256),
    Asset("ATLAS", "images/inventoryimages/fishhomingbait2.xml"),
    Asset("IMAGE", "images/inventoryimages/fishhomingbait2.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/fishhomingbait2.xml", 256),
    Asset("ATLAS", "images/inventoryimages/fishhomingbait3.xml"),
    Asset("IMAGE", "images/inventoryimages/fishhomingbait3.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/fishhomingbait3.xml", 256)
}
local prefabs_bag = {
    "fishhomingbaiting"
}
local baiting_base = {
    dusty = {
        img = "fishhomingbait1", atlas = "images/inventoryimages/fishhomingbait1.xml",
        anim = "idle1", swap = "swap1", symbol = "base1", build = "fishhomingbait"
    },
    pasty = {
        img = "fishhomingbait2", atlas = "images/inventoryimages/fishhomingbait2.xml",
        anim = "idle2", swap = "swap2", symbol = "base2", build = "fishhomingbait"
    },
    hardy = {
        img = "fishhomingbait3", atlas = "images/inventoryimages/fishhomingbait3.xml",
        anim = "idle3", swap = "swap3", symbol = "base3", build = "fishhomingbait"
    }
}

local function OnHit(inst, attacker, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    if not TheWorld.Map:IsOceanAtPoint(x, y, z) then --如果没有投进海洋里，那就只产生个特效
        local fx = SpawnPrefab("sivctl_moi_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
        end
    else
        SpawnPrefab("splash_green").Transform:SetPosition(x, y, z)

        local baiting = SpawnPrefab("fishhomingbaiting")
        if baiting ~= nil then
            if inst._dd ~= nil and inst._dd.build ~= nil then
                baiting.AnimState:SetBank(inst._dd.bank)
                baiting.AnimState:SetBuild(inst._dd.build)
            end
            baiting.Transform:SetPosition(x, y, z)
            inst.components.fishhomingbait:Handover(baiting)
        end
    end

    inst:Remove()
end
local function OnThrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.AnimState:SetBank("chum_pouch")
    local data = inst._dd[inst.components.fishhomingbait.type_shape]
    if data ~= nil then
        inst.AnimState:OverrideSymbol("chum_pouch01", data.build, data.symbol)
    else
        inst.AnimState:OverrideSymbol("chum_pouch01", "fishhomingbait", "base1")
    end
    inst.AnimState:PlayAnimation("spin_loop")

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:SetCollisionMask(COLLISION.GROUND)
    inst.Physics:SetCapsule(.2, .2)
end
local function OnAddProjectile(inst)
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(OnThrown)
    inst.components.complexprojectile:SetOnHit(OnHit)
end
local function OnEquip(inst, owner)
    local data = inst._dd[inst.components.fishhomingbait.type_shape]
    if data ~= nil then
        if data.isshield then
            TOOLS_L.hand_on_shield(owner, data.build, data.swap)
        else
            TOOLS_L.hand_on(owner, data.build, data.swap)
        end
    else
        TOOLS_L.hand_on(owner, "fishhomingbait", "swap1")
    end
end
local function OnUnequip(inst, owner)
    local data = inst._dd[inst.components.fishhomingbait.type_shape]
    if data ~= nil then
        if data.isshield then
            TOOLS_L.hand_off_shield(inst, owner)
        else
            TOOLS_L.hand_off(inst, owner)
        end
    else
        TOOLS_L.hand_off(inst, owner)
    end
end
local function Init_bag(inst)
    local data = inst._dd[inst.components.fishhomingbait.type_shape]
    if data ~= nil then
        inst.components.inventoryitem.atlasname = data.atlas
        inst.components.inventoryitem:ChangeImageName(data.img)
        inst.AnimState:PlayAnimation(data.anim)
    end
end
local function DisplayName_bag(inst)
    local namepre = ""

    for k, str in pairs(STRINGS.FISHHOMING2_LEGION) do
        if inst:HasTag("FH_"..k) then
            namepre = str
            break
        end
    end
    for k, str in pairs(STRINGS.FISHHOMING1_LEGION) do
        if inst:HasTag("FH_"..k) then
            namepre = str..namepre
            break
        end
    end

    local times = 0
    for k, str in pairs(STRINGS.FISHHOMING3_LEGION) do
        if inst:HasTag("FH_"..k) then
            namepre = str..namepre
            times = times + 1

            if times >= 2 then break end
        end
    end

    return namepre..STRINGS.NAMES.FISHHOMINGBAIT
end
local function Fn_dealdata_bag(inst, data)
    local dd = {
        ti = tostring(data.ti or 1)
    }
    if data.sp ~= nil then
        for k, _ in pairs(data.sp) do
            local fh = STRINGS.FISHHOMING3_INFO_LEGION[k]
            if fh ~= nil then
                local fhdd = { fi = tostring(fh.fish), ch = fh.chance }
                if k == "fragrant" then
                    if TheWorld.state.isspring then fhdd.ch = 0.1 end
                elseif k == "hot" then
                    if TheWorld.state.issummer then fhdd.ch = 0.1 end
                elseif k == "wrinkled" then
                    if TheWorld.state.isautumn then fhdd.ch = 0.1 end
                elseif k == "frozen" then
                    if TheWorld.state.iswinter then fhdd.ch = 0.1 end
                end
                fhdd.ch = tostring(fhdd.ch*100)
                if dd.dt == nil then
                    dd.dt = subfmt(STRINGS.NAMEDETAIL_L.FISHHOMING, fhdd)
                else
                    dd.dt = dd.dt..STRINGS.NAMEDETAIL_L.SPACE..subfmt(STRINGS.NAMEDETAIL_L.FISHHOMING, fhdd)
                end
            end
        end
    end
    if dd.dt == nil then
        return subfmt(STRINGS.NAMEDETAIL_L.FISHHOMINGBAIT1, dd)
    else
        return subfmt(STRINGS.NAMEDETAIL_L.FISHHOMINGBAIT2, dd)
    end
end
local function Fn_getdata_bag(inst)
    local data = {}
    local cpt = inst.components.fishhomingbait
    if cpt.times > 1 then
        data.ti = cpt.times
    end
    if cpt.type_special ~= nil then
        data.sp = cpt.type_special
    end
    return data
end

local function Fn_bag()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.Transform:SetTwoFaced()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fishhomingbait")
    inst.AnimState:SetBuild("fishhomingbait")
    inst.AnimState:PlayAnimation("idle1")
    inst.AnimState:SetDeltaTimeMultiplier(.75)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function()
        local pos = Vector3()
        for r = 6.5, 3.5, -.25 do
            pos.x, pos.y, pos.z = ThePlayer.entity:LocalToWorldSpace(r, 0, 0)
            if TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z, false) then
                return pos
            end
        end
        return pos
    end
    inst.components.reticule.ease = true

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制

    TOOLS_L.InitMouseInfo(inst, Fn_dealdata_bag, Fn_getdata_bag, 5)
    LS_C_Init(inst, "fishhomingbait", false)

    inst.displaynamefn = DisplayName_bag

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst._dd = baiting_base

    inst:AddComponent("locomotor")

    inst:AddComponent("oceanthrowable")
    inst.components.oceanthrowable:SetOnAddProjectileFn(OnAddProjectile)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "fishhomingbait1"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fishhomingbait1.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)

    inst:AddComponent("forcecompostable")
    inst.components.forcecompostable.green = true

    inst:AddComponent("fishhomingbait")
    inst.components.fishhomingbait.oninitfn = Init_bag

    MakeHauntableLaunch(inst)

    return inst
end

--------------------------------------------------------------------------
--[[ 使用中的打窝饵 ]]
--------------------------------------------------------------------------

local assets_baiting = {
    Asset("ANIM", "anim/fish_chum.zip")
}
local prefabs_baiting = {
    "chumpiece"
}

local function Init_baiting(inst)
    local type_eat = inst.baitcolors_l[inst.components.fishhomingbait.type_eat]
    if type_eat ~= nil then
        inst.AnimState:SetMultColour(type_eat.r, type_eat.g, type_eat.b, 0.5)
    end
    local type_shape = inst.components.fishhomingbait.type_shape
    if type_shape == "hardy" then
        inst.AnimState:SetScale(0.5, 0.5)
    elseif type_shape == "pasty" then
        inst.AnimState:SetScale(0.75, 0.75)
    else
        inst.AnimState:SetScale(1, 1)
    end
end

local function Fn_baiting()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fish_chum")
    inst.AnimState:SetBuild("fish_chum")
    inst.AnimState:PlayAnimation("fish_chum_base_pre")
    inst.AnimState:PushAnimation("fish_chum_base_idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(3)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    -- inst:AddTag("chum")

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_cloud_LP", "spore_loop")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.baitcolors_l = {
		meat = { r = 138/255, g = 109/255, b = 94/255 },
		monster = { r = 91/255, g = 59/255, b = 123/255 },
		veggie = { r = 163/255, g = 187/255, b = 169/255 },
	}

    inst:AddComponent("fishhomingbait")
    inst.components.fishhomingbait.isbaiting = true
    inst.components.fishhomingbait.oninitfn = Init_baiting

    inst:DoTaskInTime(3 + math.random()*3, function()
        inst.components.fishhomingbait:Baiting()
    end)

    return inst
end

------

return Prefab("fishhomingtool_container", Fn_cont, assets_cont),
    Prefab("fishhomingtool_normal", Fn_normal, assets_normal, prefabs_normal),
    Prefab("fishhomingtool_awesome", Fn_awesome, assets_awesome, prefabs_normal),
    Prefab("fishhomingbait", Fn_bag, assets_bag, prefabs_bag),
    Prefab("fishhomingbaiting", Fn_baiting, assets_baiting, prefabs_baiting)
