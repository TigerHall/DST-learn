local assets =
{
    Asset("ANIM", "anim/hmr_cherry_flower.zip"),
}

local names = {"idle1","idle2"}

local function onpickedfn(inst, picker)
    local pos = inst:GetPosition()

    if picker ~= nil then
        if picker.components.sanity ~= nil and not picker:HasTag("plantkin") then
            picker.components.sanity:DoDelta(TUNING.SANITY_TINY)
        end
    end

    TheWorld:PushEvent("plantkilled", { doer = picker, pos = pos }) --this event is pushed in other places too
end

local FINDLIGHT_MUST_TAGS = { "daylight", "lightsource" }
local function DieInDarkness(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,0,z, TUNING.DAYLIGHT_SEARCH_RANGE, FINDLIGHT_MUST_TAGS)
    for i,v in ipairs(ents) do
        local lightrad = v.Light:GetCalculatedRadius() * .7
        if v:GetDistanceSqToPoint(x,y,z) < lightrad * lightrad then
            --found light
            return
        end
    end
    --in darkness
    inst:Remove()
    SpawnPrefab("flower_withered").Transform:SetPosition(x,y,z)
end

local function OnIsCaveDay(inst, isday)
    if isday then
        inst:DoTaskInTime(5.0 + math.random()*5.0, DieInDarkness)
    end
end

local function setflowertype(inst)
    if inst.anim == nil then
        inst.anim = names[math.random(#names)]
    end
    inst.AnimState:PlayAnimation(inst.anim)
end

local function OnSave(inst, data)
    data.anim = inst.anim
end

local function OnLoad(inst, data)
    inst.anim = data.anim
    setflowertype(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("hmr_cherry_flower")
    inst.AnimState:SetBuild("hmr_cherry_flower")
    inst.AnimState:SetRayTestOnBB(true)

	inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2) --butterfly deployspacing/2

    inst:AddTag("flower")
    inst:AddTag("cattoy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("petals", 10)
    inst.components.pickable.onpickedfn = onpickedfn
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true
    inst.components.pickable.wildfirestarter = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    if TheWorld:HasTag("cave") then -- 没有光源就死亡
        inst:WatchWorldState("iscaveday", OnIsCaveDay)
    end

    MakeHauntableChangePrefab(inst, "flower_evil")

    if not POPULATING then
        setflowertype(inst)
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("hmr_cherry_flower", fn, assets)