--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    需要配方里配置 科技  ：  TECH.LOST

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_item_blueprint"
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
--- 
    local function OnTeach(inst, learner)
        learner:PushEvent("learnrecipe", { teacher = inst, recipe = inst.components.teacher.recipe })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    
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
        -------------------------------------------------
            inst:AddComponent("erasablepaper") -- 可擦除

            inst:AddComponent("named")
            inst:AddComponent("teacher")
            inst.components.teacher.onteach = OnTeach
            -- inst.components.teacher:SetRecipe()


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
        "tbat_item_snow_plum_wolf_kit",
        "tbat_eq_furrycat_circlet",
        "tbat_item_maple_squirrel_kit",
        "tbat_building_snow_plum_pet_house",
        "tbat_building_osmanthus_cat_pet_house",
        "tbat_building_maple_squirrel_pet_house",

        --- 第二期：
        "tbat_eq_snail_shell_of_mushroom",  --- 蜗牛壳
        "tbat_building_forest_mushroom_cottage",  --- 蘑菇小窝房子
        "tbat_container_mushroom_snail_cauldron",  --- 蘑菇小蜗埚(炼丹炉)
        "tbat_building_four_leaves_clover_crane_lv1",  --- 四叶草鹤雕像
        "tbat_container_little_crane_bird",  --- 小小鹤草箱
        "tbat_container_lavender_kitty",  --- 薰衣草小猫
        "tbat_building_lavender_flower_house",  --- 薰衣草花房
        "tbat_eq_ray_fish_hat",                 --- 鳐鱼帽子
        "tbat_building_reef_lighthouse",        --- 礁石灯塔
    }
    local ret = {}
    for k, prefab in pairs(blueprint_prefabs) do
        local function fn()
            local inst = common_item_fn()
            if not TheWorld.ismastersim then
                return inst
            end
            inst.components.teacher:SetRecipe(prefab)
            return inst
        end
        table.insert(ret, Prefab(prefab.."_blueprint2", fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)

