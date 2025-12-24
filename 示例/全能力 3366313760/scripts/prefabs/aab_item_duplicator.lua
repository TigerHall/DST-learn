local assets =
{
    Asset("ANIM", "anim/monkey_island_portal.zip"),
    Asset("ATLAS", "images/inventoryimages/aab_item_duplicator.xml"),
    Asset("ATLAS_BUILD", "images/inventoryimages/aab_item_duplicator.xml", 256), --小木牌和展柜使用
}

RegisterInventoryItemAtlas("images/inventoryimages/aab_item_duplicator.xml", "aab_item_duplicator.tex")

local function Start(inst)
    inst.components.timer:StartTimer("spawn", TUNING.TOTAL_DAY_TIME * 2)
    inst.SoundEmitter:PlaySound("monkeyisland/portal/idle_lp", "loop")
    inst.AnimState:PlayAnimation("in_idle", true)
end

local function Stop(inst)
    inst.components.timer:StopTimer("spawn")
    inst.SoundEmitter:KillSound("loop")
    inst.AnimState:PlayAnimation("out_idle", true)
end

local function on_timer_done(inst, data)
    if data.name == "spawn" then
        local item = inst.components.container:GetItemInSlot(1)
        if item and item.components.stackable and not item.components.stackable:IsFull() then
            item.components.stackable:SetStackSize(item.components.stackable.stacksize + 1)
            inst.SoundEmitter:PlaySound("monkeyisland/portal/spit_item")
            inst.components.timer:StartTimer("spawn", TUNING.TOTAL_DAY_TIME * 2)
        else
            Stop(inst)
        end
    end
end

local function OnItemGet(inst, data)
    if not inst.components.timer:TimerExists("spawn") then
        Start(inst)
    end
end

local function OnItemLose(inst, data)
    if inst.components.container:IsEmpty() then
        Stop(inst)
    end
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    ReplacePrefab(inst, "collapse_big"):SetMaterial("wood")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("monkey_island_portal.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.AnimState:SetBank("monkey_island_portal")
    inst.AnimState:SetBuild("monkey_island_portal")
    inst.AnimState:PlayAnimation("out_idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)

    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(.8)
    inst.Light:SetColour(98 / 255, 18 / 255, 227 / 255)
    inst.Light:Enable(true)

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.min_speed = 4
    inst.components.lootdropper.max_speed = 6
    inst.components.lootdropper.y_speed_variance = 2

    inst:AddComponent("timer")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aab_item_duplicator")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)

    inst:ListenForEvent("timerdone", on_timer_done)
    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    return inst
end

return Prefab("aab_item_duplicator", fn, assets),
    MakePlacer("aab_item_duplicator_placer", "monkey_island_portal", "monkey_island_portal", "out_idle")
