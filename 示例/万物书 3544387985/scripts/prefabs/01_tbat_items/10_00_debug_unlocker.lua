--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_potion_recipe_for_"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_blueprint.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 影子
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:HideSymbol("shadow")
        else                                
            inst.AnimState:ShowSymbol("shadow")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable 右键使用模块
    local function workable_on_work_fn(inst,doer)
        ------------------------------------------------------------------------------------------
        --- 物品消耗
            inst.components.stackable:Get():Remove()
        ------------------------------------------------------------------------------------------
        --- 内部执行
            doer.components.tbat_com_mushroom_snail_cauldron__for_player:Unlock(inst.unlock_recipe_prefab)
        ------------------------------------------------------------------------------------------
        return true
    end
    local function workable_test_fn(inst,doer,right_click)        
        return inst.replica.inventoryitem:IsGrandOwner(doer)
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.HEAL.USE)
        replica_com:SetSGAction("dolongaction") --- 执行长动作动画
        -- replica_com:SetSGAction("doshortaction") --- 执行瞬间动画
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品
    local function common_item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_blueprint")
        inst.AnimState:SetBuild("tbat_item_blueprint")
        inst.AnimState:PlayAnimation("idle",true)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        -- inst:AddTag("usedeploystring")
        inst.entity:SetPristine()
        -------------------------------------------------
        ---
            workable_install(inst)
        -------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -------------------------------------------------
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_blueprint","images/inventoryimages/tbat_item_blueprint.xml")
        -------------------------------------------------
            inst:ListenForEvent("on_landed",shadow_init)
        -------------------------------------------------
        --- 叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize =  TBAT.PARAM.STACK_40()
        -------------------------------------------------
            inst:AddComponent("named")
            inst:AddComponent("fuel")
            inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL
            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            MakeSmallPropagator(inst)
            MakeHauntableLaunch(inst)
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local blueprint_prefabs = {
		"tbat_item_wish_note_potion",			-- 【药剂】 愿望之笺
		"tbat_item_veil_of_knowledge_potion", 	-- 【药剂】 知识之纱
		"tbat_item_oath_of_courage_potion", 	-- 【药剂】 勇气之誓
		"tbat_item_lucky_words_potion", 		-- 【药剂】 幸运之语
		"tbat_item_peach_blossom_pact_potion",	-- 【药剂】 桃花之约
    }
    local ret = {}
    for k, prefab in pairs(blueprint_prefabs) do
        local temp_prefab = this_prefab..prefab
        local function fn()
            local inst = common_item_fn()
            inst.unlock_recipe_prefab = prefab
            if not TheWorld.ismastersim then
                return inst
            end
            inst.components.named:SetName("配方:"..STRINGS.NAMES[prefab:upper(prefab)])
            return inst
        end
        table.insert(ret, Prefab(temp_prefab, fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)

