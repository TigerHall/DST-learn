--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    FOODTYPE =
    {
        GENERIC = "GENERIC",
        MEAT = "MEAT",
        VEGGIE = "VEGGIE",
        ELEMENTAL = "ELEMENTAL",
        GEARS = "GEARS",
        HORRIBLE = "HORRIBLE",
        INSECT = "INSECT",
        SEEDS = "SEEDS",
        BERRY = "BERRY", --hack for smallbird; berries are actually part of veggie
        RAW = "RAW", -- things which some animals can eat off the ground, but players need to cook
        BURNT = "BURNT", --For lavae.
        NITRE = "NITRE", -- For acidbats; they are part of elemental.
        ROUGHAGE = "ROUGHAGE",
        WOOD = "WOOD",
        GOODIES = "GOODIES",
        MONSTER = "MONSTER", -- Added in for woby, uses the secondary foodype originally added for the berries
        LUNAR_SHARDS = "LUNAR_SHARDS", -- For rift birds, yummy glass
        CORPSE = "CORPSE", -- For rift buzzards potentially
        MIASMA = "MIASMA", -- For the centipede thrall
    }

    TUNING.STACK_SIZE_SMALLITEM

            STACK_SIZE_LARGEITEM = 10,
            STACK_SIZE_MEDITEM = 20,
            STACK_SIZE_SMALLITEM = 40,
            STACK_SIZE_TINYITEM = 60,


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets = {
        Asset("ANIM", "anim/fwd_in_pdt_food_raw_milk.zip"), 

    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 落水影子
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:HideSymbol("shadow")
        else                                
            inst.AnimState:Show("SHADOW")
            inst.AnimState:ShowSymbol("shadow")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品食用
    local function on_eaten(inst, eater)
        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("fwd_in_pdt_food_raw_milk")
        inst.AnimState:SetBuild("fwd_in_pdt_food_raw_milk")
        inst.AnimState:PlayAnimation("idle",true)
        inst:AddTag("preparedfood")        
        MakeInventoryFloatable(inst)
        inst.entity:SetPristine()        
        if not TheWorld.ismastersim then
            return inst
        end
        --------------------------------------------------------------------------
        ---- 物品名 和检查文本
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            -- inst.components.inventoryitem:TBATInit("tbat_item_butterfly_wrapping_paper","images/inventoryimages/tbat_item_butterfly_wrapping_paper.xml")
        --------------------------------------------------------------------------
        ---- 食物组件
            inst:AddComponent("edible") -- 可食物组件
            inst.components.edible.foodtype = FOODTYPE.GOODIES
            inst.components.edible:SetOnEatenFn(on_eaten)
            inst.components.edible.hungervalue = 15
            inst.components.edible.sanityvalue = -10
            inst.components.edible.healthvalue = 1
        --------------------------------------------------------------------------
        --- 腐烂
            inst:AddComponent("perishable") -- 可腐烂的组件
            inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY*10)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food" -- 腐烂后变成腐烂食物
        --------------------------------------------------------------------------
        --- 叠堆
            inst:AddComponent("stackable") -- 可堆叠
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        -------------------------------------------------------------------
        --- 物品交易
            inst:AddComponent("tradable")
        -------------------------------------------------------------------
            MakeHauntableLaunch(inst)
        -------------------------------------------------------------------
        --- 落水影子
            inst:ListenForEvent("on_landed",shadow_init)
            shadow_init(inst)
        -------------------------------------------------------------------    
        return inst
    end
return Prefab("fwd_in_pdt_food_raw_milk", fn, assets)