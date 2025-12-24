--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 数据
    local ALL_FOODS_DATA = require("_key_modules_of_tbat/15_cooking/01_01_phase2_cooked_foods_data")
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
    ---
        local all_ret = {}
        for prefab_name, data in pairs(ALL_FOODS_DATA) do
            local assets = {
                Asset("ANIM", "anim/"..prefab_name..".zip"), 
            }
            local function fn()
                --------------------------------------------------------------------------
                --- 实例
                    local inst = CreateEntity()
                    inst.entity:AddTransform()
                    inst.entity:AddAnimState()
                    inst.entity:AddNetwork()
                    MakeInventoryPhysics(inst)
                    inst.AnimState:SetBank(prefab_name)
                    inst.AnimState:SetBuild(prefab_name)
                    inst.AnimState:PlayAnimation("idle",true)
                    inst.AnimState:SetScale(0.9,0.9,0.9)
                    inst:AddTag("preparedfood")        
                    MakeInventoryFloatable(inst)
                    inst.entity:SetPristine()
                --------------------------------------------------------------------------
                --- 自定义初始化
                    if data.custom_init_fn then
                        data.custom_init_fn(inst)
                    end
                --------------------------------------------------------------------------
                if not TheWorld.ismastersim then
                    return inst
                end
                --------------------------------------------------------------------------
                ---- 物品名 和检查文本
                    inst:AddComponent("inspectable")
                    inst:AddComponent("inventoryitem")
                    inst.components.inventoryitem:TBATInit(prefab_name,"images/inventoryimages/"..prefab_name..".xml")
                --------------------------------------------------------------------------
                ---- 食物组件
                    inst:AddComponent("edible") -- 可食物组件
                    inst.components.edible.foodtype = data.foodtype or FOODTYPE.GOODIES
                    inst.components.edible:SetOnEatenFn(data.oneaten)
                    inst.components.edible.hungervalue = data.hungervalue or 0
                    inst.components.edible.sanityvalue = data.sanityvalue or 0
                    inst.components.edible.healthvalue = data.healthvalue or 0
                --------------------------------------------------------------------------
                --- 腐烂
                    if data.perishtime then
                        inst:AddComponent("perishable") -- 可腐烂的组件
                        inst.components.perishable:SetPerishTime(data.perishtime)
                        inst.components.perishable:StartPerishing()
                        inst.components.perishable.onperishreplacement = "spoiled_food" -- 腐烂后变成腐烂食物
                    end
                --------------------------------------------------------------------------
                --- 叠堆
                    if data.stacksize then
                        inst:AddComponent("stackable") -- 可堆叠
                        inst.components.stackable.maxsize =  data.stacksize -- TUNING.STACK_SIZE_SMALLITEM
                    end
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
                --- 可燃
                    if data.burningtime then
                        inst:AddComponent("fuel")
                        inst.components.fuel.fuelvalue = data.burningtime
                        MakeSmallBurnable(inst,data.burningtime)
                        MakeSmallPropagator(inst)
                    end
                -------------------------------------------------------------------
                ---
                    if data.master_init_fn then
                        data.master_init_fn(inst)
                    end
                -------------------------------------------------------------------    
                return inst
            end
            table.insert(all_ret,Prefab(prefab_name, fn, assets))
        end
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    return unpack(all_ret)