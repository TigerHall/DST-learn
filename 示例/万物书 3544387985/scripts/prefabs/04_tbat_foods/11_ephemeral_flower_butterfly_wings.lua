--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    昙花蝴蝶翅膀

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_food_ephemeral_flower_butterfly_wings"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_food_ephemeral_flower_butterfly_wings.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:HideSymbol("shadow")
        else
            inst.AnimState:ShowSymbol("shadow")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_food_ephemeral_flower_butterfly_wings")
        inst.AnimState:SetBuild("tbat_food_ephemeral_flower_butterfly_wings")
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("cattoy")

        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})


        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_food_ephemeral_flower_butterfly_wings","images/inventoryimages/tbat_food_ephemeral_flower_butterfly_wings.xml")
        -----------------------------------------------------------
            inst:ListenForEvent("on_landed",item_onland_event)
        -----------------------------------------------------------
        --- 可食用
            inst:AddComponent("edible")
            inst.components.edible.foodtype = FOODTYPE.GOODIES
            inst.components.edible.healthvalue = 0
            inst.components.edible.hungervalue = 0
            inst.components.edible.sanityvalue = 0
        -----------------------------------------------------------
        --- 腐烂
            inst:AddComponent("perishable")
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
            inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*6)
        -----------------------------------------------------------
        --- 可叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TBAT.PARAM.STACK_20()
        -----------------------------------------------------------
        --- 可交易
            inst:AddComponent("tradable")
        -----------------------------------------------------------
        --- 可燃
            inst:AddComponent("fuel")
            inst.components.fuel.fuelvalue = 7.5
            MakeSmallBurnable(inst,7.5)
            MakeSmallPropagator(inst)
        -----------------------------------------------------------
        MakeHauntableLaunch(inst)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 添加到烹饪锅
    AddIngredientValues({this_prefab}, {magic=1,decoration=2})
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
