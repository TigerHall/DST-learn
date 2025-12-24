--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    勇者玫瑰

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_food_valorbush"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_food_valorbush.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:PlayAnimation("water")
        else
            inst.AnimState:Show("SHADOW")
            inst.AnimState:PlayAnimation("idle")
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

        inst.AnimState:SetBank("tbat_food_valorbush")
        inst.AnimState:SetBuild("tbat_food_valorbush")
        inst.AnimState:PlayAnimation("idle")


        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_food_valorbush","images/inventoryimages/tbat_food_valorbush.xml")
        -----------------------------------------------------------
            inst:ListenForEvent("on_landed",item_onland_event)
        -----------------------------------------------------------
        --- 可食用
            inst:AddComponent("edible")
            inst.components.edible.foodtype = FOODTYPE.VEGGIE
            inst.components.edible.healthvalue = 5
            inst.components.edible.hungervalue = 1
            inst.components.edible.sanityvalue = 1
        -----------------------------------------------------------
        --- 腐烂
            inst:AddComponent("perishable")
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
            inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*3)
        -----------------------------------------------------------
        --- 可叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        -----------------------------------------------------------
        --- 
            inst:AddComponent("tradable")
        -----------------------------------------------------------
        MakeHauntableLaunch(inst)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 添加到烹饪锅
    AddIngredientValues({this_prefab}, {veggie=0.5})
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
