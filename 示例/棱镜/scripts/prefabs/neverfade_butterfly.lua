require "prefabutil"

local assets = {
    Asset("ANIM", "anim/neverfade_butterfly.zip"),
    Asset("ANIM", "anim/butterfly_basic.zip") --官方蝴蝶动画模板
}
local brain = require "brains/neverfade_butterflybrain"

local function Fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    -- inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 1, .5)

    inst:AddTag("NOCLICK") --不被鼠标响应
    inst:AddTag("NOBLOCK") --不妨碍玩家摆放建筑物
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("FX")

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("butterfly")
    inst.AnimState:SetBuild("neverfade_butterfly")
    inst.AnimState:PlayAnimation("idle")
    -- inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetLightOverride(.2)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    -- inst.AnimState:SetFinalOffset(3)

    -- inst.Light:SetIntensity(.6)
    -- inst.Light:SetRadius(.5)
    -- inst.Light:SetFalloff(.6)
    -- inst.Light:Enable(true)
    -- inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false
    -- inst.legiontag_dead = 1

    inst:AddComponent("locomotor") --locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }
    inst.components.locomotor.walkspeed = 6 --苍蝇是8，蝴蝶是4
    inst.components.locomotor.runspeed = 8 --苍蝇是12，蝴蝶是6

    inst:AddComponent("follower")

    inst:SetStateGraph("SGneverfade_butterfly")

    inst:SetBrain(brain)

    return inst
end

return Prefab("neverfade_butterfly", Fn, assets)
