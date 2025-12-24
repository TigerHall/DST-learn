--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    水母
    
    晾晒相关：
        inst:AddComponent("dryable")
        inst.components.dryable:SetProduct(dryable.product)     --- 设置产品
        inst.components.dryable:SetDryTime(dryable.time)        --- 设置烘干时间
		inst.components.dryable:SetBuildFile(dryable.build)     --- 晾晒前的 build 文件
        inst.components.dryable:SetDriedBuildFile(dryable.dried_build) -- 晾晒后的build文件
        --- inst.components.dryable.prefab  -- 调用build里的图层。
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_food_jellyfish"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_food_jellyfish.zip"),
        Asset("ANIM", "anim/tbat_food_jellyfish_dried.zip"),
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
--- 创建物品
    local function normal_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_food_jellyfish")
        inst.AnimState:SetBuild("tbat_food_jellyfish")
        inst.AnimState:PlayAnimation("item")

        inst:AddTag("meat")
        inst:AddTag("dryable")

        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_food_jellyfish","images/inventoryimages/tbat_food_jellyfish.xml")
        -----------------------------------------------------------
            inst:ListenForEvent("on_landed",item_onland_event)
        -----------------------------------------------------------
        --- 可食用
            inst:AddComponent("edible")
            inst.components.edible.ismeat = true
            inst.components.edible.foodtype = FOODTYPE.MEAT
            inst.components.edible.healthvalue = 5
            inst.components.edible.hungervalue = 2
            inst.components.edible.sanityvalue = 20
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
        --- 晾晒相关
            inst:AddComponent("dryable")
            inst.components.dryable:SetProduct(this_prefab.."_dried")     --- 设置产品
            inst.components.dryable:SetDryTime(TBAT.DEBUGGING and 10 or TBAT.PARAM.ONE_DAY*2)        --- 设置烘干时间
            inst.components.dryable:SetBuildFile(this_prefab)     --- 晾晒前的 build 文件
            inst.components.dryable:SetDriedBuildFile(this_prefab.."_dried") -- 晾晒后的build文件
        -----------------------------------------------------------
        --- 
            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
        -----------------------------------------------------------
        MakeHauntableLaunch(inst)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 晾干的
    local function dried_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_food_jellyfish_dried")
        inst.AnimState:SetBuild("tbat_food_jellyfish_dried")
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
            inst.components.inventoryitem:TBATInit("tbat_food_jellyfish_dried","images/inventoryimages/tbat_food_jellyfish_dried.xml")
        -----------------------------------------------------------
            inst:ListenForEvent("on_landed",item_onland_event)
        -----------------------------------------------------------
        --- 可食用
            inst:AddComponent("edible")
            inst.components.edible.ismeat = true
            inst.components.edible.foodtype = FOODTYPE.MEAT
            inst.components.edible.healthvalue = 5
            inst.components.edible.hungervalue = 20
            inst.components.edible.sanityvalue = 20
        -----------------------------------------------------------
        --- 腐烂
            -- inst:AddComponent("perishable")
            -- inst.components.perishable:StartPerishing()
            -- inst.components.perishable.onperishreplacement = "spoiled_food"
            -- inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*3)
        -----------------------------------------------------------
        --- 可叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        -----------------------------------------------------------
        --- 
            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
        -----------------------------------------------------------
        MakeHauntableLaunch(inst)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 添加到烹饪锅
    AddIngredientValues({this_prefab,this_prefab.."_dried"}, {meat=1})
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, normal_fn, assets),
    Prefab(this_prefab.."_dried", dried_fn, assets)
