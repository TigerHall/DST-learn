local assets =
{
    Asset("ANIM", "anim/flowers_rainforest.zip"),
}

local prefabs =
{
    "petals",
	"small_puff",
}

local names = {"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12","f14","f15","f16","f17"}

local function setflowertype(inst, name)
    if inst.animname == nil or (name ~= nil and inst.animname ~= name) then
        inst.animname = name or names[math.random(#names)]
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function onsave(inst, data)
    data.anim = inst.animname
    data.origin_plant_idx = inst.origin_plant_idx
end

local function onload(inst, data)
    setflowertype(inst, data ~= nil and data.anim or nil)
end

local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.origin_plant_idx ~= nil then
        if TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.AddOriginPlant ~= nil then
            TheWorld.medal_origin_tree:AddOriginPlant(inst,data.origin_plant_idx)--加入本源之树列表
        end
    end
end

local function onpickedfn(inst, picker)
    local pos = inst:GetPosition()

    -- if picker ~= nil then
    --     if picker.components.sanity ~= nil and not picker:HasTag("plantkin") then
    --         picker.components.sanity:DoDelta(TUNING.SANITY_TINY)
    --     end
    -- end
    
    --获取本源能量(只能在本源之树范围内获取)
    if picker and picker:HasTag("under_origin_tree") then
        picker:AddMedalDebuff("buff_medal_origin_energy",2)
    end

    TheWorld:PushEvent("plantkilled", { doer = picker, pos = pos }) --this event is pushed in other places too
end

--移除
local function OnRemoveEntity(inst)
    if inst.origin_plant_idx ~= nil and TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.RemoveOriginPlant ~= nil then
        TheWorld.medal_origin_tree:RemoveOriginPlant(inst)--从本源之树植物列表中移除
    end
end

--催熟
local function DoOriginGrowth(inst)
    local cactus = SpawnPrefab("medal_origin_cactus")
    if cactus ~= nil then
        cactus.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if inst.origin_plant_idx ~= nil and TheWorld and TheWorld.medal_origin_tree ~= nil and TheWorld.medal_origin_tree.UpdateOriginPlant ~= nil then
            TheWorld.medal_origin_tree:UpdateOriginPlant(inst,cactus)--更新本源之树绑定的目标
        end
        if cactus.playSpawnAnimation then
            cactus:playSpawnAnimation()
        end
        inst:Remove()
    end
    return true
end

--授粉
local function DoOriginPollination(inst)
    DoOriginGrowth(inst)--直接催熟
end

--作祟
local function OnHaunt(inst, haunter)
    return DoOriginGrowth(inst)--直接催熟
end

--------------------------------------------------------------------------

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("flowers_rainforest")
    inst.AnimState:SetBuild("flowers_rainforest")
    inst.AnimState:SetRayTestOnBB(true)
    -- inst.scrapbook_anim = "f1"

	inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2) --butterfly deployspacing/2

	inst:AddTag("origin_flower")--本源之花(可生成昆虫)
    inst:AddTag("origin_pollinationable")--可授粉
    -- inst:AddTag("cattoy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    -- inst.components.pickable:SetUp("petals", 10)
    inst.components.pickable:SetUp(nil, 0)
    inst.components.pickable.onpickedfn = onpickedfn
	inst.components.pickable.remove_when_picked = true
    -- inst.components.pickable.quickpick = true
    -- inst.components.pickable.wildfirestarter = true

    --inst:AddComponent("transformer")
    --inst.components.transformer:SetTransformWorldEvent("isfullmoon", true)
    --inst.components.transformer:SetRevertWorldEvent("isfullmoon", false)
    --inst.components.transformer:SetOnLoadCheck(testfortransformonload)
    --inst.components.transformer.transformPrefab = "flower_evil"

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    if not POPULATING then
        setflowertype(inst)
    end
    --------SaveLoad
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnLoadPostPass = OnLoadPostPass

    inst.DoOriginGrowth = DoOriginGrowth--催熟
    inst.DoOriginPollination = DoOriginPollination--授粉

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("medal_origin_flower", commonfn, assets, prefabs)
