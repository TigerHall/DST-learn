--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    生肉熟肉
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_food_raw_meat"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_food_raw_meat.zip"),
        Asset("ANIM", "anim/tbat_food_raw_meat_cooked.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:PlayAnimation("item_water")
        else
            inst.AnimState:Show("SHADOW")
            inst.AnimState:PlayAnimation("item")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function common_fn(bank,build)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank(bank or "tbat_food_raw_meat")
        inst.AnimState:SetBuild(build or "tbat_food_raw_meat")
        inst.AnimState:PlayAnimation("item")
        inst:AddTag("meat")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
        -----------------------------------------------------------
            inst:ListenForEvent("on_landed",item_onland_event)
        -----------------------------------------------------------
        --- 可食用
            inst:AddComponent("edible")
            inst.components.edible.ismeat = true
            inst.components.edible.foodtype = FOODTYPE.MEAT
        -----------------------------------------------------------
        --- 腐烂
            inst:AddComponent("perishable")
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
            inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*6)
        -----------------------------------------------------------
        --- 可叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
        -----------------------------------------------------------
        --- 
            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
        -----------------------------------------------------------
        MakeHauntableLaunch(inst)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function normal_fn()
        local inst = common_fn()
        inst:AddTag("cookable")
        if not TheWorld.ismastersim then
            return inst
        end
        inst.components.inventoryitem:TBATInit("tbat_food_raw_meat","images/inventoryimages/tbat_food_raw_meat.xml")
        inst.components.edible.healthvalue = 1
        inst.components.edible.hungervalue = 25
        inst.components.edible.sanityvalue = 10
        inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*6)
        inst:AddComponent("cookable")
        inst.components.cookable.product = "tbat_food_raw_meat_cooked"
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 晾干的
    local function cooked_fn()
        local inst  = common_fn("tbat_food_raw_meat_cooked","tbat_food_raw_meat_cooked")
        if not TheWorld.ismastersim then
            return inst
        end
        inst.components.inventoryitem:TBATInit("tbat_food_raw_meat_cooked","images/inventoryimages/tbat_food_raw_meat_cooked.xml")
        inst.components.edible.healthvalue = 3
        inst.components.edible.hungervalue = 25
        inst.components.edible.sanityvalue = 0
        inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*10)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 添加到烹饪锅
    AddIngredientValues({this_prefab,this_prefab.."_cooked"}, {meat=1})
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, normal_fn, assets),
    Prefab(this_prefab.."_cooked", cooked_fn, assets)
