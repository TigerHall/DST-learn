--------------------------------
--[[ 恶魔护照]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-14]]
--[[ @updateTime: 2021-12-14]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local assets =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB..".zip"),--动画
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB..".tex"),
}
--[[耐久消耗完毕-处理方法]]
--local function depletedFn(inst)
--    if inst._owner ~= nil then
--        inst._owner:RemoveTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
--    end
--    inst:Remove()
--end

--[[构造方法]]
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.6)--漂浮在水上

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB)
    inst.AnimState:PlayAnimation("idle")


    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB..".xml"
    inst:AddComponent("tradable")

    inst:AddComponent("doraemon_evil_passport")

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.YELLOWAMULET_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove) -- 耐久耗尽,删除就可以,unequip会被自动调用
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_body", TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB, "swap_body")
        owner:AddTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
        inst.components.doraemon_evil_passport:SetStatus(true)
        if inst.components.fueled then
            inst.components.fueled:StartConsuming()
        end
        inst._owner = owner
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_body")
        owner:RemoveTag(TUNING.DORAEMON_TECH.EVIL_PASSPORT_TAG)
        inst.components.doraemon_evil_passport:SetStatus(false)
        inst._owner = nil -- 加一个下划线 官方inventoryitem已使用owner,虽然挂在不同地方，以防万一作区分
        if inst.components.fueled then
            inst.components.fueled:StopConsuming()
        end
    end)


    MakeHauntableLaunchAndPerish(inst) --作祟相关
    return inst
end



return  Prefab(TUNING.DORAEMON_TECH.EVIL_PASSPORT_PREFAB, fn, assets)