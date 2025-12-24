
local assets = {
	Asset("ANIM", "anim/ui_portablecellar.zip"),
}



local function OnAttacked(inst, data)
    local attacker = data.attacker
    inst.components.combat:SetTarget(attacker)
end

local function ShouldAcceptItem(inst, item)
    if item.components.equippable then
        --如果是头部， 身体 和手 则可以装备
        if item.components.equippable.equipslot == EQUIPSLOTS.HEAD or
            item.components.equippable.equipslot == EQUIPSLOTS.BODY or
            item.components.equippable.equipslot == EQUIPSLOTS.HANDS then
            return true
        end
    end

    return inst.components.eater:CanEat(item)
end


local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    inst.components.talker:Say("我不需要这个东西")
end


local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.eater:CanEat(item) then
        --增加健康值
        inst.components.health.currenthealth = inst.components.health.currenthealth + item.components.edible.healthvalue
        --如果超过了最大生命值，则修改成最大生命值
        if inst.components.health.currenthealth > inst.components.health.maxhealth then
            inst.components.health.currenthealth = inst.components.health.maxhealth
        end

        inst.components.talker:Say("谢谢你，我现在感觉好多了")
        return
    end

    if item.components.equippable then
        local current = inst.components.inventory:GetEquippedItem(item.components.equippable.equipslot)
        if current then
            inst.components.inventory:DropItem(current)
        end
        inst.components.talker:Say("谢谢你，我变强大了")
        inst.components.inventory:Equip(item)
    end
end


local function onsave(inst, data)
    data.attack = inst.components.combat.defaultdamage
    data.maxhealth = inst.components.health.maxhealth
    data.currenthealth = inst.components.health.currenthealth
end

local function onload(inst, data)
    if data then
        inst.components.combat.defaultdamage = data.attack
        inst.components.health.maxhealth = data.maxhealth
        inst.components.health.currenthealth = data.currenthealth
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.Transform:SetFourFaced()
    
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeCharacterPhysics(inst, 50, .5)

    inst:AddTag("character")

    inst.AnimState:SetBank("pigman")
    inst.AnimState:SetBuild("pig_build")
    inst.AnimState:PlayAnimation("idle_loop")

    --可以移动
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3

    
    --可以交易
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer 
    inst.components.trader.onrefuse = OnRefuseItem
    
    --添加可吃东西组件
    inst:AddComponent("eater")
    inst.components.eater.foodprefs = { "PigPet" }


    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(20)

    --可以战斗
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pig_torso"
    inst.components.combat:SetDefaultDamage(5)
    inst.components.combat:SetAttackPeriod(2)

    inst:ListenForEvent("attacked", OnAttacked)

    --添加talker 组件
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0,-400,0)

    --可以跟随玩家
    inst:AddComponent("follower")
    --物品栏，可以装备武器，防具，背包等
    inst:AddComponent("inventory")
    inst.components.inventory.dropondeath = false

    inst:AddComponent("inspectable")
    
    --添加growth 组件
    inst:AddComponent("growth")

     --设置状态图
     inst:SetStateGraph("SGpigpet")
     --设置brain
     inst:SetBrain(require "brains/pigpetbrain")
     inst:ListenForEvent("attacked", OnAttacked)         
     --监听onload 和 onsave

     inst.OnSave = onsave
     inst.OnLoad = onload

    return inst
end

return Prefab("common/pigpet", fn, assets)