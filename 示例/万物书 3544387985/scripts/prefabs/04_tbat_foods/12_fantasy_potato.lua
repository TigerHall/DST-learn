--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    幻想土豆

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_food_fantasy_potato"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_food_fantasy_potato.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local foods_data = {
        [this_prefab] ={
            healthvalue = 1,
            hungervalue = 5,
            sanityvalue = 1,
            anim = {
                normal = "idle",
                water = "idle_water",
            },
            image = "tbat_food_fantasy_potato",
            cook_product = this_prefab.."_cooked",
        },
        [this_prefab.."_cooked"] ={
            healthvalue = 2,
            hungervalue = 10,
            sanityvalue = 2,
            anim = {
                normal = "cooked",
                water = "cooked_water",
            },
            image = "tbat_food_fantasy_potato_cooked",
        },

    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local ret_prefabs = {}
    for temp_prefab, data in pairs(foods_data) do
            local function item_onland_event(inst)
                if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
                    inst.AnimState:PlayAnimation(data.anim.water)
                else
                    inst.AnimState:PlayAnimation(data.anim.normal)
                end
            end
            local function fn()
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddSoundEmitter()
                inst.entity:AddNetwork()
                MakeInventoryPhysics(inst)
                inst.AnimState:SetBank("tbat_food_fantasy_potato")
                inst.AnimState:SetBuild("tbat_food_fantasy_potato")
                inst.AnimState:PlayAnimation(data.anim.normal)
                inst:AddTag("cattoy")
                MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
                inst.entity:SetPristine()
                if not TheWorld.ismastersim then
                    return inst
                end
                -----------------------------------------------------------
                    inst:AddComponent("inspectable")
                    inst:AddComponent("inventoryitem")
                    inst.components.inventoryitem:TBATInit(data.image,"images/inventoryimages/".. data.image ..".xml")
                -----------------------------------------------------------
                    inst:ListenForEvent("on_landed",item_onland_event)
                -----------------------------------------------------------
                --- 可食用
                    inst:AddComponent("edible")
                    inst.components.edible.foodtype = FOODTYPE.VEGGIE
                    inst.components.edible.healthvalue = data.healthvalue
                    inst.components.edible.hungervalue = data.hungervalue
                    inst.components.edible.sanityvalue = data.sanityvalue
                -----------------------------------------------------------
                --- 腐烂
                    inst:AddComponent("perishable")
                    inst.components.perishable:StartPerishing()
                    inst.components.perishable.onperishreplacement = "spoiled_food"
                    inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*10)
                -----------------------------------------------------------
                --- 可叠堆
                    inst:AddComponent("stackable")
                    inst.components.stackable.maxsize = TBAT.PARAM.STACK_40()
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
                --- 烤
                    if data.cook_product then
                        inst:AddComponent("cookable")
                        inst.components.cookable.product = data.cook_product
                    end
                -----------------------------------------------------------
                MakeHauntableLaunch(inst)

                return inst
            end

            table.insert(ret_prefabs,Prefab(temp_prefab, fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 添加到烹饪锅
    AddIngredientValues({this_prefab,this_prefab.."_cooked"}, {veggie=1})
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret_prefabs)
