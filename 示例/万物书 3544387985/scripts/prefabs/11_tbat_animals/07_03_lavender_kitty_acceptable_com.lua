--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

2.野外的薰衣草猫猫改成给与猫猫6个薰衣草花穗会给玩家一个薰衣草洗衣液


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    local this_prefab = "tbat_pet_lavender_kitty"
    local accept_prefab = "tbat_food_lavender_flower_spike"
    local accpet_num_max = 6
    local reward_prefab = "tbat_material_lavender_laundry_detergent"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受升级
    local function acceptable_test_fn(inst,item,doer,right_click)
        if not inst:HasTag("pet") and item.prefab == accept_prefab then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 物品消耗
            item.components.stackable:Get():Remove()
            local num = inst.components.tbat_data:Add("item_accepted_num",1)
        --------------------------------------------------
        --  给玩家物品
            if num >= accpet_num_max then
                inst.components.tbat_data:Set("item_accepted_num",0)
                TBAT.FNS:GiveItemByPrefab(doer, reward_prefab, 1)
            end
        --------------------------------------------------
        -- 动画
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("playful"..math.random(4))
            end
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ADDCOMPOSTABLE)
        replica_com:SetSGAction("doshortaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return acceptable_com_install